// Popup içinde çalışan TUI. Tek IO noktası: raw stdin, çizim, süreç çalıştırma.
// Karar mantığı model.ts'te, çizim render.ts'te — ikisi de saf.

import { spawn as nodeSpawn } from "node:child_process";
import { basename, dirname, join } from "node:path";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import {
  clampSel,
  initialState,
  parsePorcelain,
  reduce,
  type Cmd,
  type Key,
  type State,
} from "./model.ts";
import { render, SCREEN_INIT } from "./render.ts";

// Herdr binary'sinin yolunu kendisi veriyor; PATH'e güvenmek gereksiz varsayım
// (kullanıcının worktree-swap.sh'i de aynı şeyi HERDR_BIN ile yapıyor).
const HERDR = process.env.HERDR_BIN_PATH || "herdr";

const STATE_DIR = process.env.HERDR_PLUGIN_STATE_DIR || join(process.env.HOME ?? ".", ".config/herdr");
const RUN_LOG = join(STATE_DIR, "wt-run.log");

// ---- repo keşfi -------------------------------------------------------------
//
// Plugin, wt-dev.sh'in nerede olduğunu bilmek zorunda. Üç kaynak, bu sırayla:
//   1. WT_REPO env'i — elle denemenin en kolay yolu.
//   2. HERDR_PLUGIN_CONTEXT_JSON — Herdr'ın verdiği çağrı bağlamı.
//   3. plugin config dizinindeki `repo` dosyası — kullanıcının sabitlemesi.
//
// Aday bir dizin bulunduğunda git'in COMMON dir'ine çıkıyoruz: bir worktree'den
// çağrıldığında bile ana checkout'a, yani script'in ve env dosyalarının
// kaynağına ulaşmak gerekiyor. wt-dev.sh kendi ROOT'unu tam olarak böyle bulur.
async function resolveRepo(): Promise<string> {
  const candidates: string[] = [];

  if (process.env.WT_REPO) candidates.push(process.env.WT_REPO);

  const ctx = process.env.HERDR_PLUGIN_CONTEXT_JSON;
  if (ctx) {
    try {
      const parsed = JSON.parse(ctx) as Record<string, any>;
      // Gerçek anahtar adları — 0.8.0'ın bir çağrısından alındı, tahmin değil:
      //   worktree: { repo_root, checkout_path, ... }, workspace_cwd,
      //   focused_pane_cwd. repo_root en doğrusu: bağlı bir worktree'den
      //   çağrılsa bile ANA checkout'u veriyor.
      const wt = parsed.worktree;
      if (wt && typeof wt === "object") {
        for (const key of ["repo_root", "checkout_path"]) {
          if (typeof wt[key] === "string") candidates.push(wt[key]);
        }
      }
      for (const key of ["workspace_cwd", "focused_pane_cwd", "cwd"]) {
        if (typeof parsed[key] === "string") candidates.push(parsed[key]);
      }
    } catch {
      // Bozuk JSON bir hata değil, sadece bu kaynağın yokluğu.
    }
  }

  const cfgDir = process.env.HERDR_PLUGIN_CONFIG_DIR;
  if (cfgDir) {
    const f = join(cfgDir, "repo");
    if (existsSync(f)) candidates.push((await Bun.file(f).text()).trim());
  }

  candidates.push(process.cwd());

  for (const c of candidates) {
    if (!c) continue;
    const root = await gitCommonRoot(c);
    if (root && existsSync(join(root, "scripts/wt-dev.sh"))) return root;
  }

  throw new Error(
    "wt-dev.sh bulunamadı. Repo yolunu sabitlemek için:\n" +
      `  echo /path/to/boemar-hr > ${cfgDir ?? "<plugin-config-dir>"}/repo`,
  );
}

async function gitCommonRoot(dir: string): Promise<string | null> {
  if (!existsSync(dir)) return null;
  const p = Bun.spawn(
    ["git", "-C", dir, "rev-parse", "--path-format=absolute", "--git-common-dir"],
    { stdout: "pipe", stderr: "ignore" },
  );
  const out = (await new Response(p.stdout).text()).trim();
  if ((await p.exited) !== 0 || !out) return null;
  return dirname(out);
}

// ---- veri -------------------------------------------------------------------

function wtScript(repo: string): string {
  return join(repo, "scripts/wt-dev.sh");
}

