## Functional Composability — The Real Advantage

OpenTUI's raw imperative API is inherently **not composable**:

```ts
// Imperative — zero composability, side effects everywhere
const buffer = renderer.getNextBuffer()
buffer.drawText("Login", 0, 0, fg, bg, 0)
buffer.fillRect(0, 2, 40, 1, border)
buffer.drawText("User:", 1, 3, fg, bg, 0)
renderer.render()
```

React adds composability via JSX, but that requires the React reconciler runtime. Gleam gives you composability **as pure data** — no framework needed:

```gleam
type Element {
  Box(List(Style), List(Element))
  Text(String, List(Style))
  Input(List(InputOption))
  Spacer
}

// Pure data — no side effects, no runtime
let login_form =
  Box([Padding(2), FlexColumn], [
    Text("Login Form", [Fg("#FFFF00"), Bold]),
    Box([Border, Width(40), Height(3)], [
      Input([Placeholder("Username"), Focused]),
    ]),
    Box([Border, Width(40), Height(3)], [
      Input([Placeholder("Password"), Masked]),
    ]),
  ])

// Transform freely — it's just data
let with_debug = add_debug_overlay(login_form)
let conditional = case is_loading {
  True -> add_spinner(login_form)
  False -> login_form
}
```

Then a single render pass walks the tree and calls the imperative FFI:

```gleam
fn render_element(buffer: Buffer, el: Element, x: Int, y: Int) -> #(Int, Int) {
  case el {
    Box(styles, children) -> render_box(buffer, styles, children, x, y)
    Text(content, styles) -> render_text(buffer, content, styles, x, y)
    Input(options) -> render_input(buffer, options, x, y)
    Spacer -> #(x, y)
  }
}
```

**The difference**: React's JSX is syntax sugar for `React.createElement()` calls — it still needs the React reconciler runtime. Gleam's `Element` type is just an algebraic data type. You can map over it, filter it, diff it, serialize it, transform it — all pure functions, no runtime overhead.

### Composition Patterns That Matter for TUIs

**1. Conditional rendering via `case`**

```gleam
let content = case state {
  Loading -> [Spinner()]
  Loaded(data) -> render_data(data)
  Error(msg) -> [ErrorBanner(msg)]
}
```

**2. Higher-order element transformers**

```gleam
// Wrap any element with a border and title
fn with_title(title: String, el: Element) -> Element {
  Box([Border, Title(title), Padding(1)], [el])
}

// Compose freely
let ui = with_title("Dashboard", login_form)
```

**3. Folding over element trees**

```gleam
// Count all interactive elements
fn count_interactive(elements: List(Element)) -> Int {
  elements
  |> list.flat_map(fn(el) {
    case el {
      Box(_, children) -> [el, ..count_interactive(children)]
      Input(_) -> [el]
      _ -> []
    }
  })
  |> list.length
}
```

**4. Serialization for debugging / testing**

```gleam
fn element_to_string(el: Element) -> String {
  case el {
    Box(styles, children) ->
      "Box(" ++ styles_to_string(styles) ++ ", ["
      ++ list.join(list.map(children, element_to_string), ", ") ++ "])"
    Text(content, _) -> "Text(\"" ++ content ++ "\")"
    Input(opts) -> "Input(" ++ opts_to_string(opts) ++ ")"
    Spacer -> "Spacer"
  }
}
```

**5. Diff-based re-rendering (manual, no reconciler)**

```gleam
fn diff_elements(old: Element, new: Element) -> List(Diff) {
  case old, new {
    Box(old_styles, old_children), Box(new_styles, new_children) ->
      diff_styles(old_styles, new_styles)
      ++ diff_children(old_children, new_children)
    Text(old_content, _), Text(new_content, _) ->
      case old_content == new_content {
        True -> []
        False -> [TextChanged(old_content, new_content)]
      }
    _, _ -> [ElementReplaced(old, new)]
  }
}
```

### Why This Matters for TUIs Specifically

In a web app, an unhandled edge case is a minor UX glitch. In a TUI, it's the user's entire interface freezing with no escape hatch. Functional composability means:

- **State transitions are explicit data transformations** — not scattered `setState` calls across event handlers
- **Every screen is a pure function of state** — `fn render(state: AppState) -> Element` — trivially testable
- **No reconciler overhead** — the element tree is walked once per frame, calling imperative FFI. No virtual DOM diffing, no fiber scheduler
- **Serialization is free** — the element tree is just data. Print it, log it, snapshot it, replay it

## Where Gleam's Edge Actually Is

For a TUI built on OpenTUI, Gleam's advantage isn't FFI or ecosystem access — it's **correctness guarantees for an environment where crashes are unrecoverable**:

| Guarantee | Why It Matters for TUIs |
|---|---|
| Exhaustive `case` | Missed keybinding = frozen terminal. Compiler prevents this. |
| No null / no undefined | Null deref = dead process. `Result` types force handling. |
| No `any` escape hatch | Can't accidentally bypass the type system. |
| Immutability by default | No accidental state mutation across render cycles. |
| Union types for screen state | Add a screen → compiler tells you every render branch to update. |
| `BitArray` pattern matching | Terminal protocols are byte protocols. Gleam parses them naturally. |
| Pure data element trees | UI as data structures, composable with standard functional patterns. |
| Serialization for free | Element trees print, log, snapshot, replay — no extra work. |

The `@external` tax is a one-time cost per function you use. Once declared, it's just a function call. The correctness guarantees compound with every line of application code you write.

---

## Why Gleam's FP Model Is the Right Fit for TUIs

The raw OpenTUI API is imperative coordinate math:

```ts
buffer.drawText("Login", 0, 0, fg, bg, 0)
buffer.fillRect(0, 2, 40, 1, border)
buffer.drawText("User:", 1, 3, fg, bg, 0)
```

You can't compose that. You can't say "put this inside that." You calculate positions manually. Every change ripples through every coordinate.

Gleam's ADTs fix this by making UI **data instead of side effects**:

```gleam
Box([Padding(2)], [
  Text("Login"),
  Box([Border], [Input([Focused])]),
])
```

Then one `case` expression walks the tree and calls the imperative FFI. That's it. No reconciler, no fiber scheduler, no virtual DOM. Just pattern matching on a tree.

### Why This Matters More for TUIs Than for Web

**1. TUIs are state machines** — discrete screens, modes, focus states. Union types + exhaustive `case` is the natural representation.

| Environment | Missed case consequence |
|---|---|
| Web app | Minor UI glitch, user refreshes page |
| TUI | Frozen terminal, no escape hatch, killed process |

**2. TUI rendering is simple** — a cell buffer, 30-60fps. React's reconciler is overkill for this. A single `case` walk is all you need.

**3. Every transformation is free** — conditional rendering, higher-order wrappers, tree folding, serialization, diffing. All just functions over data. No runtime cost.

### The Real Comparison

The alternative isn't "Gleam vs React." It's:

| Approach | What you write | What happens when layout changes |
|---|---|---|
| Raw imperative | `drawText("Login", x, y, ...)` | Recalculate every coordinate manually |
| React/JSX | `<box><text>Login</text></box>` | Reconciler diffs virtual DOM, patches native |
| Gleam ADT | `Box([], [Text("Login")])` | Single `case` walk calls imperative FFI |

Gleam gets the composability of React's declarative model without the runtime overhead of a reconciler. The element tree is just data — you can map over it, filter it, serialize it, diff it — all pure functions, zero runtime cost.

For anything beyond a single-screen form, the data-driven approach wins.
