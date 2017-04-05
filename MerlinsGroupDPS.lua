merlinsGroupDPS = {}

merlinsGroupDPS.name = "MerlinsGroupDPS"
merlinsGroupDPS.version = "1.0.2"
merlinsGroupDPS.inCombat = false

merlinsGroupDPS.timestart = 0
merlinsGroupDPS.timeend = 0

merlinsGroupDPS.dd = 0
merlinsGroupDPS.dps = 0
merlinsGroupDPS.rez = 0
merlinsGroupDPS.dead = 0

merlinsGroupDPS.groupDPSdatas = {}
merlinsGroupDPS.lastGroupDatas = 0
merlinsGroupDPS.tableBG = {}
merlinsGroupDPS.field = {}

merlinsGroupDPS.wm = nil
merlinsGroupDPS.tlw = nil
merlinsGroupDPS.tableBG = nil

-- timer
merlinsGroupDPS.tltw = nil
merlinsGroupDPS.timerlabel = nil
merlinsGroupDPS.timertime = 0


-- Initialize addon
function merlinsGroupDPS.OnAddOnLoaded(eventCode, addOnName)
	if (addOnName == merlinsGroupDPS.name) then
		merlinsGroupDPS:Initialize()
	end
end


local function OnPluginLoaded(event, addon)

end


function merlinsGroupDPS:Initialize()
	self.inCombat = IsUnitInCombat("player")

	merlinsGroupDPS:SetupInterface()

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CHAT_MESSAGE_CHANNEL, self.ChatCallback)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_DEAD, self.GetsKilled)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_START_SOUL_GEM_RESURRECTION, self.StartRez)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_COMBAT_EVENT, self.OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAP_PING, self.OnPing)


end


function merlinsGroupDPS.OnCombatEvent(eventCode , result , isError , abilityName , abilityGraphic , abilityActionSlotType , sourceName , sourceType , targetName , targetType , hitValue , powerType , damageType , log , sourceUnitId , targetUnitId , abilityId)
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
								if (merlinsGroupDPS.inCombat==false) then
									merlinsGroupDPS.inCombat = true
									merlinsGroupDPS.timestart = GetGameTimeMilliseconds()
									merlinsGroupDPS.dd = 0
									 -- d("passed")
								end

								-- d(hitValue .. player .. " ... " .. target)
								merlinsGroupDPS.timeend = GetGameTimeMilliseconds()
								merlinsGroupDPS.dd = merlinsGroupDPS.dd + hitValue
								-- d(hitValue)
							end

	        -- Healing Dealt
	        -- elseif ( hitValue > 0 and ( result == ACTION_RESULT_HEAL or result == ACTION_RESULT_CRITICAL_HEAL or result == ACTION_RESULT_HOT_TICK or result == ACTION_RESULT_HOT_TICK_CRITICAL ) ) then

	        elseif ( hitValue > 0 ) then

	            -- Prompt other unrecognized

	        end


end


function merlinsGroupDPS.OnPlayerCombatState(event, inCombat)
	-- The ~= operator is "not equal to" in Lua.

	if inCombat ~= merlinsGroupDPS.inCombat then
		-- merlinsGroupDPS.inCombat = inCombat
		if inCombat then
			-- entering combat
			-- d("Start combat")
			--merlinsGroupDPS.timestart = GetTimeStamp()
			--merlinsGroupDPS.dd = 0

		else
			-- exiting combat
		  -- d("Left combat")
			merlinsGroupDPS.inCombat = inCombat
			merlinsGroupDPS:SendPing()
		end
	end
end


function merlinsGroupDPS.OnPing( eventCode, pingEventType, pingType, pingTag, offsetX, offsetY , isOwner )

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
		if ((merlinsGroupDPS.lastGroupDatas == 0) or ((merlinsGroupDPS.lastGroupDatas-now)/1000 > 5)) then
			-- new table
			merlinsGroupDPS.lastGroupDatas = now
			merlinsGroupDPS.groupDPSdatas = {}
		end

		-- add data
		local data = {
			["name"]	= name,
			["damage"] 	= damage,
			["dps"]		= dps,
			["time"]	= time,
		}
		merlinsGroupDPS.groupDPSdatas[name] = data

		-- d("Data added ..."..name)

		-- reload table
		merlinsGroupDPS:UIReloadTable()

	end

end


merlinsGroupDPS.GetsKilled = function(_)
	-- d("GetsKilled")
	merlinsGroupDPS.dead = merlinsGroupDPS.dead + 1
end

