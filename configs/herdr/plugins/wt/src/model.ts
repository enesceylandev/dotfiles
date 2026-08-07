// Saf model: porcelain ayrıştırma, tuş → durum geçişi.
//
// Burada bilerek hiç IO yok. Reducer saf olduğu sürece "j j enter enter" gibi
// bir akışı popup açmadan, tuşa basmadan, gözle bakmadan test edebiliyoruz.
// IO (raw stdin, çizim, süreç çalıştırma) menu.ts'te, çizim render.ts'te.

export type Panel = "worktree" | "slot" | "snapshot";
export const PANELS: Panel[] = ["worktree", "slot", "snapshot"];

export type Worktree = {
  name: string;
  branch: string;
  path: string;
  missingEnv: number;
  running: boolean;
};

export type SlotState = "down" | "convex" | "up";

export type Slot = {
  n: string;
  wtName: string;
  path: string;
  fe: string;
  be: string;
  api: string;
  site: string;
  state: SlotState;
  log: string;
};

export type Snapshot = { name: string; bytes: number; mtime: number };

export type Data = {
  worktrees: Worktree[];
  slots: Slot[];
  snapshots: Snapshot[];
};

// `wt --porcelain` sözleşmesi: tip belirteci ilk alan, sekme ayrılmış, alanlar
// yalnızca sona eklenir. Bilinmeyen tipleri ve eksik alanlı satırları sessizce
// atlıyoruz — script'e yeni bir kayıt tipi eklendiğinde bu menü çökmesin.
export function parsePorcelain(out: string): Data {
  const data: Data = { worktrees: [], slots: [], snapshots: [] };
  for (const line of out.split("\n")) {
    if (!line) continue;
    const f = line.split("\t");
    switch (f[0]) {
      case "worktree":
        if (f.length < 6) break;
        data.worktrees.push({
          name: f[1]!,
          branch: f[2]!,
          path: f[3]!,
          missingEnv: Number(f[4]) || 0,
          running: f[5] === "1",
        });
        break;
      case "slot":
        if (f.length < 10) break;
        data.slots.push({
          n: f[1]!,
          wtName: f[2]!,
          path: f[3]!,
          fe: f[4]!,
          be: f[5]!,
          api: f[6]!,
          site: f[7]!,
          state: (["down", "convex", "up"].includes(f[8]!) ? f[8] : "down") as SlotState,
          log: f[9]!,
        });
        break;
      case "snapshot":
        if (f.length < 4) break;
        data.snapshots.push({
          name: f[1]!,
          bytes: Number(f[2]) || 0,
          mtime: Number(f[3]) || 0,
        });
        break;
    }
  }
  return data;
}

// Ana worktree slot alamaz (wt bunu reddediyor: "ana worktree izole stack
// olamaz"), o yüzden listede duruyor ama Enter'ı ona harcamıyoruz.
export function isMainWorktree(wt: Worktree, data: Data): boolean {
  return data.worktrees.length > 0 && wt.path === data.worktrees[0]!.path;
}

export function slotOf(data: Data, wtName: string): Slot | undefined {
  return data.slots.find((s) => s.wtName === wtName);
}

// ---- tuşlar -----------------------------------------------------------------

export type Key = {
  name: string; // "up" | "down" | "enter" | "tab" | "escape" | tek karakter
  ctrl?: boolean;
  alt?: boolean;
  shift?: boolean;
};

// ---- seçim ------------------------------------------------------------------

export type Sel = { panel: Panel; index: number };

export function rowCount(data: Data, panel: Panel): number {
  if (panel === "worktree") return data.worktrees.length;
  if (panel === "slot") return data.slots.length;
  return data.snapshots.length;
}

// Boş panel focuslanmıyor: orada yapılacak bir şey yok ve imlecin görünmez bir
// yerde kaybolması "tuşlar çalışmıyor" hissi veriyor.
function livePanels(data: Data): Panel[] {
  return PANELS.filter((p) => rowCount(data, p) > 0);
}

