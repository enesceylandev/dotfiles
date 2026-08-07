// Tasarımı tty'siz gözden geçirmek için. Popup açıp tuşa basmadan, sabit bir
// fixture üzerinde herhangi bir ekranı basar:
//
//   bun src/preview.ts              → liste
//   bun src/preview.ts tab          → slot paneli seçili
//   bun src/preview.ts tab,s        → snapshot adı girişi
//   bun src/preview.ts tab,d        → silme onayı
//   bun src/preview.ts tab,tab,enter → geri yükleme hedefi seçimi
//   bun src/preview.ts ?            → yardım
//
// Gerçek veriyle bakmak için: WT_REPO=<repo> bun src/menu.ts (tty yoksa döker).
import { initialState, parsePorcelain, reduce } from "./model.ts";
import { render } from "./render.ts";
const F = [
  "worktree\tboemar-hr\tfeat/workflow-node-activation\t/Users/enes/Documents/boemar-hr\t0\t1",
  "worktree\tboemar-hr-dbopt\trefactor/database-optimization\t/Users/enes/Documents/boemar-hr-dbopt\t0\t0",
  "worktree\tform-file-upload-ai\tfeature/form-file-upload-ai\t/wt/form-file-upload-ai\t0\t0",
  "worktree\tbroken-env\tfeature/broken\t/wt/broken-env\t2\t0",
  "slot\t1\tboemar-hr-dbopt\t/x\t3100\t3101\t3012\t3014\tup\t/log/1",
  "slot\t2\tform-file-upload-ai\t/y\t3110\t3111\t3022\t3024\tconvex\t/log/2",
  "snapshot\tdemo-firma\t47621082\t1786012725",
  "snapshot\ttest\t8033341\t1786027066",
].join("\n");
let s = initialState(parsePorcelain(F));
if (process.env.BUSY) s = { ...s, busy: { "form-file-upload-ai": "başlatılıyor" } };
const keys = (process.argv[2] ?? "").split(",").filter(Boolean);
for (const name of keys) s = reduce(s, { name }).state;
console.log(render(s, 108, 22, "boemar-hr").join("\n"));
