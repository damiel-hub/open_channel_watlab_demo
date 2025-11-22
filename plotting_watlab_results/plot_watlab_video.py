import watlab
import matplotlib.pyplot as plt

mesh_path = '../W13_environment_setup\watlab-field-case/msh/laonong_gmsh_size_10.msh'
DEM_path = '../W13_environment_setup\watlab-field-case/raster/raw/laonongDEM_5m.tif'
pic_path_template = 'outputs_unsteady/pic_{:d}_{:02d}.txt'

mesh = watlab.Mesh(mesh_path)
mesh.set_nodes_elevation_from_tif(DEM_path)

#create the mesh and plotter object
plotter = watlab.Plotter(mesh)
plotter.create_video_on_hillshade(pic_path_template,'unsteadyFlow',time_step = 1800, variable_name = "h",dem_path=DEM_path, colorbar_values = [0, 5.5])
