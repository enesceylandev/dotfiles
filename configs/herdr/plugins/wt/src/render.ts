// Durum → ekran satırları. Saf: string[] döner, hiçbir şey yazdırmaz.
//
// Tasarım kararları:
//   · Onay/seçim ekranları tam ekran DEĞİL, listenin üstünde duran bir kutu.
//     Tam ekran çizmek "başka bir ekrana geçtim" hissi veriyordu; oysa d'ye
//     basmak listede kalıp bir soru sormak olmalı.
//   · İki alan: solda kimlik (ad), sağda üstveri. Sağdaki alan SOLA YASLI
//     sabit kolonlar — rozetler, adresler ve tarihler alt alta hizalansın.
//     Popup genişliği de bu içeriğe göre seçildi, yoksa sağda boşluk kalır.
//   · Üst başlık satırı yok ve alt bar çerçevenin dibine sabit — içerikle dış
//     çerçeve arasında ölü alan kalmasın. Paneller arasındaki tek boş satır
//     BİLEREK duruyor, okunurluğu o taşıyor.
//   · Seçili satır tam genişlik bir bant; kolon genişlikleri veriden hesaplanır.
//   · Satırlar GÖRÜNÜR genişliğe göre kesilir; sarmalanmaya bırakılsa tek uzun
//     branch adı bütün düzeni kaydırırdı.

import {
  busyLabel,
  contextWorktree,
  formatDate,
  humanBytes,
  isMainWorktree,
  restoreTargets,
  slotOf,
  slotStateLabel,
  type Panel,
  type State,
} from "./model.ts";

// Palet: Catppuccin Mocha — herdr'ın varsayılan teması bu, yani menü herdr'ın
// kendi yüzeyleriyle aynı dünyada duruyor. Truecolor, çünkü 16-renk paleti
// terminal temasına göre kayıyor.
const BG = "\x1b[48;2;24;24;37m"; // mantle   #181825 — panel zemini
const SEL_BG = "\x1b[48;2;49;50;68m"; // surface0 #313244 — seçim bandı
const BOX_BG = "\x1b[48;2;30;30;46m"; // base     #1e1e2e — kutu zemini
const FG = "\x1b[38;2;205;214;244m"; // text     #cdd6f4

// "Reset" burada tam sıfırlama DEĞİL: zemini ve temel metin rengini geri koyar.
// Tam sıfırlama olsaydı her ${R}'den sonra arka plan terminalin varsayılanına
// düşer ve satırın kalanı boyanmamış kalırdı.
const R = `\x1b[0m${BG}${FG}`;
const RB = `\x1b[0m${BOX_BG}${FG}`; // kutunun içindeki reset
const B = "\x1b[1m";
const DIM = "\x1b[38;2;127;132;156m"; // overlay1 #7f849c
const CYAN = "\x1b[38;2;137;180;250m"; // blue    #89b4fa — vurgu
const GREEN = "\x1b[38;2;166;227;161m"; // green  #a6e3a1
const YELLOW = "\x1b[38;2;249;226;175m"; // yellow #f9e2af
const RED = "\x1b[38;2;243;139;168m"; // red      #f38ba8

export const SCREEN_INIT = `${BG}${FG}`;

const TITLES: Record<Panel, string> = {
  worktree: "worktree",
  slot: "slot",
  snapshot: "snapshot",
};

function visLen(s: string): number {
  return s.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").length;
}

function cut(s: string, w: number): string {
  return s.length > w ? s.slice(0, Math.max(0, w - 1)) + "…" : s;
}

