// Reducer ve ayrıştırıcı saf olduğu için tty'siz test edilebiliyor: popup
// açmadan, tuşa basmadan, gözle bakmadan. Fixture gerçek `wt --porcelain`
// biçimi — elle özetlenmiş bir örnek olsaydı alan sırası kaydığında sessizce
// geçerdi.

import { describe, expect, test } from "bun:test";
import {
  formatDate,
  humanBytes,
  initialState,
  parsePorcelain,
  reduce,
  restoreTargets,
  validateSnapshotName,
  type Key,
  type State,
} from "./model.ts";
import { render } from "./render.ts";

const FIXTURE = [
  "worktree\tboemar-hr\tfeat/workflow-node-activation\t/Users/enes/Documents/boemar-hr\t0\t1",
  "worktree\tboemar-hr-dbopt\trefactor/database-optimization\t/Users/enes/Documents/boemar-hr-dbopt\t0\t0",
  "worktree\tform-file-upload-ai\tfeature/form-file-upload-ai\t/wt/form-file-upload-ai\t0\t0",
  "worktree\tbroken-env\tfeature/broken\t/wt/broken-env\t2\t0",
  "slot\t1\tboemar-hr-dbopt\t/Users/enes/Documents/boemar-hr-dbopt\t3100\t3101\t3012\t3014\tup\t/log/1",
  "slot\t3\tform-file-upload-ai\t/wt/form-file-upload-ai\t3120\t3121\t3032\t3034\tdown\t/log/3",
  "snapshot\tdemo-firma\t47621082\t1786012725",
  "snapshot\ttest\t8033341\t1786027066",
].join("\n");

const k = (name: string, mods: Partial<Key> = {}): Key => ({ name, ...mods });

const fresh = () => initialState(parsePorcelain(FIXTURE));

const strip = (s: string) => s.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "");

function press(state: State, ...keys: Key[]) {
  let r = reduce(state, keys[0]!);
  for (const key of keys.slice(1)) r = reduce(r.state, key);
  return r;
}

// Sık kullanılan konumlar: fixture'daki satır sıralarına isim veriyoruz, testler
// "k('j') dört kez" gibi okunmasın.
const AT = {
  mainWt: (s: State) => s,
  dboptWt: (s: State) => press(s, k("j")).state, // slotu ayakta
  uploadWt: (s: State) => press(s, k("j"), k("j")).state, // slotu kapalı
  brokenWt: (s: State) => press(s, k("j"), k("j"), k("j")).state, // env eksik
  upSlot: (s: State) => press(s, k("tab")).state, // slot panelinin ilk satırı
  downSlot: (s: State) => press(s, k("tab"), k("j")).state,
  firstSnap: (s: State) => press(s, k("tab"), k("tab")).state,
};

describe("parsePorcelain", () => {
  test("üç kayıt tipini de okur ve alanları doğru yerleştirir", () => {
    const d = parsePorcelain(FIXTURE);
    expect(d.worktrees).toHaveLength(4);
    expect(d.slots).toHaveLength(2);
    expect(d.snapshots).toHaveLength(2);
    expect(d.worktrees[0]).toMatchObject({ name: "boemar-hr", running: true, missingEnv: 0 });
    expect(d.worktrees[3]).toMatchObject({ name: "broken-env", missingEnv: 2 });
    expect(d.slots[0]).toMatchObject({ n: "1", fe: "3100", be: "3101", api: "3012", state: "up" });
    expect(d.snapshots[0]).toMatchObject({ name: "demo-firma", bytes: 47621082 });
  });

  test("eksik alanlı, bilinmeyen tipli ve boş satırları atlar", () => {
    const d = parsePorcelain("worktree\tkısa\tsatır\ngelecek-tipi\ta\tb\tc\n\n" + FIXTURE);
    expect(d.worktrees).toHaveLength(4);
    expect(d.slots).toHaveLength(2);
  });

  test("bilinmeyen slot state'i down sayar, çökmez", () => {
    const d = parsePorcelain("slot\t9\tx\t/x\t1\t2\t3\t4\tGARİP\t/l");
    expect(d.slots[0]!.state).toBe("down");
  });
});

