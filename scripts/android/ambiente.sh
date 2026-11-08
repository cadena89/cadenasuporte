# Caminhos dentro da distribuicao do WSL usada para o Android (criada pelo 1_criar_wsl.ps1)
SCRIPTS_ANDROID="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export VB=/opt/vb
export RUSTUP_HOME=$VB/rustup
export CARGO_HOME=$VB/cargo
export PUB_CACHE=$VB/pub-cache
export VCPKG_ROOT=$VB/vcpkg
export VCPKG_DISABLE_METRICS=1
export VCPKG_MAX_CONCURRENCY=4
export CARGO_BUILD_JOBS=4
export ANDROID_HOME=$VB/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_HOME=$VB/android-ndk-r28c
export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export CI=true
export LANG=C.UTF-8
export PATH=$CARGO_HOME/bin:$VB/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_NDK_HOME:$PATH
# Vem do 0_nova_versao.ps1 (config.local.psd1 e marca). Para trocar a versao do RustDesk: TagRustDesk no config
# e depois trocar_base.sh
export TAG_RUSTDESK="${TAG_RUSTDESK:-1.5.1}"
: "${ENTREGA:?Defina ENTREGA (pasta de entrega, ex.: /mnt/d/rustdesk-build/entrega)}"
# A compilacao roda em prioridade baixa
renice -n 10 $$ >/dev/null 2>&1 || true
