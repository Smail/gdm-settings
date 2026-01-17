# RunImage Build for GDM Settings

This directory contains scripts to build GDM Settings as a RunImage - a containerized application format that works across all Linux distributions without dependency conflicts.

## What is RunImage?

RunImage is a modern alternative to AppImage that uses full containerization instead of bundling libraries. Key advantages:

- **No GLibC version conflicts**: Runs the same on Ubuntu 18.04 and Ubuntu 25.10
- **Works on musl-based distros**: Alpine, Void Linux, etc.
- **No FUSE dependency**: Uses `uruntime` for extraction
- **Better compression**: DwarFS with zstd is smaller than SquashFS
- **Full isolation**: Complete Arch Linux environment prevents library conflicts

## Quick Start

### Prerequisites

Only two requirements:
- `wget` (to download RunImage)
- `bash` (to run the build script)

No system dependencies, compilers, or development packages needed!

### Build

```bash
./runimage/build.sh
```

The script will:
1. Download the RunImage base runtime
2. Create an Arch Linux container
3. Install GTK4, libadwaita, Python, and dependencies
4. Build gdm-settings inside the container
5. Create a compressed RunImage at `build/GDM_Settings.RunImage`

### Run

```bash
./build/GDM_Settings.RunImage --version
./build/GDM_Settings.RunImage
```

## How It Works

### Build Process

1. **Download RunImage**: Gets the latest RunImage runtime from GitHub
2. **OverlayFS Mode**: Launches RunImage with `RIM_OVERFS_MODE=1` to customize the rootfs
3. **Install Dependencies**: Uses `pac` (fake sudo) to install Arch packages
4. **Build Application**: Runs meson to build and install gdm-settings
5. **Compress**: Uses `rim-build` with DwarFS compression (zstd level 22, 1M blocks)

### Container Environment

The RunImage contains a complete Arch Linux environment with:
- GTK 4.10+
- libadwaita 1.4+
- Python 3 with PyGObject
- GLib, GDK-Pixbuf, and other GNOME libraries
- All language packs and schemas

## Technical Details

### RunImage Commands Used

- `pac`: Package manager wrapper (works without root inside container)
- `rim-build`: Builds the final RunImage with compression
  - `-c 22`: zstd compression level 22 (maximum)
  - `-b 1M`: DwarFS block size 1MB
  - `-z`: Enable compression

### File Structure

```
runimage/
├── build.sh           # Main build script
├── install-deps.sh    # Reference for manual builds
└── README.md          # This file
```

### Environment Variables

The build script uses:
- `RIM_OVERFS_MODE=1`: Enable OverlayFS for rootfs modification
- `OVERFS_ID`: Overlay filesystem ID (set by RunImage)

## Comparison with AppImage

| Feature | AppImage | RunImage |
|---------|----------|----------|
| GLibC dependency | ✗ Tied to build system | ✓ Isolated in container |
| musl support | ✗ No | ✓ Yes |
| FUSE required | ✓ Yes (or extract) | ✗ No (uruntime) |
| Library conflicts | ⚠ Possible | ✓ Full isolation |
| Compression | SquashFS | DwarFS (better) |
| Build complexity | High (manual bundling) | Low (package manager) |

## Verification

Test on multiple distributions:

```bash
# Ubuntu
./build/GDM_Settings.RunImage --version

# Arch Linux
./build/GDM_Settings.RunImage --version

# Alpine Linux (musl)
./build/GDM_Settings.RunImage --version

# Fedora
./build/GDM_Settings.RunImage --version
```

All should work identically without installing any dependencies.

## Troubleshooting

### Build fails to download RunImage

Ensure you have internet connectivity and wget installed:
```bash
wget --version
```

### Container fails to start

The RunImage runtime requires a modern Linux kernel (3.10+). Check:
```bash
uname -r
```

### Build completes but file not found

Check the build directory:
```bash
ls -lh build/
```

The output should be `build/GDM_Settings.RunImage`.

## Resources

- [RunImage GitHub](https://github.com/VHSgunzo/runimage)
- [RunImage Documentation](https://github.com/VHSgunzo/runimage/blob/main/README.md)
- [DwarFS](https://github.com/mhx/dwarfs)
