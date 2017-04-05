MerlinsRaidHelper = {}

MerlinsRaidHelper.name = "MerlinsRaidHelper"
MerlinsRaidHelper.version = "1.0.2"
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

-- timer
MerlinsRaidHelper.tltw = nil
MerlinsRaidHelper.timerlabel = nil
MerlinsRaidHelper.timertime = 0


-- Initialize addon
function MerlinsRaidHelper.OnAddOnLoaded(eventCode, addOnName)
	if (addOnName == MerlinsRaidHelper.name) then
		MerlinsRaidHelper:Initialize()
	end
end


local function OnPluginLoaded(event, addon)

end


function MerlinsRaidHelper:Initialize()
	self.inCombat = IsUnitInCombat("player")

	MerlinsRaidHelper:SetupInterface()

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CHAT_MESSAGE_CHANNEL, self.ChatCallback)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEAD, self.GetsKilled)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_START_SOUL_GEM_RESURRECTION, self.StartRez)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_COMBAT_EVENT, self.OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAP_PING, self.OnPing)


end


function MerlinsRaidHelper.OnCombatEvent(eventCode , result , isError , abilityName , abilityGraphic , abilityActionSlotType , sourceName , sourceType , targetName , targetType , hitValue , powerType , damageType , log , sourceUnitId , targetUnitId , abilityId)
	-- Ignore errors
  if ( isError ) then return end
  -- result , abilityName , abilityGraphic , abilityActionSlotType , sourceName , sourceType , targetName , targetType , hitValue , powerType , damageType

	-- Determine context
        	local target = zo_strformat("<<!aC:1>>",targetName)
        	local player = zo_strformat("<<!aC:1>>",GetUnitName("player")) -- should be player name
	        local damageOut = false
	        if ( sourceType == COMBAT_UNIT_TYPE_PLAYER or sourceType == COMBAT_UNIT_TYPE_PLAYER_PET ) then damageOut = true
	        elseif ( target == player ) then damageOut = false
	        else return end

	        -- Debugging
	       --d( result .. " || " .. sourceType .. " || " .. sourceName .. " || " .. targetName .. " || " .. abilityName .. " || " .. hitValue  )

	        -- Reflag self-targetted as incoming
	        if ( damageOut and ( target == player ) ) then damageOut = false end

					-- Ignore certain results
        	if ( result == ACTION_RESULT_QUEUED) then return end

	        -- Damage Dealt
	        if ( hitValue > 0 and ( result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_BLOCKED_DAMAGE or result == ACTION_RESULT_DOT_TICK or result == ACTION_RESULT_DOT_TICK_CRITICAL ) ) then

	            -- Flag timestamps
	            if ( damageOut ) then

							  -- backup for pre damageOut
								if (MerlinsRaidHelper.inCombat==false) then
									MerlinsRaidHelper.inCombat = true
									MerlinsRaidHelper.timestart = GetGameTimeMilliseconds()
									MerlinsRaidHelper.dd = 0
									 -- d("passed")
								end

								-- d(hitValue .. player .. " ... " .. target)
								MerlinsRaidHelper.timeend = GetGameTimeMilliseconds()
								MerlinsRaidHelper.dd = MerlinsRaidHelper.dd + hitValue
								-- d(hitValue)
							end

	        -- Healing Dealt
	        -- elseif ( hitValue > 0 and ( result == ACTION_RESULT_HEAL or result == ACTION_RESULT_CRITICAL_HEAL or result == ACTION_RESULT_HOT_TICK or result == ACTION_RESULT_HOT_TICK_CRITICAL ) ) then

	        elseif ( hitValue > 0 ) then

	            -- Prompt other unrecognized

	        end


end


function MerlinsRaidHelper.OnPlayerCombatState(event, inCombat)
	-- The ~= operator is "not equal to" in Lua.

	if inCombat ~= MerlinsRaidHelper.inCombat then
		-- MerlinsRaidHelper.inCombat = inCombat
		if inCombat then
			-- entering combat
			-- d("Start combat")
			--MerlinsRaidHelper.timestart = GetTimeStamp()
			--MerlinsRaidHelper.dd = 0

		else
			-- exiting combat
		  -- d("Left combat")
			MerlinsRaidHelper.inCombat = inCombat
			MerlinsRaidHelper:SendPing()
		end
	end