describe("navigasyon: j/k panel sınırını geçer", () => {
  test("son worktree'den sonra j slot paneline girer", () => {
    const s = AT.brokenWt(fresh());
    expect(s.sel).toEqual({ panel: "worktree", index: 3 });
    const next = press(s, k("j")).state;
    expect(next.sel).toEqual({ panel: "slot", index: 0 });
  });

  test("ilk slottan k son worktree'ye döner", () => {
    const s = press(AT.upSlot(fresh()), k("k")).state;
    expect(s.sel).toEqual({ panel: "worktree", index: 3 });
  });

  test("son slottan j snapshot paneline girer", () => {
    const s = press(AT.downSlot(fresh()), k("j")).state;
    expect(s.sel).toEqual({ panel: "snapshot", index: 0 });
  });

  test("listenin sonunda durur, başa sarmalamaz", () => {
    let s = fresh();
    for (let i = 0; i < 20; i++) s = press(s, k("j")).state;
    expect(s.sel).toEqual({ panel: "snapshot", index: 1 });
    for (let i = 0; i < 20; i++) s = press(s, k("k")).state;
    expect(s.sel).toEqual({ panel: "worktree", index: 0 });
  });

  test("ok tuşları j/k ile aynı", () => {
    expect(press(fresh(), k("down")).state.sel).toEqual({ panel: "worktree", index: 1 });
    expect(press(AT.upSlot(fresh()), k("up")).state.sel).toEqual({ panel: "worktree", index: 3 });
  });

  test("boş paneller atlanır — slot ve snapshot yoksa j worktree'de kalır", () => {
    const only = initialState(parsePorcelain("worktree\ta\tb\t/a\t0\t0\nworktree\tc\td\t/c\t0\t0"));
    let s = only;
    for (let i = 0; i < 5; i++) s = press(s, k("j")).state;
    expect(s.sel).toEqual({ panel: "worktree", index: 1 });
  });
});

describe("navigasyon: tab panel atlar", () => {
  test("tab sırayla dolaşır ve sarmalar", () => {
    let s = fresh();
    s = press(s, k("tab")).state;
    expect(s.sel.panel).toBe("slot");
    s = press(s, k("tab")).state;
    expect(s.sel.panel).toBe("snapshot");
    s = press(s, k("tab")).state;
    expect(s.sel.panel).toBe("worktree");
  });

  test("shift+tab ters yön", () => {
    expect(press(fresh(), k("tab", { shift: true })).state.sel.panel).toBe("snapshot");
  });

  test("tab panelin ilk satırına konar", () => {
    const s = press(AT.brokenWt(fresh()), k("tab"), k("j"), k("tab"), k("tab")).state;
    expect(s.sel).toEqual({ panel: "worktree", index: 0 });
  });

  test("boş panel atlanır", () => {
    const noSnap = initialState(
      parsePorcelain(
        "worktree\ta\tb\t/a\t0\t0\nworktree\tc\td\t/c\t0\t0\nslot\t1\tc\t/c\t3100\t3101\t3012\t3014\tup\t/l",
      ),
    );
    let s = press(noSnap, k("tab")).state;
    expect(s.sel.panel).toBe("slot");
    s = press(s, k("tab")).state;
    expect(s.sel.panel).toBe("worktree");
  });
});

