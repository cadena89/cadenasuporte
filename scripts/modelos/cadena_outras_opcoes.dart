  // CadenaTech: a secao "Outro" das Configuracoes > Geral virou tres secoes (aprovado em 2026-11-13): Interface e
  // abas; Desempenho e renderizacao; Rede e conexao avancada, recolhida por padrao (ExpansionTile) para nao
  // confundir quem nao e tecnico. As opcoes e as condicoes sao as mesmas da secao original. O 2_marca.ps1 poe este
  // trecho no lugar do other() do desktop_setting_page.dart.
  Widget other() {
    final incomingOnly = bind.isIncomingOnly();
    final outgoingOnly = bind.isOutgoingOnly();
    final showAutoUpdate = (isWindows && bind.mainIsInstalled()) ||
        (isMacOS &&
            bind.mainIsInstalled() &&
            bind.mainIsInstalledDaemon(prompt: false) &&
            !bind.isCustomClient());

    final interface = <Widget>[
      if (!isWeb && !incomingOnly)
        _OptionCheckBox(context, 'Confirm before closing multiple tabs',
            kOptionEnableConfirmClosingTabs,
            isServer: false),
      if (!incomingOnly)
        _OptionCheckBox(
          context,
          'allow-remote-toolbar-docking-any-edge',
          kOptionAllowMultiEdgeToolbarDock,
          isServer: false,
          update: (_) {
            reloadAllWindows();
          },
        ),
      if (!isWeb && !incomingOnly)
        _OptionCheckBox(
          context,
          'Open connection in new tab',
          kOptionOpenNewConnInTabs,
          isServer: false,
        ),
      // Console Tecnico: padrao de onde abrir os acessos (cadena_console.dart)
      if (!isWeb && !incomingOnly && cadenaConsole())
        _OptionCheckBox(
          context,
          'Abrir os acessos em janela separada (fora do console)',
          kCadenaOpcaoJanela,
          isServer: false,
        ),
      if (!isWeb && !incomingOnly)
        Tooltip(
          message: translate('sync-clipboard-between-sessions-tip'),
          child: _OptionCheckBox(
            context,
            'Sync clipboard between sessions',
            kOptionAllowSyncClipboardBetweenSessions,
            isServer: false,
          ),
        ),
      if (!bind.isDisableAccount())
        _OptionCheckBox(
          context,
          'note-at-conn-end-tip',
          kOptionAllowAskForNoteAtEndOfConnection,
          isServer: false,
          optSetter: (key, value) async {
            if (value && !gFFI.userModel.isLogin) {
              final res = await loginDialog();
              if (res != true) return;
            }
            await mainSetLocalBoolOption(key, value);
          },
        ),
      _OptionCheckBox(
        context,
        'Show monitor switch button on the main toolbar',
        kOptionAllowMonitorSwitchMainToolbar,
        isServer: false,
        update: (enabled) async {
          if (!enabled) {
            await mainSetLocalBoolOption(
                kOptionAllowMonitorSwitchMinToolbar, false);
          }
          if (mounted) setState(() {});
          reloadAllWindows();
          if (enabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final ctx = _minToolbarOptionKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  alignment: 0.5,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        },
      ),
      if (mainGetLocalBoolOptionSync(kOptionAllowMonitorSwitchMainToolbar))
        KeyedSubtree(
          key: _minToolbarOptionKey,
          child: _OptionCheckBox(
            context,
            'Show on the minimized toolbar',
            kOptionAllowMonitorSwitchMinToolbar,
            isServer: false,
            update: (_) {
              reloadAllWindows();
            },
          ).marginOnly(left: _kCheckBoxLeftMargin * 3),
        ),
      if (!isWeb && !bind.isCustomClient())
        _OptionCheckBox(
          context,
          'Check for software update on startup',
          kOptionEnableCheckUpdate,
          isServer: false,
        ),
      if (showAutoUpdate)
        _OptionCheckBox(
          context,
          'Auto update',
          kOptionAllowAutoUpdate,
          isServer: true,
        ),
    ];

    final desempenho = <Widget>[
      if (!isWeb && !outgoingOnly)
        _OptionCheckBox(context, 'Adaptive bitrate', kOptionEnableAbr),
      if (!isWeb) wallpaper(),
      // though this is related to GUI, but opengl problem affects all users, so put in config rather than local
      if (!isWeb && !incomingOnly && isLinux)
        Tooltip(
          message: translate('software_render_tip'),
          child: _OptionCheckBox(
            context,
            "Always use software rendering",
            kOptionAllowAlwaysSoftwareRender,
          ),
        ),
      if (!isWeb && !incomingOnly)
        Tooltip(
          message: translate('texture_render_tip'),
          child: _OptionCheckBox(
            context,
            "Use texture rendering",
            kOptionTextureRender,
            optGetter: bind.mainGetUseTextureRender,
            optSetter: (k, v) async =>
                await bind.mainSetLocalOption(key: k, value: v ? 'Y' : 'N'),
          ),
        ),
      if (!isWeb && !incomingOnly && isWindows)
        Tooltip(
          message: translate('d3d_render_tip'),
          child: _OptionCheckBox(
            context,
            "Use D3D rendering",
            kOptionD3DRender,
            isServer: false,
          ),
        ),
      if (isWindows && !outgoingOnly)
        _OptionCheckBox(
          context,
          'Capture screen using DirectX',
          kOptionDirectxCapture,
        ),
      if (!incomingOnly)
        _OptionCheckBox(
          context,
          'keep-awake-during-outgoing-sessions-label',
          kOptionKeepAwakeDuringOutgoingSessions,
          isServer: false,
        ),
    ];

    final rede = <Widget>[
      if (!isWeb && !incomingOnly) ...[
        Tooltip(
          message: translate('port-forward-mux-tip'),
          child: _OptionCheckBox(
            context,
            'Reuse one connection for port forwarding',
            kOptionEnablePortForwardMux,
            isServer: false,
          ),
        ),
        _OptionCheckBox(
          context,
          'Enable TCP hole punching',
          kOptionEnableTcpPunch,
          isServer: false,
        ),
        _OptionCheckBox(
          context,
          'Enable UDP hole punching',
          kOptionEnableUdpPunch,
          isServer: false,
        ),
        _OptionCheckBox(
          context,
          'Enable IPv6 P2P connection',
          kOptionEnableIpv6Punch,
          isServer: false,
        ),
      ],
      if (!incomingOnly) ...webrtcOptions(context),
    ];

    return Column(children: [
      if (interface.isNotEmpty)
        _Card(title: 'Interface e abas', children: interface),
      if (desempenho.isNotEmpty)
        _Card(title: 'Desempenho e renderização', children: desempenho),
      if (rede.isNotEmpty)
        _Card(title: 'Rede e conexão avançada', children: [
          Theme(
            // Sem as linhas que o ExpansionTile desenha em cima e embaixo
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.only(left: _kCheckBoxLeftMargin, right: 4),
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Opções de rede (só mexa se o suporte pedir)',
                style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              children:
                  rede.map((e) => e.marginOnly(top: 4)).toList(),
            ),
          ),
        ]),
    ]);
  }
