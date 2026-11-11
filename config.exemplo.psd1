@{
  # Copie para config.local.psd1 (ignorado pelo Git) e preencha. Ou aponte CADENA_CONFIG para outro arquivo.
  # Qualquer valor pode ser trocado por variavel de ambiente (ver scripts\configuracao.ps1).

  # Pasta de marcas\ (ex.: 'cadenatech') ou caminho completo de uma marca propria, fora do repositorio
  Marca     = 'cadenatech'

  # Ferramentas (Rust, Flutter, vcpkg...) e codigo do RustDesk ficam aqui; os instaladores gerados, em Entrega
  Raiz      = 'D:\rustdesk-build'
  Entrega   = 'D:\rustdesk-build\entrega'
  TagRustDesk = '1.5.3'
  # Distribuicao do WSL usada para compilar o Android
  DistroWsl = 'CadenaBuild'

  # Servidor hbbs/hbbr proprio. Chave = conteudo do id_ed25519.pub do hbbs (publica, mas fica fora do Git
  # junto com o endereco). Nome = texto ao lado do "Pronto" no programa
  Servidor1 = @{ Endereco = '203.0.113.10'; Chave = 'COLE_A_CHAVE_PUBLICA_DO_HBBS='; Nome = 'Principal' }
  # Opcional: segundo servidor, usado ao mesmo tempo (registro do Cliente) e como segunda tentativa do Tecnico
  Servidor2 = @{ Endereco = ''; Chave = ''; Nome = '' }

  # API (rustdesk-api-server-pro com os recursos deste repositorio), por HTTPS
  Api       = 'https://api.exemplo.com.br'

  # Atualizacao automatica do Windows: repositorio do GitHub com as releases e o par de chaves Ed25519.
  # Gere as chaves uma vez (veja o README) e guarde a privada fora do repositorio e com backup
  RepoAtualizacao = 'usuario/repositorio-das-releases'
  ChavePublica    = 'C:\caminho\privado\atualizacao\chave-publica.txt'
  ChavePrivada    = 'C:\caminho\privado\atualizacao\atualizacao.pem'

  # Assinatura de codigo (opcional): certificado autoassinado da marca, gerado uma vez com
  # scripts\gerar_certificado.ps1. O .cer vai embutido e o instalador o grava como confiavel no computador
  Certificado      = 'C:\caminho\privado\assinatura-codigo\certificado.cer'
  CertificadoPfx   = 'C:\caminho\privado\assinatura-codigo\certificado.pfx'
  CertificadoSenha = 'C:\caminho\privado\assinatura-codigo\senha.txt'

  # Assinatura do Android: criada na primeira compilacao se nao existir. Guarde com backup: sem ela, o APK
  # seguinte nao instala por cima do anterior
  AndroidChave  = 'C:\caminho\privado\android\suporte.jks'
  AndroidSenhas = 'C:\caminho\privado\android\senha.properties'

  # API (opcional, api\atualizar_api.ps1): pasta do codigo e, para instalar, a pasta do servidor e o PM2
  ApiFonte      = 'D:\rustdesk-build\api-server-pro'
  ApiInstalacao = ''
  ApiPm2        = ''
  ApiProcesso   = 'rustdesk-api'
}
