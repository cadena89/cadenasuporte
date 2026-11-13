// CadenaTech: cartao de computador do Tecnico (visao em cartoes), no visual aprovado em 2026-11-08: capa com o icone do
// sistema, "Online/Offline", estrela de favorito, nome, usuario, ID e os botoes Conectar e mais opcoes. E uma parte
// (part of) do peer_card.dart para usar o menu, a selecao e a conexao do proprio RustDesk. O 2_marca.ps1 copia este
// arquivo para flutter/lib/common/widgets/cadena_cartao.dart.
part of 'peer_card.dart';

/// IDs favoritos, para a estrela do cartao (lidos uma vez e atualizados ao marcar)
final cadenaFavoritos = <String>{}.obs;

Future<void> cadenaCarregarFavoritos() async {
  final favs = await bind.mainGetFav();
  cadenaFavoritos
    ..clear()
    ..addAll(favs);
}

Future<void> cadenaAlternarFavorito(String id) async {
  final favs = (await bind.mainGetFav()).toList();
  if (favs.contains(id)) {
    favs.remove(id);
  } else {
    favs.add(id);
  }
  await bind.mainStoreFav(favs: favs);
  cadenaFavoritos
    ..clear()
    ..addAll(favs);
  bind.mainLoadFavPeers();
}

extension _CadenaLinha on _PeerCardState {
  /// Visao em lista do Tecnico, no estilo visual escolhido (style_manager.dart): bolinha de status + apelido (ou
  /// nome do computador) e a empresa; abaixo, ID, telefone e sistema usado; a direita, CONECTAR (online) ou
  /// Acessar (offline, apagado) e o menu do RustDesk
  Widget _cadenaLinha(BuildContext context, Peer peer, Rx<BoxDecoration?> deco) {
    final nome = peer.alias.isNotEmpty
        ? peer.alias
        : (peer.hostname.isNotEmpty ? peer.hostname : formatID(peer.id));
    final extras = cadenaExtras[peer.id];
    final detalhes = [
      'ID: ${formatID(peer.id)}',
      if (extras != null && extras.telefone.isNotEmpty) extras.telefone,
      if (extras != null && extras.sistema.isNotEmpty) extras.sistema,
      if (peer.alias.isNotEmpty && peer.hostname.isNotEmpty) peer.hostname,
    ].join('  |  ');
    final statusCor =
        peer.online ? const Color(0xFF22C55E) : const Color(0xFFE04F5F);

    return Obx(() {
      final estilo = cadenaEstilo.value;
      final p = cadenaPaleta;
      final apagado = !peer.online;
      final conteudo = Row(children: [
        if (estilo != CadenaEstilo.onyx)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (peer.online ? p.destaque : p.textoSuave).withOpacity(0.14),
              borderRadius: BorderRadius.circular(estilo == CadenaEstilo.glass ? 12 : 8),
            ),
            padding: const EdgeInsets.all(9),
            child: getPlatformImage(peer.platform, size: 24),
          ).marginOnly(right: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusCor,
                    boxShadow: estilo == CadenaEstilo.glass && peer.online
                        ? [BoxShadow(color: statusCor.withOpacity(0.7), blurRadius: 8)]
                        : null,
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Tooltip(
                    message: peer.note.isNotEmpty ? '$nome\n${peer.note}' : nome,
                    waitDuration: const Duration(milliseconds: 600),
                    child: Text(nome,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: estilo == CadenaEstilo.onyx
                                ? FontWeight.w400
                                : FontWeight.w700,
                            color: apagado ? p.textoSuave : p.texto)),
                  ),
                ),
                if (apagado)
                  Text('  (Offline)',
                      style: TextStyle(fontSize: 13, color: const Color(0xFFE04F5F).withOpacity(0.85))),
                if (peer.device_group_name.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: p.destaque.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(peer.device_group_name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: p.destaque)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(detalhes,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: estilo == CadenaEstilo.glass && !apagado
                          ? p.destaque.withOpacity(0.85)
                          : p.textoSuave)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        apagado
            ? cadenaBotao('Acessar', () => widget.connect(context, peer.id),
                altura: 34, largura: 126, apagado: true)
            : cadenaBotao('CONECTAR', () => widget.connect(context, peer.id),
                altura: 34, largura: 126),
        const SizedBox(width: 4),
        SizedBox(
          width: 34,
          height: 34,
          child: Center(child: checkBoxOrActionMoreLandscape(peer, isTile: true)),
        ),
      ]);
      return Container(
        foregroundDecoration: deco.value,
        child: CadenaSuperficie(
          destaque: peer.online,
          raio: estilo == CadenaEstilo.glass ? 14 : null,
          padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
          child: conteudo,
        ),
      );
    });
  }
}

