// Lab Pixel Gallery demo — locked palette, slime variants, coin anim, tiles.
pal({
  k: "#1b1630",
  g: "#8ccf63",
  G: "#4c8a44",
  t: "#2a5560",
  w: "#fff6e0",
  r: "#e2585e",
  R: "#a63a4c",
  b: "#5b8def",
  B: "#3a5fad",
  o: "#e8b84a",
  O: "#c48a2a",
  p: "#9b59b6",
  P: "#6c3483",
  s: "#8b7355",
  S: "#5c4a38",
  d: "#6b5344",
})
ramps("ktGg", "kRr", "kbB", "kOo", "kpP", "kSs")

sprite("slime", { mx: true, outline: "k" }, `
  ....ggg
  ..ggGGg
  .ggGwGg
  .gggggg
  gggkwgg
  gggkkgg
  tgggggg
  .tttttt`)

sprite("slime_red", { base: "slime", swap: { g: "r", G: "R", t: "R" } })
sprite("slime_blue", { base: "slime", swap: { g: "b", G: "B", t: "B" } })

sprite("heart", { mx: "c", outline: "k" }, `
  .rr.
  rwrr
  rrrr
  rrrr
  .rrr
  ..rr
  ...r`)

sprite("chest", { w: 16, h: 12, outline: "k" },
  rect(0, 3, 16, 9, "O"),
  rect(0, 0, 16, 4, "o"),
  hline(0, 4, 16, "k"),
  vline(3, 0, 12, "O"),
  vline(12, 0, 12, "O"),
  rect(7, 5, 2, 2, "w"),
  shade([0, 9, 16, 3]))

sprite("potion", { w: 10, h: 14, outline: "k" },
  rect(3, 0, 4, 3, "w"),
  rect(2, 3, 6, 2, "t"),
  circ(4, 9, 4, "p"),
  circ(4, 9, 3, "P"),
  px(3, 7, "w"),
  glow("pP", { r: 3, strength: 0.4, bands: 2 }))

sprite("tile_grass", { w: 16, h: 16 },
  rect(0, 0, 16, 16, "G"),
  noise(0, 0, 16, 16, "g", 0.12, 3, "G"),
  hline(0, 0, 16, "g"))

sprite("tile_dirt", { w: 16, h: 16 },
  rect(0, 0, 16, 16, "d"),
  noise(0, 0, 16, 16, "s", 0.08, 5),
  dither(0, 12, 16, 4, "d", "S", 0.35))

sprite("tile_stone", { w: 16, h: 16 },
  rect(0, 0, 16, 16, "t"),
  box(1, 1, 6, 5, "k"),
  box(8, 2, 7, 6, "k"),
  box(2, 8, 8, 6, "k"),
  light([4, 3, 2], 1, 0.5))

anim("coin_spin", { w: 12, h: 12, frames: 6, fps: 10, outline: "k" }, (c) => {
  const t = c.phase * Math.PI * 2
  const rx = Math.max(1, Math.round(5 * Math.abs(Math.cos(t))))
  c.ellipse(6, 6, rx, 5, "o")
  c.ellipse(6, 6, Math.max(0, rx - 1), 4, "O")
  if (rx >= 3) c.vline(6, 3, 6, "o")
  if (rx >= 4) c.px(5, 3, "w")
})

sheet("demo_sprites", [
  "slime", "slime_red", "slime_blue",
  "heart", "chest", "potion",
  "tile_grass", "tile_dirt", "tile_stone",
], { cols: 3, pad: 1 })
