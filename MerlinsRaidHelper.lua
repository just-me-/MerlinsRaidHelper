MerlinsRaidHelper = {}

MerlinsRaidHelper.LAM2 = LibStub("LibAddonMenu-2.0")

MerlinsRaidHelper.name = "MerlinsRaidHelper"
MerlinsRaidHelper.version = "1.0.3"
MerlinsRaidHelper.inCombat = false

MerlinsRaidHelper.timestart = 0
MerlinsRaidHelper.timeend = 0

MerlinsRaidHelper.dd = 0
MerlinsRaidHelper.dps = 0
MerlinsRaidHelper.rez = 0
MerlinsRaidHelper.dead = 0

MerlinsRaidHelper.groupDPSdatas = {}
MerlinsRaidHelper.lastGroupDatas = 0
MerlinsRaidHelper.tableBG = {}
MerlinsRaidHelper.field = {}

MerlinsRaidHelper.wm = nil
MerlinsRaidHelper.tlw = nil
MerlinsRaidHelper.tableBG = nil
MerlinsRaidHelper.tablewidth = 415 -- const.

-- timer
MerlinsRaidHelper.tltw = nil
MerlinsRaidHelper.timerlabel = nil
MerlinsRaidHelper.timertime = 0

-- rdy checker
MerlinsRaidHelper.rdylist = {}


-- #############################
-- initialize addon
-- #############################

function MerlinsRaidHelper.OnAddOnLoaded(eventCode, addOnName)
	if (addOnName == MerlinsRaidHelper.name) then
		MerlinsRaidHelper:Initialize()
		MerlinsRaidHelper:CreateSettingsMenu()
	end
end


local function OnPluginLoaded(event, addon)

	-- 2do..
	-- IsUnitInCombat(string unitTag)
	--		Returns: boolean isInCombat

end


function MerlinsRaidHelper:Initialize()
	-- saved varis
	local defaults = {
		userOPACITY = 100,
		userSHOWTABLE = false,
	}
	self.savedVariables = ZO_SavedVars:NewAccountWide("MerlinsRaidHelperSavedVariables", 1, nil, defaults)

	self.inCombat = IsUnitInCombat("player")

	MerlinsRaidHelper:SetupInterface()

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CHAT_MESSAGE_CHANNEL, self.ChatCallback)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEAD, self.GetsKilled)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_START_SOUL_GEM_RESURRECTION, self.StartRez)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_COMBAT_EVENT, self.OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAP_PING, self.OnPing)


end


MerlinsRaidHelper.GetsKilled = function(_)
	-- d("GetsKilled")
	MerlinsRaidHelper.dead = MerlinsRaidHelper.dead + 1
end

MerlinsRaidHelper.StartRez = function(_, durationMs)
	-- d("StartRez")
	MerlinsRaidHelper.rez = MerlinsRaidHelper.rez + 1
end


-- callback fired on chat message
MerlinsRaidHelper.ChatCallback = function(_, messageType, from, message)

		if from ~= nil and from ~= "" then

	    if string.lower(message) == "showdps" then
				MerlinsRaidHelper:SendToChat()
	    end

			if string.lower(message) == "showinit" then
				MerlinsRaidHelper:SendInitToChat()
	    end

			if string.lower(message) == "rdycheck" then
				MerlinsRaidHelper:StartReadyCheck()
	    end

			if string.match(string.lower(message), "^settimer%s%d+") then
				-- d("Match Timer: " .. message)
				mins = string.match(string.lower(message), "(%d+)")
				-- d(mins)
				local secounds = mins * 60
				MerlinsRaidHelper.timertime = secounds + (GetGameTimeMilliseconds() / 1000)
	    end

		end

end

-- #############################
-- helping functions
-- #############################

function MerlinsRaidHelper:GetSec()
	local sec = (MerlinsRaidHelper.timeend-MerlinsRaidHelper.timestart)/1000
	if not (sec>1) then sec = 1 end
	return sec
end

function MerlinsRaidHelper:GetDps(sec)
	if not (sec) then sec = 1 end
	return math.floor(MerlinsRaidHelper.dd / sec)
end


-- #############################
-- text functions
-- #############################

function MerlinsRaidHelper:SendToChat()

	-- prepare data and strings...
	local sec = MerlinsRaidHelper:GetSec()
	local dps = MerlinsRaidHelper:GetDps(sec) / 1000 -- get k (1000)

	d(math.floor(MerlinsRaidHelper.dd) .. "k in " .. sec .."s is a dps of "..dps .."k.")

	if not (dps>0) then dps = 0 end

	local dpstext = "";
	if (dps < 5) then
		dpstext = "Probably not a DD. Less than 5k."
	elseif (dps < 10) then
		dpstext = "I should do more DMG. Under 10k."
	elseif (dps < 15) then
		dpstext = "A little more DMG wouldn't be worse. Under 15k."
	elseif (dps < 20) then
		dpstext = "My DMG was good. Over 15k."
	else
		dpstext = "Fear my madness! DPS: around " .. dps .. "k!"
	end

	local deadtext = "";
	if (MerlinsRaidHelper.dead == 0) then
		deadtext = "I'm immortal!"
	elseif (MerlinsRaidHelper.dead == 1) then
		deadtext = "I died once."
	elseif (MerlinsRaidHelper.dead < 5) then
		deadtext = "I died a few times."
	else
		deadtext = "I died too often. I should train my movement."
	end

	CHAT_SYSTEM:SetChannel(3)
	CHAT_SYSTEM:StartTextEntry(dpstext.." "..deadtext.." Rez attempts: "..MerlinsRaidHelper.rez)

	-- reset
	MerlinsRaidHelper.rez = 0
	MerlinsRaidHelper.dead = 0
