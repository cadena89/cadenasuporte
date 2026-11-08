using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Cryptography;
using System.Security.Principal;
using System.ServiceProcess;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("Instalador do __EXIBIDO_CLIENTE__")]
[assembly: AssemblyProduct("__EXIBIDO_CLIENTE__")]
[assembly: AssemblyCompany("__EMPRESA__")]
[assembly: AssemblyVersion("1.5.1.0")]

namespace InstaladorSuporte
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.Run(new Janela());
        }
    }

    class Resultado
    {
        public string Id = "";
        public string Senha = "";
        public string Aviso = "";
    }

    static class Instalador
    {
        const string NomeApp = "__NOME_CLIENTE__";
        const string RecursoPacote = "pacote.exe";

        static readonly string PastaDados = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), NomeApp);
        public static readonly string ArquivoLog = Path.Combine(PastaDados, "instalacao.log");

        static string ExeInstalado
        {
            get
            {
                return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), NomeApp, NomeApp + ".exe");
            }
        }

        public static Resultado Executar(Action<string> status)
        {
            Directory.CreateDirectory(PastaDados);
            Log("=== Inicio ===");

            // 1. Instala somente quando falta; maquinas ja instaladas recebem apenas uma senha nova
            if (File.Exists(ExeInstalado))
            {
                Log("Ja instalado, versao " + FileVersionInfo.GetVersionInfo(ExeInstalado).ProductVersion + ". Instalacao ignorada.");
                status("__EXIBIDO_CLIENTE__ já instalado. Atualizando o acesso...");
            }
            else
            {
                status("Instalando o __EXIBIDO_CLIENTE__...");
                InstalarPacote(status);
            }

            // 2. Aguarda o servico, necessario para os comandos de configuracao
            status("Aguardando o serviço do __EXIBIDO_CLIENTE__...");
            AguardarServico();

            status("Obtendo o ID desta máquina...");
            Resultado r = new Resultado();
            r.Id = AguardarId();

            // 3. Libera o controle completo e confirma lendo o valor de volta
            status("Aplicando as permissões...");
            string saida;
            Rodar(ExeInstalado, "--option access-mode full", 30000, out saida);
            string modo = "";
            for (int i = 0; i < 5 && modo != "full"; i++)
            {
                Thread.Sleep(1000);
                Rodar(ExeInstalado, "--option access-mode", 30000, out saida);
                modo = saida.Trim();
            }
            if (modo != "full")
            {
                throw new Exception("Não foi possível confirmar as permissões de acesso.");
            }

            // O padrao do Cliente e aprovar cada acesso com um clique; aqui a senha fixa tambem precisa entrar sozinha
            Rodar(ExeInstalado, "--option approve-mode password-click", 30000, out saida);
            string aprovacao = "";
            for (int i = 0; i < 5 && aprovacao != "password-click"; i++)
            {
                Thread.Sleep(1000);
                Rodar(ExeInstalado, "--option approve-mode", 30000, out saida);
                aprovacao = saida.Trim();
            }
            if (aprovacao != "password-click")
            {
                throw new Exception("Não foi possível liberar o acesso por senha.");
            }

            // 4. Senha exclusiva desta maquina; nao e gravada em log nem em arquivo
            status("Definindo a senha de acesso...");
            string senha = GerarSenha(16);
            Rodar(ExeInstalado, "--password " + senha, 30000, out saida);
            if (saida.IndexOf("Done", StringComparison.OrdinalIgnoreCase) < 0)
            {
                throw new Exception("A senha não foi aceita pelo __EXIBIDO_CLIENTE__: " + saida.Trim());
            }
            r.Senha = senha;

            if (ServicoExiste("RustDesk"))
            {
                r.Aviso = "Atenção: o RustDesk continua instalado nesta máquina e pode entrar em conflito de ID. Desinstale-o.";
                Log("Aviso: servico RustDesk encontrado");
            }

            Log("Concluido. ID " + r.Id);
            return r;
        }

        static void InstalarPacote(Action<string> status)
        {
            string pasta = Path.Combine(PastaDados, "setup_" + Guid.NewGuid().ToString("N"));
            CriarPastaProtegida(pasta);
            try
            {
                string pacote = Path.Combine(pasta, NomeApp + ".exe");
                using (Stream origem = Assembly.GetExecutingAssembly().GetManifestResourceStream(RecursoPacote))
                using (FileStream destino = new FileStream(pacote, FileMode.Create, FileAccess.Write))
                {
                    origem.CopyTo(destino);
                }

                string saida;
                int codigo = Rodar(pacote, "--silent-install", 120000, out saida);
                Log("Pacote iniciado, codigo " + codigo);

                // O pacote extrai os arquivos e continua a instalacao em outro processo, entao o resultado vem do disco
                DateTime limite = DateTime.UtcNow.AddMinutes(5);
                while (!File.Exists(ExeInstalado))
                {
                    if (DateTime.UtcNow >= limite)
                    {
                        throw new Exception("A instalação não terminou em 5 minutos. Arquivo esperado: " + ExeInstalado);
                    }
                    Thread.Sleep(3000);
                }
                Log("Arquivos instalados");
            }
            finally
            {
                try { Directory.Delete(pasta, true); } catch { }
            }
        }

        // Pasta restrita a administradores e SYSTEM, porque o pacote e executado com privilegio elevado
        static void CriarPastaProtegida(string pasta)
        {
            DirectorySecurity seguranca = new DirectorySecurity();
            seguranca.SetAccessRuleProtection(true, false);
            InheritanceFlags heranca = InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit;
            seguranca.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSidType.BuiltinAdministratorsSid, null),
                FileSystemRights.FullControl, heranca, PropagationFlags.None, AccessControlType.Allow));
            seguranca.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSidType.LocalSystemSid, null),
                FileSystemRights.FullControl, heranca, PropagationFlags.None, AccessControlType.Allow));
            Directory.CreateDirectory(pasta, seguranca);
        }

        static bool ServicoExiste(string nome)
        {
            try
            {
                using (ServiceController sc = new ServiceController(nome))
                {
                    return sc.Status >= 0;
                }
            }
            catch (InvalidOperationException)
            {
                return false;
            }
        }

        static void AguardarServico()
        {
            bool registrou = false;
            DateTime limite = DateTime.UtcNow.AddSeconds(120);
            while (DateTime.UtcNow < limite)
            {
                try
                {
                    using (ServiceController sc = new ServiceController(NomeApp))
                    {
                        if (sc.Status == ServiceControllerStatus.Running)
                        {
                            return;
                        }
                        if (sc.Status == ServiceControllerStatus.Stopped)
                        {
                            sc.Start();
                        }
                    }
                }
                catch (InvalidOperationException)
                {
                    // Servico inexistente: a instalacao ainda pode estar registrando; apos 20 s registra aqui
                    if (!registrou && limite.Subtract(DateTime.UtcNow).TotalSeconds < 100)
                    {
                        registrou = true;
                        string saida;
                        Log("Servico ausente; executando --install-service");
                        Rodar(ExeInstalado, "--install-service", 60000, out saida);
                    }
                }
                Thread.Sleep(3000);
            }
            throw new Exception("O serviço do __EXIBIDO_CLIENTE__ não iniciou em 2 minutos.");
        }

        static string AguardarId()
        {
            for (int i = 0; i < 20; i++)
            {
                string saida;
                Rodar(ExeInstalado, "--get-id", 30000, out saida);
                string id = saida.Trim();
                if (id.Length > 0)
                {
                    return id;
                }
                Thread.Sleep(3000);
            }
            throw new Exception("Não foi possível obter o ID do __EXIBIDO_CLIENTE__.");
        }

        // Sem caracteres ambiguos, para poder ser ditada por telefone
        static string GerarSenha(int tamanho)
        {
            const string alfabeto = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
            int limite = 256 - (256 % alfabeto.Length);
            StringBuilder senha = new StringBuilder();
            byte[] b = new byte[1];
            using (RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider())
            {
                while (senha.Length < tamanho)
                {
                    rng.GetBytes(b);
                    if (b[0] < limite)
                    {
                        senha.Append(alfabeto[b[0] % alfabeto.Length]);
                    }
                }
            }
            return senha.ToString();
        }

        static int Rodar(string arquivo, string argumentos, int limiteMs, out string saida)
        {
            StringBuilder texto = new StringBuilder();
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = arquivo,
                Arguments = argumentos,
                CreateNoWindow = true,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };
            using (Process p = new Process())
            {
                p.StartInfo = psi;
                p.OutputDataReceived += delegate(object s, DataReceivedEventArgs e)
                {
                    if (e.Data != null)
                    {
                        lock (texto) { texto.AppendLine(e.Data); }
                    }
                };
                p.Start();
                p.BeginOutputReadLine();
                if (!p.WaitForExit(limiteMs))
                {
                    try { p.Kill(); } catch { }
                    lock (texto) { saida = texto.ToString(); }
                    return -1;
                }
                Thread.Sleep(200);
                lock (texto) { saida = texto.ToString(); }
                return p.ExitCode;
            }
        }

        public static void Log(string mensagem)
        {
            try
            {
                Directory.CreateDirectory(PastaDados);
                File.AppendAllText(ArquivoLog, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " " + mensagem + Environment.NewLine);
            }
            catch { }
        }
    }

    class Janela : Form
    {
        readonly Label lblStatus = new Label();
        readonly TextBox txtId = new TextBox();
        readonly TextBox txtSenha = new TextBox();
        readonly Button btnCopiar = new Button();
        readonly Button btnFechar = new Button();
        bool executando = true;

        public Janela()
        {
            Text = "__EXIBIDO_CLIENTE__";
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            ClientSize = new Size(440, 210);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;

            lblStatus.SetBounds(16, 14, 408, 56);
            lblStatus.Text = "Preparando...";

            Label lblId = new Label();
            lblId.SetBounds(16, 78, 70, 22);
            lblId.Text = "ID:";
            txtId.SetBounds(90, 76, 334, 24);
            txtId.ReadOnly = true;

            Label lblSenha = new Label();
            lblSenha.SetBounds(16, 112, 70, 22);
            lblSenha.Text = "Senha:";
            txtSenha.SetBounds(90, 110, 334, 24);
            txtSenha.ReadOnly = true;

            btnCopiar.SetBounds(214, 160, 120, 32);
            btnCopiar.Text = "Copiar dados";
            btnCopiar.Enabled = false;
            btnCopiar.Click += delegate
            {
                Clipboard.SetText("ID: " + txtId.Text + Environment.NewLine + "Senha: " + txtSenha.Text);
            };

            btnFechar.SetBounds(344, 160, 80, 32);
            btnFechar.Text = "Fechar";
            btnFechar.Enabled = false;
            btnFechar.Click += delegate { Close(); };

            Controls.AddRange(new Control[] { lblStatus, lblId, txtId, lblSenha, txtSenha, btnCopiar, btnFechar });

            FormClosing += delegate(object s, FormClosingEventArgs e)
            {
                if (executando)
                {
                    e.Cancel = true;
                }
            };

            Shown += delegate
            {
                Thread trabalho = new Thread(Trabalhar);
                trabalho.IsBackground = true;
                trabalho.Start();
            };
        }

        void Trabalhar()
        {
            try
            {
                Resultado r = Instalador.Executar(delegate(string texto)
                {
                    BeginInvoke((MethodInvoker)delegate { lblStatus.Text = texto; });
                });
                BeginInvoke((MethodInvoker)delegate
                {
                    txtId.Text = r.Id;
                    txtSenha.Text = r.Senha;
                    lblStatus.ForeColor = r.Aviso.Length > 0 ? Color.DarkOrange : Color.DarkGreen;
                    lblStatus.Text = "Concluído. Envie o ID e a senha ao suporte antes de fechar: a senha não será mostrada novamente."
                        + (r.Aviso.Length > 0 ? Environment.NewLine + r.Aviso : "");
                    btnCopiar.Enabled = true;
                    Encerrar();
                });
            }
            catch (Exception ex)
            {
                Instalador.Log("ERRO: " + ex.Message);
                BeginInvoke((MethodInvoker)delegate
                {
                    lblStatus.ForeColor = Color.Firebrick;
                    lblStatus.Text = ex.Message + Environment.NewLine + "Registro: " + Instalador.ArquivoLog;
                    Encerrar();
                });
            }
        }

        void Encerrar()
        {
            executando = false;
            btnFechar.Enabled = true;
        }
    }
}
