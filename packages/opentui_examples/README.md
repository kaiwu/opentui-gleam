# opentui_examples

Runnable Gleam demos built on top of `opentui_core`, `opentui_runtime`, and `opentui_ui`.

This package is also the execution backlog for porting the upstream TypeScript demos one by one while expanding the right lower-level packages.

## How to run from project root

```bash
./scripts/run-example.sh catalog
./scripts/run-example.sh editor
./scripts/run-example.sh terminal-title
./scripts/run-example.sh text-wrap
./scripts/run-example.sh text-truncation
./scripts/run-example.sh simple-layout-example
./scripts/run-example.sh relative-positioning-demo
./scripts/run-example.sh nested-zindex-demo
./scripts/run-example.sh transparency-demo
./scripts/run-example.sh opacity-example
./scripts/run-example.sh vnode-composition-demo
./scripts/run-example.sh styled-text-demo
./scripts/run-example.sh text-node-demo
./scripts/run-example.sh link-demo
./scripts/run-example.sh terminal
./scripts/run-example.sh fonts
./scripts/run-example.sh grayscale-buffer-demo
./scripts/run-example.sh input-demo
./scripts/run-example.sh select-demo
./scripts/run-example.sh tab-select-demo
./scripts/run-example.sh slider-demo
./scripts/run-example.sh scroll-example
./scripts/run-example.sh sticky-scroll-example
./scripts/run-example.sh focus-restore-demo
./scripts/run-example.sh keypress-debug-demo
./scripts/run-example.sh split-mode-demo
./scripts/run-example.sh mouse-interaction-demo
./scripts/run-example.sh scrollbox-mouse-test
./scripts/run-example.sh scrollbox-overlay-hit-test
```

All planned upstream demo ids are also wired into `./scripts/run-example.sh`. Unfinished demos run as stubs and explain which phase and lower-level capabilities are still needed.

## Porting strategy

The target is to implement demos **one by one**, and use each demo to drive the next required layer of the ecosystem backward into:

- `opentui_core`
- `opentui_runtime`
- `opentui_ui`

That means we do **not** blindly port every example at once. Instead, each demo should pressure the right abstraction into existence.

## Phase 1 — foundation / low-risk primitives

- [x] `terminal-title` ← upstream `terminal-title.ts`
- [x] `text-wrap` ← upstream `text-wrap.ts`
- [x] `text-truncation` ← upstream `text-truncation-demo.ts`
- [x] `simple-layout-example`
- [x] `relative-positioning-demo`
- [x] `nested-zindex-demo`
- [x] `transparency-demo`
- [x] `opacity-example`
- [x] `vnode-composition-demo`
- [x] `styled-text-demo`
- [x] `text-node-demo`
- [x] `link-demo`
- [x] `terminal`
- [x] `fonts`
- [x] `grayscale-buffer-demo`

Primary pressure on the stack:

- core buffer/runtime primitives
- declarative UI trees
- style/layout as data
- composable text rendering

## Phase 2 — widgets, input, scrolling, focus

- [x] `select-demo`
- [x] `tab-select-demo`
- [x] `input-demo`
- [x] `slider-demo`
- [x] `scroll-example`
- [x] `sticky-scroll-example`
- [x] `scrollbox-mouse-test`
- [x] `scrollbox-overlay-hit-test`
- [x] `mouse-interaction-demo`
- [x] `focus-restore-demo`
- [x] `keypress-debug-demo`
- [x] `split-mode-demo`

Primary pressure on the stack:

- keyboard and mouse abstractions
- focus model
- scroll containers
- interactive widget primitives

## Phase 3 — editor/text tooling/rich runtime features

- [x] `editor` ← upstream `editor-demo.ts`
- [ ] `text-selection-demo`
- [ ] `ascii-font-selection-demo`
- [ ] `extmarks-demo`
- [ ] `console-demo`
- [ ] `input-select-layout-demo`
- [ ] `text-table-demo`
- [ ] `hast-syntax-highlighting-demo`
- [ ] `code-demo`
- [ ] `diff-demo`
- [ ] `markdown-demo`
- [ ] `live-state-demo`
- [ ] `core-plugin-slots-demo`

Primary pressure on the stack:

- `text_buffer`
- `editor_view`
- syntax style APIs
- selection/extmark abstractions
- richer state-to-view composition

## Phase 4 — framebuffer, unicode, animation, assets

- [ ] `framebuffer-demo`
- [ ] `full-unicode-demo`
- [ ] `wide-grapheme-overlay-demo`
- [ ] `timeline-example`
- [ ] `static-sprite-demo`
- [ ] `texture-loading-demo`
- [ ] `sprite-animation-demo`
- [ ] `sprite-particle-generator-demo`

Primary pressure on the stack:

- framebuffer APIs
- grapheme correctness
- animation/timeline support
- sprite/texture loading abstractions

## Phase 5 — 3D, physics, showcase demos

- [ ] `shader-cube-demo`
- [ ] `fractal-shader-demo`
- [ ] `lights-phong-demo`
- [ ] `draggable-three-demo`
- [ ] `physx-planck-2d-demo`
- [ ] `physx-rapier-2d-demo`
- [ ] `golden-star-demo`
- [ ] `opentui-demo`

Primary pressure on the stack:

- optional 3D package(s)
- physics integration package(s)
- advanced rendering backends
- showcase-level composition across the whole ecosystem

## Current rule for unfinished demos

Every upstream demo should exist in Gleam as either:

- a real implementation, or
- a runnable stub explaining the current phase and missing prerequisites

That keeps the roadmap executable and prevents demos from being forgotten.
