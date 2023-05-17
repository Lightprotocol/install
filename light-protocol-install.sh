#!/bin/bash

set -eux

PREFIX=${HOME}/.local/light-protocol
PROMPT=true
ARCH=$(uname -m)
SOLANA_VERSION="v1.15.2"
ANCHOR_VERSION="v0.27.2"

function download_file () {
    local git_repo=$1
    local git_release=$2
    local src_name=$3
    local dest_name=$4
    local dest=$5

    echo "Downloading ${dest_name}"
    curl -L \
        -o ${dest}/${dest_name} \
        https://github.com/Lightprotocol/${git_repo}/releases/download/${git_release}/${src_name}
    chmod +x ${dest}/${dest_name}
}

function download_and_extract () {
    local git_repo=$1
    local git_release=$2
    local archive_name=$3
    local dest=$4

    echo "Downloading ${archive_name}"
    curl -L https://github.com/Lightprotocol/${git_repo}/releases/download/${git_release}/${archive_name} | tar -I zstd -xvf - -C ${dest}
}

while (( "$#" )); do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --no-prompt)
      PROMPT=false
      shift
      ;;
    *)
      echo "Error: Invalid option"
      exit 1
      ;;
  esac
done

if ! rustup toolchain list 2>/dev/null | grep -q "nightly"; then
    echo "Rust nightly is not installed!"
    echo "Please install https://rustup.rs/ and then install the nightly toolchain with:"
    echo "    rustup toolchain install nightly" 
fi

case $ARCH in
    "x86_64")
        SYSTEM="linux-amd64"
        ;;
    "aarch64")
        SYSTEM="linux-arm64"
        ;;
    "arm64")
        SYSTEM="macos-arm64"
        ;;
    *)
        echo "Architecture $ARCH is not supported."
        exit 1
        ;;
esac

echo "Detected system $SYSTEM"

echo "Creating directory $PREFIX"
mkdir -p $PREFIX/bin/deps

echo "Downloading Solana toolchain"

download_and_extract \
    solana \
    ${SOLANA_VERSION} \
    solana-${SYSTEM}.tar.zst \
    ${PREFIX}/bin
download_and_extract \
    solana \
    ${SOLANA_VERSION} \
    solana-sdk-sbf-${SYSTEM}.tar.zst \
    ${PREFIX}/bin
download_and_extract \
    solana \
    ${SOLANA_VERSION} \
    solana-deps-${SYSTEM}.tar.zst \
    ${PREFIX}/bin/deps

download_file \
    anchor \
    ${ANCHOR_VERSION} \
    light-anchor-${SYSTEM} \
    light-anchor \
    ${PREFIX}/bin

echo
echo "Light Protocol toolchain installed"
echo "$PREFIX/bin needs to be added to \$PATH in your shell configuration."
echo

if [ "$PROMPT" = true ]; then
    read -p "Do you want to automatically add it to your Bash profile (~/.profile)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "export PATH=$PREFIX/bin:\$PATH" >> ~/.profile
        echo "Bash profile updated. Please restart your shell."
    fi
fi
