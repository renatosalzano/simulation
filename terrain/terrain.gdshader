shader_type spatial;

//render_mode wireframe;

uniform sampler2D heightmap: filter_nearest;
//uniform sampler2D normal;
uniform sampler2D gradient: repeat_disable;

uniform float height_scale = 15.0;
uniform float normal_intensity = 0.5;

varying float height;
//varying float h = 0.0;

vec3 heightToNormal(float h, vec3 vertex, vec3 normal) {
	
	vec3 worldDerivativeX = dFdx(vertex);
	vec3 worldDerivativeY = dFdy(vertex);
	
	vec3 crossX = cross(normal, worldDerivativeX);
	vec3 crossY = cross(worldDerivativeY, normal);
	float d = dot(worldDerivativeX, crossY);
	float sgn = d < 0.0 ? (-1.0) : 1.0;
	float surface = sgn / max(0.00000000000001192093, abs(d));

	float dHdx = dFdx(h);
	float dHdy = dFdy(h);
	vec3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
	return normalize(normal - (normal_intensity * surfGrad));
}


void vertex() {
	// Called for every vertex the material is visible on
	
	height = texture(heightmap, UV).r * height_scale;
	
	VERTEX.y = height;
}

void fragment() {
	
	//vec3 normal_map = texture(normal, UV).rgb;
    //normal_map = normal_map * 2.0 - 1.0;
	//normal_map.xy *= normal_intensity;
//
    //// Costruisci la matrice di trasformazione tangent-to-world
    //mat3 tbn = mat3(TANGENT, BINORMAL, NORMAL);
//
    //// Converti la normale dal tangent space al world space
    //vec3 world_normal = tbn * normal_map;
	//
	//NORMAL = normalize(world_normal);
	//ALBEDO = texture(heightmap,UV).rrr;
	
	float min_height = 30.0;
	float max_height = 100.0;
	
    float normalized_height = (height - min_height) / (max_height - min_height);
    vec3 color = texture(gradient, vec2(normalized_height, 0.5)).rgb; // Campiona la texture gradiente
    ALBEDO = texture(heightmap, UV).rrr;
	//NORMAL = heightToNormal(height, VERTEX, NORMAL);
	
	float edge = 0.04;
	if (UV.x < edge || UV.x > (1.0 - edge) || UV.y < edge || UV.y > (1.0 - edge)) {
		ALBEDO += vec3(0.1,0,0);
	}
	
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
