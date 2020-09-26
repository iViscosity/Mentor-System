local CATEGORY = "Mentors"

function ulx.assign(calling_ply, assigner, assignee)
	if assignee:CheckGroup("helper") then
		return ULib.tsayError(calling_ply, "This player is already a Helper or above!")
	end

	if not assigner:CheckGroup("senioradmin") then
		return ULib.tsayError(calling_ply, "Mentor must be a Senior Admin or higher!")
	end

	assignee:AssignSenior(assigner)
	ulx.fancyLogAdmin(calling_ply, "#A assigned #T to #T.", assignee, assigner)
end
local assign = ulx.command(CATEGORY, "ulx assign", ulx.assign, "!assign")
assign:addParam{type = ULib.cmds.PlayerArg}
assign:addParam{type = ULib.cmds.PlayerArg}
assign:defaultAccess(ULib.ACCESS_SUPERADMIN)
assign:help("Promotes a target and assigns them a Mentor.")

function ulx.openmenu(calling_ply)
	ULib.clientRPC(calling_ply, "Mentor_Menu")
end
local openmenu = ulx.command(CATEGORY, "ulx mentormenu", ulx.openmenu, {"!mentor", "!mentormenu"})
openmenu:defaultAccess(ULib.ACCESS_SUPERADMIN)
openmenu:help("Opens the Mentor menu.")