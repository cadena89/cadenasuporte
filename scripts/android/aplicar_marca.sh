#!/usr/bin/env bash
# Recoloca o codigo no estado original da tag e aplica os patches gerados no Windows (6_empacotar.ps1).
set -euo pipefail
source "$(dirname "$0")/ambiente.sh"
FONTE="$ENTREGA/fonte"
cd "$VB/rustdesk"
git -C libs/hbb_common checkout --quiet .
git checkout --quiet -- . ':!libs/hbb_common'
# Arquivos novos do patch (ex.: src/cadena_ftp.rs) nao saem com o checkout; apaga antes de reaplicar
for NOVO in $(git apply --summary "$FONTE/rustdesk.patch" | awk '/create mode/ {print $4}'); do rm -f "$NOVO"; done
git apply --whitespace=nowarn "$FONTE/rustdesk.patch"
git -C libs/hbb_common apply --whitespace=nowarn "$FONTE/hbb_common.patch"
grep -n 'applicationId' flutter/android/app/build.gradle
grep -n 'RENDEZVOUS_SERVERS: \|APP_NAME: ' libs/hbb_common/src/config.rs
echo "Marca aplicada"
