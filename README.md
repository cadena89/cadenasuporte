<p align="center">
  <img src="marcas/cadenatech/logo.svg" alt="CadenaTech" width="420">
</p>

# Cadena Suporte

Acesso remoto para equipes de suporte, baseado no [RustDesk](https://github.com/rustdesk/rustdesk), com servidor próprio, marca configurável e um painel de gestão em português. Projeto 100% open source, sob a licença **AGPL-3.0**.

O repositório **não traz uma cópia do RustDesk**. Os scripts baixam o código original numa versão fixa (tag `1.5.1`), aplicam as modificações e a marca e compilam. Assim cada mudança fica legível e é fácil acompanhar versões novas do RustDesk.

## O que vem pronto

**Dois programas para Windows e Android**, gerados do mesmo código:

- **Cadena Suporte** (Cliente), instalado no computador atendido. Só recebe acesso. Cada conexão abre uma janela de aprovação com um aviso contra golpes; o Android mostra o mesmo aviso. Há também um instalador silencioso que já define senha e ID.
- **Cadena Técnico**, para quem atende. Só acessa e exige login na conta da API. A tela inicial tem uma lateral com Clientes, Recentes, Favoritos e Catálogos, a conta e o status dos servidores, e cartões por computador (sistema, online, favorito, Conectar); em janela estreita a lateral fica só com os ícones. Clientes lista os computadores dos clientes. Cada acesso é gravado, e as gravações podem ir sozinhas para um servidor FTP (Configurações > Geral, com endereço para a rede local e para fora).

**Servidor próprio, com reserva automática.** O servidor e a chave vão embutidos e travados no programa. Um segundo servidor é opcional:

- o Cliente se registra nos dois servidores;
- o Técnico procura o ID no segundo quando o primeiro não responde;
- a tela mostra `Pronto · Principal, Reserva` com os servidores que respondem, ou `Sem conexão com o servidor` com a bolinha vermelha.

**Atualização automática no Windows.** Cada release no GitHub é assinada com Ed25519. O programa instalado confere a assinatura e o SHA-256 do instalador antes de se atualizar, e só faz isso quando não há acesso em andamento.

**API e painel web**, a partir do [rustdesk-api-server-pro](https://github.com/lantongxue/rustdesk-api-server-pro) com recursos a mais:

- tradução pt-BR e identidade da marca;
- catálogos de endereços compartilhados, com permissão por técnico;
- tela de acessos em andamento;
- registro de acessos com técnico, hora final e as gravações enviadas por FTP (botão Assistir, em `pastasGravacoes`);
- derrubar um acesso pelo painel (Acessos agora > Desconectar), alertas de segurança enviados pelos Clientes e limpeza automática de registros e gravações (`diasRegistros`, `diasGravacoes`);
- registro das ações do painel (quem criou, editou ou excluiu algo e cada entrada no painel, sem senhas) e exportação para CSV nas telas de auditoria;
- 2FA (código do autenticador) no login do painel para quem tem "2FA" em Verificação no login, e o papel **auditor**, que entra no painel só para ver a auditoria, as gravações e os acessos agora;
- bloqueio de login depois de tentativas erradas;
- **PostgreSQL**, além de SQLite e MySQL, e o comando `migrate-db` para migrar os dados.

## Estrutura

```
marcas/cadenatech/      marca padrao: marca.psd1 (nomes, cores, textos) + SVGs (icone, simbolo, logos)
scripts/                compilacao do app (Windows e Android)
  configuracao.ps1      le config.local.psd1 / variaveis de ambiente e a marca
  0_nova_versao.ps1     tudo de uma vez: marca, Windows, Android, release assinada (-Publicar)
  1_ferramentas.ps1     Rust 1.75, Flutter 3.24.5, LLVM, vcpkg e o codigo do RustDesk
  2_marca.ps1           aplica marca, servidores, chaves e as modificacoes no codigo do RustDesk
  3_dependencias.ps1    bibliotecas C (vcpkg) e geradores da ponte Flutter/Rust
  4_compilar.ps1        compila (build.py --flutter)
  6_empacotar.ps1       instalador unico + pacote de fonte da AGPL (patches)
  8_compilar_perfis.ps1 Tecnico e Cliente, atalhos .bat e instalador silencioso
  9_publicar.ps1        release com versao.assinado (atualizacao automatica)
  gerar_chave_atualizacao.ps1  par de chaves Ed25519 da atualizacao (guardado fora do repositorio)
  modelos/              modulo de FTP (Rust), tela do FTP (Dart), .bat do tecnico
  instalador-silencioso/  instalador do Cliente (C#, .NET Framework)
  android/              compilacao do Android num WSL (Ubuntu) dedicado
api/                    API e painel: cadena-api.patch, pt-br.ts, atualizar_api.ps1, exemplos de configuracao
config.exemplo.psd1     modelo da configuracao local (copie para config.local.psd1)
```

## Configuração

Nada de segredo ou de endereço de servidor fica no repositório. Copie `config.exemplo.psd1` para `config.local.psd1` (o arquivo é ignorado pelo Git) e preencha:

| Chave | Para que serve |
|---|---|
| `Marca` | `cadenatech` ou o caminho de uma marca própria, fora do repositório |
| `Raiz`, `Entrega` | pasta das ferramentas e do código do RustDesk; pasta dos instaladores gerados |
| `Servidor1`, `Servidor2` | endereço do hbbs, chave pública (`id_ed25519.pub`) e o nome mostrado na tela |
| `Api` | endereço HTTPS da API |
| `RepoAtualizacao`, `ChavePublica`, `ChavePrivada` | releases da atualização automática e o par de chaves Ed25519 |
| `AndroidChave`, `AndroidSenhas` | keystore do Android (criada na primeira compilação, se não existir) |

Também dá para usar variáveis de ambiente, úteis num CI: `CADENA_SERVIDOR1`, `CADENA_CHAVE1`, `CADENA_SERVIDOR2`, `CADENA_CHAVE2`, `CADENA_API`, `CADENA_REPO_ATUALIZACAO`, `CADENA_CHAVE_ATUALIZACAO`, `CADENA_MARCA` e as demais listadas em [`scripts/configuracao.ps1`](scripts/configuracao.ps1).

### Sua própria marca

1. Copie `marcas/cadenatech` para uma pasta fora do repositório.
2. Troque nomes, cores e textos de segurança no `marca.psd1`; se quiser, ponha o telefone oficial no aviso. Salve em UTF-8.
3. Troque os SVGs:
   - `icone.svg`: ícone completo. Sem `<mask>`, porque o Flutter não desenha.
   - `simbolo-branco.svg`: só o símbolo, em branco.
   - `logo.svg` e `logo-branco.svg`: logo horizontal para fundo claro e escuro.
4. Aponte `Marca` do `config.local.psd1` para essa pasta.

Os nomes internos (`NomeCliente`, `NomeTecnico`) não podem ter espaços e não devem mudar depois de instalados.

## Como compilar (Windows 10/11 x64)

Pré-requisitos: Git for Windows, Microsoft Edge (para renderizar os SVGs), Visual Studio 2022 Build Tools com C++ e, para o Android, WSL 2.

```powershell
copy config.exemplo.psd1 config.local.psd1   # e preencha
powershell -ExecutionPolicy Bypass -File scripts\gerar_chave_atualizacao.ps1 -Pasta D:\privado\atualizacao
powershell -ExecutionPolicy Bypass -File scripts\1_ferramentas.ps1
powershell -ExecutionPolicy Bypass -File scripts\3_dependencias.ps1
powershell -ExecutionPolicy Bypass -File scripts\0_nova_versao.ps1 -SemAndroid
```

Para o Android, rode uma vez `scripts\android\1_criar_wsl.ps1` e depois `0_nova_versao.ps1` sem `-SemAndroid`. Para publicar a release no GitHub (com o GitHub CLI logado), acrescente `-Publicar`.

### API

```powershell
powershell -ExecutionPolicy Bypass -File api\atualizar_api.ps1 -SoCompilar
```

Para trocar o SQLite pelo PostgreSQL, faça nesta ordem:

1. Crie o banco.
2. Configure `RUSTDESK_API_DB_DRIVER` e `RUSTDESK_API_DB_DSN` no `.env` da pasta do servidor (veja [`api/.env.exemplo`](api/.env.exemplo)).
3. Copie os dados:

   ```
   rustdesk-api-server-pro.exe migrate-db --from-driver sqlite --from-dsn ./server.db --to-driver postgres
   ```

## Assinatura de código

Os instaladores do Windows são compilados no GitHub Actions pelo workflow [`.github/workflows/windows.yml`](.github/workflows/windows.yml). Ele roda manualmente (Actions > Windows > Run workflow, informando o número da versão) ou a cada tag `v<versão>-<número>`, por exemplo `v1.5.1-2`.

**Variáveis do workflow** (Settings > Secrets and variables > Actions > Variables):

- servidor principal: `CADENA_SERVIDOR1`, `CADENA_CHAVE1`, `CADENA_NOME1`;
- segundo servidor, opcional: `CADENA_SERVIDOR2`, `CADENA_CHAVE2`, `CADENA_NOME2`;
- API: `CADENA_API`;
- atualização automática: `CADENA_REPO_ATUALIZACAO` e `CADENA_CHAVE_ATUALIZACAO`, a chave **pública**.

O workflow publica os executáveis como artefatos, junto com o pacote de fonte da AGPL.

A assinatura fica com a [SignPath Foundation](https://signpath.org), que oferece certificados gratuitos para projetos open source. O certificado sai em nome da *SignPath Foundation*. Para ligar a assinatura:

1. Peça a adesão do projeto em signpath.org.
2. Depois da aprovação, defina as variáveis `SIGNPATH_ORGANIZATION_ID`, `SIGNPATH_PROJECT_SLUG` e `SIGNPATH_SIGNING_POLICY_SLUG` e o segredo `SIGNPATH_API_TOKEN`.

A partir daí, cada execução envia os executáveis ao SignPath e publica também o artefato `windows-assinado`.

A chave **privada** da atualização automática nunca vai para o GitHub. Para montar a release, baixe os executáveis assinados para a pasta de entrega e rode `scripts\9_publicar.ps1 -SemCompilar` na máquina que guarda a chave.

**Limitação conhecida:** o `Instalar*.exe` (instalador silencioso) leva dentro uma cópia do Cliente feita antes da assinatura. Só o arquivo de fora sai assinado.

## Licença e créditos

O projeto é distribuído sob a [GNU AGPL-3.0](LICENSE). Quem distribuir os programas ou oferecer a API pela rede precisa disponibilizar o código-fonte modificado; o `6_empacotar.ps1` gera esse pacote a cada versão.

- [RustDesk](https://github.com/rustdesk/rustdesk): © Purslane Tech Pte. Ltd., AGPL-3.0.
- [rustdesk-api-server-pro](https://github.com/lantongxue/rustdesk-api-server-pro): lantongxue, AGPL-3.0.
- "RustDesk" é marca dos seus titulares. Este projeto não é afiliado nem endossado por eles.

Veja também [CONTRIBUTING.md](CONTRIBUTING.md) e [SECURITY.md](SECURITY.md).
