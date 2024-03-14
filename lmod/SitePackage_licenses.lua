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

function find_and_define_license_file(environment_variable,application)
	require "lfs"
	require "os"
	local mode_s = mode() or nil
	-- unless 
	if (not (mode_s == 'load' or mode_s == 'unload' or mode_s == 'show' or mode_s == 'dependencyCk')) then
		return false
	end
	-- skip the test in these cases
	local fn = myFileName()
	local user = getenv_logged("USER","unknown")
	if ((fn:find("^/cvmfs") == nil and fn:find("^/opt/software") == nil) or user == "ebuser") then
		return true
	end
	local posix = require "posix"
	local license_found = false
	local license_path = ""

	-- if there is already an existing value for the environment variable, never fail
	local existing_value = os.getenv(environment_variable) or nil
	if (existing_value == nil or existing_value == '') then
		license_found = false
	else 
		license_found = true
	end

	-- First, look at the public repository for a file called by the cluster's name
	local cluster = os.getenv("CC_CLUSTER") or nil
	local dir = pathJoin("/cvmfs/soft.computecanada.ca/config/licenses/",application)
	if (posix.stat(dir,"type") == 'directory') then
		local path = pathJoin(dir,cluster .. ".lic")
		if (posix.stat(path,"type") == 'regular') then
			license_path = path
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
					local typef = posix.stat(file,"type") or "nil"
					if (typef == 'regular' or typef == 'link' or typef == 'directory') then
						-- We can open that file, lets use it as license file
						license_path = file
						prepend_path(environment_variable,file)
						license_found = true
					end
				elseif (posix.stat(path,"type") == 'regular') then
					-- We can open that file, lets use it as license file
					license_path = path
					prepend_path(environment_variable,path)
					license_found = true
				end
			end
		end
	end

	-- Third, look at the site-specific repository for
	-- $RSNT_LOCAL_LICENSE_PATH/<application>.lic
	local dir = os.getenv("RSNT_LOCAL_LICENSE_PATH")
	if (dir ~= nil) then
		if (posix.stat(dir, "type") == "directory") then
			local path = pathJoin(dir, application .. ".lic")
			local typef = posix.stat(path, "type") or "nil"
			if (typef == "regular" or typef == "link") then
				license_path = path
				prepend_path(environment_variable, path)
				license_found = true
			end
		end
	end
	
	-- Fourth, look at the public repository for a file called by the cluster's name with priority
	local dir = pathJoin("/cvmfs/soft.computecanada.ca/config/licenses/",application)
	if (posix.stat(dir,"type") == 'directory') then
		local path = pathJoin(dir,cluster .. ".priority.lic")
		local typef = posix.stat(path,"type") or "nil"
		if (typef == 'regular' or typef == 'link') then
			license_path = path
			prepend_path(environment_variable,path)
			license_found = true
		end
	end
	
	-- Fifth, look at the restricted repository for a file called by the cluster's name with priority
	local dir = pathJoin("/cvmfs/restricted.computecanada.ca/config/licenses/",application,"clusters")
	if (posix.stat(dir,"type") == 'directory') then
		local path = pathJoin(dir,cluster .. ".priority.lic")
		local typef = posix.stat(path,"type") or "nil"
		if (typef == 'regular' or typef == 'link') then
			license_path = path
			prepend_path(environment_variable,path)
			license_found = true
		end
	end

	-- Sixth, look at the user's home for a $HOME/.licenses/<application>.lic
	local home = getenv_logged("HOME",pathJoin("/home",user))
	local license_file = pathJoin(home,".licenses",application .. ".lic")
	if (posix.stat(license_file,"type") == 'regular') then
		license_path = license_file
		prepend_path(environment_variable,license_file)
		license_found = true
	end

	-- Finally, if restricted is not available don't set any license info automically
	-- for intel or pgi. For those the license is irrelevant if the restricted repo
	-- isn't available but they are still loaded to expand MODULEPATH.
	local restricted = os.getenv("CC_RESTRICTED") or nil
	if (not license_found and restricted ~= 'true' and (application == 'intel' or application == 'pgi')) then
		license_found = true
	end

	return license_found, license_path
end

function validate_license(t)
	require "io"
	local academic_autoaccept_message = [[
============================================================================================
The software listed above is available for academic usage only. By continuing, you 
accept that you will not use the software for commercial or non-academic purposes. 

Le logiciel listé ci-dessus est disponible pour usage académique seulement. En 
continuant, vous acceptez de ne pas l'utiliser pour un usage commercial ou non académique.
============================================================================================
	]]
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
Please confirm that you registered on the website below (yes/no).

Utiliser ce logiciel nécessite que vous acceptiez une licence sur le site de l'auteur. 
Veuillez confirmer que vous vous êtes enregistrés sur le site web ci-dessous (oui/non).
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
us at support@tech.alliancecan.ca so that we can enable access for you.

