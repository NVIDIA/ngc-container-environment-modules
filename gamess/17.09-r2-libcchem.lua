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
The General Atomic and Molecular Electronic Structure Systems (GAMESS) program
simulates molecular quantum chemistry, allowing users to calculate various
molecular properties and dynamics.

More information
================
 - NGC: https://ngc.nvidia.com/catalog/containers/hpc:gamess
]==])

whatis("Name: gamess")
whatis("Version: 17.09-r2-libcchem")
whatis("Description: The General Atomic and Molecular Electronic Structure Systems (GAMESS) program simulates molecular quantum chemistry, allowing users to calculate various molecular properties and dynamics.")
whatis("URL: https://ngc.nvidia.com/catalog/containers/hpc:gamess")

if not (os.getenv("NGC_SINGULARITY_MODULE") == "none") then
	local singularity_module = os.getenv("NGC_SINGULARITY_MODULE") or "Singularity"
	if not (isloaded(singularity_module)) then
		load(singularity_module)
	end
end

conflict(myModuleName())

local image = "nvcr.io_hpc_gamess:17.09-r2-libcchem.sif"
local uri = "docker://nvcr.io/hpc/gamess:17.09-r2-libcchem"
local programs = {"rungms"}
local entrypoint_args = ""

-- This GAMESS installation expects to run in '/workspace' and deliver its
-- output to '/results'... so we need to bind them into container.
-- Moreover, it expects things to be as follows:
-- 	/path/to/your_workspace
--	    scratch/
--	    restart/
--	    your_input.inp
-- We'd want to point 'scratch' to cluster scratch (if present),
-- but keep 'workspace' and 'results' in current working directory, so need
-- to assemble a fancy SINGULARITY_BINDPATH variable.
local workspace = '.'
local results   = '.'
local restart   = pathJoin(workspace, "restart")
local scratch   = pathJoin(workspace, "scratch")
if (os.getenv("CLUSTER_SCRATCH")) then
	scratch = pathJoin(os.getenv("CLUSTER_SCRATCH"), "gamess-ngc")
end
append_path("SINGULARITY_BINDPATH", workspace .. ":/workspace", ",")
append_path("SINGULARITY_BINDPATH", results   .. ":/results",   ",")
append_path("SINGULARITY_BINDPATH", scratch   .. ":/scratch",   ",")

-- We defined bind points, but we must ensure that they exist on the host.
-- The catch is that this needs to be done *at run time*, not at module load
-- time - so we prepare a "pre" command to be executed prior to the main
-- singularity call.
-- Note: the way GAMESS is setup in this container, we really need a
-- "local" workspace/scratch (will only keep one file) and a true /scratch
-- scratch - so make them both.
directories = {workspace, results, pathJoin(workspace, scratch), scratch, restart}
preexec_command = "mkdir -p"
for i,dir in pairs(directories) do
	preexec_command = preexec_command .. " " .. dir
end

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

-- And assemble the preexecution command with actual singularity call.
-- Note: '--pid' is needed because otherwise Ctrl-C'ing the container
-- leaves behind lingering mpiexec.hydra processes.
-- Using 'exec' instead of 'run' to bypass /bin/bash entrypoint that would
-- othewise expected a "-c 'cd /workspace && rungms $@'" argument.
local container_launch = singularity .. " exec --nv --pid --pwd /workspace " .. image .. " " .. entrypoint_args
container_launch = preexec_command .. " && " .. container_launch

-- Programs to setup in the shell
for i,program in pairs(programs) do
        set_shell_function(program, container_launch .. " " .. program .. " $@",
	                            container_launch .. " " .. program .. " $*")
end
