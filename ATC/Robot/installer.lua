local component = require("component");
local fs = require("filesystem")

--Download file from the internet
function getFileFromUrl(url, path)
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
--Appropriate request to the Web server instead of the default Internet API, throwing stderr, when he wants
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
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/etc/atc.cfg","/etc/atc.cfg")
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/config.lua","/usr/lib/config.lua")
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/atc.lua","/usr/lib/atc.lua")
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/wp.lua","/usr/lib/wp.lua")
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/lib/json.min.lua","/usr/lib/json.lua")
getFileFromUrl(baseUri .. "OpenComputers-Collection/master/ATC/Robot/listener.lua","/home/listener.lua")

