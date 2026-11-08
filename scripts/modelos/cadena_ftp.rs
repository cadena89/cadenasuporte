// CadenaTech: envio das gravacoes do Tecnico por FTP. O 2_marca.ps1 copia este arquivo para src/cadena_ftp.rs,
// com o prefixo de arquivos e o nome do Tecnico da marca.
//
// Liga quando existe __PREFIXO__-ftp.txt na pasta de configuracao do app, gravado pela tela Configuracoes > Geral do
// Tecnico ou pelo ConfigurarFTP.bat:
//   servidor_local=192.168.0.10:21     (opcional: tentado primeiro, com prazo curto, dentro do escritorio)
//   servidor=ftp.exemplo.com.br:21       (externo: usado quando o local nao responde)
//   usuario=...
//   senha=...
//   pasta=/gravacoes
// Assim nao e preciso apontar o nome externo para o IP interno no arquivo hosts de cada tecnico.
// A senha fica so no perfil do tecnico, nunca no executavel publicado. Cada gravacao concluida e enviada (FTP
// passivo, binario) com o nome do tecnico na frente e, depois de o servidor confirmar o tamanho, apagada deste
// computador. O que falhar continua na pasta e e reenviado quando outra gravacao terminar.

use hbb_common::{bail, config::Config, lazy_static, log, ResultType};
use std::{
    collections::HashSet,
    fs,
    io::{BufRead, BufReader, Write},
    net::{IpAddr, Shutdown, SocketAddr, TcpStream, ToSocketAddrs},
    path::{Path, PathBuf},
    sync::Mutex,
    time::{Duration, SystemTime},
};

const ARQUIVO_CONFIG: &str = "__PREFIXO__-ftp.txt";
const PRAZO: Duration = Duration::from_secs(60);
const PRAZO_CONEXAO: Duration = Duration::from_secs(15);
// Gravacoes que sobraram de outras sessoes so sao enviadas se ninguem mexe nelas ha este tempo
const SOBRA_PARADA: Duration = Duration::from_secs(10 * 60);
// Sufixo do arquivo enquanto e enviado: impede dois envios do mesmo arquivo
const MARCA_ENVIO: &str = ".enviando";

lazy_static::lazy_static! {
    static ref GRAVANDO: Mutex<HashSet<PathBuf>> = Default::default();
    static ref ENVIO: Mutex<()> = Mutex::new(());
}

// Prazo curto para o endereco da rede local: fora do escritorio ele nao responde e o envio segue pelo externo
const PRAZO_LOCAL: Duration = Duration::from_secs(3);

#[derive(Default)]
struct Configuracao {
    servidor: String,
    servidor_local: String,
    usuario: String,
    senha: String,
    pasta: String,
}

/// "ftp://servidor:21/" -> "servidor:21"; sem porta -> ":21"; vazio continua vazio
fn normalizar_endereco(s: &str) -> String {
    let s = s.trim();
    let s = if s.len() > 6 && s[..6].eq_ignore_ascii_case("ftp://") {
        &s[6..]
    } else {
        s
    };
    let s = s.trim_end_matches('/').trim();
    if s.is_empty() {
        String::new()
    } else if s.contains(':') {
        s.to_owned()
    } else {
        format!("{}:21", s)
    }
}

fn ler_arquivo() -> Option<Configuracao> {
    let texto = fs::read_to_string(Config::path(ARQUIVO_CONFIG)).ok()?;
    let mut c = Configuracao::default();
    for linha in texto.trim_start_matches('\u{feff}').lines() {
        let Some((chave, valor)) = linha.split_once('=') else {
            continue;
        };
        match chave.trim() {
            "servidor" => c.servidor = normalizar_endereco(valor),
            "servidor_local" => c.servidor_local = normalizar_endereco(valor),
            "usuario" => c.usuario = valor.trim().to_owned(),
            "senha" => c.senha = valor.to_owned(),
            "pasta" => c.pasta = valor.trim().to_owned(),
            _ => {}
        }
    }
    Some(c)
}

fn ler_configuracao() -> Option<Configuracao> {
    let c = ler_arquivo()?;
    if (c.servidor.is_empty() && c.servidor_local.is_empty()) || c.usuario.is_empty() {
        return None;
    }
    Some(c)
}

fn pasta_gravacoes() -> String {
    crate::ui_interface::video_save_directory(false)
}

fn contar_pendentes() -> usize {
    fs::read_dir(pasta_gravacoes())
        .map(|itens| itens.flatten().filter(|i| e_gravacao(&i.path())).count())
        .unwrap_or(0)
}