Utiliser ce logiciel nécessite que vous aillez accès à une licence. Si c'est le cas, 
veuillez nous écrire à support@tech.alliancecan.ca pour que nous puissions l'activer.
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
		[ { "matlab" } ] = "academic_autoaccept",
		[ { "fsl" } ] = "academic_autoaccept",
		[ { "intel/2014.6", "intel/2016.4", "intel/2017.1", "intel/2017.5", "intel/2018.3", "intel/2019.3", "intel/2020.1.217" } ] = "noncommercial_autoaccept",
		[ { "signalp", "tmhmm", "rnammer", "amber/22.5-23.5" } ] = "noncommercial_autoaccept",
		[ { "cudnn" } ] = "nvidia_autoaccept",
		[ { "namd", "vmd", "rosetta", "gatk", "gatk-queue", "motioncor2", "pwrf"} ] = "academic_license",
		[ { "namd", "namd-mpi", "namd-verbs", "namd-multicore", "namd-verbs-smp" } ] = "academic_license_autoaccept",
		[ { "cfour", "cpmd", "dl_poly4", "gaussian", "maker", "orca", "vasp/4.6", "vasp/5.4.1", "sas", "imagenet", "voxceleb" } ] = "posix_group",
	}
	local groupT = {
		[ "cfour" ] = "soft_cfour",
		[ "cpmd" ] = "soft_cpmd",
		[ "dl_poly4" ] = "soft_dl_poly4",
		[ "gaussian" ] = "soft_gaussian",
		[ "maker" ] = "soft_maker",
		[ "orca" ] = "soft_orca",
		[ "vasp/4.6" ] = "soft_vasp4",
		[ "vasp/5.4.1" ] = "soft_vasp5",
		[ "sas" ] = "soft_sas",
		[ "imagenet" ] = "imagenet-optin",
		[ "voxceleb"] = "voxceleb-optin",
	}
	local posix_group_messageT = {
		[ { "maker" } ] = [[

============================================================================================
Using maker requires you to register with them. Please register on this site
 http://yandell.topaz.genetics.utah.edu/cgi-bin/maker_license.cgi
Once this is done, write to us at support@tech.alliancecan.ca showing us that you've registered. 
Then we will be able to grant you access to maker.

Utiliser maker nécessite que vous ayiez une licence. Vous devez vous enregistrer sur ce site :
 http://yandell.topaz.genetics.utah.edu/cgi-bin/maker_license.cgi
Lorsque c'est fait, écrivez-nous à support@tech.alliancecan.ca pour nous le dire. Nous pourrons
ensuite vous donner accès à maker.
============================================================================================
		]],
                [ { "cfour-mpi" } ] = [[

============================================================================================
Using CFOUR requires you to agree to the following license terms:

1) I will use CFOUR only for academic research.
2) I will not copy the CFOUR software, nor make it available to anyone else.
3) I will properly acknowledge original papers of CFOUR and the Alliance in my 
   publications (see the license form for more details).
4) I understand that the agreement for using CFOUR can be terminated by one of the 
   parties: CFOUR developers or the Alliance.
5) I will notify the Alliance of any change in the above acknowledgement.

If you do, please send an email with a copy of those conditions, saying that you agree to
them at support@tech.alliancecan.ca. We will then be able to grant you access to CFOUR.

Utiliser CFOUR nécessites que vous acceptiez les conditions suivantes (en anglais) :

1) I will use CFOUR only for academic research.
2) I will not copy the CFOUR software, nor make it available to anyone else.
3) I will properly acknowledge original papers of CFOUR and the Alliance in my 
   publications (see the license form for more details).
4) I understand that the agreement for using CFOUR can be terminated by one of the 
   parties: CFOUR developers or the Alliance.
5) I will notify the Alliance of any change in the above acknowledgement.

