
function set_family(t)
   ------------------------------------------------------------
   -- table of properties for fullnames or sn

   local familyT = {
      [ { "gcc", "intel", "pgi" } ] = "compiler",
      [ { "openmpi", "mvapich2" } ] = "mpi",
      [ { "hdf5-mpi", "hdf5", "hdf5-serial" } ] = "hdf5",
      [ { "petsc", "petsc-64bits", "petsc-debug", "petsc-complex" } ] = "petsc",
      [ { "gromacs-plumed", "gromacs" } ] = "gromacs",
      [ { "netcdf-mpi", "netcdf", "netcdf-serial" } ] = "netcdf",
      [ { "fftw-mpi", "fftw", "fftw-serial" } ] = "fftw",
      [ { "boost-mpi", "boost", "boost-serial" } ] = "boost",
      [ { "ls-dyna-mpi", "ls-dyna" } ] = "lsdyna",
      [ { "namd-verbs-smp", "namd-verbs", "namd-multicore", "namd-mpi" } ] = "namd",
      [ { "python27-scipy-stack", "python35-scipy-stack", "scipy-stack" } ] = "scipy_stack",
      [ { "python27-mpi4py", "python35-mpi4py", "mpi4py" } ] = "mpi4py",
      [ { "lammps", "lammps-omp", "lammps-user-intel" } ] = "lammps",
      [ { "starccm", "starccm-mixed" } ] = "starccm",
      [ { "gatk", "gatk-queue" } ] = "gatk",
      [ { "gdal", "gdal-mpi" } ] = "gdal",
      [ { "wrf", "pwrf" } ] = "wrf",
      [ { "lumerical", "fdtd_solutions"  } ] = "lumerical"
   }

   for k,v in pairs(familyT) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(k,myModuleFullName()) or has_value(k,myModuleName())) then
        ----------------------------------------------------------
        -- Loop over value array and fill properties for this module.
	family(v)
     end
   end
end

