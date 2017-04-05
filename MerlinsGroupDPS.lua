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
		merlinsGroupDPS.inCombat = inCombat
		if inCombat then
			-- entering combat
			-- d("Start combat")
			--merlinsGroupDPS.timestart = GetTimeStamp()
			--merlinsGroupDPS.dd = 0

		else
			-- exiting combat
			d("Left combat")
			merlinsGroupDPS:SendPing()

		end
	end
end


function merlinsGroupDPS.OnPing( eventCode, pingEventType, pingType, pingTag, offsetX, offsetY , isOwner )

	if ( pingType == MAP_PIN_TYPE_PING ) then
		if ( offsetX == 0 and offsetY == 0 ) then return end

		local name		= GetUnitName( pingTag )
		local time 		= offsetX * 10000
		local dps 		= offsetY * 200000
		local damage	= dps * time

		-- Only accept pings within a reasonable range
		if ( ( dps < 0 or dps > 100000 ) or ( time < 2 or time > 1200 ) ) then return end

		d("DMG: "..damage.." Time: "..time.." DPS: "..dps)

	end


-- Display control
--FTC.Stats:DisplayGroupDPS()

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

    if string.lower(message) == "showdps" and from ~= nil and from ~= "" then
			merlinsGroupDPS:SendToChat()
    end

		if string.lower(message) == "showinit" and from ~= nil and from ~= "" then
			merlinsGroupDPS:SendInitToChat()
    end

		if string.lower(message) == "showping" and from ~= nil and from ~= "" then
			merlinsGroupDPS:SendPing()
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
	CHAT_SYSTEM:StartTextEntry("◯ M's Group DPS is ready to use! ◯")

end

function merlinsGroupDPS:SendPing()

	local time = merlinsGroupDPS:GetSec()
	local dps = merlinsGroupDPS:GetDps(sec) -- get k (1000)

	-- Compute map ping offsets
	local timeCoord 	= time/10000
	local dpsCoord		= dps/200000

	-- Send the ping
	PingMap( MAP_PIN_TYPE_PING , MAP_TYPE_LOCATION_CENTERED , timeCoord , dpsCoord )

	-- d("Ping Posted")

end



EVENT_MANAGER:RegisterForEvent(merlinsGroupDPS.name, EVENT_ADD_ON_LOADED, merlinsGroupDPS.OnAddOnLoaded);
