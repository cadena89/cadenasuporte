# Cria a distribuicao do WSL usada para compilar o Android (DistroWsl do config.local.psd1) e monta o ambiente.
# Nao altera a distribuicao padrao do WSL. Rode antes o 2_marca.ps1 e o 6_empacotar.ps1 (ou o 0_nova_versao.ps1
# -SemAndroid) no Windows: o preparar.sh aplica os patches da pasta fonte da entrega. Pode ser repetido.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\configuracao.ps1"
$Arquivo = "$Raiz\baixados\ubuntu-base-24.04.5-base-amd64.tar.gz"
$Sha = 'e77b6f10c2590cef872b33ee9f635a0e3fd1f57fb074c0e52b5c7f56147a0c86'
(Get-Process -Id $PID).PriorityClass = 'BelowNormal'
New-Item -ItemType Directory -Force "$Raiz\baixados" | Out-Null

if (-not (Test-Path $Arquivo)) {
  & curl.exe -fsSL --retry 3 -o $Arquivo 'https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.5-base-amd64.tar.gz'
  if ($LASTEXITCODE -ne 0) { throw 'download do Ubuntu' }
}
if ((Get-FileHash $Arquivo -Algorithm SHA256).Hash.ToLower() -ne $Sha) { throw 'sha256 do Ubuntu nao confere' }
"Ubuntu Base conferido"

$lista = (& wsl.exe -l -q) -replace "`0", ''
if ($lista -notcontains $DistroWsl) {
  New-Item -ItemType Directory -Force "$Raiz\wsl-android" | Out-Null
  & wsl.exe --import $DistroWsl "$Raiz\wsl-android" $Arquivo --version 2
  if ($LASTEXITCODE -ne 0) { throw 'wsl --import' }
}
function Wsl([string]$p) { return '/mnt/' + $p.Substring(0, 1).ToLower() + $p.Substring(2).Replace('\', '/') }
& wsl.exe -d $DistroWsl -u root --cd / -- env "ENTREGA=$(Wsl $Entrega)" "TAG_RUSTDESK=$TagRustDesk" bash "$(Wsl $PSScriptRoot)/preparar.sh"
if ($LASTEXITCODE -ne 0) { throw "preparar.sh saiu com $LASTEXITCODE" }
"=== Tudo pronto"
