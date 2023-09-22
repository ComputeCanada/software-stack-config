--------------------------------------------------------------------------
-- This is a placeholder for site specific functions.
-- @module SitePackage

require("strict")



-- Anything in this file will automatically be loaded everytime the Lmod command
-- is run.  Here are two suggestions on how to use your SitePackage.lua file 
--
-- a) Install Lmod normally and then overwrite your SitePackage.lua file over
--    this one in the install directory.

-- b) Create a file named "SitePackage.lua" in a different directory separate
--    from the Lmod installed directory.  Then you should modify
--    your modules.sh and modules.csh (or however you initialize the "module" command)
--    with:
--
--       (for bash, zsh, etc)
--       export LMOD_PACKAGE_PATH=/path/to/the/Site/Directory
--
--       (for csh)
--       setenv LMOD_PACKAGE_PATH /path/to/the/Site/Directory
--
--    A "SitePackage.lua" in that directory will override the one in the Lmod
--    install directory.
--
-----------------------------------------------------------------------------
-- You should check to see that Lmod finds your SitePackage.lua.  If you do:
-- 
--    $ module --config
-- 
-- and it reports:
-- 
--    Modules based on Lua: Version X.Y.Z  3016-02-05 16:31
--        by Robert McLay mclay@tacc.utexas.edu
-- 
--    Description                      Value
--    -----------                      -----
--    ...
--    Site Pkg location                standard
-- 
-- Then you haven't set things up correctly.
-----------------------------------------------------------------------------
--  Any function here that is called by a module file must be registered with
--  the sandbox.  For example you have following functions in your
--  SitePackage.lua file:
--
--      function sam()
--      end
--
--      function bill()
--      end
--
--  Then you have to add any functions defined here that you wish to call inside
--  a modulefile with the sandbox by doing:
--      sandbox_registration{ sam = sam, bill = bill}

------------------------------------------------------------------------
-- DO NOT FORGET TO USE CURLY BRACES "{}" and NOT PARENS "()"!!!!
------------------------------------------------------------------------

--  As an example suppose you want to require that users of a particular package must
--  be in a special group.  You can write this function here and use it in any
--  modulefile:
--
--
--     function module_requires_group(group)
--        local grps   = capture("groups")
--        local found  = false
--        local userId = capture("id -u")
--        local isRoot = tonumber(userId) == 0
--        for g in grps:split("[ \n]") do
--           if (g == group or isRoot)  then
--              found = true
--              break
--           end
--        end
--        return found
--     end
--
--     sandbox_registration{ ['required_group'] = module_requires_group }
--
--
--  Then in any module file you can have:
--
--
--     -------------------------
--     foo/1.0.lua:
--     -------------------------
--
--     local err_message="To use this module you must be in a particular group\n" ..
--                       "Please contact foo@my.supercomputer.center to join\n"
--
--     local found = required_group("G123456")
--
--     if (not found) then
--        LmodError(err_message)
--     end
--
--     prepend_path("PATH","/path/to/Foo/Bin")
--
--  Note that here I have used the name "required_group" in the modulefile and named the
--  function as "module_requires_group".  The key is the name used in the modulefile and
--  the right is what the function is called in SitePackage.lua.  The names can be the
--  same.
--

function dofile (filename)
	local f = assert(loadfile(filename))
	return f()
end

local lmod_package_path = os.getenv("LMOD_PACKAGE_PATH")
dofile(pathJoin(lmod_package_path,"SitePackage_logging.lua"))
dofile(pathJoin(lmod_package_path,"SitePackage_licenses.lua"))
dofile(pathJoin(lmod_package_path,"SitePackage_families.lua"))
dofile(pathJoin(lmod_package_path,"SitePackage_properties.lua"))
dofile(pathJoin(lmod_package_path,"SitePackage_visible.lua"))
dofile(pathJoin(lmod_package_path,"SitePackage_localpaths.lua"))
dofile(pathJoin(lmod_package_path,"SitePackage_warnings.lua"))

sandbox_registration{ loadfile = loadfile, assert = assert, loaded_modules = loaded_modules, serializeTbl = serializeTbl, clearWarningFlag = clearWarningFlag  }
require("strict")
require("string_utils")
local hook      = require("Hook")
local time = os.time
local date = os.date

function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end
local cached_arch = nil
function get_highest_supported_architecture()
	if not cached_arch then 
		cached_arch = _get_highest_supported_architecture()
	end
	return cached_arch
end
sandbox_registration{ get_highest_supported_architecture = get_highest_supported_architecture }
function _get_highest_supported_architecture()
	local flags = {};
	for line in io.lines("/proc/cpuinfo") do
		local values = string.match(line, "flags%s*: (.+)");
		if values ~= nil then
			for match in (values.." "):gmatch("(.-)".." ") do
				flags[match] = true;
			end
			break
		end
	end
	if flags.avx512f then
		return "avx512"
	elseif flags.avx2 then
		return "avx2"
	elseif flags.avx then
		return "avx"
	elseif flags.pni then
		return "sse3"
	end
	return "sse3"
end
local cached_vendor = nil
function get_cpu_vendor_id()
	if not cached_vendor then
		cached_vendor = _get_cpu_vendor_id()
	end
	return cached_vendor
end
sandbox_registration{ get_cpu_vendor_id = get_cpu_vendor_id }
function _get_cpu_vendor_id()
	local vendor_id = {};
	for line in io.lines("/proc/cpuinfo") do
		local values = string.match(line, "vendor_id%s*: (.+)");
		if values ~= nil then
			vendor_id = values
			break
		end
	end
	if vendor_id == "AuthenticAMD" then
		return "amd"
	elseif vendor_id == "GenuineIntel" then
		return "intel"
	else
		return "unknown"
	end