// Bütün satırların tek düz listesi. Panel geçişinin ayrı bir tuşa ihtiyaç
// duymamasının sebebi bu: j/k bu liste üzerinde yürüyor, panel sınırını
// kendiliğinden geçiyor.
export function flatten(data: Data): Sel[] {
  const out: Sel[] = [];
  for (const panel of livePanels(data)) {
    for (let i = 0; i < rowCount(data, panel); i++) out.push({ panel, index: i });
  }
  return out;
}

function selIndex(flat: Sel[], sel: Sel): number {
  const i = flat.findIndex((s) => s.panel === sel.panel && s.index === sel.index);
  return i < 0 ? 0 : i;
}

function moveFlat(data: Data, sel: Sel, dir: 1 | -1): Sel {
  const flat = flatten(data);
  if (flat.length === 0) return sel;
  const next = selIndex(flat, sel) + dir;
  // Uçlarda duruyor, sarmalamıyor: listenin sonundan başına atlamak, üç panelli
  // bir görünümde nerede olduğunu kaybettiriyor.
  return flat[Math.max(0, Math.min(next, flat.length - 1))]!;
}

// tab: doğrudan bir sonraki dolu panelin ilk satırına. Bu sarmalıyor, çünkü
// "panel değiştir" niyeti tekrarlanabilir olmalı.
function jumpPanel(data: Data, sel: Sel, dir: 1 | -1): Sel {
  const live = livePanels(data);
  if (live.length === 0) return sel;
  const i = live.indexOf(sel.panel);
  const next = live[(Math.max(0, i) + dir + live.length) % live.length]!;
  return { panel: next, index: 0 };
}

export function clampSel(data: Data, sel: Sel): Sel {
  const rows = rowCount(data, sel.panel);
  if (rows === 0) {
    const live = livePanels(data);
    return live.length ? { panel: live[0]!, index: 0 } : sel;
  }
  return { panel: sel.panel, index: Math.min(sel.index, rows - 1) };
}

// ---- durum ------------------------------------------------------------------

export type Mode =
  | { kind: "list" }
  // Worktree'de Enter: snapshot seç. cursor 0 = "(boş)" yani sıfırdan slot.
  | { kind: "snapshotPick"; wtName: string; cursor: number }
  // Snapshot'ta Enter: hangi worktree'ye basılacak?
  | { kind: "restorePick"; snapName: string; cursor: number }
  // s: snapshot adı yaz. Doğrulama burada, wt'ye hatalı ad göndermeden.
  | { kind: "input"; wtName: string; slotN: string; value: string; error: string }
  | { kind: "confirm"; title: string; detail: string; argv: string[]; busyKey: string }
  | { kind: "help" };

export type State = {
  data: Data;
  sel: Sel;
  mode: Mode;
  message: string;
  // Süren işler: worktree adı → "başlatılıyor" gibi bir etiket. Buna ihtiyaç
  // var çünkü işler artık arka planda dönüyor ve başlatma dakikalar sürüyor:
  // o süre boyunca satır hâlâ "kapalı" görünür, ve işaretlemezsek Enter'a
  // tekrar basmak ikinci bir başlatma denemesi başlatır (wt de "slot zaten
  // çalışıyor" diye ölür). Meşgulken Enter yutuluyor.
  busy: Record<string, string>;
};

export type Cmd =
  | { kind: "none" }
  | { kind: "quit" }
  | { kind: "refresh" }
  // Hepsi arka planda çalışır; busyKey biten işi eşlemek için.
  | { kind: "exec"; argv: string[]; label: string; busyKey: string }
  // Tek istisna: env kurmak birkaç symlink, milisaniyelik iş. Arka plana atıp
  // bildirim beklemek yerine yerinde bitiyor ki rozet aynı karede kaybolsun.
  | { kind: "linkEnv"; wtName: string }
  | { kind: "open"; url: string };

const NONE: Cmd = { kind: "none" };

export function initialState(data: Data): State {
  return {
    data,
    sel: clampSel(data, { panel: "worktree", index: 0 }),
    mode: { kind: "list" },
    message: "",
    busy: {},
  };
}

export function busyLabel(state: State, wtName: string): string | undefined {
  return state.busy[wtName];
}

export function selectedWorktree(state: State): Worktree | undefined {
  return state.sel.panel === "worktree" ? state.data.worktrees[state.sel.index] : undefined;
}

