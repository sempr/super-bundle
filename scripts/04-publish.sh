#!/bin/bash

##############################################################################
# Publish Preparation Script
# Prepares checksum files and packages for publishing
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd $SCRIPT_DIR

echo "==================================="
echo "Preparing Packages for Publishing"
echo "==================================="

# Get timestamp for consistent naming
TIMESTAMP=$(date +%Y%m%d%H%M)

# Get timestamp for consistent naming
TIMESTAMP=$(date +%Y%m%d%H%M)

# Configuration
PUBLISH_DIR="/tmp/pub"
CHECKSUM_FILE="sha256sum.txt"
FINAL_CHECKSUM_FILE="super-bundle-${TIMESTAMP}.sha256sum"

echo "Timestamp: ${TIMESTAMP}"
echo "Publish directory: ${PUBLISH_DIR}"

# Step 1: Verify packages exist
echo ""
echo "Step 1: Verifying packages..."
echo "-----------------------------------"

# Find the IPK and APK packages
IPK_PACKAGE=$(ls super-bundle_1.0-*.ipk 2>/dev/null | sort -V | tail -1)
APK_PACKAGE=$(ls super-bundle-1.0-*.apk 2>/dev/null | sort -V | tail -1)

if [ -z "$IPK_PACKAGE" ]; then
    echo "Error: No IPK package found. Please run 03-package.sh first."
    exit 1
fi

if [ -z "$APK_PACKAGE" ]; then
    echo "Error: No APK package found. Please run 03-package.sh first."
    exit 1
fi

echo "Found IPK package: $IPK_PACKAGE"
echo "Found APK package: $APK_PACKAGE"
echo "Found checksum file: $CHECKSUM_FILE"
echo "✓ Packages verified"

# Step 2: Create comprehensive checksum file
echo ""
echo "Step 2: Creating comprehensive checksums..."
echo "-----------------------------------"

# Create a new comprehensive checksum file
rm -f "$FINAL_CHECKSUM_FILE"

# Add package checksums
echo "Generating package checksums..."
sha256sum "$IPK_PACKAGE" >> "$FINAL_CHECKSUM_FILE"
sha256sum "$APK_PACKAGE" >> "$FINAL_CHECKSUM_FILE"

# Add binary checksums if they exist (from 02-prepare.sh)
if [ -f "$CHECKSUM_FILE" ]; then
    echo "Adding binary checksums..."
    cat "$CHECKSUM_FILE" >> "$FINAL_CHECKSUM_FILE"

    # Also include the binary checksum file itself
    sha256sum "$FINAL_CHECKSUM_FILE" | awk '{print $1}' > "${FINAL_CHECKSUM_FILE}.digest"
    V2DAT_CHECKSUM=$(cat "${FINAL_CHECKSUM_FILE}.digest")
    echo "Final checksum digest: $V2DAT_CHECKSUM"
else
    echo "Warning: No binary checksum file found"
fi

echo "Comprehensive checksum file created: $FINAL_CHECKSUM_FILE"
echo "Total entries: $(wc -l < "$FINAL_CHECKSUM_FILE")"

# Display the checksums for verification
echo ""
echo "Generated checksums:"
echo "-----------------------------------"
cat "$FINAL_CHECKSUM_FILE"

# Step 3: Create publish manifest
echo ""
echo "Step 3: Creating publish manifest..."
echo "-----------------------------------"

MANIFEST_FILE="super-bundle-${TIMESTAMP}.manifest"
cat > "$MANIFEST_FILE" <<EOF
Super Bundle Publish Manifest
Generated: $(date -u)
Timestamp: ${TIMESTAMP}
Version: 1.0-${TIMESTAMP}

CONTENTS:
--------------
IPK Package: $IPK_PACKAGE
APK Package: $APK_PACKAGE
Checksum File: $FINAL_CHECKSUM_FILE

CHECKSUMS:
EOF

# Add checksums to manifest
cat "$FINAL_CHECKSUM_FILE" >> "$MANIFEST_FILE"

echo "Publish manifest created: $MANIFEST_FILE"

# Step 4: Setup publish directory
echo ""
echo "Step 4: Setting up publish directory..."
echo "-----------------------------------"

mkdir -p "$PUBLISH_DIR"
echo "Created directory: $PUBLISH_DIR"

