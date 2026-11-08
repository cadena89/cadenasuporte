@echo off
rem Grava o nome do tecnico que aparece na janela do cliente durante o acesso.
rem Usa o __EXIBIDO_TECNICO__ instalado ou, se nao houver, o portatil que estiver nesta pasta.
setlocal
set "EXE=%ProgramFiles%\__NOME_TECNICO__\__NOME_TECNICO__.exe"
if not exist "%EXE%" for %%f in ("%~dp0__NOME_TECNICO__-*-portatil.exe") do set "EXE=%%~ff"
if not exist "%EXE%" (
  echo __EXIBIDO_TECNICO__ nao encontrado. Instale o programa ou coloque este arquivo na pasta do portatil.
  pause
  exit /b 1
)
echo Este nome aparece para o cliente quando voce acessa o computador dele.
echo Deixe em branco para voltar a mostrar o usuario do Windows.
echo.
set "NOME="
set /p "NOME=Seu nome: "
start "" /wait "%EXE%" --__PREFIXO__-nome %NOME%