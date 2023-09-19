#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

download_geodata() {
    curl -OL https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat
    curl -OL https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
}

download_clashmeta() {
    DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/MetaCubeX/Clash.Meta/releases/latest  | jq | grep clash.meta-linux-amd64-compatible | grep browser |awk '{print $2}' | tr -d '"')
    curl -L -o clash.gz "${DOWNLOAD_URL}"
    gunzip clash.gz
    chmod +x clash
    mv $(find -name clash |head -1) .
}

download_yacd() {
  curl -OL https://github.com/MetaCubeX/Yacd-meta/archive/refs/heads/gh-pages.zip
  mkdir -p yacd
  pushd yacd
    unzip -j ../gh-pages.zip
  popd
}

download_mosdns() {
    DOWNLOAD_URL=$(curl -fsS -L https://api.github.com/repos/IrineSistiana/mosdns/releases | jq | grep browser_download_url | grep v4 | grep linux-amd64 | head -1 | awk '{print $2}' | tr -d '"')
    curl -fsS -OL "${DOWNLOAD_URL}"
    mkdir -p mosdns
    unzip -o mosdns-linux-amd64.zip -d mosdns
}

download_old() {
    DOWNLOAD_URL=$(curl -L -fsS "https://github.com/sempr/super-bundle/releases/latest" | grep "sha256sum.txt" | grep href | awk -F'"' '{print $2}')
    curl -fsS -L -o old.sha256sum.txt "https://github.com${DOWNLOAD_URL}"
}

download_all() {
    mkdir -p tmp
    pushd tmp
    download_geodata
    download_clashmeta
    download_mosdns
    download_yacd
    popd

    mkdir -p data/etc/geodata
    mkdir -p data/usr/bin
    mkdir -p data/etc/clash
    mkdir -p data/www/

    mv tmp/yacd data/www/

    mv tmp/{geoip,geosite}.dat data/etc/geodata/
    ln -sf /etc/geodata/geoip.dat data/etc/clash/
    ln -sf /etc/geodata/geosite.dat data/etc/clash/
    mv tmp/{mosdns/mosdns,clash} data/usr/bin/
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
