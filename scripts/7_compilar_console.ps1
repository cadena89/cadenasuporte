# Compila so o Console Tecnico: o Tecnico com os acessos em abas na janela principal (CADENA_PERFIL=console).
# Ele tem nome proprio (Console<NomeTecnico>), instala e guarda a configuracao separado do Tecnico, e nao entra
# na release nem na atualizacao automatica. O Tecnico e o Cliente ja entregues nao mudam.
# Rode antes o 2_marca.ps1 (a mesma marca), como no 8_compilar_perfis. Saida: <Entrega>\suporte-vX.Y.Z-console-x64.exe
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\configuracao.ps1"
$env:CADENA_PERFIL = 'console'
try {
  & "$PSScriptRoot\4_compilar.ps1"
  & "$PSScriptRoot\6_empacotar.ps1"
} finally {
  $env:CADENA_PERFIL = $null
}
"##### Console Tecnico concluido"
