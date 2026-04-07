# Phase 4 Design — Framebuffer, Unicode, Animation, Assets

Phase 4 demos sit at the boundary between what pure FP can express as data and what
requires tight integration with the native rendering pipeline.  The central tension:
phases 1–3 rendered everything through `buffer.draw_text` / `buffer.set_cell` or the
Element tree.  Phase 4 introduces **off-screen framebuffers**, **timer-driven animation**,
and **asset loading** — concepts that are inherently effectful.  The design question is
how to keep the FP composability edge while embracing the new capabilities.

---

## The eight demos

| Demo | Upstream pattern | Core capability needed |
|---|---|---|
| `framebuffer-demo` | Multiple overlapping off-screen buffers, alpha blending, partial draw (crop), buffer resize | Framebuffer create/destroy/draw/resize |
| `full-unicode-demo` | Wide graphemes (CJK, emoji, ZWJ sequences), correct column widths | `encodeUnicode` / `freeUnicode`, grapheme-aware width |
| `wide-grapheme-overlay-demo` | Draggable boxes filled with wide-char text, alpha overlays | Framebuffer + grapheme width (union of above two) |
| `timeline-example` | Declarative timelines with sub-timelines, easing, looping | Frame callback (`setFrameCallback`), pure timeline model |
| `static-sprite-demo` | Load a PNG sprite sheet, render via Three.js orthographic camera | 3D engine init, sprite utils, texture loading |
| `texture-loading-demo` | Textured 3D cube with Phong lighting | 3D engine, texture utils, Three.js materials |
| `sprite-animation-demo` | Tiled sprite animation with frame stepping | Sprite animator, resource manager, tiled sprites |
| `sprite-particle-generator-demo` | Particle systems driven by sprite sheets | Particle generator, sprite resources, 3D scene |

---

## Capability analysis

### Tier 1 — Pure Zig FFI (no JS-side dependencies)

These can be wrapped the same way we wrapped buffer/text_buffer/edit_buffer:

1. **Framebuffer** — Already exported from the native library:
   - `destroyFrameBuffer(ptr)` (alias for `destroyOptimizedBuffer`)
   - `drawFrameBuffer(target, destX, destY, source, srcX, srcY, srcW, srcH)`
   - `bufferResize(ptr, width, height)`
   - A framebuffer is just an `OptimizedBuffer` created with `respectAlpha = true`.
     No new opaque type needed — reuse `ffi.Buffer`.

2. **Unicode / Grapheme** — Already exported:
   - `encodeUnicode(textPtr, textLen, outPtr, outLenPtr, widthMethod) -> bool`
   - `freeUnicode(charsPtr, charsLen)`
   - Returns an array of `EncodedChar { char: u32, width: u8 }`.
   - Needs a JS shim that marshals the output pointer into a Gleam-friendly structure
     (list of `#(Int, Int)` pairs, or a dedicated `GraphemeInfo` type).

### Tier 2 — JS-side runtime (no third-party npm)

3. **Frame callback / animation tick** — The upstream `renderer.setFrameCallback(fn)` is
   implemented in the JS-side `CliRenderer` class, not in the Zig library.  It calls the
   callback with `deltaTime` on each frame.  We need to expose this through our event loop.
   - Option A: Add a `setFrameCallback` binding and run a requestAnimationFrame / setInterval
     loop in JS that calls the Gleam callback.
   - Option B: Extend `runDemoLoop` / `runEventLoop` to accept an optional tick function
     that receives delta time.  Simpler, stays within our existing loop architecture.
   - **Recommendation**: Option B.  A new `run_animated_demo` variant in `common.gleam` that
     takes `on_tick: fn(Float) -> Nil` alongside the existing `on_key` / `draw_body`.
     The JS side runs a `setInterval` at ~30fps, calls `on_tick(dt)`, then redraws.

