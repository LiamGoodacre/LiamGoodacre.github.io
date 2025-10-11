# bootstrap.nix (one-off)
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby_3_3
    bundler
  ];

  shellHook = "
    export LC_ALL=C.UTF-8
    bundle config set --local path 'vendor/bundle'
    bundle install
    bundle lock --update
    bundle exec jekyll serve -l --watch --incremental --port 8080 || true
    exit 0
  ";
}
