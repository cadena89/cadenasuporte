# Compila e empacota as duas versoes do Windows: Tecnico (so acessa) e Cliente (so recebe acesso). Depois gera
# os atalhos do tecnico (.bat) e o instalador silencioso do Cliente. Pode ser repetido.
# O Cliente fica por ultimo, para a pasta Release e o instalador silencioso terminarem com ele.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\configuracao.ps1"
foreach ($perfil in 'tecnico', 'cliente') {
  "##### Perfil $perfil"
  $env:CADENA_PERFIL = if ($perfil -eq 'tecnico') { 'tecnico' } else { $null }
  & "$PSScriptRoot\4_compilar.ps1"
  & "$PSScriptRoot\6_empacotar.ps1"
}
$env:CADENA_PERFIL = $null

# Texto so com ASCII para o cmd ("Técnico" -> "Tecnico")
function Sem-Acento([string]$s) {
  $d = $s.Normalize([Text.NormalizationForm]::FormD)
  return -join ($d.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' })
}
function Preencher([string]$texto) {
  return $texto.Replace('__NOME_TECNICO__', $Marca.NomeTecnico).Replace('__NOME_CLIENTE__', $Marca.NomeCliente).
    Replace('__EXIBIDO_TECNICO__', (Sem-Acento $Marca.ExibidoTecnico)).Replace('__EXIBIDO_CLIENTE__', $Marca.ExibidoCliente).
    Replace('__EMPRESA__', $Marca.Empresa).Replace('__PREFIXO__', $Marca.Prefixo)
}

# Atalhos do tecnico: nome mostrado ao cliente e envio das gravacoes por FTP (o .bat precisa de CRLF)
foreach ($bat in 'DefinirNomeTecnico.bat', 'ConfigurarFTP.bat') {
  $texto = Preencher ([IO.File]::ReadAllText("$PSScriptRoot\modelos\$bat") -replace "`r`n", "`n")
  [IO.File]::WriteAllText("$Entrega\$bat", $texto.Replace("`n", "`r`n"), [Text.Encoding]::ASCII)
}

"##### Instalador silencioso (Cliente)"
$Versao = (Select-String -Path "$Raiz\rustdesk\Cargo.toml" -Pattern '^version = "([^"]+)"' | Select-Object -First 1).Matches[0].Groups[1].Value
$Pasta = "$Raiz\instalador-gerado"
New-Item -ItemType Directory -Force $Pasta | Out-Null
$Cs = Preencher ([IO.File]::ReadAllText("$PSScriptRoot\instalador-silencioso\Instalador.cs", [Text.Encoding]::UTF8))
$Cs = $Cs -replace 'AssemblyVersion\("[0-9.]+"\)', "AssemblyVersion(`"$Versao.0`")"
[IO.File]::WriteAllText("$Pasta\Instalador.cs", $Cs, (New-Object Text.UTF8Encoding $false))
Copy-Item -Force "$PSScriptRoot\instalador-silencioso\app.manifest" "$Pasta\app.manifest"
Copy-Item -Force "$Raiz\rustdesk\res\icon.ico" "$Pasta\icon.ico"
$Csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$Saida = "$Entrega\Instalar$($Marca.NomeCliente).exe"
& $Csc /nologo /codepage:65001 /target:winexe /platform:x64 /optimize+ "/out:$Saida" "/win32manifest:$Pasta\app.manifest" "/win32icon:$Pasta\icon.ico" "/resource:$Entrega\$($Marca.NomeCliente)-$Versao-portatil.exe,pacote.exe" /reference:System.ServiceProcess.dll /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "$Pasta\Instalador.cs"
if ($LASTEXITCODE -ne 0) { throw "csc saiu com $LASTEXITCODE" }
"$Saida $([math]::Round((Get-Item $Saida).Length/1MB,1)) MB"
"##### Concluido"
