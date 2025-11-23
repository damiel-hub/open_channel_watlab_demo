# open-channel-watlab-demo

# Prerequisite Software
1. Anaconda: [Install tutorial](https://www.jcchouinard.com/install-python-with-anaconda-on-windows/), 
[Download link](https://www.anaconda.com/download?utm_source=anacondadocs&utm_medium=documentation&utm_campaign=download&utm_content=installwindows).

2. Visual Studio Code (VS Code): [Downlaod link](https://code.visualstudio.com/).

3. QGIS: [Download link](https://www.qgis.org/download/).


# WatLab Setup Guide (Step-by-Step)


### Steps to Set Up WatLab:

1. **Download and Extract Required Files**  
   - Download the file **`open_channel_watlab_demo-main.zip`** from the website or directly using this [link](https://github.com/damiel-hub/open_channel_watlab_demo/archive/refs/heads/main.zip).  
   - Extract the contents of the ZIP file to your preferred directory.

2. **Install WatLab and Its Dependencies**  
   - Open the **Anaconda Prompt** on your computer.  
   - Navigate to the directory **`open_channel_watlab_demo-main\environment_setup`** using the `cd` command. Replace `to_your_path` with the actual path to the extracted folder:  
     ```bash
     cd to_your_path\open_channel_watlab_demo-main\environment_setup
     ```  
   - **Note:** If the folder is on a different drive (e.g., D:), switch to that drive first by typing the drive letter followed by a colon (`:`):  
     ```bash
     D:
     ```  
   - Run the following commands to create and set up the WatLab environment:  
     ```bash
     conda create --name watlab python=3.11
     conda activate watlab
     python -m pip install GDAL-3.4.3-cp311-cp311-win_amd64.whl
     python -m pip install watlab
     python -m pip install seamsh
     ```

<!-- 3. **Install a C++ Compiler**  
   - Download and install a C++ compiler from [MSYS2](https://www.msys2.org/). Follow the installation instructions provided on their website.  
   - Add the MSYS2 binary path (default: `C:\msys64\ucrt64\bin`) to your system's environment variables:  
     - Open the "Run" dialog by pressing `Windows + R`, type `SystemPropertiesAdvanced`, and hit Enter.  
     - Use the Environment Variable Manager to add the path. -->

3. **Run WatLab**  
   - Open the **`watlab-first-script.py`** file using VS Code.  
   - Open a terminal within VS Code and activate the WatLab environment:  
     ```bash
     conda activate watlab
     ```  
   - Navigate to the script directory:  
     ```bash
     cd .\open_channel_watlab_demo-main\watlab-first-script
     ```  
   - Run the script with the following command:  
     ```bash
     python watlab-first-script.py
     ```  

By following these steps, you can successfully set up and run WatLab.




For more information please visit official [Watlab Website](https://sites.uclouvain.be/hydraulics-group/watlab/index.html).






