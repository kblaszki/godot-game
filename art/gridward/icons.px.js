// Gridward tower build-bar icons. Locked to the lab pixel_demo palette.
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
  c: "#d7f4ff",
  o: "#e8b84a",
  O: "#c48a2a",
  p: "#9b59b6",
  P: "#6c3483",
  s: "#8b7355",
  S: "#5c4a38",
  d: "#6b5344",
  n: "#c5d0d8",
})
ramps("ktn", "kbBc", "kOo", "kPp", "kSs")

sprite("bolt", { w: 16, h: 16, outline: "k" }, (canvas) => {
  canvas.poly([10, 1, 14, 1, 9, 8, 12, 8, 3, 15, 7, 9, 4, 9, 9, 1], "o")
  canvas.poly([11, 2, 13, 2, 9, 7, 11, 7, 6, 12, 8, 8, 6, 8, 10, 2], "O")
  canvas.px(12, 2, "w")
})

sprite("mortar", { w: 16, h: 16, outline: "k" }, (canvas) => {
  canvas.rect(3, 11, 10, 3, "S")
  canvas.rect(4, 12, 8, 1, "s")
  canvas.rect(6, 4, 4, 8, "d")
  canvas.rect(7, 5, 2, 6, "O")
  canvas.rect(5, 3, 6, 2, "o")
  canvas.px(8, 2, "w")
  canvas.shade([3, 13, 10, 1])
})

sprite("frost", { w: 16, h: 16, outline: "k" }, (canvas) => {
  canvas.hline(2, 8, 12, "b")
  canvas.vline(8, 2, 12, "b")
  canvas.line(3, 3, 13, 13, "B")
  canvas.line(13, 3, 3, 13, "B")
  canvas.circ(8, 8, 2, "c")
  canvas.px(8, 8, "w")
  canvas.px(8, 2, "c")
  canvas.px(8, 13, "B")
  canvas.px(2, 8, "c")
  canvas.px(13, 8, "B")
})

sprite("flak", { w: 16, h: 16, outline: "k" }, (canvas) => {
  canvas.circ(8, 8, 5, "t")
  canvas.circ(8, 8, 3, "n")
  canvas.circ(8, 8, 1, "w")
  canvas.px(8, 1, "n")
  canvas.px(8, 14, "n")
  canvas.px(1, 8, "n")
  canvas.px(14, 8, "n")
  canvas.px(3, 3, "o")
  canvas.px(12, 3, "o")
  canvas.px(3, 12, "O")
  canvas.px(12, 12, "O")
})

sprite("beam", { w: 16, h: 16, outline: "k" }, (canvas) => {
  canvas.rect(6, 1, 4, 14, "P")
  canvas.rect(7, 1, 2, 14, "p")
  canvas.vline(8, 2, 12, "w")
  canvas.rect(4, 6, 8, 4, "p")
  canvas.px(5, 7, "w")
  canvas.px(10, 8, "P")
})

sheet("icons", ["bolt", "mortar", "frost", "flak", "beam"], { cols: 5, pad: 1 })