export function selectedSlot(state: State): Slot | undefined {
  return state.sel.panel === "slot" ? state.data.slots[state.sel.index] : undefined;
}

export function selectedSnapshot(state: State): Snapshot | undefined {
  return state.sel.panel === "snapshot" ? state.data.snapshots[state.sel.index] : undefined;
}

// Seçili satırın ilgili olduğu slot: slot panelinde satırın kendisi, worktree
// panelinde o worktree'nin slotu. `s` ve `d` ikisinde de çalışsın diye.
function contextSlot(state: State): Slot | undefined {
  const slot = selectedSlot(state);
  if (slot) return slot;
  const wt = selectedWorktree(state);
  return wt ? slotOf(state.data, wt.name) : undefined;
}

// contextSlot'un tersi: slot satırı da bir worktree'yi temsil ediyor, ve `e`
// oradayken de çalışmalı — env eksikliği worktree'nin özelliği, slotun değil.
export function contextWorktree(state: State): Worktree | undefined {
  const wt = selectedWorktree(state);
  if (wt) return wt;
  const slot = selectedSlot(state);
  return slot ? state.data.worktrees.find((w) => w.name === slot.wtName) : undefined;
}

// wt'nin kabul ettiği ad kümesi (side_snapshot_path): harf, rakam, . _ - ve
// nokta ile başlamıyor. Burada doğrulamak, run pane'inin açılıp tek satırlık
// bir hatayla kapanmasından iyi.
export function validateSnapshotName(name: string): string {
  if (!name) return "ad boş olamaz";
  if (/[^A-Za-z0-9._-]/.test(name)) return "yalnızca harf, rakam, . _ - kullanılabilir";
  if (name.startsWith(".")) return "nokta ile başlayamaz";
  return "";
}

