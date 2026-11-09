// CadenaTech: tela inicial do Tecnico (so acessa), no visual aprovado em 2026-11-08: lateral com as secoes
// (Clientes, Recentes, Favoritos, Catalogos, Configuracoes) e o cartao da conta com o status dos servidores; barra de
// cima com o ID para conectar, a busca, a ordenacao e a troca entre cartoes e lista. A lista de computadores, o
// status online e os menus continuam os do RustDesk (PeerTabPage), so com outra aparencia (cadena_cartao.dart).
// O 2_marca.ps1 copia este arquivo para flutter/lib/desktop/pages/cadena_inicio.dart.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:flutter_hbb/common/widgets/peers_view.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../models/platform_model.dart';

Color _suave(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.75) ??
    Colors.grey;

Color _linha(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.10);

/// Estado da tela lido de tempos em tempos. Nao da para escutar o gFFI.peerTabModel direto: ele avisa mudancas durante
/// a montagem da lista (setCurrentTabCachedPeers), e o Flutter recusa redesenhar outro widget nesse momento
class _CadenaEstado {
  static final aba = (-1).obs;
  static final visiveis = <int>[].obs;
  static final clientes = ''.obs;
  static final favoritos = ''.obs;
  static Timer? _timer;

  static void iniciar() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 400), (_) => _ler());
    _ler();
  }

  static void _ler() {
    final m = gFFI.peerTabModel;
    if (aba.value != m.currentTab) aba.value = m.currentTab;
    final v = m.visibleEnabledOrderedIndexs;
    if (v.length != visiveis.length ||
        Iterable.generate(v.length).any((i) => v[i] != visiveis[i])) {
      visiveis.assignAll(v);
    }
    final p = gFFI.groupModel.peersModel.peers;
    final c = p.isEmpty ? '' : '${p.where((e) => e.online).length}/${p.length}';
    if (clientes.value != c) clientes.value = c;
    final n = gFFI.favoritePeersModel.peers.length;
    final f = n > 0 ? '$n' : '';
    if (favoritos.value != f) favoritos.value = f;
  }
}

/// Lateral do Tecnico: marca, secoes e cartao da conta
class CadenaLateral extends StatefulWidget {
  const CadenaLateral({Key? key}) : super(key: key);

  @override
  State<CadenaLateral> createState() => _CadenaLateralState();
}

class _CadenaLateralState extends State<CadenaLateral> {
  final _servidores = RxnString();
  final _ftp = ''.obs;
  final _versao = ''.obs;
  Timer? _timer;

