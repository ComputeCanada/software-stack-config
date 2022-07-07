function visible_hook(t)
	local restricted_packages = {
		"abaqus", 
		"allinea",
		"amber",
		"ansys",
		"cfour-mpi",
		"comsol",
		"cpmd",
		"ddt-cpu",
		"ddt-gpu",
		"demon2k",
		"dl_poly4",
		"feko",
		"fluent",
		"hfss",
		"ls-dyna",
		"ls-dyna-mpi",
		"ls-opt",
		"maker",
		"matlab",
		"oasys-ls-dyna",
		"orca",
		"starccm",
		"starccm-mixed",
	}
	local pathT = {
		[ "vasp" ] = "/opt/software/easybuild",
		[ "gaussian" ] = "/opt/software/gaussian",
		[ "singularity/2.5" ] = "/opt/software/singularity-2.5",
		[ "singularity/2.6" ] = "/opt/software/singularity-2.6",
		[ "singularity/3.1" ] = "/opt/software/singularity-3.1",
		[ "singularity/3.2" ] = "/opt/software/singularity-3.2",
		[ "singularity/3.3" ] = "/opt/software/singularity-3.3",
		[ "singularity/3.4" ] = "/opt/software/singularity-3.4",
		[ "singularity/3.5" ] = "/opt/software/singularity-3.5-hidden",
		[ "singularity/3.6" ] = "/opt/software/singularity-3.6-hidden",
		[ "singularity/3.7" ] = "/opt/software/singularity-3.7",
                [ "singularity/3.8" ] = "/opt/software/singularity-3.8",
	}
	local moduleName = t.sn
	local fullName = t.fullName
	local fn = t.fn
	local posix = require "posix"
	-- only test visibility for modules in /cvmfs/soft.computecanada.ca
	local prefix = "/cvmfs/soft.computecanada.ca"
	if (string.sub(fn,1,string.len(prefix)) ~= prefix) then
		return
	end
	local modulePath = pathT[moduleName] or pathT[fullName]
	if modulePath ~= nil then
		local ftype = posix.stat(modulePath,"type") or nil
		if ftype == nil then
			t['isVisible'] = false
			return
		end
	end
	local restricted_available = os.getenv("CC_RESTRICTED") or "false"
	if (restricted_available ~= "true") then
		if (has_value(restricted_packages,moduleName)) then
			t['isVisible'] = false
			return
		end
	end

	if moduleName == "cuda" then
		-- https://docs.nvidia.com/deploy/cuda-compatibility/index.html
		-- New reference: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html
		local cuda_minimum_drivers_version = {
			[ "11.7" ] = "515.43.04",
			[ "11.6" ] = "510.47.03",
			[ "11.5" ] = "495.29.05",
			[ "11.4" ] = "470.57.02",
			[ "11.3" ] = "465.19.01",
			[ "11.2" ] = "460.32.03",
			[ "11.1" ] = "455.32",
			[ "11.0" ] = "450.51.06",
			[ "10.2" ] = "440.33",
			[ "10.1" ] = "418.39",
			[ "10.0" ] = "410.48",
			[ "9.2" ] = "396.26",
			[ "9.1" ] = "390.46",
			[ "9.0" ] = "384.81",
			[ "8.0" ] = "367.48",
			[ "7.5" ] = "352.31",
			[ "7.0" ] = "346.46"
		}
		local driver_version = os.getenv("RSNT_CUDA_DRIVER_VERSION") or "0"
		-- for backward compatibility, if no driver version were found, we consider that they can run 10.2
		-- this is because we introduced hiding of cuda versions when cuda/11.0 was just out
		if driver_version == "0" then
			driver_version = cuda_minimum_drivers_version["10.2"]
		end
		local cuda_version_two_digits = fullName:match("^.+/([0-9]+%.[0-9]+).*$")
		local min_driver_version = cuda_minimum_drivers_version[cuda_version_two_digits] or "10000"
		
		if convertToCanonical(driver_version) < convertToCanonical(min_driver_version) then
			t['isVisible'] = false
		end
	end
	local arch = get_highest_supported_architecture()
	if moduleName == "arch" then
		local name = nil
		local version = nil
		for v in fullName:split("/") do
			name = version
			version = v
		end
		if version == "avx" and (arch == "sse3") then
			t['isVisible'] = false
		elseif version == "avx2" and (arch == "sse3" or arch == "avx") then
			t['isVisible'] = false
		elseif version == "avx512" and (arch == "sse3" or arch == "avx" or arch == "avx2") then
			t['isVisible'] = false
		end
	end
end

local hook      = require("Hook")
hook.register("isVisibleHook",  visible_hook)

