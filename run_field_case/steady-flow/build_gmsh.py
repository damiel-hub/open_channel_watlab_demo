import seamsh
from seamsh.geometry import CurveType
import seamsh.geometry
import numpy as np
from osgeo import osr

# Remenber to proceed "pip install seamsh" first!

# Input Datas
boundarySHP = "data\\shape\\build_gmsh\\laonong_boundary.shp"
mesh_size_tif = "data\\raster\\build_gmsh\\laonong_gmsh_10m.tif"
outputName = 'data\\msh\\laonong_gmsh_size_10'
EPSGcode = 3826

# %%
# First, let's create a domain object and its associated projection.
# Any projection supported by osgeo.osr can be used.

domain_srs = osr.SpatialReference()
domain_srs.ImportFromEPSG(EPSGcode)
domain = seamsh.geometry.Domain(domain_srs)

# %%
# We load all curves from a given ESTRI shapefile as polylines.
# In the shapefile, a field named "Type" defines the physical tag of each
# curve. If a re-projection is required, it will be done automatically.
domain.add_boundary_curves_shp(boundarySHP,
                                "Type", CurveType.POLYLINE)
bath_field = seamsh.field.Raster(mesh_size_tif)
def mesh_size(x,projection) :
    bath = bath_field(x,projection)  
    return (bath)

# %%
# The "intermediate_file_name" option is used to save files containing
# intermediate meshes and mesh size fields. If this parameter takes the
# special value "-" an interactive gmsh graphical window will pop up
# after each meshing step.

output_srs = osr.SpatialReference()
output_srs.ImportFromEPSG(EPSGcode)

seamsh.gmsh.mesh(domain, outputName + ".msh", mesh_size, intermediate_file_name="debug", output_srs=output_srs)

seamsh.gmsh.reproject(outputName + ".msh", domain_srs, outputName + "_lonlat" + ".msh", output_srs)

# %%
# The gmsh.convert_to_gis function can be used to convert a gmsh .msh file
# into a shape file or into a geo package file.

seamsh.gmsh.convert_to_gis(outputName + ".msh", output_srs, outputName + ".gpkg")
