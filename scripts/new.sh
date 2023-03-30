#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

download_geodata() {
    FILES=$(curl -fsS -L https://api.github.com/repos/leemars/v2ray-rules-dat/releases/latest | grep "\.dat\"" | grep "releases/download" | awk '{print $2}' | tr -d '"')
    for file in $FILES; do
        curl -OL $file
    done
}

download_xray() {
    FILES=$(curl -fsS -L https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq | grep browser_download_url | grep "Xray-linux-64.zip\"" | awk '{print $2}' | tr -d '"')
    curl -OL $FILES
    unzip -o Xray-linux-64.zip
}

download_singbox() {
    DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/SagerNet/sing-box/releases/latest  | jq | grep linux-amd64.tar | grep browser |awk '{print $2}' | tr -d '"')
    curl -L -o sing-box.tgz "${DOWNLOAD_URL}"
    tar xvzf sing-box.tgz
    mv $(find -name sing-box |head -1) .
}

download_mosdns() {
    DOWNLOAD_URL=$(curl -fsS -L https://api.github.com/repos/IrineSistiana/mosdns/releases | jq | grep browser_download_url | grep v4 | grep linux-amd64 | head -1 | awk '{print $2}' | tr -d '"')
    curl -fsS -OL "${DOWNLOAD_URL}"
    mkdir -p mosdns
    unzip -o mosdns-linux-amd64.zip -d mosdns
}

download_wstunnel() {
    DOWNLOAD_URL=$(curl -fsS -L https://api.github.com/repos/erebe/wstunnel/releases/latest | jq| grep browser_download_url | grep wstunnel-linux-x64 | head -1 |awk '{print $2}' | tr -d '"')
    curl -fsS -OL "${DOWNLOAD_URL}"
    mv wstunnel-linux-x64 wstunnel
}

download_hysteria() {
    DOWNLOAD_URL=$(curl -fsS -L https://api.github.com/repos/HyNetwork/hysteria/releases/latest |jq| grep browser_download_url | grep hysteria-linux-amd64 | head -1 |awk '{print $2}' | tr -d '"')
    curl -fsS -OL "${DOWNLOAD_URL}"
    mv hysteria-linux-amd64 hysteria
}

download_old() {
    DOWNLOAD_URL=$(curl -L -fsS "https://github.com/sempr/super-bundle/releases/latest" | grep "sha256sum.txt" | grep href | awk -F'"' '{print $2}')
    curl -fsS -L -o old.sha256sum.txt "https://github.com${DOWNLOAD_URL}"
}

download_all() {
    mkdir -p tmp
    pushd tmp
    download_hysteria
    download_xray
    download_geodata
    download_singbox
    download_wstunnel
    download_mosdns
    popd

    mkdir -p data/etc/geodata
    mkdir -p data/usr/bin

    mv tmp/{geoip,geosite}.dat data/etc/geodata/
    mv tmp/{xray,sing-box,wstunnel,hysteria,mosdns/mosdns} data/usr/bin/
    chmod +x data/usr/bin/*
    rm -rf tmp/

    tree data/
    download_old
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
    sudo apt update && sudo apt install -y upx jq
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
