use godot::{builtin::math::ApproxEq, classes::{mesh::{ArrayType, PrimitiveType}, ArrayMesh, INavigationRegion3D, NavigationMesh, NavigationRegion3D}, meta::ParamType, obj::IndexEnum, prelude::*};
use geo::{Polygon, LineString, MultiPolygon};
use earcutr::{earcut, flatten};
use geo::BooleanOps;

const INDEX_VERTICES: bool = true;

/// NavigationRegion3D which allows procedurally cutting holes into the initial
/// navmesh. That way we can make positions where characters are standing
/// un-navigable without re-baking the mesh.
#[derive(GodotClass)]
#[class(init, base=NavigationRegion3D)]
pub struct Navigation {
    base: Base<NavigationRegion3D>,

    /// Initial navmesh that is used as template whenever creating new navmesh
    template: Option<Vec<Triangle>>,
}

#[godot_api]
impl INavigationRegion3D for Navigation {

    /// Prepare the navmesh template
    fn ready(&mut self) -> () {
        let mut navmesh = self.base().get_navigation_mesh().expect("Navigation node is missing navigation mesh");
        let vertices = navmesh.get_vertices();
        let p_count = navmesh.get_polygon_count();
        let mut mesh = Vec::<Triangle>::new();
        for p_i in 0..p_count {
            let indices = navmesh.get_polygon(p_i);
            let v0 = vertices[indices[0] as usize];
            let v1 = vertices[indices[1] as usize];
            let v2 = vertices[indices[2] as usize];
            mesh.push((v0, v1, v2));
        }

        self.template = Some(mesh);
    }

}

#[godot_api]
impl Navigation {

    /// Check whether closest point on current navmesh is close enough for
    /// given position to be considerable as navigable to
    #[func]
    pub fn is_navigable(&mut self, pos: Vector3) -> bool {
        let map_rid = self.base().get_navigation_map();
        let nav_server = godot::classes::NavigationServer3D::singleton();
        if nav_server.map_get_iteration_id(map_rid) > 0 {
            let pos2 = Vector2::new(pos.x, pos.z);
            let closest = nav_server.map_get_closest_point(map_rid, pos);
            let closest2 = Vector2::new(closest.x, closest.z);
            let delta = pos2 - closest2;
            return delta.length() < 0.2;
        } else {
            return false;
        }
    }

    /// Take the template navmesh and cut holes on given positions and update
    /// the navigation mesh.
    #[func]
    pub fn cut_holes(&mut self, holes: PackedVector3Array) -> () {
        let mut new_mesh = Vec::new();

        for triangle in self.template.as_ref().expect("Missing navmesh template").iter() {
            let clipped_triangles = clip_triangle_against_circle(triangle, &holes.to_vec(), 0.6);
            new_mesh.extend(clipped_triangles);
        }

        let mut arrays: Array<Variant> = Array::new();
        arrays.resize(ArrayType::MAX.to_index(), Variant::nil().owned_to_arg());

        if INDEX_VERTICES {
            let mut vertices: Vec<Vector3> = Vec::new();
            let mut indices: Vec<i32> = Vec::new();

            // todo: O(n^2) :((, come up with a way to hashmap vectors
            for new_vertex in new_mesh {
                let i = vertices.iter().position(|vertex| new_vertex.approx_eq(vertex));
                if let Some(i) = i {
                    indices.push(i as i32);
                } else {
                    indices.push(vertices.len() as i32);
                    vertices.push(new_vertex);
                }
            }

            arrays.set(ArrayType::VERTEX.to_index(), PackedVector3Array::from(vertices).to_variant().owned_to_arg());
            arrays.set(ArrayType::INDEX.to_index(), PackedInt32Array::from(indices).to_variant().owned_to_arg());
        } else {
            let indices = (0i32..new_mesh.len() as i32).collect::<Vec<i32>>();
            arrays.resize(ArrayType::MAX.to_index(), Variant::nil().owned_to_arg());
            arrays.set(ArrayType::VERTEX.to_index(), PackedVector3Array::from(new_mesh).to_variant().owned_to_arg());
            arrays.set(ArrayType::INDEX.to_index(), PackedInt32Array::from(indices).to_variant().owned_to_arg());
        }

        let mut navmesh_gd = ArrayMesh::new_gd();
        navmesh_gd.add_surface_from_arrays(PrimitiveType::TRIANGLES, &arrays);

        let mut nnm = NavigationMesh::new_gd();
        nnm.create_from_mesh(&navmesh_gd);

        self.base_mut().set_navigation_mesh(&nnm);
    }

}


