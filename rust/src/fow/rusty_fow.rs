use godot::{prelude::*, engine::{MeshInstance3D, StandardMaterial3D, Image, ImageTexture, image::Format, base_material_3d::TextureParam}};

const PX_PER_METER: i32 = 8;
const SIGHT_DISANCE_M: i32 = 10;
const SIGHT_DISANCE_PX_SQUARED: i32 = (SIGHT_DISANCE_M * PX_PER_METER).pow(2);

/// Node which renders fog of war over area configured by setup method
#[derive(GodotClass)]
#[class(base=MeshInstance3D)]
pub struct RustyFow {
    #[base]
    base: Base<MeshInstance3D>,
    width_px: i32,
    height_px: i32,
    image_data: PackedByteArray,
}

#[godot_api]
impl NodeVirtual for RustyFow {

    fn init(base: Base<MeshInstance3D>) -> Self {
        Self {
            base,
            height_px: 0,
            width_px: 0,
            ///
            image_data: PackedByteArray::new(),
        }
    }
}

#[godot_api]
impl RustyFow {

    /// Initialize the mesh. Nothing is displayed until this method is called.
    #[func]
    pub fn setup(&mut self, terrain_aabb: Aabb) -> () {
        godot_print!("yay");
        let width_m = terrain_aabb.size.x.ceil();
        let height_m = terrain_aabb.size.z.ceil();
        self.base.set_position(terrain_aabb.position);
        self.base.set_scale(Vector3::new(width_m, 1.0, height_m));

        let test_pos = Vector3::new(0.0, 0.0, 0.0);

        self.width_px = ((PX_PER_METER as f32) * width_m).ceil() as i32;
        self.height_px = ((PX_PER_METER as f32) * height_m).ceil() as i32;

        self.image_data.resize((self.width_px * self.height_px) as usize);
        self.image_data.fill(255);

        self.update(Array::from_iter([test_pos]));
        self.upload_texture();
    }

    /// Update the FoW map assuming observing characters are currently as given
    /// positions
    #[func]
    pub fn update(&mut self, positions: Array<Vector3>) -> () {
        let mut changed: bool = false;
        let fx_px_per_meter = PX_PER_METER as f32;
        for pos in positions.iter_shared() {
            // This won`'t work correctly since we need to add the fow
            // position. If the fow starts at (-1,-1), then 1,1 isn't
            // actually 1,1.
            let pos_pixel_x = (pos.x.round() * fx_px_per_meter) as i32;
            let pos_pixel_y = (pos.y.round() * fx_px_per_meter) as i32;
            for i in 0..self.image_data.len() {
                let x: i32 = (i as i32) % self.width_px;
                let y: i32 = (i as i32) / self.width_px;
                let current = self.image_data.get(i);
                let observed = (pos_pixel_x - x).pow(2) + (pos_pixel_y - y).pow(2) < SIGHT_DISANCE_PX_SQUARED;
                if observed {
                    if current != 255 {
                        self.image_data.set(i, 255);
                        changed = true;
                    }
                } else {
                    if current == 255 {
                        self.image_data.set(i, 100);
                        changed = true;
                    }
                }
            }
        }

        if changed {
            self.upload_texture();
        }
    }

    fn upload_texture(&mut self) -> () {
        let image_opt = Image::create_from_data(self.width_px, self.height_px, false, Format::FORMAT_R8, self.image_data.to_owned());
        let image = image_opt.expect("Image wasn't created from image data");
        let tex = ImageTexture::create_from_image(image).expect("Could not create texture");
        let mesh = self.base.get_mesh().expect("FoW has no mesh");
        let material = mesh.surface_get_material(0).expect("Mesh has no material");
        let mut std_mat = material.cast::<StandardMaterial3D>();
        std_mat.set_texture(TextureParam::TEXTURE_ALBEDO, tex.upcast());
    }
}
