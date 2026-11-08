@echo off
rem Liga, testa ou desliga o envio das gravacoes do __EXIBIDO_TECNICO__ para o FTP configurado.
rem O mesmo pode ser feito no proprio programa: Configuracoes > Geral > Envio das gravacoes (FTP).
rem Com o endereco da rede local preenchido, o envio funciona dentro e fora do escritorio sem mexer no arquivo hosts.
rem Ligado, cada gravacao e enviada ao fim do acesso e apagada deste computador depois de o servidor confirmar.
rem A senha fica so no perfil deste usuario do Windows, nunca no programa:
rem   %APPDATA%\__NOME_TECNICO__\config\__PREFIXO__-ftp.txt
setlocal
set "CONFIG=%APPDATA%\__NOME_TECNICO__\config\__PREFIXO__-ftp.txt"
set "VIDEOS=%USERPROFILE%\Videos\__NOME_TECNICO__"
set "EXE=%ProgramFiles%\__NOME_TECNICO__\__NOME_TECNICO__.exe"
if not exist "%EXE%" for %%f in ("%~dp0__NOME_TECNICO__-*-portatil.exe") do set "EXE=%%~ff"

:menu
cls
echo.
echo  Envio das gravacoes por FTP - __EXIBIDO_TECNICO__
echo.
if exist "%CONFIG%" (echo  Situacao: LIGADO) else (echo  Situacao: DESLIGADO)
echo.
echo  1 - Configurar e ligar (enderecos, usuario e senha)
echo  2 - Testar o envio
echo  3 - Desligar (apaga a configuracao deste computador)
echo  4 - Ver a configuracao e as gravacoes ainda nao enviadas
echo  5 - Sair
echo.
set "OP="
set /p "OP=Escolha: "
if "%OP%"=="1" goto configurar
if "%OP%"=="2" goto testar
if "%OP%"=="3" goto desligar
if "%OP%"=="4" goto ver
if "%OP%"=="5" exit /b 0
goto menu

:configurar
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$a=$env:CONFIG; $l=Read-Host 'Endereco na rede local, opcional (ex.: 192.168.0.10:21)'; $s=Read-Host 'Endereco externo (ex.: ftp.exemplo.com.br:21)'; $u=Read-Host 'Usuario'; $l=($l.Trim() -replace '^(?i)ftp://','').TrimEnd('/'); $s=($s.Trim() -replace '^(?i)ftp://','').TrimEnd('/'); if((-not $s -and -not $l) -or -not $u){Write-Host 'Informe pelo menos um endereco e o usuario. Nada foi salvo.'; exit 1}; $p=Read-Host 'Senha' -AsSecureString; $p=[Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p)); $d=Read-Host 'Pasta no servidor [/gravacoes]'; if(-not $d){$d='/gravacoes'}; New-Item -ItemType Directory -Force (Split-Path $a) | Out-Null; [IO.File]::WriteAllText($a, ('servidor_local='+$l+[char]10+'servidor='+$s+[char]10+'usuario='+$u.Trim()+[char]10+'senha='+$p+[char]10+'pasta='+$d.Trim()+[char]10), (New-Object Text.UTF8Encoding $false)); Write-Host ''; Write-Host 'Configuracao salva. Use a opcao 2 para testar.'"
echo.
pause
goto menu

:testar
if not exist "%EXE%" (
  echo.
  echo __EXIBIDO_TECNICO__ nao encontrado. Instale o programa ou coloque este arquivo na pasta do portatil.
  pause
  goto menu
)
echo.
echo Testando... uma janela mostra o resultado.
start "" /wait "%EXE%" --__PREFIXO__-ftp-teste
goto menu

:desligar
if exist "%CONFIG%" del /f /q "%CONFIG%"
echo.
echo Envio desligado. As proximas gravacoes ficam neste computador.
pause
goto menu

:ver
echo.
if exist "%CONFIG%" (
  powershell -NoProfile -Command "Get-Content $env:CONFIG | Where-Object { $_ -notlike 'senha=*' } | ForEach-Object { '  ' + $_ }"
) else (
  echo   Envio desligado.
)
echo.
powershell -NoProfile -Command "$v=$env:VIDEOS; $n=@(Get-ChildItem $v -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(webm|mp4)(\.enviando)?$' }).Count; '  Gravacoes ainda neste computador: ' + $n + '  (' + $v + ')'"
echo.
pause
goto menu