
function set_family(t)
   ------------------------------------------------------------
   -- table of properties for fullnames or sn

   local familyT = {
      [ { "gcc", "intel", "pgi" } ] = "compiler",
      [ { "openmpi", "mvapich2" } ] = "mpi",
      [ { "nixpkgs", "gentoo" } ] = "base_os",
      [ { "hdf5-mpi", "hdf5", "hdf5-serial" } ] = "hdf5",
      [ { "petsc", "petsc-64bits", "petsc-debug", "petsc-complex" } ] = "petsc",
      [ { "gromacs", "gromacs-plumed", "gromacs-colvars" } ] = "gromacs",
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
      [ { "wrf", "wrf-co2", "pwrf" } ] = "wrf",
      [ { "lumerical", "fdtd_solutions"  } ] = "lumerical",
      [ { "openmabel", "openbabel-omp"  } ] = "openbabel",
      [ { "scotch", "scotch-no-thread" } ] = "scotch"
   }

   for k,v in pairs(familyT) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(k,myModuleFullName()) or has_value(k,myModuleName())) then
        ----------------------------------------------------------
        -- Loop over value array and fill properties for this module.
	if (has_value(k, "fftw")) then
	   -- fftw-mpi 3.3.10 depends on fftw, no longer conflicts with it
	   if(convertToCanonical(myModuleVersion()) < convertToCanonical("3.3.10")) then
	      family(v)
	   end
	else
	   family(v)
	end
     end
   end
end
