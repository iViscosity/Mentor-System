local menteeList = {} -- contains the list of players assigned to this player and their associated logs

-- The function called from the ULX command. The menu is not shown until all of the data necessary is received.
function Mentor_Menu()
	local client = LocalPlayer()
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
	local client = LocalPlayer()
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

	--local scrollPanel = vgui.Create("DScrollPanel", frame) -- container for the list view of mentees
	--scrollPanel:SetHeight(600)
	--scrollPanel:Dock(LEFT)

	local refresh = vgui.Create("DButton", frame)
	refresh:Dock(BOTTOM)
	refresh:SetText("Refresh")

	refresh.DoClick = function()
		frame:Close()
		Mentor_Menu()
	end

	local listOfMentees = vgui.Create("DListView", frame) -- container for menteeList
	listOfMentees:SetMultiSelect(false)
	listOfMentees:AddColumn("Mentees"):SetFixedWidth(120)
	listOfMentees:SetWidth(120)
	listOfMentees:Dock(LEFT)

	-- debug
	--listOfMentees:AddLine("Test (test)")
	--listOfMentees:AddLine("Test (test)")
	--listOfMentees:AddLine("Test (test)")
	--listOfMentees:AddLine("Test (test)")

	for steamid in pairs(menteeList) do
		local ply = player.GetBySteamID64(steamid)
		if not ply then continue end
		listOfMentees:AddLine(steamid)
	end

	local tabs = vgui.Create("DPropertySheet", frame)
	tabs:Dock(FILL)

	local commandLog = vgui.Create("DListView", tabs)
	commandLog:AddColumn("Timestamp"):SetFixedWidth(115)
	commandLog:AddColumn("Command")

	local chatLog = vgui.Create("DListView", tabs)
	chatLog:AddColumn("Timestamp"):SetFixedWidth(115)
	chatLog:AddColumn("Message")

	--local settingsMenu = vgui.Create("DLabel", tabs)
	--settingsMenu:SetText("TBD")

	tabs:AddSheet("Commands", commandLog, "icon16/computer.png")
	tabs:AddSheet("Chat", chatLog, "icon16/textfield.png")
	--tabs:AddSheet("Settings", settingsMenu, "icon16/wrench.png")

	listOfMentees.OnRowSelected = function(lst, index, pnl)
		local steamid = pnl:GetColumnText(1)
		commandLog:Clear()
		chatLog:Clear()

		local commands = menteeList[steamid].commands
		local chat = menteeList[steamid].chat

		for _command in commands:gmatch(".-\n") do
			local timestamp = _command:sub(1, 21):gsub("[%[%]]", "")
			local command = _command:sub(22):gsub("\n", "")

			commandLog:AddLine(timestamp, command)
		end

		for _message in chat:gmatch(".-\n") do
			local timestamp = _message:sub(1, 21):gsub("[%[%]]", "")
			local message = _message:sub(22):gsub("\n", "")

			chatLog:AddLine(timestamp, message)
		end
	end

	listOfMentees:SelectFirstItem()
	--scrollPanel:AddItem(listOfMentees)
end

net.Receive("Mentor_AddMentor", function(len)
	local sid = net.ReadString()
	menteeList[sid] = {commands={}, chat={}}
end)

net.Receive("Mentor_SendLogs", function(len)
	local n = net.ReadUInt(2)

	for i = 1, n do
		local sid = net.ReadString()
		local commands = net.ReadString()
		local chat = net.ReadString()
	
		menteeList[sid] = {
			commands = commands,
			chat = chat
		}

		--print(sid, commands, chat)
	end

	Mentor_OpenMenu()
end)