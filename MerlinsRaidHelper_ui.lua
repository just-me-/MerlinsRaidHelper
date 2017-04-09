function MerlinsRaidHelper:SetupInterface()

		MerlinsRaidHelper.wm = GetWindowManager()
		MerlinsRaidHelper.tlw = MerlinsRaidHelper.wm:CreateTopLevelWindow("ccTLW")

		MerlinsRaidHelper.tlw:SetDimensions(MerlinsRaidHelper.tablewidth,20*12+37)
		MerlinsRaidHelper.tlw:SetResizeToFitDescendents(true)
		MerlinsRaidHelper.tlw:SetAnchor(RIGHT, GuiRoot, RIGHT, -10, -100)

		MerlinsRaidHelper.tlw:SetMovable(true)
		MerlinsRaidHelper.tlw:SetMouseEnabled(true)
		-- tlw:SetHandler("OnClicked", tlwClicked)

		MerlinsRaidHelper.tableBG = MerlinsRaidHelper.wm:CreateControl("tableBG", MerlinsRaidHelper.tlw, CT_BACKDROP)
		MerlinsRaidHelper.tableBG:SetEdgeColor(0.4,0.4,0.4, 0.1)
		MerlinsRaidHelper.tableBG:SetCenterColor(0.2,0.2,0.2,1)
		MerlinsRaidHelper.tableBG:SetAnchor(TOPLEFT, MerlinsRaidHelper.tlw, TOPLEFT, 0, 0)
		MerlinsRaidHelper.tableBG:SetDimensions(MerlinsRaidHelper.tablewidth,20*12+37)
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


function MerlinsRaidHelper:UIRow(id, height, left, top)

		local tableBG = {}
		MerlinsRaidHelper.tableBG[id] = MerlinsRaidHelper.wm:CreateControl("rowBackDrop"..id, MerlinsRaidHelper.tlw, CT_BACKDROP)
		MerlinsRaidHelper.tableBG[id]:SetAnchor(TOPLEFT, MerlinsRaidHelper.tlw, TOPLEFT, left-5, top)
		MerlinsRaidHelper.tableBG[id]:SetDimensions(390+7,height)
		if (id%2 == 0) then
			MerlinsRaidHelper.tableBG[id]:SetEdgeColor(0.1,0.1,0.1)
			MerlinsRaidHelper.tableBG[id]:SetCenterColor(0.1,0.1,0.1)
		else
			MerlinsRaidHelper.tableBG[id]:SetEdgeColor(0.1,0.1,0.1,0.001)
			MerlinsRaidHelper.tableBG[id]:SetCenterColor(0.1,0.1,0.1,0.001)
		end

		MerlinsRaidHelper:UILabel(id, "Player", 140, height, left, top)
		MerlinsRaidHelper:UILabel(id, "Time", 75, height, left+140, top, true)
		MerlinsRaidHelper:UILabel(id, "Damage", 100, height, left+140+75, top, true)
		MerlinsRaidHelper:UILabel(id, "DPS", 75, height, left+140+75+100, top, true)

end

function MerlinsRaidHelper:UILabel(id, text, width, height, left, top, align_right)

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

	if(align_right) then
		MerlinsRaidHelper.field[id..tag]:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
	end

end


function MerlinsRaidHelper:UIReloadTable()

		-- sort data
		local data = {}
		-- d(MerlinsRaidHelper.groupDPSdatas)
		for player , damage in pairs(MerlinsRaidHelper.groupDPSdatas) do
			table.insert(data,damage)
		end
		table.sort(data, MerlinsRaidHelper.compare)
		 --d(data)

		-- visibility
		MerlinsRaidHelper.tlw:SetHidden(false)
		if ( #data == 0 ) then MerlinsRaidHelper.tlw:SetHidden(true) end

		-- insert rows
		for i = 1 , #data do
			MerlinsRaidHelper.field[i.."Player"]:SetText(data[i].name)
			MerlinsRaidHelper.field[i.."Damage"]:SetText((FormatIntegerWithDigitGrouping(data[i].damage,"'")))
			MerlinsRaidHelper.field[i.."DPS"]:SetText((FormatIntegerWithDigitGrouping(data[i].dps,"'")))
			MerlinsRaidHelper.field[i.."Time"]:SetText(data[i].time.."s")
			MerlinsRaidHelper.tableBG[i]:SetHidden(false)
		end
		-- clean up table
		for i = (#data+1) , 12 do
			MerlinsRaidHelper.tableBG[i]:SetHidden(true)
		end

		-- resize
		-- d((25*#data)-5)
		MerlinsRaidHelper.tlw:SetDimensions(MerlinsRaidHelper.tablewidth,(20*#data)+37)
		MerlinsRaidHelper.tableBG:SetDimensions(MerlinsRaidHelper.tablewidth,(20*#data)+37)

		-- fade out
		--MerlinsRaidHelper.tlw:SetHidden(true)

		zo_callLater(MerlinsRaidHelper.HideTable, 12000) --12 s

end

-- used by UIReloadTable
function MerlinsRaidHelper.compare(x,y)
	return x.damage > y.damage
end