end


function MerlinsRaidHelper.OnPing( eventCode, pingEventType, pingType, pingTag, offsetX, offsetY , isOwner )

  -- d("get ping"..GetUnitName( pingTag ))
	if ( pingType == MAP_PIN_TYPE_PING ) then
		if ( offsetX == 0 and offsetY == 0 ) then return end

		local name		= GetUnitName( pingTag )
		local time 		= zo_roundToNearest(offsetX * 10000, 0.1 )
		local dps 		= zo_roundToNearest(offsetY * 200000, 1 )
		local damage	= zo_roundToNearest(dps * time, 100 )

		-- Only accept pings within a reasonable range
		if ( ( dps < 0 or dps > 100000 ) or ( time < 1 or time > 1200 ) ) then return end


		d(name.." - DMG: "..damage.." Time: "..time.." DPS: "..dps)


		local now = GetGameTimeMilliseconds()
		if ((MerlinsRaidHelper.lastGroupDatas == 0) or ((MerlinsRaidHelper.lastGroupDatas-now)/1000 > 5)) then
			-- new table
			MerlinsRaidHelper.lastGroupDatas = now
			MerlinsRaidHelper.groupDPSdatas = {}
		end

		-- add data
		local data = {
			["name"]	= name,
			["damage"] 	= damage,
			["dps"]		= dps,
			["time"]	= time,
		}
		MerlinsRaidHelper.groupDPSdatas[name] = data

		-- d("Data added ..."..name)

		-- reload table
		MerlinsRaidHelper:UIReloadTable()

	end

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

		if string.match(string.lower(message), "^settimer%s%d+") then
			-- d("Match Timer: " .. message)
			mins = string.match(string.lower(message), "(%d+)")
			-- d(mins)
			local secounds = mins * 60
			MerlinsRaidHelper.timertime = secounds + (GetGameTimeMilliseconds() / 1000)
    end



		end

end

function MerlinsRaidHelper:GetSec()
	local sec = (MerlinsRaidHelper.timeend-MerlinsRaidHelper.timestart)/1000
	if not (sec>1) then sec = 1 end
	return sec
end

function MerlinsRaidHelper:GetDps(sec)
	if not (sec) then sec = 1 end
	return math.floor(MerlinsRaidHelper.dd / sec)
end


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

	CHAT_SYSTEM:SetChannel(3)
	CHAT_SYSTEM:StartTextEntry("◯ M's Group DPS (V"..MerlinsRaidHelper.version..") is ready to use! ◯")

end

function MerlinsRaidHelper:SendPing()

	local time = MerlinsRaidHelper:GetSec()
	local dps = MerlinsRaidHelper:GetDps(time) -- get k (1000)

	-- Compute map ping offsets
	local timeCoord 	= time/10000
	local dpsCoord		= dps/200000

	-- Send the ping
	PingMap( MAP_PIN_TYPE_PING , MAP_TYPE_LOCATION_CENTERED , timeCoord , dpsCoord )

	 -- d("Ping Posted - "..dps)

end

