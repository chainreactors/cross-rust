FROM ubuntu:20.04 AS ollvm-base
WORKDIR /repos
COPY ollvm16/* ./
RUN tar zxvf llvm-16.0-2023-03-06.tar.gz \
    && mkdir rust-1.74.0 \
    && tar zxvf malefic-1.74.0.tar.gz -C rust-1.74.0

FROM ubuntu:20.04 AS rust-base
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
#COPY script/cargo/config.toml $CARGO_HOME/config.toml

FROM rust-base AS installer
RUN apt update -y && apt install wget -y

WORKDIR /src
RUN wget -O malefic-mutant https://github.com/chainreactors/malefic/releases/download/v0.1.0/malefic-mutant-x86_64-unknown-linux-musl
RUN git clone https://github.com/chainreactors/malefic.git \
    && cd /src/malefic \
    && cargo fetch

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
    && rm -rf /usr/share/doc/* /usr/share/info/* /usr/share/man/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /usr/lib/gcc/i686-w64-mingw32/9.3-win32/libgcc_eh.a /usr/lib/gcc/i686-w64-mingw32/9.3-posix/libgcc_eh.a

# for i686-pc-windows-gnu , replace libgcc_eh.a in i686-mingw-w64
COPY script/i686-mingw-w64/win32/libgcc_eh.a /usr/lib/gcc/i686-w64-mingw32/9.3-win32/libgcc_eh.a
COPY script/i686-mingw-w64/posix/libgcc_eh.a /usr/lib/gcc/i686-w64-mingw32/9.3-posix/libgcc_eh.a

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
COPY --from=ollvm-base /repos/rust-1.74.0 /repos/rust-1.74.0
COPY --from=ollvm-base /repos/llvm-16.0-2023-03-06 /repos/llvm-16.0-2023-03-06

RUN rustup toolchain link ollvm16-rust-1.74.0 /repos/rust-1.74.0

## add cache from installer
COPY --from=installer /root/cargo/registry /root/cargo/registry
COPY --from=installer /root/cargo/git /root/cargo/git
COPY --from=installer --chmod=755 /src/malefic-mutant /usr/local/bin/malefic-mutant

WORKDIR /root/src
