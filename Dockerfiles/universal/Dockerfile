FROM ubuntu:20.04 as rust-base
ENV DEBIAN_FRONTEND=noninteractive

COPY script/common.sh script/lib.sh /
RUN /common.sh
COPY script/cmake.sh /
RUN /cmake.sh

# ENV RUSTUP_DIST_SERVER="https://rsproxy.cn"
# ENV RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
ARG TOOLCHAIN_VERSION="nightly-2023-09-18"
ENV RUSTUP_HOME=/root/rustup
ENV CARGO_HOME=/root/cargo
COPY script/rust-and-xargo.sh /
ENV PATH=$CARGO_HOME/bin:$PATH
RUN /rust-and-xargo.sh ${TOOLCHAIN_VERSION}
COPY script/cargo/config.toml $CARGO_HOME/config.toml

FROM rust-base

# for darwin
ARG MACOS_SDK_DIR="."
ARG MACOS_SDK_FILE="nonexistent"
ARG MACOS_SDK_URL="https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz"
COPY $MACOS_SDK_DIR/$MACOS_SDK_FILE* /
COPY script/darwin/*.sh /
RUN /darwin.sh
RUN /darwin-symlink.sh
ENV CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=x86_64-apple-darwin20.4-clang \
    CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=aarch64-apple-darwin20.4-clang \
    PATH=$PATH:/opt/osxcross/bin

# for x86_64-pc-windows-gnu
# RUN apt update && apt install -y --no-install-recommends libz-mingw-w64-dev
RUN apt update && apt install -y --no-install-recommends \
    libz-mingw-w64-dev \
    mingw-w64 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# for i686-pc-windows-gnu , needs to be executed at the end.
COPY script/i686-mingw-w64/* /
RUN /mingw-build.sh

ENV CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc \
    CARGO_TARGET_I686_PC_WINDOWS_GNU_LINKER=i686-w64-mingw32-gcc \
    PATH=$PATH:/usr/bin/mingw-w64

# add targets
RUN rustup target add x86_64-pc-windows-gnu \
    i686-pc-windows-gnu \
    x86_64-unknown-linux-musl \
    i686-unknown-linux-musl \
    x86_64-apple-darwin \
    aarch64-apple-darwin

# for ollvm
COPY ollvm16/* /repos/
WORKDIR /repos
RUN tar xvf llvm-16.0-2023-03-06.tar && \
    rm -rf llvm-16.0-2023-03-06.tar && \
    mkdir rust-1.74.0 && \
    mv malefic-1.74.0.tar rust-1.74.0 && \
    cd rust-1.74.0 && \
    tar xvf malefic-1.74.0.tar && \
    rm -rf malefic-1.74.0.tar && \
    rustup toolchain link ollvm16-rust-1.74.0 /repos/rust-1.74.0 && \
    ln -sf $RUSTUP_HOME/toolchains/nightly-2023-09-18-x86_64-unknown-linux-gnu/bin/cargo /usr/local/bin/cargo

ENV PATH=/usr/local/bin:$PATH

WORKDIR /root/src