merlinsGroupDPS.StartRez = function(_, durationMs)
	-- d("StartRez")
	merlinsGroupDPS.rez = merlinsGroupDPS.rez + 1
end

-- callback fired on chat message
merlinsGroupDPS.ChatCallback = function(_, messageType, from, message)

		if from ~= nil and from ~= "" then

    if string.lower(message) == "showdps" then
			merlinsGroupDPS:SendToChat()
    end

		if string.lower(message) == "showinit" then
			merlinsGroupDPS:SendInitToChat()
    end

		if string.match(string.lower(message), "^settimer%s%d+") then
			-- d("Match Timer: " .. message)
			mins = string.match(string.lower(message), "(%d+)")
			-- d(mins)
			local secounds = mins * 60
			merlinsGroupDPS.timertime = secounds + (GetGameTimeMilliseconds() / 1000)
    end



		end

end

function merlinsGroupDPS:GetSec()
	local sec = (merlinsGroupDPS.timeend-merlinsGroupDPS.timestart)/1000
	if not (sec>1) then sec = 1 end
	return sec
end

function merlinsGroupDPS:GetDps(sec)
	if not (sec) then sec = 1 end
	return math.floor(merlinsGroupDPS.dd / sec)
end


function merlinsGroupDPS:SendToChat()

	-- prepare data and strings...
	local sec = merlinsGroupDPS:GetSec()
	local dps = merlinsGroupDPS:GetDps(sec) / 1000 -- get k (1000)

	d(math.floor(merlinsGroupDPS.dd) .. "k in " .. sec .."s is a dps of "..dps .."k.")

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
	if (merlinsGroupDPS.dead == 0) then
		deadtext = "I'm immortal!"
	elseif (merlinsGroupDPS.dead == 1) then
		deadtext = "I died once."
	elseif (merlinsGroupDPS.dead < 5) then
		deadtext = "I died a few times."
	else
		deadtext = "I died too often. I should train my movement."
	end

	CHAT_SYSTEM:SetChannel(3)
	CHAT_SYSTEM:StartTextEntry(dpstext.." "..deadtext.." Rez attempts: "..merlinsGroupDPS.rez)

	-- reset
	merlinsGroupDPS.rez = 0
	merlinsGroupDPS.dead = 0
end

function merlinsGroupDPS:SendInitToChat()

	CHAT_SYSTEM:SetChannel(3)
	CHAT_SYSTEM:StartTextEntry("◯ M's Group DPS (V"..merlinsGroupDPS.version..") is ready to use! ◯")

end

function merlinsGroupDPS:SendPing()

	local time = merlinsGroupDPS:GetSec()
	local dps = merlinsGroupDPS:GetDps(time) -- get k (1000)

	-- Compute map ping offsets
	local timeCoord 	= time/10000
	local dpsCoord		= dps/200000

	-- Send the ping
	PingMap( MAP_PIN_TYPE_PING , MAP_TYPE_LOCATION_CENTERED , timeCoord , dpsCoord )

	 -- d("Ping Posted - "..dps)

end

