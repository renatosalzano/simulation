shader_type spatial;

//render_mode wireframe;

uniform float level;
uniform vec2 index;
uniform sampler2D hm: filter_nearest;
uniform float quad_scale;
uniform float quad_size;
uniform float height_scale = 50.;

uniform bool is_tile;
uniform int LOD;
uniform int min_LOD;
uniform float max_distance_LOD;
uniform vec3 global_position;
uniform vec3 camera_position;

int calc_LOD(vec3 next_tile) {
	float distance_to = distance(camera_position, next_tile);
	
	if (distance_to >= max_distance_LOD) {
		return min_LOD;
	}
	
	for (int x = 0; x <= min_LOD; ++x) {
		if (distance_to < float((x + 1) * 64)) {
			return x;
		}
	}
	
	return LOD;
	
}

bool LOD_is_lower(vec3 next_tile) {
	float distance_to = distance(camera_position, next_tile);
	
	if (distance_to >= max_distance_LOD) {
		return LOD < min_LOD;
	}
	
	for (int x = 1; x <= min_LOD; ++x) {
		if (distance_to < float(x * 64)) {
			return LOD < x;
		}
	}
	
	return false;
	
}

float calc_middle(vec2 uv, vec2 offset) {
	float h1 = texture(hm, vec2(uv.x - offset.x, uv.y - offset.y)).r * height_scale;
	float h2 = texture(hm, vec2(uv.x + offset.x, uv.y + offset.y)).r * height_scale;
	return mix(h1, h2, 0.5);
}

void vertex() {

	float pixel_size = 1.0 / 2049.;
	float half_pixel = pixel_size / 2.0;
	float factor = pow(2.0, level);
	float size = (2048.0 / factor) + 1.;
	
	if (UV.x == 0.0 || UV.x > 0.99 || UV.y == 0.0 || UV.y > 0.99) {
		//ALBEDO = color;
	}
	
	if (level > 0.) {
		//float uv_scale = 1.0 / pow(2.0, level);
		//vec2 offset = index * (uv_scale - (pixel_size / 2.0));
		//UV = UV * quad_scale + offset;
		//float scale = 1.0 / factor;
		//vec2 offset = index * (pixel_size * size);
		//UV = UV * scale + offset;
	}
	
	
	
	if (is_tile) {
		
		float p_size = 1.0 / 513.;
		
		float distance_to = distance(camera_position, global_position);
		
		vec3 tile_top = global_position + vec3(0, 0, -64);
		vec3 tile_bottom = global_position + vec3(0, 0, 64);
		vec3 tile_left = global_position + vec3(-64, 0, 0);
		vec3 tile_right = global_position + vec3(64, 0, 0);
		
		if (calc_LOD(tile_top) > LOD) {
			if (UV2.y == 0.0 && VERTEX_ID % 2 != 0) {
				float h1 = texture(hm, vec2(UV.x, UV.y - p_size)).r * height_scale;
				float h2 = texture(hm, vec2(UV.x, UV.y + p_size)).r * height_scale;
				//VERTEX.y = 50.0;
			}
		}
		
		
	} else {
		
		
		
	}
	
	VERTEX.y = texture(hm, UV).r * 50.;
	
}

void fragment() {
	
	
	ALBEDO = texture(hm, UV).rrr;
	
	float edge = 0.01;
	if (UV2.x < edge || UV2.x > (1.0 - edge) || UV2.y < edge || UV2.y > (1.0 - edge)) {
		//ALBEDO = color;
		ALBEDO += vec3(0.5,0,0);
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
