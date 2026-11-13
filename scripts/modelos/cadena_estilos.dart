// CadenaTech: estilos visuais do Cliente e do Tecnico (aprovados em 2026-11-13), trocados na hora, sem reiniciar:
//   1. Glass & Glow: fundo azul escuro com brilhos, cartoes translucidos com desfoque (BackdropFilter) e bordas
//      luminosas em ciano.
//   2. Onyx Minimal: preto absoluto, sem caixas pesadas, so tipografia fina em branco e cinza, com bastante respiro.
//   3. Modular Space: cinza espacial, modulos em caixas com bordas bem definidas e titulos de secao.
// A escolha fica na opcao local cadena-estilo-visual (1, 2 ou 3) de cada usuario; sem ela, vale o Modular Space.
// O 2_marca.ps1 copia este arquivo
// para flutter/lib/theme/style_manager.dart.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';

enum CadenaEstilo { glass, onyx, modular }

/// Opcao local (por usuario) com o estilo escolhido: '1' Glass, '2' Onyx, '3' Modular
const String kCadenaOpcaoEstilo = 'cadena-estilo-visual';

const _nomes = {
  CadenaEstilo.glass: 'Glass & Glow',
  CadenaEstilo.onyx: 'Onyx Minimal',
  CadenaEstilo.modular: 'Modular Space',
};

/// Estilo atual; os widgets do Cliente e do Tecnico redesenham ao mudar. Padrao (sem escolha gravada): Modular Space,
/// por decisao do usuario em 2026-11-13
final cadenaEstilo = CadenaEstilo.modular.obs;
bool _carregado = false;

void cadenaCarregarEstilo() {
  if (_carregado) return;
  _carregado = true;
  switch (bind.getLocalFlutterOption(k: kCadenaOpcaoEstilo)) {
    case '1':
      cadenaEstilo.value = CadenaEstilo.glass;
      break;
    case '2':
      cadenaEstilo.value = CadenaEstilo.onyx;
      break;
    default:
      cadenaEstilo.value = CadenaEstilo.modular;
  }
}

Future<void> cadenaMudarEstilo(CadenaEstilo e) async {
  cadenaEstilo.value = e;
  await bind.setLocalFlutterOption(
      k: kCadenaOpcaoEstilo, v: '${e.index + 1}');
}

String cadenaNomeEstilo(CadenaEstilo e) => _nomes[e]!;

/// Cores e efeitos de um estilo
class CadenaPaleta {
  final List<Color> fundo;
  final List<Color> brilhos; // manchas de luz do fundo (so Glass)
  final Color lateral;
  final Color superficie;
  final Color borda;
  final double larguraBorda;
  final Color? brilhoBorda; // glow em volta dos cartoes (so Glass)
  final double raio;
  final double desfoque; // BackdropFilter dos cartoes (so Glass)
  final Color texto;
  final Color textoSuave;
  final Color destaque;
  final Color corId;
  final FontWeight pesoId;
  final bool botaoContorno; // CONECTAR em contorno (Glass, Onyx) ou cheio (Modular)
  final bool titulosDeSecao; // "AUTENTICACAO", "ACOES" (Modular)

  const CadenaPaleta({
    required this.fundo,
    this.brilhos = const [],
    required this.lateral,
    required this.superficie,
    required this.borda,
    this.larguraBorda = 1,
    this.brilhoBorda,
    required this.raio,
    this.desfoque = 0,
    required this.texto,
    required this.textoSuave,
    required this.destaque,
    required this.corId,
    this.pesoId = FontWeight.w700,
    this.botaoContorno = false,
    this.titulosDeSecao = false,
  });
}

