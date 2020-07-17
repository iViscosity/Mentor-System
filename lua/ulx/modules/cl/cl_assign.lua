local client = LocalPlayer()

local menteeList = {} -- contains the list of players assigned to this player and their associated logs

net.Receive("Mentor_AddMentor", function(len)
	local sid = net.ReadString()
	menteeList[sid] = {commands={}, chat={}}
end)

net.Receive("Mentor_SendLogs", function(len)
	local n = net.ReadUInt(2)

	for i = 1, n do
		local sid = net.ReadString()
		local commands = util.Decompress(net.ReadString())
		local chat = util.Decompress(net.ReadString())
	
		menteeList[sid] = {
			commands = commands,
			chat = chat
		}
	end

	Mentor_OpenMenu()
end)

-- The function called from the ULX command. The menu is not shown until all of the data necessary is received.
function Mentor_Menu()
	if not client:CheckGroup("senioradmin") then -- sanity check (ULX command should prevent this, but better to be safe than sorry)
		return ULib.tsayError(client, "You are not allowed to open this menu, " .. client:Name() .. ".")
	end

	net.Start("Mentor_RequestLogs")
	net.SendToServer()
end

-- This opens the menu once the information is received
-- This isn't going to look great because my clientside scripting is awful,
-- but I plan on improving it eventually.
local function Mentor_OpenMenu()
	local frame = vgui.Create("DFrame") -- container for everything

	frame:SetSize(1024, 768)
	frame:Center()

	frame:SetTitle("List of Mentees - " .. client:SteamID() .. " (" .. client:Name() .. ")")

	frame:SetDraggable(false)
	frame:SetSizable(false)
	frame:SetBackgroundBlur(true)

	frame:MakePopup()

	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)

	local scrollPanel = vgui.Create("DScrollPanel", frame) -- container for the list view of mentees
	scrollPanel:Dock(LEFT)

	local listOfMentees = vgui.Create("DListView", scrollPanel) -- container for menteeList
	listOfMentees:SetMultiSelect(false)
	listOfMentees:AddColumn("Mentees"):SetFixedWidth(125)

	for steamid in pairs(menteeList) do
		local ply = player.GetBySteamID(steamid)
		listOfMentees:AddLine(ply:Name() .. " (" .. steamid .. ")")
	end

	local tabs = vgui.Create("DPropertySheet", frame)
	tabs:Dock(FILL)

	local commandLog = vgui.Create("DListView", tabs)
	commandLog:AddColumn("Timestamp"):SetFixedWidth(150)
	commandLog:AddColumn("Command")

	local chatLog = vgui.Create("DListView", tabs)
	chatLog:AddColumn("Timestamp"):SetFixedWidth(150)
	chatLog:AddColumn("Message")

	--local settingsMenu = vgui.Create("DLabel", tabs)
	--settingsMenu:SetText("TBD")

	tabs:AddSheet("Commands", commandLog, "icon16/computer.png")
	tabs:AddSheet("Chat", chatLog, "icon16/textfield.png")
	--tabs:AddSheet("Settings", settingsMenu, "icon16/wrench.png")

	listOfMentees.OnRowSelected = function(lst, index, pnl)
		local steamid = pnl:GetColumnText(1)

		local commands = menteeList[steamid].commands
		local chat = menteeList[steamid].chat

		for _, _command in pairs(commands:gmatch(".-\n")) do
			local timestamp = _command:sub(1, 21):gsub("[%[%]]", "")
			local command = _command:sub(22):gsub("\n", "")

			commandLog:AddLine(timestamp, command)
		end

		for _, _message in pairs(chat:gmatch(".-\n")) do
			local timestamp = _message:sub(1, 21):gsub("[%[%]]", "")
			local message = _message:sub(22):gsub("\n", "")

			chatLog:AddLine(timestamp, message)
		end
	end

	listOfMentees:SelectFirstItem()
	scrollPanel:AddItem(listOfMentees)

	local refresh = vgui.Create("DButton", frame)
	refresh:Dock(BOTTOM)
	refresh:SetText("Refresh")

	refresh.DoClick = function()
		frame:Close()
		Mentor_Menu()
	end
end