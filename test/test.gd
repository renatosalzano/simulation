@tool
extends Node3D

@export var level:= 0:
	set(value): level = max(0, value); if quad: quad.set_level(level)

@export var noise:= FastNoiseLite.new()

@onready var camera: Camera3D = $Test
# Called when the node enters the scene tree for the first time.
var quad: QuadTree
var tile: TerrainChunk


func create_tile_mesh(size: int, subdiv: int) -> Mesh:

	var mesh:= PlaneMesh.new()
	mesh.subdivide_width = subdiv
	mesh.subdivide_depth = subdiv
	mesh.size = Vector2(size, size)
	mesh.add_uv2 = true

	return mesh

	# var mesh_arrays = mesh.get_mesh_arrays()
	# var uv_1: PackedVector2Array = mesh_arrays[ArrayMesh.ARRAY_TEX_UV]

	# var texture_size:= size + 1
	# var edges:= subdiv + 1
	# var pixel:= 1.0 / texture_size
	# var half_pixel:= pixel / 2.0

	# var factor = int(texture_size / edges)
	# pixel = pixel * factor

	# var idx:= 0
	# var uv_cycle:= range(subdiv + 1, -1, -1)

	# for y in uv_cycle:
	# 	for x in uv_cycle:
	# 		uv_1[idx] = Vector2(half_pixel, half_pixel) + Vector2(pixel * x, pixel * y)
	# 		idx += 1

	# var array_mesh = ArrayMesh.new()
	# array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	# return array_mesh



func generate_quad_mesh(size:= 2048, min_size:= 512, output = []):

	var subdiv:= (size / 64) - 1

	var mesh:= create_tile_mesh(size, subdiv)

	output.append(mesh)

	size /= 2
	if size > min_size - 1:
		generate_quad_mesh(size, min_size, output)
	else:
		return output
	

func generate_mesh(size:= 64) -> Array:

	var subdivisions: Array[int] = []
	var subdiv: int = size

	var i: int = 0

	while subdiv > 1:
		subdiv /= 1 if i == 0 else 2
		if subdiv - 1 >= 0:
			subdivisions.append(subdiv - 1)
		else:
			break
		
		i += 1

	print(subdivisions)

	var lod_meshes = []
	lod_meshes.resize(subdivisions.size())

	for lod_index in lod_meshes.size():

		var mesh:= create_tile_mesh(size, subdivisions[lod_index])

		lod_meshes[lod_index] = mesh

	return lod_meshes



func _ready() -> void:
	var meshes:= []

	var size:= 2048
	var min_size:= 512

	generate_quad_mesh(size, min_size, meshes)
	var lod_meshes:= generate_mesh()

	# print(lod_meshes)
	var hm_size:= size + 1
	var hm:= Image.create(hm_size, hm_size, false, Image.FORMAT_R8)

	for y in hm_size:
		for x in hm_size:
			var value:= noise.get_noise_2d(float(x), float(y))
			value = clamp(value, -1.0, 1.0) + 1.0
			value *= 0.5
			hm.set_pixel(x, y, Color(value, 0, 0))

	var hm_tex:= ImageTexture.create_from_image(hm)

	quad = QuadTree.new(Vector2i(0,0), size, min_size, meshes, hm_tex)
	add_child(quad)

	# var leaf = TerrainChunk.new(min_size, lod_meshes)

	quad.set_leafs(lod_meshes, noise)
	
	# quad.calc_area()

	# tile = TerrainChunk.new(min_size, lod_meshes)
	# add_child(tile)
	# tile.enable()

	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var curr_pos:= Vector3.ZERO

func _process(_delta: float) -> void:

	if !is_node_ready(): return

	# printraw("\r camera: "+ str(camera.global_position))

	if curr_pos != camera.global_position:
		curr_pos = camera.global_position
		# var distance:= curr_pos.distance_to(quad.global_position)

		quad.test(curr_pos)
		# tile.update(curr_pos)


		# printraw('\r', str(distance))
	pass