async function loadData(repo: string) {
  const p = Bun.spawn(["bash", wtScript(repo), "--porcelain"], {
    stdout: "pipe",
    stderr: "pipe",
    cwd: repo,
  });
  const out = await new Response(p.stdout).text();
  if ((await p.exited) !== 0) {
    const err = await new Response(p.stderr).text();
    throw new Error(`wt --porcelain başarısız:\n${err.trim() || out.trim()}`);
  }
  return parsePorcelain(out);
}

// Kısa bir wt komutunu bekleyerek çalıştırır. Yalnızca anlık işler için: uzun
// işler startJob'a gidiyor, çünkü burada beklemek menüyü tuşa sağır bırakır.
// Hata metni stderr'den, boşsa stdout'tan — wt uyarıları stderr'e, adımları
// stdout'a yazıyor ve hangisinin dolu olduğu komuta göre değişiyor.
async function runWt(repo: string, argv: string[]): Promise<{ ok: boolean; text: string }> {
  const p = Bun.spawn(["bash", wtScript(repo), ...argv], {
    cwd: repo,
    stdout: "pipe",
    stderr: "pipe",
  });
  const [out, err] = await Promise.all([
    new Response(p.stdout).text(),
    new Response(p.stderr).text(),
  ]);
  return { ok: (await p.exited) === 0, text: (err.trim() || out.trim()).trim() };
}

// Hata mesajının SON satırı: wt önce atladığı dosyaları tek tek uyarıyor, asıl
// teşhisi en sona yazıyor. İlk satırı almak "atlandı: .env" gibi bir ayrıntıyı
// tek satırlık mesaj çubuğuna koyardı.
function lastLine(text: string): string {
  const lines = text.split("\n").filter((l) => l.trim());
  return (lines[lines.length - 1] ?? "bilinmeyen hata").replace(/^[✗!▸]\s*/, "").trim();
}

