local getenv    = os.getenv
local concatTbl = table.concat
function getenv_logged(var,default)
	local val = getenv(var)
	if var == "USER" and (not val or val == "") then
		val = getenv("SLURM_JOB_USER")
	end
	if not val then
		val = default
		local user = getenv("USER") or getenv("SLURM_JOB_USER") or "unknown"
		if user == "" then
			user = getenv("SLURM_JOB_USER") or "unknown"
		end
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

function log_module_load(t,success)
	-- t is a table containing:
	-- t.modFullName:   Full name of the Module,
	-- t.fn:            the path of the modulefile.

	local FrameStk   = require("FrameStk")
	local frameStk   = FrameStk:singleton()
	local module_user_name   = frameStk:userName()

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
	if string.match(t.modFullName,'.*/.*') then
		for v in t.modFullName:split("/") do
			name = version
			version = v
		end
	else
		name = t.modFullName
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
		if v == "avx" or v == "avx2" or v == "sse3" or v == "avx512" then
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
	a[#a+1] = "MUN=" .. module_user_name

	local s = concatTbl(a," ")  --> "M${module} FN${fn} U${user} H${hostname}"

	local cmd = "logger -t lmod-1.0 -p local0.info " .. s
	if (not success) then
		cmd = cmd .. " Error=\\'Failed_to_load_due_to_license_restriction.\\'"
	end
	os.execute(cmd)
end

sandbox_registration{ getenv_logged = getenv_logged  }

