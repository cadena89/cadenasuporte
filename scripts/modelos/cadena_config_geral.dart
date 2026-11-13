// CadenaTech: visual das Configuracoes (aprovado em 2026-11-13, a partir dos modelos do usuario). Cada trecho abaixo
// (depois de //@@ nome) entra no lugar de um pedaco do desktop_setting_page.dart, pelo 2_marca.ps1:
//   card      - o _Card vira o CadenaCartaoConfig (style_manager.dart): borda e brilho do estilo, largura toda
//   tema      - Claro, Escuro e Padrao do sistema na mesma linha
//   geral     - a aba Geral em duas colunas quando ha espaco (o FTP do Tecnico a direita)
//   gravacao  - "Gravacao e Midia": o codec de hardware entra no cartao da gravacao
//   pagina    - o fundo do estilo atras das Configuracoes (CadenaFundo)
//   pagina_fim, titulo, item - fecha o CadenaFundo, titulo "Configuracoes" e o item da lateral com destaque
// Este arquivo nao e compilado sozinho.
//@@ card
Widget _Card(
    {required String title,
    required List<Widget> children,
    List<Widget>? title_suffix}) {
  return CadenaCartaoConfig(
      titulo: translate(title), complemento: title_suffix, children: children);
}
//@@ tema
    return _Card(title: 'Theme', children: [
      Wrap(spacing: 18, runSpacing: 4, children: [
        for (final o in const [
          ['light', 'Light'],
          ['dark', 'Dark'],
          ['system', 'Follow System']
        ])
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: isOptFixed ? null : () => onChanged(o[0]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Radio<String>(
                  value: o[0],
                  groupValue: current,
                  onChanged: isOptFixed
                      ? null
                      : (v) {
                          if (v != null) onChanged(v);
                        }),
              Text(translate(o[1]),
                      style: TextStyle(
                          fontSize: _kContentFontSize,
                          color: disabledTextColor(context, !isOptFixed)))
                  .marginOnly(right: 6),
            ]),
          ),
      ]).marginOnly(left: _kRadioLeftMargin),
    ]);
//@@ geral
    final scrollController = ScrollController();
    // CadenaTech: duas colunas quando ha espaco; o FTP (so no Tecnico) fica sozinho a direita
    final esquerda = <Widget>[
      if (!isWeb) service(),
      theme(),
      _Card(title: 'Language', children: [language()]),
      if (!isWeb) record(context),
      if (!isWeb) audio(context),
    ];
    final direita = <Widget>[
      if (!isWeb && bind.isOutgoingOnly()) const _CadenaFtp(),
    ];
    final resto = <Widget>[
      if (!isWeb) WaylandCard(),
      other(),
      if (!bind.isIncomingOnly()) keyboardShortcuts(),
    ];
    return LayoutBuilder(builder: (context, limites) {
      final duasColunas = limites.maxWidth >= 900 && direita.isNotEmpty;
      return ListView(
        controller: scrollController,
        children: [
          if (duasColunas)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(children: esquerda)),
              Expanded(child: Column(children: direita)),
            ])
          else ...[
            ...esquerda,
            ...direita
          ],
          ...resto,
        ],
      ).marginOnly(bottom: _kListViewBottomMargin);
    });
//@@ gravacao
      return _Card(title: 'Gravação e Mídia', children: [
        // CadenaTech: o codec de hardware saiu do cartao proprio e entrou aqui
        if (bind.mainHasHwcodec() || bind.mainHasVram())
          _OptionCheckBox(
            context,
            'Enable hardware codec',
            kOptionEnableHwcodec,
            update: (bool v) {
              if (v) {
                bind.mainCheckHwcodec();
              }
            },
          ),
//@@ pagina
    super.build(context);
    // CadenaTech: fundo e tema do estilo atual atras das Configuracoes
    return CadenaFundo(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBlock(
//@@ pagina_fim
    ));
  }

  Widget _header(BuildContext context) {
//@@ titulo
    final settingsText = Text(
      translate('Settings'),
      textAlign: TextAlign.left,
      style: TextStyle(
        color: cadenaPaleta.texto,
        fontSize: 24,
        fontWeight: FontWeight.w500,
//@@ item
      return Container(
        height: _kTabHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? cadenaPaleta.destaque.withOpacity(0.14) : null,
          borderRadius: BorderRadius.circular(8),
          border: selected && cadenaEstilo.value == CadenaEstilo.glass
              ? Border.all(color: cadenaPaleta.borda.withOpacity(0.6))
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
