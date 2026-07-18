# De-AI App Design — Rules for UI That Reads as Human-Made

Synthesized from 8 videos on AI-generated design ("AI slop") and how professionals fix it. Written as enforceable audit-and-refactor rules for app UIs, weighted toward dashboards and data-heavy screens. Drop this file in the repo root (as `DESIGN.md` or a Claude Code skill) and reference it in every AI-assisted session — codifying rules like these into a file the AI must follow is itself the \#1 fix the videos converge on.

---

## 0\. The core finding

Every video lands on the same diagnosis from a different angle: **AI slop is what the statistical average of the internet looks like.** When a model gets no constraints, it outputs the most probable design — purple gradients, Inter, three feature cards, even padding, rainbow charts — because that's the center of its training distribution.

The fix is therefore never "a better prompt." It is **constraints**:

1. A codified design system (exact tokens, this file) the AI must obey.  
2. Visual references (screenshots of premium products) the AI must mimic — rhythm, spacing, density — not copy.  
3. A human-defined hierarchy (what matters on this screen) decided *before* generation, not after.  
4. Never shipping the first output. Staged passes: structure → theme → polish.

Everything below is those four ideas made concrete.

---

## 1\. Color (the priority)

### 1.1 The ban list — instant AI tells

- **Purple/violet gradients** anywhere. The single most-cited tell across the videos. Includes purple→blue, purple→pink, and radial "glow" backgrounds.  
- **Neon-blue-on-dark "fintech glow"** — dark background \+ glowing blue/cyan accents regardless of brand.  
- **Rainbow charts** — multi-hue palettes where color carries no meaning.  
- **Unmodified framework defaults** — raw Tailwind 500-weights, default shadcn/Chakra theme colors used as-is.  
- **Pure values** — `#FFFFFF` backgrounds, `#000000` text, `#808080` grays. Real palettes are always nudged off pure.  
- **The 2026-era tells** (newer than the videos, same disease): warm cream `#F4F1EA` \+ high-contrast serif \+ terracotta `#D97757` (reads specifically as Claude-generated); near-black \+ single acid-green/vermilion accent. Both are legitimate styles but are now *defaults*, not choices.

### 1.2 The positive rules

- **One brand hue, built into a full ramp.** Pick a single saturated brand color and generate a proper 10–11 step tint/shade scale from it (50→950). Every UI color derives from a step on a ramp — never an orphan hex.  
- **Tinted neutrals.** Grays lean warm or cool toward the brand hue. Never neutral-neutral gray. Backgrounds sit a few points off white (or off black in dark mode), e.g. `#FAFAF8` not `#FFFFFF`.  
- **Max \~5 colors doing work on any screen.** Brand hue \+ 2–3 semantic \+ neutrals. If a screen uses more, hierarchy has already failed.  
- **Color is reserved.** A human-designed dashboard is mostly neutral; color goes only to (a) the data, and (b) the single primary action. AI slop colors everything equally, which flattens hierarchy — restraint *is* the human tell.  
- **Semantic colors are designed, not defaults.** Success/warning/danger are desaturated, brand-adjacent versions — never pure `#FF0000` / `#00FF00` / `#FFFF00`.  
- **Exact hex codes only.** The AI never picks a color. "Use red" produces slop; "use `--danger-600: #C4483D`" produces the brand. All hexes live in this file / the token file.  
- **Contrast is a merge gate.** 4.5:1 minimum for body text, 3:1 for large text and UI components. AI-generated palettes routinely fail this on "subtle" variants — check them explicitly.  
- **Steal the palette from references, don't invent it.** Screenshot 2–3 target-quality products (Canary-class device dashboards, Linear, Grafana), extract their actual values, adapt to the brand. Premium products use specific, slightly-off colors ("carbon gray," "warm gold") — not generic hue-family names.

### 1.3 Starter token shape

/\* Brand ramp — replace hue, keep the structure \*/

\--brand-50 … \--brand-950;        /\* one hue, 11 steps \*/

/\* Tinted neutrals — biased toward brand hue temperature \*/

\--neutral-0: /\* off-white, NOT \#FFF \*/;

\--neutral-50 … \--neutral-950;

/\* Semantic — desaturated, brand-adjacent \*/

\--success-600; \--warning-600; \--danger-600;

