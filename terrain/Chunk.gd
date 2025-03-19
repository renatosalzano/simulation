@tool
class_name Chunk extends StaticBody3D

enum NEIGHBORS { TL, T, TR, L, C, R, BL, B, BR }

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

var normal_img: Image
var normal: ImageTexture

func _init(i: Vector2i, size: int, meshes: Array): # material: ShaderMaterial, get_noise: Callable
	index = i
	lod.meshes = meshes
	neighbors.resize(9)

	heightmap.len = size + 1
	heightmap.half_size = size / 2
	heightmap.offset = Vector2(index) * Vector2(size, size)
	heightmap.image = Image.create(heightmap.len, heightmap.len, true, Image.FORMAT_R8)
	heightmap.texture = ImageTexture.create_from_image(heightmap.image)

	normal_img = Image.create(heightmap.len, heightmap.len, false, Image.FORMAT_RGB8)
	normal = ImageTexture.create_from_image(normal_img)

	var s := size / (size - 1.0)
	collision.scale = Vector3(s,s,s)
	collision.shape = heightmap.shape

	mesh_instance.mesh = lod.meshes[lod.index]

	mesh_instance.material_override = ShaderMaterial.new()
	mesh_instance.material_override.shader = shader

	add_child(mesh_instance)
	add_child(collision)


func set_material(height: float, get_noise: Callable):

	for y in heightmap.len:
		for x in heightmap.len:
			var value:= 0.0
			value = get_noise.call(float(x + heightmap.offset.x), float(y + heightmap.offset.y)) + 1.0
			value /= 2.0
			heightmap.image.set_pixel(x,y, Color(value, 0, 0))
	
	heightmap.image.generate_mipmaps(true)
	heightmap.texture.update(heightmap.image)

	mesh_instance.material_override.set_shader_parameter("heightmap", heightmap.texture)
	mesh_instance.material_override.set_shader_parameter("height_scale", height)

	var path:= "res://data/{y}_{x}.exr"
	heightmap.image.save_exr(path.format({x=index.x,y=index.y}))

	# var normal_img:= Image.create(heightmap.len, heightmap.len, true, Image.FORMAT_RGB8)

	# for y in heightmap.len:
	# 	for x in heightmap.len:
	# 		var value:= normal_color(x,y,heightmap.image, heightmap.len)
	# 		normal_img.set_pixel(x,y, value)

	# mesh_instance.material_override.set_shader_parameter("normalmap", ImageTexture.create_from_image(normal_img))

	# var path:= "res://data/{y}_{x}.png"
	# normal_img.save_png(path.format({x=index.x,y=index.y}))

	heightmap.height = height
	collision.shape.update_map_data_from_image(heightmap.image, 0.0, height)
		

		# var map_data = heightmap.image.get_data().to_float32_array()

		# for i in map_data.size():
		# 	map_data[i] *= height

		# heightmap.shape.map_data = map_data
		# collision.shape = heightmap.shape

	pass

func update_material(dict: Dictionary):
	for key in dict:
		mesh_instance.material_override.set_shader_parameter(key, dict[key])

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
	var size:int = heightmap.len - 1
	
	if y < 0:
		if has_neighbor(NEIGHBORS.T):
			return neighbors[NEIGHBORS.T].get_pixel(x, y + size)
		return Color.BLACK
	
	if y > size:
		if has_neighbor(NEIGHBORS.B):
			return neighbors[NEIGHBORS.B].get_pixel(x, y - size)
		return Color.BLACK

	if x < 0:
		if has_neighbor(NEIGHBORS.L): 
			return neighbors[NEIGHBORS.L].get_pixel(x + size, y)
		return Color.BLACK

	if x > size:
		if has_neighbor(NEIGHBORS.R):
			return neighbors[NEIGHBORS.R].get_pixel(x - size, y)
		return Color.BLACK
	
	return heightmap.image.get_pixel(x,y)


var map_data_update:= {}

func set_pixel(x: int, y: int, color: Color):
	heightmap.image.set_pixel(x, y, color)
	map_data_update[y * heightmap.len + x] = color.r * heightmap.height


func update_texture(update_collision = false):
	heightmap.texture.update(heightmap.image)
	if update_collision:
		collision.shape.update_map_data_from_image(heightmap.image, 0.0, heightmap.height)
	

func deferred_update():
	heightmap.texture.update(heightmap.image)


func set_LOD(lod_index: int):
	lod.index = lod_index
	mesh_instance.mesh = lod.meshes[lod.index]
	update_material({ LOD=lod_index })


func gen_normal():

	for y in heightmap.len:
		for x in heightmap.len:
			var value:= normal_color(x, y)
			normal_img.set_pixel(x,y, value)

	normal.update(normal_img)
	update_material({ normal=normal })


func normal_color(x: int, y: int) -> Color:

	# var h_c = img.get_pixel(x, y).r
	var t:= get_pixel(x, y - 1).r
	var b:= get_pixel(x, y + 1).r
	var l:= get_pixel(x - 1, y).r
	var r:= get_pixel(x + 1, y).r

	var dx = (r - l) * 0.5 * 50.0
	var dy = (t - b) * 0.5 * 50.0
	var dz = 1.0

	var n = Vector3(dx, dy, dz).normalized()
	var color = Color((n.x + 1.0) * 0.5, (n.y + 1.0) * 0.5, (n.z + 1.0) * 0.5)

	return color



func has_neighbor(i: NEIGHBORS) -> bool:
	return neighbors[i] != null

func set_neighbor(i: int, chunk: Chunk):
	neighbors[i] = chunk
