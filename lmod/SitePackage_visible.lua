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
		local cuda_version_two_digits = fullName:match("^.+/([0-9]+%.[0-9]+).*$")
		if cuda_driver_library_available(cuda_version_two_digits) == "none" then
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

