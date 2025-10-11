# bootstrap.nix (one-off)
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby_3_3
    bundler
  ];

  shellHook = "
    export LC_ALL=C.UTF-8

    echo 'Will start Caddy server on port 4000 with Basic Auth...'
    read -p 'Basic Auth User: ' BASIC_AUTH_USER
    read -s -p 'Basic Auth Password: ' basic_auth_password
    echo
    password_hash=\$(caddy hash-password --plaintext \$basic_auth_password)
    export BASIC_AUTH_PASSWORD_HASH=\$password_hash

    cat > Caddyfile <<EOF
{
  admin off
}
:4000 {
  basicauth * {
    \$BASIC_AUTH_USER \$BASIC_AUTH_PASSWORD_HASH
  }
  reverse_proxy localhost:8080
}
EOF
    caddy fmt --overwrite Caddyfile

    echo 'Caddyfile created.'
    read -p 'Press Enter to start Caddy & Jekyll server...'

    caddy run --config Caddyfile &
    CADDY_PID=\$!
    trap \"
      echo Stopping Caddy server...;
      rm Caddyfile || true;
      kill \$CADDY_PID || true 2>/dev/null;
    \" EXIT

    bundle config set --local path 'vendor/bundle'
    bundle install
    bundle lock --update
    bundle exec jekyll serve -l --watch --incremental --port 8080 || true
    exit 0
  ";
}
