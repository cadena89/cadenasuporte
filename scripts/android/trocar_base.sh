#!/usr/bin/env bash
# Troca o codigo do RustDesk do Android para a tag de TAG_RUSTDESK (ambiente.sh) e refaz a ponte Flutter/Rust.
# Depois rode compilar_todos.sh. Os patches vem da pasta fonte da entrega, gerada pelo 6_empacotar.ps1 do Windows.
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
cd "$VB/rustdesk"
echo "=== RustDesk $TAG_RUSTDESK"
git -C libs/hbb_common checkout --quiet .
git checkout --quiet -- . ':!libs/hbb_common'
git fetch --quiet --depth 1 origin tag "$TAG_RUSTDESK"
git -c advice.detachedHead=false checkout --quiet "$TAG_RUSTDESK"
git submodule update --init --depth 1 libs/hbb_common
git log -1 --format='%h %s'
git -C libs/hbb_common log -1 --format='hbb_common %h'
echo "=== Ponte Flutter/Rust"
rm -f src/bridge_generated.rs src/bridge_generated.io.rs flutter/lib/generated_bridge.dart
cd flutter
flutter --no-version-check pub get >/dev/null
cd ..
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
cp ./flutter/macos/Runner/bridge_generated.h ./flutter/ios/Runner/bridge_generated.h
ls -l src/bridge_generated.rs flutter/lib/generated_bridge.dart
echo "=== Concluido"