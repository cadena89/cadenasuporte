# Carrega a configuracao local e a marca. Os outros scripts usam: . "$PSScriptRoot\configuracao.ps1"
#
# Configuracao local (servidores, chaves, pastas): o arquivo de $env:CADENA_CONFIG ou, sem a variavel,
# config.local.psd1 na raiz do repositorio (fora do Git: copie de config.exemplo.psd1).
# Cada valor pode ser trocado na hora por uma variavel de ambiente, por exemplo num CI:
#   CADENA_MARCA, CADENA_RAIZ, CADENA_ENTREGA, CADENA_SERVIDOR1, CADENA_CHAVE1, CADENA_NOME1,
#   CADENA_SERVIDOR2, CADENA_CHAVE2, CADENA_NOME2, CADENA_API, CADENA_REPO_ATUALIZACAO,
#   CADENA_CHAVE_ATUALIZACAO (chave publica Ed25519 em base64), CADENA_DISTRO_WSL, CADENA_TAG_RUSTDESK,
#   CADENA_NUMERO (numero da versao compilado, no lugar do <Entrega>\numero.txt)
# CADENA_RESERVA=1 troca o servidor 1 pelo 2 (0_nova_versao.ps1 -Reserva).
# Sem arquivo de configuracao e com CADENA_SERVIDOR1 (ou CI) definido, so as variaveis sao usadas.
$Repositorio = Split-Path $PSScriptRoot -Parent

# Le um .psd1 sempre como UTF-8 (o Import-PowerShellDataFile do PowerShell 5.1 estraga os acentos sem BOM)
function Ler-Psd1([string]$arquivo) {
  $texto = [IO.File]::ReadAllText($arquivo, [Text.Encoding]::UTF8)
  $erros = $null
  $ast = [Management.Automation.Language.Parser]::ParseInput($texto, [ref]$null, [ref]$erros)
  if ($erros) { throw "Erro em ${arquivo}: $($erros[0].Message)" }
  $tabela = $ast.Find({ $args[0] -is [Management.Automation.Language.HashtableAst] }, $false)
  if (-not $tabela) { throw "$arquivo nao tem uma tabela @{ ... }" }
  # SafeGetValue so aceita dados (texto, numero, lista, tabela): nada no arquivo e executado
  return $tabela.SafeGetValue()
}

function Valor([string]$variavel, $padrao) {
  $v = [Environment]::GetEnvironmentVariable($variavel)
  if ($v) { return $v }
  return $padrao
}

$ArqConfig = Valor 'CADENA_CONFIG' "$Repositorio\config.local.psd1"
if (Test-Path $ArqConfig) {
  $Cfg = Ler-Psd1 $ArqConfig
} elseif ($env:CADENA_SERVIDOR1 -or $env:CI) {
  # Sem arquivo (ex.: GitHub Actions): tudo vem das variaveis CADENA_*
  $Cfg = @{}
} else {
  throw "Configuracao nao encontrada: $ArqConfig. Copie config.exemplo.psd1 para config.local.psd1 e preencha (ou defina CADENA_CONFIG)."
}
if (-not $Cfg.Servidor1) { $Cfg.Servidor1 = @{} }
if (-not $Cfg.Servidor2) { $Cfg.Servidor2 = @{} }

$NomeMarca = Valor 'CADENA_MARCA' $Cfg.Marca
if (-not $NomeMarca) { $NomeMarca = 'cadenatech' }
$PastaMarca = if (Test-Path -PathType Container $NomeMarca) { (Resolve-Path $NomeMarca).Path } else { "$Repositorio\marcas\$NomeMarca" }
if (-not (Test-Path "$PastaMarca\marca.psd1")) { throw "Marca nao encontrada: $PastaMarca\marca.psd1" }
$Marca = Ler-Psd1 "$PastaMarca\marca.psd1"

$Raiz = Valor 'CADENA_RAIZ' $Cfg.Raiz
if (-not $Raiz) { $Raiz = 'D:\rustdesk-build' }
$Entrega = Valor 'CADENA_ENTREGA' $Cfg.Entrega
if (-not $Entrega) { $Entrega = "$Raiz\entrega" }
$DistroWsl = Valor 'CADENA_DISTRO_WSL' $Cfg.DistroWsl
if (-not $DistroWsl) { $DistroWsl = 'CadenaBuild' }

