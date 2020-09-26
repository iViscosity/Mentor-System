-- For logging commands and chat
local gamemodesWithTeamSupport = { -- gamemodes that use special handling for team messages
	["terrortown"] = true
}

local DEBUG = true

-- Player say logs everything, including commands.
local function LogPlayerSay(ply, text, teamOnly)
	--print("got msg")
	if not DEBUG and not ply:IsUserGroup("helper") then return end -- we only want Helpers.

	local mentor = DEBUG and ply:SteamID64() or ply:GetPData("mentor", false) -- sanity check
	if not mentor then 
		ErrorNoHalt("Helper with no mentor? " .. ply:Name() .. " (" .. ply:SteamID64() .. ")")
		return
	end

	local timestamp = os.date("[%x @ %X]") -- returns "[09/26/20 @ 02:20:31]"
	if gamemodesWithTeamSupport[engine.ActiveGamemode()] and teamOnly then
		text = "(TEAM) " .. text
	end

	text = timestamp .. text

	local path = "mentors/" .. mentor .. "/" .. ply:SteamID64()
	if file.Exists(path .. "/chat.txt", "DATA") then
		file.Append(path .. "/chat.txt", text .. "\n")
	else
		file.Write(path .. "/chat.txt", text .. "\n")
	end
end
hook.Add("PlayerSay", "Mentor_PlayerSay", LogPlayerSay)

local function LogPlayerCommand(ply, commandName, args)
	if not IsPlayer(ply) then return end
	if not DEBUG and not ply:IsUserGroup("helper") then return end

	local mentor = DEBUG and ply:SteamID64() or ply:GetPData("mentor", false)
	if not mentor then 
		ErrorNoHalt("Helper with no mentor? " .. ply:Name() .. " (" .. ply:SteamID64() .. ")")
		return
	end

	local timestamp = os.date("[%x @ %X]")
	local text = timestamp .. commandName .. " " .. table.concat(args, " ")

	local path = "mentors/" .. mentor .. "/" .. ply:SteamID64()
	if file.Exists(path .. "/commands.txt", "DATA") then
		file.Append(path .. "/commands.txt", text .. "\n")
	else
		file.Write(path .. "/commands.txt", text .. "\n")
	end
end
hook.Add("ULibCommandCalled", "Mentor_ULibCommandCalled", LogPlayerCommand)