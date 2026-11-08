# Gera o par de chaves Ed25519 da atualizacao automatica numa pasta PRIVADA (fora do repositorio):
#   atualizacao.pem    chave privada: assina cada release (9_publicar.ps1). Backup, e nunca a publique
#   chave-publica.txt  vai embutida no programa (2_marca.ps1); pode ser publicada
# Uso: powershell -ExecutionPolicy Bypass -File scripts\gerar_chave_atualizacao.ps1 -Pasta D:\privado\atualizacao
# Nao sobrescreve uma chave existente: trocar a chave faz as maquinas instaladas pararem de se atualizar.
param([Parameter(Mandatory = $true)][string]$Pasta)
$ErrorActionPreference = 'Stop'
$OpenSsl = 'C:\Program Files\Git\usr\bin\openssl.exe'
if (-not (Test-Path $OpenSsl)) { $OpenSsl = (Get-Command openssl -ErrorAction Stop).Source }
$Repositorio = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force $Pasta | Out-Null
$Pasta = (Resolve-Path $Pasta).Path
if ($Pasta.StartsWith($Repositorio, [StringComparison]::OrdinalIgnoreCase)) { throw 'Use uma pasta fora do repositorio' }
$Privada = Join-Path $Pasta 'atualizacao.pem'
$Publica = Join-Path $Pasta 'chave-publica.txt'
if (Test-Path $Privada) { throw "Ja existe uma chave em $Privada. Nada foi alterado." }

& $OpenSsl genpkey -algorithm ed25519 -out $Privada
if ($LASTEXITCODE -ne 0) { throw 'openssl nao gerou a chave' }
# Chave publica no formato do libsodium: os 32 bytes finais do DER (SubjectPublicKeyInfo), em base64
$Der = Join-Path $env:TEMP 'chave-publica.der'
& $OpenSsl pkey -in $Privada -pubout -outform DER -out $Der
if ($LASTEXITCODE -ne 0) { throw 'openssl nao exportou a chave publica' }
$bytes = [IO.File]::ReadAllBytes($Der)
Remove-Item $Der
[IO.File]::WriteAllText($Publica, [Convert]::ToBase64String($bytes[($bytes.Length - 32)..($bytes.Length - 1)]), [Text.Encoding]::ASCII)
"Chave privada: $Privada  (faca backup, fora deste computador)"
"Chave publica: $Publica"
"No config.local.psd1: ChavePublica = '$Publica' e ChavePrivada = '$Privada'"
