class_name TerrainResource

var path:= "res://terrain/data/{lod}_{type}.res"

func save_meshes(meshes: Array):
	print('save meshes')

	var file:= FileAccess.open("res://terrain/data/meshes_map.json", FileAccess.WRITE)
	var data = {meshes=[]}
	data.meshes.resize(meshes.size())

	var i:= 0
	for lod_meshes in meshes:
		var j:= 0
		data.meshes[i] = []
		data.meshes[i].resize(9)
		for mesh in lod_meshes:
			var file_path = path.format({lod=i,type=j})
			ResourceSaver.save(mesh, file_path)
			data.meshes[i][j] = file_path
			j+=1
		i+=1

	file.store_string(JSON.stringify(data))
	file.close()


func load_meshes():
	print('load meshes')
	var file:= FileAccess.open("res://terrain/data/meshes_map.json", FileAccess.READ)
	var data = null
	if file:
		data = JSON.parse_string(file.get_as_text())
		data = data.meshes

		var meshes = []
		meshes.resize(data.size())

		var i:= 0

		for lod_meshes in data:
			meshes[i] = []
			meshes[i].resize(lod_meshes.size())
			var j:= 0
			for mesh_path in lod_meshes:
				var mesh:= load(mesh_path)
				meshes[i][j] = mesh
				j+=1
			i+=1

		data = meshes
		print("end load meshes")
	file.close()
	return data
	


class Res extends Resource:
	var data