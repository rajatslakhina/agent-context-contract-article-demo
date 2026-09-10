#!/usr/bin/env python3
"""Visuals for the 2026-09-10 article: Xcode 27 made your coding agent a dropdown.
Every number comes from ContextContract (swift test 25/25): PortabilityReport(markdown: Fixture.claudeMD),
Coverage(report:sourceFile:) and ContractCompiler.compile(_:project:) over the 28-line fixture."""
import sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1]
F = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FM = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
FMB = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
INK=(22,24,29); MUTED=(110,116,128); LINE=(214,218,226); PAPER=(250,250,248); CARD=(255,255,255)
RED=(183,28,40); GREEN=(26,122,78); BLUE=(0,81,184); AMBER=(191,121,15); PURPLE=(96,64,168)
REDL=(251,231,233); GREENL=(226,244,234); BLUEL=(228,236,250); AMBERL=(252,240,214); GRAYL=(236,238,241); PURPLEL=(236,230,250)
def f(p,s): return ImageFont.truetype(p,s)
def save(im,path): im.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)
def card(d,box,r=14,fill=CARD,outline=LINE,w=2): d.rounded_rectangle(box,radius=r,fill=fill,outline=outline,width=w)
def wrap(d,xy,text,font,fill,width,lh):
    x,y=xy; line=""
    for w in text.split(" "):
        t=(line+" "+w).strip()
        if d.textlength(t,font=font)>width: d.text((x,y),line,font=font,fill=fill); y+=lh; line=w
        else: line=t
    d.text((x,y),line,font=font,fill=fill); return y+lh
def arrow(d,x0,y0,x1,y1,color,w=4):
    d.line((x0,y0,x1,y1),fill=color,width=w)
    import math
    a=math.atan2(y1-y0,x1-x0); L=16
    p1=(x1-L*math.cos(a-0.45),y1-L*math.sin(a-0.45)); p2=(x1-L*math.cos(a+0.45),y1-L*math.sin(a+0.45))
    d.polygon([(x1,y1),p1,p2],fill=color)

REPO="github.com/rajatslakhina/agent-context-contract-article-demo"
TOTAL=28; PORTABLE=12; VENDOR=9; ENFORCE=7
COVERAGE=[("Claude Code",28,26,"reads CLAUDE.md natively · AGENTS.md via @AGENTS.md"),
          ("Codex",0,20,"reads AGENTS.md natively"),
          ("Gemini CLI",0,20,"reads GEMINI.md natively · AGENTS.md via @./AGENTS.md"),
          ("Cursor",0,19,"reads AGENTS.md natively"),
          ("GitHub Copilot",0,19,"reads AGENTS.md natively")]

def header():
    W,H=1600,900; im=Image.new("RGB",(W,H),PAPER); d=ImageDraw.Draw(im)
    d.rectangle((0,0,W,10),fill=BLUE)
    d.text((80,66),"XCODE 27 RC  ·  SETTINGS → INTELLIGENCE → ADD AN AGENT…  ·  AGENT CLIENT PROTOCOL",font=f(FB,23),fill=BLUE)
    d.text((80,120),"Your CLAUDE.md was written",font=f(FB,62),fill=INK)
    d.text((80,195),"for one agent.",font=f(FB,62),fill=INK)
    d.text((80,270),"Xcode 27 just made the agent a dropdown.",font=f(FB,54),fill=RED)
    d.text((80,360),"A realistic CLAUDE.md with 28 directives, scanned. Codex reads 0 of the 28: it opens AGENTS.md, and never opens CLAUDE.md.",font=f(F,23),fill=MUTED)
    d.text((80,393),"ACP forwards your MCP servers to whichever agent you pick. It does not forward your instructions.",font=f(F,23),fill=MUTED)
    y=470
    boxes=[(80,f"{PORTABLE} / {TOTAL}","portable → AGENTS.md","any agent can act on them as written; 43% of the file",GREEN,GREENL),
           (590,f"{VENDOR} / {TOTAL}","vendor-bound → overlays","7 Claude · 1 Codex · 1 Gemini: tool names, slash commands, .claude/ paths, models",AMBER,AMBERL),
           (1100,f"{ENFORCE} / {TOTAL}","enforced by prose → permission layer","every line under ## Rules; exactly one is enforced today, by a Claude-only hook",RED,REDL)]
    for x,n,t1,t2,c,bg in boxes:
        card(d,(x,y,x+420,y+320),fill=bg,outline=bg)
        d.text((x+24,y+30),n,font=f(FB,72),fill=c)
        wrap(d,(x+24,y+150),t1,f(FB,22),INK,372,28)
        wrap(d,(x+24,y+215),t2,f(F,19),MUTED,372,26)
    d.text((80,H-50),f"Numbers from ContextContract · swift test 25/25 · {REPO}",font=f(FM,17),fill=MUTED)
    save(im,f"{OUT}/2026-09-10-agent-context-contract-header.png")

