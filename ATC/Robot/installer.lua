local component = require("component");
local computer = require("computer");
local fs = require("filesystem")

function getFileFromUrl(url, path, overwrite)
  local continue = true
  if fs.exists(path) then
    if overwrite == true then
      continue = true
    else
      continue = false
    end
  end
  if continue == true then
    local success, response = internetRequest(url)
    if success then
      fs.makeDirectory(fs.path(path) or "")
      local file = io.open(path, "w")
      file:write(response)
      file:close()
    else
      print("Could not connect to to URL address \"" .. url .. "\"")
      return
    end
  end
end

function internetRequest(url)
	local success, response = pcall(component.internet.request, url)
	if success then
		local responseData = ""
		while true do
			local data, responseChunk = response.read()	
			if data then
				responseData = responseData .. data
			else
				if responseChunk then
					return false, responseChunk
				else
					return true, responseData
				end
			end
		end
	else
		return false, reason
	end
end

local baseUri = "https://raw.githubusercontent.com/L00Cyph3r/"
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/etc/atc.cfg","/etc/atc.cfg", false)
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/config.lua","/usr/lib/config.lua", true)
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/atc.lua","/usr/lib/atc.lua", true)
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/wp.lua","/usr/lib/wp.lua", true)
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/json.min.lua","/usr/lib/json.lua", true)
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/autorun.lua","/autorun.lua", true)
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/listener.lua","/listener.lua", true)
computer.shutdown(true)