---
created_at: 2021-04-05 12:00:00
layout: post
title: "A Tour of Nix Flakes"
thumbnail: "https://gsnaps.s3.us-west-2.amazonaws.com/blog/monkey-island-tour.jpg"
permalink: /a-tour-of-nix-flakes
excerpt_separator: <!--more-->
---

![monkey island tour](https://gsnaps.s3.us-west-2.amazonaws.com/blog/monkey-island-tour.jpg)

For a while now I've been wondering about Nix Flakes, what they are and how they are going to change how we use Nix.
<!--more-->

This post is a summary of my understanding so far based on research (see resources below) and some light experimentation.

**Disclamer:** I am quite new to flakes and by no means a Nix expert, so if something in this article is inaccurate or wrong please reach out and I'll fix it!

**Warning:** The word flakes appears over 30 times in this blog post.

# Nix Flakes?
Nix Flakes are an upcoming feature of the Nix package manager.

Flakes allow to define inputs (you can think of them as dependencies) and outputs of packages in a declarative way.

You will notice similarities to what you find in package definitions for other languages (Rust crates, Ruby gems, Node packages) - like many language package managers flakes also introduce dependency pinning using a `lockfile`.

## What can they do for everyone?
The main benefits of flakes are:

**Reproducibility:** Even if the Nix language is purely functional it is currently not possible to ensure that the same derivation will yield the same results. This is because a derivation can have _undeclared_ external dependencies such as local configuration, `$NIX_PATH`, command-line arguments and more. Flakes tackle this issue by making every dependency **explicit** as well as **pinning** (or locking) their versions.

**Standardization:** Every Flake implements a `schema` and defines clear `inputs` and `outputs` (see below for more details). This allows for better **composability** as well as avoiding the need for [niv](https://ghedam.at/25722/using-niv-to-install-recent-elixir-in-your-nix-shell).

**Discoverability:** Because all outputs are declared, it is possible to know what is exposed by a flake (i.e which packages).


## What can they do for me?
On top of the above there are other practical benefits for day to day Nix use.

### Faster nix-shell(s)
Nix Flakes add another layer of caching that was not possible before: the **evaluation** of Nix expressions.

A very practical result of this change is that `nix-shell` gets a whole lot faster. The first run will take the usual time but any subsequent one will be practically instant!

### A new `nix` command
Another change that  been paired with the addition of flakes is a whole new set of features for the  `nix` command.

I will not cover them all (see [NixOS wiki](https://nixos.wiki/wiki/Nix_command/flake)) but here's a few that I have been using:

#### `nix build` and `nix run`
`nix build` replaces `nix-build` and extends it in interesting ways, it can be used to build local as well as remote flakes. 

```
$ nix build .# <- defaultApp in local flake
$ nix build github:Mic92/nix-ld#nix-ld <- specifies output in remote flake
$ nix build github:Mic92/nix-ld <- defaultPackage in remote flake
```

`nix run nipkgs#XXX` replaces `nix-shell -p XXX --run XXX` 

```
$ nix run nixpkgs#jq <- runs the defaultApp from the `jq package`
```

You can use this to run also remote packages (same as with `nix build`).

```
$ nix run 'github:nixos/nixpkgs/nixpkgs-unstable#jq' 
#                 ^^ this could be any repository, not only nixpkgs
```


#### `nix shell` or `nix develop`?
There are now two separate commands to replace `nix-shell` although I expect to be mostly using `nix develop`

The main difference is that `nix shell nixpkgs#hello` will spawn a bash shell with the `hello` executable in the `$PATH` but no development dependencies while `nix develop nixpkgs#hello` will add those too.

I will provide a more detailed example of how to build a `nix-shell` using flakes later in this post.

#### `nix flake ...`

Nix Flakes have a dedicated whole set of subcommands, the two that I expect to use the most are

`nix flake show` which lists all the outputs provided by a flake.

`nix flake lock` which allows to manipulate the lockfile, in particular this is used to update the pinned versions of dependencies. i.e. `nix-flake lock --update-input nixpkgs`.

`nix flake new` can be used to create a new flake, it also supports [templates](https://github.com/NixOS/templates)!

For example:
```
$ nix flake new . -t templates#rust
```


# This sounds amazing, how do I try it?
## Installing
Most of the information I found claims that flakes should be pretty stable at this point. That said, note that this is still flagged as an **experimental** feature.

### On NixOS
Enable the required features in your `configuration.nix`.

```nix
{ pkgs, ... }: {
  nix = {
    package = pkgs.nixUnstable; # or versioned attributes like nix_2_4
    extraOptions = ''
 experimental-features = nix-command flakes
 '';
   };
}
```

### Using only the Nix package manager
Enable the required features for your user.
```
$ nix-env -f '<nixpkgs>' -iA nixUnstable # ensure you are running unstable
$ mkdir -p ~/.config/nix
$ echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

The [NixOS Wiki has a dedicated page](https://nixos.wiki/wiki/Flakes) with more details.

## Bits of a flake
Nix Flakes are declared as an "attribute set" that respects a predefined `schema`.

There are 3 top level attributes and various sub-attributes:

```nix
{
	description = "I am an optional description";
	
	# inputs contains all the dependencies of the flake
	inputs = {
		nixpkgs.url = "github:NixOs/nixpkgs" # this is set by default
		flake-utils.url = "github:numtide/flake-utils" # this is another flake
	};
	
	# outputs is a function that has the inputs are passed as parameters
	outputs = { self, nixpkgs, flake-utils }:

		packages = ... # packages exposed by this flake, used by nix build
		defaultPackage = ... # package called when nix build has no arguments
		
		apps = ... # apps exposed by this flake, used by nix run
		defaultApp = ... # app called when nix run has no arguments
		
		devShell = ... # this is the definition of the nix-shell
		
    ... # there's much more, see the NixOS wiki for details
	
	}

}
```

## An example of a `devShell`

As said above, `nix develop` replaces `nix-shell`.

Here's an example of a basic development shell with `ripgrep`:
```nix
{
  description = "A basic devShell";

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;

    in {
      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [ ripgrep ];

        shellHook = ''
          echo "shell with ripgrep"
        '';
      };

    };
}
```

Run it and you'll see the lockfile being created.
```
$ nix develop
warning: creating lock file '/home/ghedamat/DEV/OSS/ghedamat/flakes-playground/basic-shell/flake.lock'
shell with ripgrep
```

Run it again and you'll notice a faster startup as well as no changes to the lockfile.
```
$ nix develop
shell with ripgrep
```

You might have also noticed that I had to specify the "architecture", this is because one of the goals of flakes is to return the same output regardless of the environment they are evaluated in. 

This is achieved by making the output an attribute set with values for each architecture. For more details see this [serokell.io blog post](https://serokell.io/blog/practical-nix-flakes).

Running `nix flake show` shows:

```
$ nix flake show
path:/home/ghedamat/DEV/OSS/ghedamat/flakes-playground/basic-shell?narHash=sha256-waOoDEnxQM7fdvfFtDWYMd+jQRkwA1BrohBE37rUjYs=
└───devShell
    └───x86_64-linux: development environment 'nix-shell'
```

To avoid having to repeat our declaration for each architecture we intend to support we can use `eachDefaultSystem`  from [flake-utils](https://github.com/numtide/flake-utils) .

```nix
{
  description = "A basic devShell using flake-utils each";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
      flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ ripgrep ];

          shellHook = ''
            echo "shell with ripgrep"
          '';
        };
      }
    );
}
```

Using `nix flake show` we can see more systems:
```
$ nix flake show
path:/home/ghedamat/DEV/OSS/ghedamat/flakes-playground/flake-utils-each-shell?narHash=sha256-KHDsbeusyxmw+BVMcIMnYJvKFwUXjf7Jiv+S7TaJo+Q=
└───devShell
    ├───aarch64-darwin: development environment 'nix-shell'
    ├───aarch64-linux: development environment 'nix-shell'
    ├───i686-linux: development environment 'nix-shell'
    ├───x86_64-darwin: development environment 'nix-shell'
    └───x86_64-linux: development environment 'nix-shell'
