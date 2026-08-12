# Alliance cluster usage

This is a shared HPC environment used by many researchers. Be conservative,
respect shared resources, and prefer small, verifiable steps. Consult the
Alliance documentation before improvising: https://docs.alliancecan.ca

Do not try to be creative by working outside of the practices documented in
the Alliance documentation. When in doubt, suggest to the user to contact our
technical support for guidance.

## Keep login-node work lightweight

The current working directory may be on a shared login node. On login nodes,
limit work to lightweight operations such as editing files, reading code,
small Git operations, and short commands.

Do not run heavy, long-running, or parallel workloads on a login node. This
includes large builds, training or inference, large data processing, and
multi-core or GPU workloads. If unsure whether a task is lightweight, assume
it is not.

Not all compute nodes have access to the internet. You may need to stage
tarballs or wheels.

## Use the scheduler for non-trivial work

For interactive work, request an allocation:

```sh
salloc --account=<account> --time=... --cpus-per-task=1 --mem=1G
```

Run unattended work through an `sbatch` script. Before starting anything that
may consume significant CPU, memory, GPU resources, or wall time, stop and ask
the user to move the work into an interactive job. Request the minimal amount
of resources necessary to run the job always. Wasting resources impacts other
users. Limit test jobs. Avoid jobs with run time shorter than 15 minutes, as
these can be bundled together. Jobs longer than 12 hours should implement
checkpointing.

## Use the Alliance Python wheelhouse

The Alliance wheelhouse provides prebuilt, cluster-optimized Python packages.
It is a package source, not a replacement for a virtual environment.

Load an available Python module, create a virtual environment, and install
packages from the wheelhouse:

```sh
module load python/<version>
virtualenv --no-download <venv>
source <venv>/bin/activate
pip install --no-index <package>
```

This can also be done within jobs via `$SLURM_TMPDIR`. Prefer the wheelhouse
over PyPI. Use `requirements.txt` files. Avoid `uv`, Conda, and arbitrary
internet installations unless the user explicitly requests otherwise. Missing
wheels can be installed via a support ticket with the Alliance.

## Use the filesystems

Do not try to access files outside of the user's home, project, or scratch. Do
not try to access files of other users. These are networked filesystems, and
patterns which write frequently in fast loops are destructive.

- **home**: Backed up, with a small quota. Use for configuration, source code,
  and small persistent files.
- **project**: Backed up and shared with the sponsor or PI group. Use for
  cleaned results intended to persist or be shared.
- **scratch**: Not backed up and periodically purged. Used for active work,
  temporary files, logs, and checkpoints. Never keep the only copy of important
  data there.

The usual flow is to work in scratch, move cleaned results to project, and
keep configuration in home. Check `diskusage_report` before large writes. If
an operation could exhaust quota, stop and inform the user.

## Use environment modules

Software is provided through environment modules. Use `module avail` and
`module load` to discover and activate software. Consult the Alliance
documentation for setup details rather than guessing.
