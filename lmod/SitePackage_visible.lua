function installed_cuda_driver_version(t) 
	local lfs       = require("lfs")
	for f in lfs.dir('/usr/lib64/nvidia') do
		local name = f:match("^(.+%.so).+$")
		if name == "libcuda.so" then
			local version = f:match("^.+%.so%.(.+)$")
			if version ~= "1" then
				return version
			end
		end
	end
end

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
		[ "singularity/3.5" ] = "/opt/software/singularity-3.5",
		[ "cuda" ] = "/usr/lib64/nvidia",
	}
	-- https://docs.nvidia.com/deploy/cuda-compatibility/index.html
	local cuda_minimum_drivers_version = {
		[ "11.0" ] = "450.36.06",
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

	local arch = get_highest_supported_architecture()
	if moduleName == "cuda" then
		local driver_version = installed_cuda_driver_version()
		local cuda_version_two_digits = fullName:match("^.+/([0-9]+%.[0-9]+).*$")
		local dv_major = tonumber(driver_version:match("^([0-9]+)%..*$"))
		local dv_minor = tonumber(driver_version:match("^[0-9]+%.([0-9]+).*$"))
		local dv_revision = tonumber(driver_version:match("^[0-9]+%.[0-9]+%.([0-9]+)$")) or 0
		local min_driver_version = cuda_minimum_drivers_version[cuda_version_two_digits]
		local min_dv_major = tonumber(min_driver_version:match("^([0-9]+)%..*$"))
		local min_dv_minor = tonumber(min_driver_version:match("^[0-9]+%.([0-9]+).*$"))
		local min_dv_revision = tonumber(min_driver_version:match("^[0-9]+%.[0-9]+%.([0-9]+)$")) or 0

		if dv_major < min_dv_major then
			t['isVisible'] = false
		elseif dv_major == min_dv_major and dv_minor < min_dv_minor then
			t['isVisible'] = false
		elseif dv_major == min_dv_major and dv_minor == min_dv_minor and dv_revision < min_dv_revision then
			t['isVisible'] = false
		end
	end
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