function MerlinsRaidHelper:SetupInterface()

		MerlinsRaidHelper.wm = GetWindowManager()
		MerlinsRaidHelper.tlw = MerlinsRaidHelper.wm:CreateTopLevelWindow("ccTLW")

		MerlinsRaidHelper.tlw:SetDimensions(408,20*12+37)
		MerlinsRaidHelper.tlw:SetResizeToFitDescendents(true)
		MerlinsRaidHelper.tlw:SetAnchor(RIGHT, GuiRoot, RIGHT, -10, -100)

		MerlinsRaidHelper.tlw:SetMovable(true)
		MerlinsRaidHelper.tlw:SetMouseEnabled(true)
		-- tlw:SetHandler("OnClicked", tlwClicked)

		MerlinsRaidHelper.tableBG = MerlinsRaidHelper.wm:CreateControl("tableBG", MerlinsRaidHelper.tlw, CT_BACKDROP)
		MerlinsRaidHelper.tableBG:SetEdgeColor(0.4,0.4,0.4, 0.1)
		MerlinsRaidHelper.tableBG:SetCenterColor(0.2,0.2,0.2,1)
		MerlinsRaidHelper.tableBG:SetAnchor(TOPLEFT, MerlinsRaidHelper.tlw, TOPLEFT, 0, 0)
		MerlinsRaidHelper.tableBG:SetDimensions(408,20*12+37)
		MerlinsRaidHelper.tableBG:SetAlpha(0.8)
		MerlinsRaidHelper.tableBG:SetDrawLayer(0)
		-- tableBG:SetHandler( "OnMouseUp", function( self ) FTC.Menu:SaveAnchor( self ) end )


		for i=0,12,1 do
	  	MerlinsRaidHelper:UIRow(i, 20, 14, 9 + 20*i)
		end
		MerlinsRaidHelper.field["0Player"]:SetColor(0.8, 0.8, 0.8)
		MerlinsRaidHelper.field["0Time"]:SetColor(0.8, 0.8, 0.8)
		MerlinsRaidHelper.field["0Damage"]:SetColor(0.8, 0.8, 0.8)
		MerlinsRaidHelper.field["0DPS"]:SetColor(0.8, 0.8, 0.8)

		MerlinsRaidHelper.tlw:SetHidden(true)

		-- set up timer
		MerlinsRaidHelper.tltw = MerlinsRaidHelper.wm:CreateTopLevelWindow("ccTLTW")

		MerlinsRaidHelper.tltw:SetDimensions(200,100)
		MerlinsRaidHelper.tltw:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)

		MerlinsRaidHelper.timerBG = MerlinsRaidHelper.wm:CreateControl("timerBackDrop", MerlinsRaidHelper.tltw, CT_BACKDROP)
		MerlinsRaidHelper.timerBG:SetAnchor(CENTER, MerlinsRaidHelper.tltw, CENTER, 0, 0)
		MerlinsRaidHelper.timerBG:SetDimensions(200,100)
		MerlinsRaidHelper.timerBG:SetEdgeColor(0.1,0.1,0.1, 0.8)
		MerlinsRaidHelper.timerBG:SetCenterColor(0.1,0.1,0.1, 0.8)

		MerlinsRaidHelper.timerlabel = MerlinsRaidHelper.wm:CreateControl("timerlabel", MerlinsRaidHelper.tltw, CT_LABEL)
		MerlinsRaidHelper.timerlabel:SetColor(0.8, 0.8, 0.8, 0.7)
		MerlinsRaidHelper.timerlabel:SetFont("ZoFontWinH1")
		MerlinsRaidHelper.timerlabel:SetScale(1)
		MerlinsRaidHelper.timerlabel:SetWrapMode(TEX_MODE_CLAMP)
		MerlinsRaidHelper.timerlabel:SetDrawLayer(1)
		MerlinsRaidHelper.timerlabel:SetText("00:00")
		MerlinsRaidHelper.timerlabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		MerlinsRaidHelper.timerlabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
		MerlinsRaidHelper.timerlabel:SetAnchor(CENTER, MerlinsRaidHelper.tltw, CENTER, 0, 0)
		MerlinsRaidHelper.timerlabel:SetDimensions(200,100)

		MerlinsRaidHelper.tltw:SetHidden(true)


end

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


function MerlinsRaidHelper:UIRow(id, height, left, top)

		local tableBG = {}
		MerlinsRaidHelper.tableBG[id] = MerlinsRaidHelper.wm:CreateControl("rowBackDrop"..id, MerlinsRaidHelper.tlw, CT_BACKDROP)
		MerlinsRaidHelper.tableBG[id]:SetAnchor(TOPLEFT, MerlinsRaidHelper.tlw, TOPLEFT, left-5, top)
		MerlinsRaidHelper.tableBG[id]:SetDimensions(390,height)
		if (id%2 == 0) then
			MerlinsRaidHelper.tableBG[id]:SetEdgeColor(0.1,0.1,0.1)
			MerlinsRaidHelper.tableBG[id]:SetCenterColor(0.1,0.1,0.1)
		else
			MerlinsRaidHelper.tableBG[id]:SetEdgeColor(0.1,0.1,0.1,0.001)
			MerlinsRaidHelper.tableBG[id]:SetCenterColor(0.1,0.1,0.1,0.001)
		end

		MerlinsRaidHelper:UILabel(id, "Player", 140, height, left, top)
		MerlinsRaidHelper:UILabel(id, "Time", 75, height, left+140, top)
		MerlinsRaidHelper:UILabel(id, "Damage", 100, height, left+140+75, top)
		MerlinsRaidHelper:UILabel(id, "DPS", 75, height, left+140+75+100, top)

