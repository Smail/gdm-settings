## Build Methods

There are two ways to build portable packages for GDM Settings:

1. **RunImage** (Recommended) - Modern containerized format with no dependency conflicts
2. **AppImage** (Legacy) - Traditional bundled format with potential GLibC issues

## RunImage Build (Recommended)

### Overview

RunImage creates a fully containerized application that works across all Linux distributions without any dependency conflicts. It uses an Arch Linux container with complete isolation.

### Advantages

- ✓ No GLibC version conflicts (works on Ubuntu 18.04 through 25.10+)
- ✓ Works on musl-based distros (Alpine, Void Linux)
- ✓ No FUSE dependency (uses uruntime)
- ✓ Better compression than AppImage (DwarFS with zstd)
- ✓ Full library isolation prevents conflicts
- ✓ Simpler build process (no manual dependency bundling)

### Prerequisites

Only two requirements:
- `wget` (to download RunImage runtime)
- `bash` (to run the build script)

**No system dependencies, compilers, or development packages needed!**

### Build Command

```bash
./runimage/build.sh
```

### Output

The RunImage will be created at `build/GDM_Settings.RunImage`

### Testing

```bash
./build/GDM_Settings.RunImage --version
./build/GDM_Settings.RunImage
```

### More Information

See [runimage/README.md](runimage/README.md) for detailed documentation.

---

## AppImage Build (Legacy)

**Note**: The AppImage build is maintained for compatibility but may have GLibC version conflicts across distributions. Consider using RunImage instead.

### Dependencies

#### AppImageTool

We need to install `appimagetool` for packaging the appimage.
It is (as of now) not available in the package managers of Arch or Ubuntu.

```bash
wget https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage

# Verify checksums
echo "ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0  appimagetool-x86_64.AppImage" | sha256sum --check

chmod +x appimagetool-x86_64.AppImage

mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
```

### Arch

```bash
sudo pacman -Sy pkgconf gdk-pixbuf2 glib2-devel meson blueprint-compiler

# Fix gdk-pixbuf2 loaders missing
sudo mkdir -p /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders
sudo gdk-pixbuf-query-loaders --update-cache
```

### Ubuntu 25.10

```bash
# Required for the Meson build
sudo apt install meson libadwaita-1-dev sassc libgtk-4-dev python-gi-dev blueprint-compiler gettext

# Required for building the appimage
sudo apt install libnss-db gir1.2-rsvg-2.0 gir1.2-tracker-3.0 libturbojpeg0 gir1.2-cloudproviders-0.3.0 tinysparql
```

### Build

Run `./appimage/build.sh`

**Output**: `build/GDM_Settings.AppImage`

### Known Issues (AppImage only)

If you get the error `libc.mo` or `glib20.mo` not found, then you're missing language packs.
This issue commonly occurs in minimal Linux installations or containers where language packs aren't installed by default.
Install a language pack, e.g., `apt install language-pack-en language-pack-en-base language-pack-gnome-en-base`

**Note**: RunImage builds do not have these issues as all dependencies are containerized.