function merlinsGroupDPS:SetupInterface()

		merlinsGroupDPS.wm = GetWindowManager()
		merlinsGroupDPS.tlw = merlinsGroupDPS.wm:CreateTopLevelWindow("ccTLW")

		merlinsGroupDPS.tlw:SetDimensions(408,20*12+37)
		merlinsGroupDPS.tlw:SetResizeToFitDescendents(true)
		merlinsGroupDPS.tlw:SetAnchor(RIGHT, GuiRoot, RIGHT, -10, -100)

		merlinsGroupDPS.tlw:SetMovable(true)
		merlinsGroupDPS.tlw:SetMouseEnabled(true)
		-- tlw:SetHandler("OnClicked", tlwClicked)

		merlinsGroupDPS.tableBG = merlinsGroupDPS.wm:CreateControl("tableBG", merlinsGroupDPS.tlw, CT_BACKDROP)
		merlinsGroupDPS.tableBG:SetEdgeColor(0.4,0.4,0.4, 0.1)
		merlinsGroupDPS.tableBG:SetCenterColor(0.2,0.2,0.2,1)
		merlinsGroupDPS.tableBG:SetAnchor(TOPLEFT, merlinsGroupDPS.tlw, TOPLEFT, 0, 0)
		merlinsGroupDPS.tableBG:SetDimensions(408,20*12+37)
		merlinsGroupDPS.tableBG:SetAlpha(0.8)
		merlinsGroupDPS.tableBG:SetDrawLayer(0)
		-- tableBG:SetHandler( "OnMouseUp", function( self ) FTC.Menu:SaveAnchor( self ) end )


		for i=0,12,1 do
	  	merlinsGroupDPS:UIRow(i, 20, 14, 9 + 20*i)
		end
		merlinsGroupDPS.field["0Player"]:SetColor(0.8, 0.8, 0.8)
		merlinsGroupDPS.field["0Time"]:SetColor(0.8, 0.8, 0.8)
		merlinsGroupDPS.field["0Damage"]:SetColor(0.8, 0.8, 0.8)
		merlinsGroupDPS.field["0DPS"]:SetColor(0.8, 0.8, 0.8)

		merlinsGroupDPS.tlw:SetHidden(true)

		-- set up timer
		merlinsGroupDPS.tltw = merlinsGroupDPS.wm:CreateTopLevelWindow("ccTLTW")

		merlinsGroupDPS.tltw:SetDimensions(200,100)
		merlinsGroupDPS.tltw:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)

		merlinsGroupDPS.timerBG = merlinsGroupDPS.wm:CreateControl("timerBackDrop", merlinsGroupDPS.tltw, CT_BACKDROP)
		merlinsGroupDPS.timerBG:SetAnchor(CENTER, merlinsGroupDPS.tltw, CENTER, 0, 0)
		merlinsGroupDPS.timerBG:SetDimensions(200,100)
		merlinsGroupDPS.timerBG:SetEdgeColor(0.1,0.1,0.1, 0.8)
		merlinsGroupDPS.timerBG:SetCenterColor(0.1,0.1,0.1, 0.8)

		merlinsGroupDPS.timerlabel = merlinsGroupDPS.wm:CreateControl("timerlabel", merlinsGroupDPS.tltw, CT_LABEL)
		merlinsGroupDPS.timerlabel:SetColor(0.8, 0.8, 0.8, 0.7)
		merlinsGroupDPS.timerlabel:SetFont("ZoFontWinH1")
		merlinsGroupDPS.timerlabel:SetScale(1)
		merlinsGroupDPS.timerlabel:SetWrapMode(TEX_MODE_CLAMP)
		merlinsGroupDPS.timerlabel:SetDrawLayer(1)
		merlinsGroupDPS.timerlabel:SetText("00:00")
		merlinsGroupDPS.timerlabel:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		merlinsGroupDPS.timerlabel:SetVerticalAlignment(TEXT_ALIGN_CENTER)
		merlinsGroupDPS.timerlabel:SetAnchor(CENTER, merlinsGroupDPS.tltw, CENTER, 0, 0)
		merlinsGroupDPS.timerlabel:SetDimensions(200,100)

		merlinsGroupDPS.tltw:SetHidden(true)


end

function merlinsGroupDPS:UpdateTimer()
	if (merlinsGroupDPS.timertime == 0) then return end

	--d("Timer update"..merlinsGroupDPS.timertime)

	local secounds = merlinsGroupDPS.timertime -  (GetGameTimeMilliseconds() / 1000)
	merlinsGroupDPS.timerlabel:SetText(merlinsGroupDPS:GetTimeShort(secounds))

	if (secounds > (2 * 60)) then
		merlinsGroupDPS.timerBG:SetCenterColor(0.12, 0.76, 0.12, 0.6)
	elseif (secounds > 60) then
		merlinsGroupDPS.timerBG:SetCenterColor(0.76, 0.76, 0.12, 0.6)
	else
		merlinsGroupDPS.timerBG:SetCenterColor(0.76, 0.12, 0.12, 0.6)
	end

	merlinsGroupDPS.tltw:SetHidden(false)

	if (secounds < 1) then
		merlinsGroupDPS.timertime = 0
		merlinsGroupDPS.tltw:SetHidden(true)
	end

end

function merlinsGroupDPS:GetTimeShort(s)
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


