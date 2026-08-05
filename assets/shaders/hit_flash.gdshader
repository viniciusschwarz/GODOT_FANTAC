shader_type canvas_item;

uniform bool hit = false;
uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (hit && col.a > 0.0) {
		COLOR = hit_color;
	} else {
		COLOR = col;
	}
}
