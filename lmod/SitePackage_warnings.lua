function intel_old_stack_warning(t)
	local moduleName = myModuleName()
	-- only go further for intel
	if (moduleName ~= "intel") then return end
	local vendor_cpu_id = os.getenv("RSNT_CPU_VENDOR_ID") or get_cpu_vendor_id()
	if vendor_cpu_id == "amd" then
		local myFileName = myFileName()
		if string.match(myFileName, "/cvmfs/soft.computecanada.ca/easybuild/modules/2017/Core") then
	   		local lang = os.getenv("LANG") or "en"
			if (string.sub(lang,1,2) == "fr") then
				LmodWarning([[Vous tentez de charger le module d'un compilateur intel sur un ordinateur doté de processeurs AMD. 
Les logiciels compilés à l'aide des compilateurs Intel dans les environnements standard StdEnv/2016.4 et StdEnv/2018.3 ne sont pas
compatibles avec les processeurs AMD. Veuillez plutôt charger l'environnement StdEnv/2020 et un compilateur plus récent.
]])
			else
				LmodWarning([[You are attempting to load the intel compiler on a computer equiped with AMD processors. 
Software compiled with the Intel compiler in the standard environments StdEnv/2016.4 and StdEnv/2018.3 are not compatible
with AMD processors. Please instead use the StdEnv/2020 standard environment and a more recent compiler. 
]])
			end
		end
	end
end
function default_module_change_warning(t)
	local moduleName = myModuleName()

	-- only go further for StdEnv
	if (moduleName ~= "StdEnv" and moduleName ~= "python") then return end
	-- allow to completely disable the upcoming transition
	local enableStdEnv2020Transition = os.getenv("RSNT_ENABLE_STDENV2020_TRANSITION") or "unknown"
	if (enableStdEnv2020Transition == "unknown") then
		-- Niagara sets the variable locally
   		local cccluster = os.getenv("CC_CLUSTER") or "computecanada"
		if (cccluster == "cedar" or cccluster == "graham" or cccluster == "beluga") then
			enableStdEnv2020Transition = "yes"
		else
			enableStdEnv2020Transition = "no"
		end
	end
	if (enableStdEnv2020Transition == "no") then return end

	local FrameStk   = require("FrameStk")
	local frameStk   = FrameStk:singleton()
	local userProvidedName = frameStk:userName()
	local moduleFullName = t.modFullName
	-- do not go further if the user provided the name with the version
	if (userProvidedName == moduleFullName) then return end

	local moduleVersion = myModuleVersion()
	local defaultKind
	if convertToCanonical(LmodVersion()) >= convertToCanonical("8.4.20") then
		defaultKind = t.mname:defaultKind()
	else
		defaultKind = "unknown"   -- before 8.4.20, we can not detect if the default comes from the user, so we display the warning regardless
	end
		
   	local lang = os.getenv("LANG") or "en"

	-- only show the warning if the user provided "StdEnv" as load, if the defaultKind is system, and if it does not result in 2020
	if (userProvidedName == "StdEnv" and moduleVersion ~= "2020" and (defaultKind == "system" or defaultKind == "unknown")) then
		--color_banner("red")
		if (string.sub(lang,1,2) == "fr") then
			LmodWarning([[Attention, le 1er avril 2021, la version par défaut de l'environnement standard sera mise à jour.
Pour tester vos tâches avec le nouvel environnement, exécutez la commande :
module load StdEnv/2020

Pour changer votre version par défaut immédiatement, exécutez la commande suivante : 

echo "module-version StdEnv/2020 default" >> $HOME/.modulerc

Pour davantage d'information, visitez :
https://docs.computecanada.ca/wiki/Standard_software_environments/fr]])
		else
			LmodWarning([[Warning, April 1st 2021, the default standard environment module will be changed to a more recent one.
To test your jobs with the new environment, please run:
module load StdEnv/2020

To change your default version immediately, please run the following command:

echo "module-version StdEnv/2020 default" >> $HOME/.modulerc

For more information, please see:
https://docs.computecanada.ca/wiki/Standard_software_environments]])
		end
		--color_banner("red")
	end
	
	-- only show the warning if the user provided a shortened version of python as load, if the defaultKind is system or marked, and if it does not result in 3.10.2
	if (userProvidedName == "python" or userProvidedName == "python/3" or userProvidedName == "python/3.") then
		if (moduleVersion ~= "3.10.2" and (defaultKind == "system" or defaultKind == "unknown" or defaultKind == "marked")) then
			if (string.sub(lang,1,2) == "fr") then
				LmodWarning([[Attention, le 4 avril 2023, la version par défaut de python deviendra 3.10. 
Pour continuer d'utiliser la version 3.8, veuillez charger le module python/3.8 explicitement.
]])
			else
				LmodWarning([[Warning. On April 4th 2023, the default version of python will become 3.10. 
To keep using python 3.8, please load the python/3.8 module explicitly. 
]])
			end
		end
		--color_banner("red")
	end
end

function incomplete_version_warning(t)
   local min_digits = {
      [ { "python", "arrow" } ]       = 2,
      [ { "scipy-stack", "StdEnv" } ] = 1,
   }

   for modules,min_digit in pairs(min_digits) do
     ------------------------------------------------------------
     -- Look for fullName first otherwise sn
     if (has_value(modules,myModuleFullName()) or has_value(modules,myModuleName())) then
        ----------------------------------------------------------
	local FrameStk   = require("FrameStk")
	local frameStk   = FrameStk:singleton()
	local userProvidedName = frameStk:userName()
	local userProvidedVersion = string.match(userProvidedName, "/(.*)") or ""
	local num_digit = 0
	if userProvidedVersion == "" then
		num_digit = 0
	else
		local _, num_dot = string.gsub(userProvidedVersion, "%.", "")
		num_digit = num_dot+1
	end
	if (num_digit < min_digit) then
   		local lang = os.getenv("LANG") or "en"
		if (string.sub(lang,1,2) == "fr") then
			LmodWarning([[Attention, vous avez chargé le module ]] .. myModuleName() .. [[ en spécifiant une version incomplète: "]] .. userProvidedVersion .. [[".
Nous vous recommandons fortement de spécifier au moins ]] .. min_digit .. [[ chiffres pour la version de ce module. Dans le cas contraire, une future mise à jour
de ce module pourrait faire échouer vos tâches.]])
		else
			LmodWarning([[Warning, you have loaded the module ]] .. myModuleName() .. [[ by specifying an incomplete version: "]] .. userProvidedVersion .. [[".
We strongly recommend that you specify at least ]] .. min_digit .. [[ digits for the version of this module. Not doing this could crash your jobs when we install a newer version in the future.]])
		end
	end
     end
   end
end

