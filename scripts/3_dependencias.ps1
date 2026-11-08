# Compila as bibliotecas C do RustDesk (aom, opus, libvpx, libyuv, ffmpeg...) e os geradores da ponte Flutter.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\ambiente.ps1"
Set-Location "$Raiz\rustdesk"

"=== vcpkg install"
& "$env:VCPKG_ROOT\vcpkg.exe" install --triplet x64-windows-static "--x-install-root=$env:VCPKG_ROOT\installed"
if ($LASTEXITCODE -ne 0) { throw "vcpkg saiu com $LASTEXITCODE" }

"=== geradores da ponte"
if (-not (Test-Path "$env:CARGO_HOME\bin\cargo-expand.exe")) {
  & cargo install cargo-expand --version 1.0.95 --locked
  if ($LASTEXITCODE -ne 0) { throw 'cargo-expand' }
}
if (-not (Test-Path "$env:CARGO_HOME\bin\flutter_rust_bridge_codegen.exe")) {
  & cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
  if ($LASTEXITCODE -ne 0) { throw 'flutter_rust_bridge_codegen' }
}
"=== Concluido"
