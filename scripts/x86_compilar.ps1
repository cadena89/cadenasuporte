# Compila e empacota o Cliente de 32 bits (x86): suporte-vX.Y.Z-client-x86.exe (instala) e -x86-portable.exe.
# O RustDesk nao tem Flutter de 32 bits, entao esta versao usa a interface antiga (Sciter), como o build oficial
# (job build-for-windows-sciter). O 2_marca adapta o essencial nela: aviso na janela de aceitar, aprovacao por clique
# sem senha na tela, texto do ID e o servico ligado sozinho ao abrir. Servidores, chaves e atualizacao vem do Rust.
# Rode depois do 2_marca.ps1 e do x86_ferramentas.ps1. Usa pastas proprias (<Raiz>\target-x86 e <Raiz>\release-x86)
# para nao misturar com o build de 64 bits, e devolve o Cargo.toml/Cargo.lock como estavam no fim.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\ambiente.ps1"
$Fonte = "$Raiz\rustdesk"
$ToolchainX86 = 'nightly-2023-10-13-i686-pc-windows-msvc'
$ReleaseX86 = "$Raiz\release-x86"
$env:RUSTUP_TOOLCHAIN = $ToolchainX86
$env:CARGO_TARGET_DIR = "$Raiz\target-x86"
$env:VCPKG_DEFAULT_HOST_TRIPLET = 'x86-windows-static'
# Bibliotecas de 32 bits na raiz propria do x86_ferramentas (separada da do x64)
$env:VCPKG_ROOT = "$Ferramentas\vcpkg-x86"
if (-not (Test-Path "$env:VCPKG_ROOT\installed\x86-windows-static\lib\vpx.lib")) { throw 'Rode antes o x86_ferramentas.ps1' }
$env:LIBCLANG_PATH = "$Ferramentas\llvm32\bin"
$env:PATH = "$Ferramentas\llvm32\bin;$env:PATH"
$env:CADENA_PERFIL = $null
$py = "$Ferramentas\python\python.exe"
if (-not (Test-Path "$Ferramentas\llvm32\bin\libclang.dll")) { throw 'Rode antes o x86_ferramentas.ps1' }

