# API e painel (rustdesk-api-server-pro, de lantongxue, AGPL-3.0) com os recursos do CadenaTech (cadena-api.patch):
#   - aba "Grupo" do Tecnico com todos os computadores dos clientes, num grupo de nome configuravel
#   - catalogos de enderecos compartilhados, com permissao por tecnico (painel: Catalogos)
#   - acessos em andamento (painel: Acessos agora) e correcao do fechamento de conexoes na auditoria
#   - bloqueio de login depois de 5 senhas erradas em 15 minutos (por usuario + IP)
#   - PostgreSQL (alem de SQLite e MySQL), DSN e signKey por .env ou variavel de ambiente, comando migrate-db
# Painel em pt-BR (padrao), com o nome, as cores e os logos da marca, e sem o bloco de doacao da Home.
#
# Baixa o codigo na versao testada, aplica tudo, compila o painel (Node.js) e o servidor (Go) e, se ApiInstalacao
# estiver no config.local.psd1, instala: para o processo do PM2, guarda uma copia do server.db (SQLite),
# troca o executavel e o painel, roda o "sync" das tabelas e inicia de novo. Pode ser repetido.
param([switch]$SoCompilar)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\scripts\configuracao.ps1"
$Commit = '749b84fac1eb22e1278f3453dd9c02f2eac896a4'
$Fonte = if ($Cfg.ApiFonte) { $Cfg.ApiFonte } else { "$Raiz\api-server-pro" }
$Painel = "$Fonte\soybean-admin"
$Go = if ($Cfg.Go) { $Cfg.Go } else { "$Raiz\ferramentas\go\bin" }

if (-not (Test-Path "$Fonte\.git")) {
  & git clone --quiet https://github.com/lantongxue/rustdesk-api-server-pro.git $Fonte
  if ($LASTEXITCODE -ne 0) { throw 'clone do rustdesk-api-server-pro' }
}
if ((& git -C $Fonte rev-parse HEAD) -ne $Commit) {
  & git -C $Fonte checkout --quiet -- .
  & git -C $Fonte fetch --quiet origin
  & git -C $Fonte -c advice.detachedHead=false checkout --quiet $Commit
  if ($LASTEXITCODE -ne 0) { throw "checkout de $Commit" }
}
# Comeca sempre do fonte original. Os arquivos novos do patch sao apagados antes, porque o checkout nao os remove
& git -C $Fonte checkout --quiet -- soybean-admin backend
$Patch = "$PSScriptRoot\cadena-api.patch"
foreach ($linha in (& git -C $Fonte apply --summary $Patch)) {
  if ($linha -match 'create mode \d+ (.+)$') {
    $novo = $Matches[1].Trim()
    & git -C $Fonte rm --cached --quiet --ignore-unmatch $novo
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Fonte $novo)
  }
}
& git -C $Fonte apply --whitespace=nowarn $Patch
if ($LASTEXITCODE -ne 0) { throw 'cadena-api.patch nao aplicou' }

$utf8 = New-Object Text.UTF8Encoding $false
$Titulo = $Marca.PainelTitulo
[IO.File]::WriteAllText("$Painel\src\locales\langs\pt-br.ts", ([IO.File]::ReadAllText("$PSScriptRoot\pt-br.ts", [Text.Encoding]::UTF8).Replace('__TITULO__', $Titulo.Replace("'", "\'"))), $utf8)

function Trocar([string]$arquivo, [string]$de, [string]$para) {
  $caminho = "$Painel\$arquivo"
  # O checkout pode vir com CRLF; tudo e comparado e gravado com LF
  $texto = [IO.File]::ReadAllText($caminho).Replace("`r`n", "`n")
  if (-not $texto.Contains($de)) { throw "nao encontrado em ${arquivo}: $de" }
  [IO.File]::WriteAllText($caminho, $texto.Replace($de, $para), $utf8)
}