Si vous acceptez, envoyez-nous un courriel avec une copie de ces conditions, mentionnant
que vous les acceptez, à support@tech.alliancecan.ca. Nous pourrons ensuite activer votre
accès à CFOUR.
============================================================================================
                ]],
		[ { "cpmd" } ] = [[

============================================================================================
Using CPMD requires being added to the POSIX group "soft_cpmd":
https://docs.alliancecan.ca/wiki/CPMD/en#License_limitations
Please write to us at "support@tech.alliancecan.ca" asking to
be added to the POSIX group and we will grant you access to CPMD.

Utiliser CPMD nécessite d'être membre du group "soft_cpmd":
https://docs.alliancecan.ca/wiki/CPMD/fr#Limites_de_la_licence
Ecrivez-nous à support@tech.alliancecan.ca pour demander d'être
membre de ce groupe et nous pourrons vous donner accès au
logiciel CPMD.
============================================================================================
		]],
		[ { "dl_poly4" } ] = [[

============================================================================================
Using DL_POLY4 requires being added to the POSIX group "soft_dl_poly4":
https://docs.alliancecan.ca/wiki/DL_POLY#License_limitations 
Please write to us at "support@tech.alliancecan.ca" asking to
be added to the POSIX group and we will grant you access to DL_POLY4

Utiliser DL POLY4 nécessite d'être membre du group "soft_dl_poly4":
https://docs.alliancecan.ca/wiki/DL_POLY/fr#Licence
Ecrivez-nous à support@tech.alliancecan.ca pour demander d'être
membre de ce groupe et nous pourrons vous donner accès au
logiciel DL_POLY4.
============================================================================================
		]],
		[ { "gaussian" } ] = [[

============================================================================================
Using Gaussian requires you to agree to the following license terms:
 1) I am not a member of a research group developing software competitive to Gaussian.
 2) I will not copy the Gaussian software, nor make it available to anyone else.
 3) I will properly acknowledge Gaussian Inc. and the Alliance in publications.
 4) I will notify the Alliance of any change in the above acknowledgement.

If you do, please send an email with a copy of those conditions, saying that you agree to
them at support@tech.alliancecan.ca. We will then be able to grant you access to Gaussian.

Utiliser Gaussian nécessites que vous acceptiez les conditions suivantes (en anglais) :
 1) I am not a member of a research group developing software competitive to Gaussian.
 2) I will not copy the Gaussian software, nor make it available to anyone else.
 3) I will properly acknowledge Gaussian Inc. and the Alliance in publications.
 4) I will notify the Alliance of any change in the above acknowledgement.

Si vous acceptez, envoyez-nous un courriel avec une copie de ces conditions, mentionnant
que vous les acceptez, à support@tech.alliancecan.ca. Nous pourrons ensuite activer votre
accès à Gaussian.
============================================================================================
		]],
		[ { "orca" } ] = [[

============================================================================================
Using ORCA requires you to have access to a license. Please register on this site
https://orcaforum.kofo.mpg.de/
Once this is done, send a copy of the confirmation message to us at support@tech.alliancecan.ca.
We will then be able to grant you access to ORCA.

Utiliser ORCA nécessite que vous ayiez une licence. Vous devez vous enregistrer sur ce site :
https://orcaforum.kofo.mpg.de/
Lorsque c'est fait, envoyez-nous une copie du courriel de confirmation à
support@tech.alliancecan.ca. Nous pourrons ensuite vous donner accès à ORCA.
============================================================================================
		]],
		[ { "sas" } ] = [[

============================================================================================
This software is only licensed for Alberta School of Business users.
If you are in the Alberta School of Buisness and covered by the SAS license agreement
please send an email to support@tech.alliancecan.ca with following subject line:
Please add me to soft_sas group
The email should include your userid and a statment that you are in the
the Alberta School of Buisness and thefore the current SAS license covers you.
============================================================================================
		]],
		[ { "imagenet" } ] = [[

============================================================================================
Using IMAGENET requires you to have agreed to Imagenet's license and have registered with the 
owner of the data. Please see https://docs.alliancecan.ca/wiki/ImageNet

L'utilisation d'IMAGENET nécessite que vous acceptiez la licence d'Imagenet et que vous vous 
soyez enregistré auprès du propriétaire des données.
Veuillez consulter https://docs.alliancecan.ca/wiki/ImageNet
============================================================================================
		]],
		[ { "voxceleb" } ] = [[

============================================================================================
Using VoxCeleb requires you to have agreed to VoxCeleb's license and have registered with 
the owner of the data. Please see https://docs.alliancecan.ca/wiki/VoxCeleb
		
L'utilisation de VoxCeleb nécessite que vous ayez accepté la licence de VoxCeleb et que vous
vous soyez enregistré auprès du propriétaire des données. 
Veuillez consulter https://docs.alliancecan.ca/wiki/VoxCeleb
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
		[ "motioncor2" ] = "http://tiny.cc/UCSFMotionCor2",
		[ "gatk" ] = "https://software.broadinstitute.org/gatk/download/licensing.php",
		[ "gatk-queue" ] = "https://software.broadinstitute.org/gatk/download/licensing.php",
		[ "pwrf" ] = "http://polarmet.osu.edu/PWRF/registration.php",
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
		return true, nil
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
			if (v == "academic_autoaccept") then
				if (not user_accepted_license(name,true)) then
					LmodMessage(myModuleFullName() .. ":")
					LmodMessage(academic_autoaccept_message)
				end
			end
			if (v == "noncommercial_autoaccept") then
				if (not user_accepted_license(myModuleName(),true)) then
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
sandbox_registration{ find_and_define_license_file = find_and_define_license_file }