  static const _secoes = [
    (PeerTabIndex.group, 'Clientes', Icons.desktop_windows_outlined),
    (PeerTabIndex.recent, 'Recentes', Icons.history),
    (PeerTabIndex.fav, 'Favoritos', Icons.star_outline),
    (PeerTabIndex.ab, 'Catálogos', Icons.menu_book_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _CadenaEstado.iniciar();
    cadenaCarregarFavoritos();
    bind.mainLoadFavPeers();
    bind.mainGetVersion().then((v) => _versao.value = v);
    _atualizar();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _atualizar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _atualizar() async {
    _servidores.value = await bind.mainGetCommon(key: 'cadena-servidores');
    try {
      final e = jsonDecode(await bind.mainGetCommon(key: 'cadena-ftp-estado'))
          as Map<String, dynamic>;
      final pendentes = (e['pendentes'] ?? 0) as int;
      _ftp.value = e['ligado'] == true
          ? (pendentes > 0
              ? '$pendentes para enviar'
              : 'enviando ao FTP')
          : 'desligado';
    } catch (_) {
      _ftp.value = '';
    }
  }

  Future<void> _abrir(PeerTabIndex aba) async {
    await cadenaTrocarAba?.call(aba.index);
    await bind.setLocalFlutterOption(
        k: kOptionPeerTabIndex, v: aba.index.toString());
  }

  void _configuracoes() {
    if (DesktopSettingPage.tabKeys.isNotEmpty) {
      DesktopSettingPage.switch2page(DesktopSettingPage.tabKeys[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = MyTheme.accent;
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(right: BorderSide(color: _linha(context))),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                      color: cor.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: SvgPicture.asset('assets/icon.svg')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cadenaNomeExibido(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('Suporte remoto',
                      style: TextStyle(fontSize: 12, color: _suave(context))),
                ],
              ),
            ),
          ]).paddingOnly(left: 4, bottom: 14),
          Divider(height: 1, color: _linha(context)).paddingOnly(bottom: 10),
          Obx(() {
            final visiveis = _CadenaEstado.visiveis.toList();
            final aba = _CadenaEstado.aba.value;
            return Column(
              children: [
                for (final s in _secoes)
                  if (visiveis.contains(s.$1.index))
                    _item(
                      context,
                      icone: s.$3,
                      texto: s.$2,
                      ativo: aba == s.$1.index,
                      contagem: _contagem(s.$1),
                      onTap: () => _abrir(s.$1),
                    ),
                _item(context,
                    icone: Icons.settings_outlined,
                    texto: 'Configurações',
                    ativo: false,
                    onTap: _configuracoes),
              ],
            );
          }),
          const Spacer(),
          _cartaoConta(context),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Versão', style: TextStyle(fontSize: 12, color: _suave(context))),
                  Text(_versao.value,
                      style: TextStyle(fontSize: 12, color: _suave(context))),
                ],
              ).paddingOnly(left: 6, right: 6, top: 10)),
        ],
      ),
    );
  }

  String? _contagem(PeerTabIndex aba) {
    final t = aba == PeerTabIndex.group
        ? _CadenaEstado.clientes.value
        : (aba == PeerTabIndex.fav ? _CadenaEstado.favoritos.value : '');
    return t.isEmpty ? null : t;
  }

  Widget _item(BuildContext context,
      {required IconData icone,
      required String texto,
      required bool ativo,
      String? contagem,
      required VoidCallback onTap}) {
    final cor = MyTheme.accent;
    final hover = false.obs;
    return Obx(() {
      // O Obx precisa ler o observavel sempre (no item ativo a condicao abaixo nao o leria)
      final emCima = hover.value;
      return InkWell(
          onTap: onTap,
          onHover: (v) => hover.value = v,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: ativo
                  ? cor.withOpacity(0.12)
                  : (emCima
                      ? Theme.of(context).hoverColor
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(icone, size: 20, color: ativo ? cor : _suave(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(texto,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ativo ? cor : _suave(context))),
              ),
              if (contagem != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: ativo
                        ? Theme.of(context).cardColor
                        : Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(contagem,
                      style: TextStyle(
                          fontSize: 12, color: ativo ? cor : _suave(context))),
                ),
            ]),
          ),
        );
    });
  }

  Widget _cartaoConta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _linha(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Obx(() {
        final logado = gFFI.userModel.isLogin;
        final nome = gFFI.userModel.displayNameOrUserName;
        final serv = _servidores.value;
        final semServidor = serv != null && serv.isEmpty;
        final status = Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          decoration: BoxDecoration(
            color: (semServidor ? Colors.red : Colors.green).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: semServidor ? Colors.red : Colors.green),
            ),
            const SizedBox(width: 5),
            Text(semServidor ? 'Sem servidor' : (serv == null ? '...' : 'Pronto'),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: semServidor ? Colors.red : Colors.green)),
          ]),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: MyTheme.accent,
                child: Text(
                  _iniciais(logado ? nome : '?'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(logado ? nome : 'Sem login',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    Text(logado ? 'conta da API' : 'entre para acessar',
                        style: TextStyle(fontSize: 12, color: _suave(context))),
                  ],
                ),
              ),
              status,
            ]),
            const SizedBox(height: 10),
            _linhaInfo(context, 'Servidores',
                serv == null ? 'verificando' : (serv.isEmpty ? 'nenhum responde' : serv)),
            if (_ftp.value.isNotEmpty) _linhaInfo(context, 'Gravações', _ftp.value),
            if (!logado)
              ElevatedButton(
                onPressed: () => loginDialog(),
                child: Text(translate('Login')),
              ).paddingOnly(top: 10),
          ],
        );
      }),
    );
  }

  Widget _linhaInfo(BuildContext context, String rotulo, String valor) => Row(
        children: [
          Text(rotulo, style: TextStyle(fontSize: 12.5, color: _suave(context))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(valor,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ).paddingOnly(top: 5);

  String _iniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

/// Barra de cima do Tecnico: ID + Conectar (e outros modos), busca, ordenacao, cartoes/lista e atualizar
class CadenaTopo extends StatefulWidget {
  final IDTextEditingController controlador;
  final void Function(
      {bool isFileTransfer,
      bool isViewCamera,
      bool isTerminal,
      bool isTcpTunneling}) conectar;

  const CadenaTopo(
      {Key? key, required this.controlador, required this.conectar})
      : super(key: key);

  @override
  State<CadenaTopo> createState() => _CadenaTopoState();
}

class _CadenaTopoState extends State<CadenaTopo> {
  final _foco = FocusNode();
  final _focado = false.obs;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => _focado.value = _foco.hasFocus);
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  BoxDecoration _caixa(BuildContext context, {bool ativo = false}) =>
      BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
            color: ativo ? MyTheme.accent : _linha(context),
            width: ativo ? 1.5 : 1),
      );

  Widget _botaoIcone(BuildContext context,
          {required IconData icone,
          required String dica,
          required bool ativo,
          required VoidCallback onTap}) =>
      Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Tooltip(
        message: dica,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ativo
                  ? MyTheme.accent.withOpacity(0.12)
                  : Theme.of(context).hoverColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: ativo ? Colors.transparent : _linha(context)),
            ),
            child: Icon(icone,
                size: 19, color: ativo ? MyTheme.accent : _suave(context)),
          ),
        ),
        ),
      );

  void _mudarVisao(PeerUiType tipo) {
    peerCardUiType.value = tipo;
    bind.setLocalFlutterOption(
        k: kOptionPeerCardUiType, v: tipo.index.toString());
  }

  void _mudarOrdem() {
    final novo = peerSort.value == PeerSortType.status
        ? PeerSortType.remoteHost
        : PeerSortType.status;
    peerSort.value = novo;
    bind.setLocalFlutterOption(k: kOptionPeerSorting, v: novo);
  }

  @override
  Widget build(BuildContext context) {
    final campoId = Obx(() => Container(
          constraints: const BoxConstraints(maxWidth: 520, minWidth: 300),
          padding: const EdgeInsets.all(4),
          decoration: _caixa(context, ativo: _focado.value),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: widget.controlador,
                focusNode: _foco,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: [IDTextInputFormatter()],
                style: const TextStyle(fontSize: 17, letterSpacing: 0.6),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'ID do computador do cliente',
                  hintStyle: TextStyle(
                      fontSize: 14, letterSpacing: 0, color: _suave(context)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onSubmitted: (_) => widget.conectar(),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => widget.conectar(),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(translate('Connect')),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
              ),
            ),
            PopupMenuButton<int>(
              tooltip: 'Outros modos',
              icon: Icon(Icons.more_vert, color: _suave(context)),
              onSelected: (i) {
                switch (i) {
                  case 0:
                    widget.conectar(isFileTransfer: true);
                    break;
                  case 1:
                    widget.conectar(isTerminal: true);
                    break;
                  case 2:
                    widget.conectar(isViewCamera: true);
                    break;
                  case 3:
                    widget.conectar(isTcpTunneling: true);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 0, child: Text(translate('Transfer file'))),
                PopupMenuItem(value: 1, child: Text(translate('Terminal'))),
                PopupMenuItem(value: 2, child: Text(translate('View camera'))),
                PopupMenuItem(value: 3, child: Text(translate('TCP tunneling'))),
              ],
            ),
          ]),
        ));

    final busca = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _caixa(context),
      child: Row(children: [
        Icon(Icons.search, size: 19, color: _suave(context)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: peerSearchTextController,
            onChanged: (v) => peerSearchText.value = v,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Buscar nome, usuário ou ID',
              hintStyle: TextStyle(fontSize: 13.5, color: _suave(context)),
            ),
          ),
        ),
      ]),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: _linha(context))),
      ),
      child: Obx(() => Row(
            children: [
              Flexible(
                flex: 5,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: campoId),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 3,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: busca),
              ),
              const SizedBox(width: 10),
              _botaoIcone(context,
                  icone: Icons.swap_vert,
                  dica: peerSort.value == PeerSortType.status
                      ? 'Online primeiro (clique para ordenar por nome)'
                      : 'Por nome (clique para online primeiro)',
                  ativo: peerSort.value == PeerSortType.status,
                  onTap: _mudarOrdem),
              _botaoIcone(context,
                  icone: Icons.grid_view_rounded,
                  dica: 'Cartões',
                  ativo: peerCardUiType.value == PeerUiType.grid,
                  onTap: () => _mudarVisao(PeerUiType.grid)),
              _botaoIcone(context,
                  icone: Icons.view_list_rounded,
                  dica: 'Lista',
                  ativo: peerCardUiType.value != PeerUiType.grid,
                  onTap: () => _mudarVisao(PeerUiType.list)),
              _botaoIcone(context,
                  icone: Icons.refresh,
                  dica: translate('Refresh'),
                  ativo: false,
                  onTap: () => cadenaRecarregarAba?.call()),
            ],
          )),
    );
  }
}

/// Titulo da secao atual, acima da lista de computadores
class CadenaTituloSecao extends StatelessWidget {
  const CadenaTituloSecao({Key? key}) : super(key: key);

  static const _textos = {
    0: ('Recentes', 'Os últimos computadores acessados neste Técnico.'),
    1: ('Favoritos', 'Os computadores marcados com a estrela.'),
    2: ('Rede local', 'Computadores encontrados na mesma rede.'),
    3: ('Catálogos', 'Catálogos de endereços compartilhados pelo painel.'),
    4: ('Clientes', 'Computadores com o Cliente instalado. A bolinha verde indica que está ligado e pronto para o acesso.'),
  };

  @override
  Widget build(BuildContext context) {
    _CadenaEstado.iniciar();
    return Align(
      alignment: Alignment.centerLeft,
      child: Obx(() {
        final t = _textos[_CadenaEstado.aba.value] ?? ('', '');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.$1,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w700)),
            Text(t.$2, style: TextStyle(fontSize: 13, color: _suave(context)))
                .paddingOnly(top: 2),
          ],
        ).paddingOnly(left: 4, top: 18, bottom: 4);
      }),
    );
  }
}
