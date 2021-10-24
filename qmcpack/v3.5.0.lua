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
QMCPACK is an open-source, high-performance electronic structure code that
implements numerous Quantum Monte Carlo algorithms. Its main applications are
electronic structure calculations of molecular, periodic 2D and periodic 3D
solid-state systems. Variational Monte Carlo (VMC), diffusion Monte Carlo (DMC)
and a number of other advanced QMC algorithms are implemented. By directly
solving the Schrodinger equation, QMC methods offer greater accuracy than
methods such as density functional theory, but at a trade-off of much greater
computational expense. Distinct from many other correlated many-body methods,
QMC methods are readily applicable to both bulk (periodic) and isolated
molecular systems.

More information
================
 - NGC: https://ngc.nvidia.com/catalog/containers/hpc:qmcpack
]==])

whatis("Name: qmcpack")
whatis("Version: 3.5.0")
whatis("Description: QMCPACK is an open-source, high-performance electronic structure code that implements numerous Quantum Monte Carlo algorithms. Its main applications are electronic structure calculations of molecular, periodic 2D and periodic 3D solid-state systems. Variational Monte Carlo (VMC), diffusion Monte Carlo (DMC) and a number of other advanced QMC algorithms are implemented. By directly solving the Schrodinger equation, QMC methods offer greater accuracy than methods such as density functional theory, but at a trade-off of much greater computational expense. Distinct from many other correlated many-body methods, QMC methods are readily applicable to both bulk (periodic) and isolated molecular systems.")
whatis("URL: https://ngc.nvidia.com/catalog/containers/hpc:qmcpack")

if not (os.getenv("NGC_SINGULARITY_MODULE") == "none") then
	local singularity_module = os.getenv("NGC_SINGULARITY_MODULE") or "Singularity"
	if not (isloaded(singularity_module)) then
		load(singularity_module)
	end
end

conflict(myModuleName(), "openmpi", "chroma", "lammps", "milc", "relion")

local image = "nvcr.io_hpc_qmcpack:v3.5.0.sif"
local uri = "docker://nvcr.io/hpc/qmcpack:v3.5.0"
local programs = {"mpirun", "qmcpack"}
-- needed to work around a bug in the qmcpack container entrypoint
local entrypoint_args = "--gpu_default_driver=0.0"

-- Workaround for lack of SLURM awareness in the container --
pushenv("SLURM_JOBID", false)
pushenv("SLURM_NODELIST", false)

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
