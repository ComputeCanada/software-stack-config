local impiv = ...
local posix = require "posix"

local slurmpaths = { "/opt/software/slurm/lib", "/opt/software/slurm/lib64",
                     "/opt/slurm/lib64" }

if impiv == "2019.7" then
	setenv("I_MPI_PMI_LIBRARY", "libpmi2.so")
	setenv("I_MPI_HYDRA_TOPOLIB", "ipl")
else
	for i,v in ipairs(slurmpaths) do
		if posix.stat(pathJoin(v,"libpmi.so"),"type") == "link" then
			setenv("I_MPI_PMI_LIBRARY", pathJoin(v,"libpmi.so"))
			break
		end
	end
end

if string.sub(impiv,1,4) ~= "2019" then
	if os.getenv("RSNT_INTERCONNECT") == "omnipath" then
		setenv("I_MPI_FABRICS_LIST", "ofi,tmi,dapl,tcp,ofa")
	else
		setenv("I_MPI_FABRICS_LIST", "ofa,dapl,tmi,tcp,ofi")
	end
end
