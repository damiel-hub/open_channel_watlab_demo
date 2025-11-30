import watlab
import os

mesh_path = 'data/msh/laonong_narrow_50m/gmsh.msh'
DEM_path = 'data/raster/raw/laonongDEM_5m.tif'

mesh = watlab.Mesh(mesh_path)
mesh.set_nodes_elevation_from_tif(DEM_path)
model = watlab.HydroflowModel(mesh)

model.name = "laonong_unsteady_narrow_50m_cfl05_hydrograph_steep"
model.ending_time = 3000
model.Cfl_number = 0.5

model.set_friction_coefficient("domain",0.05)
model.set_initial_water_level("domain", 0.001)

model.set_boundary_hydrograph('Qin', 'data/txt/steep/hydrograph.txt')
model.set_transmissive_boundaries("Qout")
model.set_wall_boundaries(["East", "West"])

model.set_picture_times(n_pic = 51)

result_folder = "results/" + model.name

model.export.input_folder_name = f"{result_folder}/inputs"
model.export.output_folder_name = f"{result_folder}/outputs"

my_gauges = [
    [226955.7, 2562347.0, 0],
    [226734.1, 2563331.4, 0],
]

model.set_gauge(gauge_position=my_gauges, time_step=1)

model.export_data()
model.solve(isParallel=True)
os.replace("log.txt", f"{result_folder}/log.txt")