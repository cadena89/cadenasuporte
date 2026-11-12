# Monta em <Entrega>\publicar\<tag> os arquivos da release do GitHub, com versao.assinado (atualizacao automatica).
# Sem -SemCompilar, sobe o numero, aplica a marca e compila as duas versoes do Windows antes.
# Com -Publicar, ja cria a release em RepoAtualizacao (GitHub CLI logado) e marca como Latest.
param([switch]$SemCompilar, [switch]$Publicar)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\configuracao.ps1"
$Versao = (Select-String -Path "$Raiz\rustdesk\Cargo.toml" -Pattern '^version = "([^"]+)"' | Select-Object -First 1).Matches[0].Groups[1].Value
$OpenSsl = 'C:\Program Files\Git\usr\bin\openssl.exe'
if (-not $ChavePrivada -or -not (Test-Path $ChavePrivada)) { throw "Chave privada de assinatura ausente: $ChavePrivada (ChavePrivada no config.local.psd1)" }
if (-not $RepoAtualizacao) { throw 'Informe RepoAtualizacao no config.local.psd1' }
$Cliente = $Marca.NomeCliente
# A release leva o Cliente (x64 e x86) e o Console Tecnico, mais os APKs. O Tecnico avulso saiu em 2026-11-12: quem
# o tem instalado instala o Console uma vez, e o Console se atualiza sozinho daqui em diante

if (-not $SemCompilar) {
  $novo = [int](Get-Content -Raw $ArqNumero).Trim() + 1
  Set-Content -Encoding ascii $ArqNumero $novo
  "##### Numero da versao: $novo"
  & "$PSScriptRoot\2_marca.ps1"
  & "$PSScriptRoot\8_compilar_perfis.ps1"
}
$Numero = [int](Get-Content -Raw $ArqNumero).Trim()
# O numero compilado vem do 2_marca; confere que o fonte esta com o mesmo numero
$Fonte = Get-Content -Raw "$Raiz\rustdesk\src\updater.rs"
if ($Fonte -notmatch "CADENA_NUMERO: u64 = $Numero;") { throw "O fonte nao esta com o numero $Numero. Rode o 2_marca e compile." }

# Tag e nomes seguem a versao publica (SemVer, configuracao.ps1); $Versao e a versao do RustDesk usada como base
$Tag = "v$VersaoProduto"
$Pasta = "$Entrega\publicar\$Tag"
New-Item -ItemType Directory -Force $Pasta | Out-Null
# A chave e o nome interno do app em minusculas: o atualizador de cada perfil procura a sua e baixa o arquivo
# indicado aqui (o nome vem do versao.json assinado, nao de um padrao fixo no programa)
$Arquivos = [ordered]@{
  ($Cliente.ToLower()) = (Nome-Arquivo 'client')
  ($NomeConsole.ToLower()) = (Nome-Arquivo 'console')
}
$Portateis = @((Nome-Arquivo 'client' 'portable'), (Nome-Arquivo 'console' 'portable'))
# Cliente x86 (x86_compilar.ps1), quando compilado: o atualizador da versao de 32 bits procura a chave <nome>-x86
if (Test-Path "$Entrega\$(Nome-Arquivo 'client' 'install' 'x86')") {
  $Arquivos["$($Cliente.ToLower())-x86"] = (Nome-Arquivo 'client' 'install' 'x86')
  $Portateis += (Nome-Arquivo 'client' 'portable' 'x86')
} else {
  Write-Warning "Sem o Cliente x86 ($(Nome-Arquivo 'client' 'install' 'x86')): a release sai so com o x64"
}
foreach ($a in @($Arquivos.Values) + $Portateis) {
  Copy-Item -Force "$Entrega\$a" "$Pasta\$a"
}
# APKs do Android da mesma versao do RustDesk, para o download pelo celular (o Android nao se atualiza sozinho).
# O script do Android gera <NomeCliente>-<versao>-<arm64|armv7>.apk; na release vao com o nome novo
Get-ChildItem "$Entrega\android\$Cliente-$Versao-*.apk" -ErrorAction SilentlyContinue | ForEach-Object {
  $arq = [regex]::Match($_.Name, '-(arm64|armv7)\.apk$').Groups[1].Value
  if ($arq) { Copy-Item -Force $_.FullName "$Pasta\$(Nome-Arquivo 'client' $arq)" }
}
$Dados = [ordered]@{ numero = $Numero; tag = $Tag; versao = $VersaoProduto; rustdesk = $Versao }
foreach ($p in @($Arquivos.Keys)) {
  $Dados[$p] = [ordered]@{
    arquivo = $Arquivos[$p]
    sha256  = (Get-FileHash -Algorithm SHA256 "$Pasta\$($Arquivos[$p])").Hash.ToLower()
  }
}
$Json = "$Pasta\versao.json"
[IO.File]::WriteAllText($Json, ($Dados | ConvertTo-Json -Depth 3), (New-Object Text.UTF8Encoding $false))

