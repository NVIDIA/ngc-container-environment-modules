-- The MIT License (MIT)
--
-- Copyright (c) 2020 NVIDIA Corporation
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

help([==[

Description
===========
The Chroma package provides a toolbox and executables to carry out calculation
of lattice Quantum Chromodynamics (LQCD). It is built on top of the QDP++ (QCD
Data Parallel Layer) which provides an abstract data parallel view of the
lattice and provides lattice wide types and expressions, using expression
templates, to allow straightforward encoding of LQCD equations.

More information
================
 - NGC: https://ngc.nvidia.com/catalog/containers/hpc:chroma
]==])

whatis("Name: chroma")
whatis("Version: 2018-cuda9.0-ubuntu16.04-volta-openmpi")
whatis("Description: The Chroma package provides a toolbox and executables to carry out calculation of lattice Quantum Chromodynamics (LQCD). It is built on top of the QDP++ (QCD Data Parallel Layer) which provides an abstract data parallel view of the lattice and provides lattice wide types and expressions, using expression templates, to allow straightforward encoding of LQCD equations.")
whatis("URL: https://ngc.nvidia.com/catalog/containers/hpc:chroma")

if not (isloaded("Singularity")) then
    load("Singularity")
end

conflict(myModuleName(), "openmpi", "lammps", "milc", "qmcpack", "relion")

local image = "nvcr.io_hpc_chroma:2018-cuda9.0-ubuntu16.04-volta-openmpi.sif"
local uri = "docker://nvcr.io/hpc/chroma:2018-cuda9.0-ubuntu16.04-volta-openmpi"
local programs = {"chroma", "hmc", "mpirun"}
local entrypoint_args = ""

-- Workaround for issues with Singularity environment variable handling 
setenv("SINGULARITYENV_LD_LIBRARY_PATH", "")

-- The absolute path to Singularity is needed so it can be invoked on remote
-- nodes without the corresponding module necessarily being loaded.
-- Trim off the training newline.
local singularity = capture("which singularity | head -c -1")

if (os.getenv("NGC_IMAGE_DIR") and mode() == "load") then
	image = pathJoin(os.getenv("NGC_IMAGE_DIR"), image)

	if not (isFile(image)) then
		-- The image could not be found in the container directory
		LmodMessage("file not found: " .. image)
		LmodMessage("The container image will be pulled upon first use to the Singularity cache")
		image = uri

		-- Alternatively, this could pull the container image and
		-- save it in the container directory
		--subprocess(singularity .. " pull " .. image .. " " .. uri)
	end
else
	-- Look for the image in the Singularity cache, and if not found
	-- download it when "singularity run" is invoked.
	image = uri
end

local container_launch = singularity .. " run --nv " .. image .. " " .. entrypoint_args

-- Multinode support
setenv("OMPI_MCA_orte_launch_agent", container_launch .. " orted")

-- Programs to setup in the shell
for i,program in pairs(programs) do
        set_shell_function(program, container_launch .. " " .. program .. " $@",
	                            container_launch .. " " .. program .. " $*")
end
