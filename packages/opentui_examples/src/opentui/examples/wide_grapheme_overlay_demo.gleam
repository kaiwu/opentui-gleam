import gleam/int
import opentui/buffer
import opentui/examples/common
import opentui/examples/phase2_state as state
import opentui/examples/phase4_model as model
import opentui/ffi
import opentui/framebuffer
import opentui/grapheme
import opentui/types

pub fn main() -> Nil {
  let selected = state.create_int(0)
  let layers = [
    model.Layer("cjk", 4, 4, 30, 6, True),
    model.Layer("emoji", 15, 7, 30, 6, True),
    model.Layer("symbols", 8, 10, 30, 6, True),
  ]

  common.run_interactive_demo(
    "Wide Grapheme Overlay Demo",
    "Wide Grapheme Overlay Demo",
    fn(key) { handle_key(selected, key) },
    fn(buf) { draw(buf, selected, layers) },
  )
}

fn handle_key(selected: state.IntCell, raw: String) -> Nil {
  case raw {
    "\t" -> state.set_int(selected, { state.get_int(selected) + 1 } % 3)
    _ -> Nil
  }
}

fn draw(
  buf: ffi.Buffer,
  selected: state.IntCell,
  layers: List(model.Layer),
) -> Nil {
  let sel = state.get_int(selected)

  buffer.fill_rect(buf, 2, 2, 76, 19, common.panel_bg)
  draw_layers(buf, layers, sel, 0)

  let sel_name = case sel {
    0 -> "cjk"
    1 -> "emoji"
    _ -> "symbols"
  }
  buffer.draw_text(
    buf,
    " Tab: cycle layer  |  selected: " <> sel_name,
    4,
    common.term_h - 1,
    common.fg_color,
    common.status_bg,
    0,
  )
}

fn draw_layers(
  buf: ffi.Buffer,
  layers: List(model.Layer),
  selected: Int,
  i: Int,
) -> Nil {
  case layers {
    [] -> Nil
    [layer, ..rest] -> {
      case layer.visible {
        True -> {
          let assert Ok(fb) =
            framebuffer.create(layer.w, layer.h, "overlay_" <> int.to_string(i))

          let bg = case i == selected {
            True -> #(0.15, 0.2, 0.35, 0.9)
            False -> #(0.1, 0.12, 0.2, 0.8)
          }
          buffer.fill_rect(fb, 0, 0, layer.w, layer.h, bg)

          let border_color = case i == selected {
            True -> common.accent_blue
            False -> common.border_fg
          }
          draw_border(fb, 0, 0, layer.w, layer.h, border_color)
          buffer.draw_text(
            fb,
            " " <> layer.id <> " ",
            2,
            0,
            common.fg_color,
            bg,
            1,
          )

          let content = layer_content(i)
          let chars = grapheme.encode(content, types.Normal)
          let _w =
            grapheme.draw_graphemes(fb, chars, 2, 2, common.fg_color, bg)

          let info = layer_info(i)
          buffer.draw_text(fb, info, 2, 4, common.muted_fg, bg, 0)

          framebuffer.draw_onto(buf, layer.x, layer.y, fb)
          framebuffer.destroy(fb)
        }
        False -> Nil
      }
      draw_layers(buf, rest, selected, i + 1)
    }
  }
}

fn draw_border(
  buf: ffi.Buffer,
  x: Int,
  y: Int,
  w: Int,
  h: Int,
  fg: #(Float, Float, Float, Float),
) -> Nil {
  let bg = #(0.0, 0.0, 0.0, 0.0)
  common.each_index(w, fn(i) {
    buffer.set_cell(buf, x + i, y, 0x2500, fg, bg, 0)
    buffer.set_cell(buf, x + i, y + h - 1, 0x2500, fg, bg, 0)
  })
  common.each_index(h, fn(i) {
    buffer.set_cell(buf, x, y + i, 0x2502, fg, bg, 0)
    buffer.set_cell(buf, x + w - 1, y + i, 0x2502, fg, bg, 0)
  })
  buffer.set_cell(buf, x, y, 0x250c, fg, bg, 0)
  buffer.set_cell(buf, x + w - 1, y, 0x2510, fg, bg, 0)
  buffer.set_cell(buf, x, y + h - 1, 0x2514, fg, bg, 0)
  buffer.set_cell(buf, x + w - 1, y + h - 1, 0x2518, fg, bg, 0)
}

fn layer_content(index: Int) -> String {
  case index {
    0 -> "東京都 北京市 서울시"
    1 -> "★ ● ◆ ■ ▲ ♦ ♠ ♣ ♥"
    _ -> "→ ← ↑ ↓ ⇒ ∞ ≈ ≠"
  }
}

fn layer_info(index: Int) -> String {
  case index {
    0 -> "CJK: wide characters"
    1 -> "Emoji/symbols mix"
    _ -> "Math & arrow symbols"
  }
}

