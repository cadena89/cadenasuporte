// CadenaTech: Console Tecnico (compilado com CADENA_PERFIL=console). Os acessos abrem em abas na janela principal,
// ao lado do Inicio. O menu do cartao ("Abrir em nova janela") e o clique direito na aba ("Abrir em janela separada")
// levam o acesso para uma janela propria, e a janela propria devolve o acesso ("Trazer para o console"), sem
// reconectar. No Tecnico e no Cliente nada daqui roda: cadenaConsole() e falso. Copiado pelo 2_marca.ps1.
import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/shared_state.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/remote_page.dart';
import 'package:flutter_hbb/desktop/widgets/material_mod_popup_menu.dart'
    as mod_menu;
import 'package:flutter_hbb/desktop/widgets/popup_menu.dart';
import 'package:flutter_hbb/desktop/widgets/remote_toolbar.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';

/// Chamada da janela separada para a principal: "<janela>,<id>,<sessao>"
const String kCadenaTrazer = 'cadena_trazer_para_console';

/// Opcao local (Configuracoes > Geral): abrir os acessos em janela separada, como no Tecnico
const String kCadenaOpcaoJanela = 'allow-cadena-console-janela';

bool? _console;

/// Verdadeiro so no Console Tecnico
bool cadenaConsole() =>
    _console ??= bind.mainGetCommonSync(key: 'cadena-console') == 'Y';

/// O proximo acesso abre em janela separada (menu "Abrir em nova janela" do cartao)
bool cadenaForcarJanela = false;

const _menuPadding = EdgeInsets.only(left: 8.0, right: 5.0);

bool _ehAcesso(String key) =>
    key != kTabLabelHomePage && key != kTabLabelSettingPage;

DesktopTabController? _controle() {
  try {
    final c = Get.find<DesktopTabController>();
    return c.tabType == DesktopTabType.main ? c : null;
  } catch (_) {
    return null;
  }
}

RemotePage? _pagina(DesktopTabController c, String key) {
  for (final t in c.state.value.tabs) {
    if (t.key == key && t.page is RemotePage) return t.page as RemotePage;
  }
  return null;
}

bool _preparado = false;

// Mesmo papel do ConnectionTabPage nas janelas de acesso: a sessao da aba escolhida recebe o teclado e o mouse
void _prepararControle(DesktopTabController c) {
  if (_preparado) return;
  _preparado = true;
  final antesSelecao = c.onSelected;
  final antesRemocao = c.onRemoved;
  c.onSelected = (key) {
    antesSelecao?.call(key);
    final pagina = _pagina(c, key);
    if (pagina != null) {
      bind.setCurSessionId(sessionId: pagina.ffi.sessionId);
      UnreadChatCountState.find(key).value = 0;
    }
  };
  c.onRemoved = (indice, key) {
    antesRemocao?.call(indice, key);
    if (_ehAcesso(key)) {
      ConnectionTypeState.delete(key);
      stateGlobal.relativeMouseModeState.remove(key);
    }
  };
}

bool _adicionar(String id,
    {String? password,
    bool? isSharedPassword,
    bool? forceRelay,
    String? sessionId,
    int? tabWindowId}) {
  final c = _controle();
  if (c == null) return false;
  _prepararControle(c);
  final indice = c.state.value.tabs.indexWhere((t) => t.key == id);
  if (indice >= 0) {
    c.jumpTo(indice);
    return true;
  }
  ConnectionTypeState.init(id);
  c.add(TabInfo(
    key: id,
    label: id,
    selectedIcon: Icons.desktop_windows_sharp,
    unselectedIcon: Icons.desktop_windows_outlined,
    onTabCloseButton: () async {
      if (await desktopTryShowTabAuditDialogCloseCancelled(
        id: id,
        tabController: c,
      )) {
        return;
      }
      c.closeBy(id);
    },
    page: RemotePage(
      key: ValueKey(id),
      id: id,
      sessionId: sessionId == null ? null : SessionID(sessionId),
      tabWindowId: tabWindowId,
      password: password,
      toolbarState: ToolbarState(),
      tabController: c,
      forceRelay: forceRelay,
      isSharedPassword: isSharedPassword,
    ),
  ));
  return true;
}

/// Chamado pelo connectMainDesktop: abre o acesso numa aba e devolve verdadeiro, ou falso para seguir como hoje
/// (janela separada)
bool cadenaAbrirNaAba(String id,
    {String? password, bool? isSharedPassword, bool? forceRelay}) {
  final forcar = cadenaForcarJanela;
  cadenaForcarJanela = false;
  if (!cadenaConsole() || forcar || mainGetLocalBoolOptionSync(kCadenaOpcaoJanela)) {
    return false;
  }
  return _adicionar(id,
      password: password,
      isSharedPassword: isSharedPassword,
      forceRelay: forceRelay);
}

/// Move o acesso da aba para uma janela propria, sem reconectar (o mesmo caminho do "Mover para nova janela")
Future<void> cadenaSepararAba(String key) async {
  final c = _controle();
  if (c == null) return;
  final pagina = _pagina(c, key);
  if (pagina == null) return;
  await rustDeskWinManager.moveTabToNewWindow(kWindowMainId, key,
      pagina.ffi.sessionId.toString(), WindowType.RemoteDesktop);
}

