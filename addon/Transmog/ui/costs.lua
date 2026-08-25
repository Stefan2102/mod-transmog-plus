local Transmog = _G.Transmog

local currencyTextLayoutConfigured = false

local function ConfigureCurrencyTextLayout()
    if currencyTextLayoutConfigured then
        return
    end

    TransmogFrameCurrencyText:ClearAllPoints()
    TransmogFrameCurrencyText:SetWidth(100)
    TransmogFrameCurrencyText:SetHeight(14)
    TransmogFrameCurrencyText:SetPoint("RIGHT", TransmogFrameApplyButton, "LEFT", -8, 0)
    TransmogFrameCurrencyText:SetJustifyH("RIGHT")

    currencyTextLayoutConfigured = true
end

-- Sends a cost calculation request to the server when transmog changes are pending.
function Transmog:calculateCost(to)

	twfdebug("Transmog:calculateCost")

	local slots = ""
    local transmogs = 0
    local resets = 0

    for InventorySlotId, data in pairs(self.transmogStatusFromServer) do
        if data ~= self.transmogStatusToServer[InventorySlotId] then
            if self.transmogStatusToServer[InventorySlotId] ~= 0 then
                transmogs = transmogs + 1
				slots = slots .. InventorySlotId-1 .. ":" .. self.transmogStatusToServer[InventorySlotId] .. ","
            else
                resets = resets + 1
            end
        end
    end

    if to == 0 then
        transmogs = 0
        resets = 0
    end

    if transmogs == 0 then
        if resets > 0 then
            TransmogFrameApplyButton:Enable()
            TransmogFrameApplyButton:SetText("Apply Reset")
        else
            TransmogFrameApplyButton:Disable()
            TransmogFrameApplyButton:SetText("Change any Items")
        end

		TransmogFrameCurrencyText:Hide()
    else
		self:aSend("CalculateCost:"..slots)
		TransmogFrameApplyButton:Disable()
    end
end

local function formatNumberWithCommas(amount)
    local formatted = tostring(amount)
    while true do
        local newFormatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        formatted = newFormatted
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Converts a copper amount into gold, silver, and copper values.
function formatCurrency(amount)
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount - gold * 10000) / 100)
    local copper = amount - gold * 10000 - silver * 100
    return copper, silver, gold
end

-- Updates the apply button text and cost display based on server response.
function Transmog:updateCost(cost, canPurchase)
    twfdebug("updateCost cost:" .. cost .. " canPurchase: " .. canPurchase)

    if canPurchase == 1 then
        TransmogFrameApplyButton:Enable()
        TransmogFrameApplyButton:SetText("Apply Transmog")
    else
        TransmogFrameApplyButton:Disable()
        TransmogFrameApplyButton:SetText("Not enough money")
    end

    if cost > 0 then
        ConfigureCurrencyTextLayout()
        TransmogFrameCurrencyText:Show()
        local copper, silver, gold = formatCurrency(cost)
        local costText = ""

        if gold > 0 then
            costText = formatNumberWithCommas(gold) .. "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
        end

        if silver > 0 and gold < 10000 then
            if costText ~= "" then
                costText = costText .. " "
            end
            costText = costText .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
        end

        if copper > 0 and gold < 100 then
            if costText ~= "" then
                costText = costText .. " "
            end
            costText = costText .. copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"
        end

        TransmogFrameCurrencyText:SetText(costText)
    end
end

-- Converts an item class string (e.g. "Weapon") to its numeric ID.
function Transmog:ItemClassStrToNum(itemClassStr)
	local itemClass = -1

	if itemClassStr then
		if itemClassStr == "Weapon" or itemClassStr == "Arma" then
			itemClass = 2
		elseif itemClassStr == "Armor" or itemClassStr == "Armadura" then
			itemClass = 4
		end
	end

	if itemClass == -1 then
		twferror("Invalid item class " .. itemClassStr)
	end

	return itemClass
end

