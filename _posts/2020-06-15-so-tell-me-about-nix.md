---
created_at: 2020-06-15 06:00:00
layout: post
title: "So, tell me about Nix" 
thumbnail: "https://gsnaps.s3-us-west-2.amazonaws.com/loom.png"
permalink: /15490/so-tell-me-about-nix 
excerpt_separator: <!--more-->
---

![Loom](https://gsnaps.s3-us-west-2.amazonaws.com/loom.png)

Nix has been around the block for a while but recently, both from outside and from within the Nix community, I've seen several efforts to make Nix more beginner friendly.
<!--more-->

I have been using NixOS for a year or so, and I had myself to go through what was a somewhat confusing and effortful onboarding process. I was lucky enough to have friends like [@shazow](https://twitter.com/shazow) to help me on the way but I still feel I have many gaps in my understanding.

I'm writing this post is to collect my thoughts on Nix and present a few of the things that I found helpful during my Nix journey. 

My hope is that they can also help others learn and use what I consider being the next step when it comes to developer ergonomics both on MacOS and Linux.


In the resources section below you will find more detailed and precise explanations so feel free to skip there!

# Where to start?

The first confusing thing about Nix is that the name is used to refer to a few things:

* [Nix](https://nixos.org/) the package manager
* [Nix](https://nixos.org/)  the programming language
* [NixOS](https://nixos.org/)  the operating system

I'll briefly cover what I like and how I use each one of these, leaving some resources at the end of this post for readers that are interested in a deeper exploration.

# What I love about Nix, the package manager

Nix can be used like `brew` on MacOS or `apt`, `yum`, `emerge` and many others on Linux. It can be installed locally for a single user or globally on any Unix based system (including MacOS).

One you have [installed Nix](https://nixos.org/download.html) you can do stuff like

```bash
$ nix-env -iA curl
```

and Nix will download and install the package you selected and all its dependencies.
It will be there for you to use until you decide to delete it.

There is a lot to be said about how Nix works and all the features that it brings to package management, a notable one being **reproducible builds** that guarantee that a given version of a package will **always** be the same, including all its dependencies. Some of the links at the end of this post will allow you to explore this topic.

One thing that is *unique* to Nix is the ability to download and run the package without the need to install it globally, you can instead *spawn* a new `bash` shell with the packages you are interested in
```bash
$ nix-shell -p curl
[nix-shell:~]$ curl -I http://nixos.org
# ...
```

once you leave this shell `curl` will not be available anymore.

`nix-shell`s can do this an much more, they also allow you to define **isolated development environments**, and share them with other developers ensuring that they can quickly spawn a `bash` shell using exactly the same dependencies you have.

`nix-shell` is a complex topic though (and I have much left to learn myself), I will probably cover it more in a future post, for now you can see a small example [here](https://ghedam.at/15443/a-nix-shell-for-developing-elixir).

# What I love about NixOS, the Operating System

Quoting directly from the [NixOS website](https://nixos.org/features.html):

> In NixOS, the entire operating system — the kernel, applications, system packages, configuration files, and so on — is built by the Nix package manager from a description in a purely functional build language. The fact that it’s purely functional essentially means that building a new configuration cannot overwrite previous configurations. Most of the other features follow from this.

Unlike most operating systems NixOS allows users to **describe** their desired system configuration and then leave it to Nix to *apply* said configuration and make all the required changes.

There are no configuration files to edit, copy, backup **outside** of the `.nix` ones in `/etc/nixos`.

Here's an example of the **full configuration** (minus the hard-drive part) required to provision a PostgreSQL server.
```nix
{ config, pkgs, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-config.nix
  ];

  environment.systemPackages = with pkgs; [
    curl
    wget
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "postgres-server"; # Define your hostname.
  networking.firewall.enable = false;
  networking.interfaces.enp6s18.useDHCP = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ghedamat = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.promptInit = ""; # Clear this to avoid a conflict with oh-my-zsh

  # postgres config
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_11;
    enableTCPIP = true;
  };

  system.stateVersion = "20.03"; 
}
```

There's a lot going on here and much more to say but it is hard to describe, as a long time Linux user and system administrator, how much **joy** the ability to **declare** the state of my system configuration brings me.

Oh and there's one more thing!

Thanks to the magic of the Nix package manager you can also **rollback** safely to **any previous configuration** you ever ran on your machine.

# What I love about the Nix ecosystem
The Nix community created other tools the follow the same philosophy:

* [home-manager](https://github.com/rycee/home-manager) allows you manage your user configuration. You can use it to configure git, zsh, install packages only for your user and much more.
* [NixOps](https://github.com/NixOS/nixops) allows you to provision and manage remote machines. Think like terraform plus chef but done the nix way
* [nix-darwin](https://github.com/LnL7/nix-darwin) is NixOS but on MacOS!


**home-manager** has completely changed how I manage my [`dotfiles`](https://dotfiles.github.io/), now I have a single place to configure all my user-level applications across different machines. As an example, this is my [ThinkPad config](https://github.com/ghedamat/nixfiles/blob/master/nixpkgs/home-x280.nix).

With **NixOPS** I am managing my laptop, my desktop and all my development VMs. I'll try to cover this setup in a future blog post, but you can get a sense for it [here](https://github.com/ghedamat/nixfiles/blob/master/hive-ops.nix).
# What about the Nix language? 
The Nix language is what powers this all. Truth to be told, I can't say that I have a solid understanding of it even after using Nix for quite a while. 

The good news is that I feel that's **OK**. Even with my limited proficiency I have been able to manage several systems: laptops, desktops and VMS. All my dotfiles are now managed in Nix too and I also moved over our entire development environments at work to use `nix-shell`.

My advice is to **not get intimidated** and learn it more as you need it.


# Getting started
If you looking to give this a go, whether you are on MacOS or Linux my advice is:

1) [install](https://nixos.org/download.html) Nix for your user 
2) use `nix-shell` to try a few packages
3) start using home-manager to manage your installed packages, and maybe try to move a few of your `dotfiles` over
4) start using `nix-shell` to define [per-project development environments](https://ghedam.at/15443/a-nix-shell-for-developing-elixir) 
# Some resources

Here's some of the resources I found the most helpful getting started with Nix:

* [Burke Libbey](https://twitter.com/burkelibbey) has been publishing a series of videos called [#nixology](https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs). He goes over Nix, home-manager and much more! It's a great introduction to the power of Nix and how it can be used for development.
* Burke also wrote an extensive [blog post about Nix](https://engineering.shopify.com/blogs/engineering/what-is-nix).
* The recently revamped [Nix website](https://nixos.org/) has some great example right on the homepage of what Nix can do.
* [Stéphan Kochen](https://stephank.nl/) wrote [a great blog post](https://stephank.nl/p/2020-06-01-a-nix-primer-by-a-newcomer.html) where he talks about Nix and its terminology. 
* The [NixCloud Tour](https://nixcloud.io/tour/) is a great way to learn the basics of the Nix language.
* [A gentle introduction to the Nix family](https://ebzzry.io/en/nix/).
* [Nix Pills](https://nixos.org/nixos/nix-pills/) is also a good way to learn more about the language (it gets progressively hard but you can stop along the way).
* On top of the very handy [package search interface](https://nixos.org/nixos/packages.html) the Nix website has also a useful search [for NixOS options](https://nixos.org/nixos/options.html#).
* [The Nix Wiki](https://nixos.wiki/) has some really good recipes for common problems.
* If you are seeking for help [the NixOS discourse forum](https://discourse.nixos.org/) is a great place to start.


Finally a thing that can be intimidating at first but works super well is [reading the source](https://github.com/NixOS/nixpkgs). Once you get the basics it's surprisingly approachable. 

And last but not least have a look at [other people nixfiles](https://github.com/search?q=nixfiles). It was a great way for me to get started. If you are curious these are [mine](https://github.com/ghedamat/nixfiles) and [shazow's](https://github.com/shazow/nixfiles) nixfiles.


## Conclusion 

Hope this will help you or maybe even convince you to join the Nix community! Feel free to tweet at me for any feedback or questions. 

We also have a very small [Toronto meetup](https://www.meetup.com/NixToronto/) and discord channel. Reach out if you wanna join us!


# Bonus - NixTO online meetup
On **Thursday June 25th** we are running our first online [**Toronto Nix meetup**](https://www.meetup.com/NixToronto/events/271227144/).

Regardless of where you are, come join us!

