#!/usr/bin/env bash

currentdir=$(pwd)

if [ ! -f $HOME/.bash_profile ]; then
  echo "Linking bash profile"
  ln -s $currentdir/bash_profile $HOME/.bash_profile
fi

if [ ! -f $HOME/.bash_aliases ]; then
  echo "Linking bash aliases"
  ln -s $currentdir/bash_aliases $HOME/.bash_aliases
fi

if [ ! -f $HOME/.asdfrc ]; then
  echo "Linking asdfrc"
  ln -s $currentdir/asdfrc $HOME/.asdfrc
fi

if [ -x "$(command -v apt)" ]; then
  sudo apt update
  sudo apt install -y curl git build-essential zlib1g-dev libssl-dev libffi-dev silversearch-ag unzip
fi

if [ ! -x "$(command -v win32yank.exe)" ]; then
  curl -L https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip --output win32yank-x64.zip
  mkdir tmp
  unzip -d tmp win32yank-x64.zip
  chmod 0755 tmp/win32yank.exe
  mv tmp/win32yank.exe /usr/local/bin/
  rm -r tmp win32yank-x64.zip
fi

if [ ! -x "$(command -v asdf)" ]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf
  cd ~/.asdf
  git checkout "$(git describe --abbrev=0 --tags)"
fi

echo "Installing NVM and Yarn..."
./scripts/yarn.sh

echo "Installing Python..."
./scripts/python.sh

echo "Setting up neovim..."
./scripts/install_neovim.sh

echo "Setting up WezTerm..."
./scripts/install_wezterm.sh

echo "Setting up git..."
./scripts/git.sh

. $HOME/.bash_profile
