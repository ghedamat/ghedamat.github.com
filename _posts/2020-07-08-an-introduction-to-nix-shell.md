---
created_at: 2020-07-08 21:00:00
layout: post
title: "An introduction to nix-shell" 
thumbnail: "https://gsnaps.s3-us-west-2.amazonaws.com/monkey_actions_chicken.png"
permalink: /15978/an-introduction-to-nix-shell
excerpt_separator: <!--more-->
---
![actions](https://gsnaps.s3-us-west-2.amazonaws.com/monkey_actions_chicken.png)

# Short version

On June 26th I gave a short talk at our [Toronto Elixir Meetup](https://www.meetup.com/TorontoElixir/events/270441307/), this post is an extended version of that talk.
<!--more-->

If you are in a rush, you can skim through the slides here:

<iframe height="500px" style="max-width: 800px; width: 100%" src="https://nix-shell-nixto-2020.vercel.app/">
</iframe>

---

# Long version
> 👋 A word of warning, there is a fair amount of hand-waving ahead. Suggestions and corrections are welcome and encouraged! Feel free to reach out to me [on twitter](https://twitter.com/ghedamat) or via email!

## Definition: `nix-shell`

```
nix-shell — start an interactive shell based on a Nix expression
```

> The command nix-shell will build the dependencies of the specified derivation, but not the derivation itself. 
> It will then start an interactive shell in which all environment variables defined by the derivation path have been set to their corresponding values, and the script $stdenv/setup has been sourced. This is useful for reproducing the environment of a derivation for development.

[Extract from the Nix manual](https://nixos.org/nix/manual/#name-2)


### Let me paraphrase

Running `nix-shell` will start an *interactive* `bash` shell, in the current working directory. The packages required (we'll see shorty how to specify them) will be downloaded but not installed globally. Instead the shell will have its `ENV` set appropriately so that all the packages in the shell definition are available.

You can test this by typing 

```bash
env
...
# lots of stuff

nix-shell -p ripgrep
env
...
# lots of stuff but with a bunch of new things!
```

## Some simple `nix-shell` uses 

### Install a package without installing it globally

```bash
nix-shell --packages
# or
nix-shell -p
```

Starts a `nix-shell` that has the package available in its `$PATH`

```bash
$ which rg
rg not found

$ nix-shell -p ripgrep
[nix-shell:~]$ which rg
/nix/store/rw24lqk4ls1b90k1jj0j1ld05kgqb8ac-ripgrep-11.0.2/bin/rg

```

### Run a command in a `nix-shell`
Building on the above, you can temporarily add a package and immediately use it

```
$ nix-shell -p ripgrep --run "rg foo"
```


## Creating your first `shell.nix`

The `nix-shell` command receives an optional argument for a `.nix` file. By default if invoked with no arguments `nix-shell` will first look for a file named `shell.nix` and then for one named `default.nix`.

This `.nix` file has to contain the definition of a [derivation](https://nixos.org/nix/manual/#ssec-derivation), the standard library offers a special derivation function [`mkShell`](https://nixos.org/nixpkgs/manual/#sec-pkgs-mkShell) specifically for this purpose (although the more general `stdenv.mkDerivation` can still be used).
 
> Derivations are the building blocks of a Nix system, from a file system view point. The Nix language is used to describe such derivations.  (cit. [Nix Pills](https://nixos.org/nixos/nix-pills/our-first-derivation.html))


Here's a basic shell, it provides only the `buildInputs` attribute, that is, the list of packages to make available in your shell.

```nix
# simple.nix
with (import <nixpkgs> {});
mkShell {
  buildInputs = [
    ripgrep
  ];
}
```

```bash
$ nix-shell simple.nix
[nix-shell:~]$ rg foo
# ... 
```

You can also provide the `shellHook ` attribute to customize the `bash` shell being spawned.

```nix
# hooks.nix
with (import <nixpkgs> {});
mkShell {
  shellHook = ''
    alias ll="ls -l"
    export FOO=bar
  '';
}
```

```bash
$ nix-shell
[nix-shell:~]$ echo $FOO
bar

```


## Using `nix-shell` for development

Where `nix-shell` really shines for me is in its ability to provide **uniform** and **shareable** configuration for development environments **in virtually any language**.

In this section I'll provide a few examples of `shell.nix` configuration files for different programming languages. You can imagine these shell derivations as a drop in replacement for what usually is done with language-specific *version managers* like [Rvm](http://rvm.io/), [nvm](https://github.com/nvm-sh/nvm) and [asdf](https://github.com/asdf-vm/asdf) but, as we'll see, this approach is beyond just managing language versions.


### A Python example

I am not a Python dev, but from my experimentation the support for Python feels quite "native" in Nix, one can create a *custom Python build* for the shell, and add the desired dependencies. A lot of Python version and packages are already available in the main `nixpkgs` package tree. 

The following example is lifted from the [NixOS Wiki](https://nixos.wiki/wiki/Python)

```nix
# python.nix
with (import <nixpkgs> {});
let
  my-python-packages = python-packages: with python-packages; [
    pandas
    requests
    # other python packages you want
  ];
  python-with-my-packages = python3.withPackages my-python-packages;
in
mkShell {
  buildInputs = [
    python-with-my-packages
  ];
}
```

Here's also a recent [blog post](https://thomazleite.com/posts/development-with-nix-python/) about using Python on Nix.

### A Rust example

For Rust mozilla has been providing a `shell.nix` to get you started

```nix
# rust.nix
with import <nixpkgs> {};
let src = fetchFromGitHub {
      owner = "mozilla";
      repo = "nixpkgs-mozilla";
      rev = "9f35c4b09fd44a77227e79ff0c1b4b6a69dff533";
      sha256 = "18h0nvh55b5an4gmlgfbvwbyqj91bklf1zymis6lbdh75571qaz0";
   };
in
with import "${src.out}/rust-overlay.nix" pkgs pkgs;
stdenv.mkDerivation {
  name = "rust-env";
  buildInputs = [
    # Note: to use use stable, just replace `nightly` with `stable`
    latest.rustChannels.nightly.rust

    # Add some extra dependencies from `pkgs`
    pkgconfig openssl
  ];

  # Set Environment Variables
  RUST_BACKTRACE = 1;
}
```

The interesting thing here is that the *Mozilla Nix [overlay](https://nixos.wiki/wiki/Overlays)* is fetched as part of the shell derivation, this shows how shells are not limited to a single source for packages.

### The recommended approach for NodeJS, Ruby, Elixir

My current understanding is that in **the Nix way** a package and its dependencies are "reproducible", the final derivation we build is always gonna be the same because the inputs will always be the same.
Languages like `ruby`, `js` and others don't "naturally" provide this guarantee but the Nix ecosystem has produced a few ways to work around this problem

For Ruby this pattern is implemented using [`bundix`](https://github.com/nix-community/bundix):
`bundix` runs against your `Gemfile` and generates a *Nix expression* that includes all the Ruby dependencies used in your project

With that you can define a `nix-shell` that will have all the dependencies available and can effectively avoid using `bundler` (the Ruby package manager) in your workflow.

#### In practice:
Given a Ruby project with a `Gemfile` you can:

- run `bundix -l`
- source the generated `gemset.nix` in your `shell.nix`

```nix
# bundix.nix
with (import <nixpkgs> {});
let
  gems = bundlerEnv {
    name = "your-package";
    inherit ruby;
    gemdir = ./.;
  };
in mkShell {
  buildInputs = [gems ruby];
}
```

Similar solutions exist for other languages, for example Node has [`yarn2nix`](https://github.com/nix-community/yarn2nix).


### A more generic approach for interpreted languages

While the previous approach has some really good advantages I personally found that for personal projects, and for my team at work, a less Nix-y solution has been working better.

The strategy that I have been using is to *override* the environment variables that the package manager provides and **force** the installation of packages to happen locally to the directory in which the shell is being used.

Here's an example for a [NodeJS](https://nodejs.org/en/) shell.

```nix
# node.nix
with (import <nixpkgs> {});
mkShell {
  buildInputs = [
    nodejs-12_x
    yarn
  ];
  shellHook = ''
      mkdir -p .nix-node
      export NODE_PATH=$PWD/.nix-node
      export NPM_CONFIG_PREFIX=$PWD/.nix-node
      export PATH=$NODE_PATH/bin:$PATH
  '';
}
```

And here's a slightly bigger one that I've used for [Ruby on Rails](https://rubyonrails.org/) development

```nix
# ruby.nix
with (import <nixpkgs> {});
mkShell {
  buildInputs = [
    nodejs-12_x
    ruby
    yarn
    gnumake
    gcc
    readline
    openssl
    zlib
    libiconv
    postgresql_11
    pkgconfig
    libxml2
    libxslt
  ];
  shellHook = ''
    mkdir -p .nix-gems

    export GEM_HOME=$PWD/.nix-gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
    export PATH=$PWD/bin:$PATH

    gem list -i ^bundler$ -v 1.17.3 || gem install bundler --version=1.17.3 --no-document
    bundle config build.nokogiri --use-system-libraries
    bundle config --local path vendor/cache
  '';
}
```

I've also talked about how to do this in [Elixir](https://elixir-lang.org/) in a [separate blog post](https://ghedam.at/15443/a-nix-shell-for-developing-elixir). 


At a high level, this tecnique is very similar **regardless of the programming language**:

1. Identify the `ENV ` variable that determine the installation paths for packages and executables
2. Override them to be local to `$PWD`
3. Extend `$PATH` to include the installation path for binaries (so that things like `npm install -g` work)

## Tips for sharing `shell.nix`

### Use a specific "Nix channel" 

A "trick" that I have found useful is being able to import from a different channel within a Nix derivation, this is often useful if in your `shell.nix` you want to install packages from a more recent version. In the following example I'm using the `unstable` channel while my host system `<nixpkgs>` are version `20.03`.

```nix
with (import (fetchTarball https://github.com/nixos/nixpkgs/archive/nixpkgs-unstable.tar.gz) {});
mkShell {
  buildInputs = [
    git-up
  ];
}
```


### Pinning to a specific `<nixpkgs>` SHA.

When sharing a `shell.nix` it can be helpful to "pin" the `<nixpkgs>` version. This guarantees that regardless of the `nix-channel` used on the system everyone gets **exactly** the same Nix packages.

This is done by specifying a commit SHA directly from Github.

```nix
with (import (fetchTarball https://github.com/nixos/nixpkgs/archive/8531aee99f4907bd255545eb94468e52a79a44f1.tar.gz) {});
mkShell {
  buildInputs = [
    git-up
  ];
}
```

This guarantees that so long as you specify all the dependencies, and don't accidentally rely on something coming from the OS, every user will get the same setup.

[This tutorial](https://nix.dev/tutorials/towards-reproducibility-pinning-nixpkgs.html#pinning-nixpkgs) also offers a good explanation.


### Extending a shared `shell.nix`

As soon as we started using a shared `shell.nix` at work it became clear that there was a need to customize the some aspects of the shell on a per-user basis.

The solution I resorted to is check if a `local.nix` is present and if so expect that file to provide an `attributeSet` with two attributes: `inputs` and `hooks`.
These attributes are merged with the ones provided by the `shell.nix` that is checked in into your git repository.

```nix
# shell.nix
with (import <nixpkgs> {});
let
  basePackages = [ ripgrep ];
  localPath = ./local.nix;
  inputs = basePackages
    ++ lib.optional (builtins.pathExists localPath) (import localPath {}).inputs;

  baseHooks = ''
    alias ll="ls -l"
  '';

  shellHooks = baseHooks
    + lib.optionalString (builtins.pathExists localPath) (import localPath {}).hooks;

in mkShell {
  buildInputs = inputs;
  shellHook = shellHooks;
}
```


```nix
# local.nix
{ pkgs ? import <nixpkgs> {} }:
{
  inputs = [ pkgs.curl ];
  hooks = ''
    alias ghedamat="mattia"
  '';
}
```


### Cross platform `nix-shell`

Nix works both on MacOS and Linux but there are some dependencies that are platform specific.
The following example shows how these can be accounted for in your configurations

```nix
# cross.nix
with (import <nixpkgs> {});
let
  basePackages = [
    ripgrep
  ];

  inputs = basePackages
    ++ lib.optional stdenv.isLinux inotify-tools
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
      ]);

in mkShell {
  buildInputs = inputs;
}
```

## A complete development setup: `nix-shell` and `docker`

 `nix-shell` works great to configure dependencies but does not really solve for *services*. Often your development environment will require one or more databases (I often need PostgreSQL and Redis running). Such services can be installed at the system level but project-based isolation is in my opinion preferred.
 
While I found that `nix-shell` is a much better development environment than `docker` I do think that running services is what the latter excels at.

The solution then becomes: use both! `docker-compose` for services and `nix-shell` to run code!

[I wrote a previous post](https://ghedam.at/15502/speedy-development-environments-with-nix-and-docker) on how at [Precision Nutrition](https://www.precisionnutrition.com/) we implemented this hybrid approach. If you are interested I encourage you to read it and let me know what you think!


## Customizing the shell

Extending `nix-shell` to allow for more customization (i.e. using `zsh` or not have to type `nix-shell` every time) is beyond the scope of this post but I will leave a few pointers here for the interested reader.

- `nix-shell --run zsh` is a simple workaround that allows you to change the `$SHELL` from `bash`
- [`direnv`](https://direnv.net/) can be used to take this a step further and "load" the `nix-shell` ENV without spawning a new shell
- [`lorri`](https://github.com/target/lorri) is another project that aims at replacing nix-shell by extending it.


## Recap

* `nix-shell` allows you to define development environments for pretty much any language in a consistent way, it makes also easy to support different versions of the same language!
* Adding `shell.nix` to your project can be used to ensure that everyone on the team has the same configuration and is also a great way to help new contributors get setup quickly.
* In my experience, combining `docker` and `nix-shell` for projects that require databases or other services, is the way to go!

Thanks for reading!

### Other resources:

* After writing this blog, I found [this post](https://myme.no/posts/2020-01-26-nixos-for-development.html) that covers a similar ground and shows some alternative and interesting solutions. Definitely worth a read!
* Other good examples can be found at [nix.dev](https://nix.dev/tutorials/ad-hoc-developer-environments.html).

