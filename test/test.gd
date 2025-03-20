@tool
extends Node3D

@export var noise:= FastNoiseLite.new()

@onready var camera: Camera3D = $Test
# Called when the node enters the scene tree for the first time.
var quads: Array[QuadTree] = []
var tile: TerrainChunk


func create_tile_mesh(size: int, subdiv: int) -> Mesh:

	var mesh:= PlaneMesh.new()
	mesh.subdivide_width = subdiv
	mesh.subdivide_depth = subdiv
	mesh.size = Vector2(size, size)
	mesh.add_uv2 = true

	mesh.custom_aabb.position = Vector3(-size / 2, -1500, -size / 2)
	mesh.custom_aabb.size = Vector3(size, 5000, size)

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

	# print(subdivisions)

	var lod_meshes = []
	lod_meshes.resize(subdivisions.size())

	for lod_index in lod_meshes.size():

		var mesh:= create_tile_mesh(size, subdivisions[lod_index])

		lod_meshes[lod_index] = mesh

	return lod_meshes


var mutex = Mutex.new()
var task_count:= 0
signal task_completed()

func task(chunk_size: Array[int], size: int, offset: Vector2i, n: FastNoiseLite, data: PackedByteArray):
	for y in range(chunk_size[0], chunk_size[1]):
		for x in size:
			var value:= n.get_noise_2d(float(x + offset.x), float(y + offset.y))
			value = clamp(value, -1.0, 1.0) + 1.0
			value *= 0.5
			mutex.lock()
			data[y * size + x] = int(value * 255)
			mutex.unlock()

	call_deferred("on_tasks_end")



func on_tasks_end():
	task_count -= 1
	print(task_count)
	if task_count == 0:
		print("emit task end")
		task_completed.emit()


func generate_texture(size: int, offset: Vector2i) -> ImageTexture:
	var hm:= Image.create(size, size, false, Image.FORMAT_R8)

	var data:= hm.get_data()
	task_count = 8

	var chunk:= []
	chunk.resize(8)
	var y = (size - 1) / 8 # 256

	print(y)

	for i in 8:
		chunk[i] = [i * y, ((i + 1) * y) + (1 if i == 7 else 0)]

	for chunk_y in chunk:
		WorkerThreadPool.add_task(task.bind(chunk_y,size,offset,noise,data))

	print(chunk)

	print('await task')
	await task_completed
	print('task completed')

	# for y in size:
	# 	WorkerThreadPool.add_task(task.bind(y,size,offset,noise,data))
	# 	# for x in size:
	# 	# 	var value:= noise.get_noise_2d(float(x + offset.x), float(y + offset.y))
	# 	# 	value = clamp(value, -1.0, 1.0) + 1.0
	# 	# 	value *= 0.5
	# 	# 	# hm.set_pixel(x, y, Color(value, 0, 0))
	# 	# 	data[y * size + x] = int(value * 255)

	
	hm.set_data(size, size, false, Image.FORMAT_R8, data)
	return ImageTexture.create_from_image(hm)

var last_time:= Time.get_ticks_msec()

func _ready() -> void:
	var meshes:= []

	var size:= 2048
	var min_size:= 512

	generate_quad_mesh(size, min_size, meshes)
	var lod_meshes:= generate_mesh()

	last_time = Time.get_ticks_msec()
	await generate_texture(size + 1, Vector2i(0,0) * size)
	print('generate texture in {time}ms'.format({time=Time.get_ticks_msec() - last_time }))

	return

	var offset:= size / 2

	for x in 2:
		for y in 2:

			last_time = Time.get_ticks_msec()

			var index:= Vector2i(x,y)
			# print(lod_meshes)
			var hm:= await generate_texture(size + 1, index * size)
			print('generate texture in {time}ms'.format({time=Time.get_ticks_msec() - last_time }))
			last_time = Time.get_ticks_msec()

			var quad = QuadTree.new(index, size, min_size, meshes, hm)
			quad.position = Vector3(
					(x * size) - offset,
					0,
					(y * size) - offset
				)
			add_child(quad)
			
			print('generate quad in {time}ms'.format({time=Time.get_ticks_msec() - last_time }))
			last_time = Time.get_ticks_msec()

			quad.set_leafs(lod_meshes)
			quads.append(quad)

			print('set quad leaf in {time}ms'.format({time=Time.get_ticks_msec() - last_time }))
			last_time = Time.get_ticks_msec()
	
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

		for quad in quads:
			quad.test(curr_pos)
		# tile.update(curr_pos)


		# printraw('\r', str(distance))
	pass
