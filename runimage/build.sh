#!/bin/bash
set -e

ARCH=$(uname -m)

export AppName='GDM Settings'
export ApplicationId=io.github.realmazharhussain.GdmSettings
export RIM_NO_NVIDIA_CHECK=1

ScriptDir=$(realpath "$0" | xargs dirname)

SourceDir=${ScriptDir}
while true; do
  if test -z "${SourceDir}"; then
    echo "Could not find root directory of the source code" >&2
    exit 1
  elif test -f "${SourceDir}"/LICENSE; then
    break
  else
    SourceDir=${SourceDir%/*}
  fi
done

BuildDir=${SourceDir}/build
RunImageOutput=${BuildDir}/gdm-settings.RunImage

echo "Building RunImage for ${AppName}..."
echo "Source directory: ${SourceDir}"
echo "Build directory: ${BuildDir}"
echo

# Create build directory
mkdir -p "${BuildDir}"
cd "${BuildDir}"

# Download base RunImage if not present
if [ ! -f runimage ]; then
  echo "Downloading RunImage..."
  curl -L https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$ARCH -o runimage
  chmod +x runimage
  echo
fi

# Check if we have cached rootfs with packages
if [ ! -d rootfs-base ]; then
  # First-time setup: extract, install packages, then cache
  echo "First-time setup: extracting base image and installing packages..."
  rm -rf rootfs
  ./runimage getdimg -x rootfs archlinux:latest
  echo

  # Setup DNS resolvers
  echo "Setting up DNS resolvers..."
  echo -e 'nameserver 1.1.1.1\nnameserver 8.8.8.8' > rootfs/etc/resolv.conf
  echo

  # Install system dependencies
  echo "Installing system dependencies (will be cached)..."
  RIM_ROOT=1 ./runimage pacman -Sy --noconfirm \
    gtk4 \
    libadwaita \
    python \
    python-gobject \
    meson \
    blueprint-compiler \
    git \
    pkgconf \
    glib2 \
    gdk-pixbuf2 \
    gettext || true
  echo

  # Cache the rootfs WITH packages installed
  echo "Caching base image with packages for future builds..."
  cp -a rootfs rootfs-base
  echo
else
  # Use cached rootfs that already has packages
  echo "Using cached base image with pre-installed packages..."
  rm -rf rootfs
  cp -a rootfs-base rootfs
  echo
fi

# Copy source code into rootfs (excluding build directory)
echo
echo "Copying source code into container..."
rm -rf rootfs/tmp/gdm-settings
mkdir -p rootfs/tmp/gdm-settings
(cd "${SourceDir}" && tar --exclude='./build' --exclude='./.git' --exclude='*__pycache__*' -cf - .) | (cd rootfs/tmp/gdm-settings && tar -xf -)

# Build gdm-settings inside the container
echo
echo "Building gdm-settings..."
RIM_ROOT=1 ./runimage bash -c "
  cd /tmp/gdm-settings
  meson setup build --prefix=/usr
  meson install -C build
  glib-compile-schemas /usr/share/glib-2.0/schemas
  gtk4-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
  rm -rf /tmp/gdm-settings
"

# Verify gdm-settings was installed
echo
echo "Verifying gdm-settings installation..."
if [ ! -f rootfs/usr/bin/gdm-settings ]; then
  echo "ERROR: gdm-settings was not installed to /usr/bin/gdm-settings" >&2
  echo "Listing /usr/bin contents:"
  ls -la rootfs/usr/bin/ | head -20
  exit 1
fi
echo "✓ gdm-settings found at /usr/bin/gdm-settings"

# Shrink rootfs to reduce size
echo
echo "Shrinking rootfs..."
./runimage rim-shrink --back --docs --locales --pkgcache --pycache

# Build the final RunImage
echo
echo "Building final RunImage with compression..."
./runimage rim-build gdm-settings -c 1 -b 24

# Move to expected location
if [ -f gdm-settings ]; then
  mv gdm-settings "${RunImageOutput}"
  echo
  echo "RunImage created successfully!"
  echo "Output: ${RunImageOutput}"
  echo
  ls -lh "${RunImageOutput}"
else
  echo "Error: RunImage build failed - output file not found" >&2
  exit 1
fi

# Clean up (keep rootfs-base and runimage cached for next build)
chmod u+rw -R rootfs || true
rm -rf rootfs

echo
echo "Build complete! You can run it with:"
echo "  ${RunImageOutput}"
