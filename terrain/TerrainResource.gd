class_name TerrainResource

var path:= "res://terrain/data/{lod}_{type}.res"

func save_meshes(meshes: Array):

	# var file:= FileAccess.open("res://terrain/data/meshes.res", )

	var i:= 0
	for lod_meshes in meshes:
		var j:= 0
		for mesh in lod_meshes:
			ResourceSaver.save(mesh, path.format({lod=i,type=j}))
			j+=1
		i+=1


func load_meshes():
	var file:= FileAccess.open(path.format({filename="meshes"}), FileAccess.READ)
	var data = null
	if file:
		data = file.get_var()

		if data == null: return null

		var meshes = []
		meshes.resize(data.size())

		var i:= 0
		for lod_meshes in data:
			meshes[i] = []
			meshes[i].resize(lod_meshes.size())
			var j:= 0
			for mesh_data in lod_meshes:
				mesh_data = bytes_to_var(mesh_data)
				var mesh:= Resource.new()
				mesh.lo
				meshes[i][j] = bytes_to_var(data[i][j])
				j+=1
			i+=1
	file.close()
	return data
	


class Res extends Resource:
	var data