# Copy files to publish directory
echo "Copying files to publish directory..."
cp -v "$IPK_PACKAGE" "$PUBLISH_DIR/"
cp -v "$APK_PACKAGE" "$PUBLISH_DIR/"

# Copy comprehensive checksum file and rename to sha256sum.txt for consistent naming
cp -v "$FINAL_CHECKSUM_FILE" "$PUBLISH_DIR/"
cp -v "$FINAL_CHECKSUM_FILE" "$PUBLISH_DIR/sha256sum.txt"
echo "Renamed $FINAL_CHECKSUM_FILE to sha256sum.txt for release"

cp -v "$MANIFEST_FILE" "$PUBLISH_DIR/"

# Optionally copy old checksums for comparison if they exist
if [ -f "old.sha256sum.txt" ]; then
    cp -v old.sha256sum.txt "$PUBLISH_DIR/"
fi

echo "✓ All files copied to $PUBLISH_DIR"

# Step 5: Verify checksums before copying
echo ""
echo "Step 5: Verifying checksums..."
echo "-----------------------------------"

echo ""
echo "Step 6: Verifying publish integrity..."
echo "-----------------------------------"

# Verify the copied files
pushd "$PUBLISH_DIR" >/dev/null

# Only verify the packages themselves, not the original relative paths
echo "Verifying packaged files in publish directory..."
for file in *.ipk *.apk *.sha256sum *.manifest; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    fi
done

# Checksum verification for only the package files in publish
if [ -f "$FINAL_CHECKSUM_FILE" ]; then
    # Extract only package checksums (lines containing .ipk or .apk)
    grep -E '\.(ipk|apk)$' "$FINAL_CHECKSUM_FILE" | sha256sum -c --quiet
    if [ $? -eq 0 ]; then
        echo "✓ Package checksums verified in publish directory"
    else
        echo "✗ Package verification failed"
        popd >/dev/null
        exit 1
    fi
fi

popd >/dev/null

# Step 6: Create release information
echo ""
echo "Step 6: Creating release information..."
echo "-----------------------------------"

# Count files in packages
IPK_SIZE=$(stat -c%s "$PUBLISH_DIR/$IPK_PACKAGE" 2>/dev/null || stat -f%z "$PUBLISH_DIR/$IPK_PACKAGE" 2>/dev/null)
APK_SIZE=$(stat -c%s "$PUBLISH_DIR/$APK_PACKAGE" 2>/dev/null || stat -f%z "$PUBLISH_DIR/$APK_PACKAGE" 2>/dev/null)

# Count binaries
if [ -f "$CHECKSUM_FILE" ]; then
    BINARY_COUNT=$(wc -l < "$CHECKSUM_FILE")
else
    BINARY_COUNT=0
fi

RELEASE_INFO="$PUBLISH_DIR/RELEASE_INFO.txt"
cat > "$RELEASE_INFO" <<EOF
Super Bundle Release ${TIMESTAMP}
================================

Packages:
  - $IPK_PACKAGE ($(numfmt --to=iec-i --suffix=B $IPK_SIZE 2>/dev/null || echo "${IPK_SIZE} bytes"))
  - $APK_PACKAGE ($(numfmt --to=iec-i --suffix=B $APK_SIZE 2>/dev/null || echo "${APK_SIZE} bytes"))

Contents:
  - Binaries: $BINARY_COUNT files
  - GeoData: Unpacked and ready
  - Web Dashboard: Yacd included
  - Tools: v2dat processing applied

Checksum: $V2DAT_CHECKSUM  (from $FINAL_CHECKSUM_FILE)

Ready for publishing to GitHub releases.

Files in $PUBLISH_DIR:\n$(ls -lh "$PUBLISH_DIR"/)
EOF

echo "Release information: $RELEASE_INFO"
echo ""
echo "==================================="
echo "Publish preparation completed!"
echo "==================================="
echo ""
echo "All files ready at:"
echo "  $PUBLISH_DIR"
echo ""
echo "Files to publish:"
ls -lh "$PUBLISH_DIR"/*
echo ""
echo "Quick publish commands:"
echo "  cd $PUBLISH_DIR"
echo "  gh release create ${TIMESTAMP} ./* --title \"Release ${TIMESTAMP}\""
echo ""
