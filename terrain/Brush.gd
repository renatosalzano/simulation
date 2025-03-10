class_name Brush extends Decal

var terrain: Terrain
var camera: Camera3D
var enabled:= false
var preview:= Decal.new()
var brush_size: int
var brush_ray: int
var brush_img: Image

func _init(_terrain: Node3D):
	terrain = _terrain
	terrain.add_child(self)
	hide()

	if Engine.is_editor_hint():
		camera = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	add_child(preview)


func set_brush(texture: Texture2D, preview_tex: Texture2D):
	brush_size = texture.get_width()
	brush_ray = brush_size / 2

	texture_albedo = texture
	size = Vector3(texture.get_width(), 500.0, texture.get_height())
	position = Vector3.ZERO
	brush_img = texture.get_image()

	# preview
	preview.size = size
	preview.texture_albedo = preview_tex


func get_pixel(x: int, y: int):
	return brush_img.get_pixel(x,y)


func get_pixelv(v: Vector2i):
	return brush_img.get_pixelv(v)

# func _input(event: InputEvent) -> void:

# signal on_painting

var last_time:= Time.get_ticks_msec()
var tickrate:= 1000 / 60
var tick = 0
var update_collision = false

# signal painting_process

func _physics_process(_delta: float) -> void:

	if enabled and Time.get_ticks_msec() - last_time > tickrate:
		last_time = Time.get_ticks_msec()

		var space_state:= get_world_3d().direct_space_state
		var pos:= EditorInterface.get_editor_viewport_3d().get_mouse_position()

		var from:= camera.project_ray_origin(pos)
		var to:= from + camera.project_ray_normal(pos) * 2000.0
		var query:= PhysicsRayQueryParameters3D.create(from, to)

		var result:= space_state.intersect_ray(query)

		if result:

			if result.collider is Chunk:
				position = result.position
				
				update_collision = tick % 60 == 0
				if tick % 2 == 0:
					painting(result)

				if tick % 60 == 0: tick = 0
				tick += 1

	pass


var overflow:= {
		tl = false,
		t  = false,
		tr = false,
		l  = false,
		r  = false,
		bl = false,
		b  = false,
		br = false
	}


var intensity:= 0.02

func set_pixel(chunk: Chunk, x: int, y: int, alpha: float) -> Chunk:
	var r:= chunk.get_pixel(x, y).r
	r += intensity * alpha
	chunk.set_pixel(x, y, Color(r,0,0,1))
	return chunk


func painting(res: Dictionary):

	if update_collision:
		print('update')

	var chunk: Chunk = res.collider
	var center = chunk.snap_to_pixel(res.position)
	var pixel_offset = Vector2i(center.x - brush_ray, center.y - brush_ray)
	var i: int = chunk.heightmap.len
	# printraw('\r' + str(res.position) + str(chunk.index) + str(center))

	i -= 1

	overflow.t  = center.y - brush_ray <= 0
	overflow.l  = center.x - brush_ray <= 0
	overflow.r  = center.x + brush_ray >= i
	overflow.b  = center.y + brush_ray >= i
	overflow.tl = overflow.t && overflow.l
	overflow.tr = overflow.t && overflow.r
	overflow.bl = overflow.b && overflow.l
	overflow.br = overflow.b && overflow.r
	

	var chunk_to_update: Array[Chunk] = []

	for x in brush_size:
		for y in brush_size:
			var alpha: float = get_pixel(x,y).a
			
			var X = x + pixel_offset.x
			var Y = y + pixel_offset.y

			var RX = X >= 0 && X <= i
			var RY = Y >= 0 && Y <= i

			if RX && RY:
				set_pixel(chunk, X, Y, alpha)
				# var r:= chunk.get_pixel(X,Y).r
				# r += intensity * alpha
				# chunk.set_pixel(X,Y, Color(r,0,0,1))
				pass

			# 0 1 2
			# 3 . 5
			# 6 7 8

			var Y0: int = 0
			var X0: int = 0

			if Y <= 0: Y0 = Y + i
			if Y >= i: Y0 = Y - i
			if X <= 0: X0 = X + i
			if X >= i: X0 = X - i

			# TOP
			if overflow.tl && chunk.neighbors[0] != null:
				if Y <= 0 && X <= 0:
					chunk_to_update.append(set_pixel(chunk.neighbors[0], X0, Y0, alpha))

			if overflow.t && chunk.neighbors[1] != null:
				if Y <= 0 && RX:
					chunk_to_update.append(set_pixel(chunk.neighbors[1], X, Y0, alpha))

			if overflow.tr && chunk.neighbors[2] != null:
				if Y <= 0 && X >= i:
					chunk_to_update.append(set_pixel(chunk.neighbors[2], X0, Y0, alpha))

			# CENTER
			if overflow.l && chunk.neighbors[3] != null:
				if X <= 0 && RY:
					chunk_to_update.append(set_pixel(chunk.neighbors[3], X0, Y, alpha))

			if overflow.r && chunk.neighbors[5] != null:
				if X >= i && RY:
					chunk_to_update.append(set_pixel(chunk.neighbors[5], X0, Y, alpha))
			
			# BOTTOM
			if overflow.bl && chunk.neighbors[6] != null:
				if Y >= i && X <= 0: 
					chunk_to_update.append(set_pixel(chunk.neighbors[6], X0, Y0, alpha))

			if overflow.b && chunk.neighbors[7] != null:
				if Y >= i && RX:
					chunk_to_update.append(set_pixel(chunk.neighbors[7], X, Y0, alpha))

			if overflow.br && chunk.neighbors[8] != null:
				if Y >= i && X >= i:
					chunk_to_update.append(set_pixel(chunk.neighbors[8], X0, Y0, alpha))


	chunk.update_img()
	for c in chunk_to_update:
		c.update_img()

	pass


