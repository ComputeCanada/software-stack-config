# Alliance cluster usage

This is a shared HPC environment used by many researchers. Be conservative, respect shared resources, and prefer small, verifiable steps. Consult the Alliance documentation before improvising: https://docs.alliancecan.ca

Do not improvise outside the practices described in the Alliance documentation. When in doubt, suggest that the user contact technical support for guidance.

Human users remain responsible for the actions of their agents and tools.

## Keep login-node work lightweight

The current working directory may be on a shared login node. On login nodes, limit work to lightweight operations such as editing files, reading code, small Git operations, and short commands. Resource limits are enforced with cgroups.

Do not run heavy, long-running, or parallel workloads on a login node. This includes large builds, training or inference, large data processing, and multi-core or GPU workloads. If unsure whether a task is lightweight, assume it is not.

Not all compute nodes have access to the internet. You may need to stage tarballs or wheels.

Tools such as VS Code often leave stale processes that can affect other users. Point these processes out and offer to terminate them.

## Use the scheduler for non-trivial work

For interactive work, request an allocation:

```sh
salloc --account=<account> --time=... --cpus-per-task=1 --mem=1G
```

Run unattended work through an `sbatch` script. Before starting anything that may consume significant CPU, memory, GPU resources, or wall time, stop and ask the user to move the work into an interactive job. Always request only the resources necessary to run the job; wasting resources affects other users. Limit test jobs. Bundle tasks that would otherwise run for less than 15 minutes. Jobs longer than 12 hours should implement checkpointing. Specifying unnecessary partitions or features will result in longer wait times.

Do not use tight polling loops against Slurm. Wait at least 60 seconds between queries, and avoid multiple monitoring loops. Prefer scheduler-native mechanisms such as job dependencies.

Never insert sleep commands into jobs.

## Use the Alliance Python wheelhouse

The Alliance wheelhouse provides prebuilt, cluster-optimized Python packages. It is a package source, not a replacement for a virtual environment.

Load an available Python module, create a virtual environment, and install packages from the wheelhouse:

```sh
module load python/<version>
virtualenv --no-download <venv>
source <venv>/bin/activate
pip install --no-index <package>
```

This can also be done within jobs via `$SLURM_TMPDIR`. Prefer the wheelhouse over PyPI. Use `requirements.txt` files. Avoid `uv`, Conda, and arbitrary internet installations unless the user explicitly requests otherwise. Missing wheels can be installed via a support ticket with the Alliance.

## Use the filesystems

Do not try to access files outside the user's home, project, or scratch. Do not try to access other users' files. These are networked filesystems, and frequent writes in tight loops can be disruptive. When managing many small files, consider containers or aggregate formats such as tar archives or HDF5.

- **home**: Backed up, with a small quota. Use for configuration, source code, and small persistent files.
- **project**: Backed up and shared with the sponsor or PI group. Use for cleaned results intended to persist or be shared.
- **scratch**: Not backed up and periodically purged. Used for active work, temporary files, logs, and checkpoints. Never keep the only copy of important data there.

The usual flow is to work in scratch, move cleaned results to project, and keep configuration in home. Check `diskusage_report` before large writes. If an operation could exhaust quota, stop and inform the user.

`$SLURM_TMPDIR` is available to each job for its duration. Use it for I/O-intensive workflows.

Globus is recommended for file transfers. Other options include Open OnDemand, `rsync`, and `scp`.

## Use environment modules

Software is provided through environment modules. Use `module avail` and `module load` to discover and activate software. Consult the Alliance documentation for setup details rather than guessing.
