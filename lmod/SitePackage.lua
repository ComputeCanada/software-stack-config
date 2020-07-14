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
	else
		return "0"
	end
end
sandbox_registration{ get_installed_cuda_driver_version = get_installed_cuda_driver_version }

local function default_module_change_warning(t)
	local FrameStk   = require("FrameStk")
	local frameStk   = FrameStk:singleton()
	local modulename = myModuleName()
--	if (modulename == "scipy-stack") then
		-- This will only display if "module load scipy-stack" is used, for "module load scipy-stack/2019a"
		-- there is a deprecation message
--		if (frameStk:userName() == modulename) then
--			LmodMessage("==============================================================================================")
--			LmodMessage("Warning, on December 1st, the default scipy-stack module will be changed to 2019b.")
--			LmodMessage("Note that version 2019a is the last one to support python/2.7.")
--			LmodMessage("If you need python/2.7, we suggest you load the module scipy-stack/2019a")
--			LmodMessage("Version 2019b is the first one to support python/3.8.")
--			LmodMessage("==============================================================================================")
--			LmodMessage("")
--			LmodMessage("Attention! Le 1er decembre, la version par default de scipy-stack deviendra la version 2019b.")
--			LmodMessage("Notez que la version 2019a est la derniere qui supportera python/2.7.")
--			LmodMessage("Si vous devez utiliser python/2.7, nous vous suggerons de charger le module scipy-stack/2019a")
--			LmodMessage("La version 2019b est la premiere version a supporter python/3.8.")
--			LmodMessage("==============================================================================================")
--		end
--	end
end
local function unload_hook(t)
	set_family(t)
	set_local_paths(t)
end
local function load_hook(t)
	local valid = validate_license(t)
	set_props(t)
	set_family(t)
	default_module_change_warning(t)
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