Set-Location $Fonte
$Guarda = "$Raiz\baixados\x86-cargo-guarda"
New-Item -ItemType Directory -Force $Guarda | Out-Null
Copy-Item -Force Cargo.toml, Cargo.lock $Guarda
try {
  "=== Interface antiga embutida no executavel (inline)"
  # -X utf8: o inline-sciter.py abre os .tis sem dizer a codificacao, e no Windows o Python usaria a cp1252 e
  # estragaria os acentos dos textos da marca ("tecnico" virava "tÃƒÂ©cnico"); no CI do RustDesk (Linux) ja e UTF-8
  & $py -X utf8 res\inline-sciter.py
  if ($LASTEXITCODE -ne 0) { throw 'inline-sciter.py' }

  "=== sciter-rs de 32 bits"
  $toml = [IO.File]::ReadAllText("$Fonte\Cargo.toml")
  if (-not $toml.Contains('branch = "dyn"')) { throw 'Cargo.toml sem o sciter-rs branch dyn' }
  [IO.File]::WriteAllText("$Fonte\Cargo.toml", $toml.Replace('branch = "dyn"', 'branch = "dyn_x86"'))
  & cargo update -p sciter-rs --precise 674e07d3066ca9a92ced3816203ab6b652629d1e
  if ($LASTEXITCODE -ne 0) { throw 'cargo update sciter-rs' }

  "=== cargo build (i686, Sciter)"
  & cargo build --locked --features inline,vram,hwcodec --release --bins
  if ($LASTEXITCODE -ne 0) { throw "cargo build x86 saiu com $LASTEXITCODE" }

  "=== Pasta do programa"
  if (Test-Path $ReleaseX86) { Remove-Item -Recurse -Force $ReleaseX86 }
  New-Item -ItemType Directory -Force $ReleaseX86 | Out-Null
  Copy-Item "$env:CARGO_TARGET_DIR\release\rustdesk.exe" "$ReleaseX86\rustdesk.exe"
  $sciter = "$Raiz\baixados\sciter-x32.dll"
  if (-not (Test-Path $sciter)) {
    & curl.exe -fsSL --retry 3 -o $sciter 'https://github.com/c-smile/sciter-sdk/raw/master/bin.win/x32/sciter.dll'
    if ($LASTEXITCODE -ne 0) { throw 'sciter.dll x32' }
  }
  Copy-Item $sciter "$ReleaseX86\sciter.dll"
  # Driver de monitor virtual: fica o deviceinstaller64.exe, porque o programa de 32 bits pode rodar num Windows
  # de 64 bits e so o de 64 instala o driver la (como no build oficial)
  $zip = "$Raiz\baixados\usbmmidd_v2.zip"
  if (Test-Path $zip) {
    $tmp = "$Raiz\baixados\usbmmidd-x86"
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    Expand-Archive $zip -DestinationPath $tmp
    Remove-Item -Force "$tmp\usbmmidd_v2\deviceinstaller.exe", "$tmp\usbmmidd_v2\usbmmidd.bat" -ErrorAction SilentlyContinue
    Move-Item "$tmp\usbmmidd_v2" "$ReleaseX86\usbmmidd_v2"
    Remove-Item -Recurse -Force $tmp
  }

  "=== Assinatura e empacotamento"
  . "$PSScriptRoot\assinar.ps1"
  Assinar-Arquivos @("$ReleaseX86\rustdesk.exe")
  # Marca do empacotador (o mesmo do 6_empacotar)
  $arquivo = "$Fonte\libs\portable\Cargo.toml"
  $latin = [Text.Encoding]::GetEncoding(28591)
  $texto = $latin.GetString([IO.File]::ReadAllBytes($arquivo))
  $texto = [regex]::Replace($texto, 'LegalCopyright = "[^"]*"', "LegalCopyright = `"$($Marca.Empresa). Baseado no RustDesk, (c) Purslane Tech Pte. Ltd., licenca AGPL-3.0.`"")
  $texto = $texto.Replace('ProductName = "RustDesk"', "ProductName = `"$($Marca.ExibidoCliente)`"").Replace('FileDescription = "RustDesk Remote Desktop"', "FileDescription = `"$($Marca.ExibidoCliente) - Acesso Remoto`"").Replace('OriginalFilename = "rustdesk.exe"', "OriginalFilename = `"$($Marca.NomeCliente).exe`"")
  [IO.File]::WriteAllBytes($arquivo, $latin.GetBytes($texto))
  Push-Location "$Fonte\libs\portable"
  & $py .\generate.py -f "$ReleaseX86" -o . -e "$ReleaseX86\rustdesk.exe"
  $codigo = $LASTEXITCODE
  Pop-Location
  if ($codigo -ne 0) { throw "generate.py x86 saiu com $codigo" }
  $pacote = "$env:CARGO_TARGET_DIR\release\rustdesk-portable-packer.exe"
  if (-not (Test-Path $pacote)) { throw 'empacotador x86 nao gerou o exe' }
  Assinar-Arquivos $pacote
  New-Item -ItemType Directory -Force $Entrega | Out-Null
  Copy-Item -Force $pacote "$Entrega\$(Nome-Arquivo 'client' 'install' 'x86')"
  Copy-Item -Force $pacote "$Entrega\$(Nome-Arquivo 'client' 'portable' 'x86')"
  Get-ChildItem "$Entrega\suporte-v*-x86*.exe" | ForEach-Object { "$($_.Name) $([math]::Round($_.Length/1MB,1)) MB sha256=$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)" }
} finally {
  Copy-Item -Force "$Guarda\Cargo.toml", "$Guarda\Cargo.lock" $Fonte
}
"=== Concluido"
