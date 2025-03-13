shader_type spatial;

//render_mode wireframe;


uniform sampler2D heightmap: filter_linear_mipmap;
uniform float LOD = 0;
uniform sampler2D normal: filter_linear;
uniform sampler2D gradient: repeat_disable;

uniform float height_scale;

varying float height;
varying float vertex_step;
varying vec4 world_pos;
varying vec3 projected_vertex;
//varying float h = 0.0;

float get_height(vec2 uv) {
  return textureLod(heightmap, uv, 0).r;
}


void vertex() {
	// Called for every vertex the material is visible on

	height = texture(heightmap, UV).r * height_scale;

	VERTEX.y = height;
	
	
	
	float edge = 0.01;
	float factor = pow(2.0, LOD);
	vertex_step = (1.0 / float(textureSize(heightmap, 0).x)) * factor;
	
	if (UV.x > (1.0 - edge)) {
		if (VERTEX_ID % 2 != 0) {
			float h1 = texture(heightmap, vec2(UV.x, UV.y - vertex_step)).r * height_scale;
			float h2 = texture(heightmap, vec2(UV.x, UV.y + vertex_step)).r * height_scale;
			VERTEX.y = mix(h1, h2, 0.5);
		}
	}
	
	world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	projected_vertex = (PROJECTION_MATRIX * world_pos).xyz;
	
}


float getDisplacement( float dx, float dy, vec3 uv) {
	return texture(heightmap, uv.xz + vec2( dFdx( uv.x ) * dx, dFdy( uv.z ) * dy ) ).r;
}

void fragment() {
	
	ALBEDO = texture(heightmap, UV).rrr;
	NORMAL_MAP = texture(normal, UV).xyz;

	float edge = 0.001;
	if (UV.x < edge || UV.x > (1.0 - edge) || UV.y < edge || UV.y > (1.0 - edge)) {
		//ALBEDO = color;
		ALBEDO += vec3(0.5,0,0);
	}
	
	//NORMAL = heightToNormal(height, 0.1, VERTEX, NORMAL);

	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
