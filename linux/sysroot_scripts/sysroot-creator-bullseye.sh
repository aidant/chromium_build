#!/bin/bash
# Copyright 2022 The Chromium Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DISTRO=debian
DIST=bullseye

# This number is appended to the sysroot key to cause full rebuilds.  It
# should be incremented when removing packages or patching existing packages.
# It should not be incremented when adding packages.
SYSROOT_RELEASE=1

ARCHIVE_TIMESTAMP=20221105T211506Z
ARCHIVE_URL="https://snapshot.debian.org/archive/debian/$ARCHIVE_TIMESTAMP/"
APT_SOURCES_LIST=(
  # Debian 12 (Bookworm) is needed for GTK4.  It should be kept before bullseye
  # so that bullseye takes precedence.
  "${ARCHIVE_URL} bookworm main"
  "${ARCHIVE_URL} bookworm-updates main"

  # Debian 9 (Stretch) is needed for gnome-keyring.  It should be kept before
  # bullseye so that bullseye takes precedence.
  "${ARCHIVE_URL} stretch main"
  "${ARCHIVE_URL} stretch-updates main"

  # This mimicks a sources.list from bullseye.
  "${ARCHIVE_URL} bullseye main contrib non-free"
  "${ARCHIVE_URL} bullseye-updates main contrib non-free"
  "${ARCHIVE_URL} bullseye-backports main contrib non-free"
)

# gpg keyring file generated using generate_keyring.sh
KEYRING_FILE="${SCRIPT_DIR}/keyring.gpg"

HAS_ARCH_AMD64=1
HAS_ARCH_I386=1
HAS_ARCH_ARM=1
HAS_ARCH_ARM64=1
HAS_ARCH_ARMEL=1
HAS_ARCH_MIPS=1
HAS_ARCH_MIPS64EL=1

