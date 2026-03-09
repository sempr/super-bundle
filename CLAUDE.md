# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository builds an OpenWrt "super-bundle" package (.ipk) that combines multiple network proxy tools into a single installable package. The bundle includes Hysteria, Clash.Meta, mosdns v5, geodata files, the Yacd dashboard, and v2dat tools.

## Build Process

**Primary build script**: `scripts/new.sh`

This single script handles the entire build process:
1. Downloads the latest versions of all components from GitHub releases
2. Extracts and organizes files into the proper directory structure
3. Creates OpenWrt control and data archives
4. Packages them into a .ipk file
5. Generates checksums and prepares for publishing

**To build the package:**
```bash
bash scripts/new.sh
```

**Requirements:**
- curl, jq, unzip, tar, gzip, tree
- Optional: upx (for binary compression), strip (for binary stripping)
- GitHub Actions provides: ubuntu-22.04 runner

## Package Structure

The package follows OpenWrt's ipk format with:
- `control/` - Package metadata (control file)
- `data/` - Installation files organized as:
  - `data/usr/bin/` - Binaries: clash, hysteria, mosdns
  - `data/etc/geodata/` - GeoIP and GeoSite data (unpacked)
  - `data/etc/clash/` - Symlinks to geodata for Clash
  - `data/www/` - Web dashboard (yacd)

The built package is named: `super-bundle_1.0-{timestamp}.ipk`

## Components Downloaded

1. **GeoData**: From MetaCubeX/meta-rules-dat - GeoIP and GeoSite files
2. **Hysteria**: From HyNetwork/hysteria - Proxy server/client
3. **Clash.Meta**: From MetaCubeX/Clash.Meta - Rule-based proxy client
4. **Yacd**: From MetaCubeX/Yacd-meta - Web dashboard for Clash (gh-pages branch)
5. **v2dat**: From sempr/v2dat - Tool for unpacking geodata files
6. **mosdns v5**: From IrineSistiana/mosdns - DNS server

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/run.yml`) runs:
- On push to master (excluding README changes)
- Weekly on Tuesdays at 22:01 UTC
- Manual workflow_dispatch trigger

**Workflow steps:**
1. Checkout master branch
2. Run `scripts/new.sh` to build the package
3. Check if checksums changed compared to last release
4. If changed, create a new GitHub release with the package

Release tags use timestamp format: `YYYYMMDDHHMM`

## Development Notes

- The script downloads x86_64 (amd64) Linux binaries only
- Uses v2dat to unpack geodata files into more usable formats
- Creates symlinks from /etc/geodata to /etc/clash for compatibility
- Binaries are stripped and optionally compressed with UPX
- sha256sum.txt tracks binary checksums to detect changes