describe("worktree → enter", () => {
  test("snapshot seçme moduna girer", () => {
    const s = press(AT.uploadWt(fresh()), k("enter")).state;
    expect(s.mode).toMatchObject({ kind: "snapshotPick", wtName: "form-file-upload-ai", cursor: 0 });
  });

  test("boş bırakıp enter → sıfırdan slot", () => {
    const { cmd } = press(AT.uploadWt(fresh()), k("enter"), k("enter"));
    expect(cmd).toMatchObject({
      kind: "exec",
      argv: ["form-file-upload-ai"],
      busyKey: "form-file-upload-ai",
    });
  });

  test("snapshot seçip enter → argv'ye ad eklenir", () => {
    const { cmd } = press(AT.uploadWt(fresh()), k("enter"), k("j"), k("enter"));
    expect(cmd).toMatchObject({
      kind: "exec",
      argv: ["form-file-upload-ai", "demo-firma"],
    });
  });

  test("ana worktree slot alamaz", () => {
    const { state, cmd } = press(fresh(), k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("ana worktree");
  });

  test("env eksikse başlatmaz", () => {
    const { state, cmd } = press(AT.brokenWt(fresh()), k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("env dosyası eksik");
  });

  test("worktree'de de toggle: ayaktaki slotu durdurur, yeniden başlatmaz", () => {
    const { cmd } = press(AT.dboptWt(fresh()), k("enter"));
    expect(cmd).toMatchObject({ kind: "exec", argv: ["--stop", "boemar-hr-dbopt"] });
  });

  test("esc vazgeçer", () => {
    const { state, cmd } = press(AT.uploadWt(fresh()), k("enter"), k("escape"));
    expect(state.mode.kind).toBe("list");
    expect(cmd.kind).toBe("none");
  });
});

describe("slot → enter duruma göre", () => {
  test("ayaktaki slot durur", () => {
    const { cmd } = press(AT.upSlot(fresh()), k("enter"));
    expect(cmd).toMatchObject({
      kind: "exec",
      argv: ["--stop", "boemar-hr-dbopt"],
    });
  });

  test("kapalı slot başlar", () => {
    const { cmd } = press(AT.downSlot(fresh()), k("enter"));
    expect(cmd).toMatchObject({
      kind: "exec",
      argv: ["form-file-upload-ai"],
      busyKey: "form-file-upload-ai",
    });
  });
});

describe("meşgul slot Enter'ı yutar", () => {
  // Arka planda çalışmanın bedeli: başlatma dakikalar sürerken satır hâlâ
  // "kapalı" görünüyor. İşaretlemezsek her Enter yeni bir başlatma denemesi
  // olur ve wt "slot zaten çalışıyor" diye ölür.
  const busyState = (): State => {
    const s = AT.downSlot(fresh());
    return { ...s, busy: { "form-file-upload-ai": "başlatılıyor" } };
  };

  test("slot panelinde enter komut üretmez, uyarır", () => {
    const { state, cmd } = press(busyState(), k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("başlatılıyor");
  });

  test("worktree panelinde de yutulur", () => {
    const s = { ...AT.uploadWt(fresh()), busy: { "form-file-upload-ai": "başlatılıyor" } };
    const { state, cmd } = press(s, k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.mode.kind).toBe("list");
    expect(state.message).toContain("bitmesini bekle");
  });

  test("meşgul satır YALNIZCA ◌ ile gösterilir, metin yazılmaz", () => {
    const out = strip(render(busyState(), 100, 30).join("\n"));
    expect(out).toContain("◌");
    // Etiketi satıra da basmak fazlalıktı: ikon zaten söylüyor, üstelik metin
    // durum kolonunu kaydırıp sağ hizayı bozuyordu.
    expect(out).not.toContain("başlatılıyor");
  });
});

describe("w → tarayıcıda aç", () => {
  test("ayaktaki slotta frontend adresini açar", () => {
    const { cmd } = press(AT.upSlot(fresh()), k("w"));
    expect(cmd).toMatchObject({ kind: "open", url: "http://localhost:3100" });
  });

  test("worktree satırında da çalışır", () => {
    const { cmd } = press(AT.dboptWt(fresh()), k("w"));
    expect(cmd).toMatchObject({ kind: "open", url: "http://localhost:3100" });
  });

  test("kapalı slotta açmaz, uyarır", () => {
    const { state, cmd } = press(AT.downSlot(fresh()), k("w"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("ayakta değil");
  });

  test("snapshot satırında anlamsız", () => {
    const { state, cmd } = press(AT.firstSnap(fresh()), k("w"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("adresi yok");
  });
});

describe("e → eksik env'i kur", () => {
  test("env eksik worktree'de linkEnv komutu üretir", () => {
    const { cmd } = press(AT.brokenWt(fresh()), k("e"));
    expect(cmd).toMatchObject({ kind: "linkEnv", wtName: "broken-env" });
  });

  test("env tamsa iş yapmaz ama sessiz de kalmaz", () => {
    const { state, cmd } = press(AT.uploadWt(fresh()), k("e"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("zaten tam");
  });

  test("slot satırında da o slotun worktree'sine bakar", () => {
    const { state, cmd } = press(AT.upSlot(fresh()), k("e"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("boemar-hr-dbopt");
  });

  test("snapshot satırında anlamsız", () => {
    const { state, cmd } = press(AT.firstSnap(fresh()), k("e"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("worktree seç");
  });

  test("meşgul worktree'de yutulur — iş biterken env'e dokunmak yarış", () => {
    const busy = { ...AT.brokenWt(fresh()), busy: { "broken-env": "başlatılıyor" } };
    const { cmd } = press(busy, k("e"));
    expect(cmd.kind).toBe("none");
  });

  test("enter env eksikken başlatmaz, e'ye yönlendirir", () => {
    const { state, cmd } = press(AT.brokenWt(fresh()), k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("e ile kur");
  });
});

describe("s → snapshot al", () => {
  test("slot üzerinde s ad girişi açar", () => {
    const s = press(AT.upSlot(fresh()), k("s")).state;
    expect(s.mode).toMatchObject({ kind: "input", wtName: "boemar-hr-dbopt", slotN: "1", value: "" });
  });

  test("worktree üzerinde de çalışır — o worktree'nin slotunu bulur", () => {
    const s = press(AT.dboptWt(fresh()), k("s")).state;
    expect(s.mode).toMatchObject({ kind: "input", slotN: "1" });
  });

  test("slotu olmayan worktree'de uyarır", () => {
    const { state, cmd } = press(AT.brokenWt(fresh()), k("s"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("slotu yok");
  });

  test("harf harf yazılır, backspace siler", () => {
    let s = press(AT.upSlot(fresh()), k("s"), k("d"), k("e"), k("m"), k("o")).state;
    expect((s.mode as any).value).toBe("demo");
    s = press(s, k("backspace")).state;
    expect((s.mode as any).value).toBe("dem");
  });

  test("enter → --snapshot argv'si, run pane'ine", () => {
    const { cmd } = press(AT.upSlot(fresh()), k("s"), k("y"), k("e"), k("n"), k("i"), k("enter"));
    expect(cmd).toMatchObject({
      kind: "exec",
      argv: ["--snapshot", "boemar-hr-dbopt", "yeni"],
    });
  });

  test("geçersiz ad wt'ye gönderilmez, ekranda hata gösterilir", () => {
    const { state, cmd } = press(AT.upSlot(fresh()), k("s"), k("a"), k("/"), k("b"), k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.mode.kind).toBe("input");
    expect((state.mode as any).error).toContain("yalnızca harf");
  });

  test("boş ad reddedilir", () => {
    const { state, cmd } = press(AT.upSlot(fresh()), k("s"), k("enter"));
    expect(cmd.kind).toBe("none");
    expect((state.mode as any).error).toContain("boş olamaz");
  });

  test("input modunda j/k metne yazılır, satır gezdirmez", () => {
    const s = press(AT.upSlot(fresh()), k("s"), k("j"), k("k")).state;
    expect((s.mode as any).value).toBe("jk");
    expect(s.sel).toEqual({ panel: "slot", index: 0 });
  });

  test("esc vazgeçer", () => {
    const s = press(AT.upSlot(fresh()), k("s"), k("a"), k("escape")).state;
    expect(s.mode.kind).toBe("list");
  });
});

describe("validateSnapshotName", () => {
  test("wt'nin kabul ettiği kümeyi yansıtır", () => {
    expect(validateSnapshotName("demo-firma_2.tgz")).toBe("");
    expect(validateSnapshotName("")).toContain("boş");
    expect(validateSnapshotName(".gizli")).toContain("nokta");
    expect(validateSnapshotName("a b")).toContain("yalnızca harf");
    expect(validateSnapshotName("../kaç")).toContain("yalnızca harf");
  });
});

describe("snapshot → enter → geri yükle", () => {
  test("hedef worktree seçtirir, ana worktree hedef olamaz", () => {
    const s = press(AT.firstSnap(fresh()), k("enter")).state;
    expect(s.mode).toMatchObject({ kind: "restorePick", snapName: "demo-firma", cursor: 0 });
    // Render metnine bakmak kırılgan (adlar birbirinin öneki); asıl kural bu.
    expect(restoreTargets(parsePorcelain(FIXTURE)).map((t) => t.name)).toEqual([
      "boemar-hr-dbopt",
      "form-file-upload-ai",
      "broken-env",
    ]);
    expect(strip(render(s, 100, 30).join("\n"))).toContain("boemar-hr-dbopt");
  });

  test("hedef seçtikten sonra onay ekranı gelir, hemen çalışmaz", () => {
    const { state, cmd } = press(AT.firstSnap(fresh()), k("enter"), k("enter"));
    expect(cmd.kind).toBe("none");
    expect(state.mode).toMatchObject({
      kind: "confirm",
      argv: ["--restore", "boemar-hr-dbopt", "demo-firma"],
    });
  });

  test("onaydan sonra çalışır", () => {
    const { cmd } = press(AT.firstSnap(fresh()), k("enter"), k("enter"), k("y"));
    expect(cmd).toMatchObject({
      kind: "exec",
      argv: ["--restore", "boemar-hr-dbopt", "demo-firma"],
    });
  });
});

describe("d → silme onayı", () => {
  test("slot üzerinde d onay ister, hemen silmez", () => {
    const { state, cmd } = press(AT.upSlot(fresh()), k("d"));
    expect(cmd.kind).toBe("none");
    expect(state.mode).toMatchObject({
      kind: "confirm",
      argv: ["--drop-slot", "boemar-hr-dbopt"],
    });
  });

  test("worktree üzerinde d o worktree'nin slotunu hedefler", () => {
    const { state } = press(AT.dboptWt(fresh()), k("d"));
    expect(state.mode).toMatchObject({ kind: "confirm", argv: ["--drop-slot", "boemar-hr-dbopt"] });
  });

  test("slotu olmayan worktree'de silinecek bir şey yok", () => {
    const { state, cmd } = press(AT.brokenWt(fresh()), k("d"));
    expect(cmd.kind).toBe("none");
    expect(state.message).toContain("silinecek slot yok");
  });

  test("snapshot üzerinde d snapshot'ı hedefler", () => {
    const { state } = press(AT.firstSnap(fresh()), k("j"), k("d"));
    expect(state.mode).toMatchObject({ kind: "confirm", argv: ["--drop-snapshot", "test"] });
  });

  test("y onaylar, n vazgeçer", () => {
    expect(press(AT.upSlot(fresh()), k("d"), k("y")).cmd.kind).toBe("exec");
    const cancelled = press(AT.upSlot(fresh()), k("d"), k("n"));
    expect(cancelled.cmd.kind).toBe("none");
    expect(cancelled.state.message).toBe("iptal edildi");
  });

  test("onay ekranında j satır gezdirmez — tuşlar sızmıyor", () => {
    const { state } = press(AT.upSlot(fresh()), k("d"), k("j"));
    expect(state.mode.kind).toBe("confirm");
    expect(state.sel).toEqual({ panel: "slot", index: 0 });
  });
});

describe("q / r / ?", () => {
  test("q çıkar, r yeniler", () => {
    expect(press(fresh(), k("q")).cmd.kind).toBe("quit");
    expect(press(fresh(), k("r")).cmd.kind).toBe("refresh");
  });
  test("? yardımı açar, herhangi bir tuş kapatır", () => {
    let s = press(fresh(), k("?")).state;
    expect(s.mode.kind).toBe("help");
    expect(press(s, k("x")).state.mode.kind).toBe("list");
  });
});

describe("humanBytes, du -h ile aynı okunur", () => {
  test("10'un altında ondalık, üstünde yuvarlak", () => {
    expect(humanBytes(47621082)).toBe("45M");
    expect(humanBytes(8033341)).toBe("7.7M");
    expect(humanBytes(1024 * 1024 * 12.6)).toBe("13M");
    expect(humanBytes(512)).toBe("512B");
  });
});

describe("render", () => {

  test("üç paneli, satırları ve adresi basar", () => {
    const out = strip(render(fresh(), 100, 30, "boemar-hr").join("\n"));
    // Worktree panelinin başlığı YOK — pane'in çerçeve başlığı onu adlandırıyor,
    // ikisi üst üste gelince aynı kelime iki kez okunuyordu.
    expect(out).not.toContain("── worktree");
    expect(out).toContain("── slot");
    expect(out).toContain("── snapshot");
    expect(out).toContain("boemar-hr-dbopt");
    expect(out).toContain("localhost:3100");
    expect(out).toContain("demo-firma");
  });

  test("durumu YALNIZCA glif anlatır — 'ayakta'/'kapalı' metni yok", () => {
    const out = strip(render(fresh(), 100, 30).join("\n"));
    expect(out).toContain("●"); // ayakta
    expect(out).toContain("○"); // kapalı
    expect(out).not.toContain("ayakta");
    expect(out).not.toContain("kapalı");
    // Env uyarısı bir durum değil, bir engel — o yazıyla kalıyor.
    expect(out).toContain("2 env eksik");
  });

  test("uzun branch adı kırpılmaz (ekranda yer varken)", () => {
    const long = parsePorcelain(
      "worktree\ta\tfeature/subscription-per-user-seats-and-billing\t/a\t0\t0",
    );
    const out = strip(render(initialState(long), 110, 20).join("\n"));
    expect(out).toContain("feature/subscription-per-user-seats-and-billing");
    expect(out).not.toContain("…");
  });

  test("seçili satırı kenar çubuğu ile işaretler, tek bir tane olur", () => {
    const lines = render(fresh(), 100, 30);
    expect(lines.filter((l) => l.includes("▌")).length).toBe(1);
  });

  test("alt bar bağlama göre değişir", () => {
    expect(strip(render(AT.uploadWt(fresh()), 100, 30).join("\n"))).toContain("başlat");
    expect(strip(render(AT.upSlot(fresh()), 100, 30).join("\n"))).toContain("durdur");
    expect(strip(render(AT.firstSnap(fresh()), 100, 30).join("\n"))).toContain("geri yükle");
  });

  test("hiçbir satır görünür genişliği aşmaz", () => {
    const width = 70;
    for (const line of render(fresh(), width, 30)) {
      expect(strip(line).length).toBeLessThanOrEqual(width);
    }
  });

  test("dar ekranda da taşmaz", () => {
    const width = 48;
    for (const line of render(fresh(), width, 30)) {
      expect(strip(line).length).toBeLessThanOrEqual(width);
    }
  });

  test("boş veri çökmez", () => {
    const out = strip(render(initialState(parsePorcelain("")), 80, 24).join("\n"));
    expect(out).toContain("yok");
  });

  test("hiçbir ekran yüksekliği aşmaz ve dibe kadar doldurulmaz", () => {
    const h = 26;
    for (const st of [
      fresh(),
      press(fresh(), k("?")).state,
      press(AT.upSlot(fresh()), k("d")).state,
      press(AT.upSlot(fresh()), k("s")).state,
    ]) {
      const n = render(st, 100, h).length;
      expect(n).toBeLessThanOrEqual(h);
      expect(n).toBeGreaterThan(3);
    }
  });

  test("alt bar her zaman EN SON satır — çerçevenin dibinde", () => {
    for (const h of [16, 20, 40]) {
      const lines = render(fresh(), 100, h);
      expect(lines).toHaveLength(h);
      expect(strip(lines[lines.length - 1]!)).toContain("çık");
    }
  });

  test("alt bar 'env kur'u yalnızca env eksik satırda gösterir", () => {
    const broken = strip(render(AT.brokenWt(fresh()), 100, 20).join("\n"));
    expect(broken).toContain("env kur");
    // Env'i tam olan satırda bir tuş daha okumak gereksiz gürültü.
    expect(strip(render(AT.uploadWt(fresh()), 100, 20).join("\n"))).not.toContain("env kur");
  });

  test("worktree satırında rozet branch'ten ÖNCE gelir", () => {
    const row = render(fresh(), 100, 20)
      .map(strip)
      .find((l) => l.includes("boemar-hr-dbopt") && l.includes("refactor/"))!;
    expect(row.indexOf("slot 1")).toBeLessThan(row.indexOf("refactor/"));
  });

  test("sağdaki alan sola yaslı: kolonlar satırlar arası hizalı", () => {
    const lines = render(fresh(), 100, 20).map(strip);
    const cols = ["slot 1", "slot 3", "2 env eksik", "ana"].map((needle) => {
      const row = lines.find((l) => l.includes(needle))!;
      return row.indexOf(needle);
    });
    // Hepsi aynı kolonda başlamalı — sağa yaslı olsaydı her satırda kayardı.
    expect(new Set(cols).size).toBe(1);
  });

  test("snapshot satırında boyut ve tarih kendi kolonlarında", () => {
    const row = render(fresh(), 100, 20)
      .map(strip)
      .find((l) => l.includes("demo-firma"))!;
    // Tarihi sabit yazmak saat dilimine bağımlı olurdu (bun test UTC'de koşuyor,
    // kabuk +03'te); beklenen değeri aynı fonksiyondan üretiyoruz.
    expect(row).toContain(formatDate(1786012725));
    expect(row.indexOf("45M")).toBeLessThan(row.indexOf(formatDate(1786012725)));
  });

  test("onay ekranı çalışacak komutu ve neyin korunduğunu gösterir", () => {
    const out = strip(render(press(AT.upSlot(fresh()), k("d")).state, 100, 30).join("\n"));
    expect(out).toContain("wt --drop-slot boemar-hr-dbopt");
    expect(out).toContain("DOKUNULMAZ");
  });

  test("ad girişi yazılanı ve kuralı gösterir", () => {
    const s = press(AT.upSlot(fresh()), k("s"), k("a"), k("b")).state;
    const out = strip(render(s, 100, 30).join("\n"));
    expect(out).toContain("ab");
    expect(out).toContain("harf, rakam");
  });
});
