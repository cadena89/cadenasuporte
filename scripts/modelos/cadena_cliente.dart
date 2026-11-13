// CadenaTech: tela do Cliente (so recebe acesso), nos 3 estilos visuais (style_manager.dart, aprovados em
// 2026-11-13): logo da marca, ID grande (e a senha, quando o acesso aceita senha), botao verde para chamar o suporte
// no WhatsApp, Sair, o status no rodape e a paleta discreta no canto para trocar o estilo. Sem abas nem
// configuracoes visiveis: o clique direito na paleta abre as Configuracoes (atalho escondido, para o tecnico usar
// durante o atendimento). A logica continua a do RustDesk: o desktop_home_page.dart passa o aviso de senha, os cartoes de
// ajuda (instalar, permissoes) e o OnlineStatusWidget, e a janela segue a altura medida pela chave (_childKey).
// O fundo e o tema vem do CadenaFundo, em volta da tela inteira.
// O 2_marca.ps1 copia este arquivo para flutter/lib/desktop/pages/cadena_cliente.dart e troca os __CAMPOS__.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/theme/style_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

/// Slogan da marca (marca.psd1: Slogan); vazio = sem a linha
const String kCadenaSlogan = '__SLOGAN__';

/// WhatsApp do suporte, so numeros com DDI e DDD (marca.psd1: WhatsApp); vazio = sem o botao
const String kCadenaWhatsApp = '__WHATSAPP__';

/// Nome da empresa da marca, para a mensagem do WhatsApp
const String kCadenaEmpresa = '__EMPRESA__';

const _verde = Color(0xFF22C55E);

class CadenaPainelCliente extends StatelessWidget {
  /// Chave da coluna medida para o tamanho da janela (_childKey do desktop_home_page)
  final GlobalKey chave;
  final Widget aviso;
  final Widget ajuda;
  final Widget status;
  final VoidCallback aoMudarTamanho;

  const CadenaPainelCliente({
    Key? key,
    required this.chave,
    required this.aviso,
    required this.ajuda,
    required this.status,
    required this.aoMudarTamanho,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A janela do Cliente acompanha a altura do conteudo (muda com o estilo e com os cartoes de ajuda)
    WidgetsBinding.instance.addPostFrameCallback((_) => aoMudarTamanho());
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: SizedBox(
        width: 400,
        child: Column(children: [
          SingleChildScrollView(
            child: Obx(() {
              cadenaEstilo.value;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => aoMudarTamanho());
              final p = cadenaPaleta;
              return Column(
                key: chave,
                children: [
                  aviso,
                  // Seletor numa faixa propria acima da logo: nunca sobrepoe a marca. Clique direito na paleta
                  // (atalho escondido) abre as Configuracoes
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onSecondaryTap: _abrirConfiguracoes,
                        child: const CadenaSeletorEstilo(),
                      ),
                    ),
                  ),
                  _cabecalho(p),
                  const _CadenaCredenciais(),
                  DefaultTextStyle.merge(
                    style: TextStyle(color: p.texto),
                    child: ajuda,
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: p.borda),
                  status.marginOnly(bottom: 4, right: 6, left: 6),
                ],
              );
            }),
          ),
          Expanded(child: Container()),
        ]),
      ),
    );
  }

  static void _abrirConfiguracoes() {
    if (DesktopSettingPage.tabKeys.isNotEmpty) {
      DesktopSettingPage.switch2page(DesktopSettingPage.tabKeys[0]);
    }
  }

  Widget _cabecalho(CadenaPaleta p) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 2, 28, 16),
        child: Column(children: [
          Image.asset('assets/logo_dark.png', height: 52, fit: BoxFit.contain),
          if (kCadenaSlogan.isNotEmpty)
            Text(kCadenaSlogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: p.texto))
                .paddingOnly(top: 8),
        ]),
      );
}

class _CadenaCredenciais extends StatefulWidget {
  const _CadenaCredenciais({Key? key}) : super(key: key);

  @override
  State<_CadenaCredenciais> createState() => _CadenaCredenciaisState();
}

class _CadenaCredenciaisState extends State<_CadenaCredenciais> {
  // A senha comeca escondida; o olho mostra e esconde
  final _mostrarSenha = false.obs;