// ---- tuş çözümleme ----------------------------------------------------------
//
// Terminal ham baytlar veriyor; tek bir tuş 1 ila 6 bayt olabiliyor. Ayrımı
// bozmamak gereken üç yer var:
//   · Enter = CR (\r), ctrl+j = LF (\n). Raw modda farklı baytlar.
//   · tab = \t = ctrl+i. \t'yi generic ctrl eşlemesinden ÖNCE yakalıyoruz.
//   · CSI modifier'ı 1 + shift(1) + alt(2) + ctrl(4), yani ctrl+alt+↑ = "1;7A".
export function decodeKeys(buf: string): Key[] {
  const keys: Key[] = [];
  let i = 0;

  while (i < buf.length) {
    const c = buf[i]!;

    if (c === "\x1b") {
      const csi = /^\x1b\[(\d+)?(?:;(\d+))?([A-Z~])/.exec(buf.slice(i));
      if (csi) {
        const mod = csi[2] ? Number(csi[2]) - 1 : 0;
        const key: Key = {
          name: csiName(csi[3]!, csi[1]),
          shift: (mod & 1) !== 0,
          alt: (mod & 2) !== 0,
          ctrl: (mod & 4) !== 0,
        };
        if (csi[3] === "Z") {
          key.name = "tab";
          key.shift = true;
        }
        keys.push(key);
        i += csi[0].length;
        continue;
      }
      const next = buf[i + 1];
      if (next && next >= " " && next <= "~") {
        keys.push({ name: next.toLowerCase(), alt: true });
        i += 2;
        continue;
      }
      keys.push({ name: "escape" });
      i += 1;
      continue;
    }

    if (c === "\r") {
      keys.push({ name: "enter" });
      i += 1;
      continue;
    }
    if (c === "\t") {
      keys.push({ name: "tab" });
      i += 1;
      continue;
    }
    if (c === "\x7f") {
      keys.push({ name: "backspace" });
      i += 1;
      continue;
    }

    const code = c.charCodeAt(0);
    if (code >= 1 && code <= 26) {
      keys.push({ name: String.fromCharCode(code + 96), ctrl: true });
      i += 1;
      continue;
    }

    keys.push({ name: c });
    i += 1;
  }

  return keys;
}

function csiName(final: string, param?: string): string {
  switch (final) {
    case "A":
      return "up";
    case "B":
      return "down";
    case "C":
      return "right";
    case "D":
      return "left";
    case "Z":
      return "tab";
    case "~":
      return param === "3" ? "delete" : `csi${param ?? ""}`;
    default:
      return `csi${final}`;
  }
}

// ---- ekran ------------------------------------------------------------------

// Zemin, alternatif ekrana geçer geçmez basılıyor. Sıra önemli: veri yüklemek
// (git + wt --porcelain) yüzlerce ms sürüyor, ve boyamayı ondan SONRA yapmak
// popup'ın önce terminalin varsayılan renginde açılıp sonra renk değiştirmesine
// yol açıyordu — açılışta göze çarpan bir sıçrama.
// ?7l = otomatik sarmalama KAPALI. Son kolona yazmak aksi hâlde satırı
// sarmalayıp sağdaki yazıyı kesik gösteriyor; kapatınca tam genişlik kullanılır.
const ALT_SCREEN_ON = `\x1b[?1049h\x1b[?25l\x1b[?7l${SCREEN_INIT}\x1b[2J`;
// Çıkarken TAM sıfırlama: zemin rengini terminale miras bırakmak, popup
// kapandıktan sonra kabuğun renklerini bozar.
const ALT_SCREEN_OFF = "\x1b[0m\x1b[?7h\x1b[?25h\x1b[?1049l";

let REPO_LABEL = "";
let state: State | null = null;

function redraw() {
  if (!state) return;
  const width = process.stdout.columns ?? 80;
  const height = process.stdout.rows ?? 24;
  const lines = render(state, width, height, REPO_LABEL);
  // Ekranı silip baştan yazmak yerine imleci başa alıp her satırın sonunu
  // temizliyoruz: tam temizlik popup'ta gözle görülür bir titreme yapıyor.
  // SON satırdan sonra \r\n YOK: son satıra yazıp yeni satır göndermek
  // alternatif ekranı bir satır kaydırıyor ve altta boş bir satır bırakıyor —
  // dışarıdan "popup'a padding-bottom verilmiş" gibi görünüyor.
  const shown = lines.slice(0, height);
  let out = SCREEN_INIT + "\x1b[H";
  shown.forEach((line, i) => {
    out += line + "\x1b[K";
    if (i < shown.length - 1) out += "\r\n";
  });
  out += "\x1b[J";
  process.stdout.write(out);
}

function splash(text: string) {
  process.stdout.write(`${SCREEN_INIT}\x1b[H\x1b[2J  ${text}`);
}

// ---- komutlar ---------------------------------------------------------------

function notify(body: string) {
  try {
    Bun.spawn([HERDR, "notification", "show", "wt", "--body", body], {
      stdout: "ignore",
      stderr: "ignore",
    });
  } catch {
    // Bildirim gösterilemediyse iş yine yapılmalı.
  }
}

function openUrl(url: string) {
  try {
    Bun.spawn(["open", url], { stdout: "ignore", stderr: "ignore" });
  } catch {
    // Tarayıcı açılamadıysa adres zaten mesaj satırında yazıyor.
  }
}

// Süren işler diskte tutuluyor: BUSY_DIR/<anahtar> dosyası, içinde etiket.
//
// Bellekte tutmak yetmez, çünkü iş menüden BAĞIMSIZ yaşıyor: `q` ile popup'ı
// kapatıp tekrar açtığında süren başlatmanın hâlâ göründüğünü ve Enter'ın onu
// ikinci kez tetiklemediğini görmen lazım.
const BUSY_DIR = join(STATE_DIR, "busy");

// Anahtarlar worktree adı ya da `snapshot:<ad>` — ikincisindeki iki nokta
// dosya adında sorun çıkarır, o yüzden güvenli kümeye indiriyoruz.
function busyFile(key: string): string {
  return join(BUSY_DIR, key.replace(/[^A-Za-z0-9._-]/g, "_"));
}

function readBusy(): Record<string, string> {
  const out: Record<string, string> = {};
  if (!existsSync(BUSY_DIR)) return out;
  for (const f of readdirSync(BUSY_DIR)) {
    try {
      const raw = readFileSync(join(BUSY_DIR, f), "utf8").split("\n");
      const key = raw[0]?.trim();
      const label = raw[1]?.trim();
      if (key && label) out[key] = label;
    } catch {
      // Yarım yazılmış dosya bir sonraki tikte okunur.
    }
  }
  return out;
}

function shq(s: string): string {
  return `'${s.replace(/'/g, `'\\''`)}'`;
}

// Her şey arka planda ve süreç POPUP'TAN KOPUK.
//
// KRİTİK: `detached: true` (setsid) şart, `nohup` YETMİYOR. nohup yalnızca
// SIGHUP'ı yok saydırır; süreç pane ile AYNI oturum ve process group'unda kalır,
// popup kapanınca hangup bütün gruba gider ve SIGHUP'ı yok saymayan torunlar
// (bun'ın çocuğu `next dev`) ölür. Ölçüldü — slot1/slot2 loglarında:
//
//   ✓ Ready in 422ms                       ← 10:20:27, sunucu ayakta
//   error: script "dev" was terminated by signal SIGHUP (Terminal hung up)
//                                          ← 10:20:34, popup kapandı
//
// Geriye yalnızca Docker container'ı kalıyor, yani menü yeniden açıldığında slot
// "Convex açık" görünüyor ve kullanıcı ayakta sandığı slotu tekrar başlatıyor.
// `nohup`'ın bunu neden gizlediğine dikkat: nohup'lı `bun` hayatta kalıp
// "çocuğum SIGHUP aldı" diye rapor ediyor — dışarıdan sunucu çökmüş gibi
// okunuyor, oysa sinyal bütün gruba gelmiş.
//
// Bu yüzden Bun.spawn DEĞİL node'un spawn'ı: Bun.spawn'da `detached` seçeneği
// yok, setsid'i çağırmanın başka yolu da yok.
//
// Bunun bedeli çıkış kodunu burada bekleyememek — onu işin kendisi hallediyor:
// bitince işaret dosyasını siliyor ve bildirimi kendisi gönderiyor.
//
// Arka planda tty YOK, yani wt'nin confirm_destructive'i kendi onayını atlıyor.
// Bu bilinçli: yıkıcı işlerin onayını zaten bu menüde alıyoruz, ve cevabı
// kimsenin veremeyeceği bir yerde sormak işi sonsuza kadar askıda bırakırdı.
function startJob(repo: string, cmd: Extract<Cmd, { kind: "exec" }>) {
  if (!state) return;
  mkdirSync(BUSY_DIR, { recursive: true });
  const marker = busyFile(cmd.busyKey);
  writeFileSync(marker, `${cmd.busyKey}\n${cmd.label}\n`);

  const stamp = new Date().toISOString().slice(0, 19).replace("T", " ");
  const argv = cmd.argv.map(shq).join(" ");
  const script = [
    `printf '\\n--- %s  wt %s\\n' ${shq(stamp)} ${shq(cmd.argv.join(" "))} >> ${shq(RUN_LOG)}`,
    `bash ${shq(wtScript(repo))} ${argv} >> ${shq(RUN_LOG)} 2>&1`,
    `code=$?`,
    `rm -f ${shq(marker)}`,
    `if [ $code -eq 0 ]; then body=${shq(`bitti: ${cmd.label}`)}; else body="HATA ($code): ${cmd.label}"; fi`,
    `${shq(HERDR)} notification show wt --body "$body" >/dev/null 2>&1`,
  ].join("; ");

  try {
    const child = nodeSpawn("sh", ["-c", script], {
      cwd: repo,
      detached: true,
      // Script kendi çıktısını RUN_LOG'a yönlendiriyor; buradan miras alınacak
      // bir fd bırakmak popup'ın pty'sini açık tutar ve kopukluğu bozar.
      stdio: "ignore",
    });
    // Menü `q` ile kapanırken çocuğu beklemesin.
    child.unref();
    state = { ...state, busy: readBusy(), message: `${cmd.label} — arka planda` };
  } catch (e) {
    try {
      unlinkSync(marker);
    } catch {
      /* zaten yok */
    }
    state = { ...state, message: `başlatılamadı: ${e instanceof Error ? e.message : String(e)}` };
  }
  redraw();
}

// ---- ana döngü --------------------------------------------------------------

async function main() {
  const interactive = Boolean(process.stdin.isTTY);

  if (interactive) {
    // Önce boya, sonra yükle. Tersi açılışta renk sıçramasına yol açıyor.
    process.stdout.write(ALT_SCREEN_ON);
    splash("wt — yükleniyor…");
  }

  const repo = await resolveRepo();
  REPO_LABEL = basename(repo);
  state = initialState(await loadData(repo));
  // Önceki bir oturumdan kalan süren işleri devral: menü kapanıp açılsa bile
  // "başlatılıyor" görünmeye devam etsin.
  state = { ...state, busy: readBusy() };

  if (!interactive) {
    // Popup dışında (örneğin doğrudan `bun src/menu.ts`) çalıştırıldıysa TUI
    // kurulamaz; okunur bir döküm basıp çıkmak sessiz boş ekrandan iyi.
    process.stdout.write(render(state, process.stdout.columns ?? 100, 30, REPO_LABEL).join("\n") + "\n");
    return;
  }

  try {
    mkdirSync(STATE_DIR, { recursive: true });
    writeFileSync(
      join(STATE_DIR, "dims.log"),
      `columns=${process.stdout.columns} rows=${process.stdout.rows}\n`,
    );
  } catch {
    // Ölçü günlüğü tutulamazsa menü yine çalışmalı.
  }

  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdin.setEncoding("latin1");

  const cleanup = () => {
    process.stdin.setRawMode?.(false);
    process.stdout.write(ALT_SCREEN_OFF);
  };
  process.on("exit", cleanup);
  process.on("SIGINT", () => {
    cleanup();
    process.exit(0);
  });
  process.stdout.on("resize", redraw);

  // Arka planda iş varken tabloyu tazele: başlatma dakikalar sürüyor ve
  // "kapalı" satırının kendiliğinden "ayakta"ya dönmesi, kullanıcının r'ye
  // basmasını gereksiz kılıyor.
  const ticker = setInterval(() => {
    if (!state) return;
    const busy = readBusy();
    const wasBusy = Object.keys(state.busy).length > 0;
    const isBusy = Object.keys(busy).length > 0;
    if (!wasBusy && !isBusy) return;
    loadData(repo)
      .then((data) => {
        if (!state) return;
        state = { ...state, data, sel: clampSel(data, state.sel), busy };
        redraw();
      })
      .catch(() => {
        if (!state) return;
        state = { ...state, busy };
        redraw();
      });
  }, 3000);

  redraw();

  for await (const chunk of process.stdin) {
    let quit = false;
    for (const key of decodeKeys(String(chunk))) {
      if (key.ctrl && key.name === "c") {
        quit = true;
        break;
      }
      const { state: next, cmd } = reduce(state, key);
      state = next;
      if (await apply(repo, cmd)) {
        quit = true;
        break;
      }
    }
    if (quit) break;
    redraw();
  }

  clearInterval(ticker);
  cleanup();
}

// Cmd'yi yürütür. true dönerse döngü biter.
async function apply(repo: string, cmd: Cmd): Promise<boolean> {
  if (!state) return true;
  switch (cmd.kind) {
    case "none":
      return false;
    case "quit":
      return true;
    case "open":
      openUrl(cmd.url);
      return false;
    case "refresh": {
      // Yenilemeden sonra seçimi kırpmak şart: bir slot silinmişse eski indeks
      // artık var olmayan bir satırı gösterir ve imleç görünmez olur.
      const data = await loadData(repo);
      state = { ...state, data, sel: clampSel(data, state.sel), message: "yenilendi" };
      return false;
    }
    case "linkEnv": {
      // Birkaç symlink — beklemek milisaniyeler sürüyor. Arka plana atmak
      // burada zarar: rozet ancak 3 sn'lik tikle güncellenir ve çoktan bitmiş
      // bir iş için bildirim çıkardı. Bekleyip tabloyu yenilemek, `e`ye basınca
      // rozetin aynı karede kaybolması demek.
      const res = await runWt(repo, ["--link-env", cmd.wtName]);
      const data = await loadData(repo);
      state = {
        ...state,
        data,
        sel: clampSel(data, state.sel),
        // Hata metnini kendi önekimizle sarmalamıyoruz: wt'nin son satırı zaten
        // teşhisin kendisi ("… kaynak dosya ana worktree'de de yok") ve önüne
        // "env kurulamadı" koymak aynı şeyi iki kez söylemek olurdu.
        message: `${cmd.wtName}: ${res.ok ? "env kuruldu" : lastLine(res.text)}`,
      };
      return false;
    }
    case "exec":
      // Beklemiyoruz: iş koparılmış bir süreçte dönerken menü tuş almaya devam
      // etsin, hatta kapatılabilsin.
      startJob(repo, cmd);
      return false;
  }
}

if (import.meta.main) {
  main().catch((e) => {
    process.stdin.setRawMode?.(false);
    process.stdout.write(ALT_SCREEN_OFF);
    process.stderr.write(`\nwt: ${e instanceof Error ? e.message : String(e)}\n`);
    process.exit(1);
  });
}
