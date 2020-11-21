#! /bin/bash

nix build
cp result/bin/hasura-cli_ext ~/.hasura/plugins/bin/hasura-cli_ext