const _paletas = {
  CadenaEstilo.glass: CadenaPaleta(
    fundo: [Color(0xFF0B1A38), Color(0xFF0A1530), Color(0xFF060D1E)],
    brilhos: [Color(0x552B6BFF), Color(0x3322D3EE)],
    lateral: Color(0x14FFFFFF),
    superficie: Color(0x1AFFFFFF),
    borda: Color(0x8C3FD3FF),
    larguraBorda: 1.2,
    brilhoBorda: Color(0x553FD3FF),
    raio: 16,
    desfoque: 14,
    texto: Colors.white,
    textoSuave: Color(0xFFAEBCD4),
    destaque: Color(0xFF38D6FF),
    corId: Color(0xFF5CE1FF),
    botaoContorno: true,
  ),
  CadenaEstilo.onyx: CadenaPaleta(
    fundo: [Color(0xFF0A0A0B), Color(0xFF0A0A0B)],
    lateral: Color(0xFF0E0E10),
    superficie: Color(0x00000000),
    borda: Color(0x14FFFFFF),
    larguraBorda: 0,
    raio: 6,
    texto: Color(0xFFF2F2F3),
    textoSuave: Color(0xFF8B9099),
    destaque: Color(0xFFE6E6E8),
    corId: Colors.white,
    pesoId: FontWeight.w300,
    botaoContorno: true,
  ),
  CadenaEstilo.modular: CadenaPaleta(
    fundo: [Color(0xFF17191D), Color(0xFF17191D)],
    lateral: Color(0xFF1E2126),
    superficie: Color(0xFF262A30),
    borda: Color(0xFF3A3F48),
    raio: 10,
    texto: Color(0xFFF1F3F5),
    textoSuave: Color(0xFF9CA3AE),
    destaque: Color(0xFF2F80ED),
    corId: Colors.white,
    titulosDeSecao: true,
  ),
};

CadenaPaleta get cadenaPaleta => _paletas[cadenaEstilo.value]!;

/// Tema escuro do Flutter com as cores do estilo, para os widgets do proprio RustDesk dentro da tela
ThemeData cadenaTema(CadenaPaleta p) {
  final base = MyTheme.darkTheme;
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    cardColor: p.superficie.alpha < 0x30 ? p.lateral : p.superficie,
    dividerColor: p.borda,
    hoverColor: Colors.white.withOpacity(0.06),
    colorScheme: base.colorScheme.copyWith(
      // ignore: deprecated_member_use
      background: p.lateral,
      surface: p.lateral,
      primary: p.destaque,
    ),
  );
}

/// Fundo e tema do estilo atual em volta da tela inicial (Cliente e Tecnico)
class CadenaFundo extends StatefulWidget {
  final Widget child;
  const CadenaFundo({Key? key, required this.child}) : super(key: key);

  @override
  State<CadenaFundo> createState() => _CadenaFundoState();
}

class _CadenaFundoState extends State<CadenaFundo> {
  @override
  void initState() {
    super.initState();
    cadenaCarregarEstilo();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      cadenaEstilo.value; // o Obx precisa ler o observavel sempre
      final p = cadenaPaleta;
      return Theme(
        data: cadenaTema(p),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: p.fundo,
            ),
          ),
          child: Stack(children: [
            if (p.brilhos.isNotEmpty) ...[
              Positioned(
                left: -160,
                top: -120,
                child: _brilho(p.brilhos[0], 520),
              ),
              Positioned(
                right: -180,
                bottom: -200,
                child: _brilho(p.brilhos[1], 560),
              ),
            ],
            Positioned.fill(child: widget.child),
          ]),
        ),
      );
    });
  }

  Widget _brilho(Color cor, double tamanho) => IgnorePointer(
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [cor, cor.withOpacity(0)]),
          ),
        ),
      );
}

