
// CadenaTech: envio das gravacoes do Tecnico por FTP, em Configuracoes > Geral. O 2_marca.ps1 junta este
// arquivo ao desktop_setting_page.dart. Grava o <prefixo>-ftp.txt lido pelo src/cadena_ftp.rs,
// pelo mainGetCommon / mainSetCommon. A senha nunca volta para a tela: em branco, mantem a atual.
class _CadenaFtp extends StatefulWidget {
  const _CadenaFtp({Key? key}) : super(key: key);

  @override
  State<_CadenaFtp> createState() => _CadenaFtpState();
}

class _CadenaFtpState extends State<_CadenaFtp> {
  final _local = TextEditingController();
  final _externo = TextEditingController();
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _pasta = TextEditingController();
  bool _ligado = false;
  bool _temSenha = false;
  int _pendentes = 0;
  bool _ocupado = false;
  String _mensagem = '';
  // Interruptor ligado antes de salvar (campos liberados) e o olho da senha
  bool _ativando = false;
  bool _verSenha = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in [_local, _externo, _usuario, _senha, _pasta]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final m = jsonDecode(await bind.mainGetCommon(key: 'cadena-ftp-estado'));
      if (!mounted) return;
      setState(() {
        _ligado = m['ligado'] == true;
        _temSenha = m['tem_senha'] == true;
        _pendentes = (m['pendentes'] ?? 0) as int;
        _local.text = (m['servidor_local'] ?? '') as String;
        _externo.text = (m['servidor'] ?? '') as String;
        _usuario.text = (m['usuario'] ?? '') as String;
        _pasta.text = (m['pasta'] ?? '') as String;
      });
    } catch (e) {
      debugPrint('ftp: $e');
    }
  }

  Future<void> _salvar() async {
    if ((_local.text.trim().isEmpty && _externo.text.trim().isEmpty) ||
        _usuario.text.trim().isEmpty) {
      setState(() => _mensagem =
          'Informe pelo menos um endere\u00e7o (rede local ou externa) e o usu\u00e1rio.');
      return;
    }
    if (!_temSenha && _senha.text.isEmpty) {
      setState(() => _mensagem = 'Informe a senha.');
      return;
    }
    setState(() {
      _ocupado = true;
      _mensagem = '';
    });
    await bind.mainSetCommon(
        key: 'cadena-ftp-salvar',
        value: jsonEncode({
          'servidor_local': _local.text,
          'servidor': _externo.text,
          'usuario': _usuario.text,
          'senha': _senha.text,
          'pasta': _pasta.text,
        }));
    _senha.clear();
    await _carregar();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      if (_ligado) _ativando = false;
      _mensagem = _ligado
          ? 'Configura\u00e7\u00e3o salva. Clique em Testar para conferir o envio.'
          : 'N\u00e3o foi poss\u00edvel salvar a configura\u00e7\u00e3o.';
    });
  }

  Future<void> _testar() async {
    setState(() {
      _ocupado = true;
      _mensagem = 'Testando o envio...';
    });
    final r = await bind.mainGetCommon(key: 'cadena-ftp-testar');
    await _carregar();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _mensagem = r;
    });
  }

  Future<void> _desligar() async {
    setState(() => _ocupado = true);
    await bind.mainSetCommon(key: 'cadena-ftp-desligar', value: '');
    await _carregar();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _senha.clear();
      _mensagem =
          'Envio desligado. As pr\u00f3ximas grava\u00e7\u00f5es ficam neste computador.';
    });
  }

  /// Interruptor do cabecalho: desligar apaga a configuracao (como o antigo botao Desligar); ligar so libera os
  /// campos, e o envio passa a valer ao Salvar
  Future<void> _alternar(bool ligar) async {
    if (ligar) {
      setState(() {
        _ativando = true;
        _mensagem = 'Preencha os dados e clique em Salvar para ligar o envio.';
      });
    } else if (_ligado) {
      setState(() => _ativando = false);
      await _desligar();
    } else {
      setState(() {
        _ativando = false;
        _mensagem = '';
      });
    }
  }

  bool get _ativo => _ligado || _ativando;

  /// Campo no estilo atual: rotulo a esquerda e o campo a direita quando o cartao e largo (modelo aprovado em
  /// 2026-11-13); estreito, o rotulo vai dentro da borda do campo
  Widget _campo(String rotulo, TextEditingController c,
      {String? dica, bool senha = false}) {
    return LayoutBuilder(builder: (context, k) {
      final aoLado = k.maxWidth >= 620;
      final campo = TextField(
        controller: c,
        obscureText: senha && !_verSenha,
        enabled: _ativo && !_ocupado,
        decoration: cadenaDecoracaoCampo(
          rotulo: aoLado ? null : rotulo,
          dica: dica,
          sufixo: senha
              ? IconButton(
                  tooltip: _verSenha ? 'Esconder a senha' : 'Mostrar a senha',
                  splashRadius: 18,
                  icon: Icon(_verSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _verSenha = !_verSenha),
                )
              : null,
        ),
      );
      if (!aoLado) return campo;
      return Row(children: [
        Expanded(
            flex: 5,
            child: Text(rotulo,
                style: TextStyle(
                    fontSize: 14.5,
                    color: _ativo ? cadenaPaleta.texto : cadenaPaleta.textoSuave))),
        Expanded(flex: 6, child: campo),
      ]);
    }).marginOnly(left: _kContentHMargin, top: 12);
  }

  @override
  Widget build(BuildContext context) {
    final suave = TextStyle(color: cadenaPaleta.textoSuave);
    return _Card(
        title: 'Envio das grava\u00e7\u00f5es (FTP)',
        title_suffix: [
          Flexible(
            child: Text('Ativar envio das grava\u00e7\u00f5es ao finalizar',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13.5, color: cadenaPaleta.texto)),
          ),
          const SizedBox(width: 6),
          cadenaInterruptor(
              value: _ativo, onChanged: _ocupado ? null : (v) => _alternar(v == true)),
        ],
        children: [
          Text(
                  _ligado
                      ? 'Ligado: cada grava\u00e7\u00e3o \u00e9 enviada ao fim do acesso e apagada deste computador.'
                      : (_ativando
                          ? 'Preencha os dados e clique em Salvar para ligar o envio.'
                          : 'Desligado: as grava\u00e7\u00f5es ficam neste computador.'),
                  style: suave)
              .marginOnly(left: _kContentHMargin),
          if (_pendentes > 0)
            Text('Grava\u00e7\u00f5es ainda neste computador: $_pendentes', style: suave)
                .marginOnly(left: _kContentHMargin, top: 4),
          _campo('Endere\u00e7o na rede local (opcional)', _local,
              dica: 'ex.: 192.168.0.10:21 - tentado primeiro, dentro do escrit\u00f3rio'),
          _campo('Endere\u00e7o externo', _externo,
              dica: 'ex.: ftp.exemplo.com.br:21 - usado fora do escrit\u00f3rio'),
          _campo('Usu\u00e1rio', _usuario),
          _campo(
              _temSenha
                  ? 'Senha (deixe em branco para manter a atual)'
                  : 'Senha',
              _senha,
              senha: true),
          _campo('Pasta no servidor', _pasta, dica: '/gravacoes'),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 10, runSpacing: 8, children: [
              SizedBox(
                height: 36,
                child: OutlinedButton(
                    onPressed: _ocupado || !_ligado ? null : _testar,
                    child: const Text('Testar conex\u00e3o')),
              ),
              cadenaBotao('Salvar', _ocupado || !_ativo ? null : _salvar,
                  largura: 110),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                    onPressed: _ocupado || !_ligado ? null : () => _alternar(false),
                    // Vermelho so quando da para desligar; apagado, igual aos outros botoes
                    style: _ligado && !_ocupado
                        ? OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.55)))
                        : null,
                    child: const Text('Desligar')),
              ),
            ]),
          ).marginOnly(left: _kContentHMargin, top: 18),
          if (_ocupado)
            const LinearProgressIndicator().marginOnly(left: _kContentHMargin, top: 8),
          if (_mensagem.isNotEmpty)
            SelectableText(_mensagem).marginOnly(left: _kContentHMargin, top: 8),
        ]);
  }
}
