local ompiv=...
local cluster = os.getenv("CC_CLUSTER") or nil
local arch = os.getenv("RSNT_ARCH") or nil
local interconnect = os.getenv("RSNT_INTERCONNECT") or nil
local gentoo = os.getenv("EBROOTGENTOO") or nil

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

if cluster == "beluga" then
	-- hack to disable OpenIB warnings on Beluga login nodes,
	-- and UCX issues from trying to use mlx5_2 and mlx5_bond_0
	setenv("UCX_NET_DEVICES","mlx5_0:1")
	setenv("OMPI_MCA_btl_openib_if_include", "mlx5_0")
end

if posix.stat(pathJoin(slurmpath,"libslurm.so.36"),"type") == "link" then
	-- we need SLURM_WHOLE for Slurm 20.11 which ships with .so.36
	-- older Slurms use .so.35
	setenv("OMPI_MCA_plm_slurm_args", "--whole")
end

if ompiv == "1.6" or ompiv == "1.8" or ompiv == "1.10" or ompiv == '2.0' or ompiv == '2.1' then
	-- OpenMPI 3.1+ do not need LD_LIBRARY_PATH any more
	if slurmpath and posix.stat(pathJoin(slurmpath,"libpmi.so"),"type") == "link" then
		prepend_path("LD_LIBRARY_PATH", slurmpath)
		-- below is so we can recover it after newgrp
		prepend_path("RSNT_LD_LIBRARY_PATH", slurmpath)
	end
end

if ompiv == "2.1" or ompiv == "3.1" or ompiv == "4.0" or ompiv == "4.1" then
	local slurm_pmi = nil
	if slurmpath then
		if ompiv == "3.1" or ompiv == "4.0" or ompiv == "4.1" then
			if posix.stat(pathJoin(slurmpath,"slurm/mpi_pmix_v4.so"),"type") == "regular" then
				slurm_pmi = "pmix_v4"
			elseif posix.stat(pathJoin(slurmpath,"slurm/mpi_pmix_v3.so"),"type") == "regular" then
				slurm_pmi = "pmix_v3"
			elseif posix.stat(pathJoin(slurmpath,"slurm/mpi_pmix_v2.so"),"type") == "regular" then
				slurm_pmi = "pmix_v2"
			else
				slurm_pmi = "pmi2"
			end
		else
			if posix.stat(pathJoin(slurmpath,"slurm/mpi_pmix_v1.so"),"type") == "regular" then
				if not posix.stat("/usr/lib64/libpmix.so.2.0.2") then
					slurm_pmi = "pmix_v1"
				end
			end
		end
		if slurm_pmi then
			setenv("SLURM_MPI_TYPE", slurm_pmi)
			-- RSNT_SLURM_MPI_TYPE is set so we can recover SLURM_MPI_TYPE after salloc
			setenv("RSNT_SLURM_MPI_TYPE", slurm_pmi)
		end
	end

elseif ompiv == "5.0" then
	-- 5.0 only supports PMIx
	setenv("SLURM_MPI_TYPE", "pmix")
	setenv("RSNT_SLURM_MPI_TYPE", "pmix")
end

if ompiv == "2.1" or ompiv == "2.0" or (ompiv == "1.10" and arch == "avx512") then
	if interconnect == "omnipath" or interconnect == "ethernet" then
	        setenv("OMPI_MCA_mtl", "^mxm")
	        setenv("OMPI_MCA_pml", "^yalla,ucx")
	        setenv("OMPI_MCA_btl", "^openib")
	        setenv("OMPI_MCA_oob", "^ud")
	        setenv("OMPI_MCA_coll", "^fca,hcoll")
	else
		if (ompiv == "2.1" or ompiv == "1.10") and cluster == "beluga" then
			-- Beluga 2.1 and 1.10 behave like 3.1, better performance.
			setenv("OMPI_MCA_mtl", "^mxm")
			setenv("OMPI_MCA_pml", "ucx")
			-- disable openib unconditionally, as it does not work very well with UCX
			setenv("OMPI_MCA_btl", "^openib")
			-- avoids error messages about multicast, needs investigation
			-- setenv("HCOLL_ENABLE_MCAST_ALL", "0")
			-- we have multiple issues with the hcoll module, will need
			-- thorough investigation, disabling for now
			setenv("OMPI_MCA_coll", "^hcoll")
		else
			setenv("OMPI_MCA_pml", "^ucx")
			setenv("MXM_LOG_LEVEL", "error")
		end
	end
elseif  ompiv == "3.1" or ompiv == "4.0" or ompiv == "4.1" then
	-- disable openib unconditionally, as it does not work very well with UCX
	setenv("OMPI_MCA_btl", "^openib")

	if interconnect == "omnipath" or interconnect == "ethernet" then
	        setenv("OMPI_MCA_pml", "^ucx,yalla")
	        if ompiv == "3.1" then -- removed in 4.0; don't use ofi by default for cuda
			setenv("OMPI_MCA_mtl", "^mxm,ofi")
			setenv("OMPI_MCA_oob", "^ud")
		else
			if interconnect == "ethernet" then
				setenv("OMPI_MCA_mtl", "^ofi")
			end
			if ompiv == "4.1" then -- omnipath nodes may run out of contexts if the ofi btl is enabled
				setenv("OMPI_MCA_btl", "^openib,ofi")
			end
		end
	        setenv("OMPI_MCA_coll", "^fca,hcoll")
		setenv("OMPI_MCA_osc", "^ucx")
	else
	        setenv("OMPI_MCA_pml", "^yalla")
		if ompiv == "3.1" then -- removed in 4.0
			setenv("OMPI_MCA_mtl", "^mxm")
		else -- ofi mtl/btl are suboptimal with IB and can give cryptic warnings
			setenv("OMPI_MCA_mtl", "^ofi")
			setenv("OMPI_MCA_btl", "^openib,ofi")
		end
		-- avoids error messages about multicast, needs investigation
		-- setenv("HCOLL_ENABLE_MCAST_ALL", "0")
		-- we have multiple issues with the hcoll module, will need
		-- thorough investigation, disabling for now
		setenv("OMPI_MCA_coll", "^hcoll")
	end
elseif ompiv == "5.0" then
	-- omnipath nodes may run out of contexts if the ofi btl is enabled
	setenv("OMPI_MCA_btl", "^ofi")
	if interconnect ~= "infiniband" then
	        setenv("OMPI_MCA_pml", "^ucx")
		setenv("OMPI_MCA_osc", "^ucx")
	end
	if interconnect ~= "omnipath" then
		-- ofi mtl/btl are suboptimal with IB and can give cryptic warnings
		setenv("OMPI_MCA_mtl", "^ofi")
	end
	if posix.stat("/dev/knem", "type") ~= "character device" then
		setenv("OMPI_MCA_smsc", "^knem")
	end
elseif ompiv == "1.6" or ompiv == "1.8" or ompiv == "1.10" then
	if interconnect == "omnipath" or interconnect == "ethernet" then
		setenv("OMPI_MCA_mtl", "^mxm")
		setenv("OMPI_MCA_pml", "^yalla")
	else
		setenv("MXM_LOG_LEVEL", "error")
	end
end

-- for CUDA + omnipath enable direct GPU transfers
if interconnect == "omnipath" and isloaded("cuda") then
	setenv("PSM2_CUDA", 1)
end
