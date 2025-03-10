class_name Chunk extends StaticBody3D

var shader = preload("res://terrain/terrain.gdshader")

var index: Vector2i

var lod:= {
	meshes = [],
	index = 0,
	type = 4
}


# var img: Image
# var texture: ImageTexture
var mesh_instance:= MeshInstance3D.new()
var collision:= CollisionShape3D.new()
# var heightmap:= HeightMapShape3D.new()
var neighbors: Array[Chunk] = []

var heightmap:= {
	len = 0,
	half_size = 0,
	height = 0.0,
	image = Image,
	texture = ImageTexture,
	shape = HeightMapShape3D.new(),
	offset = Vector2.ZERO
}

var img_len: int;

func _init(i: Vector2i, size: int, meshes: Array): # material: ShaderMaterial, get_noise: Callable
	index = i
	lod.meshes = meshes
	neighbors.resize(9)

	heightmap.len = size + 1
	heightmap.half_size = size / 2
	heightmap.offset = Vector2(index) * Vector2(size, size)
	heightmap.image = Image.create(heightmap.len, heightmap.len, true, Image.FORMAT_RF)
	heightmap.texture = ImageTexture.create_from_image(heightmap.image)

	# heightmap.shape.map_width = heightmap.len
	# heightmap.shape.map_depth = heightmap.len

	collision.shape = heightmap.shape

	mesh_instance.mesh = lod.meshes[lod.index][lod.type]

	mesh_instance.material_override = ShaderMaterial.new()
	mesh_instance.material_override.shader = shader

	# img_len = size + 1
	# img = Image.create(img_len, img_len, false, Image.FORMAT_RF)

	# var offset = Vector2(index) * Vector2(size, size)

	# mesh_instance.material_override = material.duplicate()

	# for y in img_len:
	# 	for x in img_len:
	# 		var value:= 0.0
	# 		value = get_noise.call(float(x + offset.x), float(y + offset.y))

	# 		img.set_pixel(x,y, Color(value, 0, 0))

	# texture = ImageTexture.create_from_image(img)

	# heightmap.map_depth = img_len
	# heightmap.map_width = img_len

	

	# height_scale = mesh_instance.material_override.get_shader_parameter("height_scale")

	# generate_collision()

	add_child(mesh_instance)
	add_child(collision)


func set_material(height: float, get_noise: Callable):

	for y in heightmap.len:
		for x in heightmap.len:
			var value:= 0.0
			value = get_noise.call(float(x + heightmap.offset.x), float(y + heightmap.offset.y))
			heightmap.image.set_pixel(x,y, Color(value, 0, 0))

	heightmap.texture.update(heightmap.image)

	mesh_instance.material_override.set_shader_parameter("heightmap", heightmap.texture)
	mesh_instance.material_override.set_shader_parameter("height_scale", height)

	var normal_map:= Image.create(heightmap.len, heightmap.len, true, Image.FORMAT_RGB8)

	for y in heightmap.len:
		for x in heightmap.len:
			var value:= normal_color(x,y,heightmap.image, heightmap.len)
			normal_map.set_pixel(x,y, value)

	mesh_instance.material_override.set_shader_parameter("normalmap", ImageTexture.create_from_image(normal_map))

	var path:= "res://data/{y}_{x}.png"
	normal_map.save_png(path.format({x=index.x,y=index.y}))

	if height != heightmap.height:
		heightmap.height = height

		collision.shape.update_map_data_from_image(heightmap.image, 0.0, height)

		# var map_data = heightmap.image.get_data().to_float32_array()

		# for i in map_data.size():
		# 	map_data[i] *= height

		# heightmap.shape.map_data = map_data
		# collision.shape = heightmap.shape

	pass



# func generate_collision():
# 	var map_data = img.get_data().to_float32_array()

# 	for i in map_data.size():
# 		map_data[i] *= height_scale

# 	heightmap.map_data = map_data
# 	collision.shape = heightmap


func snap_to_pixel(hit_position: Vector3) -> Vector2:
	
	# var img_size:= img.get_size()
	hit_position -= position
	var pos:= Vector2(hit_position.x + heightmap.half_size, hit_position.z + heightmap.half_size).round()
	# printraw("\r" + str(pos))
	return pos
	# var brush_len = brush.image.get_size().x
	# var brush_size = brush_len / 2
	# var pixel_offset = Vector2i(pos.x - brush_size, pos.y - brush_size)

func get_pixel(x: int, y: int) -> Color:
	return heightmap.image.get_pixel(x,y)


var map_data_update:= {}

func set_pixel(x: int, y: int, color: Color):
	heightmap.image.set_pixel(x, y, color)
	map_data_update[y * img_len + x] = color.r * heightmap.height

	# map_data_update[y * img_len + x] = color.r * height_scale

func update_img():
	heightmap.texture.update(heightmap.image)
	# questa funzione viene chiamata a pennellata finita

func set_LOD(lod_index: int):
	lod.index = lod_index
	mesh_instance.mesh = lod.meshes[lod.index][lod.type]

func save():
	pass

# func set_data(data: PackedByteArray):
# 	img.set_data(img_len, img_len, false, Image.FORMAT_RF, data)
# 	mesh_instance.material_override.set_shader_parameter("heightmap", ImageTexture.create_from_image(img))

func normal_color(x: int, y: int, img: Image, size: int) -> Color:

	# var h_c = img.get_pixel(x, y).r
	var h_dx = img.get_pixel(min(x + 1, size - 1), y).r
	var h_sx = img.get_pixel(max(x - 1, 0), y).r
	var h_t = img.get_pixel(x, max(y - 1, 0)).r
	var h_b = img.get_pixel(x, min(y + 1, size - 1)).r

	var dx = (h_dx - h_sx) * 0.5 * 5.0
	var dy = (h_t - h_b) * 0.5 * 5.0
	var dz = 1.0

	var normal = Vector3(dx, dy, dz).normalized()
	var color = Color((normal.x + 1.0) * 0.5, (normal.y + 1.0) * 0.5, (normal.z + 1.0) * 0.5)

	return color

