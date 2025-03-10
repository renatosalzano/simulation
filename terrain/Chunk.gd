class_name Chunk extends StaticBody3D

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
var height_scale: float;

func _init(i: Vector2i, size: int, meshes: Array): # material: ShaderMaterial, get_noise: Callable
	index = i
	lod.meshes = meshes
	neighbors.resize(9)

	heightmap.len = size + 1
	heightmap.half_size = size / 2
	heightmap.offset = Vector2(index) * Vector2(size, size)
	heightmap.image = Image.create(heightmap.len, heightmap.len, true, Image.FORMAT_RF)
	heightmap.texture = ImageTexture.create_from_image(heightmap.image)

	heightmap.shape.map_width = heightmap.len
	heightmap.shape.map_depth = heightmap.len

	collision.shape = heightmap.shape

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

	mesh_instance.mesh = lod.meshes[lod.index][lod.type]
	# mesh_instance.material_override.set_shader_parameter("heightmap", texture)

	# height_scale = mesh_instance.material_override.get_shader_parameter("height_scale")

	# generate_collision()

	add_child(mesh_instance)
	add_child(collision)


func set_material(material: ShaderMaterial, get_noise: Callable):
	mesh_instance.material_override = material.duplicate()
	var height: float = mesh_instance.material_override.get_shader_parameter("height_scale")

	for y in heightmap.len:
		for x in heightmap.len:
			var value:= 0.0
			value = get_noise.call(float(x + heightmap.offset.x), float(y + heightmap.offset.y))
			heightmap.image.set_pixel(x,y, Color(value, 0, 0))

	heightmap.texture.update(heightmap.image)

	mesh_instance.material_override.set_shader_parameter("heightmap", heightmap.texture)

	if height != heightmap.height:
		heightmap.height = height

		var map_data = heightmap.image.get_data().to_float32_array()

		for i in map_data.size():
			map_data[i] *= height

		heightmap.shape.map_data = map_data
		collision.shape = heightmap.shape

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

class Collision extends CollisionShape3D:
	var chunk: Chunk

