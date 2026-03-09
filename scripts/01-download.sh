#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

# Function to download GeoData files
download_geodata() {
    echo "Downloading GeoData files..."
    curl -OL https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat
    curl -OL https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
}

# Function to download Hysteria
download_hysteria() {
    echo "Downloading Hysteria..."
    DOWNLOAD_URL=$(curl -fsS -L https://api.github.com/repos/HyNetwork/hysteria/releases/latest | jq -r '.assets[] | select(.name | contains("hysteria-linux-amd64")) | .browser_download_url' | head -1)
    curl -fsS -OL "${DOWNLOAD_URL}"
    mv hysteria-linux-amd64 hysteria
}

# Function to download Clash.Meta
download_clashmeta() {
    echo "Downloading Clash.Meta..."
    DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/MetaCubeX/Clash.Meta/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64-compatible")) | .browser_download_url' | grep gz | head -1)
    curl -L -o clash.gz "${DOWNLOAD_URL}"
}

# Function to download Yacd dashboard
download_yacd() {
    echo "Downloading Yacd dashboard..."
    curl -OL https://github.com/MetaCubeX/Yacd-meta/archive/refs/heads/gh-pages.zip
    unzip -q gh-pages.zip
    mv Yacd-meta-gh-pages yacd
    rm -f gh-pages.zip
}

# Function to download v2dat tool
download_v2dat() {
    echo "Downloading v2dat tool..."
    DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/sempr/v2dat/releases | jq -r '.[0].assets[0].browser_download_url')
    curl -fsS -OL "${DOWNLOAD_URL}"
    chmod +x v2dat
    mkdir -p ../../tmp/bin/
    mv v2dat ../../tmp/bin/
}

# Function to download mosdns v5
download_mosdns_v5() {
    echo "Downloading mosdns v5..."
    DOWNLOAD_URL=$(curl -fsS -L https://api.github.com/repos/IrineSistiana/mosdns/releases | jq -r '.[].assets[].browser_download_url' | grep "v5.*linux-amd64" | head -1)
    curl -fsS -OL "${DOWNLOAD_URL}"
    unzip -q mosdns-linux-amd64.zip
    rm -f mosdns-linux-amd64.zip
}

# Function to download old checksums for comparison
download_old_checksums() {
    echo "Downloading old checksums..."
    DOWNLOAD_URL=$(curl -L -fsS "https://api.github.com/repos/sempr/super-bundle/releases" | grep "sha256sum.txt" | grep "browser_download_url" | head -n1 | awk '{print $2}' | tr -d '"')
    if [ -n "$DOWNLOAD_URL" ]; then
        curl -fsS -L -o ../../old.sha256sum.txt ${DOWNLOAD_URL}
    fi
}

# Install prerequisites
prepare() {
    echo "Installing prerequisites..."
    which apt && sudo apt update && sudo apt install -y upx jq
}

# Main download function
download_all() {
    echo "Starting download process..."

    # Create staging directory
    mkdir -p tmp
    pushd tmp >/dev/null

    # Download all components
    download_geodata
    download_hysteria
    download_clashmeta
    download_v2dat
    download_mosdns_v5
    download_yacd

    popd >/dev/null

    # Download old checksums for comparison
    download_old_checksums

    echo "Download completed. Files are in the 'tmp' directory."
    ls -la tmp/
}

# Main execution
prepare
download_all

echo "Download step completed successfully."
exit 0
