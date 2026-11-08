# Como contribuir

Contribuições são bem-vindas: correções, traduções, documentação e recursos novos.

## Antes de começar

- Abra uma *issue* descrevendo o problema ou a ideia, principalmente se a mudança for grande.
- Escreva em português (pt-BR). Mensagens de commit podem ser em português ou inglês.

## Como o código está organizado

Este repositório não contém o RustDesk. Ele contém os **scripts que modificam** o código original:

- `scripts/2_marca.ps1` aplica as mudanças no RustDesk com a função `Trocar`. Ela procura um trecho exato do código original (expressão regular) e o substitui. Se o trecho não existir, por exemplo numa versão nova do RustDesk, o script para com a mensagem `nao encontrado em <arquivo>`. Nesse caso, ajuste o padrão para o código novo.
- Módulos inteiros e telas novas ficam em `scripts/modelos/`.
- A API é modificada pelo `api/cadena-api.patch`. Para mudar a API:

  1. Rode `api\atualizar_api.ps1 -SoCompilar`.
  2. Edite os arquivos em `<ApiFonte>` (o clone do rustdesk-api-server-pro).
  3. Gere o patch de novo com `git diff` (use `git add -N` nos arquivos novos), só com os arquivos de recurso. Os arquivos de marca (`.env`, login, rodapé, idiomas) são trocados pelo script, não pelo patch.

## Regras

1. **Nada de segredos no Git**:
   - endereços e chaves de servidor, senhas e DSN;
   - chaves privadas (`*.pem`), keystores (`*.jks`, `senha.properties`);
   - bancos (`server.db`) e credenciais de FTP ou de túnel.

   Use o `config.local.psd1`, o `.env` ou variáveis de ambiente. Rode `git status` antes de cada commit.
2. **Nenhuma marca de cliente no repositório**: marcas próprias ficam fora dele (`Marca` no `config.local.psd1`). A pasta `marcas/` só tem a CadenaTech.
3. **Textos de segurança** (aviso de golpe, janela de aprovação) precisam continuar claros para leigos.
4. Scripts PowerShell devem rodar no Windows PowerShell 5.1 e ser salvos em **UTF-8 com BOM** se tiverem acentos. Os arquivos `.psd1` são lidos sempre em UTF-8.
5. Teste antes de abrir o *pull request*:
   - rode o `2_marca.ps1` e compile pelo menos o Cliente do Windows;
   - para mudanças na API, teste com SQLite **e** PostgreSQL.

## Licença das contribuições

Ao contribuir, você concorda em licenciar a sua contribuição sob a [AGPL-3.0](LICENSE), a mesma do projeto.