// Renkli bir satırı GÖRÜNÜR uzunluğa göre keser. Baytla kesmek kaçış dizisinin
// ortasında durup terminale yarım komut gönderir.
function cutVis(s: string, w: number, reset = R): string {
  if (visLen(s) <= w) return s;
  const limit = Math.max(0, w - 1);
  let out = "";
  let vis = 0;
  let i = 0;
  while (i < s.length && vis < limit) {
    if (s[i] === "\x1b") {
      const m = /^\x1b\[[0-9;?]*[A-Za-z]/.exec(s.slice(i));
      if (m) {
        out += m[0];
        i += m[0].length;
        continue;
      }
    }
    out += s[i];
    vis++;
    i++;
  }
  return out + "…" + reset;
}

function padTo(s: string, w: number): string {
  const gap = w - visLen(s);
  return gap > 0 ? s + " ".repeat(gap) : s;
}

function maxLen(values: string[], min: number, max: number): number {
  return Math.min(max, Math.max(min, ...values.map((v) => v.length)));
}

// Seçili satır: tam genişlik bant. İçerideki ${R}'ler zemini mantle'a geri
// döndüreceği için bandın ortasında delik açardı — kesme yapıldıktan SONRA
// satırdaki tüm zemin kodlarını bant rengiyle değiştiriyoruz.
function bandRow(line: string, width: number, selected: boolean): string {
  const clipped = cutVis(line, width);
  if (!selected) return clipped;
  return SEL_BG + padTo(clipped.split(BG).join(SEL_BG), width) + R;
}

function panelHeader(panel: Panel, count: number, active: boolean, width: number): string {
  const label = active
    ? `${B}${CYAN}${TITLES[panel]}${R} ${DIM}(${count})${R}`
    : `${DIM}${TITLES[panel]} (${count})${R}`;
  const head = `${active ? CYAN : DIM}──${R} ${label} `;
  const rest = Math.max(0, width - visLen(head));
  return head + `${active ? CYAN : DIM}${"─".repeat(rest)}${R}`;
}

function cursor(selected: boolean): string {
  return selected ? `${CYAN}▌${R} ` : "  ";
}

function stateGlyph(state: "down" | "convex" | "up"): string {
  return state === "up" ? `${GREEN}●${R}` : state === "convex" ? `${YELLOW}◐${R}` : `${DIM}○${R}`;
}

export function render(state: State, width: number, height: number, _repo = ""): string[] {
  if (state.mode.kind === "help") return renderHelp(width, height);
  const base = renderList(state, width, height);
  const box = boxFor(state, width);
  return box ? overlay(base, box, width, height) : base;
}

// ---- liste ------------------------------------------------------------------

function renderList(state: State, width: number, height: number): string[] {
  const { data, sel } = state;
  const body: string[] = [];

  // Sağ alan üç panelde de AYNI kolondan başlıyor. Her panel kendi ad
  // genişliğine göre hizalanınca snapshot satırı (adları kısa) çok erken
  // başlıyor ve üstveri sağ alanda değil, ortada duruyormuş gibi görünüyordu.
  // En geniş önek slot satırınınki: imleç(2) + glif(1) + boşluk(1) + no(1) +
  // iki boşluk(2) = 7.
  const nameW = maxLen(
    [
      ...data.worktrees.map((w) => w.name),
      ...data.slots.map((s) => s.wtName),
      ...data.snapshots.map((s) => s.name),
    ],
    12,
    30,
  );
  // Her panelin sağ bloğu KENDİ genişliğiyle sağ kenara dayanıyor. Tek bir
  // ortak blok genişliği kullanmak iki yönden de bozuyordu: dar paneller
  // (snapshot) sağa ulaşamıyor, geniş panel (slot) dar ekranda taşıp
  // "Convex açık"ı yarıda kesiyordu.
  //
  // Blok içindeki kolonlar yine sola yaslı, yani rozetler/adresler/tarihler
  // kendi aralarında hizalı kalıyor.
  const minLeft = 7 + nameW + 2; // imleç+glif+no önekleri + ad
  const avail = Math.max(20, width - minLeft);

  // Esneyen kolon branch: dar ekranda önce o kısalıyor, rozet değil.
  // Branch'i sabit bir sayıda kırpmak (34) uzun adlarda "…" bırakıyordu; sınır
  // artık ekranda kalan gerçek yer.
  const wtBranchW = Math.min(maxLen(data.worktrees.map((w) => w.branch), 12, 80), avail - 13);
  // Portlar bilgi yoğun ama vazgeçilebilir; sığmazsa adres ve durum kalıyor.
  const showPorts = avail >= 18 + 20;
  const slBlockW = 18 + (showPorts ? 20 : 0);
  const snBlockW = 10 + 16;

  const at = (blockW: number) => Math.max(minLeft, width - blockW);
  const wtRight = at(13 + wtBranchW);
  const slRight = at(slBlockW);
  const snRight = at(snBlockW);
  // Worktree panelinin kendi başlığı YOK: pane'in çerçeve başlığı zaten
  // "worktree" diyor ve ikisi üst üste gelince aynı kelime iki kez okunuyordu.
  // (Çerçeve başlığı boş bırakılamıyor — herdr "pane title is required" diyor.)
  // Hangi panelde olduğun ▌ imlecinden belli; slot/snapshot başlıkları sönükse
  // seçim buradadır.
  if (data.worktrees.length === 0) body.push(`  ${DIM}worktree yok${R}`);
  data.worktrees.forEach((wt, i) => {
    const selected = sel.panel === "worktree" && sel.index === i;
    const slot = slotOf(data, wt.name);
    const busy = busyLabel(state, wt.name);
    const glyph = busy
      ? `${CYAN}◌${R}`
      : wt.running
        ? `${GREEN}●${R}`
        : slot
          ? stateGlyph(slot.state)
          : `${DIM}·${R}`;
    const name = selected ? `${B}${cut(wt.name, nameW)}${R}` : cut(wt.name, nameW);

    // Meşgul etiketi YAZILMIYOR — ◌ ikonu zaten söylüyor, rozet kolonu da
    // kalıcı bilgisini (ana / slot N / env eksik) korusun.
    let badge = "";
    if (wt.missingEnv > 0) badge = `${YELLOW}${wt.missingEnv} env eksik${R}`;
    else if (isMainWorktree(wt, data)) badge = `${DIM}ana${R}`;
    else if (slot) badge = `${DIM}slot ${slot.n}${R}`;

    body.push(
      bandRow(
        padTo(cursor(selected) + glyph + " " + name, wtRight) +
          padTo(badge, 13) +
          `${DIM}${cut(wt.branch, wtBranchW)}${R}`,
        width,
        selected,
      ),
    );
  });

  body.push("");
  body.push(panelHeader("slot", data.slots.length, sel.panel === "slot", width));
  if (data.slots.length === 0) body.push(`  ${DIM}yok — bir worktree seçip Enter'a bas${R}`);
  data.slots.forEach((s, i) => {
    const selected = sel.panel === "slot" && sel.index === i;
    const busy = busyLabel(state, s.wtName);
    // Durum yazısı yok; ayrımı kontrast taşıyor. Ayakta olmayan satır komple
    // sönük, ayakta olanın adı normal parlaklıkta ve adresi camgöbeği.
    const live = s.state === "up";
    const plain = cut(s.wtName, nameW);
    const name = selected ? `${B}${plain}${R}` : live ? plain : `${DIM}${plain}${R}`;
    // Frontend adresi tam URL: kopyalanacak ya da tıklanacak olan şey bu.
    const url = s.state === "up" ? `${CYAN}localhost:${s.fe}${R}` : `${DIM}localhost:${s.fe}${R}`;
    body.push(
      bandRow(
        padTo(
          cursor(selected) + (busy ? `${CYAN}◌${R}` : stateGlyph(s.state)) + ` ${DIM}${s.n}${R}  ` + name,
          slRight,
        ) +
          padTo(url, 18) +
          (showPorts ? `${DIM}be ${s.be} · cx ${s.api}${R}` : ""),
        width,
        selected,
      ),
    );
  });

  body.push("");
  body.push(panelHeader("snapshot", data.snapshots.length, sel.panel === "snapshot", width));
  if (data.snapshots.length === 0) body.push(`  ${DIM}yok — bir slot seçip s'ye bas${R}`);
  data.snapshots.forEach((s, i) => {
    const selected = sel.panel === "snapshot" && sel.index === i;
    const busy = busyLabel(state, `snapshot:${s.name}`);
    const name = selected ? `${B}${cut(s.name, nameW)}${R}` : cut(s.name, nameW);
    body.push(
      bandRow(
        padTo(cursor(selected) + name, snRight) +
          // Meşgulken boyutun yerine ◌: ayrı bir metin eklemek satırı kaydırıp
          // tarihi sağ kenardan koparıyordu.
          padTo(busy ? `${CYAN}◌${R}` : `${DIM}${humanBytes(s.bytes).padStart(6)}${R}`, 10) +
          `${DIM}${formatDate(s.mtime)}${R}`,
        width,
        selected,
      ),
    );
  });

  // Alt bar son satırın hemen altında; mesaj yalnızca varken yer kaplıyor.
  const tail: string[] = [];
  if (state.message) tail.push(`  ${YELLOW}${cut(state.message, width - 4)}${R}`);
  tail.push(cutVis(`  ${footerFor(state)}`, width));

  // Yer yetmezse listeden kırpıyoruz, alt bardan değil: hangi tuşun ne yaptığı
  // her zaman görünür kalmalı.
  // Alt bar çerçevenin dibinde: içerikle dış çerçeve arasında ölü alan
  // bırakmamanın yolu bu. Yer yetmezse listeden kırpılıyor, alt bardan değil —
  // hangi tuşun ne yaptığı her zaman görünür kalmalı.
  const room = Math.max(1, height - tail.length);
  const shown =
    body.length <= room
      ? [...body, ...Array(room - body.length).fill("")]
      : [...body.slice(0, room - 1), `  ${DIM}… ${body.length - room + 1} satır daha${R}`];
  return [...shown, ...tail];
}

function footerFor(state: State): string {
  // Tuşlar vurgu renginde: alt barda gözün ilk yakalaması gereken şey hangi
  // tuşa basılacağı, ne yaptığı değil.
  const key = (k: string, what: string) => `${CYAN}${k}${R}${DIM} ${what}${R}`;
  const parts = [key("j/k", "gez"), key("tab", "panel")];

  if (state.sel.panel === "snapshot") {
    parts.push(key("enter", "geri yükle"), key("d", "sil"));
  } else {
    const wt = contextWorktree(state);
    const slot =
      state.sel.panel === "slot"
        ? state.data.slots[state.sel.index]
        : slotOf(state.data, state.data.worktrees[state.sel.index]?.name ?? "");
    // Env eksikken yapılacak İLK iş bu, o yüzden enter'ın da önünde: env
    // gelmeden başlatmanın anlamı yok ve enter zaten reddedecek.
    if (wt && wt.missingEnv > 0) parts.push(key("e", "env kur"));
    parts.push(key("enter", slot?.state === "up" ? "durdur" : "başlat"));
    if (slot?.state === "up") parts.push(key("w", "aç"));
    if (slot) parts.push(key("s", "snapshot"), key("d", "sil"));
  }

  parts.push(key("r", "yenile"), key("q", "çık"));
  return parts.join(`${DIM} · ${R}`);
}

// ---- kutular ----------------------------------------------------------------

type Box = { title: string; lines: string[]; hint: string; danger?: boolean };

function boxFor(state: State, width: number): string[] | null {
  const m = state.mode;
  if (m.kind === "list") return null;
  const inner = Math.max(24, Math.min(width - 10, 64));

  if (m.kind === "confirm") {
    return drawBox(
      {
        title: m.title,
        lines: [...m.detail.split("\n"), "", `${DIM}wt ${m.argv.join(" ")}${RB}`],
        hint: `${CYAN}y${RB}${DIM} sil${RB}    ${CYAN}n${RB}${DIM} vazgeç${RB}`,
        danger: true,
      },
      inner,
    );
  }

  if (m.kind === "input") {
    return drawBox(
      {
        title: `slot ${m.slotN} — snapshot al`,
        lines: [
          `${CYAN}▌${RB} ${B}${m.value}${RB}${CYAN}▁${RB}`,
          m.error ? `${RED}${m.error}${RB}` : `${DIM}harf, rakam, . _ -${RB}`,
        ],
        hint: `${CYAN}enter${RB}${DIM} al${RB}    ${CYAN}esc${RB}${DIM} vazgeç${RB}`,
      },
      inner,
    );
  }

  if (m.kind === "snapshotPick") {
    const rows = [`${DIM}(boş)${RB}  sıfırdan slot`];
    for (const s of state.data.snapshots) {
      rows.push(padTo(cut(s.name, 24), 26) + `${DIM}${humanBytes(s.bytes).padStart(6)}${RB}`);
    }
    return drawBox(
      {
        title: `${m.wtName} — başlat`,
        lines: rows.map((row, i) => pickRow(row, i === m.cursor)),
        hint: `${CYAN}j/k${RB}${DIM} seç${RB}   ${CYAN}enter${RB}${DIM} başlat${RB}   ${CYAN}esc${RB}${DIM} vazgeç${RB}`,
      },
      inner,
    );
  }

  const targets = restoreTargets(state.data);
  return drawBox(
    {
      title: `'${m.snapName}' geri yükle`,
      lines: [
        `${RED}Hedef slottaki veritabanı silinir.${RB}`,
        "",
        ...targets.map((t, i) => {
          const slot = slotOf(state.data, t.name);
          const row = padTo(cut(t.name, 26), 28) + `${DIM}${slot ? `slot ${slot.n}` : "slotu yok"}${RB}`;
          return pickRow(row, i === m.cursor);
        }),
      ],
      hint: `${CYAN}j/k${RB}${DIM} seç${RB}   ${CYAN}enter${RB}${DIM} devam${RB}   ${CYAN}esc${RB}${DIM} vazgeç${RB}`,
    },
    inner,
  );
}

function pickRow(row: string, selected: boolean): string {
  return selected ? `${CYAN}▌${RB} ${B}${row}${RB}` : `  ${row}`;
}

function drawBox(box: Box, inner: number): string[] {
  const edge = box.danger ? RED : CYAN;
  const row = (s: string) =>
    `${BOX_BG}${edge}│${RB} ${padTo(cutVis(s, inner, RB), inner)} ${BOX_BG}${edge}│${R}`;
  return [
    `${BOX_BG}${edge}╭${"─".repeat(inner + 2)}╮${R}`,
    row(`${B}${box.title}${RB}`),
    row(""),
    ...box.lines.map(row),
    row(""),
    row(box.hint),
    `${BOX_BG}${edge}╰${"─".repeat(inner + 2)}╯${R}`,
  ];
}

// Kutuyu listenin ÜSTÜNE koyar: liste yerinde kalıyor, kutu ortada duruyor.
// "Başka bir ekran" değil, listenin üstünde sorulmuş bir soru gibi okunuyor.
function overlay(base: string[], box: string[], width: number, height: number): string[] {
  const out = [...base];
  while (out.length < Math.min(height, box.length + 2)) out.push("");
  const start = Math.max(
    0,
    Math.min(Math.floor((out.length - box.length) / 2), Math.max(0, out.length - box.length)),
  );
  const left = Math.max(0, Math.floor((width - visLen(box[0]!)) / 2));
  const indent = " ".repeat(left);
  for (let i = 0; i < box.length; i++) {
    if (start + i >= out.length) break;
    out[start + i] = cutVis(`${R}${indent}${box[i]}`, width);
  }
  return out.slice(0, height);
}

// ---- yardım -----------------------------------------------------------------

function renderHelp(width: number, height: number): string[] {
  const k = (s: string) => `${CYAN}${s}${R}`;
  return [
    `  ${B}wt — yardım${R}`,
    "",
    `  ${k("j/k")} ${DIM}veya ok tuşları — panel sınırını kendiliğinden geçer${R}`,
    `  ${k("tab")} ${DIM}bir sonraki panele atla${R}`,
    "",
    `  ${k("enter")} ${DIM}worktree/slot: kapalıysa başlat, ayaktaysa durdur${R}`,
    `        ${DIM}snapshot: bir worktree'nin slotuna geri yükle${R}`,
    `  ${k("e")}     ${DIM}eksik env dosyalarını ana worktree'den bağla${R}`,
    `  ${k("w")}     ${DIM}ayaktaki slotun adresini tarayıcıda aç${R}`,
    `  ${k("s")}     ${DIM}slottan snapshot al${R}`,
    `  ${k("d")}     ${DIM}slotu ya da snapshot'ı sil (onay sorar)${R}`,
    `  ${k("r")}     ${DIM}tazele${R}      ${k("q")} ${DIM}çık${R}`,
    "",
    `  ${DIM}Bütün işler arka planda çalışır, terminal açılmaz. Süren iş ◌ ile${R}`,
    `  ${DIM}işaretlenir; menüyü kapatsan da iş devam eder, bitince bildirim gelir.${R}`,
    "",
    `  ${DIM}herhangi bir tuş — geri dön${R}`,
  ]
    .map((l) => cutVis(l, width))
    .slice(0, height);
}
