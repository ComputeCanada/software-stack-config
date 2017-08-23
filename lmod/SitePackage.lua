--------------------------------------------------------------------------
-- This is a placeholder for site specific functions.
-- @module SitePackage

require("strict")


--------------------------------------------------------------------------------
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

local getenv    = os.getenv
function getenv_logged(var,default)
	local val = getenv(var)
	if not val then
		val = default
		local user = getenv("USER") or "unknown"
		local slurm_jobid = getenv("SLURM_JOB_ID") or "-"
		local moab_jobid = getenv("MOAB_JOBID") or "-"
		local pbs_jobid = getenv("PBS_JOBID") or "-"
		local jobid = getenv("SLURM_JOB_ID") or getenv("MOAB_JOBID") or getenv("PBS_JOBID") or "-"
		local hostname = getenv("HOSTNAME") or "unknown"
		local cluster = getenv("CC_CLUSTER") or "unknown"
		os.execute("logger -t lmod-err -p local0.info User " .. user .. " had the environment variable " .. var .. " undefined in job " .. jobid .. " on host " .. hostname .. " on cluster " .. cluster)
	end
	return val
end

sandbox_registration{ loadfile = loadfile, assert = assert, getenv_logged = getenv_logged }
require("strict")
require("string_utils")
local hook      = require("Hook")
local concatTbl = table.concat
local time = os.time
local date = os.date

local function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end
local function set_family(t)
   ------------------------------------------------------------
   -- table of properties for fullnames or sn

   local familyT = {
      [ { "gcc", "intel", "pgi" } ] = "compiler",
      [ { "openmpi", "mvapich2" } ] = "mpi",
      [ { "hdf5-mpi", "hdf5", "hdf5-serial" } ] = "hdf5",
      [ { "gromacs-plumed", "gromacs" } ] = "gromacs",
      [ { "netcdf-mpi", "netcdf", "netcdf-serial" } ] = "netcdf",
      [ { "fftw-mpi", "fftw", "fftw-serial" } ] = "fftw",
      [ { "boost-mpi", "boost", "boost-serial" } ] = "boost",
      [ { "ls-dyna-mpi", "ls-dyna" } ] = "lsdyna",
   }

   for k,v in pairs(familyT) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(k,myModuleFullName()) or has_value(k,myModuleName())) then
        ----------------------------------------------------------
        -- Loop over value array and fill properties for this module.
	family(v)
     end
   end
end
local function set_wiki_url(t)
   ------------------------------------------------------------
   -- table of properties for fullnames or sn
   local wiki_urlT = {
	   [ { "abinit" } ] = "Abinit",
	   [ { "spark" } ] = "Apache Spark",
	   [ { "cuda" } ] = "CUDA",
	   [ { "gaussian" } ] = "Gaussian",
	   [ { "gromacs", "gromacs-plumed" } ] = "GROMACS",
	   [ { "java" } ] = "Java",
	   [ { "namd", "namd-verbs", "namd-multicore", "namd-verbs-smp", "namd-mpi" } ] = "NAMD",
	   [ { "matlab", "mcr" } ] = "Matlab",
	   [ { "openmpi", "mvapich2" } ] = "MPI",
	   [ { "paraview", "paraview-offscreen", "paraview-offscreen-gpu" } ] = "Visualization",
	   [ { "perl" } ] = "Perl",
	   [ { "python" } ] = "Python",
	   [ { "quantumespresso" } ] = "Quantum ESPRESSO",
	   [ { "r" } ] = "R",
	   [ { "vasp" } ] = "VASP",

   }

   for k,v in pairs(wiki_urlT) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(k,myModuleFullName()) or has_value(k,myModuleName())) then
        ----------------------------------------------------------
        -- Loop over value array and fill properties for this module.
	whatis("CC-Wiki: " .. v)
     end
   end
end
local function user_accepted_license(soft,autoaccept)
	require "lfs"
	local posix = require "posix"
	require "io"
	require "os"
	local user = getenv_logged("USER","unknown")
	local home = getenv_logged("HOME",pathJoin("/home",user))
	local license_dir = home .. "/.licenses"
	local license_file = license_dir .. "/" .. soft
	if not (posix.stat(license_dir,"type") == 'directory') then
		lfs.mkdir(license_dir)
	end
	if (posix.stat(license_file,"type") == 'regular') then
		return true
	elseif (autoaccept) then
		local file = io.open(license_file,"w")
		file:close()
		
		local cmd = "logger -t lmod-UA-1.0 -p local0.info User " .. user .. " accepted usage agreement for software " .. soft
 		os.execute(cmd)
		
		return false
	end
	return false