/// Nome da aba: o apelido ou o ID do computador (Inicio e Configuracoes continuam traduzidos)
Rx<String> cadenaRotuloAba(String key) =>
    _ehAcesso(key) ? DesktopTab.tablabelGetter(key) : Rx<String>(key);

/// Clique direito numa aba de acesso da janela principal
Widget cadenaMenuDaAba(BuildContext context, String key) {
  final c = _controle();
  if (c == null || !_ehAcesso(key) || _pagina(c, key) == null) {
    return Container();
  }
  final menu = <MenuEntryBase<String>>[
    MenuEntryButton<String>(
      childBuilder: (TextStyle? style) =>
          Text('Abrir em janela separada', style: style),
      proc: () {
        BotToast.cleanAll();
        cadenaSepararAba(key);
      },
      padding: _menuPadding,
    ),
    MenuEntryDivider<String>(),
    MenuEntryButton<String>(
      childBuilder: (TextStyle? style) =>
          Text('Fechar os outros acessos', style: style),
      proc: () {
        BotToast.cleanAll();
        final outros = c.state.value.tabs
            .where((t) => t.key != key && _ehAcesso(t.key) && t.page is RemotePage)
            .map((t) => t.key)
            .toList();
        for (final k in outros) {
          c.closeBy(k);
        }
      },
      padding: _menuPadding,
    ),
    MenuEntryButton<String>(
      childBuilder: (TextStyle? style) =>
          Text('Encerrar este acesso', style: style),
      proc: () {
        BotToast.cleanAll();
        c.closeBy(key);
      },
      padding: _menuPadding,
    ),
  ];
  return mod_menu.PopupMenu<String>(
    items: menu
        .map((e) => e.build(
              context,
              const MenuConfig(
                commonColor: CustomPopupMenuTheme.commonColor,
                height: CustomPopupMenuTheme.height,
                dividerHeight: CustomPopupMenuTheme.dividerHeight,
              ),
            ))
        .expand((i) => i)
        .toList(),
  );
}

/// Na janela separada: item "Trazer para o console" do clique direito na aba
MenuEntryBase<String>? cadenaItemTrazer(
    int janela, String key, String sessionId, VoidCallback fechar) {
  if (!cadenaConsole()) return null;
  return MenuEntryButton<String>(
    childBuilder: (TextStyle? style) =>
        Text('Trazer para o console', style: style),
    proc: () async {
      fechar();
      await DesktopMultiWindow.invokeMethod(
          kMainWindowId, kCadenaTrazer, '$janela,$key,$sessionId');
    },
    padding: _menuPadding,
  );
}

/// Chamadas que a janela principal do console responde (ver desktop_home_page)
bool cadenaChamadaDoConsole(String metodo) =>
    cadenaConsole() &&
    (metodo == kWindowEventGetCachedSessionData || metodo == kCadenaTrazer);

Future<dynamic> cadenaTratarChamada(MethodCall call, int deJanela) async {
  final c = _controle();
  if (c == null) return null;
  if (call.method == kWindowEventGetCachedSessionData) {
    // A janela nova pede os dados da sessao e a aba daqui fecha sem encerrar o acesso
    final args = jsonDecode(call.arguments);
    final String id = args['id'];
    final pagina = _pagina(c, id);
    if (pagina == null) return null;
    final dados = pagina.ffi.ffiModel.cachedPeerData.toString();
    if (args['close'] == true) {
      closeSessionOnDispose[id] = false;
      c.closeBy(id);
    }
    return dados;
  }
  if (call.method == kCadenaTrazer) {
    final partes = '${call.arguments}'.split(',');
    if (partes.length < 3) return null;
    final janela = int.tryParse(partes[0]);
    if (janela == null) return null;
    await windowOnTop(null);
    return _adicionar(partes[1], sessionId: partes[2], tabWindowId: janela);
  }
  return null;
}

/// Antes de fechar a janela principal: com acessos em abas, confirma e encerra todos
Future<bool> cadenaPodeFecharConsole(DesktopTabController c) async {
  if (!cadenaConsole() || c.tabType != DesktopTabType.main) return true;
  final acessos = c.state.value.tabs
      .where((t) => _ehAcesso(t.key) && t.page is RemotePage)
      .map((t) => t.key)
      .toList();
  if (acessos.isEmpty) return true;
  final n = acessos.length;
  final texto = n == 1
      ? 'Há 1 acesso aberto nesta janela. Fechar encerra esse acesso (a gravação é finalizada normalmente). As janelas separadas continuam abertas.'
      : 'Há $n acessos abertos nesta janela. Fechar encerra todos eles (as gravações são finalizadas normalmente). As janelas separadas continuam abertas.';
  final ok = await gFFI.dialogManager.show<bool>((setState, close, context) {
    return CustomAlertDialog(
      title: Text('Fechar o ${cadenaNomeExibido()}?'),
      content: Text(texto),
      actions: [
        dialogButton('Cancel', onPressed: () => close(false), isOutline: true),
        dialogButton('Encerrar e fechar', onPressed: () => close(true)),
      ],
      onCancel: () => close(false),
      onSubmit: () => close(true),
    );
  });
  if (ok != true) return false;
  for (final k in acessos) {
    c.closeBy(k);
  }
  return true;
}
