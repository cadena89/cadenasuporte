# Gera uma nova versao completa com um comando so:
#   1. sobe o numero da versao (<Entrega>\numero.txt)
#   2. aplica a marca e compila o Tecnico e o Cliente do Windows (2_marca + 8_compilar_perfis)
#   3. compila os dois APKs do Android no WSL (android\compilar_todos.sh), com os patches gerados no passo 2
#   4. monta e assina a release em <Entrega>\publicar\<tag> (9_publicar -SemCompilar)
#   5. com -Publicar, ja publica no GitHub como Latest
# Uso (numa janela do PowerShell, na pasta do repositorio):
#   powershell -ExecutionPolicy Bypass -File scripts\0_nova_versao.ps1            -> so monta
#   powershell -ExecutionPolicy Bypass -File scripts\0_nova_versao.ps1 -Publicar  -> monta e publica
#   -Config <arquivo>  usa outra configuracao local (o mesmo que CADENA_CONFIG)
#   -SemAndroid        pula o Android (a release leva os APKs que ja existirem da mesma versao do RustDesk)
#   -Reserva           compila com o servidor 2 como principal, se o 1 cair. Para voltar, rode de novo sem
#                      -Reserva. Nos dois casos as maquinas instaladas mudam pela atualizacao automatica
#   -Versao x.y.z      versao publica (SemVer) da release e dos arquivos (suporte-vx.y.z-client-x64.exe). Sem ela, sobe
#                      o ultimo numero da anterior (1.0.0 -> 1.0.1); a primeira e 1.0.0
param([switch]$Publicar, [switch]$SemAndroid, [switch]$Reserva, [string]$Config, [string]$Versao)
$ErrorActionPreference = 'Stop'
if ($Config) { $env:CADENA_CONFIG = (Resolve-Path $Config).Path }
$env:CADENA_RESERVA = if ($Reserva) { '1' } else { $null }
. "$PSScriptRoot\configuracao.ps1"
$Inicio = Get-Date

if (-not (Test-Path $ArqNumero)) { New-Item -ItemType Directory -Force (Split-Path $ArqNumero) | Out-Null; Set-Content -Encoding ascii $ArqNumero 0 }
$Numero = [int](Get-Content -Raw $ArqNumero).Trim() + 1
Set-Content -Encoding ascii $ArqNumero $Numero
# Versao publica: a informada, ou a anterior com o ultimo numero + 1. Os scripts seguintes a leem do arquivo
if ($env:CADENA_VERSAO) { throw 'Use -Versao em vez de CADENA_VERSAO no 0_nova_versao.ps1' }
if (-not $Versao) {
  $Versao = if (Test-Path $ArqVersaoProduto) {
    $p = (Get-Content -Raw $ArqVersaoProduto).Trim().Split('.')
    "$($p[0]).$($p[1]).$([int]$p[2] + 1)"
  } else { '1.0.0' }
}
if ($Versao -notmatch '^\d+\.\d+\.\d+$') { throw "A versao precisa seguir o SemVer, ex.: 1.0.0 (veio: $Versao)" }
Set-Content -Encoding ascii $ArqVersaoProduto $Versao
"##### Nova versao de $($Marca.ExibidoCliente): $Versao (numero $Numero)"

"##### Windows"
& "$PSScriptRoot\2_marca.ps1"
& "$PSScriptRoot\8_compilar_perfis.ps1"

if (-not $SemAndroid) {
  "##### Android"
  # Caminho do Windows visto de dentro do WSL: C:\pasta -> /mnt/c/pasta
  function Wsl([string]$p) { if (-not $p) { return '' }; return '/mnt/' + $p.Substring(0, 1).ToLower() + $p.Substring(2).Replace('\', '/') }
  $Variaveis = @(
    "ENTREGA=$(Wsl $Entrega)",
    "NOME_CLIENTE=$($Marca.NomeCliente)",
    "TAG_RUSTDESK=$TagRustDesk",
    "SERVIDOR=$($Srv1.Endereco)",
    "ANDROID_CHAVE=$(Wsl $Cfg.AndroidChave)",
    "ANDROID_SENHAS=$(Wsl $Cfg.AndroidSenhas)",
    "ANDROID_ALIAS=$($Marca.Prefixo)suporte",
    "ANDROID_DONO=$($Marca.AndroidDono)"
  )
  & wsl.exe -d $DistroWsl -u root -- env @Variaveis bash "$(Wsl $PSScriptRoot)/android/compilar_todos.sh"
  if ($LASTEXITCODE -ne 0) { throw "Android saiu com $LASTEXITCODE" }
}

"##### Release"
$Opcoes = @{ SemCompilar = $true; Publicar = [bool]$Publicar }
& "$PSScriptRoot\9_publicar.ps1" @Opcoes
"##### Concluido em $([math]::Round(((Get-Date) - $Inicio).TotalMinutes)) minutos"