extension _CadenaCartao on _PeerCardState {
  Widget _cadenaCartao(BuildContext context, Peer peer, Rx<BoxDecoration?> deco) {
    final cor = MyTheme.accent;
    final suave =
        Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.75) ??
            Colors.grey;
    final linha = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.10);
    final nome = peer.alias.isNotEmpty
        ? peer.alias
        : (peer.hostname.isNotEmpty ? peer.hostname : formatID(peer.id));
    final tags = _frontN(peer.tags, 25)
        .map((e) => gFFI.abModel.getCurrentAbTagColor(e))
        .toList();

    Widget infoLinha(IconData icone, String texto, {bool destaque = false}) =>
        Row(children: [
          Icon(icone, size: 15, color: suave),
          const SizedBox(width: 7),
          Expanded(
            child: Text(texto,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    color: destaque ? null : suave,
                    letterSpacing: destaque ? 0.4 : 0)),
          ),
        ]).paddingOnly(top: 3);

    final capa = Container(
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cor.withOpacity(0.13), cor.withOpacity(0.04)],
        ),
      ),
      child: Stack(children: [
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: peer.online ? cor : Colors.blueGrey.shade300,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5))
              ],
            ),
            padding: const EdgeInsets.all(11),
            child: getPlatformImage(peer.platform, size: 26),
          ),
        ),
        if (_shouldBuildPasswordIcon(peer))
          Positioned(
              top: 6, left: 8, child: Icon(Icons.key, size: 13, color: cor)),
        if (tags.isNotEmpty)
          Positioned(
            top: 8,
            right: 14,
            child: CustomPaint(painter: TagPainter(radius: 4, colors: tags)),
          ),
      ]),
    );

    final estado = Row(children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: peer.online ? Colors.green : Colors.blueGrey.shade300),
      ),
      const SizedBox(width: 6),
      Text(peer.online ? 'Online' : 'Offline',
          style: TextStyle(fontSize: 12, color: suave)),
      const Spacer(),
      Obx(() {
        final fav = cadenaFavoritos.contains(peer.id);
        return InkWell(
          onTap: () => cadenaAlternarFavorito(peer.id),
          child: Tooltip(
            message: fav ? 'Tirar dos favoritos' : 'Marcar como favorito',
            child: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 19, color: fav ? const Color(0xFFF5B301) : linha),
          ),
        );
      }),
    ]);

    final acoes = Row(children: [
      Expanded(
        child: SizedBox(
          height: 34,
          child: TextButton(
            onPressed: () => widget.connect(context, peer.id),
            style: TextButton.styleFrom(
              backgroundColor: cor.withOpacity(0.12),
              foregroundColor: cor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
            child: Text(translate('Connect'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        width: 36,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: linha),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(child: checkBoxOrActionMoreLandscape(peer, isTile: false)),
      ),
    ]);

    return Obx(() => Container(
          foregroundDecoration: deco.value,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: linha),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              capa,
              const SizedBox(height: 9),
              estado.paddingSymmetric(horizontal: 3),
              Tooltip(
                message: nome,
                waitDuration: const Duration(seconds: 1),
                child: Text(nome,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ).paddingOnly(left: 3, right: 3, top: 5),
              // Com apelido (definido no painel), o nome do computador vai junto do usuario
              infoLinha(
                      Icons.person_outline,
                      [
                        peer.username.isNotEmpty ? peer.username : '—',
                        if (peer.alias.isNotEmpty && peer.hostname.isNotEmpty)
                          peer.hostname,
                      ].join(' · '))
                  .paddingSymmetric(horizontal: 3),
              infoLinha(Icons.badge_outlined, formatID(peer.id), destaque: true)
                  .paddingSymmetric(horizontal: 3),
              const Spacer(),
              acoes,
            ],
          ),
        ));
  }
}
