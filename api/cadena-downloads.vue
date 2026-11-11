<script setup lang="ts">
// Cartao "Downloads" da Home: links da ultima versao publicada no GitHub (releases/latest), para o tecnico
// copiar e mandar ao cliente sem digitar o endereco de uma versao antiga. Os valores __...__ sao trocados
// pelo api\atualizar_api.ps1 (RepoAtualizacao, NomeCliente e NomeTecnico da marca).
import { onMounted, ref } from 'vue';

defineOptions({ name: 'CadenaDownloads' });

const repo = '__REPO__';
const cliente = '__CLIENTE__';
const tecnico = '__TECNICO__';
const paginaVersoes = `https://github.com/${repo}/releases/latest`;

interface Arquivo {
  nome: string;
  rotulo: string;
  url: string;
  mb: string;
}

const versao = ref('');
const data = ref('');
const arquivos = ref<Arquivo[]>([]);
const carregando = ref(true);
const erro = ref(false);

function rotulo(nome: string) {
  let quem = '';
  if (nome.startsWith(`${cliente}-`)) quem = 'Cliente';
  else if (nome.startsWith(`${tecnico}-`)) quem = 'Técnico';
  else quem = nome.split('-')[0];
  if (nome.endsWith('-install.exe')) return `${quem}: instalador (Windows)`;
  if (nome.endsWith('-portatil.exe')) return `${quem}: portátil, sem instalar (Windows)`;
  const apk = nome.match(/-(arm64|armv7)\.apk$/);
  if (apk) return `${quem}: Android (${apk[1] === 'arm64' ? 'celulares atuais' : 'celulares antigos'})`;
  return `${quem}: ${nome}`;
}

function ordem(nome: string) {
  const base = nome.startsWith(`${cliente}-`) ? 0 : nome.startsWith(`${tecnico}-`) ? 10 : 20;
  if (nome.endsWith('-install.exe')) return base;
  if (nome.endsWith('-portatil.exe')) return base + 1;
  return base + 2;
}

async function carregar() {
  carregando.value = true;
  erro.value = false;
  try {
    const resposta = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' }
    });
    if (!resposta.ok) throw new Error(String(resposta.status));
    const r = await resposta.json();
    versao.value = r.tag_name || '';
    data.value = r.published_at ? new Date(r.published_at).toLocaleDateString('pt-BR') : '';
    arquivos.value = (r.assets || [])
      .filter((a: any) => /\.(exe|apk)$/i.test(a.name))
      .sort((a: any, b: any) => ordem(a.name) - ordem(b.name))
      .map((a: any) => ({
        nome: a.name,
        rotulo: rotulo(a.name),
        url: a.browser_download_url,
        mb: (a.size / 1048576).toFixed(1).replace('.', ',')
      }));
  } catch {
    erro.value = true;
  } finally {
    carregando.value = false;
  }
}

async function copiar(url: string) {
  try {
    await navigator.clipboard.writeText(url);
    window.$message?.success('Link copiado');
  } catch {
    window.$message?.error('Não foi possível copiar. Clique com o botão direito em Baixar e copie o link.');
  }
}

onMounted(carregar);
</script>

<template>
  <NCard :bordered="false" class="card-wrapper">
    <template #header>
      <span>Downloads</span>
      <span v-if="versao" class="pl-8px text-14px font-normal opacity-70">
        última versão: {{ versao }}{{ data ? ` (${data})` : '' }}
      </span>
    </template>
    <template #header-extra>
      <a :href="paginaVersoes" target="_blank" rel="noopener" class="text-14px text-primary">Página da versão</a>
    </template>
    <NSpin v-if="carregando" size="small" />
    <div v-else-if="erro" class="text-14px">
      Não foi possível consultar o GitHub agora.
      <a :href="paginaVersoes" target="_blank" rel="noopener" class="text-primary">Abrir a página da última versão</a>
      <NButton size="tiny" class="ml-8px" @click="carregar">Tentar de novo</NButton>
    </div>
    <div v-else class="flex-col gap-8px">
      <div v-for="a in arquivos" :key="a.nome" class="flex flex-wrap items-center gap-8px">
        <span class="min-w-280px flex-1 text-14px">
          {{ a.rotulo }}
          <span class="text-12px opacity-60">{{ a.nome }} · {{ a.mb }} MB</span>
        </span>
        <NButton size="small" tag="a" :href="a.url" type="primary">Baixar</NButton>
        <NButton size="small" @click="copiar(a.url)">Copiar link</NButton>
      </div>
      <div class="pt-4px text-12px opacity-70">
        Para o cliente, mande o link do instalador do Cliente. Esta lista mostra sempre a última versão
        publicada: use estes links em vez de digitar o endereço de uma versão antiga.
      </div>
    </div>
  </NCard>
</template>

<style scoped></style>
