#!/bin/bash

set -eu

PREFIX=${HOME}/.local/light-protocol
PROMPT=true
TOOLCHAIN=true
LIGHT_PROTOCOL_PROGRAMS=true
ARCH=$(uname -m)

function latest_release() {
    local OWNER="$1"
    local REPO="$2"
    local GITHUB="https://api.github.com"

    local LATEST_RELEASE=$(curl -s $GITHUB/repos/$OWNER/$REPO/releases/latest)

    # Extract the tag name
    local TAG_NAME=$(echo "$LATEST_RELEASE" | perl -ne 'print "$1\n" if /"tag_name":\s*"([^"]*)"/' | head -1)

    echo "$TAG_NAME"
}

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
    curl -L https://github.com/Lightprotocol/${git_repo}/releases/download/${git_release}/${archive_name} | \
        tar -zxf - -C ${dest}
}

SOLANA_VERSION=$(latest_release Lightprotocol solana)
ANCHOR_VERSION=$(latest_release Lightprotocol anchor)
CIRCOM_VERSION=$(latest_release Lightprotocol circom)
MACRO_CIRCOM_VERSION=$(latest_release Lightprotocol macro-circom)
LIGHT_PROTOCOL_VERSION=$(latest_release Lightprotocol light-protocol)

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
        --skip-toolchain)
            TOOLCHAIN=false
            shift
            ;;
        --skip-light-protocol-programs)
            LIGHT_PROTOCOL_PROGRAMS=false
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

if [[ "$TOOLCHAIN" == true ]]; then
    echo "Downloading Solana toolchain"

    download_and_extract \
        solana \
        ${SOLANA_VERSION} \
        solana-${SYSTEM}.tar.gz \
        ${PREFIX}/bin
    download_and_extract \
        solana \
        ${SOLANA_VERSION} \
        solana-sdk-sbf-${SYSTEM}.tar.gz \
        ${PREFIX}/bin
    download_and_extract \
        solana \
        ${SOLANA_VERSION} \
        solana-deps-${SYSTEM}.tar.gz \
        ${PREFIX}/bin/deps

    echo "Downloading Light Anchor"
    download_file \
        anchor \
        ${ANCHOR_VERSION} \
        light-anchor-${SYSTEM} \
        light-anchor \
        ${PREFIX}/bin

    echo "Downloading Circom"
    download_file \
        circom \
        ${CIRCOM_VERSION} \
        circom-${SYSTEM} \
        circom \
        ${PREFIX}/bin

    echo "Downloading macro-circom"
    download_file \
        macro-circom \
        ${MACRO_CIRCOM_VERSION} \
        macro-circom-${SYSTEM} \
        macro-circom \
        ${PREFIX}/bin
fi

if [[ "$LIGHT_PROTOCOL_PROGRAMS" == true ]]; then
    mkdir -p $PREFIX/lib/light-protocol

    echo "Downloading Light Protocol programs"

    files=(
        merkle_tree_program.so
        verifier_program_zero.so
        verifier_program_storage.so
        verifier_program_one.so
        verifier_program_two.so
    )
    for file in "${files[@]}"; do
        download_file \
            light-protocol \
            ${LIGHT_PROTOCOL_VERSION} \
            $file \
            $file \
            ${PREFIX}/lib/light-protocol
    done
fi

echo
echo "Light Protocol toolchain installed"
echo "$PREFIX/bin needs to be added to \$PATH in your shell configuration."
echo

if [[ "$PROMPT" == true ]]; then
    read -p "Do you want to automatically add it to your Bash profile (~/.profile)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "export PATH=$PREFIX/bin:\$PATH" >> ~/.profile
        echo "Bash profile updated. Please restart your shell."
    fi
fi
