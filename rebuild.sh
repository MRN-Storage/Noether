#!/usr/bin/env bash

pushd /etc/nixos
sudo git status
sudo git pull

sudo nixos-rebuild switch --flake .#nas
popd
