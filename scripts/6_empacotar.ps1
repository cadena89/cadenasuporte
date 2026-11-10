# Gera o executavel unico de instalacao e o pacote de fonte exigido pela AGPL. Pode ser repetido.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\ambiente.ps1"
$Fonte = "$Raiz\rustdesk"
$Release = "$Fonte\flutter\build\windows\x64\runner\Release"
# Versao do RustDesk no fonte (Cargo.toml)
$Versao = (Select-String -Path "$Fonte\Cargo.toml" -Pattern '^version = "([^"]+)"' | Select-Object -First 1).Matches[0].Groups[1].Value
New-Item -ItemType Directory -Force $Entrega, "$Entrega\fonte" | Out-Null
$py = "$Ferramentas\python\python.exe"
$NomeApp = $Marca.NomeCliente

"=== Marca do empacotador"
$arquivo = "$Fonte\libs\portable\Cargo.toml"
$latin = [Text.Encoding]::GetEncoding(28591)
$texto = $latin.GetString([IO.File]::ReadAllBytes($arquivo))
$texto = [regex]::Replace($texto, 'LegalCopyright = "[^"]*"', "LegalCopyright = `"$($Marca.Empresa). Baseado no RustDesk, (c) Purslane Tech Pte. Ltd., licenca AGPL-3.0.`"")
$texto = $texto.Replace('ProductName = "RustDesk"', "ProductName = `"$($Marca.ExibidoCliente)`"").Replace('FileDescription = "RustDesk Remote Desktop"', "FileDescription = `"$($Marca.ExibidoCliente) - Acesso Remoto`"").Replace('OriginalFilename = "rustdesk.exe"', "OriginalFilename = `"$NomeApp.exe`"")
[IO.File]::WriteAllBytes($arquivo, $latin.GetBytes($texto))

"=== Driver de monitor virtual, como no build oficial"
if (-not (Test-Path "$Release\usbmmidd_v2")) {
  $zip = "$Raiz\baixados\usbmmidd_v2.zip"
  if (-not (Test-Path $zip)) {
    & curl.exe -fsSL --retry 3 -o $zip 'https://github.com/rustdesk-org/rdev/releases/download/usbmmidd_v2/usbmmidd_v2.zip'
    if ($LASTEXITCODE -ne 0) { throw 'usbmmidd' }
  }
  "usbmmidd_v2.zip sha256=$((Get-FileHash $zip -Algorithm SHA256).Hash)"
  $temp = "$Raiz\baixados\usbmmidd-temp"
  if (Test-Path $temp) { Remove-Item -Recurse -Force $temp }
  Expand-Archive $zip -DestinationPath $temp
  Remove-Item -Recurse -Force "$temp\usbmmidd_v2\Win32"
  Remove-Item -Force "$temp\usbmmidd_v2\deviceinstaller64.exe", "$temp\usbmmidd_v2\deviceinstaller.exe", "$temp\usbmmidd_v2\usbmmidd.bat"
  Move-Item "$temp\usbmmidd_v2" "$Release\usbmmidd_v2"
  Remove-Item -Recurse -Force $temp
}

"=== Dependencia do empacotador"
if (-not (Test-Path "$Ferramentas\python\brotli.py")) {
  Get-Content "$Fonte\libs\portable\requirements.txt"
  $info = Invoke-RestMethod 'https://pypi.org/pypi/Brotli/1.1.0/json'
  $roda = $info.urls | Where-Object { $_.filename -eq 'Brotli-1.1.0-cp312-cp312-win_amd64.whl' }
  if (-not $roda) { throw 'wheel do Brotli nao encontrado' }
  $whl = "$Raiz\baixados\brotli.zip"
  & curl.exe -fsSL --retry 3 -o $whl $roda.url
  if ($LASTEXITCODE -ne 0) { throw 'brotli' }
  if ((Get-FileHash $whl -Algorithm SHA256).Hash -ne $roda.digests.sha256.ToUpper()) { throw 'sha256 do Brotli nao confere' }
  Expand-Archive -Force $whl -DestinationPath "$Ferramentas\python"
  & $py -c 'import brotli; print(brotli.__version__)'
  if ($LASTEXITCODE -ne 0) { throw 'import brotli' }
}

"=== Assinatura do programa (certificado da marca, se configurado)"
. "$PSScriptRoot\assinar.ps1"
Assinar-Arquivos @("$Release\rustdesk.exe", "$Release\librustdesk.dll")

"=== Empacotando"
Push-Location "$Fonte\libs\portable"
& $py .\generate.py -f "$Release" -o . -e "$Release\rustdesk.exe"
$codigo = $LASTEXITCODE
Pop-Location
if ($codigo -ne 0) { throw "generate.py saiu com $codigo" }
$pacote = "$Fonte\target\release\rustdesk-portable-packer.exe"
if (-not (Test-Path $pacote)) { throw 'empacotador nao gerou o exe' }
Assinar-Arquivos $pacote
# O nome terminado em install.exe faz o programa abrir a tela de instalacao
# CADENA_PERFIL=tecnico vem do 8_compilar_perfis e define qual versao foi compilada
$Nome = if ($env:CADENA_PERFIL -eq 'tecnico') { $Marca.NomeTecnico } else { $NomeApp }
Copy-Item -Force $pacote "$Entrega\$Nome-$Versao-install.exe"
Copy-Item -Force $pacote "$Entrega\$Nome-$Versao-portatil.exe"

"=== Fonte correspondente (AGPL-3.0)"
Push-Location $Fonte
$utf8 = New-Object Text.UTF8Encoding $false
# --output grava os bytes do git; passar pelo PowerShell corrompe acentos
& git diff --binary "--output=$Entrega\fonte\rustdesk.patch" -- . ':!flutter/pubspec.lock' ':!libs/hbb_common'
& git -C libs/hbb_common diff --binary "--output=$Entrega\fonte\hbb_common.patch"
$commit = & git rev-parse HEAD
$sub = & git -C libs/hbb_common rev-parse HEAD
Copy-Item -Force LICENCE "$Entrega\fonte\LICENCE"
Pop-Location
$leia = @"
$($Marca.ExibidoCliente) $Versao e uma versao modificada do RustDesk, distribuida sob a licenca AGPL-3.0 (arquivo LICENCE).
Codigo original: https://github.com/rustdesk/rustdesk, tag $Versao, commit $commit
Submodulo libs/hbb_common: commit $sub
Modificacoes: rustdesk.patch e hbb_common.patch, gerados pelos scripts do CadenaTech:
https://github.com/cadena89/cadenasuporte
"@
[IO.File]::WriteAllText("$Entrega\fonte\LEIA-ME.txt", $leia, $utf8)

Get-ChildItem $Entrega -File | ForEach-Object { "$($_.Name) $([math]::Round($_.Length/1MB,1)) MB sha256=$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)" }
"=== Concluido"
