local ompiv=...
local cluster = os.getenv("CC_CLUSTER") or nil

if cluster == "beluga" then
	-- hack to disable OpenIB warnings on Beluga login nodes
	setenv("OMPI_MCA_btl_openib_if_exclude", "mlx5_bond_0")
	setenv("OMPI_MCA_btl_openib_warn_nonexistent_if", "0")
end

if ompiv == "2.1" or ompiv == "2.0" then
	if os.getenv("RSNT_INTERCONNECT") == "omnipath" then
	        setenv("OMPI_MCA_mtl", "^mxm")
	        setenv("OMPI_MCA_pml", "^yalla,ucx")
	        setenv("OMPI_MCA_btl", "^openib")
	        setenv("OMPI_MCA_oob", "^ud")
	        setenv("OMPI_MCA_coll", "^fca")
	else
	        setenv("OMPI_MCA_pml", "^ucx")
	end
elseif  ompiv == "3.1" then
	setenv("SLURM_MPI_TYPE", "pmi2")
	setenv("OMPI_MCA_mtl", "^mxm")

	if os.getenv("RSNT_INTERCONNECT") == "omnipath" then
	        setenv("OMPI_MCA_pml", "^ucx,yalla")
	        setenv("OMPI_MCA_btl", "^openib")
	        setenv("OMPI_MCA_oob", "^ud")
	        setenv("OMPI_MCA_coll", "^fca,hcoll")
	else
	        setenv("OMPI_MCA_pml", "^yalla")
	end
elseif ompiv == "1.6" or ompiv == "1.8" then
	if os.getenv("RSNT_INTERCONNECT") == "omnipath" then
		setenv("OMPI_MCA_mtl", "^mxm")
		setenv("OMPI_MCA_pml", "^yalla")
	end
end