export function reduce(state: State, key: Key): { state: State; cmd: Cmd } {
  const keep = (s: Partial<State> = {}): { state: State; cmd: Cmd } => ({
    state: { ...state, ...s },
    cmd: NONE,
  });

  // ---- alt ekranlar önce: liste tuşları buraya sızmasın ----

  if (state.mode.kind === "help") return keep({ mode: { kind: "list" } });

  if (state.mode.kind === "input") {
    const m = state.mode;
    if (key.name === "escape") return keep({ mode: { kind: "list" }, message: "iptal edildi" });
    if (key.name === "backspace") {
      return keep({ mode: { ...m, value: m.value.slice(0, -1), error: "" } });
    }
    if (key.name === "enter") {
      const error = validateSnapshotName(m.value);
      if (error) return keep({ mode: { ...m, error } });
      return {
        state: { ...state, mode: { kind: "list" }, message: "" },
        cmd: {
          kind: "exec",
          argv: ["--snapshot", m.wtName, m.value],
          label: `slot ${m.slotN} → snapshot '${m.value}'`,
          busyKey: m.wtName,
        },
      };
    }
    // Yalnızca tek karakterli, modifier'sız tuşlar metne yazılır.
    if (key.name.length === 1 && !key.ctrl && !key.alt) {
      return keep({ mode: { ...m, value: m.value + key.name, error: "" } });
    }
    return keep();
  }

  if (state.mode.kind === "confirm") {
    const m = state.mode;
    if (key.name === "y" || key.name === "Y" || key.name === "enter") {
      return {
        state: { ...state, mode: { kind: "list" }, message: "" },
        cmd: { kind: "exec", argv: m.argv, label: m.title, busyKey: m.busyKey },
      };
    }
    if (key.name === "n" || key.name === "N" || key.name === "escape" || key.name === "q") {
      return keep({ mode: { kind: "list" }, message: "iptal edildi" });
    }
    return keep();
  }

  if (state.mode.kind === "snapshotPick") {
    const m = state.mode;
    const max = state.data.snapshots.length + 1; // 0 = "(boş)"
    if (key.name === "escape" || key.name === "q") {
      return keep({ mode: { kind: "list" }, message: "iptal edildi" });
    }
    if (key.name === "j" || key.name === "down") {
      return keep({ mode: { ...m, cursor: Math.min(m.cursor + 1, max - 1) } });
    }
    if (key.name === "k" || key.name === "up") {
      return keep({ mode: { ...m, cursor: Math.max(m.cursor - 1, 0) } });
    }
    if (key.name === "enter") {
      const snap = m.cursor === 0 ? undefined : state.data.snapshots[m.cursor - 1]?.name;
      return {
        state: { ...state, mode: { kind: "list" }, message: "" },
        cmd: {
          kind: "exec",
          argv: snap ? [m.wtName, snap] : [m.wtName],
          label: snap ? `${m.wtName} ← ${snap}` : `${m.wtName} (sıfırdan)`,
          busyKey: m.wtName,
        },
      };
    }
    return keep();
  }

  if (state.mode.kind === "restorePick") {
    const m = state.mode;
    const targets = restoreTargets(state.data);
    if (key.name === "escape" || key.name === "q") {
      return keep({ mode: { kind: "list" }, message: "iptal edildi" });
    }
    if (key.name === "j" || key.name === "down") {
      return keep({ mode: { ...m, cursor: Math.min(m.cursor + 1, Math.max(0, targets.length - 1)) } });
    }
    if (key.name === "k" || key.name === "up") {
      return keep({ mode: { ...m, cursor: Math.max(m.cursor - 1, 0) } });
    }
    if (key.name === "enter") {
      const target = targets[m.cursor];
      if (!target) return keep({ mode: { kind: "list" }, message: "hedef worktree yok" });
      // Yıkıcı: hedef slotun volume'ü silinip yerine bu snapshot açılıyor.
      // wt'nin kendi onayı run pane'inde de çalışır ama neyin gittiğini burada
      // da söylüyoruz — oraya varmadan vazgeçebilmek lazım.
      return keep({
        mode: {
          kind: "confirm",
          title: `${target.name} ← '${m.snapName}'`,
          detail:
            `${target.name} slotundaki mevcut veritabanı SİLİNİP yerine\n` +
            `'${m.snapName}' snapshot'ı açılacak.`,
          argv: ["--restore", target.name, m.snapName],
          busyKey: target.name,
        },
      });
    }
    return keep();
  }

  // ---- ana liste ----

  if (key.name === "q" || key.name === "escape") return { state, cmd: { kind: "quit" } };
  if (key.name === "r" && !key.ctrl) return { state, cmd: { kind: "refresh" } };
  if (key.name === "?") return keep({ mode: { kind: "help" } });

  if (key.name === "tab") {
    return keep({ sel: jumpPanel(state.data, state.sel, key.shift ? -1 : 1), message: "" });
  }
  // Panel atlama için ek tuşlar. ctrl+j/ctrl+k kullanıcının config'inde global
  // focus_pane_down/up olduğu için Herdr bunları genelde yutuyor; burada
  // durmalarının maliyeti yok, geçerlerse çalışırlar.
  if ((key.ctrl && key.alt && key.name === "down") || (key.ctrl && key.name === "j")) {
    return keep({ sel: jumpPanel(state.data, state.sel, 1), message: "" });
  }
  if ((key.ctrl && key.alt && key.name === "up") || (key.ctrl && key.name === "k")) {
    return keep({ sel: jumpPanel(state.data, state.sel, -1), message: "" });
  }

  if (!key.ctrl && !key.alt && (key.name === "j" || key.name === "down")) {
    return keep({ sel: moveFlat(state.data, state.sel, 1) });
  }
  if (!key.ctrl && !key.alt && (key.name === "k" || key.name === "up")) {
    return keep({ sel: moveFlat(state.data, state.sel, -1) });
  }

  if (key.name === "enter") return onEnter(state);
  if (key.name === "d") return onDrop(state);
  if (key.name === "e") return onLinkEnv(state);
  if (key.name === "s") return onSnapshot(state);
  if (key.name === "w") return onOpenWeb(state);

  return keep();
}

function stopCmd(state: State, slot: Slot): { state: State; cmd: Cmd } {
  return {
    state: { ...state, message: "" },
    cmd: {
      kind: "exec",
      argv: ["--stop", slot.wtName],
      label: `slot ${slot.n} durduruluyor`,
      busyKey: slot.wtName,
    },
  };
}