end
function get_interconnect()
	local posix = require "posix"
	if posix.stat("/sys/module/opa_vnic","type") == 'directory' then
		return "omnipath"
	elseif posix.stat("/sys/module/ib_core","type") == 'directory' then
		return "infiniband"
	end
	return "ethernet"
end
sandbox_registration{ get_interconnect = get_interconnect }
function get_installed_cuda_driver_version()
	local lfs       = require("lfs")
	local posix = require "posix"
	if posix.stat("/usr/lib64/nvidia","type") == 'directory' then
		for f in lfs.dir('/usr/lib64/nvidia') do
			local name = f:match("^(.+%.so).+$")
			if name == "libcuda.so" then
				local version = f:match("^.+%.so%.(.+)$")
				-- skip libcuda.so.1
				if version ~= "1" then
					return version
				end
			end
		end
	end
	return "0"
end
sandbox_registration{ get_installed_cuda_driver_version = get_installed_cuda_driver_version }
function cuda_driver_library_available(cuda_version_two_digits)
	-- https://docs.nvidia.com/deploy/cuda-compatibility/index.html
	-- New reference: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html
	local cuda_minimum_drivers_version = {
		[ "12.2" ] = "535.54.03",
		[ "12.1" ] = "530.30.02",
		[ "12.0" ] = "525.60.13",
		[ "11.8" ] = "520.61.05",
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
	local min_driver_version = cuda_minimum_drivers_version[cuda_version_two_digits] or "10000"
	if convertToCanonical(driver_version) >= convertToCanonical(min_driver_version) then
		return "native"
	end

	-- can possibly use compat library via LD_LIBRARY_PATH
	local restricted_available = os.getenv("CC_RESTRICTED") or "false"
	if (restricted_available == "true") then
		-- Older compat versions need driver 418.40.04+, 11.7 needs 450.36.06+, see
		-- https://docs.nvidia.com/deploy/cuda-compatibility/index.html#use-the-right-compat-package
		if convertToCanonical(cuda_version_two_digits) >= convertToCanonical("11.7") then
		    if convertToCanonical(driver_version) >= convertToCanonical("450.36.06") then
			return "compat"
		    end
		elseif convertToCanonical(driver_version) >= convertToCanonical("418.40.04") then
			return "compat"
		end
	end
	return "none"
end
sandbox_registration{ cuda_driver_library_available = cuda_driver_library_available }

local function unload_hook(t)
	set_family(t)
	set_local_paths(t)
end
local function load_hook(t)
	local valid = validate_license(t)
	set_props(t)
	set_family(t)
	incomplete_version_warning(t)
	default_module_change_warning(t)
	intel_old_stack_warning(t)
	log_module_load(t,true)
	set_local_paths(t)
end
local function spider_hook(t)
	set_props(t)
	set_local_paths(t)
end
hook.register("unload",           unload_hook)
hook.register("load",           load_hook)
hook.register("load_spider", 	spider_hook)
local mapT =
{
   grouped = {
      ['/cvmfs/.*/modules/.*/Core.*']     = "Core Modules",
      ['/cvmfs/.*/modules/.*/CUDA.*'] = "Cuda-dependent modules",
      ['/cvmfs/.*/modules/.*/avx512/Compiler.*'] = "Compiler-dependent avx512 modules",
      ['/cvmfs/.*/modules/.*/avx512/MPI.*'] = "MPI-dependent avx512 modules",
      ['/cvmfs/.*/modules/.*/avx2/Compiler.*'] = "Compiler-dependent avx2 modules",
      ['/cvmfs/.*/modules/.*/avx2/MPI.*'] = "MPI-dependent avx2 modules",
      ['/cvmfs/.*/modules/.*/avx/Compiler.*'] = "Compiler-dependent avx modules",
      ['/cvmfs/.*/modules/.*/avx/MPI.*'] = "MPI-dependent avx modules",
      ['/cvmfs/.*/modules/.*/sse3/Compiler.*'] = "Compiler-dependent sse3 modules",
      ['/cvmfs/.*/modules/.*/sse3/MPI.*'] = "MPI-dependent sse3 modules",
      ['/cvmfs/.*/custom/modules.avx$'] = "Custom avx modules",
      ['/cvmfs/.*/custom/modules.avx2$'] = "Custom avx2 modules",
      ['/cvmfs/.*/custom/modules.avx512$'] = "Custom avx512 modules",
      ['/cvmfs/.*/custom/modules.sse3$'] = "Custom sse3 modules",
      ['/cvmfs/.*/custom/modules$'] = "Custom modules",
      ['/opt/software/modulefiles'] = "Cluster specific modules",
      ['/project/.*'] = "Your groups' modules",
      ['/home/.*'] = "Your personal modules",
   },
}

function avail_hook(t)
   local availStyle = masterTbl().availStyle
   local styleT     = mapT[availStyle]
   if (not availStyle or availStyle == "system" or styleT == nil) then
      return
   end
   local localModulePaths = os.getenv("RSNT_LOCAL_MODULEPATHS") or nil
   if localModulePaths ~= nil then
	for localModulePathRoot in localModulePaths:split(":") do
	   styleT[localModulePathRoot .. "/.*/Core.*"] = "Cluster specific Core modules"
	   styleT[localModulePathRoot .. "/.*/CUDA.*"] = "Cluster specific Cuda-dependent modules"
	   styleT[localModulePathRoot .. "/.*/Compiler.*"] = "Cluster specific Compiler-dependent modules"
	   styleT[localModulePathRoot .. "/.*/MPI.*"] = "Cluster specific MPI-dependent modules"
	end
   end
   for k,v in pairs(t) do
      for pat,label in pairs(styleT) do
         if (k:find(pat)) then
            t[k] = label
            break
         end
      end
   end
end

hook.register("avail",avail_hook)