end
local function confirm_acceptance(soft)
	require "io"
	local answer = io.read()
	if (string.lower(answer) == "yes" or string.lower(answer) == "oui") then
		user_accepted_license(soft,true)
		return true
	else 
		return false
	end
	return false
end
local function localUserInGroup(group)
	local handle = io.popen("groups 2>/dev/null")
	local grps = handle:read()
	handle:close()
	local found  = false
	for g in string.gmatch(grps, '([^ ]+)') do
		if (g == group)  then
			found = true
			break
		end
	end
	return found
end
function find_and_define_license_file(environment_variable,application)
	require'lfs'
	require "os"
	-- skip the test in these cases
	local fn = myFileName()
	local user = getenv_logged("USER","unknown")
	if ((fn:find("^/cvmfs") == nil and fn:find("^/opt/software") == nil) or user == "ebuser") then
		return true
	end
	local posix = require "posix"
	local license_found = false

	-- First, look at the public repository for a file called by the cluster's name
	local cluster = os.getenv("CC_CLUSTER") or nil
	local dir = pathJoin("/cvmfs/soft.computecanada.ca/config/licenses/",application)
	if (posix.stat(dir,"type") == 'directory') then
		local path = pathJoin(dir,cluster .. ".lic")
		if (posix.stat(path,"type") == 'regular') then
			prepend_path(environment_variable,path)
			license_found = true
		end
	end

	-- Second, look at restricted repository for a license readable if you are in the right group
	local dir = pathJoin("/cvmfs/restricted.computecanada.ca/config/licenses/",application)
	if (posix.stat(dir,"type") == 'directory') then
		for item in lfs.dir(dir) do
			local path = pathJoin(dir,item)
			-- check if we can read the path
			if (io.open(path)) then
				-- the item is a directory, find a file called <cluster>.lic in that directory
				if (posix.stat(path,"type") == 'directory') then
					local file = pathJoin(path,cluster .. ".lic")
					if (posix.stat(file,"type") == 'regular') then
						-- We can open that file, lets use it as license file
						prepend_path(environment_variable,file)
						license_found = true
					end
				elseif (posix.stat(path,"type") == 'regular') then
					-- We can open that file, lets use it as license file
					prepend_path(environment_variable,path)
					license_found = true
				end
			end
		end
	end

	-- Third, look at the user's home for a $HOME/.licenses/<application>.lic
	local home = getenv_logged("HOME",pathJoin("/home",user))
	local license_file = pathJoin(home,".licenses",application .. ".lic")
	if (posix.stat(license_file,"type") == 'regular') then
		prepend_path(environment_variable,license_file)
		license_found = true
	end
	return license_found 
end
sandbox_registration{ find_and_define_license_file = find_and_define_license_file }

