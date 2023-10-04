use godot::{prelude::*, engine::{MeshInstance3D, Image, ImageTexture, image::Format, ShaderMaterial}};

const PX_PER_METER: i32 = 4;
const SIGHT_DISANCE_M: i32 = 10;
const SIGHT_RADIUS_PX: i32 = SIGHT_DISANCE_M * PX_PER_METER;
const SIGHT_DISANCE_PX_SQUARED: i32 = SIGHT_RADIUS_PX.pow(2);

const OBSERVED: u8 = 0;
const EXPLORED: u8 = 100;
const UNEXPLORED: u8 = 255;

/// Node which renders fog of war over area configured by setup method
#[derive(GodotClass)]
#[class(base=MeshInstance3D)]
pub struct RustyFow {
    #[base]
    base: Base<MeshInstance3D>,
    width_px: i32,
    height_px: i32,
    /// Image data containing mask of previously explored area. The currently
    /// observed area is not baked into this array, as it serves as base image
    /// for each frame
    explored_mask: PackedByteArray,
}

#[godot_api]
impl NodeVirtual for RustyFow {

    fn init(base: Base<MeshInstance3D>) -> Self {
        Self {
            base,
            height_px: 0,
            width_px: 0,
            explored_mask: PackedByteArray::new(),
        }
    }
}

#[godot_api]
impl RustyFow {

    /// Initialize the mesh. Nothing is displayed until this method is called.
    #[func]
    pub fn setup(&mut self, terrain_aabb: Aabb) -> () {
        let width_m = terrain_aabb.size.x.ceil();
        let height_m = terrain_aabb.size.z.ceil();
        self.base.set_position(terrain_aabb.position);
        self.base.set_scale(Vector3::new(width_m, 1.0, height_m));

        let test_pos = Vector3::new(0.0, 0.0, 0.0);

        self.width_px = ((PX_PER_METER as f32) * width_m).ceil() as i32;
        self.height_px = ((PX_PER_METER as f32) * height_m).ceil() as i32;

        self.explored_mask.resize((self.width_px * self.height_px) as usize);
        self.explored_mask.fill(UNEXPLORED);

        self.update(Array::from_iter([test_pos]));
    }

    /// Update the FoW map assuming observing characters are currently as given
    /// positions
    #[func]
    pub fn update(&mut self, positions: Array<Vector3>) -> () {
        let mut image_data = self.explored_mask.clone();
        let px_per_meter_f32 = PX_PER_METER as f32;
        let box_size = SIGHT_RADIUS_PX * 2;
        let n_of_px_in_box = box_size.pow(2);
        for pos in positions.iter_shared() {
            // This won`'t work correctly since we need to add the fow
            // position. If the fow starts at (-1,-1), then 1,1 isn't
            // actually 1,1.
            let pos_pixel_x = (pos.x.round() * px_per_meter_f32) as i32;
            let pos_pixel_y = (pos.z.round() * px_per_meter_f32) as i32;
            let top = pos_pixel_y - SIGHT_RADIUS_PX;
            let left = pos_pixel_x - SIGHT_RADIUS_PX;

            for i in 0..n_of_px_in_box {
                let x: i32 = left + i % box_size;
                let y: i32 = top + i / box_size;

                if x >= 0 && x < self.width_px && y >= 0 && y < self.height_px {
                    let observed = (pos_pixel_x - x).pow(2) + (pos_pixel_y - y).pow(2) < SIGHT_DISANCE_PX_SQUARED;
                    if observed {
                        let real_i = (x + y * self.width_px) as usize;
                        image_data.set(real_i, OBSERVED);
                        self.explored_mask.set(real_i, EXPLORED);
                    }
                }

            }
        }

        self.upload_texture(image_data);
    }

    fn upload_texture(&mut self, image_data: PackedByteArray) -> () {
        let image_opt = Image::create_from_data(self.width_px, self.height_px, false, Format::FORMAT_R8, image_data);
        let image = image_opt.expect("Image wasn't created from image data");
        let tex = ImageTexture::create_from_image(image).expect("Could not create texture");
        let mesh = self.base.get_mesh().expect("FoW has no mesh");
        let material = mesh.surface_get_material(0).expect("Mesh has no material");
        let mut std_mat = material.cast::<ShaderMaterial>();
        std_mat.set_shader_parameter("tex".into(), tex.to_variant());
    }
}
