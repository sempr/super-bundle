#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

# Function to uncompress and prepare all downloaded files
prepare_files() {
    echo "Starting file preparation..."

    # Check if download directory exists
    if [ ! -d "tmp" ]; then
        echo "Error: 'tmp' directory not found. Please run 01-download.sh first."
        exit 1
    fi

    # Create data directories
    echo "Creating data directory structure..."
    mkdir -p data/etc/geodata
    mkdir -p data/usr/bin
    mkdir -p data/etc/clash
    mkdir -p data/www/

    # Uncompress clash binary
    echo "Uncompressing Clash binary..."
    if [ -f "tmp/clash.gz" ]; then
        gunzip tmp/clash.gz
        chmod +x tmp/clash
    fi

    # Move Yacd dashboard
    echo "Moving Yacd dashboard..."
    if [ -d "tmp/yacd" ]; then
        mv tmp/yacd data/www/
        ln -sf yacd data/www/
    fi

    # Move geodata files
    echo "Moving geodata files..."
    if [ -f "tmp/geoip.dat" ] && [ -f "tmp/geosite.dat" ]; then
        mv tmp/{geoip,geosite}.dat data/etc/geodata/
    fi

    # Unpack geodata files using v2dat
    echo "Unpacking geodata files with v2dat..."
    if [ -f "/tmp/bin/v2dat" ] && [ -f "data/etc/geodata/geoip.dat" ]; then
        /tmp/bin/v2dat unpack geoip -o data/etc/geodata data/etc/geodata/geoip.dat
        /tmp/bin/v2dat unpack geosite -o data/etc/geodata data/etc/geodata/geosite.dat
    else
        echo "Warning: v2dat or geodata files not found, skipping unpack"
    fi

    # Create symlinks for Clash compatibility
    echo "Creating symlinks for Clash compatibility..."
    ln -sf /etc/geodata/geoip.dat data/etc/clash/
    ln -sf /etc/geodata/geosite.dat data/etc/clash/

    # Move binaries to their destination
    echo "Moving binaries..."
    if [ -f "tmp/mosdns" ]; then
        mv tmp/mosdns data/usr/bin/
    fi
    if [ -f "tmp/clash" ]; then
        mv tmp/clash data/usr/bin/
    fi
    if [ -f "tmp/hysteria" ]; then
        mv tmp/hysteria data/usr/bin/
    fi

    # Set executable permissions on binaries
    chmod +x data/usr/bin/* 2>/dev/null

    # Clean up temp directory
    rm -rf tmp/

    echo "File preparation completed successfully."
    echo "Directory structure:"
    tree -L 2 data/usr/bin/
    tree -L 1 data/etc/
}

# Function to generate checksums
generate_checksums() {
    echo "Generating checksums for binaries..."
    sha256sum data/usr/bin/* >sha256sum.txt
    echo "Checksums saved to sha256sum.txt"
}

# Main execution
prepare_files
generate_checksums

echo "\nPreparation step completed successfully."
echo "Files are ready in the 'data' directory for packaging."
exit 0
