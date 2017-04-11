-- #############################
-- settings...
-- #############################

function MerlinsRaidHelper.CreateSettingsMenu()
	local colorYellow = "|cFFFF22"

	local panelData = {
		type = "panel",
		name = "Merlins Raid Helper",
		displayName = colorYellow.."Merlin's|r Raid Helper",
		author = "@Just_Merlin",
		version = MerlinsRaidHelper.version,
		slashCommand = "/MerlinsRaidHelper",
		registerForRefresh = true,
		registerForDefaults = true,
	}

	local cntrlOptionsPanel = MerlinsRaidHelper.LAM2:RegisterAddonPanel("MerlinsRaidHelper_Options", panelData)

	local optionsData = {
		[1] = {
			type = "description",
			text = colorYellow.."Table Settings|r ",
		},
		[2] = {
			type = "slider",
			name =  GetString(LOCALES_OPACITY),
			tooltip = GetString(LOCALES_OPACITY_TP),
			min = 0,
			max = 100,
			step = 50,
			default = 100,
			getFunc = function() return MerlinsRaidHelper.savedVariables.userOPACITY end,
			setFunc = function(iValue)
									PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_JOINED)
									MerlinsRaidHelper.savedVariables.userOPACITY = iValue
                  -- a change as to update opacity...
									MerlinsRaidHelper:UpdateOpacity()
								end,
		},
		[3] = {
			type = "checkbox",
			name = GetString(LOCALES_SHOW_TABLE),
			tooltip = GetString(LOCALES_SHOW_TABLE_TP),
			default = false,
			getFunc = function() return MerlinsRaidHelper.savedVariables.userSHOWTABLE end,
			setFunc = function(bValue)
									PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_JOINED)
									MerlinsRaidHelper.savedVariables.userSHOWTABLE = bValue
                  -- a change has (evt) to hide the table
									if (bValue == false) then
										MerlinsRaidHelper:HideTable()
									end
								end
		},
    -- show and hide button
		[4] = {
			type = "description",
			text = colorYellow.."Test Options|r",
		},
		[5] = {
    	type = "button",
    	name = "Show",
    	tooltip = "Show table to replace and test color.",
    	func = function() MerlinsRaidHelper:ShowTable() end,
    	width = "half",
    },
    [6] = {
    	type = "button",
    	name = "Hide",
    	tooltip = "Hide table.",
    	func = function() MerlinsRaidHelper:HideTable() end,
    	width = "half",
    }
	}

	MerlinsRaidHelper.LAM2:RegisterOptionControls("MerlinsRaidHelper_Options", optionsData)
end