/// Convert godot Vector3 to 2D geo crate coordinate
fn to_geo_coord(v: &Vector3) -> geo::Coord<f32> {
    geo::Coord { x: v.x, y: v.z }
}

/// Create 2D N-sided circle polygon
fn create_circle(center: &Vector3, radius: f32, sides: usize) -> LineString<f32> {
    let mut points = Vec::with_capacity(sides);
    for i in 0..sides {
        let angle = 2.0 * std::f32::consts::PI * (i as f32) / (sides as f32);
        let x = center.x + radius * angle.cos();
        let y = center.z + radius * angle.sin();
        points.push(geo::Coord { x, y });
    }
    LineString(points)
}

/// Clip a triangle against a circle and return new triangles
fn clip_triangle_against_circle(
    triangle: &Triangle,
    hole_centers: &Vec<Vector3>,
    radius: f32,
) -> Vec<Vector3> {
    let a2d = to_geo_coord(&triangle.0);
    let b2d = to_geo_coord(&triangle.1);
    let c2d = to_geo_coord(&triangle.2);

    let triangle_line = LineString(vec![a2d, b2d, c2d, a2d]);
    let triangle_polygon = Polygon::new(triangle_line, vec![]);

    let hole_polygons = hole_centers.iter()
        // Do not clip holes which are to far on y axis since we are clipping
        // only in 2d space
        .filter(|hole| hole.distance_to(moller_trumbore_intersection(hole, Vector3::DOWN, triangle)) < 1.)
        // And create circle polygons for rest
        .map(|hole_center| {
            let circle_polygon = create_circle(hole_center, radius, 9);
            Polygon::new(circle_polygon, vec![])
        })
        .collect::<Vec<Polygon<f32>>>();

    let mut result = MultiPolygon::new(vec![triangle_polygon]);
    // Clip every hole separately since merging them into multipolygon results
    // in XOR and overlapping circles result in navigable area.
    for hole in hole_polygons {
        result = result.difference(&hole);
    }

    let mut out_vertices = Vec::new();

    for result_poly in result.iter() {
        let rings: Vec<Vec<Vec<_>>> = result_poly.rings().map(|line| line.coords().map(|coord| vec![coord.x, coord.y]).collect()).collect();
        let (coordinates, inners, vecsize) = flatten(&rings);
        let earcut_result = earcut(&coordinates, &inners, vecsize);

        match earcut_result {
            Ok(earcut_result) => {
                for tri in earcut_result.as_slice().chunks_exact(3) {
                    for vertex_i in tri.iter().cloned() {
                        let ray_origin = Vector3::new(coordinates[vertex_i * 2], 0., coordinates[vertex_i * 2 + 1]);
                        let new_pos = moller_trumbore_intersection(&ray_origin, Vector3::DOWN, triangle);
                        out_vertices.push(new_pos);
                    }
                }
            }
            Err(_err) => {
                godot_print!("Something went wrong with earcut lol");
            }
        }

    }

    out_vertices
}

/// Ray-triangle intersection stolen from
/// https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
fn moller_trumbore_intersection(origin: &Vector3, direction: Vector3, triangle: &Triangle) -> Vector3 {
    let e1 = triangle.1 - triangle.0;
    let e2 = triangle.2 - triangle.0;

    let ray_cross_e2 = direction.cross(e2);
    let det = e1.dot(ray_cross_e2);

    let inv_det = 1.0 / det;
    let s = *origin - triangle.0;

    let s_cross_e1 = s.cross(e1);

    // At this stage we can compute t to find out where the intersection point is on the line.
    let t = inv_det * e2.dot(s_cross_e1);

    return *origin + direction * t;
}

type Triangle = (Vector3, Vector3, Vector3);
