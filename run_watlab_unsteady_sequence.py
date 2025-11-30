
#%%
import watlab
import os
#%%
mesh_path = 'data/msh/laonong_wide_10m/gmsh.msh'
DEM_path = 'data/raster/raw/laonongDEM_5m.tif'

mesh = watlab.Mesh(mesh_path)
mesh.set_nodes_elevation_from_tif(DEM_path)
model = watlab.HydroflowModel(mesh)

model.name = "laonong_unsteady_wide_10m_cfl05"
model.ending_time = 3000
model.Cfl_number = 0.5

model.set_friction_coefficient("domain",0.05)
model.set_initial_water_level("domain", 0.001)

model.set_boundary_hydrograph('Qin', 'data/txt/hydrograph.txt')
model.set_transmissive_boundaries("Qout")
model.set_wall_boundaries(["East", "West"])

model.set_picture_times(n_pic = 51)

result_folder = "results/" + model.name

model.export.input_folder_name = f"{result_folder}/inputs"
model.export.output_folder_name = f"{result_folder}/outputs"

model.export_data()
model.solve(isParallel=True)
os.replace("log.txt", f"{result_folder}/log.txt")


#%%
mesh_path = 'data/msh/laonong_narrow_10m/gmsh.msh'
DEM_path = 'data/raster/raw/laonongDEM_5m.tif'

mesh = watlab.Mesh(mesh_path)
mesh.set_nodes_elevation_from_tif(DEM_path)
model = watlab.HydroflowModel(mesh)

model.name = "laonong_unsteady_narrow_10m_cfl05"
model.ending_time = 3000
model.Cfl_number = 0.5

model.set_friction_coefficient("domain",0.05)
model.set_initial_water_level("domain", 0.001)

model.set_boundary_hydrograph('Qin', 'data/txt/hydrograph.txt')
model.set_transmissive_boundaries("Qout")
model.set_wall_boundaries(["East", "West"])

model.set_picture_times(n_pic = 51)

result_folder = "results/" + model.name

model.export.input_folder_name = f"{result_folder}/inputs"
model.export.output_folder_name = f"{result_folder}/outputs"

model.export_data()
model.solve(isParallel=True)
os.replace("log.txt", f"{result_folder}/log.txt")

#%%

mesh_path = 'data/msh/laonong_narrow_5m_10m/gmsh.msh'
DEM_path = 'data/raster/raw/laonongDEM_5m.tif'

mesh = watlab.Mesh(mesh_path)
mesh.set_nodes_elevation_from_tif(DEM_path)
model = watlab.HydroflowModel(mesh)

model.name = "laonong_unsteady_narrow_5m_10m_cfl05"
model.ending_time = 3000
model.Cfl_number = 0.5

model.set_friction_coefficient("domain",0.05)
model.set_initial_water_level("domain", 0.001)

model.set_boundary_hydrograph('Qin', 'data/txt/hydrograph.txt')
model.set_transmissive_boundaries("Qout")
model.set_wall_boundaries(["East", "West"])

model.set_picture_times(n_pic = 51)

result_folder = "results/" + model.name

model.export.input_folder_name = f"{result_folder}/inputs"
model.export.output_folder_name = f"{result_folder}/outputs"

model.export_data()
model.solve(isParallel=True)
os.replace("log.txt", f"{result_folder}/log.txt")


#%%
mesh_path = 'data/msh/laonong_narrow_10m/gmsh.msh'
DEM_path = 'data/raster/raw/laonongDEM_5m.tif'

mesh = watlab.Mesh(mesh_path)
mesh.set_nodes_elevation_from_tif(DEM_path)
model = watlab.HydroflowModel(mesh)

model.name = "laonong_unsteady_narrow_10m_cfl09"
model.ending_time = 3000
model.Cfl_number = 0.9

model.set_friction_coefficient("domain",0.05)
model.set_initial_water_level("domain", 0.001)

model.set_boundary_hydrograph('Qin', 'data/txt/hydrograph.txt')
model.set_transmissive_boundaries("Qout")
model.set_wall_boundaries(["East", "West"])

model.set_picture_times(n_pic = 51)

result_folder = "results/" + model.name

model.export.input_folder_name = f"{result_folder}/inputs"
model.export.output_folder_name = f"{result_folder}/outputs"

model.export_data()
model.solve(isParallel=True)
os.replace("log.txt", f"{result_folder}/log.txt")