/\* each with a \-100 surface tint for badges/alerts \*/

/\* Data-viz palette — see §4, defined separately from UI colors \*/

\--viz-1 … \--viz-5;               /\* categorical, max 5 \*/

\--viz-scale-low … \--viz-scale-high;  /\* one sequential/severity ramp \*/

---

## 2\. Typography

- **Never default to Inter.** The most-named single font tell. Generic sans-serif everywhere \= AI. Choose a deliberate pairing: one characterful display face used with restraint, one workhorse body face, optionally one utility face for data/mono numerals. Name them in this file.  
- **Complete the scale.** AI-generated systems skip tiers (H1, H2… no H3) and invent orphan sizes (a random `15px`). Define the full ladder — display, H1–H4, body, small, caption — with size, weight, line-height, and letter-spacing for each. Every text element maps to a tier; no off-scale values.  
- **Kill the "cramped eyebrow."** All-caps micro-labels with wide letter-spacing above every heading is a named slop marker. Use an eyebrow only where the label carries real information, and set its tracking deliberately.  
- **Tabular numerals for KPIs.** Dashboard numbers need `font-variant-numeric: tabular-nums` (or a mono/utility face) so figures align and don't jitter on update. Small detail, strong human tell.  
- **Type carries the personality.** If every screen would look the same with the font swapped out, the type isn't doing its job yet.

---

## 3\. Spacing & layout

- **One spacing scale, zero orphans.** 4px- or 8px-based scale, tokenized. Uneven padding inside buttons/cards — a top-cited tell — comes from orphan values. Every margin/padding is a token.  
- **Asymmetric, generous white space beats uniform padding.** AI defaults to even padding everywhere. Premium human interfaces use deliberate asymmetry — more space above a section title than below it, breathing room around the hero metric, tighter grouping for related items. Space *encodes grouping*.  
- **The dashboard follows the F-pattern** (from the data-viz video; applies to any KPI or monitoring dashboard):  
  1. KPI summary cards across the top — the "is everything okay?" row.  
  2. Primary chart top-left — the most important trend, where the eye lands first.  
  3. Supporting charts below/right.  
  4. Detail tables at the bottom — for the user who wants to drill in.  
- **The layout tells a story, not a wall.** Setup (what's normal?) → tension (what's off?) → insight (why?) → action (what now?). If charts are placed "wherever they fit," it reads as generated. Every widget must answer a question a real user has; if you can't name the question, cut the widget.  
- **Structure encodes information.** Numbered markers, dividers, section labels only where the content genuinely is a sequence or grouping. Decorative structure is slop.  
- **Density is a choice.** Device-monitoring users scan repeatedly; err toward a calm, information-dense-but-ordered layout (Canary-like) over a sparse marketing-page look.

---

## 4\. Charts & data visualization

The dashboard-specific rules, from the data-viz video (Tufte/Knaflic-derived) plus the component videos:

- **Maximize data-ink ratio.** Every pixel earns its place. Remove: chart borders, heavy gridlines (keep faint horizontal ones only if values must be read precisely), axis lines that duplicate gridlines, drop shadows, background fills, redundant legends (label lines directly where possible).  
- **Chart choice is semantic, not decorative:**  
  - Trend over time → line.  
  - Comparison across categories → horizontal bar.  
  - Correlation → scatter.  
  - Part-of-whole → pie **only if ≤4 categories**; otherwise a bar. Never 3D. Never donut-with-12-slices.  
- **The viz palette is separate from the UI palette** and capped at 5 categorical colors. Series colors carry meaning consistently across the whole app — if "offline" is `--danger-600` in one chart, it's that everywhere.  
- **Severity/state uses a designed ramp** (e.g. calm neutral → brand → warning → danger), not a rainbow. For device monitoring this is the core visual language: healthy should be visually quiet, anomalies loud.  
- **Context makes it human.** Add reference lines (target, previous period, SLA threshold) and annotations on anomalies. A bare line chart is generated; a chart that says "this is where the incident started" is designed.  
- **Interactivity comes last.** Build the static dashboard until it reads clearly with zero interaction, then layer filters/cross-filtering. Filters bolted on first are a slop marker.

---

## 5\. Components & states

