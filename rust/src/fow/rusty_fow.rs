use std::ops::{Add, Sub, AddAssign, SubAssign, Mul, Div};

use godot::{engine::{image::Format, IMeshInstance3D, Image, ImageTexture, MeshInstance3D, ShaderMaterial}, prelude::*};
use stackblur_iter::{blur, imgref::ImgRefMut};

const PX_PER_METER: i32 = 1;
const SIGHT_DISANCE_M: i32 = 5;
const SIGHT_RADIUS_PX: i32 = SIGHT_DISANCE_M * PX_PER_METER;
const SIGHT_DISANCE_PX_SQUARED: i32 = SIGHT_RADIUS_PX.pow(2);

const EXPLORED: u8 = 200;
const UNEXPLORED: u8 = 255;

/// Node which renders fog of war over area configured by setup method
#[derive(GodotClass)]
#[class(init, base=MeshInstance3D)]
pub struct RustyFow {
    base: Base<MeshInstance3D>,
    #[init(default = 0)]
    width_px: i32,
    /// For now needs to be manually specified since since I didn't find a nice
    /// way to get AABB info from Terrain3D.
    ///
    /// todo: create aabb gizmo using plugin?
    #[export]
    #[init(default = Aabb { position: Vector3::ZERO, size: Vector3::ZERO })]
    bounds: Aabb,
    #[init(default = 0)]
    height_px: i32,
    /// Image data containing mask of previously explored area. The currently
    /// observed area is not baked into this array, as it serves as base image
    /// for each frame
    #[init(default = PackedByteArray::new())]
    explored_mask: PackedByteArray,
}

#[godot_api]
impl IMeshInstance3D for RustyFow {

    /// Initialize the mesh. Nothing is displayed until this method is called.
    fn ready(&mut self) -> () {
        // Hidden by default so it's not visible in editor
        self.base_mut().set_visible(true);

        let width_m = self.bounds.size.x.ceil();
        let height_m = self.bounds.size.z.ceil();

        let mut mat = self.get_shader_material();
        mat.set_shader_parameter("fow_color".into(), Vector3::new(0.0, 0.0, 0.0).to_variant());
        mat.set_shader_parameter("fow_size".into(), Vector2::new(width_m, height_m).to_variant());

        self.width_px = ((PX_PER_METER as f32) * width_m).ceil() as i32;
        self.height_px = ((PX_PER_METER as f32) * height_m).ceil() as i32;

        self.explored_mask.resize((self.width_px * self.height_px) as usize);
        self.explored_mask.fill(UNEXPLORED);
    }
}

#[godot_api]
impl RustyFow {

    /// Update the FoW map assuming observing characters are currently as given
    /// positions
    #[func]
    pub fn update(&mut self, positions: Array<Vector3>) -> () {
        let mut changed = false;
        let px_per_meter_f32 = PX_PER_METER as f32;
        let box_size = SIGHT_RADIUS_PX * 2;
        let n_of_px_in_box = box_size.pow(2);
        for pos in positions.iter_shared() {
            // This won`'t work correctly since we need to add the fow
            // position. If the fow starts at (-1,-1), then 1,1 isn't
            // actually 1,1.
            let pos_pixel_x = (pos.x * px_per_meter_f32).round() as i32;
            let pos_pixel_y = (pos.z * px_per_meter_f32).round() as i32;
            let top = pos_pixel_y - SIGHT_RADIUS_PX;
            let left = pos_pixel_x - SIGHT_RADIUS_PX;

            for i in 0..n_of_px_in_box {
                let x: i32 = left + i % box_size;
                let y: i32 = top + i / box_size;

                if x >= 0 && x < self.width_px && y >= 0 && y < self.height_px {
                    let observed = (pos_pixel_x - x).pow(2) + (pos_pixel_y - y).pow(2) < SIGHT_DISANCE_PX_SQUARED;
                    if observed {
                        let real_i = (x + y * self.width_px) as usize;
                        if self.explored_mask[real_i] != EXPLORED {
                            self.explored_mask[real_i] = EXPLORED;
                            changed = true;
                        }
                    }
                }
            }
        }

        let pos_data: PackedFloat32Array = positions.iter_shared().flat_map(|vec3| [vec3.x, vec3.y, vec3.z]).collect();
        self.upload_position_texture(pos_data.to_byte_array(), positions.len());
        if changed {
            let mut blurred: Vec<u8> = self.explored_mask.to_vec();
            let mut img = ImgRefMut::new(&mut blurred, self.width_px as usize, self.height_px as usize);
            blur(&mut img, 5, |v| StackBlurrableU32(*v as u32), |v| v.0 as u8);
            self.upload_texture(PackedByteArray::from(blurred));
        }
    }

    fn upload_texture(&mut self, image_data: PackedByteArray) -> () {
        let image_opt = Image::create_from_data(self.width_px, self.height_px, false, Format::R8, image_data);
        let image = image_opt.expect("Image wasn't created from image data");
        let tex = ImageTexture::create_from_image(image).expect("Could not create texture");
        let mut mat = self.get_shader_material();
        mat.set_shader_parameter("fow_texture".into(), tex.to_variant());
    }

    fn upload_position_texture(&mut self, image_data: PackedByteArray, count: usize) -> () {
        let image_opt = Image::create_from_data(count as i32, 1, false, Format::RGBF, image_data);
        let image = image_opt.expect("Image wasn't created from image data");
        let tex = ImageTexture::create_from_image(image).expect("Could not create texture");
        let mut mat = self.get_shader_material();
        mat.set_shader_parameter("positions_texture".into(), tex.to_variant());
    }

    fn get_shader_material(&mut self) -> Gd<ShaderMaterial> {
        let mesh = self.base().get_mesh().expect("FoW has no mesh");
        let material = mesh.surface_get_material(0).expect("Mesh has no material");
        return material.cast::<ShaderMaterial>();
    }
}

// Modified version of StackBlurrableU32 provided in the stackblur_iter
#[derive(Copy, Clone, Eq, PartialEq, Debug, Default)]
pub struct StackBlurrableU32(pub u32);

impl Add for StackBlurrableU32 {
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        Self(self.0.wrapping_add(rhs.0))
    }
}

impl Sub for StackBlurrableU32 {
    type Output = Self;

    fn sub(self, rhs: Self) -> Self::Output {
        Self(self.0.wrapping_sub(rhs.0))
    }
}

impl AddAssign for StackBlurrableU32 {
    fn add_assign(&mut self, rhs: Self) {
        self.0 = self.0.wrapping_add(rhs.0);
    }
}

impl SubAssign for StackBlurrableU32 {
    fn sub_assign(&mut self, rhs: Self) {
        self.0 = self.0.wrapping_sub(rhs.0);
    }
}

impl Mul<usize> for StackBlurrableU32 {
    type Output = Self;

    fn mul(self, rhs: usize) -> Self::Output {
        Self(self.0.wrapping_mul(rhs as u32))
    }
}

impl Div<usize> for StackBlurrableU32 {
    type Output = Self;

    fn div(self, rhs: usize) -> Self::Output {
        Self(self.0.wrapping_div(rhs as u32))
    }
}
