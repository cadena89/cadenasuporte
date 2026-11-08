# Instala Rust, Flutter, LLVM, Python e vcpkg em <Raiz>\ferramentas e baixa o codigo do RustDesk. Pode ser repetido.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\ambiente.ps1"
$Baixados = "$Raiz\baixados"
New-Item -ItemType Directory -Force $Ferramentas, $Baixados | Out-Null

function Baixar($url, $nome) {
  $destino = "$Baixados\$nome"
  if (-not (Test-Path $destino)) {
    "baixando $nome"
    & curl.exe -fsSL --retry 3 -o "$destino.parte" $url
    if ($LASTEXITCODE -ne 0) { throw "falha ao baixar $url" }
    Move-Item "$destino.parte" $destino
  }
  "$nome $([math]::Round((Get-Item $destino).Length/1MB)) MB sha256=$((Get-FileHash $destino -Algorithm SHA256).Hash)"
  return
}

"=== Python"
Baixar 'https://www.python.org/ftp/python/3.12.7/python-3.12.7-embed-amd64.zip' 'python-embed.zip'
if (-not (Test-Path "$Ferramentas\python\python.exe")) { Expand-Archive "$Baixados\python-embed.zip" "$Ferramentas\python" }
& "$Ferramentas\python\python.exe" --version

"=== 7-Zip (para abrir o instalador do LLVM sem admin)"
Baixar 'https://github.com/ip7z/7zip/releases/download/24.09/7zr.exe' '7zr.exe'
Baixar 'https://github.com/ip7z/7zip/releases/download/24.09/7z2409-x64.exe' '7z-x64.exe'
if (-not (Test-Path "$Ferramentas\7zip\7z.exe")) {
  & "$Baixados\7zr.exe" x -y "-o$Ferramentas\7zip" "$Baixados\7z-x64.exe" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw '7zip' }
}

"=== LLVM 15.0.6"
Baixar 'https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/LLVM-15.0.6-win64.exe' 'llvm.exe'
if (-not (Test-Path "$Ferramentas\llvm\bin\libclang.dll")) {
  & "$Ferramentas\7zip\7z.exe" x -y "-o$Ferramentas\llvm" "$Baixados\llvm.exe" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'llvm' }
}
& "$Ferramentas\llvm\bin\clang.exe" --version | Select-Object -First 1

"=== Rust 1.75"
Baixar 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' 'rustup-init.exe'
if (-not (Test-Path "$Ferramentas\cargo\bin\rustc.exe")) {
  & "$Baixados\rustup-init.exe" -y --no-modify-path --profile minimal --default-toolchain 1.75 --component rustfmt
  if ($LASTEXITCODE -ne 0) { throw 'rustup' }
}
& rustc --version

"=== Flutter 3.24.5"
Baixar 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip' 'flutter.zip'
if (-not (Test-Path "$Ferramentas\flutter\bin\flutter.bat")) {
  & "$Ferramentas\7zip\7z.exe" x -y "-o$Ferramentas" "$Baixados\flutter.zip" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'flutter' }
}
& flutter --no-version-check config --no-analytics --no-cli-animations --enable-windows-desktop
& flutter --no-version-check precache --windows
if ($LASTEXITCODE -ne 0) { throw 'precache' }

"=== Codigo do RustDesk $TagRustDesk"
if (-not (Test-Path "$Raiz\rustdesk\.git")) {
  & git -c advice.detachedHead=false clone --quiet --depth 1 --branch $TagRustDesk --recurse-submodules --shallow-submodules https://github.com/rustdesk/rustdesk.git "$Raiz\rustdesk"
  if ($LASTEXITCODE -ne 0) { throw "clone do RustDesk $TagRustDesk" }
}
& git -C "$Raiz\rustdesk" log -1 --format="%h %s"

"=== Motor e correcao do Flutter usados pelo RustDesk"
Baixar 'https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip' 'engine.zip'
$marca = "$Ferramentas\flutter\.motor-rustdesk"
if (-not (Test-Path $marca)) {
  $temp = "$Baixados\engine-temp"
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp }
  & "$Ferramentas\7zip\7z.exe" x -y "-o$temp" "$Baixados\engine.zip" | Out-Null
  Copy-Item -Recurse -Force "$temp\*" "$Ferramentas\flutter\bin\cache\artifacts\engine\windows-x64-release\"
  Remove-Item -Recurse -Force $temp
  Push-Location "$Ferramentas\flutter"
  & git apply "$Raiz\rustdesk\.github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff"
  $codigo = $LASTEXITCODE
  Pop-Location
  if ($codigo -ne 0) { throw 'patch do flutter' }
  Set-Content $marca 'ok'
}
& flutter --no-version-check --version

"=== vcpkg"
if (-not (Test-Path "$env:VCPKG_ROOT\.git")) {
  & git clone --quiet https://github.com/microsoft/vcpkg.git $env:VCPKG_ROOT
  if ($LASTEXITCODE -ne 0) { throw 'clone vcpkg' }
}
& git -C $env:VCPKG_ROOT -c advice.detachedHead=false checkout --quiet 9e593bb18ea69cc5095e012465dcd675a822ed0d
if ($LASTEXITCODE -ne 0) { throw 'checkout vcpkg' }
if (-not (Test-Path "$env:VCPKG_ROOT\vcpkg.exe")) {
  & "$env:VCPKG_ROOT\bootstrap-vcpkg.bat" -disableMetrics
  if ($LASTEXITCODE -ne 0) { throw 'bootstrap vcpkg' }
}

"=== Concluido"
