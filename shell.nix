{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs { };

  # define packagesto install with special handling for OSX
  basePackages = [
    pkgs.python
    pkgs.nodejs-12_x
    pkgs.yarn
    pkgs.gnumake
    pkgs.gcc
    pkgs.readline
    pkgs.openssl
    pkgs.zlib
    pkgs.curl
    pkgs.libiconv
    pkgs.postgresql_11
    pkgs.bundler
    pkgs.pkgconfig
    pkgs.libxml2
    pkgs.libxslt
    pkgs.ruby
    pkgs.zlib
    pkgs.libiconv
    pkgs.lzma
    pkgs.redis
    pkgs.git
    pkgs.openssh
  ];

  inputs = if pkgs.system == "x86_64-darwin" then
              basePackages ++ [pkgs.darwin.apple_sdk.frameworks.CoreServices]
           else
              basePackages;


   localPath = ./. + "/local.nix";

   final = if builtins.pathExists localPath then
            inputs ++ (import localPath).inputs
           else
            inputs;

  # define shell startup command with special handling for OSX
  baseHooks = ''
    export PS1='\n\[\033[1;32m\][nix-shell:\w]($(git rev-parse --abbrev-ref HEAD))\$\[\033[0m\] '

    mkdir -p .nix-gems
    mkdir -p tmp/pids

    export GEM_HOME=$PWD/.nix-gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
    export PATH=$PWD/bin:$PATH
    export NODE_PATH=$PWD/.nix-node
    export NPM_CONFIG_PREFIX=$PWD/.nix-node
    export PATH=$NODE_PATH/bin:$PATH

    echo "bundler install check..."
    gem list -i ^bundler$ -v 2.1.4 || gem install bundler --version=2.1.4 --no-document
    bundle config build.nokogiri --use-system-libraries
    bundle config --local path vendor/cache
    export DISABLE_SPRING=true
  '';

  localHooks = ./. + "/local_hooks.nix";

  hooks = if builtins.pathExists localPath then
            baseHooks + (import localPath).hooks
          else
            baseHooks;

in
  pkgs.stdenv.mkDerivation {
    name = "ghedam.at";
    buildInputs = final;
    shellHook = hooks;
    hardeningDisable = [ "all" ];
  }