-- Converts an item subclass string to its numeric ID, including localized names.
function Transmog:ItemSubclassStrToNum(itemSubclassStr)
	local itemSubclass = -1
	
	if itemSubclassStr then
		if itemSubclassStr == "One-Handed Axes" or itemSubclassStr == "Hachas de una mano" or itemSubclassStr == "Einhandäxte" then
			itemSubclass = 0
		elseif itemSubclassStr == "Two-Handed Axes" or itemSubclassStr == "Hachas de dos manos" or itemSubclassStr == "Zweihandäxte" then
			itemSubclass = 1
		elseif itemSubclassStr == "Bows" or itemSubclassStr == "Arcos" or itemSubclassStr == "Bögen" then
			itemSubclass = 2
		elseif itemSubclassStr == "Guns" or itemSubclassStr == "Armas de fuego" or itemSubclassStr == "Schusswaffen" then
			itemSubclass = 3
		elseif itemSubclassStr == "One-Handed Maces" or itemSubclassStr == "Mazas de una mano" or itemSubclassStr == "Einhandstreitkolben" then
			itemSubclass = 4
		elseif itemSubclassStr == "Two-Handed Maces" or itemSubclassStr == "Mazas de dos manos" or itemSubclassStr == "Zweihandstreitkolben" then
			itemSubclass = 5
		elseif itemSubclassStr == "Polearms" or itemSubclassStr == "Armas de asta" or itemSubclassStr == "Stangenwaffen" then
			itemSubclass = 6
		elseif itemSubclassStr == "One-Handed Swords" or itemSubclassStr == "Espadas de una mano" or itemSubclassStr == "Einhandschwerter" then
			itemSubclass = 7
		elseif itemSubclassStr == "Two-Handed Swords" or itemSubclassStr == "Espadas de dos manos" or itemSubclassStr == "Zweihandschwerter" then
			itemSubclass = 8
		elseif itemSubclassStr == "Staves" or itemSubclassStr == "Bastones" or itemSubclassStr == "Stäbe" then
			itemSubclass = 10
		elseif itemSubclassStr == "Fist Weapons" or itemSubclassStr == "Armas de puño" or itemSubclassStr == "Faustwaffen" then
			itemSubclass = 13
		elseif itemSubclassStr == "Daggers" or itemSubclassStr == "Dagas" or itemSubclassStr == "Dolche" then
			itemSubclass = 15
		elseif itemSubclassStr == "Crossbows" or itemSubclassStr == "Ballestas" or itemSubclassStr == "Armbrüste" then
			itemSubclass = 18
		elseif itemSubclassStr == "Wands" or itemSubclassStr == "Varitas" or itemSubclassStr == "Zauberstäbe" then
			itemSubclass = 19
		elseif itemSubclassStr == "Thrown" or itemSubclassStr == "Armas arrojadizas" or itemSubclassStr == "Wurfwaffen" then
	        itemSubclass = 20
		elseif itemSubclassStr == "Cloth" or itemSubclassStr == "Tela" or itemSubclassStr == "Stoff" then
			itemSubclass = 1
		elseif itemSubclassStr == "Leather" or itemSubclassStr == "Cuero" or itemSubclassStr == "Leder" then
			itemSubclass = 2
		elseif itemSubclassStr == "Mail" or itemSubclassStr == "Malla" or itemSubclassStr == "Kette" then
			itemSubclass = 3
		elseif itemSubclassStr == "Plate" or itemSubclassStr == "Placas" or itemSubclassStr == "Plattenrüstung" then
			itemSubclass = 4
		elseif itemSubclassStr == "Shields" or itemSubclassStr == "Escudos" or itemSubclassStr == "Schilde" then
			itemSubclass = 6
		elseif itemSubclassStr == "Miscellaneous" or itemSubclassStr == "Misceláneo" or itemSubclassStr == "Verschiedenes" then
			itemSubclass = 0
		end
	end
	
	if itemSubclass == -1 then
		twferror("Invalid item subclass " .. itemSubclassStr)
	end
	
	return itemSubclass
end