end

function MerlinsRaidHelper:UILabel(id, text, width, height, left, top)

	local tag = text
	MerlinsRaidHelper.field[id..tag] = MerlinsRaidHelper.wm:CreateControl("label"..tag..id, MerlinsRaidHelper.tableBG[id], CT_LABEL)
	MerlinsRaidHelper.field[id..tag]:SetColor(0.8, 0.8, 0.8, 0.7)
	MerlinsRaidHelper.field[id..tag]:SetFont("ZoFontGame")
	MerlinsRaidHelper.field[id..tag]:SetScale(1)
	MerlinsRaidHelper.field[id..tag]:SetWrapMode(TEX_MODE_CLAMP)
	MerlinsRaidHelper.field[id..tag]:SetDrawLayer(1)
	MerlinsRaidHelper.field[id..tag]:SetText(text)
	MerlinsRaidHelper.field[id..tag]:SetAnchor(TOPLEFT, MerlinsRaidHelper.tlw, TOPLEFT, left, top)
	MerlinsRaidHelper.field[id..tag]:SetDimensions(width,height)

end

local function compare(x,y)
	return x.damage > y.damage
end

function MerlinsRaidHelper:UIReloadTable()

		-- sort data
		local data = {}
		-- d(MerlinsRaidHelper.groupDPSdatas)
		for player , damage in pairs(MerlinsRaidHelper.groupDPSdatas) do
			table.insert(data,damage)
		end
		table.sort(data, compare)
		 --d(data)

		-- visibility
		if ( #data == 0 ) then MerlinsRaidHelper.tlw:SetHidden(true) end
		MerlinsRaidHelper.tlw:SetHidden(false)

		-- insert rows
		for i = 1 , #data do
			MerlinsRaidHelper.field[i.."Player"]:SetText(data[i].name)
			MerlinsRaidHelper.field[i.."Damage"]:SetText(data[i].damage)
			MerlinsRaidHelper.field[i.."DPS"]:SetText(data[i].dps)
			MerlinsRaidHelper.field[i.."Time"]:SetText(data[i].time)
			MerlinsRaidHelper.tableBG[i]:SetHidden(false)
		end
		-- clean up table
		for i = (#data+1) , 12 do
			MerlinsRaidHelper.tableBG[i]:SetHidden(true)
		end

		-- resize
		-- d((25*#data)-5)
		MerlinsRaidHelper.tlw:SetDimensions(408,(20*#data)+37)
		MerlinsRaidHelper.tableBG:SetDimensions(408,(20*#data)+37)

		-- fade out
		--MerlinsRaidHelper.tlw:SetHidden(true)

		zo_callLater(MerlinsRaidHelper.HideTable, 12000) --12 s

end

-- not local cuz teso callback function
function MerlinsRaidHelper.HideTable()
	MerlinsRaidHelper.tlw:SetHidden(true)
end

local function ResizeWind(var)
	MerlinsRaidHelper.tlw:SetDimensions(408,(20*var)+37)
	MerlinsRaidHelper.tableBG:SetDimensions(408,(20*var)+37)

	for i = 1 , var do
		MerlinsRaidHelper.tableBG[i]:SetHidden(false)
	end
	-- clean up table
	for i = (var+1) , 12 do
		MerlinsRaidHelper.tableBG[i]:SetHidden(true)
	end

	MerlinsRaidHelper.tlw:SetHidden(false)
end

local function SetTimer()
	local secounds = 5 * 60
	MerlinsRaidHelper.timertime = secounds + (GetGameTimeMilliseconds() / 1000)
	-- d("Set Timer")

end

EVENT_MANAGER:RegisterForEvent(MerlinsRaidHelper.name, EVENT_ADD_ON_LOADED, MerlinsRaidHelper.OnAddOnLoaded);

SLASH_COMMANDS["/test"] = ResizeWind
SLASH_COMMANDS["/hide"] = MerlinsRaidHelper.HideTable
SLASH_COMMANDS["/settimer"] = SetTimer
