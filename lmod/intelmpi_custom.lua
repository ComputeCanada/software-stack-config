local impiv = ...
local posix = require "posix"

local slurmpaths = { "/opt/software/slurm/lib", "/opt/software/slurm/lib64",
                     "/opt/slurm/lib64" }
local slurmpath = nil

for i,v in ipairs(slurmpaths) do
	if posix.stat(pathJoin(v,"libslurm.so"),"type") == "link" then
		slurmpath = v
		break
	end
end

if slurmpath then
	if posix.stat(pathJoin(slurmpath,"libslurm.so.36"),"type") == "link" then
		-- we need to use --whole for Slurm 20.11 which ships with .so.36
		-- older Slurms use .so.35 or older
		setenv("I_MPI_HYDRA_BOOTSTRAP_EXEC_EXTRA_ARGS", "--whole")
	else
		setenv("I_MPI_HYDRA_BOOTSTRAP_EXEC_EXTRA_ARGS", "--cpu-bind=none")
	end
end

if impiv == "2019.7" then
	setenv("I_MPI_PMI_LIBRARY", "libpmi2.so")
	setenv("I_MPI_HYDRA_TOPOLIB", "ipl")
else
	if posix.stat(pathJoin(slurmpath,"libpmi.so"),"type") == "link" then
		setenv("I_MPI_PMI_LIBRARY", pathJoin(slurmpath,"libpmi.so"))
	end
end

if string.sub(impiv,1,4) == "2019" then
	setenv("I_MPI_LINK", "opt")
elseif string.sub(impiv,1,4) ~= "2021" then
	if os.getenv("RSNT_INTERCONNECT") == "omnipath" then
		setenv("I_MPI_FABRICS_LIST", "ofi,tmi,dapl,tcp,ofa")
	else
		setenv("I_MPI_FABRICS_LIST", "ofa,dapl,tmi,tcp,ofi")
	end
end
