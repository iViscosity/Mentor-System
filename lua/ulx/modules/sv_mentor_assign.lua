--[[
	Mentors

	A custom script written for my server that allows Helpers to be assigned to Senior Admins.
	Any command they use and chat they send will be logged and can be reviewed at any time.
]]--
util.AddNetworkString("Mentor_AddMentor")
util.AddNetworkString("Mentor_SendLogs")
util.AddNetworkString("Mentor_RequestLogs")

if not file.Exists("mentors", "DATA") then
	file.CreateDir("mentors")
end

local meta = FindMetaTable("Player")
if not meta then
	error("Failed to find Player metatable!")
end

-- Assigns a mentor to a mentee
local function AddMentor(mentor, mentee)
	net.Start("Mentor_AddMentor")
		net.WriteEntity(mentee)
	net.Send(mentor)

	mentee:SetPData("mentor", mentor:SteamID64())

	if not file.Exists("mentors/" .. mentor:SteamID64(), "DATA") then
		file.CreateDir("mentors/" .. mentor:SteamID64())
	end

	local menteeData = "mentors/" .. mentor:SteamID64() .. "/" .. mentee:SteamID64()
	file.CreateDir(menteeData)
	file.Write(menteeData .. "/commands.txt", "")
	file.Write(menteeData .. "/chat.txt", "")
end

local function SendPlayerLogs(len, ply)
	local mentorID = ply:SteamID64()
	if not ply:CheckGroup("senioradmin") or 
		not file.Exists("mentors/" .. mentorID, "DATA") then return end -- don't send logs if they are not a mentor

	local path = "mentors/" .. mentorID
	local _, mentees = file.Find(path, "DATA") -- find this mentor's mentees
	local n = #mentees

	local logs = {}

	for _, sid in pairs(mentees) do -- for each mentee, grab their logs
		local folder = path .. "/" .. sid .. "/"
		local commands = file.Read(folder .. "commands.txt")
		local chat = file.Read(folder .. "chat.txt")

		logs[sid] = {
			commands = commands, 
			chat = chat
		}
	end
	--PrintTable(logs)

	net.Start("Mentor_SendLogs")
		net.WriteUInt(n, 2) -- tell the client how many mentees they have
		for sid, data in pairs(logs) do -- for each set of logs, send to client
			net.WriteString(sid)
			net.WriteString(logs[sid].commands)
			net.WriteString(logs[sid].chat)
			--print(sid)
		end
	net.Send(ply)
end
net.Receive("Mentor_RequestLogs", SendPlayerLogs)

--[[
	Sets a player's Mentor
]]--
function meta:AssignSenior(senior)
	AddMentor(senior, self)
	self:SetUserGroup("helper")

	ULib.tsayColor(self, 
		"Congratulations, " .. self:Name() .. "! You have been promoted to '", 
		Color(50, 205, 50), "Helper'", 
		Color(255, 255, 255), "! Your mentor is: ",
		Color(255, 255, 0), senior:Name(),
		Color(255, 255, 255), ". They are able to view all of your command logs and are available if you have any questions.")

	ULib.tsayColor(senior,
		"Attention: " .. self:Name() .. " has been assigned to you. Use !mentor to view the list of " ..
		"Helpers assigned to you.")
end

function meta:HasMentor()
	return self:GetPData("mentor", false)
end