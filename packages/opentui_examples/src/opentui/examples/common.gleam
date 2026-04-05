import opentui/buffer
import opentui/ffi
import opentui/renderer
import opentui/runtime
import opentui/text
import opentui/ui

pub const term_w = 80

pub const term_h = 24

pub const bg_color = #(0.08, 0.1, 0.16, 1.0)

pub const fg_color = #(0.95, 0.95, 0.98, 1.0)

pub const title_bg = #(0.2, 0.4, 0.8, 1.0)

pub const panel_bg = #(0.05, 0.07, 0.12, 1.0)

pub const status_bg = #(0.22, 0.24, 0.3, 1.0)

pub const border_fg = #(0.45, 0.5, 0.65, 1.0)

pub fn run_static_demo(
  title: String,
  term_title: String,
  draw_body: fn(ffi.Buffer) -> Nil,
) -> Nil {
  let config =
    renderer.RendererConfig(
      width: term_w,
      height: term_h,
      screen_mode: renderer.AlternateScreen,
      exit_on_ctrl_c: True,
    )

  let r = case renderer.create(config) {
    Ok(r) -> r
    Error(msg) -> {
      runtime.log(msg)
      panic as "Failed to create renderer"
    }
  }

  renderer.setup(r, renderer.AlternateScreen)
  renderer.set_title(r, term_title)
  renderer.enable_mouse(r, False)

  let r_int = ffi.renderer_to_int(r)
  runtime.run_demo_loop(r_int, fn() { render_static_frame(r, title, draw_body) })

  Nil
}

pub fn run_static_ui_demo(
  title: String,
  term_title: String,
  elements: List(ui.Element),
) -> Nil {
  run_static_demo(title, term_title, fn(buf) {
    render_static_frame_ui(buf, elements)
  })
}

pub fn run_stub_demo(
  title: String,
  term_title: String,
  phase: String,
  needs: List(String),
) -> Nil {
  run_static_ui_demo(title, term_title, stub_view(title, phase, needs))
}

pub fn draw_panel(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  w: Int,
  h: Int,
  title: String,
) -> Nil {
  buffer.fill_rect(buf, x, y, w, h, panel_bg)

  each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, border_fg, bg_color, 0)
    buffer.set_cell(buf, x + i, y + h - 1, 0x2500, border_fg, bg_color, 0)
  })

  each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, border_fg, bg_color, 0)
    buffer.set_cell(buf, x + w - 1, y + i, 0x2502, border_fg, bg_color, 0)
  })

  buffer.set_cell(buf, x, y, 0x250c, border_fg, bg_color, 0)
  buffer.set_cell(buf, x + w - 1, y, 0x2510, border_fg, bg_color, 0)
  buffer.set_cell(buf, x, y + h - 1, 0x2514, border_fg, bg_color, 0)
  buffer.set_cell(buf, x + w - 1, y + h - 1, 0x2518, border_fg, bg_color, 0)

  buffer.draw_text(buf, " " <> title <> " ", x + 2, y, fg_color, bg_color, 1)
}

fn render_static_frame(
  r: ffi.Renderer,
  title: String,
  draw_body: fn(ffi.Buffer) -> Nil,
) -> Nil {
  let buf = buffer.get_next_buffer(r)
  buffer.fill_rect(buf, 0, 0, term_w, term_h, bg_color)
  buffer.fill_rect(buf, 0, 0, term_w, 1, title_bg)
  buffer.draw_text(buf, " " <> title <> " ", 2, 0, fg_color, title_bg, 1)

  draw_body(buf)

  buffer.fill_rect(buf, 0, term_h - 1, term_w, 1, status_bg)
  buffer.draw_text(
    buf,
    " q / Ctrl+C to quit ",
    term_w - 20,
    term_h - 1,
    fg_color,
    status_bg,
    0,
  )
}

fn render_static_frame_ui(buf: ffi.Buffer, elements: List(ui.Element)) -> Nil {
  ui.render_all(buf, elements)
}

fn stub_view(
  title: String,
  phase: String,
  needs: List(String),
) -> List(ui.Element) {
  [
    ui.Box(
      [
        ui.X(2),
        ui.Y(3),
        ui.Width(76),
        ui.Height(18),
        ui.Padding(1),
        ui.Background(color(panel_bg)),
        ui.Border(title, color(border_fg)),
      ],
      [
        ui.Column([ui.Gap(1)], [
          text_line("Status: planned stub"),
          text_line("Phase: " <> phase),
          ui.Spacer(1),
          text_line(
            "This demo exists as a runnable placeholder so we can implement demos one by one while growing the right lower-level packages.",
          ),
          ui.Spacer(1),
          text_line("Likely needs:"),
          ui.Column([ui.Gap(0)], need_lines(needs)),
        ]),
      ],
    ),
  ]
}

fn need_lines(needs: List(String)) -> List(ui.Element) {
  case needs {
    [] -> [text_line("- no dependencies listed yet")]
    [need, ..rest] -> [text_line("- " <> need), ..need_lines(rest)]
  }
}

fn text_line(content: String) -> ui.Element {
  ui.Paragraph(
    [
      ui.Foreground(color(fg_color)),
      ui.Background(color(panel_bg)),
      ui.Wrap(text.WordWrap),
      ui.Truncate(ui.EndTruncate),
    ],
    content,
  )
}

fn color(c: #(Float, Float, Float, Float)) -> ui.Color {
  ui.Color(c.0, c.1, c.2, c.3)
}

fn each_index(n: Int, f: fn(Int) -> Nil) -> Nil {
  case n <= 0 {
    True -> Nil
    False -> each_index_loop(0, n, f)
  }
}

fn each_index_loop(i: Int, n: Int, f: fn(Int) -> Nil) -> Nil {
  case i >= n {
    True -> Nil
    False -> {
      f(i)
      each_index_loop(i + 1, n, f)
    }
  }
}