// `w`: ayaktaki slotun frontend'ini tarayıcıda aç. Sadece "up" için anlamlı —
// container ayakta ama stack kapalıyken (convex) o portu kimse dinlemiyor ve
// tarayıcı bağlantı hatası gösterirdi.
function onOpenWeb(state: State): { state: State; cmd: Cmd } {
  const msg = (message: string) => ({ state: { ...state, message }, cmd: NONE });
  if (state.sel.panel === "snapshot") return msg("snapshot'ın adresi yok");

  const slot =
    selectedSlot(state) ??
    (selectedWorktree(state) ? slotOf(state.data, selectedWorktree(state)!.name) : undefined);
  if (!slot) return msg("bu satırın slotu yok");
  if (slot.state !== "up") return msg(`slot ${slot.n} ayakta değil — önce Enter ile başlat`);
  return {
    state: { ...state, message: `açılıyor → http://localhost:${slot.fe}` },
    cmd: { kind: "open", url: `http://localhost:${slot.fe}` },
  };
}

// Snapshot hangi worktree'ye basılabilir: ana worktree hariç hepsi. Slotu
// olmayan da geçerli — wt --restore o worktree'ye bir slot atar.
export function restoreTargets(data: Data): Worktree[] {
  return data.worktrees.filter((wt) => !isMainWorktree(wt, data));
}

function onEnter(state: State): { state: State; cmd: Cmd } {
  const msg = (message: string) => ({ state: { ...state, message }, cmd: NONE });

  if (state.sel.panel === "worktree") {
    const wt = selectedWorktree(state);
    if (!wt) return msg("");
    const running = busyLabel(state, wt.name);
    if (running) return msg(`${wt.name}: ${running} — bitmesini bekle`);
    if (isMainWorktree(wt, state.data)) {
      return msg("ana worktree slot alamaz — o normal stack'i çalıştırıyor");
    }
    // Enter'ın burada env'i kendiliğinden kurmaması bilinçli: Enter "başlat"
    // demek ve başlatma dakikalar sürüyor, oysa env kurmak anlık ve ayrı bir
    // karar. Yapılacak tek şeyi söylemek yeter — `e` hemen yanı başında.
    if (wt.missingEnv > 0) {
      return msg(`${wt.name}: ${wt.missingEnv} env dosyası eksik — e ile kur`);
    }
    const slot = slotOf(state.data, wt.name);
    // Worktree'de de toggle: ayakta olanı Enter durdurur. Aksi hâlde tek yaptığı
    // "zaten ayakta" demek olurdu, ve durdurmak için slot paneline inmek
    // gerekirdi.
    if (slot?.state === "up") return stopCmd(state, slot);
    return {
      state: { ...state, mode: { kind: "snapshotPick", wtName: wt.name, cursor: 0 }, message: "" },
      cmd: NONE,
    };
  }

  if (state.sel.panel === "slot") {
    const slot = selectedSlot(state);
    if (!slot) return msg("");
    const running = busyLabel(state, slot.wtName);
    if (running) return msg(`slot ${slot.n}: ${running} — bitmesini bekle`);
    // Toggle: ayaktaysa durdur, değilse başlat. "convex" durumu da başlatma
    // tarafına düşüyor — container ayakta ama stack kapalı demek, ve wt zaten
    // container'ı yeniden kullanıyor.
    if (slot.state === "up") return stopCmd(state, slot);
    return {
      state: { ...state, message: "" },
      cmd: {
        kind: "exec",
        argv: [slot.wtName],
        label: `slot ${slot.n} başlatılıyor`,
        busyKey: slot.wtName,
      },
    };
  }

  const snap = selectedSnapshot(state);
  if (!snap) return msg("");
  if (restoreTargets(state.data).length === 0) return msg("geri yüklenecek worktree yok");
  return {
    state: {
      ...state,
      mode: { kind: "restorePick", snapName: snap.name, cursor: 0 },
      message: "",
    },
    cmd: NONE,
  };
}