4. **Timeline as pure data** — The upstream `Timeline` is a JS class with mutable state.
   We should model timelines as pure Gleam data:
   ```
   type Timeline {
     Timeline(
       duration: Float,       // ms
       elapsed: Float,        // ms, updated by tick
       loop: Bool,
       children: List(#(Float, Timeline)),  // (offset_ms, sub_timeline)
     )
   }

   fn tick(tl: Timeline, dt: Float) -> Timeline
   fn progress(tl: Timeline) -> Float           // 0.0–1.0
   fn is_complete(tl: Timeline) -> Bool
   fn lerp(from: Float, to: Float, t: Float) -> Float
   fn ease_in_out(t: Float) -> Float
   ```
   The event loop calls `tick` each frame; the view function reads `progress` to
   interpolate positions, colors, sizes.  Zero mutable state in the timeline itself.

### Tier 3 — Heavy JS-side dependencies (Three.js, image loading)

5. **3D / Sprite / Texture / Particle** — The upstream demos for `static-sprite-demo`,
   `texture-loading-demo`, `sprite-animation-demo`, and `sprite-particle-generator-demo`
   all depend on:
   - `three` (Three.js) — 3D scene graph, cameras, materials, lights
   - `ThreeCliRenderer` — OpenTUI's JS bridge from Three.js to the terminal framebuffer
   - `SpriteUtils`, `SpriteAnimator`, `SpriteResourceManager`, `SpriteParticleGenerator`
   - PNG image loading via Bun's asset import system

   These are fundamentally JS-side constructs.  Wrapping them in Gleam FFI is possible
   but heavy — each class becomes an opaque type with many methods.

---

## Proposed layering

### Layer 1: `opentui_core` additions

New FFI bindings in `ffi.gleam` + `ffi_shim.js`:

```
// Framebuffer (reuses Buffer type)
fn draw_frame_buffer(target, dest_x, dest_y, source, src_x, src_y, src_w, src_h) -> Nil
fn buffer_resize(buffer, width, height) -> Nil

// Unicode
fn encode_unicode(text, text_len, width_method) -> List(#(Int, Int))  // (char, width)
fn free_unicode_is_automatic()  // handled in JS shim, no Gleam call needed
```

The JS shim for `encodeUnicode` allocates the output pointer, calls the native function,
marshals `EncodedChar[]` into a JS array of `[char, width]` tuples, frees the native
memory, and returns the array.  Gleam sees `List(#(Int, Int))`.

### Layer 2: `opentui_runtime` additions

**`framebuffer.gleam`** — Ergonomic wrapper:

```gleam
pub fn create(width, height, id) -> ffi.Buffer
  // calls buffer.create with respect_alpha=True

pub fn destroy(fb) -> Nil

pub fn draw_onto(target, dest_x, dest_y, source) -> Nil
  // full blit, no crop

pub fn draw_region(target, dest_x, dest_y, source, src_x, src_y, w, h) -> Nil
  // partial blit / crop

pub fn resize(fb, width, height) -> Nil

pub fn clear(fb, bg) -> Nil
  // delegates to buffer.clear
```

A framebuffer is-a buffer.  All existing `buffer.draw_text`, `buffer.fill_rect`,
`buffer.set_cell` work on it directly.  The only new operations are `draw_onto` /
`draw_region` (compositing one buffer into another) and `resize`.

**`grapheme.gleam`** — Unicode width utilities:

```gleam
pub type EncodedChar {
  EncodedChar(codepoint: Int, width: Int)
}

pub fn encode(text: String, method: text.WidthMethod) -> List(EncodedChar)

pub fn display_width(text: String, method: text.WidthMethod) -> Int
  // sum of widths from encode()

pub fn draw_graphemes(buf, chars: List(EncodedChar), x, y, fg, bg) -> Int
  // draws each encoded char via buffer.set_cell, returns total width
```

**`animation.gleam`** — Pure timeline (no FFI):

```gleam
pub type Tween {
  Tween(from: Float, to: Float, duration: Float, easing: fn(Float) -> Float)
}

pub type Timeline {
  Timeline(
    duration: Float,
    elapsed: Float,
    looping: Bool,
    tweens: List(#(String, Float, Tween)),  // (name, start_offset, tween)
  )
}

pub fn create(duration, looping) -> Timeline
pub fn tick(tl, dt) -> Timeline
pub fn value(tl, name) -> Float
pub fn progress(tl) -> Float
pub fn is_done(tl) -> Bool
pub fn linear(t) -> Float
pub fn ease_in_out(t) -> Float
pub fn ease_out_bounce(t) -> Float
```