# Servidores: o 1 e o principal (embutido como servidor do RustDesk); o 2, opcional, recebe o registro do
# Cliente ao mesmo tempo e a segunda tentativa do Tecnico. Nome = como aparece ao lado do "Pronto"
$Srv1 = @{
  Endereco = Valor 'CADENA_SERVIDOR1' $Cfg.Servidor1.Endereco
  Chave    = Valor 'CADENA_CHAVE1' $Cfg.Servidor1.Chave
  Nome     = Valor 'CADENA_NOME1' $Cfg.Servidor1.Nome
}
$Srv2 = @{
  Endereco = Valor 'CADENA_SERVIDOR2' $Cfg.Servidor2.Endereco
  Chave    = Valor 'CADENA_CHAVE2' $Cfg.Servidor2.Chave
  Nome     = Valor 'CADENA_NOME2' $Cfg.Servidor2.Nome
}
if ($Srv2.Endereco -and -not $Srv2.Chave) { throw 'O servidor 2 precisa da chave dele (Servidor2.Chave ou CADENA_CHAVE2)' }
foreach ($s in $Srv1, $Srv2) { if ($s.Endereco -and -not $s.Nome) { $s.Nome = $s.Endereco } }
$Reserva = (Valor 'CADENA_RESERVA' '') -eq '1'
if ($Reserva) {
  if (-not $Srv2.Endereco) { throw 'CADENA_RESERVA=1 precisa do servidor 2' }
  $Srv1, $Srv2 = $Srv2, $Srv1
}

$ApiServidor = Valor 'CADENA_API' $Cfg.Api
if (-not $ApiServidor) { $ApiServidor = '' }

# Atualizacao automatica (Windows): releases do repositorio do GitHub, assinadas com Ed25519.
# A chave publica vai embutida no programa; a privada fica so na maquina que publica (ChavePrivada)
$RepoAtualizacao = Valor 'CADENA_REPO_ATUALIZACAO' $Cfg.RepoAtualizacao
if (-not $RepoAtualizacao) { $RepoAtualizacao = '' }
$ChaveAtualizacao = Valor 'CADENA_CHAVE_ATUALIZACAO' ''
if (-not $ChaveAtualizacao -and $Cfg.ChavePublica) {
  $ChaveAtualizacao = if (Test-Path $Cfg.ChavePublica) { (Get-Content -Raw $Cfg.ChavePublica).Trim() } else { $Cfg.ChavePublica }
}
$ChavePrivada = $Cfg.ChavePrivada

# Certificado de assinatura de codigo da marca (scripts\gerar_certificado.ps1). O publico (.cer) vai embutido no
# programa, que o grava como confiavel ao instalar e ao atualizar; CI: variavel CADENA_CERTIFICADO (o .cer em base64).
# A assinatura em si usa CertificadoPfx/CertificadoSenha (ver assinar.ps1)
$CertificadoB64 = Valor 'CADENA_CERTIFICADO' ''
if (-not $CertificadoB64 -and $Cfg.Certificado) {
  $CertificadoB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($Cfg.Certificado))
}
if ($CertificadoB64 -notmatch '^[A-Za-z0-9+/=]*$') { throw 'CADENA_CERTIFICADO precisa ser o .cer em base64' }

# Numero da versao da marca: sobe a cada entrega e decide a atualizacao automatica
$ArqNumero = "$Entrega\numero.txt"
$ArqNumeroAndroid = "$Entrega\android\numero.txt"
# No CI o numero vem de CADENA_NUMERO (o arquivo nao existe entre uma execucao e outra)
if ($env:CADENA_NUMERO) {
  if ($env:CADENA_NUMERO -notmatch '^\d+$') { throw "CADENA_NUMERO precisa ser um numero: $env:CADENA_NUMERO" }
  New-Item -ItemType Directory -Force $Entrega | Out-Null
  Set-Content -Encoding ascii $ArqNumero $env:CADENA_NUMERO
}

# Versao do RustDesk usada (tag do GitHub)
$TagRustDesk = Valor 'CADENA_TAG_RUSTDESK' $Cfg.TagRustDesk
if (-not $TagRustDesk) { $TagRustDesk = '1.5.1' }
