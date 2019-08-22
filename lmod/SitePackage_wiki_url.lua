function set_wiki_url(t)
   ------------------------------------------------------------
   -- table of properties for fullnames or sn
   local wiki_urlT = {
	   [ { "abaqus" } ] = "Abaqus",
	   [ { "abinit" } ] = "ABINIT",
	   [ { "ansys", "fluent", "cfx" } ] = "ANSYS",
	   [ { "spark" } ] = "Apache Spark",
	   [ { "cuda" } ] = "CUDA",
	   [ { "cpmd" } ] = "CPMD",
	   [ { "delft3d" } ] = "Delft3D",
	   [ { "gaussian" } ] = "Gaussian",
	   [ { "gromacs", "gromacs-plumed" } ] = "GROMACS",
	   [ { "java" } ] = "Java",
	   [ { "namd", "namd-verbs", "namd-multicore", "namd-verbs-smp", "namd-mpi" } ] = "NAMD",
	   [ { "matlab", "mcr" } ] = "MATLAB",
	   [ { "openmpi", "mvapich2" } ] = "MPI",
	   [ { "orca" } ] = "ORCA",
	   [ { "paraview", "paraview-offscreen", "paraview-offscreen-gpu" } ] = "Visualization",
	   [ { "perl" } ] = "Perl",
	   [ { "python" } ] = "Python",
	   [ { "quantumespresso" } ] = "Quantum ESPRESSO",
	   [ { "r" } ] = "R",
	   [ { "vasp" } ] = "VASP",
	   [ { "caffe2" } ] = "Caffe2",
	   [ { "starccm", "starccm-mixed" } ] = "StarCCM",
	   [ { "ddt-cpu", "ddt-gpu" } ] = "ARM software",
	   [ { "openfoam" } ] = "OpenFOAM",
   }

   for k,v in pairs(wiki_urlT) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(k,myModuleFullName()) or has_value(k,myModuleName())) then
        ----------------------------------------------------------
        -- Loop over value array and fill properties for this module.
	whatis("CC-Wiki: " .. v)
     end
   end
end