/// Cartao/modulo no estilo atual: vidro desfocado com borda luminosa (Glass), so espaco e uma linha fina (Onyx) ou
/// caixa solida com borda (Modular). destaque = borda mais forte (ex.: computador online)
class CadenaSuperficie extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool destaque;
  final double? raio;

  const CadenaSuperficie(
      {Key? key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.destaque = false,
      this.raio})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      cadenaEstilo.value;
      final p = cadenaPaleta;
      final r = BorderRadius.circular(raio ?? p.raio);
      switch (cadenaEstilo.value) {
        case CadenaEstilo.glass:
          final borda = destaque ? p.borda : p.borda.withOpacity(0.28);
          return Container(
            decoration: BoxDecoration(
              borderRadius: r,
              boxShadow: [
                if (destaque && p.brilhoBorda != null)
                  BoxShadow(color: p.brilhoBorda!, blurRadius: 18, spreadRadius: -2),
              ],
            ),
            child: ClipRRect(
              borderRadius: r,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: p.desfoque, sigmaY: p.desfoque),
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.13),
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
                    border: Border.all(color: borda, width: p.larguraBorda),
                  ),
                  child: child,
                ),
              ),
            ),
          );
        case CadenaEstilo.onyx:
          return Container(
            padding: padding,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.borda)),
            ),
            child: child,
          );
        case CadenaEstilo.modular:
          return Container(
            padding: padding,
            decoration: BoxDecoration(
              color: p.superficie,
              borderRadius: r,
              border: Border.all(
                  color: destaque ? p.destaque.withOpacity(0.7) : p.borda,
                  width: destaque ? 1.4 : 1),
            ),
            child: child,
          );
      }
    });
  }
}

/// Botao de acao principal no estilo atual (ex.: CONECTAR)
Widget cadenaBotao(String texto, VoidCallback? onPressed,
    {double altura = 36, double largura = 0, bool apagado = false}) {
  return Obx(() {
    final p = cadenaPaleta;
    final cor = apagado ? p.textoSuave : p.destaque;
    final estilo = TextStyle(
        fontWeight: cadenaEstilo.value == CadenaEstilo.onyx
            ? FontWeight.w500
            : FontWeight.w700,
        letterSpacing: 0.8);
    final forma = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            cadenaEstilo.value == CadenaEstilo.glass ? 10 : 7));
    final Widget botao = p.botaoContorno || apagado
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: cor,
              side: BorderSide(
                  color: cor.withOpacity(apagado ? 0.35 : 0.9),
                  width: cadenaEstilo.value == CadenaEstilo.glass ? 1.6 : 1),
              backgroundColor: cadenaEstilo.value == CadenaEstilo.glass && !apagado
                  ? cor.withOpacity(0.10)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: forma,
            ),
            child: Text(texto, style: estilo, maxLines: 1, softWrap: false),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: cor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: forma,
            ),
            child: Text(texto, style: estilo, maxLines: 1, softWrap: false),
          );
    final caixa = SizedBox(
        height: altura, width: largura > 0 ? largura : null, child: botao);
    if (cadenaEstilo.value == CadenaEstilo.glass && !apagado) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: cor.withOpacity(0.35), blurRadius: 14)],
        ),
        child: caixa,
      );
    }
    return caixa;
  });
}

/// Titulo de secao do Modular ("AUTENTICACAO", "ACOES"); nos outros estilos nao aparece
Widget cadenaTituloSecao(String texto) => Obx(() {
      final p = cadenaPaleta;
      if (!p.titulosDeSecao) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto.toUpperCase(),
            style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: p.textoSuave)),
      );
    });

/// Botao discreto com a paleta: abre os 3 estilos e troca na hora
class CadenaSeletorEstilo extends StatelessWidget {
  final double tamanho;
  const CadenaSeletorEstilo({Key? key, this.tamanho = 18}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = cadenaPaleta;
      final atual = cadenaEstilo.value;
      return PopupMenuButton<CadenaEstilo>(
        tooltip: 'Estilo visual: ${cadenaNomeEstilo(atual)}',
        icon: Icon(Icons.palette_outlined, size: tamanho, color: p.textoSuave),
        onSelected: cadenaMudarEstilo,
        itemBuilder: (_) => [
          for (final e in CadenaEstilo.values)
            PopupMenuItem(
              value: e,
              child: Row(children: [
                Icon(e == atual ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 16),
                const SizedBox(width: 10),
                Text(cadenaNomeEstilo(e)),
              ]),
            ),
        ],
      );
    });
  }
}