# Idioma pt-BR registrado e usado como padrao
Trocar 'src\typings\app.d.ts' "type LangType = 'en-US' | 'zh-CN' | 'ru-RU' | 'it-IT';" "type LangType = 'en-US' | 'zh-CN' | 'ru-RU' | 'it-IT' | 'pt-BR';"
Trocar 'src\locales\locale.ts' "import itIT from './langs/it-it';" "import itIT from './langs/it-it';`nimport ptBR from './langs/pt-br';"
Trocar 'src\locales\locale.ts' "  'it-IT': itIT`n" "  'it-IT': itIT,`n  'pt-BR': ptBR`n"
Trocar 'src\locales\naive.ts' "import { dateEnUS, dateItIT, dateRuRU, dateZhCN, enUS, itIT, ruRU, zhCN } from 'naive-ui';" "import { dateEnUS, dateItIT, datePtBR, dateRuRU, dateZhCN, enUS, itIT, ptBR, ruRU, zhCN } from 'naive-ui';"
Trocar 'src\locales\naive.ts' "  'it-IT': itIT`n" "  'it-IT': itIT,`n  'pt-BR': ptBR`n"
Trocar 'src\locales\naive.ts' "  'it-IT': dateItIT`n" "  'it-IT': dateItIT,`n  'pt-BR': datePtBR`n"
Trocar 'src\locales\dayjs.ts' "import 'dayjs/locale/it';" "import 'dayjs/locale/it';`nimport 'dayjs/locale/pt-br';"
Trocar 'src\locales\dayjs.ts' "    'it-IT': 'it'`n" "    'it-IT': 'it',`n    'pt-BR': 'pt-br'`n"
Trocar 'src\locales\dayjs.ts' "lang: App.I18n.LangType = 'zh-CN'" "lang: App.I18n.LangType = 'pt-BR'"
Trocar 'src\locales\dayjs.ts' "localStg.get('lang') || 'zh-CN'" "localStg.get('lang') || 'pt-BR'"
Trocar 'src\locales\index.ts' "localStg.get('lang') || 'zh-CN'" "localStg.get('lang') || 'pt-BR'"
Trocar 'src\store\modules\app\index.ts' "localStg.get('lang') || 'zh-CN'" "localStg.get('lang') || 'pt-BR'"
Trocar 'src\store\modules\app\index.ts' "  const localeOptions: App.I18n.LangOption[] = [`n" "  const localeOptions: App.I18n.LangOption[] = [`n    {`n      label: 'Português (Brasil)',`n      key: 'pt-BR'`n    },`n"

# Titulo da aba do navegador e da tela de login
Trocar '.env' 'VITE_APP_TITLE=Rustdesk Api Server Pro' "VITE_APP_TITLE=$Titulo"
Trocar '.env' 'VITE_APP_DESC=Rustdesk Api Server Pro' "VITE_APP_DESC=$($Marca.PainelSubtitulo) - $Titulo"

# Home: sem o bloco de doacao (QR codes) e sem o historico de versoes do autor
Trocar 'src\views\home\index.vue' "import ChangeLogs from './modules/change-logs.vue';`n" ''
Trocar 'src\views\home\index.vue' "import CreativityBanner from './modules/creativity-banner.vue';`n" ''
$PaginaInicial = [IO.File]::ReadAllText("$Painel\src\views\home\index.vue").Replace("`r`n", "`n")
$PaginaInicial = [regex]::Replace($PaginaInicial, '(?s)\s*<NGrid[^>]*>\s*<NGi[^>]*>\s*<ChangeLogs />.*?</NGrid>', '')
if ($PaginaInicial -match 'ChangeLogs|CreativityBanner') { throw 'a Home ainda tem o bloco de doacao' }
[IO.File]::WriteAllText("$Painel\src\views\home\index.vue", $PaginaInicial, $utf8)
# Home: cartao "Downloads" com os links da ultima versao publicada (releases/latest de RepoAtualizacao)
if ($RepoAtualizacao) {
  $Downloads = [IO.File]::ReadAllText("$PSScriptRoot\cadena-downloads.vue", [Text.Encoding]::UTF8).Replace("`r`n", "`n")
  $Downloads = $Downloads.Replace('__REPO__', $RepoAtualizacao).Replace('__CLIENTE__', $Marca.NomeCliente).Replace('__TECNICO__', $Marca.NomeTecnico)
  [IO.File]::WriteAllText("$Painel\src\views\home\modules\cadena-downloads.vue", $Downloads, $utf8)
  Trocar 'src\views\home\index.vue' "import CardData from './modules/card-data.vue';" "import CardData from './modules/card-data.vue';`nimport CadenaDownloads from './modules/cadena-downloads.vue';"
  # Depois dos graficos, para nao atrapalhar as metricas
  Trocar 'src\views\home\index.vue' "    </NGrid>`n  </NSpace>" "    </NGrid>`n    <CadenaDownloads />`n  </NSpace>"
}

