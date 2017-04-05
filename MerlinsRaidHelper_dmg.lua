-- #############################
-- event functions
-- #############################

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


-- #############################
-- called functions
-- #############################

-- called by OnPlayerCombatState - on left
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