/// Interruptor no lugar do Checkbox nas Configuracoes (mesmos parametros: value e onChanged). O 2_marca.ps1 troca
/// todo Checkbox( do desktop_setting_page.dart por CadenaCheckbox(
class CadenaCheckbox extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;

  const CadenaCheckbox({Key? key, required this.value, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 30,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value ?? false,
          onChanged: onChanged == null ? null : (v) => onChanged!(v),
          activeColor: Colors.white,
          // Cor de destaque do estilo (no Onyx o destaque e quase branco, entao fica o azul da marca)
          activeTrackColor: cadenaEstilo.value == CadenaEstilo.onyx
              ? MyTheme.accent
              : cadenaPaleta.destaque,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
/// O mesmo interruptor, para quem chama direto (a tela de FTP): no desktop_setting_page.dart o texto
/// "CadenaCheckbox(" so aparece depois da troca do 2_marca.ps1
Widget cadenaInterruptor(
        {required bool? value, required ValueChanged<bool?>? onChanged}) =>
    CadenaCheckbox(value: value, onChanged: onChanged);

/// Cartao das Configuracoes no estilo atual (aprovado em 2026-11-13, a partir dos modelos do usuario): titulo,
/// complemento a direita (ex.: o interruptor do FTP) e o conteudo, numa CadenaSuperficie com o brilho do Glass. O
/// 2_marca.ps1 troca o _Card do desktop_setting_page.dart por este, entao todas as abas ficam no mesmo visual
class CadenaCartaoConfig extends StatelessWidget {
  final String titulo;
  final List<Widget>? complemento;
  final List<Widget> children;

  const CadenaCartaoConfig(
      {Key? key,
      required this.titulo,
      this.complemento,
      required this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = cadenaPaleta;
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: CadenaSuperficie(
          destaque: cadenaEstilo.value == CadenaEstilo.glass,
          padding: const EdgeInsets.fromLTRB(6, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 6),
                child: Row(children: [
                  Expanded(
                    child: Text(titulo,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: p.texto)),
                  ),
                  if (complemento != null)
                    Flexible(
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: complemento!),
                    ),
                ]),
              ),
              ...children.map(
                  (e) => Padding(padding: const EdgeInsets.only(top: 4), child: e)),
            ],
          ),
        ),
      );
    });
  }
}

/// Campo de texto das Configuracoes no estilo atual (borda do estilo, destaque ao focar)
InputDecoration cadenaDecoracaoCampo(
    {String? rotulo, String? dica, Widget? sufixo}) {
  final p = cadenaPaleta;
  final cor = cadenaEstilo.value == CadenaEstilo.glass
      ? p.borda.withOpacity(0.55)
      : (cadenaEstilo.value == CadenaEstilo.onyx
          ? Colors.white.withOpacity(0.18)
          : p.borda);
  OutlineInputBorder borda(Color c, [double largura = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c, width: largura));
  return InputDecoration(
    labelText: rotulo,
    hintText: dica,
    isDense: true,
    filled: true,
    fillColor: Colors.black.withOpacity(0.18),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    suffixIcon: sufixo,
    border: borda(cor),
    enabledBorder: borda(cor),
    disabledBorder: borda(cor.withOpacity(0.35)),
    focusedBorder: borda(
        cadenaEstilo.value == CadenaEstilo.onyx ? Colors.white : p.destaque,
        1.6),
  );
}

/// Cor do item selecionado na lateral das Configuracoes: ciano claro no Glass (o azul sumia no fundo azul), branco
/// no Onyx e o azul da marca no Modular
Color get cadenaCorSelecao {
  switch (cadenaEstilo.value) {
    case CadenaEstilo.glass:
      return cadenaPaleta.corId;
    case CadenaEstilo.onyx:
      return Colors.white;
    case CadenaEstilo.modular:
      return MyTheme.accent;
  }
}
