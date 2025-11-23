import watlab
import os

mesh_path = 'data/msh/laonong/laonong_gmsh_size_10.msh'
DEM_path = 'data/raster/raw/laonongDEM_5m.tif'

mesh = watlab.Mesh(mesh_path, reorder=True)
mesh.set_nodes_elevation_from_tif(DEM_path)
model = watlab.HydroflowModel(mesh)

model.name = "laonong_steady"
model.ending_time = 1000
model.Cfl_number = 0.9

model.set_friction_coefficient("domain",0.05)
model.set_initial_water_level("domain", 0.001)

model.set_boundary_water_discharge('Qin', 1500)
model.set_transmissive_boundaries("Qout")
model.set_wall_boundaries(["East", "West"])

model.set_picture_times(n_pic = 26)

result_folder = "results/" + model.name

model.export.input_folder_name = f"{result_folder}/inputs"
model.export.output_folder_name = f"{result_folder}/outputs"

model.export_data()
model.solve(isParallel=True)
os.replace("log.txt", f"{result_folder}/log.txt")