require("serializeTbl")
require("string_utils")

function arch2023(arch)
	if arch == "avx2" then
		return "x86-64-v3"
	elseif arch == "avx512" then
		return "x86-64-v4"
	end
end

function has_arch2023(str)
	if string.find(str, "2023/x86%-64%-v3/") then
		return true
	end
	if string.find(str, "2023/x86%-64%-v4/") then
		return true
	end
	return false
end

function set_local_paths(t)
	
	local localModulePaths = os.getenv("RSNT_LOCAL_MODULEPATHS") or nil
	if localModulePaths == nil then
		return
	end


	local moduleNamesToCheck = { "openmpi", "intelmpi", "gcc", "intel", "pgi", "cuda", "nixpkgs", "gentoo" }
	local myModuleName = myModuleName()

	if has_value(moduleNamesToCheck, myModuleName) then
		local arch = os.getenv("RSNT_ARCH")
		local myModuleFullName = myModuleFullName()
		local myFileName = myFileName()

		-- get module version with two dots only
		local myModuleVersion = myModuleVersion()
		local myModuleVersionTwoDigits = string.gsub(myModuleVersion, ".[0-9]*$", "")
		local myModuleVersionOneDigit = string.gsub(myModuleVersionTwoDigits, ".[0-9]*$", "")
		myModuleVersionOneDigit = tonumber(myModuleVersionOneDigit) or 0

		local rootPath = "^/cvmfs/soft.computecanada.ca/"
		local rootEasyBuildModulePath = "^/cvmfs/soft.computecanada.ca/easybuild/modules/"
		local relativeModulePaths = ""
		-- these modules are not in the same paths as others:w
		--
		if myModuleName == "nixpkgs" then
			relativeModulePaths = "2017/Core"	
		elseif myModuleName == "gentoo" then
			if myModuleVersion == "2019" then
				relativeModulePaths = "2019/Core"
			elseif myModuleVersion == "2020" then
				relativeModulePaths = "2020/Core:2020/" .. arch .. "/Core"
			elseif myModuleVersion == "2023" then
				-- arch dirnames changed in StdEnv/2023 but not RSNT_ARCH values
				-- e.g. avx2 -> x86-64-v3
				arch = arch2023(arch)
				relativeModulePaths = "2023/" .. arch .. "/Core"
			end
		else
			local rootModulePath = rootEasyBuildModulePath
			local relativeFileName = string.gsub(myFileName, rootModulePath, "")
			-- from the module filename, remove the <name>/<version>.lua
			relativeModulePaths = string.gsub(relativeFileName, myModuleFullName .. ".lua", "")
--			LmodWarning("myModuleName:" .. myModuleName)
--			LmodWarning("initial:" .. relativeModulePaths)
	
			local subPath = myModuleName .. myModuleVersionTwoDigits

			if myModuleName == "openmpi" or myModuleName == "intelmpi" or myModuleName == "impi" then
				-- build the module path by changing Compiler or CUDA by MPI 
				relativeModulePaths = string.gsub(relativeModulePaths, "/Compiler/", "/MPI/")
				relativeModulePaths = string.gsub(relativeModulePaths, "/CUDA/", "/MPI/")
			elseif myModuleName == "gcc" or myModuleName == "intel" or myModuleName == "pgi" then
				-- build the module path by changing Core by Compiler
				if has_arch2023(relativeModulePaths) then
					relativeModulePaths = string.gsub(relativeModulePaths, "/Core/", "/Compiler/")
				else
					relativeModulePaths = string.gsub(relativeModulePaths, "/Core/", "/" .. arch .. "/Compiler/")
					relativeModulePaths = string.gsub(relativeModulePaths, "/Core%-sse3/", "/" .. arch .. "/Compiler/")
					relativeModulePaths = string.gsub(relativeModulePaths, "/Core%-avx/", "/" .. arch .. "/Compiler/")
					relativeModulePaths = string.gsub(relativeModulePaths, "/Core%-avx2/", "/" .. arch .. "/Compiler/")
					relativeModulePaths = string.gsub(relativeModulePaths, "/Core%-avx512/", "/" .. arch .. "/Compiler/")
				end
--				LmodWarning("replaced:" .. relativeModulePaths)
			elseif myModuleName == "cuda" then
				-- build the module path by changing Compiler for CUDA
				relativeModulePaths = string.gsub(relativeModulePaths, "/Compiler/", "/CUDA/")
			end
--			LmodWarning("after_replacement:" .. relativeModulePaths)
	
			-- intelmpi is a corner case, we use impi rather than the usual convention
			-- after impi2018.3 we started using a single digit: impi2019, impi2021
			if myModuleName == "intelmpi" then
				if myModuleVersionOneDigit >= 2019 then
					subPath = "impi" .. myModuleVersionOneDigit
				else
					subPath = "impi" .. myModuleVersionTwoDigits
				end
			end
			-- gcc >= 8, intel >= 2019, openmpi >= 4 use a single version for directories
			if myModuleName == "gcc" and myModuleVersionOneDigit >= 8 then
				subPath = myModuleName .. myModuleVersionOneDigit
			end
			if myModuleName == "intel" and myModuleVersionOneDigit >= 2019 then
				subPath = myModuleName .. myModuleVersionOneDigit
			end
			if myModuleName == "openmpi" and myModuleVersionOneDigit >= 4 then
				subPath = myModuleName .. myModuleVersionOneDigit
			end
			--LmodWarning(subPath)
			--LmodWarning(relativeModulePaths)
			-- and adding the subPath
			relativeModulePaths = pathJoin(relativeModulePaths, subPath)
		end

		for localModulePathRoot in localModulePaths:split(":") do
			for relativeModulePath in relativeModulePaths:split(":") do
				local localModulePath = pathJoin(localModulePathRoot, relativeModulePath)
				--LmodWarning(localModulePath)
				--LmodWarning(myModuleFullName .. ":" .. localModulePath)
				if isDir(localModulePath) then
					prepend_path("MODULEPATH", localModulePath)
				end
			end
		end
	end
end

