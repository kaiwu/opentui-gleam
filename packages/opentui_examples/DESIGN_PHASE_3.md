# Phase 3 Design — Editor, Text Tooling, Rich Runtime Features

**Status: complete.** All 12 demos implemented, 56 tests passing.

Phase 3 answers the question: can the FP composability model from phases 1–2 scale
to demos that require real domain logic — tokenizers, parsers, selection models,
table formatters, plugin systems?  The answer is yes, and the key insight is that
all of it lives in a single pure module (`phase3_model.gleam`) with zero FFI calls.

---

## Design principle

**Think in FP composability — it's our edge for highly sophisticated TUI.**

Every phase 3 demo follows the same architecture:

```
event → pure state transition → pure view function → render
```

The domain logic (tokenizing code, parsing markdown, formatting tables, managing
selections) is modeled as algebraic data types and pure functions.  The rendering
layer — whether Element-based or buffer-based — is a thin translation of that data
into visual output.  No reconciler, no virtual DOM, no subscriptions.

---

## Foundation enrichment (pre-demo work)

Before implementing demos, we enriched the core/runtime/ui packages:

### `opentui_core`

- Added `textBufferGetPlainTextAsString` to `ffi_shim.js` — mirrors the existing
  `editBufferGetTextAsString` pattern with a growing buffer for string extraction.
- Added the matching binding in `ffi.gleam`.
- Expanded tests from 1 placeholder to 7 real tests: renderer lifecycle, buffer
  lifecycle, text_buffer ops, edit_buffer cursor, syntax_style register, opaque
  type roundtrips.

### `opentui_runtime`

Two new modules created as phase 3 prerequisites:

- **`text_buffer.gleam`** — Wraps core TextBuffer FFI with ergonomic API:
  `create(WidthMethod)`, `destroy`, `append`, `clear`, `length`, `text`.
  4 tests.

- **`syntax_style.gleam`** — Wraps core SyntaxStyle FFI:
  `create`, `destroy`, `register(style, name, fg, bg, attributes)`.
  2 tests.

Existing test suites expanded: `text_test` (3 → 11), `edit_buffer_test` (1 → 5).

### `opentui_ui`

Test suite expanded from 5 to 17 tests covering Element rendering, style
application, Box/Column/Row layout, and Paragraph wrapping.

---

## The pure model: `phase3_model.gleam`

The heart of phase 3.  ~690 lines, zero imports from `opentui_core` or
`opentui_runtime`.  Everything is `gleam/list`, `gleam/string`, `gleam/int`.

### Domain types

| Type | Purpose | Used by |
|---|---|---|
| `LogLevel`, `LogEntry` | Structured logging with bounded FIFO | `console_demo` |
| `Selection` | Anchor/focus cursor pair, bidirectional | `text_selection_demo` |
| `TokenStyle`, `Token` | Keyword-based lexer output | `hast_syntax_highlighting_demo`, `code_demo` |
| `Alignment` | Left/center/right column alignment | `text_table_demo` |
| `DiffKind`, `DiffLine` | Unified diff classification | `diff_demo` |
| `MdBlock` | Markdown AST (heading, paragraph, code, bullet, hrule) | `markdown_demo` |
| `Extmark` | Virtual range with label, atomic skip | `extmarks_demo` |
| `Slot` | Named boolean toggle for higher-order composition | `core_plugin_slots_demo` |

### Key functions

**Log operations**: `append_entry`, `format_entry`, `level_label`, `level_color_index`
— Bounded FIFO append with `keep_last_entries` that drops oldest entries beyond `max`.

**Selection algebra**: `selection_range` (normalize to lo/hi), `extend_selection` (move
focus, keep anchor), `collapse_selection` (anchor = focus), `selection_contains`,
`selection_length` — Selection as a value type, not mutable cursor state.

**Tokenizer**: `tokenize` — Hand-written character-by-character lexer.  Classifies
Gleam source into Keyword, StringLit, Comment, Punctuation, Number, Normal tokens.
Handles `//` line comments, `"string"` literals, punctuation characters.
`token_text` reconstitutes the original string from tokens.

**Table formatter**: `column_widths` (scan headers + rows for max per column),
`pad_cell` (left/right/center padding), `format_row`, `format_separator`,
`format_table_top`, `format_table_bottom`, `format_table` — Produces a `List(String)`
of box-drawn table lines.  Pure data in, pure strings out.

**Diff parser**: `parse_unified_diff` — Classifies each line as Added (`+`), Removed
(`-`), DiffHeader (`@@`), or Context (` `).  Returns `List(DiffLine)` with line numbers.
`diff_prefix` maps kind back to the prefix character.

**Markdown parser**: `parse_markdown_blocks` — Line-by-line parser producing
`List(MdBlock)`.  Handles `# headings`, ```` ```code blocks``` ````, `- bullet lists`,
`---` horizontal rules, and paragraph aggregation.  Uses a `pending` accumulator for
multi-line paragraphs flushed on block boundaries.

