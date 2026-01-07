FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG RPKI_CLIENT_VERSION=9.6

# 必要パッケージのインストール（python3 を追加）
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      ca-certificates \
      curl \
      wget \
      rsync \
      python3 \
      libssl-dev \
      libexpat1-dev \
      zlib1g-dev \
      pkg-config \
      libtls-dev \
      bash \
      ntpdate \
      iptables \
      && rm -rf /var/lib/apt/lists/*

# rpki-client が権限を落とすための _rpki-client ユーザを作成
RUN useradd -r -M -s /usr/sbin/nologin _rpki-client

# rpki-client-portable 9.6 をソースからビルド
WORKDIR /tmp/build

RUN wget https://ftp.openbsd.org/pub/OpenBSD/rpki-client/rpki-client-${RPKI_CLIENT_VERSION}.tar.gz || \
    wget https://ftp.jaist.ac.jp/pub/OpenBSD/rpki-client/rpki-client-${RPKI_CLIENT_VERSION}.tar.gz && \
    tar xzf rpki-client-${RPKI_CLIENT_VERSION}.tar.gz && \
    cd rpki-client-${RPKI_CLIENT_VERSION} && \
    ./configure && \
    make -j"$(nproc)" && \
    make install && \
    cd / && rm -rf /tmp/build

# テストスクリプト配置用ディレクトリ
WORKDIR /work

# 同じディレクトリにある .sh をすべてコンテナ内にコピー
COPY *.sh /work/
RUN chmod +x /work/*.sh

ENTRYPOINT ["/bin/bash"]

