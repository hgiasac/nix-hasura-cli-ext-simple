{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./ext-cli.nix {}
