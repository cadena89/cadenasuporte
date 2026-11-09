# Compila e empacota as duas versoes do Windows: Tecnico (so acessa) e Cliente (so recebe acesso). Pode ser repetido.
# O Cliente fica por ultimo, para a pasta Release terminar com ele.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\configuracao.ps1"
foreach ($perfil in 'tecnico', 'cliente') {
  "##### Perfil $perfil"
  $env:CADENA_PERFIL = if ($perfil -eq 'tecnico') { 'tecnico' } else { $null }
  & "$PSScriptRoot\4_compilar.ps1"
  & "$PSScriptRoot\6_empacotar.ps1"
}
$env:CADENA_PERFIL = $null
# Os atalhos .bat (nome do tecnico e FTP) e o instalador silencioso sairam em 2026-11-09: o nome vem da conta da API,
# o FTP tem tela no proprio Tecnico (Configuracoes > Geral) e o instalador silencioso nao e usado
"##### Concluido"