### Layer 3: `opentui_ui` — no changes needed

The Element tree already supports everything phase 4 demos render.  Framebuffers are
a buffer-level concept — they compose below the Element abstraction, not above it.

### Layer 4: `opentui_examples` — demo loop and model

**`common.gleam`** — Add animated demo runner:

```gleam
pub fn run_animated_demo(title, term_title, on_key, on_tick, draw_body) -> Nil
  // on_tick receives delta_ms: Float each frame
  // JS side uses setInterval(~33ms) to drive the tick
```

**`phase4_model.gleam`** — Pure types and functions:

```gleam
// Physics / motion
pub type Vec2 { Vec2(x: Float, y: Float) }
pub fn vec2_add(a, b) -> Vec2
pub fn vec2_scale(v, s) -> Vec2
pub fn bounce(pos, vel, min, max) -> #(Float, Float)  // returns (new_pos, new_vel)

// Framebuffer composition patterns
pub type Layer { Layer(id: String, x: Int, y: Int, visible: Bool, alpha: Float) }
pub fn visible_layers(layers) -> List(Layer)

// Grapheme display
pub type GraphemeLine { GraphemeLine(text: String, display_width: Int) }
pub fn measure_lines(lines: List(String), method) -> List(GraphemeLine)

// Animation
pub fn lerp_color(from, to, t) -> #(Float, Float, Float, Float)
pub fn lerp_int(from, to, t) -> Int
pub fn wrap_angle(degrees) -> Float
```

**`phase4_state.gleam`** — Mutable cells for animation:

```gleam
pub type FloatCell
pub fn create_float(initial: Float) -> FloatCell
pub fn get_float(cell: FloatCell) -> Float
pub fn set_float(cell: FloatCell, value: Float) -> Nil
```

---

## Demo implementation strategy

### Group A — Framebuffer + grapheme (no animation)

These two demos need only the framebuffer and grapheme wrappers:

1. **`full-unicode-demo`** — Display `GRAPHEME_LINES` in a buffer, show measured column
   widths beside each line.  No animation, no interaction beyond scrolling.
   Uses `grapheme.encode` to measure + render each line character-by-character.

2. **`wide-grapheme-overlay-demo`** — Multiple framebuffers with wide-char content
   and alpha overlays.  Keyboard-driven movement (arrows move a selected layer).
   Each layer is a framebuffer composited via `framebuffer.draw_onto`.

### Group B — Animation (framebuffer + timeline)

3. **`framebuffer-demo`** — Bouncing box and ball using `phase4_model.bounce`,
   a resizing framebuffer, transparent overlay, and partial-draw crops.
   Driven by `run_animated_demo`; `on_tick` updates positions via pure `bounce`.

4. **`timeline-example`** — Two sub-timelines controlling box position and color.
   Pure `Timeline` data ticked each frame, `value("x")` / `value("color_r")` read in
   the draw function.  Demonstrates that animation is just `fn(state) -> state`.

### Group C — 3D / Sprites (heavy JS interop)

5–8. **`static-sprite-demo`**, **`texture-loading-demo`**, **`sprite-animation-demo`**,
     **`sprite-particle-generator-demo`**

These depend on Three.js and the upstream JS rendering pipeline.  Two options:

**Option A — Thin FFI shell**: Create `opentui_3d` bindings for ThreeCliRenderer,
SpriteUtils, SpriteAnimator etc.  Heavy upfront cost, many opaque types.

**Option B — JS-driven with Gleam orchestration**: Write the 3D setup in JS (a
`phase4_3d_shim.js` helper), expose only high-level controls to Gleam:
```gleam
@external(javascript, "./phase4_3d_shim.js", "initSpriteDemo")
pub fn init_sprite_demo(renderer: Int, width: Int, height: Int) -> Nil

@external(javascript, "./phase4_3d_shim.js", "tickSpriteDemo")
pub fn tick_sprite_demo(dt: Float) -> Nil
```

