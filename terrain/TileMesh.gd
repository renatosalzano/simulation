class_name TileMesh extends PlaneMesh

var index: Vector2i
var offset: Vector2

var img: Image
var mesh_arrays: Array
var array_mesh:= ArrayMesh.new()

var vertex: PackedVector3Array
var uvs: PackedVector2Array

func _init(i: Vector2i, square_size: int):
	index = i
	subdivide_depth = square_size - 1
	subdivide_width = square_size - 1
	size = Vector2i(square_size, square_size)

	offset = Vector2(-index) * square_size

	var w:= square_size + 1
	var h:= square_size + 1
	img = Image.create(w, h, false, Image.FORMAT_RF)

	mesh_arrays = get_mesh_arrays()
	uvs = mesh_arrays[ArrayMesh.ARRAY_TEX_UV]


func create(noise: FastNoiseLite):

	var idx:= 0
	var img_size:= img.get_size().x
	print('create tile with size: ',  noise)

	for y in range(img_size - 1, -1, -1):
		for x in range(img_size - 1, -1, -1):

			var value:= 0.0
			if noise:
				value = clamp(noise.get_noise_2d(float(x + offset.x), float(y + offset.y)), -1.0, 1.0) + 1.0
				value /= 2

			img.set_pixel(x,y, Color(value, value, value))

			uvs[idx] = Vector2((x + 0.5) / img_size, (y + 0.5) / img_size)
			# vertex[idx].y = value * 15.0
			idx += 1

			
		


func get_mesh() -> ArrayMesh:
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	return array_mesh

func get_shape():
	return array_mesh.create_trimesh_shape()

	# var surface = SurfaceTool.new()
	# surface.create_from(array_mesh, 0)

	# surface.generate_normals()
	# surface.generate_tangents()

	# return surface.commit()


func get_texture():
	return ImageTexture.create_from_image(img)

func get_texture_size():
	return img.get_size()

	
	