/// Estado para a tela de configuracoes (sem a senha)
pub fn estado_json() -> String {
    let c = ler_arquivo().unwrap_or_default();
    serde_json::json!({
        "ligado": ler_configuracao().is_some(),
        "servidor": c.servidor,
        "servidor_local": c.servidor_local,
        "usuario": c.usuario,
        "pasta": c.pasta,
        "tem_senha": !c.senha.is_empty(),
        "pendentes": contar_pendentes(),
        "pasta_gravacoes": pasta_gravacoes(),
    })
    .to_string()
}

/// Grava a configuracao vinda da tela. Senha em branco mantem a atual. Depois, envia o que estiver pendente
pub fn salvar_json(json: &str) {
    let Ok(v) = serde_json::from_str::<serde_json::Value>(json) else {
        return;
    };
    let campo = |k: &str| v[k].as_str().unwrap_or("").to_owned();
    let atual = ler_arquivo().unwrap_or_default();
    let mut senha = campo("senha");
    if senha.is_empty() {
        senha = atual.senha;
    }
    let mut pasta = campo("pasta").trim().to_owned();
    if pasta.is_empty() {
        pasta = "/gravacoes".to_owned();
    }
    let texto = format!(
        "servidor_local={}\nservidor={}\nusuario={}\nsenha={}\npasta={}\n",
        normalizar_endereco(&campo("servidor_local")),
        normalizar_endereco(&campo("servidor")),
        campo("usuario").trim(),
        senha.replace(['\r', '\n'], ""),
        pasta
    );
    let arquivo = Config::path(ARQUIVO_CONFIG);
    if let Some(p) = arquivo.parent() {
        fs::create_dir_all(p).ok();
    }
    if let Err(e) = fs::write(&arquivo, texto) {
        log::error!("FTP: nao foi possivel salvar a configuracao: {}", e);
        return;
    }
    enviar_pendentes_agora();
}

/// Desliga o envio (apaga a configuracao deste usuario do Windows)
pub fn desligar() {
    fs::remove_file(Config::path(ARQUIVO_CONFIG)).ok();
}

/// Envia, em segundo plano, as gravacoes paradas ha mais de 1 minuto (as em andamento ficam)
fn enviar_pendentes_agora() {
    std::thread::spawn(|| {
        let pasta = pasta_gravacoes();
        if !pasta.is_empty() {
            enviar_pasta(Path::new(&pasta), None, Duration::from_secs(60));
        }
    });
}

/// Registra o aviso da gravacao. Chamado na abertura de todo processo; so age se houver configuracao.
pub fn registrar() {
    scrap::record::CADENA_AVISO
        .set(aviso as fn(&str, bool))
        .ok();
    // Ao abrir a janela principal (sem argumentos), envia o que sobrou de sessoes anteriores: por exemplo,
    // quando a janela do acesso era a ultima aberta e o programa fechou antes de terminar o envio.
    // So este processo grava, entao o GRAVANDO dele cobre as gravacoes em andamento
    if std::env::args().len() == 1 {
        std::thread::spawn(|| {
            std::thread::sleep(Duration::from_secs(60));
            if ler_configuracao().is_none() {
                return;
            }
            let pasta = pasta_gravacoes();
            if !pasta.is_empty() {
                enviar_pasta(Path::new(&pasta), None, SOBRA_PARADA);
            }
        });
    }
}

fn aviso(arquivo: &str, concluida: bool) {
    let caminho = PathBuf::from(arquivo);
    if !concluida {
        GRAVANDO.lock().unwrap().insert(caminho);
        return;
    }
    GRAVANDO.lock().unwrap().remove(&caminho);
    if ler_configuracao().is_none() {
        return;
    }
    std::thread::spawn(move || {
        // O gravador ainda termina de fechar o arquivo depois do aviso
        std::thread::sleep(Duration::from_secs(5));
        if let Some(pasta) = caminho.parent() {
            enviar_pasta(pasta, Some(&caminho), SOBRA_PARADA);
        }
    });
}

fn e_gravacao(p: &Path) -> bool {
    let nome = p
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_lowercase();
    let nome = nome.trim_end_matches(MARCA_ENVIO);
    nome.ends_with(".webm") || nome.ends_with(".mp4")
}

fn parado_ha(p: &Path) -> Option<Duration> {
    // fs::metadata abre o arquivo e le a hora real da ultima gravacao, mesmo com ele aberto
    let quando = fs::metadata(p).ok()?.modified().ok()?;
    SystemTime::now().duration_since(quando).ok()
}

