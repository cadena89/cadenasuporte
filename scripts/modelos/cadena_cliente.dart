// CadenaTech: tela do Cliente (so recebe acesso), no visual aprovado em 2026-11-12: logo da marca e slogan, cartao
// "Precisa de ajuda?" com o ID grande (e a senha, quando o acesso aceita senha), botao verde para chamar o suporte
// no WhatsApp, botao Sair e o status da conexao no rodape. Sem abas nem configuracoes. A logica continua a do
// RustDesk: o desktop_home_page.dart passa o aviso de senha, os cartoes de ajuda (instalar, permissoes) e o
// OnlineStatusWidget, e a janela continua com o tamanho medido pela chave (_childKey / _updateWindowSize).
// O 2_marca.ps1 copia este arquivo para flutter/lib/desktop/pages/cadena_cliente.dart e troca os __CAMPOS__.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/models/server_model.dart';
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

const _fundoTopo = Color(0xFF1B2538);
const _fundoBase = Color(0xFF111827);
const _cartao = Color(0xFF1F2A3E);
const _caixaId = Color(0xFF0D1422);
const _borda = Color(0x1FFFFFFF);
const _textoSuave = Color(0xFFB4BED0);
const _verde = Color(0xFF22B45A);

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
    // A janela do Cliente acompanha a altura do conteudo (cartoes de ajuda aparecem e somem)
    WidgetsBinding.instance.addPostFrameCallback((_) => aoMudarTamanho());
    return Theme(
      data: MyTheme.darkTheme,
      child: Builder(
        builder: (context) => ChangeNotifierProvider.value(
          value: gFFI.serverModel,
          child: Container(
            width: 340,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_fundoTopo, _fundoBase],
              ),
            ),
            child: Column(children: [
              SingleChildScrollView(
                child: Column(
                  key: chave,
                  children: [
                    aviso,
                    _cabecalho(),
                    const _CadenaCartaoAjuda(),
                    DefaultTextStyle.merge(
                      style: const TextStyle(color: Colors.white),
                      child: ajuda,
                    ),
                    const SizedBox(height: 6),
                    Divider(height: 1, color: _borda),
                    status.marginOnly(bottom: 4, right: 6, left: 4),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
        child: Column(children: [
          Image.asset('assets/logo_dark.png', height: 46, fit: BoxFit.contain),
          if (kCadenaSlogan.isNotEmpty)
            const Text(kCadenaSlogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.white, letterSpacing: 0.2))
                .paddingOnly(top: 8),
        ]),
      );
}

class _CadenaCartaoAjuda extends StatefulWidget {
  const _CadenaCartaoAjuda({Key? key}) : super(key: key);

  @override
  State<_CadenaCartaoAjuda> createState() => _CadenaCartaoAjudaState();
}

class _CadenaCartaoAjudaState extends State<_CadenaCartaoAjuda> {
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
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: _cartao,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borda),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Precisa de ajuda?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Text('Passe os dados abaixo para o nosso suporte:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _textoSuave))
                .paddingOnly(top: 4, bottom: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: _caixaId,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borda),
              ),
              child: Column(children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: model.serverId,
                  builder: (context, v, _) => _linha(
                    rotulo: 'ID:',
                    valor: v.text.isEmpty ? '...' : formatID(v.text),
                    acao: IconButton(
                      tooltip: 'Copiar o ID',
                      splashRadius: 18,
                      icon: const Icon(Icons.copy_rounded,
                          size: 19, color: _textoSuave),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: v.text));
                        showToast(translate('Copied'));
                      },
                    ),
                  ),
                ),
                if (comSenha)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: model.serverPasswd,
                    builder: (context, v, _) => Obx(() => _linha(
                          rotulo: 'Senha:',
                          valor: _mostrarSenha.value
                              ? v.text
                              : '•' * (v.text.isEmpty ? 6 : v.text.length),
                          acao: IconButton(
                            tooltip: _mostrarSenha.value
                                ? 'Esconder a senha'
                                : 'Mostrar a senha',
                            splashRadius: 18,
                            icon: Icon(
                                _mostrarSenha.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: _textoSuave),
                            onPressed: () =>
                                _mostrarSenha.value = !_mostrarSenha.value,
                          ),
                        )).paddingOnly(top: 6),
                  ),
              ]),
            ),
            if (!comSenha)
              const Text(
                      'Quando o técnico conectar, uma janela vai pedir a sua aprovação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: _textoSuave))
                  .paddingOnly(top: 10),
            if (kCadenaWhatsApp.isNotEmpty)
              SizedBox(
                height: 46,
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
                  label: const Text('Chamar Suporte no WhatsApp',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ).paddingOnly(top: 16),
            SizedBox(
              height: 38,
              child: OutlinedButton(
                onPressed: () => windowManager.close(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _borda),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
                child: const Text('Sair'),
              ),
            ).paddingOnly(top: 10),
          ],
        ),
      );
    });
  }

  Widget _linha(
          {required String rotulo, required String valor, required Widget acao}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 74,
            child: Text(rotulo,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _textoSuave)),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white)),
            ),
          ),
          acao,
        ],
      );
}
