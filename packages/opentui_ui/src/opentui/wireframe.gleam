import gleam/float
import gleam/int
import gleam/list
import opentui/lighting
import opentui/math3d

pub type Edge {
  Edge(a: Int, b: Int)
}

pub type Mesh3d {
  Mesh3d(vertices: List(math3d.Vec3), edges: List(Edge))
}

pub type Viewport {
  Viewport(left: Int, top: Int, width: Int, height: Int)
}

pub type ProjectedVertex {
  ProjectedVertex(x: Int, y: Int, position: math3d.Vec3)
}

pub type RasterCell {
  RasterCell(x: Int, y: Int, codepoint: Int, brightness: Float, is_vertex: Bool)
}

pub fn edge(a: Int, b: Int) -> Edge {
  Edge(a, b)
}

pub fn mesh(vertices: List(math3d.Vec3), edges: List(Edge)) -> Mesh3d {
  Mesh3d(vertices, edges)
}

pub fn viewport(left: Int, top: Int, width: Int, height: Int) -> Viewport {
  Viewport(left, top, width, height)
}

pub fn project_mesh(
  mesh: Mesh3d,
  rx: Float,
  ry: Float,
  rz: Float,
  scale: Float,
  cx: Float,
  cy: Float,
) -> List(ProjectedVertex) {
  project_vertices(mesh.vertices, rx, ry, rz, scale, cx, cy)
}

pub fn rasterize(
  mesh: Mesh3d,
  projected: List(ProjectedVertex),
  light_dir: math3d.Vec3,
  viewport: Viewport,
) -> List(RasterCell) {
  list.append(
    rasterize_edges(projected, mesh.edges, light_dir, viewport),
    rasterize_vertices(projected, viewport),
  )
}

pub fn shade_char(brightness: Float) -> Int {
  let clamped = float.min(float.max(brightness, 0.0), 1.0)
  let idx = float.truncate(clamped *. 7.0)
  case idx {
    0 -> 0x20
    1 -> 0x2E
    2 -> 0xB7
    3 -> 0x2B
    4 -> 0x2A
    5 -> 0x25
    6 -> 0x23
    _ -> 0x2588
  }
}

fn project_vertices(
  vertices: List(math3d.Vec3),
  rx: Float,
  ry: Float,
  rz: Float,
  scale: Float,
  cx: Float,
  cy: Float,
) -> List(ProjectedVertex) {
  case vertices {
    [] -> []
    [vertex, ..rest] -> {
      let rotated = math3d.rotate_euler(vertex, rx, ry, rz)
      let #(sx, sy) = math3d.project_simple(rotated, scale, cx, cy)
      [
        ProjectedVertex(float.truncate(sx), float.truncate(sy), rotated),
        ..project_vertices(rest, rx, ry, rz, scale, cx, cy)
      ]
    }
  }
}

fn rasterize_edges(
  projected: List(ProjectedVertex),
  edges: List(Edge),
  light_dir: math3d.Vec3,
  viewport: Viewport,
) -> List(RasterCell) {
  case edges {
    [] -> []
    [edge, ..rest] -> {
      let ProjectedVertex(ax, ay, a_pos) = list_at(projected, edge.a)
      let ProjectedVertex(bx, by, b_pos) = list_at(projected, edge.b)
      let mid = math3d.vec3_scale(math3d.vec3_add(a_pos, b_pos), 0.5)
      let normal = math3d.vec3_normalize(mid)
      let brightness = lighting.diffuse(normal, light_dir) *. 0.6 +. 0.4
      list.append(
        points_to_cells(
          line_points(ax, ay, bx, by),
          shade_char(brightness),
          brightness,
          viewport,
        ),
        rasterize_edges(projected, rest, light_dir, viewport),
      )
    }
  }
}

fn rasterize_vertices(
  projected: List(ProjectedVertex),
  viewport: Viewport,
) -> List(RasterCell) {
  case projected {
    [] -> []
    [ProjectedVertex(x, y, _), ..rest] -> {
      let head = case in_viewport(viewport, x, y) {
        True -> [RasterCell(x, y, 0x25CF, 1.0, True)]
        False -> []
      }
      list.append(head, rasterize_vertices(rest, viewport))
    }
  }
}

fn points_to_cells(
  points: List(#(Int, Int)),
  codepoint: Int,
  brightness: Float,
  viewport: Viewport,
) -> List(RasterCell) {
  case points {
    [] -> []
    [#(x, y), ..rest] -> {
      let head = case in_viewport(viewport, x, y) {
        True -> [RasterCell(x, y, codepoint, brightness, False)]
        False -> []
      }
      list.append(head, points_to_cells(rest, codepoint, brightness, viewport))
    }
  }
}

fn in_viewport(viewport: Viewport, x: Int, y: Int) -> Bool {
  x > viewport.left
  && x < viewport.left + viewport.width - 1
  && y > viewport.top
  && y < viewport.top + viewport.height - 1
}

fn line_points(x0: Int, y0: Int, x1: Int, y1: Int) -> List(#(Int, Int)) {
  let dx = int.absolute_value(x1 - x0)
  let dy = int.absolute_value(y1 - y0)
  let sx = case x1 > x0 {
    True -> 1
    False -> -1
  }
  let sy = case y1 > y0 {
    True -> 1
    False -> -1
  }
  bresenham(x0, y0, x1, y1, dx, dy, sx, sy, dx - dy, [])
}

fn bresenham(
  x: Int,
  y: Int,
  x1: Int,
  y1: Int,
  dx: Int,
  dy: Int,
  sx: Int,
  sy: Int,
  err: Int,
  acc: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  let new_acc = [#(x, y), ..acc]
  case x == x1 && y == y1 {
    True -> new_acc
    False -> {
      let e2 = 2 * err
      let #(new_x, new_err_x) = case e2 > 0 - dy {
        True -> #(x + sx, err - dy)
        False -> #(x, err)
      }
      let #(new_y, new_err_y) = case e2 < dx {
        True -> #(y + sy, new_err_x + dx)
        False -> #(y, new_err_x)
      }
      bresenham(new_x, new_y, x1, y1, dx, dy, sx, sy, new_err_y, new_acc)
    }
  }
}

fn list_at(items: List(a), index: Int) -> a {
  case items, index {
    [item, ..], 0 -> item
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> panic as "list_at: index out of bounds"
  }
}
