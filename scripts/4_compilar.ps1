# Gera a ponte Flutter/Rust e compila o cliente. Pode ser repetido.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\ambiente.ps1"
Set-Location "$Raiz\rustdesk"
& flutter --no-version-check doctor -v

"=== flutter pub get"
Push-Location flutter
& flutter --no-version-check pub get
$codigo = $LASTEXITCODE
Pop-Location
if ($codigo -ne 0) { throw 'pub get' }

# A ponte e gerada a partir do src\flutter_ffi.rs: gera de novo quando ele muda (versao nova do RustDesk ou
# funcao nova nas modificacoes), comparando o SHA-256 guardado na ultima geracao
$Selo = 'src\bridge_generated.sha256'
$Hash = (Get-FileHash -Algorithm SHA256 'src\flutter_ffi.rs').Hash
$Gerada = (Test-Path 'src\bridge_generated.rs') -and (Test-Path $Selo) -and ((Get-Content -Raw $Selo).Trim() -eq $Hash)
if (-not $Gerada) {
  "=== ponte Flutter/Rust"
  & flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h --llvm-path "$Ferramentas\llvm"
  if ($LASTEXITCODE -ne 0) { throw 'ponte' }
  Copy-Item -Force flutter\macos\Runner\bridge_generated.h flutter\ios\Runner\bridge_generated.h
  Set-Content -Encoding ascii $Selo $Hash
}

"=== build.py"
# --dart-define=APP_TYPE (2_marca): tech no Tecnico e no Console, client no Cliente
$env:CADENA_APP_TYPE = if ($env:CADENA_PERFIL -in 'tecnico', 'console') { 'tech' } else { 'client' }
"APP_TYPE=$env:CADENA_APP_TYPE"
& "$Ferramentas\python\python.exe" .\build.py --portable --flutter --skip-portable-pack --hwcodec --vram
if ($LASTEXITCODE -ne 0) { throw "build.py saiu com $LASTEXITCODE" }
if (-not (Test-Path 'flutter\build\windows\x64\runner\Release\rustdesk.exe')) { throw 'rustdesk.exe nao foi gerado' }
"=== Concluido"
