

enum TRANSITION_TYPE { CENTER, TOP, LEFT, BOTTOM, RIGHT, TOP_L, TOP_R, BOTTOM_L, BOTTOM_R }

static func generate(size: int):

	var subdivisions: Array[int] = []
	var subdiv: int = size - 1

	var i: int = 0

	while subdiv > 1:
		subdiv /= 1 if i == 0 else 2
		if subdiv - 1 > 0:
			subdivisions.append(subdiv - 1)
		else:
			break
		
		i += 1

	print(subdivisions)

	var lod_meshes = []
	lod_meshes.resize(subdivisions.size())

	var chunk_size = Vector2(size, size)

	for lod_index in lod_meshes.size():
		lod_meshes[lod_index] = []
		lod_meshes[lod_index].resize(9)

		for transition_index in 9:
			lod_meshes[lod_index][transition_index] = draw_tile(chunk_size, subdivisions, lod_index, transition_index)

	return lod_meshes


static func draw_tile(size: Vector2, subdivisions: Array[int], lod_index, transition_type: int) -> ArrayMesh:

	var subdiv:= subdivisions[lod_index]

	var set_aabb:= func (m):
		m.custom_aabb.position = Vector3(-size.x / 2, -1500, -size.y / 2)
		m.custom_aabb.size = Vector3(size.x, 5000, size.y)
		return m

	var mesh:= PlaneMesh.new()
	mesh.subdivide_depth = subdiv
	mesh.subdivide_width = subdiv
	mesh.size = size
	mesh.add_uv2 = true


	var mesh_arrays = mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = mesh_arrays[ArrayMesh.ARRAY_VERTEX]
	var uv_1: PackedVector2Array = mesh_arrays[ArrayMesh.ARRAY_TEX_UV]
	var vertices_to_remove:= vertices_to_delete(subdiv, vertices.size())

	var vertices_on_edge:= subdiv + 2

	
	var texture_size:= size.x
	var edges:= vertices_on_edge - 1
	var pixel:= 1.0 / texture_size
	var half_pixel:= pixel / 2.0

	var factor = int(texture_size / edges)
	pixel = pixel * factor

	var idx:= 0

	for y in range(subdiv + 1, -1, -1):
		for x in range(subdiv + 1, -1, -1):
			uv_1[idx] = Vector2(half_pixel, half_pixel) + Vector2(pixel * x, pixel * y)
			idx += 1

	var array_mesh = ArrayMesh.new()

	if transition_type == 4 || (subdivisions.size() == lod_index - 1):
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
		set_aabb.call(array_mesh)
		return array_mesh
	# 0 1 2
	# 3 4 5
	# 6 7 8

	match transition_type:
		0,1,2:
			for index in vertices_to_remove[0]: 
				vertices[index] = vertices[index + 1]
				uv_1[index] = uv_1[index + 1]
		6,7,8:
			for index in vertices_to_remove[1]:
				vertices[index] = vertices[index - 1]
				uv_1[index] = uv_1[index - 1]

	match transition_type:
		0,3,6:
			for index in vertices_to_remove[2]:
				vertices[index] = vertices[index + vertices_on_edge]
				uv_1[index] = uv_1[index + vertices_on_edge]
		2,5,8:
			for index in vertices_to_remove[3]:
				vertices[index] = vertices[index - vertices_on_edge]
				uv_1[index] = uv_1[index - vertices_on_edge]

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	var surface = SurfaceTool.new()
	surface.create_from(array_mesh, 0)

	surface.generate_normals()
	surface.generate_tangents()
	surface.index()

	var res_mesh = surface.commit()

	set_aabb.call(res_mesh)

	return res_mesh


static func vertices_to_delete(subdiv: int, total: int) -> Array:

	var vertices_on_edge := subdiv + 2

	var vertices_to_remove = [[],[],[],[]]

	var offsets:Array[Vector3i] = [
		Vector3i(1, 1, total - vertices_on_edge), # TOP
		Vector3i(1, 1, 0), # BOTTOM
		Vector3i(vertices_on_edge, vertices_on_edge, 0), # LEFT
		Vector3i(1, vertices_on_edge, 0) # RIGHT
	]

	var prev_index = 1
	for i in (subdiv + 1) / 2:

		i = 1 if i == 0 else prev_index + 2

		var pos_index := 0
		for offset in offsets:
			var vertex_to_remove:= offset.x - 1
			vertex_to_remove += (offset.y * i) + offset.z
			vertices_to_remove[pos_index].push_front(vertex_to_remove)
			
			pos_index += 1
			pass

		prev_index = i
		pass

	return vertices_to_remove


func normal_color(x: int, y: int, img: Image, size: int, height_scale: float):

	# var h_c = img.get_pixel(x, y).r
	var h_dx = img.get_pixel(min(x + 1, size - 1), y).r
	var h_sx = img.get_pixel(max(x - 1, 0), y).r
	var h_t = img.get_pixel(x, max(y - 1, 0)).r
	var h_b = img.get_pixel(x, min(y + 1, size - 1)).r

	var dx = (h_dx - h_sx) * 0.5 * height_scale
	var dy = (h_t - h_b) * 0.5 * height_scale
	var dz = 1.0

	var normal = Vector3(dx, dy, dz).normalized()
	var color = Color((normal.x + 1.0) * 0.5, (normal.y + 1.0) * 0.5, (normal.z + 1.0) * 0.5)

	return color