import gleeunit/should
import opentui/math3d.{Vec3}
import opentui/wireframe

pub fn project_mesh_preserves_vertex_count_test() {
  let mesh =
    wireframe.mesh(
      [Vec3(-0.5, -0.5, 0.0), Vec3(0.5, -0.5, 0.0), Vec3(0.0, 0.5, 0.0)],
      [wireframe.edge(0, 1), wireframe.edge(1, 2)],
    )

  wireframe.project_mesh(mesh, 0.0, 0.0, 0.0, 10.0, 20.0, 10.0)
  |> should.equal([
    wireframe.ProjectedVertex(15, 15, Vec3(-0.5, -0.5, 0.0)),
    wireframe.ProjectedVertex(25, 15, Vec3(0.5, -0.5, 0.0)),
    wireframe.ProjectedVertex(20, 5, Vec3(0.0, 0.5, 0.0)),
  ])
}

pub fn rasterize_clips_to_viewport_test() {
  let mesh =
    wireframe.mesh([Vec3(-0.5, 0.0, 0.0), Vec3(0.5, 0.0, 0.0)], [
      wireframe.edge(0, 1),
    ])
  let projected = [
    wireframe.ProjectedVertex(5, 5, Vec3(-0.5, 0.0, 0.0)),
    wireframe.ProjectedVertex(8, 5, Vec3(0.5, 0.0, 0.0)),
  ]

  wireframe.rasterize(
    mesh,
    projected,
    Vec3(0.0, 0.0, 1.0),
    wireframe.viewport(5, 4, 3, 3),
  )
  |> should.equal([
    wireframe.RasterCell(6, 5, 0xB7, 0.4, False),
  ])
}
