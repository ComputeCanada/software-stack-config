local posix = require "posix"
local io = require "io"
local bindmounts = ""
for i, dir in ipairs({"/project", "/scratch", "/localscratch"}) do
   dirtype = posix.stat(dir, "type")
   if dirtype == 'link' or dirtype == 'directory' then
      local root = dir
      if dirtype == 'link' then
         -- Niagara, symlink
         root = posix.readlink(dir)
      else
         for line in io.lines("/proc/self/mountinfo") do
            match = line:match(" " .. dir .. " " .. dir .. " %S+ %S+ %S+ %S+ [^/]+(%S+) ")
            if match ~= nil then
               -- Beluga/Narval
               root = match .. dir
            end
         end
      end
      if bindmounts ~= "" then
         bindmounts = bindmounts .. ","
      end
      if root == dir then
         bindmounts = bindmounts .. dir
      else
         bindmounts = bindmounts .. root .. "," .. root .. ":" .. dir
      end
   end
end

apptainerbind = os.getenv("APPTAINER_BIND") or ""
if bindmounts ~= "" and apptainerbind == "" then
   setenv("APPTAINER_BIND", bindmounts)
end
