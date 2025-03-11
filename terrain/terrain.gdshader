shader_type spatial;

//render_mode wireframe;

uniform sampler2D heightmap: filter_nearest_mipmap;
//uniform sampler2D normalmap: filter_linear;
uniform sampler2D gradient: repeat_disable;

uniform float height_scale;

varying float height;
//varying float h = 0.0;

vec3 heightToNormal(float h,float strength, vec2 uv, vec3 vertex) {

	vec2 texelSize = 1.0 / vec2(textureSize(heightmap, 0)); // Dimensione di un texel

	vec3 worldDerivativeX = dFdx(vertex) * 0.5;
    vec3 worldDerivativeY = dFdy(vertex) * 0.5;

	vec3 normal = normalize(cross(worldDerivativeX, worldDerivativeY));

    vec3 crossX = cross(normal, worldDerivativeX);
    vec3 crossY = cross(worldDerivativeY, normal);
    float d = dot(worldDerivativeX,crossY);
    float sgn = d < 0.0 ? (-1.0) : 1.0;
    float surface = sgn / max(0.00000000000001192093, abs(d));

    float dHdx = dFdx(h);
    float dHdy = dFdy(h);
    vec3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
    return normalize(normal - (strength * surfGrad));
}


void vertex() {
	// Called for every vertex the material is visible on

	height = texture(heightmap, UV).r * height_scale;

	VERTEX.y = height;
}

void fragment() {



	// vec3 normal_map = texture(normalmap, UV).rgb;
  //   normal_map = normal_map * 2.0 - 1.0;
	// normal_map.xy *= 1.0;

  //   // Costruisci la matrice di trasformazione tangent-to-world
  //   mat3 tbn = mat3(TANGENT, BINORMAL, NORMAL);

  //   // Converti la normale dal tangent space al world space
  //   vec3 world_normal = tbn * normal_map;

	// NORMAL = normalize(world_normal);

	//float min_height = 30.0;
	//float max_height = 100.0;
	//
    //float normalized_height = (height - min_height) / (max_height - min_height);
    //vec3 color = texture(gradient, vec2(normalized_height, 0.5)).rgb; // Campiona la texture gradiente
	//vec4 hm = texture(heightmap, UV);
    //ALBEDO = texture(heightmap, UV).rrr;
	//vec4 world_vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	//vec3 model_vertex = (inverse(MODEL_MATRIX) * world_vertex).xyz;
	//float gradient_uv = (model_vertex.y / height) + 0.5;
	//ALBEDO = texture(gradient, vec2(gradient_uv)).rgb;

	ALBEDO = texture(heightmap, UV).rrr;

    //ALBEDO =  texture(heightmap, UV).rrr;
	//NORMAL = heightToNormal(height, 0.01, UV, VERTEX);


	float edge = 0.01;
	if (UV.x < edge || UV.x > (1.0 - edge) || UV.y < edge || UV.y > (1.0 - edge)) {
		ALBEDO += vec3(0.1,0,0);
	}

	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