def split():
    W,H=1600,1000; im=Image.new("RGB",(W,H),PAPER); d=ImageDraw.Draw(im)
    d.text((80,44),"One file, three kinds of line. ContractCompiler puts each where its reader actually looks.",font=f(FB,30),fill=INK)
    d.text((80,92),"Fixture: 28 directives in CLAUDE.md for a SwiftUI app. Precedence: an enforcement claim beats vendor wording; vendor wording beats nothing.",font=f(F,19),fill=MUTED)
    # source card
    sx,sy=80,170
    card(d,(sx,sy,sx+330,sy+640),fill=CARD)
    d.text((sx+24,sy+22),"CLAUDE.md",font=f(FMB,26),fill=INK)
    d.text((sx+24,sy+60),"28 directives · read by 1 of 5 agents",font=f(F,17),fill=MUTED)
    rows=[("## Project",7,[(7,GREEN)]),("## Workflow",14,[(5,GREEN),(7,AMBER),(1,PURPLE),(1,BLUE)]),("## Rules",7,[(7,RED)])]
    yy=sy+110
    for title,n,segs in rows:
        d.text((sx+24,yy),f"{title}  ·  {n} lines",font=f(FMB,17),fill=INK); yy+=30
        xx=sx+24
        for cnt,col in segs:
            w=cnt*20
            d.rounded_rectangle((xx,yy,xx+w-4,yy+22),radius=5,fill=col); xx+=w
        yy+=44
    yy+=6
    legend=[(GREEN,"portable"),(AMBER,"Claude-only"),(PURPLE,"Codex-only"),(BLUE,"Gemini-only"),(RED,"enforcement claim")]
    for col,name in legend:
        d.rounded_rectangle((sx+24,yy+4,sx+44,yy+20),radius=4,fill=col); d.text((sx+54,yy),name,font=f(F,17),fill=MUTED); yy+=28
    d.text((sx+24,sy+590),"1 of 7 rules enforced today,",font=f(F,16),fill=RED)
    d.text((sx+24,sy+612),"by a PreToolUse hook. Claude-only.",font=f(F,16),fill=RED)
    # buckets (middle)
    bx=520; by=[190,420,650]
    buckets=[(f"{PORTABLE} portable",GREEN,GREENL,"any agent can act on them as written"),
             (f"{VENDOR} vendor-bound",AMBER,AMBERL,"only mean something to one agent"),
             (f"{ENFORCE} enforcement claims",RED,REDL,"prose cannot enforce; the model complies or it doesn't")]
    for (t,c,bg,sub),y in zip(buckets,by):
        card(d,(bx,y,bx+360,y+150),fill=bg,outline=bg)
        d.text((bx+22,y+22),t,font=f(FB,30),fill=c)
        wrap(d,(bx+22,y+72),sub,f(F,18),INK,316,24)
        arrow(d,sx+330,sy+320,bx-4,y+75,c)
    # destinations (right)
    dx=1030
    dests=[(190,"AGENTS.md",GREEN,GREENL,["12 portable lines","+ a 'Codex only' heading (1)","+ 7 enforcement claims kept as","   information: 'the layer in front of","   you will refuse this'","read by Codex, Cursor, Copilot natively;","Claude via @AGENTS.md; Gemini via @./AGENTS.md"]),
           (455,"CLAUDE.md  ·  GEMINI.md",AMBER,AMBERL,["@AGENTS.md  +  7 Claude lines","@./AGENTS.md  +  1 Gemini line","the overlay is the lock-in, now legible"]),
           (650,"ENFORCEMENT.md → permission layer",RED,REDL,["7 rules, each with the layer it moves to:","permission gate ×3 · secret redaction ×2","path guard ×1 · build gate ×1","status: not enforced, until the layer exists"])]
    for y,title,c,bg,lines in dests:
        h=60+26*len(lines)
        card(d,(dx,y,dx+490,y+h),fill=CARD,outline=c,w=3)
        d.text((dx+20,y+16),title,font=f(FMB,22),fill=c)
        yy=y+52
        for l in lines: d.text((dx+20,yy),l,font=f(F,17),fill=INK if not l.startswith("read by") and not l.startswith("Claude via") and not l.startswith("the overlay") and not l.startswith("status") else MUTED); yy+=26
    arrow(d,bx+360,by[0]+75,dx-4,190+70,GREEN)
    arrow(d,bx+360,by[1]+75,dx-4,455+55,AMBER)
    arrow(d,bx+360,by[1]+90,dx-4,190+150,PURPLE,w=3)
    arrow(d,bx+360,by[2]+75,dx-4,650+70,RED)
    d.text((80,H-50),f"Numbers from ContextContract · swift test 25/25 · {REPO}",font=f(FM,17),fill=MUTED)
    save(im,f"{OUT}/2026-09-10-agent-context-contract-split.png")

