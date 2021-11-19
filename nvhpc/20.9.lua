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
The NVIDIA HPC SDK is a comprehensive suite of compilers, libraries and tools
essential to maximizing developer productivity and the performance and
portability of HPC applications. The NVIDIA HPC SDK C, C++, and Fortran
compilers support GPU acceleration of HPC modeling and simulation applications
with standard C++ and Fortran, OpenACC directives, and CUDA. GPU-accelerated
math libraries maximize performance on common HPC algorithms, and optimized
communications libraries enable standards-based multi-GPU and scalable systems
programming. Performance profiling and debugging tools simplify porting and
optimization of HPC applications, and containerization tools enable easy
deployment on-premises or in the cloud.

More information
================
 - NGC: https://ngc.nvidia.com/catalog/containers/nvidia:nvhpc
]==])

whatis("Name: NVIDIA HPC SDK")
whatis("Version: 20.9")
whatis("The NVIDIA HPC SDK is a comprehensive suite of compilers, libraries and tools essential to maximizing developer productivity and the performance and portability of HPC applications. The NVIDIA HPC SDK C, C++, and Fortran compilers support GPU acceleration of HPC modeling and simulation applications with standard C++ and Fortran, OpenACC directives, and CUDA. GPU-accelerated math libraries maximize performance on common HPC algorithms, and optimized communications libraries enable standards-based multi-GPU and scalable systems programming. Performance profiling and debugging tools simplify porting and optimization of HPC applications, and containerization tools enable easy deployment on-premises or in the cloud.")
whatis("URL: https://ngc.nvidia.com/catalog/containers/nvidia:nvhpc")

if not (os.getenv("NGC_SINGULARITY_MODULE") == "none") then
	local singularity_module = os.getenv("NGC_SINGULARITY_MODULE") or "Singularity"
	if not (isloaded(singularity_module)) then
		load(singularity_module)
	end
end

conflict(myModuleName(), "nvhpc")

local image = "nvcr.io_nvidia_nvhpc:20.9-devel-centos7.sif"
local uri = "docker://nvcr.io/nvidia/nvhpc:20.9-devel-centos7"
local programs = {"nvc", "nvc++", "nvfortran", "nvcc",
                  "pgcc", "pgc++", "pgfortran",
                  "cuda-gdb", "ncu", "nv-nsight-cu-cli", "nvprof",
                  "nsight-sys", "nsys"}
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

local container_launch = singularity .. " run --nv " .. image .. " " .. entrypoint_args

-- Programs to setup in the shell
for i,program in pairs(programs) do
        set_shell_function(program, container_launch .. " " .. program .. " \"$@\"",
	                            container_launch .. " " .. program .. " $*")
end