function merlinsGroupDPS:UIRow(id, height, left, top)

		local tableBG = {}
		merlinsGroupDPS.tableBG[id] = merlinsGroupDPS.wm:CreateControl("rowBackDrop"..id, merlinsGroupDPS.tlw, CT_BACKDROP)
		merlinsGroupDPS.tableBG[id]:SetAnchor(TOPLEFT, merlinsGroupDPS.tlw, TOPLEFT, left-5, top)
		merlinsGroupDPS.tableBG[id]:SetDimensions(390,height)
		if (id%2 == 0) then
			merlinsGroupDPS.tableBG[id]:SetEdgeColor(0.1,0.1,0.1)
			merlinsGroupDPS.tableBG[id]:SetCenterColor(0.1,0.1,0.1)
		else
			merlinsGroupDPS.tableBG[id]:SetEdgeColor(0.1,0.1,0.1,0.001)
			merlinsGroupDPS.tableBG[id]:SetCenterColor(0.1,0.1,0.1,0.001)
		end

		merlinsGroupDPS:UILabel(id, "Player", 140, height, left, top)
		merlinsGroupDPS:UILabel(id, "Time", 75, height, left+140, top)
		merlinsGroupDPS:UILabel(id, "Damage", 100, height, left+140+75, top)
		merlinsGroupDPS:UILabel(id, "DPS", 75, height, left+140+75+100, top)

end

function merlinsGroupDPS:UILabel(id, text, width, height, left, top)

	local tag = text
	merlinsGroupDPS.field[id..tag] = merlinsGroupDPS.wm:CreateControl("label"..tag..id, merlinsGroupDPS.tableBG[id], CT_LABEL)
	merlinsGroupDPS.field[id..tag]:SetColor(0.8, 0.8, 0.8, 0.7)
	merlinsGroupDPS.field[id..tag]:SetFont("ZoFontGame")
	merlinsGroupDPS.field[id..tag]:SetScale(1)
	merlinsGroupDPS.field[id..tag]:SetWrapMode(TEX_MODE_CLAMP)
	merlinsGroupDPS.field[id..tag]:SetDrawLayer(1)
	merlinsGroupDPS.field[id..tag]:SetText(text)
	merlinsGroupDPS.field[id..tag]:SetAnchor(TOPLEFT, merlinsGroupDPS.tlw, TOPLEFT, left, top)
	merlinsGroupDPS.field[id..tag]:SetDimensions(width,height)

end

local function compare(x,y)
	return x.damage > y.damage
end

function merlinsGroupDPS:UIReloadTable()

		-- sort data
		local data = {}
		-- d(merlinsGroupDPS.groupDPSdatas)
		for player , damage in pairs(merlinsGroupDPS.groupDPSdatas) do
			table.insert(data,damage)
		end
		table.sort(data, compare)
		 --d(data)

		-- visibility
		if ( #data == 0 ) then merlinsGroupDPS.tlw:SetHidden(true) end
		merlinsGroupDPS.tlw:SetHidden(false)

		-- insert rows
		for i = 1 , #data do
			merlinsGroupDPS.field[i.."Player"]:SetText(data[i].name)
			merlinsGroupDPS.field[i.."Damage"]:SetText(data[i].damage)
			merlinsGroupDPS.field[i.."DPS"]:SetText(data[i].dps)
			merlinsGroupDPS.field[i.."Time"]:SetText(data[i].time)
			merlinsGroupDPS.tableBG[i]:SetHidden(false)
		end
		-- clean up table
		for i = (#data+1) , 12 do
			merlinsGroupDPS.tableBG[i]:SetHidden(true)
		end

		-- resize
		-- d((25*#data)-5)
		merlinsGroupDPS.tlw:SetDimensions(408,(20*#data)+37)
		merlinsGroupDPS.tableBG:SetDimensions(408,(20*#data)+37)

		-- fade out
		--merlinsGroupDPS.tlw:SetHidden(true)

		zo_callLater(hideTable, 12000) --12 s

end

local function HideTable()
	merlinsGroupDPS.tlw:SetHidden(true)
end

local function ResizeWind(var)
	merlinsGroupDPS.tlw:SetDimensions(408,(20*var)+37)
	merlinsGroupDPS.tableBG:SetDimensions(408,(20*var)+37)

	for i = 1 , var do
		merlinsGroupDPS.tableBG[i]:SetHidden(false)
	end
	-- clean up table
	for i = (var+1) , 12 do
		merlinsGroupDPS.tableBG[i]:SetHidden(true)
	end

	merlinsGroupDPS.tlw:SetHidden(false)
end

local function SetTimer()
	local secounds = 5 * 60
	merlinsGroupDPS.timertime = secounds + (GetGameTimeMilliseconds() / 1000)
	-- d("Set Timer")

end

EVENT_MANAGER:RegisterForEvent(merlinsGroupDPS.name, EVENT_ADD_ON_LOADED, merlinsGroupDPS.OnAddOnLoaded);

SLASH_COMMANDS["/test"] = ResizeWind
SLASH_COMMANDS["/hide"] = HideTable
SLASH_COMMANDS["/settimer"] = SetTimer
