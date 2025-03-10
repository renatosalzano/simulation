shader_type spatial;

//render_mode wireframe;

uniform sampler2D heightmap: filter_linear;
//uniform sampler2D normalmap: filter_linear;
uniform sampler2D gradient: repeat_disable;

uniform float height_scale;

varying float height;
//varying float h = 0.0;

#define PHONG

varying vec3 vViewPosition;
varying vec3 vNormal;

uniform sampler2D heightMap;
uniform float texelSize;
uniform float texelMaxHeight;

// #include <common>

// #include <uv_pars_vertex>
// #include <uv2_pars_vertex>
// #include <displacementmap_pars_vertex>
// #include <envmap_pars_vertex>
// #include <color_pars_vertex>
// #include <fog_pars_vertex>
// #include <morphtarget_pars_vertex>
// #include <skinning_pars_vertex>
// #include <shadowmap_pars_vertex>
// #include <logdepthbuf_pars_vertex>
// #include <clipping_planes_pars_vertex>

// vec3 getNormal(vec2 uv) {

//     float u = texture2D(heightMap, uv + texelSize * vec2(0.0, -1.0)).r;
//     float r = texture2D(heightMap, uv + texelSize * vec2(-1.0, 0.0)).r;
//     float l = texture2D(heightMap, uv + texelSize * vec2(1.0, 0.0)).r;
//     float d = texture2D(heightMap, uv + texelSize * vec2(0.0, 1.0)).r;

//     vec3 n;
//     n.z = u - d;
//     n.x = r - l;
//     n.y = 1.0 / 256.0;
//     return normalize(n);
// }

// void main() {

//     #include <uv_vertex>
//     #include <uv2_vertex>
//     #include <color_vertex>

//     #include <beginnormal_vertex>

//     #include <begin_vertex>
    
//     vec4 height = texture2D(heightMap, vUv);


//     vec4 worldPosition = modelMatrix * vec4(transformed, 1.0);
//     worldPosition.y += height.r * texelMaxHeight;
//     vec4 mvPosition = viewMatrix * worldPosition;

//     objectNormal = getNormal(vUv);
//     vec3 transformedNormal = objectNormal;
//     transformedNormal = normalMatrix * transformedNormal;
//     vNormal = normalize( transformedNormal );

//     gl_Position = projectionMatrix * mvPosition;

//     #include <logdepthbuf_vertex>
//     #include <clipping_planes_vertex>

//     vViewPosition = - mvPosition.xyz;
// //vNormal = vec3(0.0, 0.0, 1.0);

//     #include <envmap_vertex>
//     #include <shadowmap_vertex>
//     #include <fog_vertex>
// }

vec3 heightToNormal(float h,float strength, vec2 uv, vec3 vertex) {
	
	vec2 texelSize = 1.0 / vec2(textureSize(heightmap, 0)); // Dimensione di un texel

    // Campionamento della heightmap
    float heightCenter = texture(heightmap, uv).r * 1.0;
	
    float heightXPlus = texture(heightmap, uv + vec2(texelSize.x, 0.0)).r * 1.0;
    float heightXMinus = texture(heightmap, uv - vec2(texelSize.x, 0.0)).r * 1.0;
    float heightYPlus = texture(heightmap, uv + vec2(0.0, texelSize.y)).r * 1.0;
    float heightYMinus = texture(heightmap, uv - vec2(0.0, texelSize.y)).r * 1.0;
	
	// Calcolo delle derivate centrali
    float dHdx = (heightXPlus - heightXMinus) / (2.0 * texelSize.x);
    float dHdy = (heightYPlus - heightYMinus) / (2.0 * texelSize.y);

    // Calcolo della normale
    vec3 worldDerivativeX = dFdx(vertex);
    vec3 worldDerivativeY = dFdy(vertex);
	
    vec3 normal = normalize(cross(worldDerivativeX, worldDerivativeY));

    vec3 crossX = cross(normal, worldDerivativeX);
    vec3 crossY = cross(worldDerivativeY, normal);
    float d = dot(worldDerivativeX, crossY);
    float sgn = d < 0.0 ? (-1.0) : 1.0;
    float surface = sgn / max(0.00000000000001192093, abs(d));

    vec3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
	
	return normalize(normal - (strength * surfGrad));

	//vec3 worldDerivativeX = dFdx(vertex);
    //vec3 worldDerivativeY = dFdy(vertex);
	//
	//normal = normalize(cross(worldDerivativeX, worldDerivativeY));
	//
    //vec3 crossX = cross(normal, worldDerivativeX);
    //vec3 crossY = cross(worldDerivativeY, normal);
    //float d = dot(worldDerivativeX,crossY);
    //float sgn = d < 0.0 ? (-1.0) : 1.0;
    //float surface = sgn / max(0.00000000000001192093, abs(d));
//
    //float dHdx = dFdx(h);
    //float dHdy = dFdy(h);
    //vec3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
    //return normalize(normal - (strength * surfGrad));
}

void vertex() {
	// Called for every vertex the material is visible on
	
	height = texture(heightmap, UV).r * height_scale;

	//vec3 worldDerivativeX = dFdx(VERTEX);
	//vec3 worldDerivativeY = dFdy(VERTEX);
	//float dHdx = dFdx(height);
	//float dHdy = dFdy(height);
//
	////calcolo della normale
	//vec3 normal = normalize(cross(worldDerivativeX, worldDerivativeY));
//
	//vec3 crossX = cross(normal, worldDerivativeX);
	//vec3 crossY = cross(worldDerivativeY, normal);
	//float d = dot(worldDerivativeX, crossY);
	//float sgn = d < 0.0 ? (-1.0) : 1.0;
	//float surface = sgn / max(0.00000000000001192093, abs(d));
//
	//vec3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
//
  //// Modifica della normale del vertice
 	//NORMAL = normalize(normal - (1.0 * surfGrad));
	
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
	ALBEDO = texture(heightmap,UV).rrr;
	
	float min_height = 30.0;
	float max_height = 100.0;
	
    float normalized_height = (height - min_height) / (max_height - min_height);
    vec3 color = texture(gradient, vec2(normalized_height, 0.5)).rgb; // Campiona la texture gradiente
	vec4 hm = texture(heightmap, UV);
    ALBEDO = texture(heightmap, UV).rrr;
	
	ALBEDO = heightToNormal(hm.r, 0.1, UV, VERTEX);
	
	float edge = 0.04;
	if (UV.x < edge || UV.x > (1.0 - edge) || UV.y < edge || UV.y > (1.0 - edge)) {
		ALBEDO += vec3(0.0,0,0);
	}
	
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
