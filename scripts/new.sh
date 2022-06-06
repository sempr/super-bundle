#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

download_geodata() {
    FILES=$(curl -fsS -L https://github.com/leemars/v2ray-rules-dat/releases/latest | grep "\.dat\"" | grep "releases/download" | awk -F"href=\"" '{print $2}' | awk -F"\"" '{print $1}')
    for file in $FILES; do
        curl -OL https://github.com$file
    done
}

download_xray() {
    FILES=$(curl -fsS -L https://github.com/XTLS/Xray-core/releases/latest | grep "Xray-linux-64.zip\"" | awk -F"href=\"" '{print $2}' | awk -F"\"" '{print $1}')
    curl -OL https://github.com/$FILES
    unzip -o Xray-linux-64.zip
}

download_clash() {
    DOWNLOAD_URL=$(curl -fsS -L https://github.com/Dreamacro/clash/releases/latest | grep "clash-linux-amd64" | awk -F"href=\"" '{print $2}' | awk -F"\"" '{print $1}')
    curl -L -o clash.gz "https://github.com${DOWNLOAD_URL}"
    gunzip clash.gz
}

download_clashpro() {
    DOWNLOAD_URL=$(curl -fsS -L https://github.com/Dreamacro/clash/releases/premium | grep "clash-linux-amd64" | awk -F"\"" '{print $2}' | head -1 | awk -F"\"" '{print $1}' | tr -d "'")
    curl -L -o clash.gz "https://github.com${DOWNLOAD_URL}"
    gunzip clash.gz

}

download_mosdns() {
    DOWNLOAD_URL=$(curl -fsS -L https://github.com/IrineSistiana/mosdns/releases/latest | grep mosdns-linux-amd64 | head -1 | awk -F"\"" '{print $2}')
    curl -fsS -OL "https://github.com${DOWNLOAD_URL}"
    mkdir -p mosdns
    unzip -o mosdns-linux-amd64.zip -d mosdns
}

download_wstunnel() {
    DOWNLOAD_URL=$(curl -fsS -L https://github.com/erebe/wstunnel/releases/latest | grep wstunnel-x64-linux | head -1 | awk -F"href=\"" '{print $2}' | awk -F"\"" '{print $1}')
    curl -fsS -OL "https://github.com${DOWNLOAD_URL}"
    mv wstunnel-x64-linux wstunnel
}

download_hysteria() {
    DOWNLOAD_URL=$(curl -fsS -L https://github.com/HyNetwork/hysteria/releases/latest | grep hysteria-linux-amd64 | head -1 | awk -F"href=\"" '{print $2}' | awk -F"\"" '{print $1}')
    curl -fsS -OL "https://github.com${DOWNLOAD_URL}"
    mv hysteria-linux-amd64 hysteria
}

download_all() {
    mkdir -p tmp
    pushd tmp
    download_hysteria
    download_xray
    download_geodata
    download_clashpro
    download_wstunnel
    download_mosdns
    popd

    mkdir -p data/etc/geodata
    mkdir -p data/usr/bin

    mv tmp/{geoip,geosite}.dat data/etc/geodata/
    mv tmp/{xray,clash,wstunnel,hysteria,mosdns/mosdns} data/usr/bin/
    chmod +x data/usr/bin/*
    rm -rf tmp/

    tree data/
    sha256sum data/usr/bin/* >sha256sum.txt
}

pack() {
    mkdir -p control

    TAG_NAME=$(date +%Y%m%d%H%M)
    cat <<EOF >control/control
Package: super-bundle
Version: 1.0-${TAG_NAME}
SourceName: super-bundle
Architecture: x86_64
Description:  super-bundle
EOF
    pushd control
    tar cvzf ../control.tar.gz ./*
    popd

    pushd data
    which strip >/dev/null 2>&1 && strip ./usr/bin/*
    which upx >/dev/null 2>&1 && upx ./usr/bin/*
    tar cvzf ../data.tar.gz ./*
    popd
    echo 2.0 >debian-binary
    tar cvzf super-bundle_1.0-${TAG_NAME}.ipk ./control.tar.gz ./data.tar.gz ./debian-binary
}

pack_clean() {
    rm -rf data control
    rm -f control.tar.gz data.tar.gz debian-binary
}

prepare() {
    apt update && apt install -y upx
}

move_to_publish() {
    mkdir -p /tmp/pub
    cp super-bundle_1.0-${TAG_NAME}.ipk /tmp/pub/
    cp sha256sum.txt /tmp/pub/
}

prepare
download_all
pack
pack_clean
move_to_publish

exit 0
