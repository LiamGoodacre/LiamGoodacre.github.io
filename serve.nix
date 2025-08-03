# bootstrap.nix (one-off)
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby
    bundler
    jekyll
    gem
  ];

  shellHook = "
    export LC_ALL=C.UTF-8
    bundle install
    bundle lock --update
    bundle exec jekyll serve -l --watch --incremental --port 8080
    exit 0
  ";
}