end

function MerlinsRaidHelper:SendInitToChat()

	PlayEmoteByIndex(84)
	CHAT_SYSTEM:SetChannel(3)
	CHAT_SYSTEM:StartTextEntry("◯ M's Group DPS (V"..MerlinsRaidHelper.version..") is ready to use! ◯")

end


-- #############################
-- rdy-Checker
-- #############################

function MerlinsRaidHelper:StartReadyCheck()
	 if IsUnitGrouped('player') == false then return end

	-- clean table; save position data
	MerlinsRaidHelper.rdylist = {}
	for xid = 1, GetGroupSize(), 1 do
	  tag = GetGroupUnitTagByIndex(xid)
		posX, posY, posZ = GetMapPlayerPosition(tag)
		MerlinsRaidHelper.rdylist[tag] = posX..posY..posZ
	end
	--d(MerlinsRaidHelper.rdylist)

	-- start timer
	MerlinsRaidHelper.timertime = 10 + (GetGameTimeMilliseconds() / 1000)
	-- callback - check table
	zo_callLater(MerlinsRaidHelper.EndReadyCheck, 10000) -- 10s
	d("rdy-Checker started...")

	-- sit on chair
	PlayEmoteByIndex(100)

end

function MerlinsRaidHelper:EndReadyCheck()
	d("rdy-Checker done.")
	for xid = 1, GetGroupSize(), 1 do
		tag = GetGroupUnitTagByIndex(xid)
		name = GetUnitName(tag)
		posX, posY, posZ = GetMapPlayerPosition(tag)
		if (MerlinsRaidHelper.rdylist[tag] == posX..posY..posZ) then
			d(name.." is still not here!")
		end
	end

end


-- #############################
-- break timer
-- #############################

function MerlinsRaidHelper:UpdateTimer()
	if (MerlinsRaidHelper.timertime == 0) then return end

	--d("Timer update"..MerlinsRaidHelper.timertime)

	local secounds = MerlinsRaidHelper.timertime -  (GetGameTimeMilliseconds() / 1000)
	MerlinsRaidHelper.timerlabel:SetText(MerlinsRaidHelper:GetTimeShort(secounds))

	if (secounds > (2 * 60)) then
		MerlinsRaidHelper.timerBG:SetCenterColor(0.12, 0.76, 0.12, 0.6)
	elseif (secounds > 60) then
		MerlinsRaidHelper.timerBG:SetCenterColor(0.76, 0.76, 0.12, 0.6)
	else
		MerlinsRaidHelper.timerBG:SetCenterColor(0.76, 0.12, 0.12, 0.6)
	end

	MerlinsRaidHelper.tltw:SetHidden(false)

	if (secounds < 1) then
		MerlinsRaidHelper.timertime = 0
		MerlinsRaidHelper.tltw:SetHidden(true)
	end

end

function MerlinsRaidHelper:GetTimeShort(s)
	--return string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)

	local val = ""
	local hours = s/(60*60)
	local minutes = s/60%60
	local seconds = s%60

	if hours >= 1 then
		val = string.format("%.2d:", hours)
	end
	if minutes >= 1 then
		val = val .. string.format("%.2d:", minutes)
	end

	val = val .. string.format("%.2d", seconds)

	return val
end


-- #############################
-- Functions for slash-commands
-- #############################

-- not local cuz teso callback function
function MerlinsRaidHelper:HideTable()
	MerlinsRaidHelper.tlw:SetHidden(true)
end

function MerlinsRaidHelper:ShowTable()
	MerlinsRaidHelper.tlw:SetHidden(false)
end

local function ResizeWind(var)
	MerlinsRaidHelper.tlw:SetDimensions(MerlinsRaidHelper.tablewidth,(20*var)+37)
	MerlinsRaidHelper.tableBG:SetDimensions(MerlinsRaidHelper.tablewidth,(20*var)+37)

	for i = 1 , var do
		MerlinsRaidHelper.tableBG[i]:SetHidden(false)
	end
	-- clean up table
	for i = (var+1) , 12 do
		MerlinsRaidHelper.tableBG[i]:SetHidden(true)
	end

	MerlinsRaidHelper:ShowTable()
end

local function SetTimer()
	local secounds = 5 * 60
	MerlinsRaidHelper.timertime = secounds + (GetGameTimeMilliseconds() / 1000)
	-- d("Set Timer")

end

-- on load call
EVENT_MANAGER:RegisterForEvent(MerlinsRaidHelper.name, EVENT_ADD_ON_LOADED, MerlinsRaidHelper.OnAddOnLoaded);

-- #############################
-- slash-commands
-- #############################

SLASH_COMMANDS["/test"] = ResizeWind
SLASH_COMMANDS["/show"] = MerlinsRaidHelper.ShowTable
SLASH_COMMANDS["/hide"] = MerlinsRaidHelper.HideTable
SLASH_COMMANDS["/rdycheck"] = MerlinsRaidHelper.StartReadyCheck
SLASH_COMMANDS["/settimer"] = SetTimer
