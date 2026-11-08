@{
  # Marca CadenaTech (padrao do repositorio). Para criar outra marca, copie esta pasta, troque os textos, as cores
  # e os SVGs, e aponte "Marca" do config.local.psd1 para ela. Nada aqui e segredo: servidores, chaves e senhas
  # ficam no config.local.psd1 (fora do Git) ou em variaveis de ambiente.

  # Nomes internos, sem espacos: pastas, servico do Windows, .exe e pipes (o RustDesk usa o nome sem aspas em
  # "sc" e "taskkill"). Mudar depois de instalado cria um programa novo nas maquinas.
  NomeCliente    = 'CadenaSuporte'
  NomeTecnico    = 'CadenaTecnico'
  # Nomes mostrados na tela, nos atalhos e em Programas instalados
  ExibidoCliente = 'Cadena Suporte'
  ExibidoTecnico = 'Cadena Técnico'
  Empresa        = 'CadenaTech'
  # Prefixo dos arquivos de configuracao do tecnico (<prefixo>-ftp.txt, <prefixo>-nome-tecnico.txt) e das
  # opcoes de linha de comando (--<prefixo>-nome, --<prefixo>-ftp-teste)
  Prefixo        = 'cadena'

  # Identificadores
  Organizacao    = 'br.com.cadenatech'
  AndroidId      = 'br.com.cadenatech.suporte'
  EsquemaUrl     = 'cadenasuporte'
  Site           = 'https://cadenatech.com.br/'
  # Dono do certificado do Android, usado so quando a chave e criada pela primeira vez
  AndroidDono    = 'CN=CadenaTech, O=CadenaTech, C=BR'

  # Cores (#RRGGBB): principal (botoes, destaque), escura (fundo do icone do Android e dos avisos) e a do ID
  CorPrincipal   = '#016BFB'
  CorEscura      = '#0A4FC4'
  CorId          = '#0BC5EA'
  # Fundo do aviso de golpe do Android, fundo do icone adaptavel e degrade do icone redondo do Android
  CorAvisoAndroid = '#016BFB'
  CorFundoAndroid = '#016BFB'
  GradienteIcone = @('#1A7DFF', '#0062F0')

  # Textos de seguranca. Sem telefone por padrao: quem usar a marca pode acrescentar o seu canal oficial
  AvisoAndroid   = @(
    'Ao continuar, quem estiver conectado poderá ver a tela e controlar este celular.'
    'Continue somente se você pediu este atendimento e reconhece quem está falando com você.'
    'Recebeu uma ligação inesperada ou ficou na dúvida? Toque em Recusar e confirme pelos canais oficiais de quem presta o suporte.'
    'Nenhum suporte legítimo pede senhas de banco, códigos recebidos por SMS ou pagamentos durante o atendimento.'
  )
  AvisoJanela    = 'Só aceite se você pediu este atendimento e reconhece quem está conectando. Na dúvida, clique em Cancelar.'
  TextoId        = 'Informe este ID ao suporte. Quando o técnico conectar, uma janela vai pedir a sua aprovação.'
  TextoLogin     = 'Entre com a sua conta antes de acessar: Configurações > Conta > Login.'

  # Painel web da API
  PainelTitulo   = 'Cadena Suporte'
  PainelSubtitulo = 'Painel do Suporte'
  PainelPrefixo  = 'CADENA_'
}
