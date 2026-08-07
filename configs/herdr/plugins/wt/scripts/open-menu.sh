#!/bin/sh
# Action entrypoint'i. Action'lar headless çalışır — bir tty'leri yoktur, yani
# interaktif olamazlar — o yüzden bu script'in tek işi popup pane'ini açmak.
# Tuş → action → popup zinciri bu yüzden var; tuşu doğrudan TUI'ye bağlamanın
# bir yolu yok.
#
# placement bilerek verilmiyor: popup yalnızca manifest'ten geliyor,
# `--placement` bayrağı 0.8.0'da da sadece overlay|split|tab|zoomed kabul ediyor.
set -u

# Çağrı bağlamını ileriye taşı: menu.ts repo'yu bundan buluyor, ve yeni pane
# kendi başına bunu miras almıyor.
if [ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]; then
  exec herdr plugin pane open \
    --plugin boemar.wt \
    --entrypoint menu \
    --focus \
    --env "HERDR_PLUGIN_CONTEXT_JSON=$HERDR_PLUGIN_CONTEXT_JSON"
fi

exec herdr plugin pane open --plugin boemar.wt --entrypoint menu --focus
