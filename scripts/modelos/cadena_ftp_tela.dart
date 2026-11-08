
// CadenaTech: envio das gravacoes do Tecnico por FTP, em Configuracoes > Geral. O 2_marca.ps1 junta este
// arquivo ao desktop_setting_page.dart. Grava o mesmo <prefixo>-ftp.txt do ConfigurarFTP.bat (src/cadena_ftp.rs),
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

  Widget _campo(String rotulo, TextEditingController c,
      {String? dica, bool senha = false}) {
    return TextField(
      controller: c,
      obscureText: senha,
      enabled: !_ocupado,
      decoration:
          InputDecoration(labelText: rotulo, hintText: dica, isDense: true),
    ).marginOnly(left: _kContentHMargin);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(title: 'Envio das grava\u00e7\u00f5es (FTP)', children: [
      Align(alignment: Alignment.centerLeft, child: Text(_ligado
              ? 'Ligado: cada grava\u00e7\u00e3o \u00e9 enviada ao fim do acesso e apagada deste computador.'
              : 'Desligado: as grava\u00e7\u00f5es ficam neste computador.'))
          .marginOnly(left: _kContentHMargin),
      if (_pendentes > 0)
        Align(alignment: Alignment.centerLeft, child: Text('Grava\u00e7\u00f5es ainda neste computador: $_pendentes'))
            .marginOnly(left: _kContentHMargin),
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
      Row(children: [
        ElevatedButton(
            onPressed: _ocupado ? null : _salvar, child: const Text('Salvar')),
        const SizedBox(width: 8),
        OutlinedButton(
            onPressed: _ocupado || !_ligado ? null : _testar,
            child: const Text('Testar')),
        const SizedBox(width: 8),
        if (_ligado)
          TextButton(
              onPressed: _ocupado ? null : _desligar,
              child: const Text('Desligar')),
      ]).marginOnly(left: _kContentHMargin, top: 8),
      if (_ocupado) const LinearProgressIndicator().marginOnly(left: _kContentHMargin),
      if (_mensagem.isNotEmpty)
        Align(alignment: Alignment.centerLeft, child: SelectableText(_mensagem))
            .marginOnly(left: _kContentHMargin),
    ]);
  }
}
