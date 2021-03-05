# NGC Container Environment Modules

NGC container environment modules are lightweight wrappers that make
it possible to transparently use [NGC
containers](https://ngc.nvidia.com) as environment modules.

- Use familiar environment module commands, ensuring a minimal
  learning curve or change to existing workflows

- Leverage all the benefits of containers, including portability and
  reproducibility

- Take advantage of the optimized HPC and Deep Learning containers
  from NGC

## Synopsis

```
$ git clone https://github.com/NVIDIA/ngc-container-environment-modules
$ module use $(pwd)/ngc-container-environment-modules
$ module load gromacs
$ gmx
```

The `gmx` command on the host is transparently mapped into the GROMACS
container. If the container image is not already present, then the
image will be pulled and cached on first use.  Since Singularity
automatically mounts `$HOME`, `/tmp`, and the current working
directory into the container, the container environment modules provide
nearly transparent access to NGC containers.

Note: Add the path to the NGC container environment modules to
`MODULEPATH` to skip the `module use` step.

## Prerequisites

- [Lmod](https://lmod.readthedocs.io/en/latest/)
- [Singularity](https://sylabs.io/guides/latest/user-guide/) 3.4.1 or later

## Modification

The NGC container environment modules are a reference. It is expected
that they will need some modification for the local environment.

Some of the expected changes are:

1. The name of the Singularity module. The container environment
   modules try to load the `Singularity` module (note the capital
   'S'). Set the `NGC_SINGULARITY_MODULE` environment variable if the
   local Singularity module is named differently (set it to `none` if
   no Singularity module is required).

2. Module conflicts. The container environment modules set module
   conflicts based on the commands mapped into the container. Sites
   may want to modify the list of conflicting modules to prevent
   conflicts between containers or other environment modules.

3. Container image cache. The container environment modules can either
   pull NGC container images as needed or use a library of
   pre-downloaded container images. Sites may wish to modify the
   modules to only support one of these modes. Sites may also want to
   hard-code the path to the library of pre-downloaded container
   images rather than using the `NGC_IMAGE_DIR` environment variable.

4. Mount additional directories into the containers. Sites may have
   filesystems that should be visible to all user processes, such as a
   `/scratch` filesystem or a set of shared datasets. In this case,
   set `SINGULARITY_BINDPATH`, either globally, or in the container
   environment modules.

## Examples

### Basic

Download a [GROMACS benchmark](http://ftp.gromacs.org/pub/benchmarks/)
to run this example.

```
$ module load gromacs/2020.2
$ gmx mdrun -ntmpi 1 -ntomp 40 -v -pin on -nb gpu --pme gpu --resetstep 12000 -nsteps 20000 -nstlist 400 -noconfout -s topol.tpr
```

### Interactive

```
$ module load pytorch/20.02-py3
$ python3
>>> import torch
>>> x = torch.randn(2,3)
```

### Jupyter notebooks

```
$ module load rapidsai
$ jupyter notebook --ip 0.0.0.0 --no-browser --notebook-dir /rapids/notebooks
```

### Multi-node MPI

Download the LAMMPS [Lennard Jones
fluid](https://lammps.sandia.gov/inputs/in.lj.txt) dataset to run this
example.

```
$ module load lammps/15Jun2020
$ mpirun -n 2 lmp -in in.lj.txt -var x 8 -var y 8 -var z 8 -k on g 2 -sf kk -pk kokkos cuda/aware on neigh full comm device binsize 2.8
```
