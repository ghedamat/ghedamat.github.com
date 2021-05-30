---
created_at: 2020-05-03 14:00:00
layout: post
title: "Speedy Development environments with Nix and Docker" 
permalink: /15502/speedy-development-environments-with-nix-and-docker
excerpt_separator: <!--more-->
---


How to use Nix and Docker together faster development environments.

<!--more-->

> This is a cross post from PrecisionNutrition's tech blog https://tech.precisionnutrition.com

# The problem

Our stack at PN is composed by one [Rails](https://rubyonrails.org) monolith and a plethora of [EmberJS](https://emberjs.com) frontend apps.

We also use [PostgreSQL](https://postgresql.org), [Redis](https://redis.io) and [NGINX](https://nginx.org).

This means that in order to run our development stack each engineer has to at a minimum run one Rails server, two databases and a web server, usually they will also be running at least one frontend application and possibly a REPL to interact with the Rails server and maybe some tests.

# The commonly used solution

In the "good old days" developers used to run everything locally on their work laptop, this was done using a bunch of tools:

* [rbenv](https://github.com/rbenv/rbenv) - managing Ruby version
* [nvm](https://github.com/nvm-sh/nvm) - managing NodeJS versions
* [homebrew](https://brew.sh) - managing system packages (like PostgreSQL, C libraries, Redis)

But running everything locally has several problems:

* It required each dev to manage their own environment and dependencies
* It is very hard to have different versions of certain dependencies (i.e database) installed at the same time (one may work on multiple projects or want to experiment with a newer version of some dependency)
* A system update can easily break the dev environment, causing lost productivity

# Docker saves the day (or not?)

In recent years the dev community moved to [containerized](https://www.docker.com/resources/what-container) solutions.

'Containerization' usually means [docker](https://docker.com), although alternatives do exist.

*handwaving ahead* - The idea behind Docker is to use the "host" system kernel but package applications and dependencies into a single "blob". This blob can be pushed to the cloud and downloaded for later use. This guarantees that when the application is the deployed **no dependencies** have to be installed on the remote system because they are all contained within the "docker image" that will be run.

Although initially intended to make deployments easier, the dev community rallied around Docker and extended its use case beyond deployments to include local development.

Docker Compose is typically used to orchestrate the various containers needed for local development. A `docker-compose.yml` configuration is defined, which includes **all** services as well as the main application.

To run a Ruby On Rails app similar to ours you would need a `docker-compose` file that configures a PostgreSQL server, a Redis server, an NGINX server and a Linux image with all the dependencies for the Rails app. [Here's one of the many blogposts on how to do this](https://thoughtbot.com/blog/rails-on-docker).

**The only real difference** between this setup and the image that gets deployed to production is that the development image is usually configured to "mount" the code directory from the host system, allowing developers to edit their code locally and have it reload within the docker image.

## Issues with Docker

The main issue we found with using Docker locally is that docker filesharing is **extremely** slow, especially on **MacOS**. The interwebs have plenty of resources to [address this problem](https://engageinteractive.co.uk/blog/making-docker-faster-on-mac) but these approaches simply mitigate rather than resolve the underlying performance issue.

Docker performance is pretty bad for Rails development but it's even worse for front-end apps that require a gazillion files to be loaded and written (cough cough webpack).
Poor Docker performance usually leads developers to give up on Docker for their frontend - and return to a painfully slow backend development process.

# Nix-shells - A better way?

Surely there must be a way to use docker for what it is good at (running services like databases) and have a way to manage dev dependencies without having to manually install them like in the "good old days".

Enter [Nix]https://nixos.org/nix/). Nix is "The Purely Functional Package Manager", you can imagine it as an alternative to Homebrew or apt, yum, etc.

Nix works **both** on MacOS and Linux and allows **userspace** installation of packages.

But for our use case the best part of nix is [`nix-shell`](https://www.sam.today/blog/environments-with-nix-shell-learning-nix-pt-1/).

A `nix-shell` is a `bash` console that is loaded starting from the host terminal but is initialized with a pre-defined set of packages which are downloaded the first time you run the shell. The packages are then instantly available for later use. Think about it as a `bundle install` or a `npm install` but for your OS dependencies.
`nix-shell`s work in isolation, this means that the dependencies available inside the shell *cannot* leak out to your host system. Nix achieves this by using a symlink structure and by manipulating your bash `PATH`.
If you are curious on how this works try to issue `echo $PATH` when you start the example shell below.

For example

A `shell.nix` file with the following contents

```nix
let
  basePackages = [
    ruby
  ];

  hooks = ''
    mkdir -p .nix-gems
    export GEM_HOME=$PWD/.nix-gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
    export PATH=$PWD/bin:$PATH
  '';

in
  pkgs.stdenv.mkDerivation {
    name = "your-shell-name";
    buildInputs = basePackages;
    shellHook = hooks;
    hardeningDisable = [ "all" ];
  }
```

can be invoked by simply running `nix-shell` in the current directory, you will be moved to a new `bash` shell that has Ruby installed for you!

An important thing to note is that a `nix-shell` is just another `bash` shell, there is **no virtualization** happening, the only difference is that the `nix-shell` has access to more dependencies that come from the shell configuration.

The consequence of this is that the shell is *not* like a docker container and will not run services for you, services are still system level processes.

### A small note about packaged dependencies 
Sometimes your project will require to install packages that are not available on Nix.
An example of this can be ruby gems that you install with `gem install` or node packages installed with `npm install -g`.

The Nix ecosystem offers a few solutions for this problem but the `shell.nix` file we included above shows a simple trick that we found works well.

By setting some `export`s (i.e `GEM_PATH`) we manipulate the install paths for RubyGems so that all `gems` installations are local to the shell. Normally RubyGems would try to install these globally and because Ruby was installed by Nix the commands would fail.

# Our solution: use Nix and Docker together 

The solution we went with at PN is to take the best of `docker` and `nix-shell` and use each one where it shines.

This means using `docker` to run our databases and NGINX and using `nix-shell` to manage the dependencies and run ruby and node.

Our main Rails application then ships with

* a `docker-compose.yml` that configures PostgreSQL, Redis, NGINX
* a `shell.nix` that gives the user a `nix-shell` with the right version of Ruby, NodeJS, OpenSSL etc

The development workflow then becomes

* start docker-compose
* run `nix-shell` and from there start `bundle exec rails s` or `bundle exec rails c` or any other process you might need to run

This also works great for our EmberJS applications and allows us to avoid using `nvm` while retaining native performance.


# Taking this further

After doing this for a few months and enjoying the greatly improved development speed we decided to take this further and build some more automation around this.

`pndev` was born - [pndev](https://github.com/PrecisionNutrition/pndev) is a command-line tool that automates our dev workflows and will likely be the subject of a future blog post.


# Resources
Here are some useful resources to get you started with development in a `nix-shell`

- [https://medium.com/better-programming/easily-reproducible-development-environments-with-nix-and-direnv-e8753f456110](https://medium.com/better-programming/easily-reproducible-development-environments-with-nix-and-direnv-e8753f456110)
- [https://medium.com/@ejpcmac/about-using-nix-in-my-development-workflow-12422a1f2f4c](https://medium.com/@ejpcmac/about-using-nix-in-my-development-workflow-12422a1f2f4c)
- [https://nixos.wiki/wiki/Development_environment_with_nix-shell](https://nixos.wiki/wiki/Development_environment_with_nix-shell)
- [https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html](https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html)
- [https://medium.com/@ejpcmac/about-using-nix-in-my-development-workflow-12422a1f2f4c](https://medium.com/@ejpcmac/about-using-nix-in-my-development-workflow-12422a1f2f4c)

# Some caveats
* Apple does their best to mess up 3rd party installs so installing Nix on MacOS is a [bit more complicated than one would like](https://dev.to/louy2/installing-nix-on-macos-catalina-2acb)
* Nix is somewhat difficult programming language to learn but writing nix-shells is fairly easy


<img style="width: 1px;" src="https://conta.onrender.com/ghedam.at/15502/speedy-development-environments-with-nix-and-docker" />
