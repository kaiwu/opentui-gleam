import opentui/app

pub fn app_config_constructs_test() {
  let config = app.AppConfig(width: 80, height: 24, title: "Test", mouse: False)
  let _ = config.width
  let _ = config.height
  let _ = config.title
  let _ = config.mouse
  Nil
}
