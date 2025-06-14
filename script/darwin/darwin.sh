#!/usr/bin/env bash

set -x
set -eo pipefail

# shellcheck disable=SC1091
. lib.sh

if [[ "${MACOS_SDK_FILE}" == "nonexistent" ]] && [[ -z "${MACOS_SDK_URL}" ]]; then
    echo 'Must set the environment variable `MACOS_SDK_FILE` or `MACOS_SDK_URL`.' 1>&2
    exit 1
fi

main() {
    local commit=ff8d100f3f026b4ffbe4ce96d8aac4ce06f1278b

    install_packages curl \
        gcc \
        g++ \
        make \
        patch \
        xz-utils \
        python3

    apt update
    apt install -y --no-install-recommends clang \
        libmpc-dev \
        libmpfr-dev \
        libgmp-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev

    local td
    td="$(mktemp -d)"

    pushd "${td}"
    git clone https://github.com/tpoechtrager/osxcross --depth 1
    cd osxcross
    git fetch --depth=1 origin "${commit}"
    git checkout "${commit}"

    if [[ -f /"${MACOS_SDK_FILE}" ]]; then
        cp /"${MACOS_SDK_FILE}" tarballs/
    else
        pushd tarballs
        curl --retry 4 -sSfL "${MACOS_SDK_URL}" -O
        popd
    fi

    mkdir -p /opt/osxcross
    TARGET_DIR=/opt/osxcross UNATTENDED=yes OSX_VERSION_MIN=10.7 ./build.sh
    # delete man pages to reduce image size
    rm -rf /opt/osxcross/SDK/MacOSX11.3.sdk/usr/share/man
    
    purge_packages

    apt clean
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
    
    popd

    rm -rf "${td}"
    rm "${0}"
}

main "${@}"
