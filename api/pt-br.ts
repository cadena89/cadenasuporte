// Traducao pt-BR do painel do rustdesk-api-server-pro (CadenaTech). O atualizar_api.ps1 troca __TITULO__ pela marca.
// Copiada para soybean-admin/src/locales/langs/pt-br.ts pelo api/atualizar_api.ps1.
const local: App.I18n.Schema = {
  system: {
    title: '__TITULO__',
    updateTitle: 'Nova versão do sistema',
    updateContent: 'Uma nova versão do sistema foi detectada. Deseja recarregar a página agora?',
    updateConfirm: 'Recarregar agora',
    updateCancel: 'Depois'
  },
  common: {
    action: 'Ação',
    add: 'Adicionar',
    addSuccess: 'Adicionado com sucesso',
    backToHome: 'Voltar ao início',
    batchDelete: 'Excluir selecionados',
    cancel: 'Cancelar',
    close: 'Fechar',
    check: 'Verificar',
    expandColumn: 'Expandir coluna',
    columnSetting: 'Configurar colunas',
    config: 'Configuração',
    confirm: 'Confirmar',
    delete: 'Excluir',
    deleteSuccess: 'Excluído com sucesso',
    confirmDelete: 'Tem certeza de que deseja excluir?',
    edit: 'Editar',
    look: 'Ver',
    warning: 'Aviso',
    error: 'Erro',
    index: 'Nº',
    keywordSearch: 'Digite uma palavra-chave',
    logout: 'Sair',
    logoutConfirm: 'Tem certeza de que deseja sair?',
    lookForward: 'Em breve',
    modify: 'Alterar',
    modifySuccess: 'Alterado com sucesso',
    noData: 'Nenhum dado',
    operate: 'Operar',
    pleaseCheckValue: 'Verifique se o valor é válido',
    refresh: 'Atualizar',
    reset: 'Limpar',
    search: 'Pesquisar',
    switch: 'Alternar',
    tip: 'Dica',
    trigger: 'Acionar',
    update: 'Atualizar',
    updateSuccess: 'Atualizado com sucesso',
    userCenter: 'Minha conta',
    yesOrNo: {
      yes: 'Sim',
      no: 'Não'
    }
  },
  request: {
    logout: 'Sair após falha na requisição',
    logoutMsg: 'Sua sessão não é mais válida. Entre novamente',
    logoutWithModal: 'Mostrar aviso após falha na requisição e sair',
    logoutWithModalMsg: 'Sua sessão não é mais válida. Entre novamente',
    refreshToken: 'O token expirou e será renovado',
    tokenExpired: 'O token expirou'
  },
  theme: {
    themeSchema: {
      title: 'Aparência',
      light: 'Claro',
      dark: 'Escuro',
      auto: 'Seguir o sistema'
    },
    grayscale: 'Tons de cinza',
    colourWeakness: 'Modo daltonismo',
    layoutMode: {
      title: 'Disposição',
      vertical: 'Menu vertical',
      horizontal: 'Menu horizontal',
      'vertical-mix': 'Menu vertical misto',
      'horizontal-mix': 'Menu horizontal misto',
      reverseHorizontalMix: 'Inverter a posição dos menus principal e secundário'
    },
    recommendColor: 'Aplicar o algoritmo de cores recomendado',
    recommendColorDesc: 'O algoritmo de cores recomendado segue',
    themeColor: {
      title: 'Cores do tema',
      primary: 'Principal',
      info: 'Informação',
      success: 'Sucesso',
      warning: 'Aviso',
      error: 'Erro',
      followPrimary: 'Seguir a principal'
    },
    scrollMode: {
      title: 'Rolagem',
      wrapper: 'Janela inteira',
      content: 'Só o conteúdo'
    },
    page: {
      animate: 'Animação de página',
      mode: {
        title: 'Tipo de animação',
        fade: 'Esmaecer',
        'fade-slide': 'Deslizar',
        'fade-bottom': 'Esmaecer e aproximar',
        'fade-scale': 'Esmaecer e escalar',
        'zoom-fade': 'Aproximar e esmaecer',
        'zoom-out': 'Afastar',
        none: 'Nenhuma'
      }
    },
    fixedHeaderAndTab: 'Fixar cabeçalho e abas',
    header: {
      height: 'Altura do cabeçalho',
      breadcrumb: {
        visible: 'Mostrar trilha de navegação',
        showIcon: 'Mostrar ícones na trilha'
      }
    },
    tab: {
      visible: 'Mostrar abas',
      cache: 'Guardar abas',
      height: 'Altura das abas',
      mode: {
        title: 'Estilo das abas',
        chrome: 'Chrome',
        button: 'Botão'
      }
    },
    sider: {
      inverted: 'Menu lateral escuro',
      width: 'Largura do menu lateral',
      collapsedWidth: 'Largura do menu recolhido',
      mixWidth: 'Largura do menu misto',
      mixCollapsedWidth: 'Largura do menu misto recolhido',
      mixChildMenuWidth: 'Largura do submenu misto'
    },
    footer: {
      visible: 'Mostrar rodapé',
      fixed: 'Fixar rodapé',
      height: 'Altura do rodapé',
      right: 'Rodapé à direita'
    },
    watermark: {
      visible: 'Marca d’água em tela cheia',
      text: 'Texto da marca d’água'
    },
    themeDrawerTitle: 'Configuração do tema',
    pageFunTitle: 'Funções da página',
    configOperation: {
      copyConfig: 'Copiar configuração',
      copySuccessMsg: 'Copiado. Substitua a variável "themeSettings" em "src/theme/settings.ts"',
      resetConfig: 'Restaurar configuração',
      resetSuccessMsg: 'Configuração restaurada'
    }
  },
  route: {
    login: 'Entrar',
    403: 'Sem permissão',
    404: 'Página não encontrada',
    500: 'Erro no servidor',
    'iframe-page': 'Iframe',
    home: 'Início',
    audit: 'Auditoria',
    user: 'Usuários',
    user_list: 'Lista de usuários',
    user_sessions: 'Sessões',
    system: 'Sistema',
    system_mail_template: 'Modelos de e-mail',
    system_mail_logs: 'E-mails enviados',
    system_mail: 'E-mail',
    audit_baselogs: 'Registro de acessos',
    audit_filetransferlogs: 'Transferências de arquivos',
    audit_alarms: 'Alertas de segurança',
    devices: 'Dispositivos',
    catalogs: 'Catálogos compartilhados',
    connections: 'Acessos agora'
  },
  page: {
    login: {
      common: {
        loginOrRegister: 'Entrar / Cadastrar',
        userNamePlaceholder: 'Digite o usuário',
        phonePlaceholder: 'Digite o telefone',
        codePlaceholder: 'Digite o código de verificação',
        passwordPlaceholder: 'Digite a senha',
        confirmPasswordPlaceholder: 'Digite a senha novamente',
        codeLogin: 'Entrar com código de verificação',
        confirm: 'Confirmar',
        back: 'Voltar',
        validateSuccess: 'Verificação concluída',
        loginSuccess: 'Login realizado',
        welcomeBack: 'Bem-vindo de volta, {userName}!'
      },
      pwdLogin: {
        title: 'Entrar com senha',
        rememberMe: 'Lembrar de mim'
      }
    },
    home: {
      greeting: 'Olá, {userName}! Bom trabalho hoje.',
      friendlySponsorship: 'Patrocínio',
      cupOfCoffee: 'Me paga um café?',
      thankYou: 'Obrigado pelo patrocínio',
      userCount: 'Usuários',
      deviceCount: 'Dispositivos',
      onlineCount: 'Online',
      visitsCount: 'Acessos',
      operatingSystem: 'Sistema operacional',
      oneWeek: 'Última semana',
      changeLogs: 'Novidades'
    },
    user: {
      list: {
        addUser: 'Adicionar usuário',
        editUser: 'Editar usuário',
        inputUsername: 'Digite o usuário',
        inputPassword: 'Digite a senha',
        inputNickname: 'Digite o nome',
        emailFormatError: 'E-mail inválido',
        selectUserStatus: 'Selecione a situação do usuário',
        searchPlaceholder: 'Usuário\\Nome\\E-mail',
        tfa_secret_bind: 'Vincular dispositivo 2FA',
        require2FASecret: 'Informe o segredo 2FA',
        require2FACode: 'Informe o código 2FA'
      },
      sessions: {
        kill: 'Encerrar',
        confirmKill: 'Encerrar esta sessão?'
      },
      audit: {
        logsSearchPlaceholder: 'Usuário\\Ação\\ID\\IP'
      },
      devices: {
        logsSearchPlaceholder: 'Computador\\Usuário\\ID'
      }
    },
    system: {
      mailTemplate: {
        addMailTemplate: 'Adicionar modelo',
        editMailTemplate: 'Editar modelo',
        inputName: 'Digite o nome',
        inputSubject: 'Digite o assunto',
        inputContents: 'Digite o conteúdo',
        selectType: 'Selecione o tipo'
      },
      mailLog: {
        info: 'Detalhes'
      }
    }
  },
  dropdown: {
    closeCurrent: 'Fechar esta',
    closeOther: 'Fechar as outras',
    closeLeft: 'Fechar à esquerda',
    closeRight: 'Fechar à direita',
    closeAll: 'Fechar todas'
  },
  icon: {
    themeConfig: 'Configuração do tema',
    themeSchema: 'Aparência',
    lang: 'Mudar idioma',
    fullscreen: 'Tela cheia',
    fullscreenExit: 'Sair da tela cheia',
    reload: 'Recarregar página',
    collapse: 'Recolher menu',
    expand: 'Expandir menu',
    pin: 'Fixar',
    unpin: 'Soltar'
  },
  datatable: {
    itemCount: 'Total de {total} itens'
  },
  dataMap: {
    user: {
      username: 'Usuário',
      password: 'Senha',
      name: 'Nome',
      email: 'E-mail',
      licensed_devices: 'Dispositivos permitidos',
      login_verify: 'Verificação no login',
      status: 'Situação',
      is_admin: 'Administrador',
      tfa_secret: 'Segredo 2FA',
      tfa_code: 'Código 2FA',
      created_at: 'Criado em',
      statusLabel: {
        disabled: 'Desativado',
        unverified: 'Não verificado',
        normal: 'Ativo'
      },
      loginVerifyLabel: {
        none: 'Nenhuma',
        emailCheck: 'Código por e-mail',
        tfaCheck: '2FA'
      }
    },
    session: {
      expired: 'Expira em',
      created_at: 'Criada em'
    },
    device: {
      username: 'Usuário',
      hostname: 'Computador',
      version: 'Versão',
      memory: 'Memória',
      os: 'Sistema',
      rustdesk_id: 'ID'
    },
    audit: {
      username: 'Usuário',
      type: 'Tipo',
      conn_id: 'Conexão',
      rustdesk_id: 'ID',
      ip: 'IP',
      session_id: 'Sessão',
      uuid: 'UUID',
      created_at: 'Início',
      closed_at: 'Fim',
      typeLabel: {
        remote_control: 'Acesso remoto',
        file_transfer: 'Transferência de arquivos',
        tcp_tunnel: 'Túnel TCP'
      },
      fileTransferTypeLabel: {
        master_controlled: 'Técnico -> Cliente',
        controlled_master: 'Cliente -> Técnico'
      },
      peer_id: 'ID do outro lado',
      path: 'Caminho'
    },
    mailTemplate: {
      name: 'Nome',
      type: 'Tipo',
      subject: 'Assunto',
      contents: 'Conteúdo',
      created_at: 'Criado em',
      typeLabel: {
        loginVerify: 'Verificação de login',
        registerVerify: 'Verificação de cadastro',
        other: 'Outro'
      }
    },
    mailLog: {
      username: 'Usuário',
      uuid: 'UUID',
      from: 'De',
      to: 'Para',
      subject: 'Assunto',
      contents: 'Conteúdo',
      status: 'Situação',
      created_at: 'Enviado em',
      statusLabel: {
        ok: 'Enviado',
        err: 'Erro'
      }
    }
  },
  api: {
    CaptchaError: 'Código de verificação incorreto',
    UserNotExists: 'Usuário não encontrado ou sem permissão de administrador. Contas de técnico entram pelo programa Técnico, não pelo painel.',
    UsernameOrPasswordError: 'Usuário ou senha incorretos',
    UserExists: 'Este usuário já existe',
    UsernameEmpty: 'Informe o usuário',
    PasswordEmpty: 'Informe a senha',
    UserAddSuccess: 'Usuário criado',
    DataError: 'Dados inválidos',
    UserUpdateSuccess: 'Usuário alterado',
    UserDeleteSuccess: 'Usuário excluído',
    SessionKillSuccess: 'Sessão encerrada',
    MailTemplateNameEmpty: 'Informe o nome',
    MailTemplateSubjectEmpty: 'Informe o assunto',
    MailTemplateContentsEmpty: 'Informe o conteúdo',
    MailTemplateAddSuccess: 'Modelo de e-mail criado',
    MailTemplateUpdateSuccess: 'Modelo de e-mail alterado',
    NoEmailAddress: 'Nenhum e-mail cadastrado',
    VerificationCodeError: 'Código de verificação incorreto',
    UUIDEmpty: 'Informe o UUID',
    LoginBlocked: 'Muitas tentativas de login. Tente de novo em 15 minutos.',
    CatalogNameEmpty: 'Informe o nome do catálogo',
    CatalogRuleInvalid: 'Permissão inválida',
    CatalogNotFound: 'Catálogo não encontrado',
    CatalogSaved: 'Catálogo salvo',
    CatalogDeleted: 'Catálogo excluído',
    ConnectionNotFound: 'Acesso não encontrado ou já encerrado',
    DisconnectRequested: 'Pedido de desconexão enviado'
  }
};

export default local;