# Sysroot packages: these are the packages needed to build chrome.
DEBIAN_PACKAGES="\
  comerr-dev
  krb5-multidev
  libasound2
  libasound2-dev
  libasyncns0
  libatk-bridge2.0-0
  libatk-bridge2.0-dev
  libatk1.0-0
  libatk1.0-dev
  libatomic1
  libatspi2.0-0
  libatspi2.0-dev
  libattr1
  libaudit1
  libavahi-client3
  libavahi-common3
  libblkid-dev
  libblkid1
  libbluetooth-dev
  libbluetooth3
  libbrotli-dev
  libbrotli1
  libbsd0
  libc6
  libc6-dev
  libcairo-gobject2
  libcairo-script-interpreter2
  libcairo2
  libcairo2-dev
  libcap-dev
  libcap-ng0
  libcap2
  libcloudproviders0
  libcolord2
  libcom-err2
  libcrypt-dev
  libcrypt1
  libcups2
  libcups2-dev
  libcupsimage2
  libcupsimage2-dev
  libcurl3-gnutls
  libcurl4-gnutls-dev
  libdatrie-dev
  libdatrie1
  libdb5.3
  libdbus-1-3
  libdbus-1-dev
  libdbus-glib-1-2
  libdbusmenu-glib-dev
  libdbusmenu-glib4
  libdbusmenu-gtk3-4
  libdbusmenu-gtk4
  libdeflate-dev
  libdeflate0
  libdouble-conversion3
  libdrm-amdgpu1
  libdrm-dev
  libdrm-nouveau2
  libdrm-radeon1
  libdrm2
  libegl-dev
  libegl1
  libegl1-mesa
  libegl1-mesa-dev
  libelf-dev
  libelf1
  libepoxy-dev
  libepoxy0
  libevdev-dev
  libevdev2
  libevent-2.1-7
  libexpat1
  libexpat1-dev
  libffi-dev
  libffi7
  libflac-dev
  libflac8
  libfontconfig-dev
  libfontconfig1
  libfreetype-dev
  libfreetype6
  libfribidi-dev
  libfribidi0
  libgbm-dev
  libgbm1
  libgcc-10-dev
  libgcc-s1
  libgcrypt20
  libgcrypt20-dev
  libgdk-pixbuf-2.0-0
  libgdk-pixbuf-2.0-dev
  libgl-dev
  libgl1
  libgl1-mesa-dev
  libgl1-mesa-glx
  libglapi-mesa
  libgles-dev
  libgles1
  libgles2
  libglib2.0-0
  libglib2.0-dev
  libglvnd-dev
  libglvnd0
  libglx-dev
  libglx0
  libgmp10
  libgnome-keyring-dev
  libgnome-keyring0
  libgnutls-dane0
  libgnutls-openssl27
  libgnutls28-dev
  libgnutls30
  libgnutlsxx28
  libgomp1
  libgpg-error-dev
  libgpg-error0
  libgraphene-1.0-0
  libgraphene-1.0-dev
  libgraphite2-3
  libgraphite2-dev
  libgssapi-krb5-2
  libgssrpc4
  libgtk-3-0
  libgtk-3-dev
  libgtk-4-1
  libgtk-4-dev
  libgtk2.0-0
  libgudev-1.0-0
  libharfbuzz-dev
  libharfbuzz-gobject0
  libharfbuzz-icu0
  libharfbuzz0b
  libhogweed6
  libice6
  libicu-le-hb0
  libicu67
  libidl-2-0
  libidn11
  libidn2-0
  libinput-dev
  libinput10
  libjbig-dev
  libjbig0
  libjpeg62-turbo
  libjpeg62-turbo-dev
  libjson-glib-1.0-0
  libjsoncpp-dev
  libjsoncpp24
  libk5crypto3
  libkadm5clnt-mit12
  libkadm5srv-mit12
  libkdb5-10
  libkeyutils1
  libkrb5-3
  libkrb5-dev
  libkrb5support0
  liblcms2-2
  libldap-2.4-2
  libltdl7
  liblz4-1
  liblzma5
  liblzo2-2
  libmd0
  libmd4c0
  libminizip-dev
  libminizip1
  libmount-dev
  libmount1
  libmtdev1
  libncurses-dev
  libncurses6
  libncursesw6
  libnettle8
  libnghttp2-14
  libnsl2
  libnspr4
  libnspr4-dev
  libnss-db
  libnss3
  libnss3-dev
  libogg-dev
  libogg0
  libopengl0
  libopus-dev
  libopus0
  libp11-kit0
  libpam0g
  libpam0g-dev
  libpango-1.0-0
  libpango1.0-dev
  libpangocairo-1.0-0
  libpangoft2-1.0-0
  libpangox-1.0-0
  libpangoxft-1.0-0
  libpci-dev
  libpci3
  libpciaccess0
  libpcre16-3
  libpcre2-16-0
  libpcre2-32-0
  libpcre2-8-0
  libpcre2-dev
  libpcre2-posix2
  libpcre3
  libpcre3-dev
  libpcre32-3
  libpcrecpp0v5
  libpipewire-0.3-0
  libpipewire-0.3-dev
  libpixman-1-0
  libpixman-1-dev
  libpng-dev
  libpng16-16
  libpsl5
  libpthread-stubs0-dev
  libpulse-dev
  libpulse-mainloop-glib0
  libpulse0
  libqt5concurrent5
  libqt5core5a
  libqt5dbus5
  libqt5gui5
  libqt5network5
  libqt5printsupport5
  libqt5sql5
  libqt5test5
  libqt5widgets5
  libqt5xml5
  libre2-9
  libre2-dev
  librest-0.7-0
  librtmp1
  libsasl2-2
  libselinux1
  libselinux1-dev
  libsepol1
  libsepol1-dev
  libsm6
  libsnappy-dev
  libsnappy1v5
  libsndfile1
  libsoup-gnome2.4-1
  libsoup2.4-1
  libspa-0.2-dev
  libspeechd-dev
  libspeechd2
  libsqlite3-0
  libssh2-1
  libssl-dev
  libssl1.1
  libstdc++-10-dev
  libstdc++6
  libsystemd-dev
  libsystemd0
  libtasn1-6
  libthai-dev
  libthai0
  libtiff-dev
  libtiff5
  libtiffxx5
  libtinfo6
  libtirpc3
  libudev-dev
  libudev1
  libunbound8
  libunistring2
  libutempter-dev
  libutempter0
  libuuid1
  libva-dev
  libva-drm2
  libva-glx2
  libva-wayland2
  libva-x11-2
  libva2
  libvorbis0a
  libvorbisenc2
  libvulkan-dev
  libvulkan1
  libwacom2
  libwayland-bin
  libwayland-client0
  libwayland-cursor0
  libwayland-dev
  libwayland-egl-backend-dev
  libwayland-egl1
  libwayland-egl1-mesa
  libwayland-server0
  libwebp-dev
  libwebp6
  libwebpdemux2
  libwebpmux3
  libwrap0
  libx11-6
  libx11-dev
  libx11-xcb-dev
  libx11-xcb1
  libxau-dev
  libxau6
  libxcb-dri2-0
  libxcb-dri2-0-dev
  libxcb-dri3-0
  libxcb-dri3-dev
  libxcb-glx0
  libxcb-glx0-dev
  libxcb-icccm4
  libxcb-image0
  libxcb-image0-dev
  libxcb-keysyms1
  libxcb-present-dev
  libxcb-present0
  libxcb-randr0
  libxcb-randr0-dev
  libxcb-render-util0
  libxcb-render-util0-dev
  libxcb-render0
  libxcb-render0-dev
  libxcb-shape0
  libxcb-shape0-dev
  libxcb-shm0
  libxcb-shm0-dev
  libxcb-sync-dev
  libxcb-sync1
  libxcb-util-dev
  libxcb-util1
  libxcb-xfixes0
  libxcb-xfixes0-dev
  libxcb-xinerama0
  libxcb-xinput0
  libxcb-xkb1
  libxcb1
  libxcb1-dev
  libxcomposite-dev
  libxcomposite1
  libxcursor-dev
  libxcursor1
  libxdamage-dev
  libxdamage1
  libxdmcp-dev
  libxdmcp6
  libxext-dev
  libxext6
  libxfixes-dev
  libxfixes3
  libxft-dev
  libxft2
  libxi-dev
  libxi6
  libxinerama-dev
  libxinerama1
  libxkbcommon-dev
  libxkbcommon-x11-0
  libxkbcommon0
  libxml2
  libxml2-dev
  libxrandr-dev
  libxrandr2
  libxrender-dev
  libxrender1
  libxshmfence-dev
  libxshmfence1
  libxslt1-dev
  libxslt1.1
  libxss-dev
  libxss1
  libxt-dev
  libxt6
  libxtst-dev
  libxtst6
  libxxf86vm-dev
  libxxf86vm1
  libzstd1
  linux-libc-dev
  mesa-common-dev
  qtbase5-dev
  qtbase5-dev-tools
  shared-mime-info
  uuid-dev
  wayland-protocols
  x11proto-dev
  zlib1g
  zlib1g-dev
"

DEBIAN_PACKAGES_AMD64="
  libtsan0
  liblsan0
"

DEBIAN_PACKAGES_X86="
  libasan6
  libdrm-intel1
  libitm1
  libquadmath0
  libubsan1
  valgrind
"

DEBIAN_PACKAGES_ARM="
  libasan6
  libdrm-etnaviv1
  libdrm-exynos1
  libdrm-freedreno1
  libdrm-omap1
  libdrm-tegra0
  libubsan1
  valgrind
"

DEBIAN_PACKAGES_ARM64="
  libasan6
  libdrm-etnaviv1
  libdrm-freedreno1
  libdrm-tegra0
  libgmp10
  libitm1
  liblsan0
  libthai0
  libtsan0
  libubsan1
  valgrind
"

DEBIAN_PACKAGES_ARMEL="
  libasan6
  libdrm-exynos1
  libdrm-freedreno1
  libdrm-omap1
  libdrm-tegra0
  libubsan1
"

DEBIAN_PACKAGES_MIPS64EL="
  valgrind
"

. "${SCRIPT_DIR}/sysroot-creator.sh"
