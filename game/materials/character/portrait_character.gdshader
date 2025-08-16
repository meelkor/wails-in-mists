// Shader used for rendering characters in portrait (no changes to light
// compared to characters ingame)
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back;

#include "./character_fragment.gdshaderinc"
