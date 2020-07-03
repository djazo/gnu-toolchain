FROM alpine:3.12.0 AS bob

RUN apk add --no-cache \
  bison \
  build-base \
  ca-certificates \
  curl \
  file \
  flex \
  git \
  texinfo

ENV BINUTILS_VERSION 2.34
ENV MPFR_VERSION 4.0.2
ENV MPC_VERSION 1.1.0
ENV GMP_VERSION 6.2.0
ENV GCC_VERSION 10.1.0

RUN echo "Creating directories..." ; \
  mkdir -p /tmp/dl /tmp/src/binutils /tmp/src/gcc/mpfr /tmp/src/gcc/mpc /tmp/src/gcc/gmp

RUN echo "Downloading sources ..." ; \
  curl -s -L -o /tmp/dl/binutils.tar.bz2 "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.bz2" ; \
  curl -s -L -o /tmp/dl/mpfr.tar.bz2 "http://ftp.funet.fi/pub/gnu/ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.bz2" ; \
  curl -s -L -o /tmp/dl/mpc.tar.gz "http://ftp.funet.fi/pub/gnu/ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz" ; \
  curl -s -L -o /tmp/dl/gmp.tar.bz2 "http://ftp.funet.fi/pub/gnu/ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2" ; \
  curl -s -L -o /tmp/dl/gcc.tar.xz "http://ftp.funet.fi/pub/gnu/ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"


RUN echo "Extracting ..." ; \
  tar xjf /tmp/dl/binutils.tar.bz2 --strip-components=1 -C /tmp/src/binutils ; \
  tar xJf /tmp/dl/gcc.tar.xz --strip-components=1 -C /tmp/src/gcc ; \
  tar xjf /tmp/dl/mpfr.tar.bz2 --strip-components=1 -C /tmp/src/gcc/mpfr ; \
  tar xzf /tmp/dl/mpc.tar.gz --strip-components=1 -C /tmp/src/gcc/mpc ; \
  tar xjf /tmp/dl/gmp.tar.bz2 --strip-components=1 -C /tmp/src/gcc/gmp


RUN echo "Building binutils..." ; \
  mkdir -p /tmp/build/binutils ; \
  cd /tmp/build/binutils ; \
  /tmp/src/binutils/configure --prefix=/opt/toolchain --target=aarch64-linux-musl --disable-nls --disable-multilib --enable-gold=yes --enable-ld=yes ; \
  make -j$(nproc) ; \
  make install

ENV PATH /opt/toolchain/bin:$PATH

RUN echo "Building gcc..." ; \
  mkdir -p /tmp/build/gcc ; \
  cd /tmp/build/gcc ; \
  /tmp/src/gcc/configure --prefix=/opt/toolchain --target=aarch64-linux-musl --enable-languages=c --disable-nls --disable-multilib --disable-libssp --with-dwarf2 ; \
  make -j$(nproc) all-gcc ; \
  make install-gcc

RUN mkdir -p /opt/toolchain/etc && \
  echo "/opt/toolchain/lib" >/opt/toolchain/etc/ld-musl-x86_64.path

FROM alpine:3.12.0

COPY --from=bob /opt/toolchain /opt/toolchain

RUN apk add --no-cache \
  bison \
  flex \
  git \
  bc \
  perl \
  openssl-dev \
  make

ENV PATH /opt/toolchain/bin:$PATH

LABEL com.embeddedreality.image.maintainer="arto.kitula@gmail.com" \
  com.embeddedreality.image.title="gnu-toolchain" \
  com.embeddedreality.image.version="10.1" \
  com.embeddedreality.image.description="gcc-toolchain for cross compiling kernel"
