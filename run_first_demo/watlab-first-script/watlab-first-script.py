"""
Created on Wed Dec 7 11:07:50 2022

@author: Nathan Delpierre & Charles Ryckmans
"""
#
# In this first example, we show how to deal with the Watlab-HydroFlow Python API 
# The example consists of a dambreak on a flat bed
# One of the area is initially filled with water, as the other is initialized with a thin layer


import watlab
import matplotlib.pyplot as plt
# Mesh generation
# ===============

# Import the mesh to hydroflow
mesh = watlab.Mesh("damBreakMesh.msh")

# # Model the situation
# # ===================

# # hydroflow needs to define a Model based on the mesh
model = watlab.HydroflowModel(mesh)

# # One can give him simple parameters
model.name = "Simple Dam Break"
model.ending_time = 5 
model.Cfl_number = 0.95

# Now, we impose some initial conditions
model.set_friction_coefficient("Filled area",0.01)
model.set_friction_coefficient("Empty area",0.01)
model.set_initial_water_height("Filled area", 0.15)
model.set_initial_water_height("Empty area", 0.015)

# You should provide information concerning the boundary conditions : 
model.set_wall_boundaries(["Boundaries down", "Boundaries up", "Boundaries right", "Boundaries left"])

# Let's define how many output files we want
model.set_picture_times(n_pic = 51)

# # We can also define the auto-input folders and auto-output folders names
model.export.input_folder_name = "inputs"
model.export.output_folder_name = "output_files"

# # This will generate the necessary data to run the model.
model.export_data()

# Just run the model and get the outputs
model.solve()

# # Plot the results
# # ================

# First we create a plotter object based on the mesh
plotter = watlab.Plotter(mesh)

# We give the path to the output (say at 0.6 seconds)
output_start_path = model.export.output_folder_name + "//pic_0_00.txt"
output_picture_path = model.export.output_folder_name + "//pic_0_60.txt"

# And we plot the result
plotter.plot(output_start_path, variable_name="h",colorbar_values=[0,0.15])
plotter.show_velocities(output_start_path, scale=100)
plt.show()

plotter.plot(output_picture_path, variable_name="h")
plotter.show_velocities(output_picture_path, scale=100)
plt.show()
 