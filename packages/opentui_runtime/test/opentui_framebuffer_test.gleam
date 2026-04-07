import gleeunit/should
import opentui/buffer
import opentui/framebuffer

pub fn framebuffer_create_destroy_test() {
  let assert Ok(fb) = framebuffer.create(10, 8, "fb_test")
  let _ = framebuffer.width(fb) |> should.equal(10)
  let _ = framebuffer.height(fb) |> should.equal(8)
  framebuffer.destroy(fb)
}

pub fn framebuffer_resize_test() {
  let assert Ok(fb) = framebuffer.create(10, 8, "fb_resize")
  framebuffer.resize(fb, 20, 12)
  let _ = framebuffer.width(fb) |> should.equal(20)
  let _ = framebuffer.height(fb) |> should.equal(12)
  framebuffer.destroy(fb)
}

pub fn framebuffer_draw_onto_test() {
  let assert Ok(src) = framebuffer.create(5, 5, "fb_src")
  let assert Ok(dst) = framebuffer.create(10, 10, "fb_dst")
  buffer.fill_rect(src, 0, 0, 5, 5, #(1.0, 0.0, 0.0, 1.0))
  // Should not crash
  framebuffer.draw_onto(dst, 2, 2, src)
  framebuffer.destroy(src)
  framebuffer.destroy(dst)
}

pub fn framebuffer_draw_region_test() {
  let assert Ok(src) = framebuffer.create(20, 20, "fb_big")
  let assert Ok(dst) = framebuffer.create(10, 10, "fb_crop")
  buffer.fill_rect(src, 0, 0, 20, 20, #(0.0, 1.0, 0.0, 1.0))
  // Crop a 5x5 region from (3,3) in source
  framebuffer.draw_region(dst, 0, 0, src, 3, 3, 5, 5)
  framebuffer.destroy(src)
  framebuffer.destroy(dst)
}