/// Envia a gravacao que acabou de terminar (atual) e as sobras da pasta paradas ha mais de "parada"
fn enviar_pasta(pasta: &Path, atual: Option<&Path>, parada: Duration) {
    let _vez = ENVIO.lock().unwrap();
    let Some(c) = ler_configuracao() else {
        return;
    };
    let mut lista = Vec::new();
    if let Some(a) = atual {
        if a.exists() {
            lista.push(a.to_path_buf());
        }
    }
    if let Ok(itens) = fs::read_dir(pasta) {
        for item in itens.flatten() {
            let p = item.path();
            if Some(p.as_path()) == atual || !e_gravacao(&p) || GRAVANDO.lock().unwrap().contains(&p) {
                continue;
            }
            if parado_ha(&p).map(|d| d >= parada).unwrap_or(false) {
                lista.push(p);
            }
        }
    }
    for arquivo in lista {
        match enviar_arquivo(&c, &arquivo) {
            Ok(remoto) => log::info!("FTP: {} enviado como {}", arquivo.display(), remoto),
            Err(e) => {
                // Servidor fora ou recusando: para aqui e tenta tudo de novo na proxima gravacao
                log::error!("FTP: falha ao enviar {}: {}", arquivo.display(), e);
                break;
            }
        }
    }
}

fn enviar_arquivo(c: &Configuracao, arquivo: &Path) -> ResultType<String> {
    let Some(nome) = arquivo.file_name().and_then(|n| n.to_str()) else {
        bail!("nome de arquivo invalido");
    };
    let original = arquivo.with_file_name(nome.trim_end_matches(MARCA_ENVIO));
    let nome_original = nome.trim_end_matches(MARCA_ENVIO).to_owned();
    let marcado = if nome.ends_with(MARCA_ENVIO) {
        arquivo.to_path_buf()
    } else {
        // A troca de nome falha enquanto o gravador ainda segura o arquivo: espera um pouco
        let m = arquivo.with_file_name(format!("{}{}", nome, MARCA_ENVIO));
        let mut marcou = false;
        for _ in 0..6 {
            if fs::rename(arquivo, &m).is_ok() {
                marcou = true;
                break;
            }
            std::thread::sleep(Duration::from_secs(5));
        }
        if !marcou {
            bail!("o arquivo continua em uso");
        }
        m
    };
    let remoto = format!("{}_{}", nome_tecnico(), nome_original);
    let resultado = (|| -> ResultType<()> {
        let tamanho = fs::metadata(&marcado)?.len();
        let (mut ftp, _) = Ftp::conectar_melhor(c)?;
        ftp.enviar(&marcado, &remoto, tamanho)?;
        ftp.sair();
        Ok(())
    })();
    match resultado {
        Ok(()) => {
            fs::remove_file(&marcado).ok();
            Ok(remoto)
        }
        Err(e) => {
            fs::rename(&marcado, &original).ok();
            Err(e)
        }
    }
}

/// Nome do tecnico para o arquivo no servidor, na mesma ordem do nome mostrado ao cliente: o do
/// DefinirNomeTecnico.bat, o nome da conta logada na API e, por ultimo, o usuario do Windows.
/// Fica em minusculas, sem acentos e sem espacos
fn nome_tecnico() -> String {
    const DE: &str = "\u{e1}\u{e0}\u{e2}\u{e3}\u{e4}\u{e9}\u{e8}\u{ea}\u{eb}\u{ed}\u{ec}\u{ee}\u{ef}\u{f3}\u{f2}\u{f4}\u{f5}\u{f6}\u{fa}\u{f9}\u{fb}\u{fc}\u{e7}\u{f1}";
    const PARA: &str = "aaaaaeeeeiiiiooooouuuucn";
    let mut nome = fs::read_to_string(Config::path("__PREFIXO__-nome-tecnico.txt")).unwrap_or_default();
    if nome.trim().is_empty() {
        nome = serde_json::from_str::<serde_json::Value>(&hbb_common::config::LocalConfig::get_option("user_info"))
            .ok()
            .and_then(|x| {
                ["display_name", "name"].iter().find_map(|k| {
                    x.get(*k)
                        .and_then(|v| v.as_str())
                        .map(|v| v.trim().to_owned())
                        .filter(|v| !v.is_empty())
                })
            })
            .unwrap_or_default();
    }
    if nome.trim().is_empty() {
        nome = std::env::var("USERNAME").unwrap_or_default();
    }
    let mut s = String::new();
    for ch in nome.trim().to_lowercase().chars() {
        if ch.is_ascii_alphanumeric() {
            s.push(ch);
        } else if let Some(i) = DE.chars().position(|d| d == ch) {
            s.push(PARA.as_bytes()[i] as char);
        } else if (ch == ' ' || ch == '-' || ch == '_' || ch == '.') && !s.ends_with('-') {
            s.push('-');
        }
    }
    let s: String = s.trim_matches('-').chars().take(40).collect();
    if s.is_empty() {
        "tecnico".to_owned()
    } else {
        s
    }
}

