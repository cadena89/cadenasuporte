# Ferramentas da versao de 32 bits (x86) do Cliente, que usa a interface antiga do RustDesk (Sciter): o RustDesk
# oficial nao tem Flutter de 32 bits. Mesmo caminho do job build-for-windows-sciter do RustDesk 1.5.3:
#   - Rust nightly-2023-10-13 de 32 bits (o sciter-rs precisa do abi_thiscall, so no nightly);
#   - LLVM 15.0.6 de 32 bits (os build scripts de 32 bits carregam o libclang de 32 bits);
#   - bibliotecas do vcpkg no triplet x86-windows-static (aom, opus, libvpx, libyuv, ffmpeg...): demora bastante.
# Pode ser repetido. Rode depois do 1_ferramentas.ps1 (usa o 7-Zip, o rustup e o vcpkg de la).
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\ambiente.ps1"
$Baixados = "$Raiz\baixados"
New-Item -ItemType Directory -Force $Baixados | Out-Null
$ToolchainX86 = 'nightly-2023-10-13-i686-pc-windows-msvc'

"=== LLVM 15.0.6 de 32 bits"
if (-not (Test-Path "$Ferramentas\llvm32\bin\libclang.dll")) {
  if (-not (Test-Path "$Baixados\llvm32.exe")) {
    & curl.exe -fsSL --retry 3 -o "$Baixados\llvm32.exe" 'https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/LLVM-15.0.6-win32.exe'
    if ($LASTEXITCODE -ne 0) { throw 'download do LLVM 32 bits' }
  }
  & "$Ferramentas\7zip\7z.exe" x -y "-o$Ferramentas\llvm32" "$Baixados\llvm32.exe" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'llvm32' }
}

"=== Rust $ToolchainX86"
if (-not (& rustup toolchain list | Select-String -SimpleMatch $ToolchainX86 -Quiet)) {
  & rustup toolchain install $ToolchainX86 --profile minimal --component rustfmt --no-self-update --force-non-host
  if ($LASTEXITCODE -ne 0) { throw "rustup $ToolchainX86" }
}
& rustup run $ToolchainX86 rustc --version

"=== vcpkg x86-windows-static"
Set-Location "$Raiz\rustdesk"
$env:VCPKG_DEFAULT_HOST_TRIPLET = 'x86-windows-static'
& "$env:VCPKG_ROOT\vcpkg.exe" install --triplet x86-windows-static "--x-install-root=$env:VCPKG_ROOT\installed"
if ($LASTEXITCODE -ne 0) { throw "vcpkg x86 saiu com $LASTEXITCODE" }
"=== Concluido"
