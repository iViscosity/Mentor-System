--[[
	Mentors

	A custom script written for my server that allows Helpers to be assigned to Senior Admins.
	Any command they use and chat they send will be logged and can be reviewed at any time.
]]--
util.AddNetworkString("Mentor_AddMentor")
util.AddNetworkString("Mentor_SendLogs")
util.AddNetworkString("Mentor_RequestLogs")

if not file.Exists("mentors") then
	file.CreateDir("mentors")
end

local meta = FindMetaTable("Player")
if not meta then
	error("Failed to find Player metatable!")
end

local function SendPlayerLogs(len, ply)
	local mentorID = ply:SteamID64()
	if not ply:CheckGroup("senioradmin") or 
		not file.Exists("mentors/" .. mentorID) then return end -- don't send logs if they are not a mentor

	local path = "mentors/" .. mentorID
	local _, mentees = file.Find(path) -- find this mentor's mentees
	local n = #mentees

	local logs = {}

	for _, sid in pairs(mentees) do -- for each mentee, grab their logs
		local folder = path .. "/" .. sid .. "/"
		local commands = file.Read(sid .. "commands.txt")
		local chat = file.Read(sid .. "chat.txt")

		logs[sid] = {
			commands = commands, 
			chat = chat
		}
	end

	net.Start("Mentor_SendLogs")
		net.WriteUInt(n, 2) -- tell the client how many mentees they have

		for sid, data in ipairs(logs) do -- for each set of logs, send to client
			net.WriteString(sid)
			net.WriteString(util.Compress(logs[sid].commands)) -- compress because it's a large amount of data
			net.WriteString(util.Compress(logs[sid].chat))
		end
	net.Send(ply)
end
net.Receive("Mentor_RequestLogs", SendPlayerLogs)

--[[
	Sets a player's Mentor
]]--
function meta:AssignSenior(senior)
	self:SetUserGroup("helper")
	
	AddMentor(senior, self)
	ULib.tsayColor(self, 
		"Congratulations, " .. self:Name() .. "! You have been promoted to '", 
		Color(50, 205, 50), "Helper'", 
		Color(255, 255, 255), "! Your mentor is: ",
		Color(255, 255, 0), assigner:Name(),
		Color(255, 255, 255), ". They are able to view all of your command logs and are available if you have any questions.")

	ULib.tsayColor(senior,
		"Attention: " .. self:Name() .. " has been assigned to you. Use !mentor to view the list of " ..
		"Helpers assigned to you.")
end

function meta:HasMentor()
	return self:GetPData("mentor", false)
end

-- Assigns a mentor to a mentee
local function AddMentor(mentor, mentee)
	net.Start("AddMentor")
		net.WriteEntity(mentee)
	net.Send(mentor)

	mentee:SetPData("mentor", mentor:SteamID64())

	local menteeData = "mentors/" .. mentor:SteamID64() .. "/" .. mentee:SteamID64()
	file.CreateDir(menteeData)
	file.Write(menteeData .. "/commands.txt", "")
	file.Write(menteeData .. "/chat.txt", "")
end