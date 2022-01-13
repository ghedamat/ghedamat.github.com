---
created_at: 2020-06-03 14:00:00
layout: post
title: "A nix-shell for developing Elixir" 
permalink: /15443/a-nix-shell-for-developing-elixir
---

Developing with [Elixir](https://elixir-lang.org) requires a fair amount of configuration.

You need:
* Erlang
* Elixir
* Hex package manager

And usually you want all these to be locked at a specific version.

There are several solutions out there, the most popular probably being [https://github.com/asdf-vm/asdf](https://github.com/asdf-vm/asdf)
but for [Nix](https://nixos.org/nix/) fans, how do we setup a `nix-shell` and do this the "nix way"?

The Nix community seems to reccomend to nixify your projects, examples exist for 
* Ruby https://github.com/nix-community/bundix
* Node https://nixos.wiki/wiki/Node.js
* Elixir https://discourse.nixos.org/t/announcing-mixnix-build-elixir-projects-with-nix/2444

I've been using a different pattern with most of my projects to achieve this, and it works for both [Ruby](https://www.ruby-lang.org/en/), Elixir and many other languages.

The trick is *find the env variables that allow us to "isolate" locally the dependency installation*, in our example these are `MIX_HOME` and `HEX_HOME`.

By setting these two variables to the local directory **within** the `nix-shell` we allow `mix` to install the packages locally instead of trying to add them to the `nix-store` path (`/nix...`) that is **readonly**.

### Summing it up

Here's the `shell.nix` file that I use in my elixir projects

```nix
with import <nixpkgs> {};
let
  # define packages to install with special handling for OSX
  basePackages = [
    gnumake
    gcc
    readline
    openssl
    zlib
    libxml2
    curl
    libiconv
    elixir_1_9
    glibcLocales
    nodejs-12_x
    yarn
    postgresql
  ];

  inputs = basePackages
    ++ lib.optional stdenv.isLinux inotify-tools
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
      ]);

  # define shell startup command
  hooks = ''
    # this allows mix to work on the local directory
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
    export LANG=en_US.UTF-8
    export ERL_AFLAGS="-kernel shell_history enabled"
  '';

in mkShell {
  buildInputs = inputs;
  shellHook = hooks;
}
```

save this in your project directory as `shell.nix` then type `nix-shell` and you will be in a `bash` shell that has `mix` and `elixir` ready to be used!

## Bonus: Add gigalixir support
[https://www.gigalixir.com](https://www.gigalixir.com/) is one of the simplest ways to deploy Elixir applications.
Similarly to Heroku, you subscribe, create an account, install the cli and you are off to the races.

### Jan 2022 Update

Gigalixir is now on [nixpkgs](https://search.nixos.org/packages?channel=21.11&from=0&size=50&sort=relevance&type=packages&query=gigalixir)! 
If you are on a recent version of nixpkgs (I tested 21.11) all you need to do is add `gigalixir` to the list of packages above.

Note: the package is currently broken in `nixpkgs-unstable`, afterall it is called "unstable" :)

### Old install process

The problem is that our `nix-shell` does not allow us to run `pip install gigalixir` and install the `gigalixir` command line utility.

Setting up python in nix requires a little more configuration. 

First we need to add [Python](https://www.python.org/) to our `nix-shell` and ensure that our python install has the `pip` package manager, a detailed explaination can be found here https://nixos.wiki/wiki/Python.

In short you can do something like this

```nix
  my-python-packages = python-packages: with python-packages; [
    pip
    setuptools
  ];

  python-with-my-packages = pkgs.python3.withPackages my-python-packages;
```

Then, like we did for Elixir, we have to force Python to 
install its stuff locally, we do this by setting `PIP_PREFIX` and `PYTHONPATH`;

```bash
 alias pip="PIP_PREFIX='$(pwd)/_build/pip_packages' \pip"
 export PYTHONPATH="$(pwd)/_build/pip_packages/lib/python3.7/site-packages:$PYTHONPATH"
```

The resulting `shell.nix` file is then as follows

```nix
with import <nixpkgs> {};
let
  my-python-packages = python-packages: with python-packages; [
    pip
    setuptools
  ];

  python-with-my-packages = pkgs.python3.withPackages my-python-packages;

  # define packages to install with special handling for OSX
  basePackages = [
    gnumake
    gcc
    readline
    openssl
    zlib
    libxml2
    curl
    libiconv
    elixir_1_9
    glibcLocales
    nodejs-12_x
    yarn
    postgresql
    inotify-tools
    python-with-my-packages
  ];


  inputs = basePackages
    ++ lib.optional stdenv.isLinux inotify-tools
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
      ]);
			
  # define shell startup command
  hooks = ''
    export PS1='\n\[\033[1;32m\][nix-shell:\w]($(git rev-parse --abbrev-ref HEAD))\$\[\033[0m\] '

    # this allows python to work locally
    alias pip="PIP_PREFIX='$(pwd)/_build/pip_packages' \pip"
    export PYTHONPATH="$(pwd)/_build/pip_packages/lib/python3.7/site-packages:$PYTHONPATH"
    unset SOURCE_DATE_EPOCH

    # this allows mix to work on the local directory
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
    export LANG=en_US.UTF-8
    export PATH=$PATH:$(pwd)/_build/pip_packages/bin
    export ERL_AFLAGS="-kernel shell_history enabled"
  '';

in mkShell {
  buildInputs = inputs;
  shellHook = hooks;
}
```

At this point we can type `nix-shell` and then `pip install gigalixir` and we are ready to go!


### Notes:

The full code can be found here in [this gist](https://gist.github.com/ghedamat/fbba4433579cd6ef8fdd94c5da57fbb3)

After publishing this post I found [this one](https://til.codes/nix-shell-for-elixir-projects/) that presents a simpler approach and with a shorter shell configuration, I updated my notes above to use `mkShell` and a nicer syntax that uses `lib.optionals` to load the MacOS only packages

Another good resource I only found today is [here](https://ejpcmac.net/blog/using-nix-in-elixir-projects/)


