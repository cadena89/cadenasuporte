#!/usr/bin/env bash
# Instala SDK e NDK do Android, compila bibliotecas nativas e gera os APKs assinados.
# Uso: compilar.sh <arm64-v8a|armeabi-v7a>. Pode ser repetido.
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
ABI="${1:?Informe arm64-v8a ou armeabi-v7a}"
SAIDA="$ENTREGA/android"
VERSAO="$TAG_RUSTDESK"
# Numero da versao para o Android: precisa subir a cada entrega, senao o APK novo nao instala por cima do antigo.
# O compilar_todos.sh soma 1 antes de compilar as duas ABIs; aqui so e lido. O versionCode final e ABI*1000 + NUMERO
NUMERO="$(tr -dc '0-9' < "$ENTREGA/android/numero.txt")"
case "$ABI" in
  arm64-v8a) ALVO=aarch64-linux-android; SCRIPT=ndk_arm64.sh; PLATAFORMA=android-arm64; LIBCXX=aarch64-linux-android; NOME=arm64 ;;
  armeabi-v7a) ALVO=armv7-linux-androideabi; SCRIPT=ndk_arm.sh; PLATAFORMA=android-arm; LIBCXX=arm-linux-androideabi; NOME=armv7 ;;
  *) echo "ABI invalida: $ABI" >&2; exit 1 ;;
esac

echo "=== NDK r28c"
if [ ! -x "$ANDROID_NDK_HOME/ndk-build" ]; then
  curl -fsSL -o /tmp/ndk.zip https://dl.google.com/android/repository/android-ndk-r28c-linux.zip
  unzip -q /tmp/ndk.zip -d "$VB"
  rm -f /tmp/ndk.zip
fi

echo "=== SDK do Android"
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fsSL -o /tmp/cmdline.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q /tmp/cmdline.zip -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -f /tmp/cmdline.zip
fi
yes | sdkmanager --licenses >/dev/null || true
sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" >/dev/null
flutter --no-version-check config --android-sdk "$ANDROID_HOME" >/dev/null

echo "=== Marca"
bash "$SCRIPTS_ANDROID/aplicar_marca.sh"

echo "=== Bibliotecas nativas $ABI"
cd "$VB/rustdesk"
./flutter/build_android_deps.sh "$ABI"

echo "=== Biblioteca Rust $ALVO"
bash "./flutter/$SCRIPT"
JNI="flutter/android/app/src/main/jniLibs/$ABI"
mkdir -p "$JNI"
cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$LIBCXX/libc++_shared.so" "$JNI/"
cp "target/$ALVO/release/liblibrustdesk.so" "$JNI/librustdesk.so"

echo "=== Chave de assinatura"
# ANDROID_CHAVE (.jks) e ANDROID_SENHAS (senha.properties) ficam fora do repositorio. So sao criados quando nao
# existem: depois disso a mesma chave assina todas as versoes (com outra, o APK nao instala por cima)
: "${ANDROID_CHAVE:?Defina ANDROID_CHAVE (AndroidChave no config.local.psd1)}"
: "${ANDROID_SENHAS:?Defina ANDROID_SENHAS (AndroidSenhas no config.local.psd1)}"
mkdir -p "$(dirname "$ANDROID_CHAVE")" "$(dirname "$ANDROID_SENHAS")" "$SAIDA"
if [ ! -f "$ANDROID_CHAVE" ]; then
  ALIAS="${ANDROID_ALIAS:-suporte}"
  SENHA="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)"
  keytool -genkeypair -noprompt -keystore /tmp/nova-chave.jks -alias "$ALIAS" -keyalg RSA -keysize 4096 -validity 10000 \
    -storepass "$SENHA" -keypass "$SENHA" -dname "${ANDROID_DONO:-CN=Suporte}" >/dev/null 2>&1
  cp /tmp/nova-chave.jks "$ANDROID_CHAVE"
  rm -f /tmp/nova-chave.jks
  printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=%s\n' "$SENHA" "$SENHA" "$ALIAS" > "$ANDROID_SENHAS"
  unset SENHA
  echo "Chave nova criada em $ANDROID_CHAVE: guarde com backup"
fi
cp "$ANDROID_CHAVE" /tmp/assinatura.jks
{ cat "$ANDROID_SENHAS"; echo 'storeFile=/tmp/assinatura.jks'; } > flutter/android/key.properties

echo "=== APK $ABI"
sed -i "s/org.gradle.jvmargs=-Xmx1024M/org.gradle.jvmargs=-Xmx2g/g" flutter/android/gradle.properties
cd flutter
flutter --no-version-check build apk --release --target-platform "$PLATAFORMA" --split-per-abi --build-number "$NUMERO"
cd ..
rm -f flutter/android/key.properties /tmp/assinatura.jks
APK="flutter/build/app/outputs/flutter-apk/app-$ABI-release.apk"
FINAL="$SAIDA/${NOME_CLIENTE:?Defina NOME_CLIENTE}-$VERSAO-$NOME.apk"
cp "$APK" "$FINAL"

echo "=== Verificacao"
AAPT="$ANDROID_HOME/build-tools/36.0.0/aapt2"
"$AAPT" dump badging "$APK" | grep -E "^package:|^application-label:|^native-code:|^sdkVersion|^targetSdkVersion"
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --print-certs "$APK" | grep -E 'Signer #1 certificate (DN|SHA-256)'
unzip -l "$APK" | grep -E 'lib/.*/lib(rustdesk|app|flutter)\.so'
sha256sum "$FINAL"
if [ -n "${SERVIDOR:-}" ]; then
  LIB="$(unzip -p "$APK" "lib/$ABI/librustdesk.so" | strings -a | grep -cF "$SERVIDOR" || true)"
  echo "servidor no binario: $LIB ocorrencias"
fi
echo "=== Concluido $ABI"