/// Teste (tela de configuracoes ou ConfigurarFTP.bat): conecta, envia um arquivo pequeno, confere e apaga
pub fn testar() -> String {
    let Some(c) = ler_configuracao() else {
        return "O envio das grava\u{e7}\u{f5}es por FTP n\u{e3}o est\u{e1} configurado.\n\nPreencha em Configura\u{e7}\u{f5}es > Geral > Envio das grava\u{e7}\u{f5}es (FTP).".to_owned();
    };
    let nome = format!("teste-{}.txt", nome_tecnico());
    let resultado = (|| -> ResultType<String> {
        let temp = std::env::temp_dir().join(&nome);
        fs::write(&temp, "Teste de envio do __TESTE__\r\n".as_bytes())?;
        let tamanho = fs::metadata(&temp)?.len();
        let (mut ftp, rede) = Ftp::conectar_melhor(&c)?;
        let enviado = ftp.enviar(&temp, &nome, tamanho);
        fs::remove_file(&temp).ok();
        enviado?;
        ftp.comando(&format!("DELE {}", nome)).ok();
        ftp.sair();
        Ok(rede)
    })();
    let pasta = if c.pasta.is_empty() { "/" } else { c.pasta.as_str() };
    match resultado {
        Ok(rede) => format!(
            "Envio por FTP funcionando, pela {}.\n\nUsu\u{e1}rio: {}\nPasta: {}\n\nAs grava\u{e7}\u{f5}es ser\u{e3}o enviadas ao fim de cada acesso e apagadas deste computador.",
            rede, c.usuario, pasta
        ),
        Err(e) => format!(
            "N\u{e3}o foi poss\u{ed}vel enviar para o FTP:\n{}\n\nUsu\u{e1}rio: {}\nPasta: {}",
            e, c.usuario, pasta
        ),
    }
}

/// Cliente FTP minimo: modo passivo e binario, so o que o envio precisa
struct Ftp {
    leitor: BufReader<TcpStream>,
    ip: IpAddr,
}

impl Ftp {
    /// Tenta o endereco da rede local (prazo curto) e depois o externo. Devolve tambem por qual rede foi
    fn conectar_melhor(c: &Configuracao) -> ResultType<(Ftp, String)> {
        let mut erros = Vec::new();
        for (endereco, prazo, rede) in [
            (&c.servidor_local, PRAZO_LOCAL, "rede local"),
            (&c.servidor, PRAZO_CONEXAO, "rede externa"),
        ] {
            if endereco.is_empty() {
                continue;
            }
            match Ftp::conectar(c, endereco, prazo) {
                Ok(ftp) => return Ok((ftp, format!("{} ({})", rede, endereco))),
                Err(e) => erros.push(format!("{} ({}): {}", rede, endereco, e)),
            }
        }
        bail!("{}", erros.join("\n"))
    }

    fn conectar(c: &Configuracao, servidor: &str, prazo: Duration) -> ResultType<Ftp> {
        let Some(endereco) = servidor.to_socket_addrs()?.next() else {
            bail!("servidor {} n\u{e3}o encontrado", servidor);
        };
        let s = TcpStream::connect_timeout(&endereco, prazo)?;
        s.set_read_timeout(Some(PRAZO))?;
        s.set_write_timeout(Some(PRAZO))?;
        let mut ftp = Ftp {
            leitor: BufReader::new(s),
            ip: endereco.ip(),
        };
        ftp.esperar(&[220])?;
        let (codigo, texto) = ftp.comando(&format!("USER {}", c.usuario))?;
        if codigo == 331 {
            ftp.comando_esperando(&format!("PASS {}", c.senha), &[230, 202])?;
        } else if codigo != 230 {
            bail!("usu\u{e1}rio recusado: {}", texto);
        }
        ftp.comando_esperando("TYPE I", &[200])?;
        let pasta = c.pasta.trim();
        if pasta.starts_with('/') {
            ftp.comando_esperando("CWD /", &[250])?;
        }
        for parte in pasta.split('/').filter(|p| !p.is_empty()) {
            if ftp.comando(&format!("CWD {}", parte))?.0 != 250 {
                ftp.comando(&format!("MKD {}", parte))?;
                ftp.comando_esperando(&format!("CWD {}", parte), &[250])?;
            }
        }
        Ok(ftp)
    }