- **Full state coverage is mandatory.** AI-generated components ship happy-path only. Every interactive component defines: default, hover, active, focus (visible\!), disabled — plus variants actually needed (danger, ghost). Missing states are a top "incomplete system" tell.  
- **One radius system.** Pick the corner-radius scale (e.g. 4/8/12) and apply it consistently. Radius drift across components — or the wrong roundness for the brand — is a named tell.  
- **Delete decoration that serves no function:** "Live" badge dots placed randomly, floating particles, sparkle icons (the Lucide sparkle specifically is a meme-level tell), glowing borders, status indicators without information architecture behind them.  
- **Icons: one family, deliberate weight.** If using Lucide, curate — consistent stroke width, no default AI/robot/sparkle glyphs. Custom or adjusted icons for the 3–4 concepts core to the product (for a monitoring app: devices, alerts, health) buy disproportionate humanity.  
- **Consistency across screens is enforced, not hoped for.** AI "drifts" — new pages forget the radius, shade, or font weight established earlier. Every new screen gets audited against the token file before merge.

---

## 6\. Copy & content

- **Copy is design material.** Verbose AI headlines and descriptions are a named tell. Constrain length explicitly ("max 2 lines"), prefer plain verbs, sentence case, no filler.  
- **Buttons say exactly what happens** — "Save changes," not "Submit." The same action keeps the same name everywhere ("Publish" → toast says "Published").  
- **No hallucinated numbers.** Stats without context ("0.1s average transaction time") read as generated. Every number shown comes from real data and carries context (vs. what? since when?).  
- **Errors and empty states are directions, not moods.** Say what went wrong and what to do; an empty screen invites the first action. No apologetic or vague system voice.  
- **No stock-photo energy.** Generic Unsplash imagery, default robot/circuit illustrations. For a monitoring dashboard the data IS the imagery — invest in chart quality over decorative images.

---

## 7\. Process rules (how to work with AI without regressing)

1. **This file is the contract.** Reference it (or its token file) in every AI session. The videos converge on this exact mechanism: DESIGN.md / Claude skill with exact hexes, type rules, and layout constraints.  
2. **Reference-first, never blank-page.** Keep a `/references/` folder with screenshots of target-quality dashboards (Canary, Linear, Grafana — the density and restraint tier to aim for). Instruct: "mimic the rhythm, spacing, and density of these — do not copy them."  
3. **Never accept the first output.** First generation \= the average of the internet. Treat it as a wireframe.  
4. **Staged passes, one axis at a time:** structure/layout first → then color tokens → then typography → then micro-polish (transitions, states). Changing everything at once makes drift undetectable.  
5. **Human decides hierarchy before generation.** For each screen, write one sentence: "The single most important thing on this screen is \_\_\_." Sketch the layout (paper/Excalidraw) before prompting.  
6. **Audit gates before merge:** contrast ratios pass; all text on the type scale; all spacing on the token scale; all states present; no banned colors (§1.1); new screen matches existing screens' tokens.  
7. **Spend boldness in one place.** Pick the product's one signature element — the thing a user would remember (e.g. the device-health severity ramp, a distinctive KPI card treatment) — and keep everything else quiet and disciplined. One deliberate risk reads as designed; five reads as generated.

---

## 8\. Quick audit checklist (print this)

- [ ] No purple gradients, neon glows, rainbow charts, or pure \#FFF/\#000/\#808080  
- [ ] Every color traces to a token on a ramp; neutrals are tinted  
- [ ] ≤5 working colors per screen; color reserved for data \+ primary action  
- [ ] Contrast: 4.5:1 body, 3:1 large/UI — including "subtle" variants  
- [ ] Not Inter-by-default; full type scale, no orphan sizes; tabular numerals on KPIs  
- [ ] All spacing on the scale; asymmetric, grouping-driven white space  
- [ ] F-pattern: KPIs top → primary chart top-left → support → tables  
- [ ] Every widget answers a nameable user question  
- [ ] Charts: no chart junk; ≤5 categorical colors; reference lines/annotations present  
- [ ] Components: hover/active/focus/disabled all defined; one radius system  
- [ ] No sparkle icons, decorative badges, particles, functionless glow  
- [ ] Copy: plain verbs, length-capped, no hallucinated stats  
- [ ] New screens audited against tokens (no drift)  
- [ ] One signature element; everything else quiet

