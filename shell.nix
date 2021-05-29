{ sources ? import ./nix/sources.nix }:
let

  pkgs = import sources.nixpkgs { };

  basePackages = with pkgs; [ ruby ];
  hooks = ''
    mkdir -p .nix-gems
    mkdir -p tmp/pids
    export GEM_HOME=$PWD/.nix-gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
    export PATH=$PWD/bin:$PATH
    echo "bundler install check..."
    gem list -i ^bundler$ -v 1.17.3 || gem install bundler --version=1.17.3 --no-document
    bundle config build.nokogiri --use-system-libraries
    bundle config --local path vendor/cache
  '';
in pkgs.mkShell {
  inputs = basePackages;
  shellHook = hooks;
}
