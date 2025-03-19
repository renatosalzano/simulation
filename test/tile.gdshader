shader_type spatial;

uniform sampler2D hm: filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX.y = texture(hm, UV).r * 50.;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(hm, UV).rrr;
	float edge = 0.01;
	if (UV2.x < edge || UV2.x > (1.0 - edge) || UV2.y < edge || UV2.y > (1.0 - edge)) {
		//ALBEDO = color;
		//ALBEDO = vec3(0.5,0,0);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
