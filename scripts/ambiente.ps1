# Configuracao + ferramentas de compilacao. Variaveis so deste processo: nada e gravado no ambiente do Windows
. "$PSScriptRoot\configuracao.ps1"
$Ferramentas = "$Raiz\ferramentas"
$env:RUSTUP_HOME = "$Ferramentas\rustup"
$env:CARGO_HOME = "$Ferramentas\cargo"
$env:PUB_CACHE = "$Ferramentas\pub-cache"
$env:VCPKG_ROOT = "$Ferramentas\vcpkg"
$env:VCPKG_DEFAULT_HOST_TRIPLET = 'x64-windows-static'
$env:VCPKG_DISABLE_METRICS = '1'
$env:VCPKG_MAX_CONCURRENCY = '4'
$env:CARGO_BUILD_JOBS = '4'
$env:LIBCLANG_PATH = "$Ferramentas\llvm\bin"
$env:FLUTTER_ROOT = "$Ferramentas\flutter"
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:CI = 'true'
$env:PATH = @(
  "$Ferramentas\cargo\bin",
  "$Ferramentas\flutter\bin",
  "$Ferramentas\llvm\bin",
  "$Ferramentas\python",
  $env:VCPKG_ROOT,
  'C:\Program Files\Git\bin',
  $env:PATH
) -join ';'

# Maquina tambem atende outros servicos, entao a compilacao roda em prioridade baixa
(Get-Process -Id $PID).PriorityClass = 'BelowNormal'