# versao.assinado = base64(assinatura Ed25519 de 64 bytes + versao.json), o formato combinado do libsodium
$Sig = "$env:TEMP\cadena-versao.sig"
& $OpenSsl pkeyutl -sign -inkey $ChavePrivada -rawin -in $Json -out $Sig
if ($LASTEXITCODE -ne 0) { throw "openssl nao assinou" }
$Combinado = [IO.File]::ReadAllBytes($Sig) + [IO.File]::ReadAllBytes($Json)
[IO.File]::WriteAllText("$Pasta\versao.assinado", [Convert]::ToBase64String($Combinado), [Text.Encoding]::ASCII)
& $OpenSsl pkeyutl -verify -inkey $ChavePrivada -rawin -in $Json -sigfile $Sig | Out-Null
$ok = $LASTEXITCODE -eq 0
Remove-Item $Sig
if (-not $ok) { throw "A assinatura gerada nao confere" }

"##### Pronto: $Pasta"
Get-ChildItem $Pasta | Select-Object Name, Length | Format-Table -AutoSize | Out-String
$Titulo = "$($Marca.ExibidoCliente) $VersaoProduto"
# Diz no titulo quando o servidor compilado e o 2 (0_nova_versao.ps1 -Reserva)
$ConfigRs = Get-Content -Raw "$Raiz\rustdesk\libs\hbb_common\src\config.rs"
$Primario = [regex]::Match($ConfigRs, 'RENDEZVOUS_SERVERS: &\[&str\] = &\["([^"]+)"\]').Groups[1].Value
$Srv = if ($Cfg.Servidor2.Endereco -and $Primario -eq $Cfg.Servidor2.Endereco) { ' - servidor reserva' } else { '' }
if ($Publicar) {
  $Gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
  if (-not $Gh) { $Gh = "$Raiz\ferramentas\gh\bin\gh.exe" }
  $Arqs = Get-ChildItem $Pasta | ForEach-Object FullName
  & $Gh release create $Tag @Arqs --repo $RepoAtualizacao --target main --title "$Titulo$Srv" --notes "$($Marca.ExibidoCliente) $VersaoProduto (numero $Numero, baseado no RustDesk $Versao)$Srv." --latest
  if ($LASTEXITCODE -ne 0) { throw "O gh nao publicou a release $Tag" }
  "##### Publicada: https://github.com/$RepoAtualizacao/releases/tag/$Tag"
  "As maquinas com numero menor que $Numero se atualizam em ate um dia, quando nao houver acesso em andamento."
  return
}
"Publique em https://github.com/$RepoAtualizacao/releases/new  (ou rode de novo com -SemCompilar -Publicar)"
"  Tag: $Tag  (crie a tag na hora, a partir do branch principal)"
"  Anexe todos os arquivos da pasta acima e deixe marcado 'Set as the latest release'."
