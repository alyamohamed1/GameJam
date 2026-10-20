shader_type canvas_item;

// Mask rect in UV space (0..1 on each axis). Pixels outside the rect are
// drawn as solid black so each monitor only shows its own room — the
// camera view may extend into neighbouring rooms otherwise.
uniform vec4 mask_rect = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	if (UV.x < mask_rect.x || UV.x > mask_rect.z
		|| UV.y < mask_rect.y || UV.y > mask_rect.w) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = texture(TEXTURE, UV);
	}
}
