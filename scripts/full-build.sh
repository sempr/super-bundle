#!/bin/bash

##############################################################################
# Full Build Pipeline Script
# Runs the complete build process from download to publish preparation
##############################################################################

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Parse arguments
PUBLISH=false
SKIP_STEP=null

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -p, --publish      Include publish preparation step (step 4)"
    echo "  -s, --skip STEP    Skip a specific step (download, prepare, package, publish)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run steps 1-3 (download, prepare, package)"
    echo "  $0 -p                 # Run all 4 steps including publish"
    echo "  $0 -s download         # Skip download, run prepare, package, (publish if -p)"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--publish)
            PUBLISH=true
            shift
            ;;
        -s|--skip)
            SKIP_STEP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo ""
print_header "Super Bundle Full Build Pipeline"
echo ""
echo "Configuration:"
echo "  Publish step: $([ "$PUBLISH" = true ] && echo "enabled" || echo "disabled")"
echo "  Skip step: ${SKIP_STEP}"
echo ""

# Step 1: Download
if [ "$SKIP_STEP" != "download" ]; then
    print_header "Step 1/4: Downloading Components"
    ./01-download.sh
else
    print_warning "Skipping download step"
fi

# Step 2: Prepare
if [ "$SKIP_STEP" != "prepare" ]; then
    print_header "Step 2/4: Preparing Files"
    ./02-prepare.sh
else
    print_warning "Skipping prepare step"
fi

# Step 3: Package
if [ "$SKIP_STEP" != "package" ]; then
    print_header "Step 3/4: Creating Packages"
    ./03-package.sh
else
    print_warning "Skipping package step"
fi

# Step 4: Publish Preparation (optional)
if [ "$PUBLISH" = true ]; then
    if [ "$SKIP_STEP" != "publish" ]; then
        print_header "Step 4/4: Preparing for Publishing"
        ./04-publish.sh
    else
        print_warning "Skipping publish step"
    fi
fi

# Final summary
print_header "Build Pipeline Completed!"
echo ""
echo "Results:"

# Find packages
IPK_FILE=$(ls super-bundle_1.0-*.ipk 2>/dev/null | sort -V | tail -1)
APK_FILE=$(ls super-bundle-1.0-*.apk 2>/dev/null | sort -V | tail -1)

if [ -n "$IPK_FILE" ]; then
    IPK_SIZE=$(stat -c%s "$IPK_FILE" 2>/dev/null || stat -f%z "$IPK_FILE" 2>/dev/null || echo 0)
    IPK_SIZE_H=$(numfmt --to=iec-i --suffix=B "$IPK_SIZE" 2>/dev/null || echo "${IPK_SIZE} bytes")
    print_success "IPK Package: $IPK_FILE ($IPK_SIZE_H)"
fi

if [ -n "$APK_FILE" ]; then
    APK_SIZE=$(stat -c%s "$APK_FILE" 2>/dev/null || stat -f%z "$APK_FILE" 2>/dev/null || echo 0)
    APK_SIZE_H=$(numfmt --to=iec-i --suffix=B "$APK_SIZE" 2>/dev/null || echo "${APK_SIZE} bytes")
    print_success "APK Package: $APK_FILE ($APK_SIZE_H)"
fi

if [ "$PUBLISH" = true ]; then
    if [ -d "/tmp/pub" ]; then
        print_success "Publish directory: /tmp/pub (ready for publishing)"
    fi

    # Show manifest if exists
    MANIFEST=$(ls super-bundle-*.manifest 2>/dev/null | sort -V | tail -1)
    if [ -n "$MANIFEST" ]; then
        print_success "Publish manifest: $MANIFEST"
    fi
fi

echo ""
echo "Available commands:"
echo "  ./scripts/full-build.sh -p    # Full build with publish"
echo "  ./scripts/full-build.sh       # Build without publish"
echo ""

print_success "All done!"
echo ""
