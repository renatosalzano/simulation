class_name QuadTree extends MeshInstance3D

var shader= preload("./test.gdshader")
var material:= ShaderMaterial.new()

var index: Vector2i
var level:= 0
var neighbors: Array = []
var _mesh: Mesh

var size:int
var leaf:= false
var leafs:= []
var radius: float

var chunk: TerrainChunk

var parent: QuadTree

var hm: Image
var hm_offset: Vector2
var hm_tex: ImageTexture

func _init(i: Vector2i, _size: int, min_size: int, meshes: Array, hm: ImageTexture, _level:= 0, _root: QuadTree = null) -> void:
	index = i
	level = _level
	size = _size
	parent = get_parent() if level > 0 else null

	material_override = material
	material_override.shader = shader

	var tile_size:= 2049.0 / pow(2.0, level) + 1.0

	material_override.set_shader_parameter("level", level)
	material_override.set_shader_parameter("hm", hm)
	material_override.set_shader_parameter("index", index)
	material_override.set_shader_parameter("quad_size", 1.0 / size)
	material_override.set_shader_parameter("quad_scale", tile_size / 2049.0)

	# print(size, " ", 1.0 / pow(2, level))

	_mesh = meshes[level]
	
	var root = _root if _root else self


	if size > min_size:

		var child_size: int = size / 2
		var offset:= child_size / 2

		# y x-->
		# |
		# v

		for y in 2:
			for x in 2:
				var child_index:= Vector2i((index.x * 2) + x, (index.y * 2) + y)
				# print("level {level}: {x} {y}".format({ level=level + 1, x=child_index.x, y=child_index.y }))
				# var rect = Rect2i(x * child_size, y * child_size, child_size + 1, child_size + 1)
				# var child_hm:= hm.get_region(rect)
				# qui volevo convertire da region a tile

				var sub_quad:= QuadTree.new(child_index, child_size, min_size, meshes, hm, level + 1, root)

				add_child(sub_quad)

				sub_quad.translate(Vector3(
					(x * child_size) - offset,
					0,
					(y * child_size) - offset
				))
		
		# for child:QuadTree in get_children():
		# 	child.neighbors = get_children()

				
	else:
		leaf = true
		
		root.leafs.append(self)



	if level == 0:
		mesh = _mesh

	var l:= pow(size, 2)
	radius = sqrt(l + l) / 2.0

	pass


var divided:= false

func test(point: Vector3):

	if leaf && divided:
		chunk.update(point)

	var distance:= point.distance_to(global_position) - 384 # max lod in tile

	if distance < radius:
		# printraw("\r inside")
		if !divided:
			divided = true
			subdivide()
		else:
			each(func(q): q.test(point))
	else:
		# printraw("\r outside")
		if divided:
			divided = false
			combine(level)

func subdivide():
	# if leaf: return
	# mesh = null
	# each(func(q): q.mesh = q._mesh)
	mesh = null
	if leaf:
		chunk.enable()
	else:
		each(func(q): q.mesh = q._mesh)




func combine(_level: int):
	if leaf:
		chunk.disable()
	mesh = _mesh if level == _level else null
	each(func(q): q.combine(_level))



func each(callback: Callable):
	for quad in get_children():
		if quad is QuadTree:
			callback.call(quad)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_leafs(meshes: Array, noise: FastNoiseLite):
	print('leafs count ', leafs.size())
	for quad in leafs:
		quad.chunk = TerrainChunk.new(quad.index, 512, meshes, material_override)
		quad.add_child(quad.chunk)
		

func create_hm(noise: FastNoiseLite):

	for y in 513:
		for x in 513:
			var value:= 0.0
			value = noise.get_noise_2d(float(x + hm_offset.x), float(y + hm_offset.y))
			hm.set_pixel(x,y, Color(value, 0, 0))

	hm_tex.update(hm)