local function log_module_load(t,success)
	-- t is a table containing:
	-- t.modFullName:   Full name of the Module,
	-- t.fn:            the path of the modulefile.

	local a   = {}
	local hostname = getenv("HOSTNAME")
	local user = getenv_logged("USER","unknown")
	local slurm_jobid = getenv("SLURM_JOB_ID") or "-"
	local moab_jobid = getenv("MOAB_JOBID") or "-"
	local pbs_jobid = getenv("PBS_JOBID") or "-"
	local jobid = getenv("SLURM_JOB_ID") or getenv("MOAB_JOBID") or getenv("PBS_JOBID") or "-"
	local clustername = getenv("CC_CLUSTER")
	if hostname == nil then
		hostname = io.popen("hostname"):read("*a")
		hostname = string.gsub(hostname,"[\n\r]+ *","")
		hostname = string.gsub(hostname,"^ *","")
	end
	a[#a+1] = "H=" .. hostname
	a[#a+1] = "U=" .. user
	a[#a+1] = "SJ=" .. slurm_jobid
	a[#a+1] = "MJ=" .. moab_jobid
	a[#a+1] = "TJ=" .. pbs_jobid
	a[#a+1] = "J=" .. jobid
	a[#a+1] = "M="  .. t.modFullName
	a[#a+1] = "FN=" .. t.fn
	local hierarchy = "na"
	local arch = "generic"
	local root = "na"
	local root_found = false
	local name = "-"
	local version = "-"
	for v in t.modFullName:split("/") do
		name = version
		version = v
	end
	local last = ""
	local second_last = ""
	local third_last = ""
	local fourth_last = ""
	local fifth_last = ""
	for v in t.fn:split("/") do
		if not root_found and string.match(v,'[a-zA-Z0-9]+') then
			root = v
			root_found = true
		end
		if v == "CUDA" then
			hierarchy = "CUDA"
		end
		if v == "MPI" then
			hierarchy = "MPI"
		end
		if v == "Compiler" then
			hierarchy = "Compiler"
		end
		if v == "Core" then
			hierarchy = "Core"
		end
		if v == "avx" or v == "avx2" or v == "sse3" then
			arch = v
		end
		fifth_last = fourth_last
		fourth_last = third_last
		third_last = second_last
		second_last = last
		last = v
	end
	local compiler = "na"
	local mpi = "na"
	local cuda = "na"
	if hierarchy == "Compiler" then
		compiler = third_last
	end
	if hierarchy == "MPI" then
		if string.find(fourth_last, 'cuda') then
			compiler = fifth_last
			cuda = fourth_last
			mpi = third_last
		else
			mpi = third_last
			compiler = fourth_last
		end
	end
	if hierarchy == "CUDA" then
		compiler = fourth_last
		cuda = third_last
	end
	a[#a+1] = "hierarchy=" .. hierarchy
	a[#a+1] = "arch=" .. arch
	a[#a+1] = "root=" .. root
	a[#a+1] = "MN=" .. name
	a[#a+1] = "MV=" .. version
	a[#a+1] = "cuda=" .. cuda
	a[#a+1] = "mpi=" .. mpi
	a[#a+1] = "compiler=" .. compiler
	a[#a+1] = "cluster=" .. clustername

	local s = concatTbl(a," ")  --> "M${module} FN${fn} U${user} H${hostname}"

	local cmd = "logger -t lmod-1.0 -p local0.info " .. s
	if (not success) then
		cmd = cmd .. " Error=\\'Failed_to_load_due_to_license_restriction.\\'"
	end
	os.execute(cmd)
end

local function validate_license(t)
	require "io"
	local non_commercial_autoaccept_message = [[
============================================================================================
The software listed above is available for non-commercial usage only. By continuing, you 
accept that you will not use the software for commercial purposes. 

Le logiciel listé ci-dessus est disponible pour usage non commercial seulement. En 
continuant, vous acceptez de ne pas l'utiliser pour un usage commercial.
============================================================================================
	]]
	local nvidia_autoaccept_message = [[
============================================================================================
The NVidia software listed above is subject to the terms of the NVidia Software
License Agreement, which can be obtained via http://developer.nvidia.com.
By continuing, you accept to be bound by the terms of that license.

Le logiciel NVidia listé ci-dessus est sous réserve des termes de la licence
NVidia Software License Agreement, qui peut être obtenue via http://developer.nvidia.com.
En continuant, vous acceptez les termes de cette licence.
============================================================================================
	]]
	local academic_license_message = [[
============================================================================================
Using this software requires you to accept a license on the software website. 
Did you accept such license ? (yes/no)

Utiliser ce logiciel nécessite que vous acceptiez une licence sur le site de l'auteur. 
L'avez-vous fait ? (oui/non)
============================================================================================
	]]
	local academic_license_message_autoaccept = [[
============================================================================================
Using this software requires you to accept a license on the software website. 
Please ensure that you register on the website below.

Utiliser ce logiciel nécessite que vous acceptiez une licence sur le site de l'auteur. 
Veuillez vous enregistrer sur le site web ci-dessous.
============================================================================================
	]]
	local posix_group_message = [[
============================================================================================
Using this software requires you to have access to a license. If you do, please write to
us at support@computecanada.ca so that we can enable access for you.

Utiliser ce logiciel nécessite que vous aillez accès à une licence. Si c'est le cas, 
veuillez nous écrire à support@calculcanada.ca pour que nous puissions l'activer.
============================================================================================
	]]
	local not_accepted_message = [[

============================================================================================
Please answer "yes" or "oui" to accept.
Veuillez répondre "yes" ou "oui" pour accepter. 
============================================================================================
	]]
	-- The names in these lists can be full name + version or just the name
	local licenseT = {
		[ { "intel", "signalp", "tmhmm", "rnammer" } ] = "noncommercial_autoaccept",
		[ { "cudnn" } ] = "nvidia_autoaccept",
		[ { "namd", "vmd", "rosetta", "gatk" } ] = "academic_license",
		[ { "namd", "namd-mpi", "namd-verbs", "namd-multicore", "namd-verbs-smp" } ] = "academic_license_autoaccept",
		[ { "cpmd", "dl_poly4", "gaussian", "orca", "vasp/4.6", "vasp/5.4.1" } ] = "posix_group",
	}
	local groupT = {
		[ "cpmd" ] = "soft_cpmd",
		[ "dl_poly4" ] = "soft_dl_poly4",
		[ "gaussian" ] = "soft_gaussian",
		[ "orca" ] = "soft_orca",
		[ "vasp/4.6" ] = "soft_vasp4",
		[ "vasp/5.4.1" ] = "soft_vasp5",
	}
	local posix_group_messageT = {
		[ { "cpmd" } ] = [[

============================================================================================
Using CPMD requires you to have access to a license. Please register on this site
 http://cpmd.org/download/cpmd-download-1/accept-license
Once this is done, write to us at support@computecanada.ca telling us so. Once we confirm
with CPMD that you indeed have registered, we will be able to grant you access to CPMD.

Utiliser CPMD nécessite que vous ayiez une licence. Vous devez vous enregistrer sur ce site :
 http://cpmd.org/download/cpmd-download-1/accept-license
Lorsque c'est fait, écrivez-nous à support@calculcanada.ca pour nous le dire. Lorsque
nous aurons confirmé votre enregistrement avec CPMD, nous pourrons vous donner accès au
logiciel.
============================================================================================
		]],
		[ { "dl_poly4" } ] = [[

============================================================================================
Using DL POLY4 requires you to have access to a license. Please register on this site
 http://www.scd.stfc.ac.uk/SCD/40526.aspx
Once this is done, send a copy of the confirmation message to us at support@computecanada.ca.
We will then be able to grant you access to DL POLY4.

Utiliser DL POLY4 nécessite que vous ayiez une licence. Vous devez vous enregistrer sur ce site :
 http://www.scd.stfc.ac.uk/SCD/40526.aspx
Lorsque c'est fait, envoyez-nous une copie du courriel de confirmation à
support@calculcanada.ca. Nous pourrons ensuite vous donner accès à DL POLY4.
============================================================================================
		]],
		[ { "gaussian" } ] = [[

============================================================================================
Using Gaussian requires you to agree to the following license terms:
 1) You are not a member of a research group developing software competitive to Gaussian.
 2) You will not copy the Gaussian software, nor make it available to anyone else.
 3) You will properly acknowledge Gaussian Inc. and Compute Canada in publications.
 4) You will notify us of any change in the above acknowledgement.

If you do, please send an email with a copy of those conditions, saying that you agree to
them at support@computecanada.ca. We will then be able to grant you access to Gaussian.

Utiliser Gaussian nécessites que vous acceptiez les conditions suivantes (en anglais) :
 1) You are not a member of a research group developing software competitive to Gaussian.
 2) You will not copy the Gaussian software, nor make it available to anyone else.
 3) You will properly acknowledge Gaussian Inc. and Compute Canada in publications.
 4) You will notify us of any change in the above acknowledgement.

Si vous acceptez, envoyez-nous un courriel avec une copie de ces conditions, mentionnant
que vous les acceptez, à support@calculcanada.ca. Nous pourrons ensuite activer votre
accès à Gaussian.
============================================================================================
		]],
		[ { "orca" } ] = [[

============================================================================================
Using ORCA requires you to have access to a license. Please register on this site
https://cec.mpg.de/orcadownload/
Once this is done, send a copy of the confirmation message to us at support@computecanada.ca.
We will then be able to grant you access to ORCA.

Utiliser ORCA nécessite que vous ayiez une licence. Vous devez vous enregistrer sur ce site :
https://cec.mpg.de/orcadownload/
Lorsque c'est fait, envoyez-nous une copie du courriel de confirmation à
support@calculcanada.ca. Nous pourrons ensuite vous donner accès à ORCA.
============================================================================================
		]],
	}
	local licenseURLT = {
		[ "namd" ] = "http://www.ks.uiuc.edu/Research/namd/license.html",
		[ "namd-mpi" ] = "http://www.ks.uiuc.edu/Research/namd/license.html",
		[ "namd-verbs" ] = "http://www.ks.uiuc.edu/Research/namd/license.html",
		[ "namd-verbs-smp" ] = "http://www.ks.uiuc.edu/Research/namd/license.html",
		[ "namd-multicore" ] = "http://www.ks.uiuc.edu/Research/namd/license.html",
		[ "vmd" ] = "http://www.ks.uiuc.edu/Research/vmd/current/LICENSE.html",
		[ "rosetta" ] = "https://els.comotion.uw.edu/licenses/86",
		[ "gatk" ] = "https://software.broadinstitute.org/gatk/download/licensing.php",
	}
	-- environment variable to define
	local auto_find_environment_variableT = {
--		[ "matlab" ] = "MLM_LICENSE_FILE",
	}
	-- message to display when a license is not found
	local auto_find_messageT = {
--		[ "matlab" ] = [[ test ]]
	}

	local fn = myFileName()
	-- skip tests for modules that are not on /cvmfs
	local user = getenv_logged("USER","unknown")
	if ((fn:find("^/cvmfs") == nil and fn:find("^/opt/software") == nil) or user == "ebuser") then
		return
	end
	for k,v in pairs(licenseT) do
     		------------------------------------------------------------
		-- Look for fullName first otherwise sn
		local name = ""
		if (has_value(k,myModuleFullName())) then
			name = myModuleFullName()
		elseif (has_value(k,myModuleName())) then
			name = myModuleName()
		end
		
     		if (has_value(k,name)) then
			if (v == "noncommercial_autoaccept") then
				if (not user_accepted_license(name,true)) then
					LmodMessage(myModuleFullName() .. ":")
					LmodMessage(non_commercial_autoaccept_message)
				end
			end
			if (v == "nvidia_autoaccept") then
				if (not user_accepted_license(name,true)) then
					LmodMessage(myModuleFullName() .. ":")
					LmodMessage(nvidia_autoaccept_message)
				end
			end
			if (v == "academic_license") then
				if (not user_accepted_license(name,false)) then
					LmodMessage(myModuleFullName() .. ":")
					LmodMessage(academic_license_message)
					LmodMessage(licenseURLT[name])
					if (not confirm_acceptance(name)) then
						log_module_load(t,false)
						LmodError(not_accepted_message)
					end
				end
			end
			if (v == "academic_license_autoaccept") then
				if (not user_accepted_license(name,true)) then
					LmodMessage(myModuleFullName() .. ":")
					LmodMessage(academic_license_message_autoaccept)
					LmodMessage(licenseURLT[name])
				end
			end
			if (v == "posix_group") then
				if (not localUserInGroup(groupT[name])) then
					log_module_load(t,false)
					local message_found = false
					for k2,v2 in pairs(posix_group_messageT) do
						if (has_value(k2,name)) then
							LmodError(v2)
							message_found = true
						end
					end
					if (not message_found) then
						LmodError(posix_group_message)
					end
				end
			end
			if (v == "auto_find_license") then
				if (not find_and_define_license_file(auto_find_environment_variableT[name],name)) then
					log_module_load(t,false)
					LmodError(auto_find_messageT[name])
				end
			end
		end
	end
end

local function set_props(t)
   ------------------------------------------------------------
   -- table of properties for fullnames or sn

   local propT = {
      [ { "armadillo", "arpack-ng", "cgal", "clhep", "cudnn", "dealii", "eigen", "fftw", "fftw-mpi", "fftw-serial", "glpk", "gsl", "igraph", "imkl", "jags", "libmesh", "libxsmm", "magma", "metis", "nlopt", "p4est", "parmetis", "python27-scipy-stack", "python35-scipy-stack", "qhull", "qrupdate", "scotch", "suitesparse", "superlu", "viennacl", "voro++" } ]       = { {name = "type_", value = "math" }, },
      [ { "abinit", "adf", "amber", "beast", "cp2k", "cpmd", "dl_poly4", "gamess-us", "gaussian", "gromacs", "gromacs-plumed", "lammps", "lammps-omp", "lammps-user-intel", "libint", "libxc", "namd", "namd-mpi", "namd-multicore", "namd-verbs", "namd-verbs-smp", "nwchem", "openbabel", "orca", "plumed", "quantumespresso", "rosetta", "siesta", "spglib", "vasp" } ]       = { {name = "type_", value = "chem" }, },
      [ { "mpi.net", "mvapich2", "openmpi" } ]       = { {name = "type_", value = "mpi" }, },
      [ { "abyss", "angsd", "annovar", "bamtools", "bamutil", "bbmap", "bcftools", "beagle-lib", "bedtools", "bioperl", "blast+", "blat", "bolt-lmm", "bowtie", "bowtie2", "bwa", "canu", "canvas", "cnvnator", "cufflinks", "diamond", "fastqc", "fastx-toolkit", "gatk", "gmap-gsnap", "hmmer", "htslib", "impute2", "interproscan", "jellyfish", "kraken", "libgtextutils", "lumpy", "mach", "megahit", "meraculous", "metaphlan", "minia", "minimac2", "minimac3", "mummer", "mummer-64bit", "mothur", "mrbayes", "nextgenmap", "pear", "picard", "pilon", "plink", "prinseq", "racon", "ray", "r-bundle-bioconductor", "repasthpc", "rnammer", "samtools", "shotmap", "signalp", "soapdenovo2", "sortmerna", "spades", "sspace-longread", "stacks", "subread", "sumaclust", "tabix", "tmhmm", "tophat", "transdecoder", "trimmomatic", "trinity", "trinotate", "vcftools", "vsearch" } ]       = { {name = "type_", value = "bio"}, },
      [ { "bazel", "boost", "boost-mpi", "chapel", "chapel-single", "chapel-slurm-gasnetrun_ibv", "cuda", "eclipse", "gcc", "intel", "ipp", "java", "julia", "matlab", "maven", "mcr", "mono", "octave", "perl", "perl4-corelibs", "petsc", "petsc-64bits", "protobuf", "python", "qt", "qt5", "r", "root", "rstudio-server", "ruby", "rubygems", "snappy", "spark", "tbb", "tcl", "trilinos", "udunits", "yaxt" } ]          = { {name = "type_", value = "tools"}, },
      [ { "grackle", "geant4", "ls-dyna", "ls-dyna-mpi", "openfoam", "shengbte" } ] = { {name = "type_", value = "phys"}, },
      [ { "ccsm", "cesm", "cdo", "esmf", "gdal", "g2clib", "g2lib", "geos", "proj", "wps", "wrf", "wrf-fire" } ] = { {name = "type_", value = "geo"}, },
      [ { "glm", "jasper", "ncl", "ncview", "opencv", "paraview", "paraview-offscreen", "paraview-offscreen-gpu", "vmd", "vtk", "xcrysden" } ] = { {name = "type_", value = "vis"}, },
      [ { "h4toh5", "hdf", "hdf5", "hdf5-mpi", "hdf5-serial", "matio", "nco", "netcdf", "netcdf-c++", "netcdf-c++4-mpi", "netcdf-c++-mpi", "netcdf-fortran", "netcdf-fortran-mpi", "netcdf-mpi", "netcdf-serial", "pnetcdf" } ] = { {name = "type_", value = "io"}, },
      [ { "theano", "torch" } ] = { { name = "type_", value = "ai" }, },
   }

   for k,v in pairs(propT) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(k,myModuleFullName()) or has_value(k,myModuleName())) then
        ----------------------------------------------------------
        -- Loop over value array and fill properties for this module.
        for i = 1,#v do
           local entry = v[i]
           add_property(entry.name, entry.value)
	   whatis("Keyword:" .. entry.value)
        end
     end
   end
end
local function load_hook(t)
	local valid = validate_license(t)
	set_props(t)
	set_wiki_url(t)
	set_family(t)
	log_module_load(t,true)
end
local function spider_hook(t)
	set_props(t)
	set_wiki_url(t)
end
hook.register("load",           load_hook)
hook.register("load_spider", 	spider_hook)

local mapT =
{
   grouped = {
      ['/cvmfs/.*/modules/.*/Core.*']     = "Core Modules",
      ['/cvmfs/.*/modules/.*/avx2/Compiler.*'] = "Compiler-dependent avx2 modules",
      ['/cvmfs/.*/modules/.*/avx2/MPI.*'] = "MPI-dependent avx2 modules",
      ['/cvmfs/.*/modules/.*/avx2/CUDA.*'] = "Cuda-dependent avx2 modules",
      ['/cvmfs/.*/modules/.*/avx/Compiler.*'] = "Compiler-dependent avx modules",
      ['/cvmfs/.*/modules/.*/avx/MPI.*'] = "MPI-dependent avx modules",
      ['/cvmfs/.*/modules/.*/avx/CUDA.*'] = "Cuda-dependent avx modules",
      ['/cvmfs/.*/modules/.*/sse3/Compiler.*'] = "Compiler-dependent sse3 modules",
      ['/cvmfs/.*/modules/.*/sse3/MPI.*'] = "MPI-dependent sse3 modules",
      ['/cvmfs/.*/modules/.*/sse3/CUDA.*'] = "Cuda-dependent sse3 modules",
      ['/cvmfs/.*/custom/modules.*'] = "Core modules",
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