func test_paint(res: Dictionary):
	printraw("\r" + str(res.collider.index))

	# var img_size:= img.get_size()

	# var half_size:= set_chunk.z / 2
	# var pos:= -Vector2(res.position.x - half_size, res.position.z - half_size).round()
	# # printraw("\r" + str(pos))
	# var brush_len = brush.image.get_size().x
	# var brush_size = brush_len / 2
	# var pixel_offset = Vector2i(pos.x - brush_size, pos.y - brush_size)

	# printraw("\r" + str(pixel_offset))

	# for x in brush_len:
	# 	for y in brush_len:
	# 		var color: Color = brush.image.get_pixel(x,y)
			
	# 		var X = x + pixel_offset.x
	# 		var Y = y + pixel_offset.y

	# 		if X >= 0 && X < img_size.x && Y >= 0 && Y < img_size.y:
	# 			var r:= img.get_pixel(X,Y).r
	# 			r += 0.1 * color.a
	# 			img.set_pixel(X,Y, Color(r,0,0,1))

	# 			vertex[Y * img_size.x + X].y = r * 15.0
	# 			pass

	# var am = ArrayMesh.new()
	# am.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, ma)



	# collision.shape = am.create_trimesh_shape()
	# mesh_instance.mesh = am


	# img.set_pixelv(Vector2i(pos), Color(1,0,0))


	# var img_size:= img.get_size()
	# var pixel_offset:= Vector2i(pos + (img_size / 2))

	# # printraw("\r" + str(pixel_offset))
	
	# img.set_pixelv(pixel_offset, Color(1,0,0))
	# pixel_offset += brush_size / 2

	# printraw("\r" + str(pixel_offset))

	# Aggiorna solo l'area del pennello
	# for y in brush_size.y:
	# 	for x in brush_size.x:

	# 		var idx:= Vector2i(x, y)
	# 		x += pixel_offset.x
	# 		y += pixel_offset.y

	# 		if x > 0 && x < img_size.x && y > 0 && y < img_size.y:
	# 			var brush_color: Color = brush.image.get_pixelv(idx)
	# 			var color: Color = brush_color + img.get_pixel(x, y)
	# 			img.set_pixel(x, y, color)

	# var texture = ImageTexture.create_from_image(img)
	# mesh_instance.material_override.set_shader_parameter("heightmap", texture)

	# printraw("\r" + str(pixel))
			
	pass

# func test_painting(res: Dictionary):
# 	var chunk: Chunk = res.collider
# 	var center = res.collider.snap_to_pixel(res.position)
# 	var pixel_offset = Vector2i(center.x - brush_ray, center.y - brush_ray)
# 	var img_size:= chunk.img.get_size().x

# 	var img_data:= chunk.img.get_data().to_float32_array() # Ottieni i dati dell'immagine

# 	for x in brush_size:
# 		for y in brush_size:
# 			var alpha: float = get_pixel(x,y).a
# 			var X = x + pixel_offset.x
# 			var Y = y + pixel_offset.y

# 			if X >= 0 && X < img_size && Y >= 0 && Y < img_size:
# 				var index = (Y * img_size + X)
# 				img_data[index] += 0.001 * alpha

# 	chunk.set_data(img_data.to_byte_array())