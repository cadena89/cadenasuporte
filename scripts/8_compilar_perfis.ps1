# Compila e empacota as versoes do Windows (x64) que vao para a release: o Console Tecnico (quem atende, com os
# acessos em abas) e o Cliente (so recebe acesso). Pode ser repetido. O Cliente fica por ultimo, para a pasta Release
# terminar com ele. O Cliente de 32 bits sai do x86_compilar.ps1 (interface antiga, Sciter).
# O Tecnico avulso (CADENA_PERFIL=tecnico) ainda compila, mas saiu da release em 2026-11-12:
#   $env:CADENA_PERFIL = 'tecnico'; scripts\4_compilar.ps1; scripts\6_empacotar.ps1
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\configuracao.ps1"
foreach ($perfil in 'console', 'cliente') {
  "##### Perfil $perfil"
  $env:CADENA_PERFIL = if ($perfil -eq 'console') { 'console' } else { $null }
  & "$PSScriptRoot\4_compilar.ps1"
  & "$PSScriptRoot\6_empacotar.ps1"
}
$env:CADENA_PERFIL = $null
"##### Concluido"
