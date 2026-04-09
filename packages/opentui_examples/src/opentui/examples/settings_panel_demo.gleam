import gleam/int
import gleam/string
import opentui/examples/common
import opentui/examples/phase2_model as model
import opentui/examples/phase4_state as state
import opentui/interaction
import opentui/ui
import opentui/widgets

const tab_labels = ["General", "Appearance", "Keys"]

pub fn main() -> Nil {
  let tabs = state.create_generic(widgets.tab_state(3))
  let focus = state.create_generic(interaction.focus_group(3))
  let username = state.create_generic(widgets.input_state("user"))
  let theme_sel = state.create_generic(widgets.select_state(4))
  let font_sel = state.create_generic(widgets.select_state(3))
  let key_sel = state.create_generic(widgets.select_state(5))

  common.run_interactive_ui_demo(
    "Settings Panel Demo",
    "Settings Panel Demo",
    fn(key) {
      handle_key(tabs, focus, username, theme_sel, font_sel, key_sel, key)
    },
    fn() { view(tabs, focus, username, theme_sel, font_sel, key_sel) },
  )
}

fn handle_key(
  tabs: state.GenericCell,
  focus: state.GenericCell,
  username: state.GenericCell,
  theme_sel: state.GenericCell,
  font_sel: state.GenericCell,
  key_sel: state.GenericCell,
  raw: String,
) -> Nil {
  let key = model.parse_key(raw)
  let t: widgets.TabState = state.get_generic(tabs)

  case key {
    model.Tab -> {
      let fg: interaction.FocusGroup = state.get_generic(focus)
      let new_fg = interaction.focus_next(fg)
      state.set_generic(focus, new_fg)
    }
    model.ShiftTab -> {
      let fg: interaction.FocusGroup = state.get_generic(focus)
      state.set_generic(focus, interaction.focus_prev(fg))
    }
    _ -> {
      let fg: interaction.FocusGroup = state.get_generic(focus)
      case fg.focused {
        0 -> {
          let new_t = case key {
            model.ArrowLeft -> widgets.tab_prev(t)
            model.ArrowRight -> widgets.tab_next(t)
            _ -> t
          }
          state.set_generic(tabs, new_t)
        }
        _ ->
          case t.active {
            0 -> handle_general_key(username, key)
            1 -> handle_appearance_key(theme_sel, font_sel, fg.focused, key)
            _ -> handle_keys_key(key_sel, key)
          }
      }
    }
  }
}

fn handle_general_key(username: state.GenericCell, key: model.Key) -> Nil {
  let inp: widgets.InputState = state.get_generic(username)
  let new_inp = case key {
    model.Character(c) -> widgets.input_insert(inp, c)
    model.Space -> widgets.input_insert(inp, " ")
    model.Backspace -> widgets.input_delete_backward(inp)
    model.ArrowLeft -> widgets.input_move_left(inp)
    model.ArrowRight -> widgets.input_move_right(inp)
    model.Home -> widgets.input_move_home(inp)
    model.End -> widgets.input_move_end(inp)
    _ -> inp
  }
  state.set_generic(username, new_inp)
}

fn handle_appearance_key(
  theme_sel: state.GenericCell,
  font_sel: state.GenericCell,
  focused: Int,
  key: model.Key,
) -> Nil {
  case focused {
    1 -> {
      let s: widgets.SelectState = state.get_generic(theme_sel)
      let new_s = case key {
        model.ArrowUp -> widgets.select_up(s)
        model.ArrowDown -> widgets.select_down(s)
        _ -> s
      }
      state.set_generic(theme_sel, new_s)
    }
    _ -> {
      let s: widgets.SelectState = state.get_generic(font_sel)
      let new_s = case key {
        model.ArrowUp -> widgets.select_up(s)
        model.ArrowDown -> widgets.select_down(s)
        _ -> s
      }
      state.set_generic(font_sel, new_s)
    }
  }
}

fn handle_keys_key(key_sel: state.GenericCell, key: model.Key) -> Nil {
  let s: widgets.SelectState = state.get_generic(key_sel)
  let new_s = case key {
    model.ArrowUp -> widgets.select_up(s)
    model.ArrowDown -> widgets.select_down(s)
    _ -> s
  }
  state.set_generic(key_sel, new_s)
}