# Identidade da marca: icone (menu, favicon, Home), logo completo no login, cores e rodape
Copy-Item -Force "$PastaMarca\icone.svg" "$Painel\src\assets\svg-icon\logo.svg"
Copy-Item -Force "$PastaMarca\icone.svg" "$Painel\public\favicon.svg"
Copy-Item -Force "$PastaMarca\logo.svg" "$Painel\src\assets\imgs\marca-logo.svg"
Copy-Item -Force "$PastaMarca\logo-branco.svg" "$Painel\src\assets\imgs\marca-logo-branco.svg"
# logo.png (512 px) a partir do icone, pelo Edge headless
$Edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
if (-not (Test-Path $Edge)) { $Edge = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe' }
$tmp = Join-Path $env:TEMP 'cadena-painel'
New-Item -ItemType Directory -Force $tmp | Out-Null
$url = 'file:///' + "$PastaMarca\icone.svg".Replace('\', '/')
[IO.File]::WriteAllText("$tmp\icone.html", "<!doctype html><html><body style=`"margin:0;background:transparent;overflow:hidden`"><img src=`"$url`" style=`"width:512px;height:512px;display:block`"></body></html>")
if (Test-Path "$tmp\icone.png") { Remove-Item "$tmp\icone.png" }
$p = Start-Process $Edge -ArgumentList @('--headless=new', '--disable-gpu', "--user-data-dir=$tmp\perfil", '--hide-scrollbars', '--default-background-color=00000000', '--window-size=512,512', "--screenshot=$tmp\icone.png", ('file:///' + "$tmp\icone.html".Replace('\', '/'))) -PassThru -WindowStyle Hidden
if (-not $p.WaitForExit(60000)) { $p.Kill(); throw 'Edge nao terminou' }
for ($i = 0; $i -lt 20 -and -not (Test-Path "$tmp\icone.png"); $i++) { Start-Sleep -Milliseconds 500 }
Copy-Item -Force "$tmp\icone.png" "$Painel\src\assets\imgs\logo.png"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

Trocar 'src\theme\settings.ts' "themeColor: '#646cff'," "themeColor: '$($Marca.CorPrincipal)',"
Trocar 'src\theme\settings.ts' "info: '#2080f0'," "info: '$($Marca.CorEscura)',"
# Prefixo proprio do armazenamento do navegador: quem ja abriu o painel recebe o tema, as cores e o idioma
# novos em vez dos guardados (e precisa entrar de novo uma vez)
Trocar '.env' 'VITE_STORAGE_PREFIX=SOY_' "VITE_STORAGE_PREFIX=$($Marca.PainelPrefixo)"
# Login com o logo completo da marca (versao branca no modo escuro) no lugar do icone + titulo
$Alt = $Marca.Empresa.Replace('"', '&quot;')
Trocar 'src\views\_builtin\login\index.vue' "import PwdLogin from './modules/pwd-login.vue';" "import PwdLogin from './modules/pwd-login.vue';`nimport marcaLogo from '@/assets/imgs/marca-logo.svg';`nimport marcaLogoBranco from '@/assets/imgs/marca-logo-branco.svg';"
Trocar 'src\views\_builtin\login\index.vue' "          <SystemLogo class=`"text-64px text-primary lt-sm:text-48px`" />`n          <h3 class=`"text-28px text-primary font-500 lt-sm:text-22px`">{{ `$t('system.title') }}</h3>" "          <div class=`"flex-col`">`n            <img :src=`"themeStore.darkMode ? marcaLogoBranco : marcaLogo`" alt=`"$Alt`" class=`"h-44px lt-sm:h-34px`" />`n            <span class=`"pt-6px text-15px text-primary font-500`">$($Marca.PainelSubtitulo)</span>`n          </div>"
# Rodape: credito ao projeto original e a licenca (AGPL-3.0, que exige oferecer o fonte modificado)
Trocar 'src\layouts\modules\global-footer\index.vue' "      href=`"https://github.com/lantongxue/rustdesk-api-server-pro/blob/master/LICENSE`"" "      href=`"https://github.com/cadena89/cadenasuporte`""
Trocar 'src\layouts\modules\global-footer\index.vue' "      Copyright MIT © 2024 lantongxue" "      $($Marca.Empresa) · CadenaTech, baseado no rustdesk-api-server-pro (lantongxue), licença AGPL-3.0"

"=== compilando o painel"
Push-Location $Painel
& npx --yes pnpm@9.15.9 install --frozen-lockfile --ignore-scripts --shamefully-hoist --config.confirmModulesPurge=false
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "pnpm install saiu com $LASTEXITCODE" }
& npx --yes pnpm@9.15.9 build
$codigo = $LASTEXITCODE
Pop-Location
if ($codigo -ne 0) { throw "pnpm build saiu com $codigo" }

"=== compilando o servidor da API"
$env:PATH = "$Go;$env:PATH"
if (-not $env:GOPATH) { $env:GOPATH = "$Raiz\ferramentas\gopath" }
if (-not $env:GOCACHE) { $env:GOCACHE = "$Raiz\ferramentas\gocache" }
$env:GOTOOLCHAIN = 'local'; $env:CGO_ENABLED = '0'
& go build -C "$Fonte\backend" -o "$Fonte\build\rustdesk-api-server-pro.exe" .
if ($LASTEXITCODE -ne 0) { throw "go build saiu com $LASTEXITCODE" }
"Compilado: $Fonte\build\rustdesk-api-server-pro.exe e $Painel\dist"
if ($SoCompilar -or -not $Cfg.ApiInstalacao) { "Instalacao pulada (ApiInstalacao nao definido ou -SoCompilar)."; return }

$Instalado = $Cfg.ApiInstalacao
$Pm2 = $Cfg.ApiPm2
$Processo = if ($Cfg.ApiProcesso) { $Cfg.ApiProcesso } else { 'rustdesk-api' }
"=== instalando em $Instalado (PM2 $Processo) e atualizando as tabelas"
if ($Pm2) { & $Pm2 stop $Processo | Out-Null }
if (Test-Path "$Instalado\server.db") { Copy-Item -Force "$Instalado\server.db" "$Instalado\server.db.antes-da-atualizacao" }
if (Test-Path "$Instalado\dist") { Remove-Item -Recurse -Force "$Instalado\dist" }
Copy-Item -Recurse "$Painel\dist" "$Instalado\dist"
# O pm2 stop nao solta o exe na hora: tenta de novo por ate 60 s e, se nao der, sobe o servico antes de parar
$copiado = $false
for ($i = 0; $i -lt 60 -and -not $copiado; $i++) {
  try { Copy-Item -Force "$Fonte\build\rustdesk-api-server-pro.exe" "$Instalado\rustdesk-api-server-pro.exe" -ErrorAction Stop; $copiado = $true }
  catch { Start-Sleep -Seconds 1 }
}
if (-not $copiado) {
  if ($Pm2) { & $Pm2 start $Processo | Out-Null }
  throw "nao foi possivel trocar $Instalado\rustdesk-api-server-pro.exe (arquivo em uso)"
}
Push-Location $Instalado
& .\rustdesk-api-server-pro.exe sync
$codigo = $LASTEXITCODE
Pop-Location
if ($Pm2) { & $Pm2 start $Processo | Out-Null }
if ($codigo -ne 0) { throw "sync saiu com $codigo" }
"Pronto. Recarregue o painel no navegador (Ctrl+F5)."
