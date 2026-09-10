local _args = ...
if type(_args) ~= "table" then _args = {} end

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file) writefile(file, '') end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/uranium-client/uranium/'..readfile('uranium/profiles/commit.txt')..'/'..select(1, path:gsub('uranium/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('%.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'uranium', 'uranium/games', 'uranium/profiles', 'uranium/assets', 'uranium/libraries', 'uranium/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not isfile('uranium/profiles/commit.txt') then
	writefile('uranium/profiles/commit.txt', 'main')
end

local function downloadPremadeProfiles(commit)
	local httpService = game:GetService('HttpService')
	if isfolder('uranium/profiles/premade') then
		for _, file in listfiles('uranium/profiles/premade') do
			pcall(function() if isfile(file) then delfile(file) end end)
		end
	else
		makefolder('uranium/profiles/premade')
	end
	local success, response = pcall(function()
		return game:HttpGet('https://api.github.com/repos/uranium-client/uranium/contents/profiles/premade?ref=' .. commit)
	end)
	if success and response then
		local ok, files = pcall(function() return httpService:JSONDecode(response) end)
		if ok and type(files) == 'table' then
			for _, file in pairs(files) do
				if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
					local baseName = (file.name:match('^(.-)%.txt$') or file.name):gsub('%d+$', '')
					local fileId = (game.GameId == 2619619496) and game.GameId or game.PlaceId
					local filePath = 'uranium/profiles/premade/' .. baseName .. tostring(fileId) .. '.txt'
					local ds, dc = pcall(function() return game:HttpGet(file.download_url, true) end)
					if ds and dc and dc ~= '404: Not Found' then writefile(filePath, dc) end
				end
			end
		end
	end
end

if not shared.VapeDeveloper then
	local commit = isfile('uranium/profiles/commit.txt') and readfile('uranium/profiles/commit.txt') or ''
	local latest = isfile('uranium/profiles/latest.txt') and readfile('uranium/profiles/latest.txt') or ''
	if #commit ~= 40 then
		local ok, res = pcall(function()
			return game:HttpGet('https://api.github.com/repos/uranium-client/uranium/commits/main', true)
		end)
		if ok and res then
			local h = res:match('"sha":"([a-f0-9]+)"')
			if h and #h == 40 then commit = h end
		end
		if #commit ~= 40 then commit = 'main' end
		latest = commit
		pcall(writefile, 'uranium/profiles/latest.txt', latest)
	elseif #latest == 40 and latest ~= commit then
		commit = latest
	end
	task.spawn(function()
		local ok, res = pcall(function()
			return game:HttpGet('https://api.github.com/repos/uranium-client/uranium/commits/main', true)
		end)
		if ok and res then
			local h = res:match('"sha":"([a-f0-9]+)"')
			if h and #h == 40 then
				pcall(writefile, 'uranium/profiles/latest.txt', h)
			end
		end
	end)
	if commit ~= 'main' and (isfile('uranium/profiles/commit.txt') and readfile('uranium/profiles/commit.txt') or '') ~= commit then
		wipeFolder('uranium')
		wipeFolder('uranium/games')
		wipeFolder('uranium/guis')
		pcall(function() if isfile('uranium/guis/new.lua') then delfile('uranium/guis/new.lua') end end)
		wipeFolder('uranium/libraries')
		if isfolder('uranium/profiles/premade') then
			for _, file in listfiles('uranium/profiles/premade') do
				pcall(function() if isfile(file) then delfile(file) end end)
			end
		end
	end
	local oldCommit = isfile('uranium/profiles/commit.txt') and readfile('uranium/profiles/commit.txt') or ''
	writefile('uranium/profiles/commit.txt', commit)
	local needPremade = (oldCommit ~= commit)
	if not needPremade then
		needPremade = true
		if isfolder('uranium/profiles/premade') then
			for _ in listfiles('uranium/profiles/premade') do
				needPremade = false
				break
			end
		end
	end
	if needPremade then
		pcall(downloadPremadeProfiles, commit)
	end
end

return loadstring(downloadFile('uranium/main.lua'), 'main')({
	Closet = _args.Closet,
})