fn view(
  tabs: state.GenericCell,
  focus: state.GenericCell,
  username: state.GenericCell,
  theme_sel: state.GenericCell,
  font_sel: state.GenericCell,
  key_sel: state.GenericCell,
) -> List(ui.Element) {
  let t: widgets.TabState = state.get_generic(tabs)
  let fg: interaction.FocusGroup = state.get_generic(focus)

  [
    common.panel("Settings", 2, 3, 76, 18, [
      ui.Column([ui.Gap(1)], [
        widgets.tab_bar(
          [],
          t,
          tab_labels,
          [ui.Foreground(common.color(common.muted_fg))],
          [
            ui.Foreground(common.color(common.accent_blue)),
            ui.Attributes(1),
          ],
        ),
        tab_content(t, fg, username, theme_sel, font_sel, key_sel),
        status_line(fg),
      ]),
    ]),
  ]
}

fn tab_content(
  t: widgets.TabState,
  fg: interaction.FocusGroup,
  username: state.GenericCell,
  theme_sel: state.GenericCell,
  font_sel: state.GenericCell,
  key_sel: state.GenericCell,
) -> ui.Element {
  case t.active {
    0 -> general_tab(username, fg)
    1 -> appearance_tab(theme_sel, font_sel, fg)
    _ -> keys_tab(key_sel, fg)
  }
}

fn general_tab(
  username: state.GenericCell,
  fg: interaction.FocusGroup,
) -> ui.Element {
  let inp: widgets.InputState = state.get_generic(username)
  let label_styles = [ui.Foreground(common.color(common.muted_fg))]
  let input_active = interaction.is_focused(fg, 1)

  ui.Column([ui.Gap(1)], [
    common.line_with(label_styles, "Username:"),
    common.line_with(
      case input_active {
        True -> [
          ui.Foreground(common.color(common.accent_green)),
          ui.Attributes(1),
        ]
        False -> []
      },
      "> "
        <> widgets.input_display_value(case input_active {
        True -> widgets.input_focus(inp)
        False -> widgets.input_blur(inp)
      }),
    ),
    ui.Spacer(1),
    common.line_with(label_styles, "Email: user@example.com (read-only)"),
    common.line_with(label_styles, "Role: developer (read-only)"),
    ui.Spacer(1),
    common.line_with(
      [ui.Foreground(common.color(common.muted_fg))],
      "Length: "
        <> int.to_string(inp.cursor)
        <> "/"
        <> int.to_string(string.length(inp.value)),
    ),
  ])
}

fn appearance_tab(
  theme_sel: state.GenericCell,
  font_sel: state.GenericCell,
  fg: interaction.FocusGroup,
) -> ui.Element {
  let ts: widgets.SelectState = state.get_generic(theme_sel)
  let fs: widgets.SelectState = state.get_generic(font_sel)

  ui.Column([ui.Gap(1)], [
    common.line_with(
      [ui.Foreground(common.color(common.muted_fg))],
      "Theme" <> focus_indicator(fg, 1),
    ),
    widgets.select_list(
      [ui.Gap(0)],
      ts,
      ["Dark", "Light", "Solarized", "Dracula"],
      [],
      [
        ui.Foreground(common.color(common.accent_green)),
        ui.Attributes(1),
      ],
    ),
    common.line_with(
      [ui.Foreground(common.color(common.muted_fg))],
      "Font" <> focus_indicator(fg, 2),
    ),
    widgets.select_list(
      [ui.Gap(0)],
      fs,
      ["Monospace", "JetBrains Mono", "Fira Code"],
      [],
      [
        ui.Foreground(common.color(common.accent_blue)),
        ui.Attributes(1),
      ],
    ),
  ])
}

fn keys_tab(
  key_sel: state.GenericCell,
  fg: interaction.FocusGroup,
) -> ui.Element {
  let ks: widgets.SelectState = state.get_generic(key_sel)

  ui.Column([ui.Gap(1)], [
    common.line_with(
      [ui.Foreground(common.color(common.muted_fg))],
      "Keybinding scheme" <> focus_indicator(fg, 1),
    ),
    widgets.select_list(
      [ui.Gap(0)],
      ks,
      ["Default", "Vim", "Emacs", "VS Code", "Custom"],
      [],
      [
        ui.Foreground(common.color(common.accent_yellow)),
        ui.Attributes(1),
      ],
    ),
    ui.Spacer(1),
    common.paragraph(
      "Select a keybinding scheme. Custom allows individual key remapping (not yet implemented).",
    ),
  ])
}

fn status_line(fg: interaction.FocusGroup) -> ui.Element {
  let area = case fg.focused {
    0 -> "tabs"
    1 -> "field 1"
    _ -> "field 2"
  }
  common.line_with(
    [ui.Foreground(common.color(common.muted_fg))],
    "Tab: cycle focus | ←→: tabs | ↑↓: select | Type: edit  [focus: "
      <> area
      <> "]",
  )
}

fn focus_indicator(fg: interaction.FocusGroup, index: Int) -> String {
  case interaction.is_focused(fg, index) {
    True -> " *"
    False -> ""
  }
}