    fn ler_linha(&mut self) -> ResultType<String> {
        let mut bytes = Vec::new();
        if self.leitor.read_until(b'\n', &mut bytes)? == 0 {
            bail!("o servidor fechou a conex\u{e3}o");
        }
        Ok(String::from_utf8_lossy(&bytes).into_owned())
    }

    fn resposta(&mut self) -> ResultType<(u32, String)> {
        let mut linha = self.ler_linha()?;
        let Some(codigo) = linha.get(0..3).and_then(|c| c.parse::<u32>().ok()) else {
            bail!("resposta inesperada do servidor: {}", linha.trim_end());
        };
        // Resposta de varias linhas: "220-..." ate "220 ..."
        if linha.as_bytes().get(3) == Some(&b'-') {
            let fim = format!("{} ", codigo);
            loop {
                let l = self.ler_linha()?;
                linha.push_str(&l);
                if l.starts_with(&fim) {
                    break;
                }
            }
        }
        Ok((codigo, linha.trim_end().to_owned()))
    }

    fn esperar(&mut self, aceitos: &[u32]) -> ResultType<String> {
        let (codigo, texto) = self.resposta()?;
        if !aceitos.contains(&codigo) {
            bail!("{}", texto);
        }
        Ok(texto)
    }

    fn comando(&mut self, comando: &str) -> ResultType<(u32, String)> {
        self.leitor
            .get_mut()
            .write_all(format!("{}\r\n", comando).as_bytes())?;
        self.resposta()
    }

    fn comando_esperando(&mut self, comando: &str, aceitos: &[u32]) -> ResultType<String> {
        let (codigo, texto) = self.comando(comando)?;
        if !aceitos.contains(&codigo) {
            let mostrado = if comando.starts_with("PASS ") {
                "PASS ***"
            } else {
                comando
            };
            bail!("{} -> {}", mostrado, texto);
        }
        Ok(texto)
    }

    fn dados(&mut self) -> ResultType<TcpStream> {
        let texto = self.comando_esperando("PASV", &[227])?;
        // "227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)". Usa o IP da conexao de controle, que atravessa NAT
        let (Some(a), Some(b)) = (texto.find('('), texto.rfind(')')) else {
            bail!("resposta PASV inesperada: {}", texto);
        };
        if b <= a {
            bail!("resposta PASV inesperada: {}", texto);
        }
        let numeros: Vec<u32> = texto[a + 1..b]
            .split(',')
            .filter_map(|n| n.trim().parse().ok())
            .collect();
        if numeros.len() != 6 || numeros[4] > 255 || numeros[5] > 255 {
            bail!("resposta PASV inesperada: {}", texto);
        }
        let porta = (numeros[4] * 256 + numeros[5]) as u16;
        let s = TcpStream::connect_timeout(&SocketAddr::new(self.ip, porta), PRAZO_CONEXAO)?;
        s.set_read_timeout(Some(PRAZO))?;
        s.set_write_timeout(Some(PRAZO))?;
        Ok(s)
    }

    fn enviar(&mut self, arquivo: &Path, remoto: &str, tamanho: u64) -> ResultType<()> {
        let mut dados = self.dados()?;
        let (codigo, texto) = self.comando(&format!("STOR {}", remoto))?;
        if codigo != 125 && codigo != 150 {
            bail!("STOR -> {}", texto);
        }
        let mut origem = fs::File::open(arquivo)?;
        std::io::copy(&mut origem, &mut dados)?;
        dados.flush()?;
        dados.shutdown(Shutdown::Write).ok();
        drop(dados);
        self.esperar(&[226, 250])?;
        // Confere o tamanho no servidor antes de a copia local ser apagada
        let (codigo, texto) = self.comando(&format!("SIZE {}", remoto))?;
        if codigo == 213 {
            let no_servidor: u64 = texto.get(4..).unwrap_or("").trim().parse().unwrap_or(u64::MAX);
            if no_servidor != tamanho {
                bail!(
                    "tamanho no servidor ({}) diferente do arquivo ({})",
                    no_servidor,
                    tamanho
                );
            }
        }
        Ok(())
    }

    fn sair(mut self) {
        self.comando("QUIT").ok();
    }
}
