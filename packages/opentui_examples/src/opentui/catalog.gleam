import gleam/io

pub type Demo {
  Demo(id: String, module: String, description: String)
}

pub fn demos() -> List(Demo) {
  [
    done(
      "editor",
      "opentui/examples/editor",
      "Implemented port of upstream editor-demo.ts.",
    ),
    done(
      "terminal-title",
      "opentui/examples/terminal_title",
      "Implemented port of upstream terminal-title.ts.",
    ),
    done(
      "text-wrap",
      "opentui/examples/text_wrap",
      "Implemented port of upstream text-wrap.ts.",
    ),
    done(
      "text-truncation",
      "opentui/examples/text_truncation",
      "Implemented port of upstream text-truncation-demo.ts.",
    ),
    done(
      "simple-layout-example",
      "opentui/examples/simple_layout_example",
      "Implemented a dashboard-style layout demo with declarative panels.",
    ),
    done(
      "relative-positioning-demo",
      "opentui/examples/relative_positioning_demo",
      "Implemented nested offset positioning within declarative boxes.",
    ),
    done(
      "nested-zindex-demo",
      "opentui/examples/nested_zindex_demo",
      "Implemented overlapping layer composition with deterministic paint order.",
    ),
    done(
      "transparency-demo",
      "opentui/examples/transparency_demo",
      "Implemented alpha-blended buffer fills over a checkerboard backdrop.",
    ),
    done(
      "opacity-example",
      "opentui/examples/opacity_example",
      "Implemented opacity stack rendering with nested draw groups.",
    ),
    done(
      "vnode-composition-demo",
      "opentui/examples/vnode_composition_demo",
      "Implemented composable UI tree assembly from reusable pure functions.",
    ),
    done(
      "styled-text-demo",
      "opentui/examples/styled_text_demo",
      "Implemented styled text samples using color, background, and emphasis attributes.",
    ),
    done(
      "text-node-demo",
      "opentui/examples/text_node_demo",
      "Implemented text and paragraph node composition examples.",
    ),
    done(
      "link-demo",
      "opentui/examples/link_demo",
      "Implemented link-like text rendering with clear visual hierarchy.",
    ),
    done(
      "terminal",
      "opentui/examples/terminal",
      "Implemented a terminal palette and renderer summary demo.",
    ),
    done(
      "fonts",
      "opentui/examples/fonts",
      "Implemented ASCII banner and text-density typography samples.",
    ),
    done(
      "grayscale-buffer-demo",
      "opentui/examples/grayscale_buffer_demo",
      "Implemented a grayscale ramp and swatch demo with direct buffer fills.",
    ),
    done(
      "select-demo",
      "opentui/examples/select_demo",
      "Implemented keyboard-driven selection and focus semantics.",
    ),
    done(
      "tab-select-demo",
      "opentui/examples/tab_select_demo",
      "Implemented keyboard tab switching with pure active-tab state.",
    ),
    done(
      "input-demo",
      "opentui/examples/input_demo",
      "Implemented a single-line keyboard input demo on top of edit_buffer.",
    ),
    done(
      "slider-demo",
      "opentui/examples/slider_demo",
      "Implemented keyboard slider state and rendering while mouse input remains pending.",
    ),
    done(
      "scroll-example",
      "opentui/examples/scroll_example",
      "Implemented keyboard-driven scroll state with pure offset clamping.",
    ),
    done(
      "sticky-scroll-example",
      "opentui/examples/sticky_scroll_example",
      "Implemented sticky header scroll semantics with keyboard-controlled offset.",
    ),
    done(
      "scrollbox-mouse-test",
      "opentui/examples/scrollbox_mouse_test",
      "Implemented mouse-wheel scrolling and row hit-testing over a rebuilt hit grid.",
    ),
    done(
      "scrollbox-overlay-hit-test",
      "opentui/examples/scrollbox_overlay_hit_test",
      "Implemented overlay-versus-dialog hit precedence with runtime hit regions.",
    ),
    done(
      "mouse-interaction-demo",
      "opentui/examples/mouse_interaction_demo",
      "Implemented click and wheel interaction through the new runtime event path.",
    ),
    done(
      "focus-restore-demo",
      "opentui/examples/focus_restore_demo",
      "Implemented focus restoration across dynamically hidden widgets.",
    ),
    done(
      "keypress-debug-demo",
      "opentui/examples/keypress_debug_demo",
      "Implemented keyboard stream inspection using the current editor loop.",
    ),
    done(
      "split-mode-demo",
      "opentui/examples/split_mode_demo",
      "Implemented keyboard-controlled split pane layout and focus switching.",
    ),
    done(
      "text-selection-demo",
      "opentui/examples/text_selection_demo",
      "Implemented selection model as pure data with visual character highlighting.",
    ),
    done(
      "ascii-font-selection-demo",
      "opentui/examples/ascii_font_selection_demo",
      "Implemented ASCII block-font banner rendering via pure glyph transformation.",
    ),
    done(
      "extmarks-demo",
      "opentui/examples/extmarks_demo",
      "Implemented virtual extmark ranges with atomic cursor skip logic.",
    ),
    done(
      "console-demo",
      "opentui/examples/console_demo",
      "Implemented log buffer with mouse-clickable level buttons and bounded FIFO.",
    ),
    done(
      "input-select-layout-demo",
      "opentui/examples/input_select_layout_demo",
      "Implemented form composition with edit_buffer input and select widget under shared focus.",
    ),
    done(
      "text-table-demo",
      "opentui/examples/text_table_demo",
      "Implemented pure table formatting with configurable column alignment.",
    ),
    done(
      "hast-syntax-highlighting-demo",
      "opentui/examples/hast_syntax_highlighting_demo",
      "Implemented keyword-based tokenizer driving per-token syntax coloring.",
    ),
    done(
      "code-demo",
      "opentui/examples/code_demo",
      "Implemented code viewer with line numbers, tokenizer, and three switchable themes.",
    ),
    done(
      "diff-demo",
      "opentui/examples/diff_demo",
      "Implemented unified diff viewer with pure line classifier and colored output.",
    ),
    done(
      "markdown-demo",
      "opentui/examples/markdown_demo",
      "Implemented markdown block parser rendering headings, code, lists, and rules as element trees.",
    ),
    done(
      "live-state-demo",
      "opentui/examples/live_state_demo",
      "Implemented four independent state cells composing into a unified reactive view.",
    ),
    done(
      "core-plugin-slots-demo",
      "opentui/examples/core_plugin_slots_demo",
      "Implemented higher-order slot composition with toggleable named render slots.",
    ),
    done(
      "framebuffer-demo",
      "opentui/examples/framebuffer_demo",
      "Implemented bouncing ball and box with framebuffer compositing and alpha overlays.",
    ),
    done(
      "full-unicode-demo",
      "opentui/examples/full_unicode_demo",
      "Implemented per-grapheme unicode rendering with display width analysis.",
    ),
    done(
      "wide-grapheme-overlay-demo",
      "opentui/examples/wide_grapheme_overlay_demo",
      "Implemented wide-char framebuffer overlays with alpha-blended layer compositing.",
    ),
    done(
      "timeline-example",
      "opentui/examples/timeline_example",
      "Implemented pure timeline animation with ease-in-out and hue cycling tweens.",
    ),
    done(
      "static-sprite-demo",
      "opentui/examples/static_sprite_demo",
      "Implemented hue-rotating diamond sprite via framebuffer cell rendering.",
    ),
    done(
      "texture-loading-demo",
      "opentui/examples/texture_loading_demo",
      "Implemented procedural texture grid with animated hue cycling.",
    ),
    done(
      "sprite-animation-demo",
      "opentui/examples/sprite_animation_demo",
      "Implemented 4-frame sprite animation with bounce easing and timeline.",
    ),
    done(
      "sprite-particle-generator-demo",
      "opentui/examples/sprite_particle_generator_demo",
      "Implemented 24-particle system with per-particle phase, speed, and color.",
    ),
    done(
      "shader-cube-demo",
      "opentui/examples/shader_cube_demo",
      "Implemented rotating wireframe cube with pure 3D projection and Phong edge shading.",
    ),
    done(
      "fractal-shader-demo",
      "opentui/examples/fractal_shader_demo",
      "Implemented Mandelbrot fractal rendered per-cell with panning viewport.",
    ),
    done(
      "lights-phong-demo",
      "opentui/examples/lights_phong_demo",
      "Implemented Phong-lit sphere with rotating directional light and ambient.",
    ),
    done(
      "draggable-three-demo",
      "opentui/examples/draggable_three_demo",
      "Implemented keyboard-rotatable 3D wireframe with switchable cube/pyramid meshes.",
    ),
    done(
      "physx-planck-2d-demo",
      "opentui/examples/physx_planck_2d_demo",
      "Implemented 2D physics simulation with 6 bouncing circles and high gravity.",
    ),
    done(
      "physx-rapier-2d-demo",
      "opentui/examples/physx_rapier_2d_demo",
      "Implemented 2D physics with mixed circles and rectangles at high restitution.",
    ),
    done(
      "golden-star-demo",
      "opentui/examples/golden_star_demo",
      "Implemented animated golden star compositing animation, lighting, and framebuffer.",
    ),
    done(
      "opentui-demo",
      "opentui/examples/opentui_demo",
      "Implemented multi-panel ecosystem showcase with live stats, fractal, cube, and unicode.",
    ),
  ]
}

pub fn print_demo_catalog() -> Nil {
  io.println(help_text())
}

pub fn help_text() -> String {
  "OpenTUI Gleam examples\n\n"
  <> "Run demos directly with `gleam run -m <module>` or from project root with `./scripts/run-example.sh <id>`.\n\n"
  <> "Catalog:\n"
  <> format_demos(demos())
}

fn done(id: String, module: String, description: String) -> Demo {
  Demo(id, module, "[done] " <> description)
}

fn format_demos(demos: List(Demo)) -> String {
  case demos {
    [] -> "  (none yet)\n"
    [Demo(id:, module:, description:)] ->
      "  - "
      <> id
      <> "\n    module: "
      <> module
      <> "\n    "
      <> description
      <> "\n"
    [Demo(id:, module:, description:), ..rest] ->
      "  - "
      <> id
      <> "\n    module: "
      <> module
      <> "\n    "
      <> description
      <> "\n"
      <> format_demos(rest)
  }
}
