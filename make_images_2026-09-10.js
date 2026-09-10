// Visuals for the 2026-09-10 article, rendered as SVG and rasterised on an HTML canvas.
// Same numbers as make_images_2026-09-10.py: ContextContract, swift test 25/25,
// PortabilityReport(markdown: Fixture.claudeMD) over the 28-line fixture.
// Usage (browser console): const figs = window.__figs; await figs.pngs() -> {name: Blob}
(function () {
  const REPO = "github.com/rajatslakhina/agent-context-contract-article-demo";
  const F = "-apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif";
  const M = "Menlo, Consolas, 'DejaVu Sans Mono', monospace";
  const INK = "#16181d", MUTED = "#6e7480", LINE = "#d6dae2", PAPER = "#fafaf8", CARD = "#ffffff";
  const RED = "#b71c28", GREEN = "#1a7a4e", BLUE = "#0051b8", AMBER = "#bf790f", PURPLE = "#6040a8";
  const REDL = "#fbe7e9", GREENL = "#e2f4ea", BLUEL = "#e4ecfa", AMBERL = "#fcf0d6", GRAYL = "#eceef1";
  const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const text = (x, y, s, size, fill, opts = {}) =>
    `<text x="${x}" y="${y}" font-family="${opts.mono ? M : F}" font-size="${size}" fill="${fill}" font-weight="${opts.bold ? 700 : 400}" dominant-baseline="hanging" text-anchor="${opts.anchor || "start"}">${esc(s)}</text>`;
  const rect = (x, y, w, h, fill, r = 14, stroke = "none", sw = 0) =>
    `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
  const arrow = (x0, y0, x1, y1, color, w = 4) => {
    const a = Math.atan2(y1 - y0, x1 - x0), L = 16;
    const p1 = [x1 - L * Math.cos(a - 0.45), y1 - L * Math.sin(a - 0.45)], p2 = [x1 - L * Math.cos(a + 0.45), y1 - L * Math.sin(a + 0.45)];
    return `<line x1="${x0}" y1="${y0}" x2="${x1}" y2="${y1}" stroke="${color}" stroke-width="${w}"/><polygon points="${x1},${y1} ${p1.join(",")} ${p2.join(",")}" fill="${color}"/>`;
  };
  const lines = (x, y, arr, size, fill, lh, opts = {}) => arr.map((s, i) => text(x, y + i * lh, s, size, fill, opts)).join("");
  const wrapSvg = (w, h, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${rect(0, 0, w, h, PAPER, 0)}${body}</svg>`;
  const footer = (h, s) => text(80, h - 50, s, 17, MUTED, { mono: true });

  function header() {
    const W = 1600, H = 900;
    let b = rect(0, 0, W, 10, BLUE, 0);
    b += text(80, 66, "XCODE 27 RC  ·  SETTINGS → INTELLIGENCE → ADD AN AGENT…  ·  AGENT CLIENT PROTOCOL", 23, BLUE, { bold: true });
    b += text(80, 118, "Your CLAUDE.md was written", 64, INK, { bold: true });
    b += text(80, 194, "for one agent.", 64, INK, { bold: true });
    b += text(80, 272, "Xcode 27 just made the agent a dropdown.", 56, RED, { bold: true });
    b += text(80, 362, "A realistic CLAUDE.md with 28 directives, scanned. Codex reads 0 of the 28: it opens AGENTS.md, and never opens CLAUDE.md.", 23, MUTED);
    b += text(80, 395, "ACP forwards your MCP servers to whichever agent you pick. It does not forward your instructions.", 23, MUTED);
    const y = 470;
    const boxes = [
      [80, "12 / 28", ["portable → AGENTS.md"], ["any agent can act on them as written;", "43% of the file"], GREEN, GREENL],
      [590, "9 / 28", ["vendor-bound → overlays"], ["7 Claude · 1 Codex · 1 Gemini:", "tool names, slash commands,", ".claude/ paths, model names"], AMBER, AMBERL],
      [1100, "7 / 28", ["enforced by prose →", "permission layer"], ["every line under ## Rules; exactly one", "is enforced today, by a Claude-only hook"], RED, REDL]];
    for (const [x, n, t1, t2, c, bg] of boxes) {
      b += rect(x, y, 420, 320, bg);
      b += text(x + 24, y + 28, n, 72, c, { bold: true });
      b += lines(x + 24, y + 150, t1, 22, INK, 28, { bold: true });
      b += lines(x + 24, y + 150 + 28 * t1.length + 12, t2, 19, MUTED, 26);
    }
    b += footer(H, `Numbers from ContextContract · swift test 25/25 · ${REPO}`);
    return wrapSvg(W, H, b);
  }

  function split() {
    const W = 1600, H = 1000;
    let b = text(80, 44, "One file, three kinds of line. ContractCompiler puts each where its reader actually looks.", 30, INK, { bold: true });
    b += text(80, 92, "Fixture: 28 directives in CLAUDE.md for a SwiftUI app. Precedence: an enforcement claim beats vendor wording; vendor wording beats nothing.", 19, MUTED);
    const sx = 80, sy = 170;
    b += rect(sx, sy, 330, 640, CARD, 14, LINE, 2);
    b += text(sx + 24, sy + 22, "CLAUDE.md", 26, INK, { mono: true, bold: true });
    b += text(sx + 24, sy + 60, "28 directives · read by 1 of 5 agents", 17, MUTED);
    const rows = [["## Project", 7, [[7, GREEN]]], ["## Workflow", 14, [[5, GREEN], [7, AMBER], [1, PURPLE], [1, BLUE]]], ["## Rules", 7, [[7, RED]]]];
    let yy = sy + 110;
    for (const [title, n, segs] of rows) {
      b += text(sx + 24, yy, `${title}  ·  ${n} lines`, 17, INK, { mono: true, bold: true }); yy += 30;
      let xx = sx + 24;
      for (const [cnt, col] of segs) { const w = cnt * 20; b += rect(xx, yy, w - 4, 22, col, 5); xx += w; }
      yy += 44;
    }
    yy += 6;
    for (const [col, name] of [[GREEN, "portable"], [AMBER, "Claude-only"], [PURPLE, "Codex-only"], [BLUE, "Gemini-only"], [RED, "enforcement claim"]]) {
      b += rect(sx + 24, yy + 4, 20, 16, col, 4); b += text(sx + 54, yy, name, 17, MUTED); yy += 28;
    }
    b += text(sx + 24, sy + 590, "1 of 7 rules enforced today,", 16, RED);
    b += text(sx + 24, sy + 612, "by a PreToolUse hook. Claude-only.", 16, RED);
    const bx = 520, by = [190, 420, 650];
    const buckets = [["12 portable", GREEN, GREENL, ["any agent can act on them as written"]],
      ["9 vendor-bound", AMBER, AMBERL, ["only mean something to one agent"]],
      ["7 enforcement claims", RED, REDL, ["prose cannot enforce; the model", "complies or it doesn't"]]];
    buckets.forEach(([t, c, bg, sub], i) => {
      const y = by[i];
      b += rect(bx, y, 360, 150, bg);
      b += text(bx + 22, y + 22, t, 30, c, { bold: true });
      b += lines(bx + 22, y + 72, sub, 18, INK, 24);
      b += arrow(sx + 330, sy + 320, bx - 4, y + 75, c);
    });
    const dx = 1030;
    const dests = [
      [190, "AGENTS.md", GREEN, [["12 portable lines", INK], ["+ a 'Codex only' heading (1)", INK], ["+ 7 enforcement claims kept as", INK], ["   information: 'the layer in front of", INK], ["   you will refuse this'", INK], ["read by Codex, Cursor, Copilot natively;", MUTED], ["Claude via @AGENTS.md; Gemini via @./AGENTS.md", MUTED]]],
      [455, "CLAUDE.md  ·  GEMINI.md", AMBER, [["@AGENTS.md  +  7 Claude lines", INK], ["@./AGENTS.md  +  1 Gemini line", INK], ["the overlay is the lock-in, now legible", MUTED]]],
      [650, "ENFORCEMENT.md → permission layer", RED, [["7 rules, each with the layer it moves to:", INK], ["permission gate ×3 · secret redaction ×2", INK], ["path guard ×1 · build gate ×1", INK], ["status: not enforced, until the layer exists", MUTED]]]];
    for (const [y, title, c, ls] of dests) {
      const h = 60 + 26 * ls.length;
      b += rect(dx, y, 490, h, CARD, 14, c, 3);
      b += text(dx + 20, y + 16, title, 22, c, { mono: true, bold: true });
      ls.forEach(([l, col], i) => { b += text(dx + 20, y + 52 + i * 26, l, 17, col); });
    }
    b += arrow(bx + 360, by[0] + 75, dx - 4, 190 + 70, GREEN);
    b += arrow(bx + 360, by[1] + 75, dx - 4, 455 + 55, AMBER);
    b += arrow(bx + 360, by[1] + 90, dx - 4, 190 + 150, PURPLE, 3);
    b += arrow(bx + 360, by[2] + 75, dx - 4, 650 + 70, RED);
    b += footer(H, `Numbers from ContextContract · swift test 25/25 · ${REPO}`);
    return wrapSvg(W, H, b);
  }

  const CODE = [
    "// Placement.decide — where a line belongs once the file is a contract",
    "public static func decide(_ signals: [Signal]) -> Placement {",
    "    let kinds = Enforcement.allCases.filter { kind in",
    "        signals.contains { $0.enforcement == kind }",
    "    }",
    "    if !kinds.isEmpty { return .protocolLayer(kinds) }   // a claim beats vendor wording",
    "    var counts: [Vendor: Int] = [:]",
    "    for s in signals { if let v = s.vendor { counts[v, default: 0] += 1 } }",
    "    guard let best = counts.values.max(),",
    "          let winner = Vendor.allCases.first(where: { counts[$0] == best })",
    "    else { return .portable }",
    "    return .vendorOverlay(winner)",
    "}",
    "",
    "// Enforcement.mechanism — where each claim has to live before it counts",
    "case .permissionGate:",
    "    return \"The ACP `session/request_permission` handler (Xcode's permission sheet,\"",
    "         + \" or a gateway in front of the agent) denies the call. A sentence cannot.\"",
    "case .buildGate:",
    "    return \"A turn-completion gate: build and tests must pass before the agent may\"",
    "         + \" report the turn done; CI repeats the check on the PR.\""];
  const KEYWORDS = new Set(["public", "static", "func", "let", "if", "return", "var", "for", "in", "guard", "else", "case", "where"]);

  function codeCard() {
    const W = 1600, H = 80 + 34 * CODE.length + 120;
    let b = rect(0, 0, W, H, "#1e2028", 0) + rect(40, 40, W - 80, H - 80, "#282a34", 18);
    [["#ff5f56", 0], ["#ffbd2e", 1], ["#27c93f", 2]].forEach(([c, i]) => { b += `<circle cx="${80 + i * 30}" cy="72" r="10" fill="${c}"/>`; });
    b += text(170, 62, "ContextContract/Model.swift", 18, "#969baa", { mono: true });
    const cw = 12.05; // Menlo 20px advance
    CODE.forEach((line, li) => {
      const y = 110 + li * 34;
      if (line.trim().startsWith("//")) { b += text(80, y, line, 20, "#788296", { mono: true }); return; }
      const tokens = line.match(/"(?:[^"\\]|\\.)*"|\/\/.*|[A-Za-z_][A-Za-z0-9_]*|\s+|[^\sA-Za-z_]+/g) || [];
      let x = 80;
      for (const t of tokens) {
        let col = "#dcdfe4";
        if (t.startsWith('"')) col = "#d69d85"; else if (t.startsWith("//")) col = "#788296";
        else if (KEYWORDS.has(t)) col = "#c678dd"; else if (/^[A-Z]/.test(t)) col = "#e5c07b"; else if (t.startsWith(".")) col = "#61afef";
        if (t.trim()) b += `<text x="${x}" y="${y}" font-family="${M}" font-size="20" fill="${col}" dominant-baseline="hanging" xml:space="preserve">${esc(t)}</text>`;
        x += t.length * cw;
      }
    });
    b += text(80, H - 70, `${REPO} · swift test 25/25`, 16, "#969baa", { mono: true });
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${b}</svg>`;
  }

  function coverage() {
    const W = 1600, H = 960;
    const rows = [["Claude Code", 28, 26, ["reads CLAUDE.md natively ·", "AGENTS.md via @AGENTS.md"]],
      ["Codex", 0, 20, ["reads AGENTS.md natively"]],
      ["Gemini CLI", 0, 20, ["reads GEMINI.md natively ·", "AGENTS.md via @./AGENTS.md"]],
      ["Cursor", 0, 19, ["reads AGENTS.md natively"]],
      ["GitHub Copilot", 0, 19, ["reads AGENTS.md natively"]]];
    let b = text(80, 44, "Directives that reach each agent, out of 28: as written vs. compiled into a contract.", 30, INK, { bold: true });
    b += text(80, 92, "As written: CLAUDE.md is read by 1 of 5 agents. Compiled: AGENTS.md + overlays reach 5 of 5 (Claude and Gemini through a one-line import).", 19, MUTED);
    b += rect(380, 138, 24, 18, BLUEL, 4, BLUE, 2) + text(414, 136, "as written (CLAUDE.md)", 16, MUTED);
    b += rect(640, 138, 24, 18, GREENL, 4, GREEN, 2) + text(674, 136, "compiled (AGENTS.md + that agent's overlay)", 16, MUTED);
    let y = 185; const scale = 28, barmax = 880, x0 = 380;
    for (const [name, before, after, note] of rows) {
      b += text(80, y + 8, name, 22, INK, { bold: true });
      b += lines(80, y + 40, note, 14, MUTED, 18);
      const bw = Math.round(barmax * before / scale);
      b += rect(x0, y + 4, Math.max(bw, 6), 26, before === 0 ? GRAYL : BLUEL, 6, before === 0 ? "none" : BLUE, before === 0 ? 0 : 2);
      b += text(x0 + Math.max(bw, 6) + 12, y + 4, String(before), 20, before === 0 ? RED : BLUE, { bold: true });
      const aw = Math.round(barmax * after / scale);
      b += rect(x0, y + 40, aw, 26, GREENL, 6, GREEN, 2);
      b += text(x0 + aw + 12, y + 40, String(after), 20, GREEN, { bold: true });
      y += 122;
    }
    b += `<line x1="${x0}" y1="175" x2="${x0}" y2="${y - 40}" stroke="${LINE}" stroke-width="2"/>`;
    b += rect(80, y - 20, W - 160, 110, REDL);
    b += lines(104, y - 2, ["Why not 28 everywhere after compiling? Each agent gets the 12 portable lines, the 7 enforcement claims kept as information, and only its own",
      "overlay: 7 lines for Claude, 1 for Codex, 1 for Gemini, 0 for Cursor and Copilot. The other vendors' lines were never for it."], 19, INK, 26);
    b += text(80, H - 45, `Numbers from ContextContract.Coverage · swift test 25/25 · ${REPO}`, 17, MUTED, { mono: true });
    return wrapSvg(W, H, b);
  }

  function rasterize(svg) {
    return new Promise((resolve, reject) => {
      const m = svg.match(/width="(\d+)" height="(\d+)"/);
      const w = +m[1], h = +m[2];
      const img = new Image();
      img.onload = () => {
        const c = document.createElement("canvas"); c.width = w; c.height = h;
        c.getContext("2d").drawImage(img, 0, 0);
        c.toBlob(blob => blob ? resolve(blob) : reject(new Error("toBlob failed")), "image/png");
      };
      img.onerror = e => reject(new Error("svg load failed"));
      img.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg);
    });
  }

  window.__figs = {
    svgs: () => ({
      "2026-09-10-agent-context-contract-header.png": header(),
      "2026-09-10-agent-context-contract-split.png": split(),
      "2026-09-10-agent-context-contract-code-card.png": codeCard(),
      "2026-09-10-agent-context-contract-coverage.png": coverage(),
    }),
    pngs: async () => {
      const out = {}; const s = window.__figs.svgs();
      for (const k of Object.keys(s)) out[k] = await rasterize(s[k]);
      return out;
    },
  };
})();
