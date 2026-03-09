# Build Scripts

This directory contains the build scripts for creating the OpenWrt super-bundle package.

## Scripts Overview

### `full-build.sh` (Recommended)
Complete build pipeline that runs all four steps in sequence:
```bash
./scripts/full-build.sh -p    # Full build with publish preparation
./scripts/full-build.sh       # Build without publish
./scripts/full-build.sh -s download     # Skip download, run prepare, package
./scripts/full-build.sh --help          # Show all options
```

### `build.sh`
Master build script that runs the first three steps (download, prepare, package):
```bash
./scripts/build.sh
```

### `04-publish.sh`
Prepares packages and checksums for publishing:
- Creates comprehensive checksum file
- Generates publish manifest
- Copies files to publish directory (/tmp/pub)
- Creates release information file
- Verifies package integrity

Usage:
```bash
./scripts/04-publish.sh
```

Output:
- Comprehensive checksum file: `super-bundle-{timestamp}.sha256sum`
- Publish manifest: `super-bundle-{timestamp}.manifest`
- Release information: `RELEASE_INFO.txt`
- All files ready in `/tmp/pub/` directory

### Individual Step Scripts

#### Step 1: `01-download.sh`
Downloads all components from their respective GitHub repositories:
- GeoData files (geoip.dat, geosite.dat)
- Hysteria (proxy server/client)
- Clash.Meta (rule-based proxy client)
- Yacd dashboard (web UI for Clash)
- v2dat tool (for unpacking geodata)
- mosdns v5 (DNS server)

Usage:
```bash
./scripts/01-download.sh
```

Output: All files downloaded to `scripts/tmp/` directory

#### Step 2: `02-prepare.sh`
Uncompresses, processes, and organizes all downloaded files:
- Uncompresses downloaded archives
- Moves files to proper directory structure
- Unpacks geodata files using v2dat
- Creates necessary symlinks
- Sets executable permissions
- Generates checksums

Usage:
```bash
./scripts/02-prepare.sh
```

Output: Organized files in `scripts/data/` directory, checksums in `scripts/sha256sum.txt`

#### Step 3: `03-package.sh`
Creates the final installable packages:
- Optimizes binaries (strip, upx if available)
- Creates `.ipk` package (OpenWrt format)
- Creates `.apk` package (Alpine Linux format)
- Generates final checksums
- Moves packages to `/tmp/pub/` (optional)

Usage:
```bash
./scripts/03-package.sh
```

Output: `super-bundle_1.0-{timestamp}.ipk` and `super-bundle-1.0-{timestamp}.apk`

## Usage Examples

### Full Build with All Steps
```bash
cd scripts
./full-build.sh -p           # Download, prepare, package, and prepare for publish
./full-build.sh                # Download, prepare, and package only
./full-build.sh --help         # Show all options
```

### Run Individual Steps
```bash
cd scripts
./01-download.sh              # Download components
./02-prepare.sh               # Prepare files
./03-package.sh               # Create packages
./04-publish.sh               # Prepare for publishing
```

### Quick Build
```bash
cd scripts
./build.sh                     # Run steps 1-3 (no publish)
```

### Skip Specific Steps
```bash
./full-build.sh -p -s download     # Skip download, run prepare, package, publish
./full-build.sh -s prepare       # Skip prepare, run download, package
./full-build.sh -p -s package    # Run download, prepare, publish (skip package)
```

## Build Requirements

### Required Tools
- `curl` - For downloading files
- `jq` - For parsing GitHub API responses
- `unzip` - For extracting zip archives
- `tar` - For creating archives
- `gzip` - For compression
- `tree` - For displaying directory structure (optional)

### Optional Tools
- `upx` - For binary compression
- `strip` - For stripping debug symbols from binaries

### System Requirements
- Linux or macOS
- Bash shell
- Network access to GitHub

## Usage Examples

### Full Build
```bash
cd scripts
./build.sh
```

### Individual Steps (for debugging or customization)
```bash
cd scripts
./01-download.sh    # Download only
./02-prepare.sh     # Prepare only
./03-package.sh     # Package only
```

### Clean Build
To start fresh, remove all generated files:
```bash
cd scripts
rm -rf tmp/ data/ control/ apk-build/
rm -f *.ipk *.apk *.tar.gz debian-binary sha256sum.txt
```

## Output Files

After successful build:

**In the current directory:**
- `super-bundle_1.0-{timestamp}.ipk` - OpenWrt package
- `super-bundle_1.0-{timestamp}.apk` - Alpine package
- `sha256sum.txt` - Checksums of all binaries and packages

**In `/tmp/pub/` (if `move_to_publish` is called):**
- Copies of the above files

## Troubleshooting

### "tmp directory not found" error
Run `./01-download.sh` first to download components.

### "data directory not found" error
Run `./02-prepare.sh` first to prepare the downloaded files.

### Download failures
Check network connectivity and GitHub API rate limits.

### Missing tools
Install required tools:
```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y curl jq unzip tar gzip

# RHEL/CentOS/Fedora
sudo yum install -y curl jq unzip tar gzip

# Optional: upx for compression
sudo apt install -y upx  # or equivalent for your distro
```
