@tool
class_name Terrain extends Node3D

var utils:= preload('res://terrain/utils.gd')

var build_mesh:= false
var build_chunk:= true

@export_group('Settings', 'set_')

@export var set_camera: Camera3D = null

@export var set_chunk:= Vector3i(3,3,64):
	set(value):
		build_mesh = value.z != set_chunk.z
		build_chunk = true
		set_chunk = value

@export var set_height:= 50.0:
	set(value): set_height = value; update_terrain()

@export var set_lod: int = 0:
	set(value): set_lod = max(0,value); chunks.each(func(chunk): chunk.set_LOD(set_lod))

@export var set_noise: Array[FastNoiseLite] = []:
	set(value): set_noise = value;

@export var set_curve:= Curve.new()

@export var set_gradient:= GradientTexture2D.new():
	set(value): set_gradient = value; if set_gradient: set_gradient.changed.connect(update_material)

@export_tool_button("Update terrain") var set_update = func(): update_terrain()
@export_tool_button("Update material") var set_update_material = update_material;

@export_group('Edit', 'edit_')
@export var edit_brush_preview:= GradientTexture2D.new():
	set(value): edit_brush_preview = value;

@export var edit_brush:= GradientTexture2D.new():
	set(value): edit_brush = value;

@export_range(16, 128, 1) var edit_brush_size:= 16:
	set(value): edit_brush_size = value; enable_brush()

@export var edit_enable_brush:= false:
	set(value): edit_enable_brush = value; enable_brush()

@export var edit_debug:= false:
	set(value): edit_debug = value; debug_brush()

@onready var collision: CollisionShape3D = $StaticBody3D/CollisionShape3D

var brush = Brush.new(self)
var camera: Camera3D

var meshes:= []
var chunks:= Chunks.new(self)
var resource:= TerrainResource.new()

func _ready() -> void:

	if Engine.is_editor_hint():
		camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
		brush.set_brush(edit_brush, edit_brush_preview)

	var cached_meshes = resource.load_meshes()

	if cached_meshes is Array:
		build_mesh = false
		meshes = cached_meshes
		print("stored meshes")
	else:
		build_mesh = true
	
	print("build mesh ", build_mesh)

	update_terrain()

	pass


func get_noise(x: float, y: float) -> float:
	var value:= 0.0
	var amplitude:= 1.0

	for noise in set_noise:

		value += noise.get_noise_2d(x,y)
		value /= set_noise.size()
		value *= amplitude
		amplitude += 0.5



	# Normalizza e applica smoothstep
	value = clamp(value, -1.0, 1.0) + 1.0
	value *= 0.5
	value = set_curve.sample(value)
	value = smoothstep(0.0, 1.0, value)

	return value

func update_terrain():

	print("update terrain")

	if not is_node_ready():
		return

	if build_chunk:

		build_chunk = false

		if build_mesh:
			build_mesh = false
			meshes = utils.generate(set_chunk.z)
			resource.save_meshes(meshes)

		var offset:= Vector2(
			(set_chunk.x - 1) * -set_chunk.z / 2.0,
			(set_chunk.y - 1) * -set_chunk.z / 2.0
		)

		chunks.queue_free()

		remove_child(chunks)

		chunks = Chunks.new(self)

		for x in set_chunk.x:
			for y in set_chunk.y:

				var reposition = Vector3(offset.x + (x * set_chunk.z), 0, offset.y + (y * set_chunk.z))
				var i = Vector2i(x,y)

				var chunk:= Chunk.new(i, set_chunk.z, meshes)
				chunk.set_material(set_height, get_noise)
				chunk.translate(reposition)

				collision.shape.update_map_data_from_image(chunk.heightmap.image, 0.0, set_height)
				collision.position = reposition

				chunks.add(i, chunk)
				
				pass

		# 0 1 2
		# 3 . 5
		# 6 7 8

		var d = [
			Vector2i(-1,-1),Vector2i(0,-1),Vector2i(+1,-1),
			Vector2i(-1, 0),Vector2i(0, 0),Vector2i(+1, 0),
			Vector2i(-1,+1),Vector2i(0,+1),Vector2i(+1,+1),
		]

		for x in set_chunk.x:
			for y in set_chunk.y:
				var idx = Vector2i(x,y)
				var chunk = chunks.get_chunk(idx)

				for i in d.size():
					var neighbor_idx = idx + d[i]
					if chunks.has(neighbor_idx):
						chunk.neighbors[i] = chunks.get_chunk(neighbor_idx)
	else:
		chunks.each(func(chunk):
			chunk.set_material(set_height, get_noise)
			pass
		)
		pass

func update_material():
	chunks.each(func(chunk):
		chunk.update_material({ gradient=set_gradient })
	)
	pass


class Chunks extends Node3D:

	var chunks = {}

	func _init(node: Node) -> void:
		node.add_child(self)

	func add(index: Vector2, chunk: Chunk) -> void:
		chunks[index] = chunk
		add_child(chunk)

	func clear() -> void:
		chunks.clear()

	func has(key: Vector2) -> bool:
		return chunks.has(key)

	func get_chunk(key: Vector2) -> Chunk:
		return chunks[key]

	func each(callable: Callable) -> void:
		for chunk: Chunk in get_children():
			callable.call(chunk)

	func save():
		for chunk in get_children():
			chunk.save()
			pass


func enable_brush():
	brush.enabled = edit_enable_brush
	edit_brush.width = edit_brush_size
	edit_brush.height = edit_brush_size

	if edit_enable_brush:
		brush.show()
		brush.set_brush(edit_brush, edit_brush_preview)
	else:
		brush.hide()
	pass


func debug_brush():
	brush.show()
	brush.position = Vector3.ZERO
	
