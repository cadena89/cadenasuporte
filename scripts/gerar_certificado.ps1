# Gera o certificado autoassinado de assinatura de codigo da marca (uma vez so). Uso:
#   powershell -ExecutionPolicy Bypass -File scripts\gerar_certificado.ps1 -Empresa "Minha Empresa" -Pasta <pasta privada>
# Grava na pasta:
#   certificado.pfx  chave privada + certificado (protegido pela senha) -> NUNCA publicar; faca backup
#   senha.txt        senha do .pfx                                       -> NUNCA publicar
#   certificado.cer  so o certificado publico: vai embutido no programa, que o grava como confiavel ao instalar
# Depois aponte no config.local.psd1: CertificadoPfx, CertificadoSenha e Certificado (o .cer).
# Nao gere de novo: os computadores ja instalados confiam so no certificado atual.
# O certificado so serve para assinar codigo (EKU) e nao pode emitir outros (CA=0), o que limita o estrago se a
# chave vazar: ninguem consegue usa-lo para sites (HTTPS) nem para criar certificados filhos.
param([Parameter(Mandatory)][string]$Empresa, [Parameter(Mandatory)][string]$Pasta, [int]$Anos = 10)
$ErrorActionPreference = 'Stop'
if (Test-Path "$Pasta\certificado.pfx") { throw "Ja existe $Pasta\certificado.pfx. Nao gere outro: os computadores instalados confiam neste." }
New-Item -ItemType Directory -Force $Pasta | Out-Null

$cert = New-SelfSignedCertificate -Type CodeSigningCert `
  -Subject "CN=$Empresa, O=$Empresa, C=BR" -FriendlyName "$Empresa - assinatura de codigo" `
  -KeyAlgorithm RSA -KeyLength 3072 -HashAlgorithm SHA256 -KeyExportPolicy Exportable `
  -NotAfter (Get-Date).AddYears($Anos) -CertStoreLocation Cert:\CurrentUser\My `
  -TextExtension @('2.5.29.19={critical}{text}CA=0')
try {
  # Senha aleatoria (48 caracteres), gravada so no arquivo
  $bytes = New-Object byte[] 36
  [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $senha = [Convert]::ToBase64String($bytes)
  [IO.File]::WriteAllText("$Pasta\senha.txt", $senha, [Text.Encoding]::ASCII)
  $seguro = ConvertTo-SecureString $senha -AsPlainText -Force
  Export-PfxCertificate -Cert $cert -FilePath "$Pasta\certificado.pfx" -Password $seguro | Out-Null
  Export-Certificate -Cert $cert -FilePath "$Pasta\certificado.cer" -Type CERT | Out-Null
} finally {
  # A chave fica so no .pfx, nao no repositorio de certificados do usuario
  Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" -DeleteKey -ErrorAction SilentlyContinue
}
"Certificado de '$Empresa' gerado em $Pasta"
"Impressao digital (SHA-1): $($cert.Thumbprint)"
"Validade: $($cert.NotBefore.ToString('yyyy-MM-dd')) a $($cert.NotAfter.ToString('yyyy-MM-dd'))"