```

## Wrapping an existing `shell.nix`
It is possible to import existing `shell.nix` files using flakes so that you can use `nix develop`. This allows for better code organization as well as having some users rely on flakes while others can keep using `nix-shell` in the same project.

Let's start from the `shell.nix` for NodeJS found in my [nix-shell post](https://ghedam.at/15978/an-introduction-to-nix-shell).

```nix
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

We first need to update this file to take `pkgs` as an optional parameter. This is required because using flakes environment dependent globals like `<nixpkgs>` (that is based on `$NIX_PATH`) are disabled.

```nix
{ pkgs ? import <nixpkgs> {} }:
with pkgs;
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

With this change we can write our `flake.nix`

```nix
{
  description = "A devShell that imports shell.nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
      flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      rec {
		# we pass `pkgs` directly to shell.nix
        devShell = import ./shell.nix { inherit pkgs; };
      }
    );
}
```

I have not tested it yet but it is possible to have `shell.nix` either rely on `niv` or on the `nixpkgs` passed by the flake.

# Conclusion and resources
I am looking forward to using flakes more in my personal and work projects.

In particular I want to explore if and how I can use flakes with my [nixops setup](https://github.com/ghedamat/nixfiles/blob/master/nixops.nix) as well as starting to migrate the `shell.nix` files that we use at work to support flakes.

If you want to dive deeper here are the references I used to write this post:
- [Initial Flakes blog post](https://www.tweag.io/blog/2020-05-25-flakes/) - great explanation of the reasons behind Nix Flakes.
- [serokell.io blog post](https://serokell.io/blog/practical-nix-flakes) - a practical introduction.
- [Official NixOS wiki](https://nixos.wiki/wiki/Flakes).
- [Nix Flakes Jupyter shell](https://dev.to/deciduously/workspace-management-with-nix-flakes-jupyter-notebook-example-2kke) - example of devShell with Flakes.
- [NixCon Flakes 101](https://www.youtube.com/watch?v=QXUlhnhuRX4&list=PLgknCdxP89RcGPTjngfNR9WmBgvD_xW0l) - NixCon Talk that gives a detailed explanation of most features.
- [Getting started with Nix Flakes](https://yuanwang.ca/posts/getting-started-with-flakes.html) - A good introductory blog post.

### Final notes

Usual shoutout to [@shazow](https://twitter.com/shazow) for reviewing this article as well as pointing out that, regarding reproducibility, there should be ways to depends on the environment safely. He also suggested [this](https://www.tweag.io/blog/2020-09-10-nix-cas/) [blog](https://www.tweag.io/blog/2020-11-18-nix-cas-self-references/) [post](https://www.tweag.io/blog/2021-02-17-derivation-outputs-and-output-paths/ ) [series](https://www.tweag.io/blog/2021-12-02-nix-cas-4/) on "content addressable Nix" that (if my understanding is correct) will be the next step after flakes.
