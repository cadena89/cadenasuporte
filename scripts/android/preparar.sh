#!/usr/bin/env bash
# Monta o ambiente Linux do build de Android, sem o SDK e o NDK do Android. Pode ser repetido.
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
mkdir -p "$VB"

echo "=== Pacotes"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  build-essential ca-certificates clang cmake curl gcc-multilib g++-multilib git \
  autoconf automake libtool make nasm yasm patch perl pkg-config python3 ninja-build \
  libasound2-dev libayatana-appindicator3-dev libc6-dev libclang-dev libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev libgtk-3-dev libpulse-dev libunwind-dev libva-dev \
  libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev libxdo-dev libxfixes-dev \
  libssl-dev llvm-dev openjdk-17-jdk-headless tar unzip wget xz-utils zip >/dev/null
java -version 2>&1 | head -1

echo "=== Rust 1.75"
if [ ! -x "$CARGO_HOME/bin/rustc" ]; then
  curl -fsSL -o /tmp/rustup-init https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
  chmod +x /tmp/rustup-init
  /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain 1.75 --component rustfmt
fi
rustup target add aarch64-linux-android armv7-linux-androideabi
rustc --version

echo "=== Flutter 3.24.5"
if [ ! -x "$VB/flutter/bin/flutter" ]; then
  curl -fsSL -o /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$VB"
  rm -f /tmp/flutter.tar.xz
fi
git config --global --add safe.directory "$VB/flutter"
flutter --no-version-check config --no-analytics --no-cli-animations >/dev/null

echo "=== Codigo do RustDesk $TAG_RUSTDESK"
if [ ! -d "$VB/rustdesk/.git" ]; then
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$TAG_RUSTDESK" --recurse-submodules --shallow-submodules \
    https://github.com/rustdesk/rustdesk.git "$VB/rustdesk"
fi
if [ ! -e "$VB/flutter/.correcao-rustdesk" ]; then
  git -C "$VB/flutter" apply "$VB/rustdesk/.github/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff"
  touch "$VB/flutter/.correcao-rustdesk"
fi
flutter --no-version-check --version | head -1

echo "=== Marca"
bash "$SCRIPTS_ANDROID/aplicar_marca.sh"

echo "=== vcpkg"
if [ ! -d "$VCPKG_ROOT/.git" ]; then
  git clone --quiet https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
fi
git -C "$VCPKG_ROOT" -c advice.detachedHead=false checkout --quiet 9e593bb18ea69cc5095e012465dcd675a822ed0d
[ -x "$VCPKG_ROOT/vcpkg" ] || "$VCPKG_ROOT/bootstrap-vcpkg.sh" -disableMetrics

echo "=== Geradores"
[ -x "$CARGO_HOME/bin/cargo-ndk" ] || cargo install cargo-ndk --version 3.1.2 --locked
[ -x "$CARGO_HOME/bin/cargo-expand" ] || cargo install cargo-expand --version 1.0.95 --locked
[ -x "$CARGO_HOME/bin/flutter_rust_bridge_codegen" ] || cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked

echo "=== Ponte Flutter/Rust"
cd "$VB/rustdesk/flutter"
flutter --no-version-check pub get >/dev/null
cd "$VB/rustdesk"
if [ ! -f src/bridge_generated.rs ]; then
  flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
  cp ./flutter/macos/Runner/bridge_generated.h ./flutter/ios/Runner/bridge_generated.h
fi
ls -l src/bridge_generated.rs flutter/lib/generated_bridge.dart
echo "=== Concluido"
