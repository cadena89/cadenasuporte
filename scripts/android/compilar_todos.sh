#!/usr/bin/env bash
# Nova entrega do Android: sobe o numero da versao e compila as duas ABIs com ele.
# Para recompilar sem mudar o numero, use compilar.sh direto (com as mesmas variaveis de ambiente).
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
ARQ="$ENTREGA/android/numero.txt"
mkdir -p "$ENTREGA/android"
[ -f "$ARQ" ] || echo 0 > "$ARQ"
NUMERO=$(( $(tr -dc '0-9' < "$ARQ") + 1 ))
echo "$NUMERO" > "$ARQ"
echo "=== Numero da versao $NUMERO (arm64 $((2000 + NUMERO)), armv7 $((1000 + NUMERO)))"
for ABI in arm64-v8a armeabi-v7a; do
  bash "$SCRIPTS_ANDROID/compilar.sh" "$ABI"
done
