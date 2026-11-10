# Assina executaveis com o certificado da marca (scripts\gerar_certificado.ps1). Uso: . "$PSScriptRoot\assinar.ps1"
# depois de carregar a configuracao, e entao: Assinar-Arquivos <arquivos>
# De onde vem o certificado:
#   - local: CertificadoPfx e CertificadoSenha (arquivo com a senha) no config.local.psd1
#   - CI: segredos CADENA_CERTIFICADO_PFX (o .pfx em base64) e CADENA_CERTIFICADO_SENHA
# Sem certificado configurado, nao assina e so avisa (o build continua).
function Carregar-Certificado {
  $pfx = $null; $senha = $null
  if ($env:CADENA_CERTIFICADO_PFX) {
    $pfx = [Convert]::FromBase64String($env:CADENA_CERTIFICADO_PFX)
    $senha = $env:CADENA_CERTIFICADO_SENHA
  } elseif ($Cfg.CertificadoPfx -and (Test-Path $Cfg.CertificadoPfx)) {
    $pfx = [IO.File]::ReadAllBytes($Cfg.CertificadoPfx)
    if (-not ($Cfg.CertificadoSenha -and (Test-Path $Cfg.CertificadoSenha))) { throw 'CertificadoSenha (arquivo com a senha do .pfx) nao encontrado' }
    $senha = (Get-Content -Raw $Cfg.CertificadoSenha).Trim()
  } else {
    return $null
  }
  $flags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet
  return [Security.Cryptography.X509Certificates.X509Certificate2]::new([byte[]]$pfx, [string]$senha, $flags)
}

function Assinar-Arquivos([string[]]$arquivos) {
  $cert = Carregar-Certificado
  if (-not $cert) { "AVISO: sem certificado configurado, os executaveis saem sem assinatura"; return }
  if (-not $cert.HasPrivateKey) { throw 'O certificado carregado nao tem a chave privada' }
  try {
  foreach ($arq in $arquivos) {
    # Carimbo de tempo: a assinatura continua valida depois que o certificado vencer. Sem rede, assina sem carimbo
    $r = $null
    foreach ($tsa in 'http://timestamp.digicert.com', 'http://timestamp.sectigo.com') {
      try {
        $r = Set-AuthenticodeSignature -FilePath $arq -Certificate $cert -HashAlgorithm SHA256 -TimestampServer $tsa -ErrorAction Stop
        if ($r.SignerCertificate) { break }
      } catch { "AVISO: carimbo de tempo de $tsa falhou: $($_.Exception.Message)" }
    }
    if (-not ($r -and $r.SignerCertificate)) {
      $r = Set-AuthenticodeSignature -FilePath $arq -Certificate $cert -HashAlgorithm SHA256
    }
    # Nesta maquina o certificado nao e confiavel, entao o status pode ser UnknownError/NotTrusted; o que importa e
    # a assinatura estar no arquivo com o nosso certificado
    $v = Get-AuthenticodeSignature $arq
    if (-not $v.SignerCertificate -or $v.SignerCertificate.Thumbprint -ne $cert.Thumbprint) { throw "Falha ao assinar $arq ($($r.StatusMessage))" }
    $carimbo = if ($v.TimeStamperCertificate) { 'com carimbo de tempo' } else { 'SEM carimbo de tempo' }
    "Assinado: $(Split-Path -Leaf $arq) ($carimbo)"
  }
  } finally { $cert.Reset() }
}
