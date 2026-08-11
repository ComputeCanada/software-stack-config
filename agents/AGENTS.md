# Alliance cluster usage

This is a shared HPC environment used by many researchers. Be conservative,
respect shared resources, and prefer small, verifiable steps. Consult the
Alliance documentation before improvising: https://docs.alliancecan.ca

## Keep login-node work lightweight

The current working directory may be on a shared login node. On login nodes,
limit work to lightweight operations such as editing files, reading code,
small Git operations, and short commands.

Do not run heavy, long-running, or parallel workloads on a login node. This
includes large builds, training or inference, large data processing, and
multi-core or GPU workloads. If unsure whether a task is lightweight, assume
it is not.

## Use the scheduler for non-trivial work

For interactive work, request an allocation:

    salloc --account=<account> --time=... --cpus-per-task=... --mem=...

Run unattended work through an `sbatch` script. Before starting anything that
may consume significant CPU, memory, GPU resources, or wall time, stop and ask
the user to move the work into an allocation.

## Use the Alliance Python wheelhouse

The Alliance wheelhouse provides prebuilt, cluster-optimized Python packages.
It is a package source, not a replacement for a virtual environment.

Load an available Python module, create a virtual environment, and install
packages from the wheelhouse:

    module load python/<version>
    python -m venv <venv>
    pip install --no-index <package>

Prefer the wheelhouse over PyPI. Avoid Conda and arbitrary internet
installations unless the user explicitly requests otherwise.

## Use the appropriate filesystem

- **home**: Backed up, with a small quota. Use for configuration, source code,
  and small persistent files.
- **project**: Backed up and shared with the sponsor or PI group. Use for
  cleaned results intended to persist or be shared.
- **scratch**: Not backed up and periodically purged. Use for active work, and
  never keep the only copy of important data there.

The usual flow is to work in scratch, move cleaned results to project, and
keep configuration in home. Check quota before large writes. If an operation
could exhaust quota, stop and inform the user.

## Use environment modules

Software is provided through environment modules. Use `module avail` and
`module load` to discover and activate software. Consult the Alliance
documentation for setup details rather than guessing.
