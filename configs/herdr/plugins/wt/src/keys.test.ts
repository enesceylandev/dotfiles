// Tuş çözümleyicinin testleri. Bunlar "çalışıyor mu" testinden çok regresyon
// kilidi: üç ayrım var ki bozulduğunda menü sessizce yanlış davranır —
// Enter(CR) ile ctrl+j(LF), tab ile ctrl+i, ve CSI modifier bitleri.

import { describe, expect, test } from "bun:test";
import { decodeKeys } from "./menu.ts";

describe("decodeKeys", () => {
  test("Enter ile ctrl+j ayrı tuşlardır", () => {
    expect(decodeKeys("\r")).toEqual([{ name: "enter" }]);
    expect(decodeKeys("\n")).toEqual([{ name: "j", ctrl: true }]);
  });

  test("tab, ctrl+i olarak raporlanmaz", () => {
    expect(decodeKeys("\t")).toEqual([{ name: "tab" }]);
  });

  test("ctrl+k ve ctrl+c", () => {
    expect(decodeKeys("\x0b")).toEqual([{ name: "k", ctrl: true }]);
    expect(decodeKeys("\x03")).toEqual([{ name: "c", ctrl: true }]);
  });

  test("çıplak ok tuşları", () => {
    expect(decodeKeys("\x1b[A")).toMatchObject([{ name: "up", ctrl: false, alt: false }]);
    expect(decodeKeys("\x1b[B")).toMatchObject([{ name: "down" }]);
    expect(decodeKeys("\x1b[C")).toMatchObject([{ name: "right" }]);
    expect(decodeKeys("\x1b[D")).toMatchObject([{ name: "left" }]);
  });

  test("CSI modifier bitleri: 1+shift(1)+alt(2)+ctrl(4)", () => {
    expect(decodeKeys("\x1b[1;7A")).toMatchObject([{ name: "up", ctrl: true, alt: true }]);
    expect(decodeKeys("\x1b[1;5B")).toMatchObject([{ name: "down", ctrl: true, alt: false }]);
    expect(decodeKeys("\x1b[1;3B")).toMatchObject([{ name: "down", ctrl: false, alt: true }]);
    expect(decodeKeys("\x1b[1;2A")).toMatchObject([{ name: "up", shift: true }]);
  });

  test("shift+tab CSI Z olarak da gelir", () => {
    expect(decodeKeys("\x1b[Z")).toMatchObject([{ name: "tab", shift: true }]);
  });

  test("çıplak ESC, dizinin başlangıcı sanılmaz", () => {
    expect(decodeKeys("\x1b")).toEqual([{ name: "escape" }]);
  });

  test("alt+harf = ESC + harf", () => {
    expect(decodeKeys("\x1bj")).toEqual([{ name: "j", alt: true }]);
  });

  test("tek okumada gelen birden fazla tuş sırayla çözülür", () => {
    expect(decodeKeys("jk\r")).toEqual([{ name: "j" }, { name: "k" }, { name: "enter" }]);
  });

  test("ok tuşu ile harf aynı tamponda karışmaz", () => {
    expect(decodeKeys("\x1b[Bd")).toMatchObject([{ name: "down" }, { name: "d" }]);
  });

  test("delete", () => {
    expect(decodeKeys("\x1b[3~")).toMatchObject([{ name: "delete" }]);
  });
});