  Future<void> _whatsApp(String id) async {
    final texto = 'Olá! Preciso de suporte'
        '${kCadenaEmpresa.isEmpty ? '' : ' da $kCadenaEmpresa'}. '
        'Meu ID é ${formatID(id)}.';
    await launchUrl(
        Uri.parse(
            'https://wa.me/$kCadenaWhatsApp?text=${Uri.encodeComponent(texto)}'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerModel>(builder: (context, model, _) {
      // Senha so quando o acesso aceita senha; no modo "aprovar com clique" ela nao vale e nao aparece
      final comSenha = model.approveMode != 'click' &&
          model.verificationMethod != kUsePermanentPassword;
      return Obx(() {
        final estilo = cadenaEstilo.value;
        final p = cadenaPaleta;
        final id = ValueListenableBuilder<TextEditingValue>(
          valueListenable: model.serverId,
          builder: (context, v, _) => _valor(
            p,
            rotulo: 'ID',
            valor: v.text.isEmpty ? '...' : formatID(v.text),
            corValor: p.corId,
            acao: _icone(p, Icons.copy_rounded, 'Copiar o ID', () {
              Clipboard.setData(ClipboardData(text: v.text));
              showToast(translate('Copied'));
            }),
          ),
        );
        final senha = !comSenha
            ? null
            : ValueListenableBuilder<TextEditingValue>(
                valueListenable: model.serverPasswd,
                builder: (context, v, _) => Obx(() => _valor(
                      p,
                      rotulo: 'Senha',
                      valor: _mostrarSenha.value
                          ? v.text
                          : '•' * (v.text.isEmpty ? 6 : v.text.length),
                      corValor: p.texto,
                      acao: _icone(
                          p,
                          _mostrarSenha.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          _mostrarSenha.value
                              ? 'Esconder a senha'
                              : 'Mostrar a senha',
                          () => _mostrarSenha.value = !_mostrarSenha.value),
                    )),
              );
        final aviso = comSenha
            ? null
            : Text('Quando o técnico conectar, uma janela vai pedir a sua aprovação.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: p.textoSuave));
        final botoes = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kCadenaWhatsApp.isNotEmpty) _botaoWhatsApp(estilo, model),
            const SizedBox(height: 10),
            Center(child: _botaoSair(p, estilo)),
          ],
        );

        if (estilo == CadenaEstilo.modular) {
          // Modulos: AUTENTICACAO (ID e senha em caixas) e ACOES
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cadenaTituloSecao('Autenticação'),
                CadenaSuperficie(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    _caixaInterna(p, id),
                    if (senha != null) const SizedBox(height: 8),
                    if (senha != null) _caixaInterna(p, senha),
                    if (aviso != null) aviso.paddingOnly(top: 10),
                  ]),
                ),
                const SizedBox(height: 14),
                cadenaTituloSecao('Ações'),
                CadenaSuperficie(
                    padding: const EdgeInsets.all(12), child: botoes),
              ],
            ),
          );
        }

        // Glass e Onyx: um bloco central com o titulo, o ID grande e os botoes
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CadenaSuperficie(
                destaque: true,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(children: [
                  Text('Precisa de ajuda?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 23,
                          fontWeight: estilo == CadenaEstilo.onyx
                              ? FontWeight.w300
                              : FontWeight.w700,
                          color: p.texto)),
                  Text('Passe os dados abaixo para o nosso suporte:',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: p.textoSuave))
                      .paddingOnly(top: 4, bottom: 14),
                  id,
                  if (senha != null) senha.paddingOnly(top: 6),
                  if (aviso != null) aviso.paddingOnly(top: 10),
                ]),
              ),
              const SizedBox(height: 18),
              botoes,
              const SizedBox(height: 6),
            ],
          ),
        );
      });
    });
  }

  /// Rotulo pequeno em cima e o valor grande, centralizado
  Widget _valor(CadenaPaleta p,
          {required String rotulo,
          required String valor,
          required Color corValor,
          required Widget acao}) =>
      Column(children: [
        Text(rotulo,
            style: TextStyle(
                fontSize: 13, letterSpacing: 0.6, color: p.textoSuave)),
        Row(children: [
          const SizedBox(width: 36),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(valor,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: p.pesoId,
                    letterSpacing: 1.5,
                    color: corValor,
                    shadows: cadenaEstilo.value == CadenaEstilo.glass
                        ? [Shadow(color: corValor.withOpacity(0.55), blurRadius: 18)]
                        : null,
                  )),
            ),
          ),
          SizedBox(width: 36, child: acao),
        ]),
      ]);

  Widget _caixaInterna(CadenaPaleta p, Widget filho) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.borda),
        ),
        child: filho,
      );

  Widget _icone(CadenaPaleta p, IconData icone, String dica, VoidCallback onTap) =>
      IconButton(
        tooltip: dica,
        splashRadius: 18,
        icon: Icon(icone, size: 19, color: p.textoSuave),
        onPressed: onTap,
      );

  Widget _botaoWhatsApp(CadenaEstilo estilo, ServerModel model) {
    final botao = SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => _whatsApp(model.serverId.text),
        // Balao com telefone (este Flutter nao tem o icone do WhatsApp)
        icon: const SizedBox(
          width: 24,
          height: 24,
          child: Stack(alignment: Alignment.center, children: [
            Icon(Icons.chat_bubble, size: 24, color: Colors.white),
            Padding(
              padding: EdgeInsets.only(bottom: 3),
              child: Icon(Icons.phone, size: 13, color: _verde),
            ),
          ]),
        ),
        label: Text('Chamar Suporte no WhatsApp',
            style: TextStyle(
                fontSize: 15,
                fontWeight: estilo == CadenaEstilo.onyx
                    ? FontWeight.w500
                    : FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _verde,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  estilo == CadenaEstilo.glass ? 12 : 8)),
        ),
      ),
    );
    if (estilo != CadenaEstilo.glass) return botao;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _verde.withOpacity(0.45), blurRadius: 18)],
      ),
      child: botao,
    );
  }

  Widget _botaoSair(CadenaPaleta p, CadenaEstilo estilo) => SizedBox(
        height: 38,
        width: estilo == CadenaEstilo.modular ? double.infinity : 140,
        child: OutlinedButton(
          onPressed: () => windowManager.close(),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.texto,
            backgroundColor: estilo == CadenaEstilo.modular
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
            side: BorderSide(
                color: estilo == CadenaEstilo.onyx
                    ? Colors.transparent
                    : p.borda.withOpacity(0.6)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          child: const Text('Sair'),
        ),
      );
}