// `e`: eksik env dosyalarını ana worktree'den symlink'le. Bir worktree env'siz
// hiçbir şey yapamaz — slot da alamaz, `bun run dev` de çalışmaz — ve buradan
// önce tek çıkış yolu menüyü kapatıp elle `wt <worktree>` demekti.
//
// Env'i tam olan satırda da bilerek bir cevap veriyoruz: sessiz kalmak "tuş
// çalışmadı mı?" sorusunu doğuruyor, oysa yapılacak iş yok demek.
function onLinkEnv(state: State): { state: State; cmd: Cmd } {
  const msg = (message: string) => ({ state: { ...state, message }, cmd: NONE });
  if (state.sel.panel === "snapshot") return msg("env kurmak için worktree seç");

  const wt = contextWorktree(state);
  if (!wt) return msg("bu satırın worktree'si yok");
  const running = busyLabel(state, wt.name);
  if (running) return msg(`${wt.name}: ${running} — bitmesini bekle`);
  if (wt.missingEnv === 0) return msg(`${wt.name}: env zaten tam`);
  return { state: { ...state, message: "" }, cmd: { kind: "linkEnv", wtName: wt.name } };
}

function onSnapshot(state: State): { state: State; cmd: Cmd } {
  if (state.sel.panel === "snapshot") {
    return { state: { ...state, message: "snapshot almak için slot veya worktree seç" }, cmd: NONE };
  }
  const slot = contextSlot(state);
  if (!slot) {
    return { state: { ...state, message: "bu worktree'nin slotu yok — önce Enter ile kur" }, cmd: NONE };
  }
  return {
    state: {
      ...state,
      mode: { kind: "input", wtName: slot.wtName, slotN: slot.n, value: "", error: "" },
      message: "",
    },
    cmd: NONE,
  };
}

function onDrop(state: State): { state: State; cmd: Cmd } {
  if (state.sel.panel === "snapshot") {
    const snap = selectedSnapshot(state);
    if (!snap) return { state, cmd: NONE };
    return {
      state: {
        ...state,
        mode: {
          kind: "confirm",
          title: `snapshot '${snap.name}' siliniyor`,
          detail: `${humanBytes(snap.bytes)} — geri dönüşü yok.`,
          argv: ["--drop-snapshot", snap.name],
          busyKey: `snapshot:${snap.name}`,
        },
      },
      cmd: NONE,
    };
  }

  const slot = contextSlot(state);
  if (!slot) {
    return { state: { ...state, message: "silinecek slot yok" }, cmd: NONE };
  }
  return {
    state: {
      ...state,
      mode: {
        kind: "confirm",
        title: `slot ${slot.n} siliniyor`,
        // Neyin gittiğini ve neyin kaldığını yazmak önemli: --drop-slot adı
        // worktree'yi silecekmiş gibi duruyor, silmiyor.
        detail:
          `${slot.wtName} — veritabanı ve container gider, snapshot'lar kalır.\n` +
          `git worktree'sine ve koda DOKUNULMAZ.`,
        argv: ["--drop-slot", slot.wtName],
        busyKey: slot.wtName,
      },
    },
    cmd: NONE,
  };
}

// ---- biçimlendirme ----------------------------------------------------------

// `du -h` ile aynı okunuşu vermek için: 10'un altında bir ondalık, üstünde
// yuvarlak. Aksi hâlde snapshot paneli "8M" derken `wt`'nin insan görünümü
// "7.7M" der ve aynı dosya iki farklı boyutta görünür.
export function humanBytes(n: number): string {
  const unit = (v: number, u: string) => `${v < 10 ? v.toFixed(1) : Math.round(v)}${u}`;
  if (n >= 1024 ** 3) return unit(n / 1024 ** 3, "G");
  if (n >= 1024 ** 2) return unit(n / 1024 ** 2, "M");
  if (n >= 1024) return unit(n / 1024, "K");
  return `${n}B`;
}

export function formatDate(epochSeconds: number): string {
  const d = new Date(epochSeconds * 1000);
  const p = (v: number) => String(v).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

export function slotStateLabel(s: SlotState): string {
  if (s === "up") return "ayakta";
  if (s === "convex") return "Convex açık";
  return "kapalı";
}
