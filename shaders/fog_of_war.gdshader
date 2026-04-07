shader_type canvas_item;
render_mode unshaded;

uniform vec2 viewport_size = vec2(320.0, 180.0);
uniform vec2 player_screen_pos = vec2(160.0, 90.0);
uniform vec2 view_direction = vec2(1.0, 0.0);
uniform float cone_angle_radians = 2.094395;
uniform float inner_radius = 24.0;
uniform float edge_softness = 28.0;
uniform vec4 overlay_color : source_color = vec4(0.015686, 0.019608, 0.031373, 0.86);

void fragment() {
	vec2 pixel = UV * viewport_size;
	vec2 delta = pixel - player_screen_pos;
	float distance_to_player = length(delta);

	vec2 forward = view_direction;
	if (length(forward) < 0.001) {
		forward = vec2(1.0, 0.0);
	}
	forward = normalize(forward);

	float overlay_alpha = overlay_color.a;
	if (distance_to_player <= inner_radius) {
		overlay_alpha = 0.0;
	} else if (distance_to_player > 0.001) {
		vec2 direction_to_pixel = normalize(delta);
		float cone_cos = cos(cone_angle_radians * 0.5);
		float facing = dot(forward, direction_to_pixel);
		float cone_mask = smoothstep(cone_cos - 0.08, cone_cos + 0.02, facing);
		float radius_mask = smoothstep(inner_radius, inner_radius + edge_softness, distance_to_player);
		overlay_alpha *= 1.0 - (cone_mask * radius_mask);
	}

	COLOR = vec4(overlay_color.rgb, overlay_alpha);
}
