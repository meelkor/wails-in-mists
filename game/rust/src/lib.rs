mod fow;
mod navigation;

use godot::prelude::*;

struct RustyMistsExtension;

#[gdextension]
unsafe impl ExtensionLibrary for RustyMistsExtension {}

