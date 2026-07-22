shader_type canvas_item;

// Filtro CRT desactivado: conserva la imagen original sin curvatura,
// scanlines, viñeta, ruido ni reducción de brillo.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	COLOR = texture(screen_texture, SCREEN_UV);
}