Gleam owns the event loop, state, and UI chrome.  JS owns the 3D scene internals.

**Recommendation**: Option B for now.  The 3D demos are showcase pieces, not
composable abstractions.  Wrapping all of Three.js adds complexity without
enabling new FP patterns.  If a future phase needs Gleam-driven 3D scene graphs,
we can introduce `opentui_3d` then.

---

## Implementation order

```
Step 1:  opentui_core   — add framebuffer FFI (drawFrameBuffer, bufferResize)
Step 2:  opentui_core   — add encodeUnicode FFI + JS shim
Step 3:  opentui_runtime — framebuffer.gleam wrapper + tests
Step 4:  opentui_runtime — grapheme.gleam wrapper + tests
Step 5:  opentui_runtime — animation.gleam (pure, no FFI) + tests
Step 6:  opentui_examples — phase4_model.gleam + phase4_state.gleam + tests
Step 7:  opentui_examples — common.gleam: add run_animated_demo
Step 8:  opentui_examples — full_unicode_demo, wide_grapheme_overlay_demo
Step 9:  opentui_examples — framebuffer_demo, timeline_example
Step 10: opentui_examples — 3D shim + sprite/texture/particle demos
```

Steps 1–5 are foundation work (like phase 3's text_buffer / syntax_style enrichment).
Steps 6–7 are example infrastructure.  Steps 8–10 are the demos themselves.

The 3D demos (step 10) are the riskiest — they depend on Three.js being available and
the ThreeCliRenderer working through our event loop.  We should implement them last
and be ready to simplify if the JS interop proves too heavy.

---

## What makes this phase different from phase 3

Phase 3 was about **data modeling** — every demo was driven by a pure function in
`phase3_model.gleam`.  The rendering was either Element trees or per-token buffer
drawing, but the state logic was always pure.

Phase 4 introduces **time as a first-class input**.  The `on_tick(dt)` callback means
state changes happen continuously, not just on key/mouse events.  The design challenge
is keeping the FP invariant:

```
new_state = tick(old_state, delta_time)    // pure
elements  = view(new_state)               // pure
render(elements)                           // effect
```

The `Timeline` type is the key abstraction — it turns time-driven animation into
the same `fn(state) -> state` pattern we use everywhere else.  A timeline is just
data that you `tick`.  Positions are just `lerp(from, to, progress(timeline))`.
No mutation, no callbacks-within-callbacks, no subscription model.

The framebuffer adds spatial composition (layering off-screen buffers) to our
existing temporal composition (event → state → view).  Together they let us build
demos that would be impractical with just `buffer.draw_text` — but the composition
model stays purely functional at the Gleam level.

---

## Risk areas

1. **`encodeUnicode` memory management** — The native function allocates and returns
   a pointer.  Our JS shim must marshal and free in the same call.  If we leak, the
   native allocator will eventually run out.  Mitigation: the shim calls `freeUnicode`
   immediately after copying data to JS arrays.

2. **Animation frame rate** — `setInterval(33)` gives ~30fps but is not perfectly
   regular.  The `dt` parameter handles this, but visual smoothness depends on the
   terminal's refresh rate.  Mitigation: clamp `dt` to avoid large jumps after GC
   pauses (the upstream does `Math.min(deltaTime, 100)`).

3. **Three.js dependency weight** — `three` is a large npm package.  Including it
   as a dependency of `opentui_examples` bloats `node_modules`.  Mitigation: make
   the 3D demos optional — if `three` is not installed, the demo shows a message
   explaining the dependency.  Or: use dynamic `import()` with a try/catch.

4. **Wide grapheme terminal support** — Not all terminals handle ZWJ emoji or CJK
   characters correctly.  The native library's `encodeUnicode` does the right thing,
   but the terminal may still misrender.  Mitigation: the demo should include a
   diagnostic panel showing expected vs actual widths.