CODE = '''// Placement.decide — where a line belongs once the file is a contract
public static func decide(_ signals: [Signal]) -> Placement {
    let kinds = Enforcement.allCases.filter { kind in
        signals.contains { $0.enforcement == kind }
    }
    if !kinds.isEmpty { return .protocolLayer(kinds) }   // a claim beats vendor wording
    var counts: [Vendor: Int] = [:]
    for s in signals { if let v = s.vendor { counts[v, default: 0] += 1 } }
    guard let best = counts.values.max(),
          let winner = Vendor.allCases.first(where: { counts[$0] == best })
    else { return .portable }
    return .vendorOverlay(winner)
}

// Enforcement.mechanism — where each claim has to live before it counts
case .permissionGate:
    return "The ACP `session/request_permission` handler (Xcode's permission sheet,"
         + " or a gateway in front of the agent) denies the call. A sentence cannot."
case .buildGate:
    return "A turn-completion gate: build and tests must pass before the agent may"
         + " report the turn done; CI repeats the check on the PR."'''

KEYWORDS={"public","static","func","let","if","return","var","for","in","guard","else","case","where"}
def code_card():
    lines=CODE.split("\n"); W,H=1600,80+34*len(lines)+120
    im=Image.new("RGB",(W,H),(30,32,40)); d=ImageDraw.Draw(im)
    d.rounded_rectangle((40,40,W-40,H-40),radius=18,fill=(40,42,52))
    for i,col in enumerate([(255,95,86),(255,189,46),(39,201,63)]): d.ellipse((70+i*30,62,90+i*30,82),fill=col)
    d.text((170,60),"ContextContract/Model.swift",font=f(FM,18),fill=(150,155,170))
    mono=f(FM,20); y=110
    import re
    for line in lines:
        x=80
        if line.strip().startswith("//"):
            d.text((x,y),line,font=mono,fill=(120,130,150)); y+=34; continue
        tokens=re.findall(r'"(?:[^"\\]|\\.)*"|//.*|[A-Za-z_][A-Za-z0-9_]*|\s+|[^\sA-Za-z_]+',line)
        for t in tokens:
            if t.startswith('"'): col=(214,157,133)
            elif t.startswith("//"): col=(120,130,150)
            elif t in KEYWORDS: col=(198,120,221)
            elif t[:1].isupper(): col=(229,192,123)
            elif t.startswith("."): col=(97,175,239)
            else: col=(220,223,228)
            d.text((x,y),t,font=mono,fill=col); x+=d.textlength(t,font=mono)
        y+=34
    d.text((80,H-70),f"{REPO} · swift test 25/25",font=f(FM,16),fill=(150,155,170))
    save(im,f"{OUT}/2026-09-10-agent-context-contract-code-card.png")

def coverage():
    W,H=1600,960; im=Image.new("RGB",(W,H),PAPER); d=ImageDraw.Draw(im)
    d.text((80,44),"Directives that reach each agent, out of 28: as written vs. compiled into a contract.",font=f(FB,30),fill=INK)
    d.text((80,92),"As written: CLAUDE.md is read by 1 of 5 agents. Compiled: AGENTS.md + overlays reach 5 of 5 (Claude and Gemini through a one-line import).",font=f(F,19),fill=MUTED)
    # legend
    d.rounded_rectangle((380,138,404,156),radius=4,fill=BLUEL,outline=BLUE,width=2); d.text((414,136),"as written (CLAUDE.md)",font=f(F,16),fill=MUTED)
    d.rounded_rectangle((640,138,664,156),radius=4,fill=GREENL,outline=GREEN,width=2); d.text((674,136),"compiled (AGENTS.md + that agent's overlay)",font=f(F,16),fill=MUTED)
    y=185; scale=28.0; barmax=880; x0=380
    for name,before,after,note in COVERAGE:
        d.text((80,y+8),name,font=f(FB,22),fill=INK)
        wrap(d,(80,y+40),note,f(F,14),MUTED,270,18)
        bw=int(barmax*before/scale)
        d.rounded_rectangle((x0,y+4,x0+max(bw,6),y+30),radius=6,fill=GRAYL if before==0 else BLUEL,outline=None if before==0 else BLUE,width=2)
        d.text((x0+max(bw,6)+12,y+4),f"{before}",font=f(FB,20),fill=RED if before==0 else BLUE)
        aw=int(barmax*after/scale)
        d.rounded_rectangle((x0,y+40,x0+aw,y+66),radius=6,fill=GREENL,outline=GREEN,width=2)
        d.text((x0+aw+12,y+40),f"{after}",font=f(FB,20),fill=GREEN)
        y+=122
    d.line((x0,175,x0,y-40),fill=LINE,width=2)
    card(d,(80,y-20,W-80,y+90),fill=REDL,outline=REDL)
    wrap(d,(104,y-2),"Why not 28 everywhere after compiling? Each agent gets the 12 portable lines, the 7 enforcement claims kept as information, and only its own overlay: 7 lines for Claude, 1 for Codex, 1 for Gemini, 0 for Cursor and Copilot. The other vendors' lines were never for it.",f(F,19),INK,W-210,26)
    d.text((80,H-45),f"Numbers from ContextContract.Coverage · swift test 25/25 · {REPO}",font=f(FM,17),fill=MUTED)
    save(im,f"{OUT}/2026-09-10-agent-context-contract-coverage.png")

header(); split(); code_card(); coverage()
print("ok")
