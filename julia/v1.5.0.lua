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
The Julia programming language is a flexible dynamic language, appropriate
for scientific and numerical computing, with performance comparable to
traditional statically-typed languages.

More information
================
 - NGC: https://ngc.nvidia.com/catalog/containers/hpc:julia
]==])

whatis("Name: julia")
whatis("Version: v1.5.0")
whatis("Description: The Julia programming language is a flexible dynamic language, appropriate for scientific and numerical computing, with performance comparable to traditional statically-typed languages.")
whatis("URL: https://ngc.nvidia.com/catalog/containers/hpc:julia")

if not (os.getenv("NGC_SINGULARITY_MODULE") == "none") then
	local singularity_module = os.getenv("NGC_SINGULARITY_MODULE") or "Singularity"
	if not (isloaded(singularity_module)) then
		load(singularity_module)
	end
end

conflict(myModuleName())

local image = "nvcr.io_hpc_julia:v1.5.0.sif"
local uri = "docker://nvcr.io/hpc/julia:v1.5.0"
local programs = {"julia"}
local entrypoint_args = ""

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

-- /data must exist and be writable inside the container
local container_launch = singularity .. " run --nv -B $HOME/.julia:/data " .. image .. " " .. entrypoint_args

-- Programs to setup in the shell
-- julia is the container entrypoint
for i,program in pairs(programs) do
        set_shell_function(program, container_launch .. " $@",
	                            container_launch .. " $*")
end
