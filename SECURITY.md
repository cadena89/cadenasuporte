# Segurança

## Como relatar uma vulnerabilidade

Não abra uma *issue* pública. Use o relato privado do GitHub em **Security > Report a vulnerability** neste repositório, com:

- o que acontece e o impacto;
- os passos para reproduzir;
- a versão (número da release) e o sistema.

Respondemos assim que possível e combinamos a divulgação depois da correção.

## Cuidados para quem publica a sua própria versão

- **Chave privada da atualização automática**, o `atualizacao.pem` gerado pelo `scripts/gerar_chave_atualizacao.ps1`. Quem tiver esse arquivo consegue instalar qualquer programa nas máquinas com o Cliente. Por isso:
  - guarde-a fora do repositório, com backup, e nunca a envie a ninguém;
  - se ela vazar, gere outra, publique uma versão nova e reinstale nas máquinas.
- **Keystore do Android**: sem ela, os APKs seguintes não instalam por cima dos anteriores. Também fica fora do repositório.
- **API**: publique só por HTTPS (proxy reverso ou túnel) e deixe o servidor ouvindo em `127.0.0.1`. Guarde a `signKey` e o DSN do banco no `.env`, nunca no Git.
- O hbbs/hbbr próprio deve ter a chave (`id_ed25519`) protegida; só a chave pública vai no programa.
