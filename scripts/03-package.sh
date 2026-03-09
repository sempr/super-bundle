#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

# Function to generate timestamp-based tag name
get_tag_name() {
    echo $(date +%Y%m%d%H%M)
}

# Function to write OpenWrt control file
write_control_file() {
    TAG_NAME=$(get_tag_name)
    mkdir -p control

    cat <<EOF >control/control
Package: super-bundle
Version: 1.0-${TAG_NAME}
SourceName: super-bundle
Architecture: x86_64
Description: super-bundle
EOF
}

# Function to apply optimizations to binaries
stage_data() {
    echo "Applying optimizations to binaries..."
    pushd data >/dev/null
    which strip >/dev/null 2>&1 && strip ./usr/bin/* 2>/dev/null
    which upx >/dev/null 2>&1 && upx ./usr/bin/* 2>/dev/null
    popd >/dev/null
}

# Function to create IPK package (OpenWrt format)
pack_ipk() {
    echo "Creating IPK package..."
    TAG_NAME=$(get_tag_name)
    write_control_file
    stage_data

    # Create IPK package (Debian format)
    pushd control >/dev/null
    tar -czf ../control.tar.gz ./*
    popd >/dev/null

    pushd data >/dev/null
    tar -czf ../data.tar.gz ./*
    popd >/dev/null

    echo "2.0" >debian-binary
    tar -czf super-bundle_1.0-${TAG_NAME}.ipk ./control.tar.gz ./data.tar.gz ./debian-binary

    echo "IPK package created: super-bundle_1.0-${TAG_NAME}.ipk"
}

# Function to create APK package (Alpine format)
pack_apk() {
    echo "Creating APK package..."
    TAG_NAME=$(get_tag_name)
    VERSION="1.0-${TAG_NAME}"
    APK_NAME="super-bundle-${VERSION}.apk"

    stage_data

    # Create APK package (Alpine format)
    mkdir -p apk-build

    # Create .PKGINFO file
    cat > apk-build/.PKGINFO <<EOF
pkgname = super-bundle
pkgver = ${VERSION}
pkgdesc = super-bundle
arch = x86_64
origin = super-bundle
maintainer = super-bundle
EOF

    # Copy data files to APK build directory
    cp -r data/* apk-build/

    # Create APK archive (single tar.gz containing everything)
    tar -C apk-build -czf "${APK_NAME}" .

    # Clean temp dir
    rm -rf apk-build

    echo "APK package created: ${APK_NAME}"
}

# Function to create both packages
pack() {
    # Check if data directory exists
    if [ ! -d "data" ]; then
        echo "Error: 'data' directory not found. Please run 02-prepare.sh first."
        exit 1
    fi

    # Check if binaries exist
    if [ ! -d "data/usr/bin" ] || [ -z "$(ls data/usr/bin)" ]; then
        echo "Error: No binaries found in data/usr/bin. Please run 02-prepare.sh first."
        exit 1
    fi

    echo "Starting package creation process..."
    pack_ipk
    pack_apk
}

# Function to clean up packaging artifacts
pack_clean() {
    echo "Cleaning up packaging artifacts..."
    rm -rf control
    rm -f control.tar.gz data.tar.gz debian-binary
}

# Function to move packages to publish directory
move_to_publish() {
    echo "Moving packages to publish directory..."
    TAG_NAME=$(get_tag_name)
    mkdir -p /tmp/pub
    cp super-bundle_1.0-${TAG_NAME}.ipk /tmp/pub/ 2>/dev/null
    cp super-bundle-1.0-${TAG_NAME}.apk /tmp/pub/ 2>/dev/null
    cp sha256sum.txt /tmp/pub/ 2>/dev/null
    echo "Packages and checksums copied to /tmp/pub/"
}

# Main execution
echo "Starting packaging process..."

pack
pack_clean
move_to_publish

# Generate final checksums including packages
echo "Generating final checksums..."
TAG_NAME=$(get_tag_name)
sha256sum super-bundle_1.0-${TAG_NAME}.ipk super-bundle-1.0-${TAG_NAME}.apk >>sha256sum.txt 2>/dev/null

echo ""
echo "Packaging completed successfully!"
echo "Created packages:"
ls -la super-bundle_*.ipk super-bundle_*.apk 2>/dev/null
echo ""
echo "Checksums saved to sha256sum.txt"

exit 0