**Extmark logic**: `extmarks_at` (filter marks containing a position), `skip_extmark`
(jump to end/start of mark atomically), `extmark_label_at` (first mark's label).

**ASCII art**: `ascii_big` — Lookup table for A-Z, 0-9, space, `!` as 5×5 block
characters.  `ascii_banner` — Compose glyphs side-by-side across 5 rows.

**Slot composition**: `active_slots` (filter enabled), `toggle_slot` (flip by name),
`slot_names` (extract names) — Higher-order composition: each slot maps to a render
function, and the active set determines the assembled layout.

### Test coverage

36 tests in `opentui_phase3_model_test.gleam` covering: log operations, selection
operations, tokenizer, table formatting, diff parsing, markdown parsing, extmark
logic, ASCII art rendering, slot composition.

---

## Mutable state: `phase3_state.gleam`

Phase 3 adds `StringCell` to phase 2's `IntCell` / `BoolCell`:

```gleam
pub type StringCell
pub fn create_string(initial: String) -> StringCell
pub fn get_string(cell: StringCell) -> String
pub fn set_string(cell: StringCell, value: String) -> Nil
```

JS implementation: `{ value: initial }` — same `phase2_state.js` pattern.
Only used by `console_demo` for the accumulated log text.

---

## Two rendering approaches

Phase 3 uses both rendering patterns established in earlier phases:

### Element-based (`run_interactive_ui_demo`)

The view function returns `List(ui.Element)`.  The framework walks the tree and
renders it.  Used when the demo's visual output maps cleanly to the Element ADT
(boxes, text lines, paragraphs).

**Demos using this approach**: `text_table_demo`, `text_selection_demo`,
`markdown_demo`, `ascii_font_selection_demo`, `extmarks_demo`,
`input_select_layout_demo`, `live_state_demo`, `core_plugin_slots_demo`,
`console_demo`.

### Buffer-based (`run_interactive_demo`)

The draw function receives `ffi.Buffer` and calls `buffer.draw_text` /
`buffer.set_cell` directly.  Used when the demo needs per-character color
control — `ui.Element` does not support inline spans (one Text element = one
color), so demos requiring per-token coloring drop to the buffer level.

**Demos using this approach**: `hast_syntax_highlighting_demo`, `code_demo`,
`diff_demo`.

The choice is pragmatic: Element trees are more composable, buffer drawing gives
more control.  The demo picks whichever fits.

---

## The twelve demos

### Console Demo (`console_demo.gleam`)

Mouse-clickable log buttons using the hit grid pattern from phase 2.  Each button
click appends a `LogEntry` to a bounded FIFO.  The log text is stored in a
`StringCell`, formatted via `format_entry`, and rendered as colored Element lines.
Log level determines color (blue=debug, green=info, orange=warn, pink=error).

**FP pattern**: Event (mouse click) → pure `append_entry` → pure view of log text.
The `StringCell` holds serialized log text, not structured data — format on write,
display on read.

### Text Table Demo (`text_table_demo.gleam`)

Four alignment modes (all-left, mixed, all-right, all-center) cycled via arrow keys.
`format_table` produces complete box-drawn table lines from headers + rows + alignments.
The view just maps lines to `common.line()` elements.

**FP pattern**: Alignment is a value.  `format_table(headers, rows, aligns)` is a
pure function.  Changing alignment = calling the same function with different data.

### Text Selection Demo (`text_selection_demo.gleam`)

`Selection(anchor, focus)` as data.  Arrow keys move both cursor and anchor (collapse).
Shift+L/H extends the selection (moves focus, keeps anchor).  `c` collapses.
Selected characters rendered with `[c]` brackets, cursor as `█`.

**FP pattern**: Selection is a value type with algebraic operations (`extend`,
`collapse`, `contains`, `range`).  No mutable selection object — just two IntCells
for anchor and focus, reconstructed as a `Selection` value each frame.

### HAST Syntax Highlighting Demo (`hast_syntax_highlighting_demo.gleam`)

Keyword-based tokenizer → per-token `buffer.draw_text` with distinct colors.
Keywords bold-blue, strings green, comments muted-italic, numbers orange,
punctuation gray.  Scrollable code view with info panel.

**FP pattern**: `tokenize(line)` is pure.  `draw_tokens` is a fold over the
token list, advancing `x` by each token's text length.  The tokenizer has no
state — it classifies one line at a time from character list to token list.

### Code Demo (`code_demo.gleam`)

Extends the syntax highlighting demo with line numbers, gutter separator, and
three switchable themes (Dark, Warm, Cool).  Tab cycles theme.  Each theme is
a pure function `fn(TokenStyle) -> Color`.

**FP pattern**: Theme as a function, not a configuration object.  Switching theme
= switching which function maps `TokenStyle` to color.  The draw function is
parameterized by theme index.

### Diff Demo (`diff_demo.gleam`)

`parse_unified_diff` classifies each line of a unified diff string.  Rendered
with colored per-line output: green for added, pink for removed, yellow for
headers, white for context.  Line number gutter with right-aligned numbers.

**FP pattern**: `parse_unified_diff` is `String -> List(DiffLine)`.  The renderer
walks the list and picks color by `DiffKind`.  No diff engine — just a line
classifier over text data.

### Markdown Demo (`markdown_demo.gleam`)

`parse_markdown_blocks` produces `List(MdBlock)`.  `block_to_elements` maps each
block to Element tree nodes: headings get level-based color and bold, code blocks
get dark background, bullets get `•` prefix, hrules get `─` line.  Scrollable.

**FP pattern**: Two-stage pipeline: `String → List(MdBlock) → List(Element)`.
The parser and renderer are independent pure functions.  Adding a new block type
means adding a variant to `MdBlock` and a case branch to `block_to_elements` —
the compiler enforces completeness.

### Input Select Layout Demo (`input_select_layout_demo.gleam`)

Edit buffer input field + select list.  Tab switches focus between the two areas.
When input is focused, typing edits the buffer; when select is focused, arrows
navigate and Enter commits.  Uses `edit_buffer.create(0)` from `opentui_runtime`.

**FP pattern**: Focus as an IntCell (0=input, 1=select).  The key handler
dispatches to `handle_input_key` or `handle_select_key` based on focus value.
Two independent sub-models composed via a focus discriminator.

### ASCII Font Selection Demo (`ascii_font_selection_demo.gleam`)

`ascii_banner` renders words as 5-row block characters.  Arrow keys cycle through
a word list.  Each word is rendered by mapping its characters through `ascii_big`
(a pattern-match lookup table) and merging the glyph rows horizontally.

**FP pattern**: Font rendering as a pure lookup + merge.  `ascii_big("A")` returns
5 strings.  `ascii_banner("HI")` zips the glyph rows of H and I side by side.
The view just maps banner lines to styled elements.

### Extmarks Demo (`extmarks_demo.gleam`)

Three extmark ranges over sample text.  Arrow keys move the cursor, but
`skip_extmark` makes the cursor jump atomically over marked ranges.  A marker
line below the text shows `▔` under extmark-covered positions.  Info panel
shows current position and which mark (if any) the cursor is inside.

**FP pattern**: `skip_extmark(marks, pos, forward)` is pure — it checks if `pos`
falls inside any mark and returns the mark's end (forward) or start-1 (backward).
No mutable range objects.  Extmarks are a `List(Extmark)` queried each frame.

### Live State Demo (`live_state_demo.gleam`)

Four independent state cells (counter, toggle, slider, tabs) rendered as four
UI quadrants.  Each quadrant has its own key bindings (`+/-` for counter, `t` for
toggle, `←/→` for slider, Tab for tabs).

**FP pattern**: Demonstrates that multiple independent state atoms compose
naturally.  No central state reducer.  Each cell is read independently in the
view function.  The event handler dispatches by key, not by focus area.

### Core Plugin Slots Demo (`core_plugin_slots_demo.gleam`)

Four named slots (header, sidebar, content, footer) that can be toggled on/off.
The "Composed Layout" panel shows only the active slots' rendered output.
`active_slots` filters, `toggle_slot` flips, `slot_names` extracts labels.

**FP pattern**: Higher-order composition.  Each slot name maps to a render function
(`render_slot`).  The composed layout is `list.map(active_slots(slots), render_slot)`.
Adding or removing a slot = toggling a boolean in a list of values, and the view
recomposes automatically.  This is the "plugin system as data" pattern — no plugin
runtime, no registration API, no lifecycle hooks.  Just a filtered list driving
a map.

---

## Architecture decisions

### Single model module vs per-demo models

All phase 3 domain types and functions live in `phase3_model.gleam` (~690 lines).
This was deliberate: the types cross-pollinate (tokens are used by both
`hast_syntax_highlighting_demo` and `code_demo`; selections and extmarks share the
concept of cursor position), and co-location makes it obvious which functions are
pure.  A per-demo split would have scattered related types across files.

### Reusing phase 2 infrastructure

Phase 3 heavily reuses `phase2_model` (key parsing, scroll adjustment, focus
navigation, slider bar) and `phase2_state` (IntCell, BoolCell).  This was the
right call — the phase boundary is about demo complexity, not about replacing
infrastructure.  `phase3_state` only adds `StringCell` because no phase 2 demo
needed mutable string storage.

### No new runtime wrappers were consumed

The `text_buffer.gleam` and `syntax_style.gleam` wrappers created during foundation
enrichment turned out not to be used by any phase 3 demo directly.  The demos that
needed syntax highlighting built their own pure tokenizer instead of using the native
syntax style API.  The wrappers remain as phase 4 prerequisites.

### Error handling in guard clauses

Gleam does not allow function calls in `case` guard clauses (`_ if f(x) -> ...`).
Several demos needed conditional logic that initially looked like guards but had to
be restructured as nested `case string.contains(...)` expressions.  This is a Gleam
language constraint, not a design choice, but it's worth noting for future work.

---

## Test summary

| Package | Tests added | Total |
|---|---|---|
| opentui_core | 7 new | 7 |
| opentui_runtime | 22 new | 33 |
| opentui_ui | 12 new | 17 |
| opentui_examples | 36 new (model) + 1 catalog fix | 56 |
| **Total** | | **113** |
