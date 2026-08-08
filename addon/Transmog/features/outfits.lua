local Transmog = _G.Transmog
local TransmogFrame_Find = string.find

-- Populates the outfits dropdown menu with all saved outfits.
function OutfitsDropDown_Initialize()

    for name, data in pairs(transmogOutfits) do
        local info = {}
        info.text = name
        info.value = 1
        info.arg1 = name
        info.checked = Transmog.currentOutfit == name
        info.func = Transmog_LoadOutfit
        info.tooltipTitle = name
        local descText = ''
        for slot, itemID in pairs(data) do
            if itemID == 0 then
            else
				Transmog:cacheItem(itemID)
                local n, _, quality, _, _, _, _, _, equip_slot = GetItemInfo(itemID)

                if quality == nil then quality = 0 end

                if n == nil then n = "error" end

                local _, _, _, color = GetItemQualityColor(quality)

                descText = descText .. FONT_COLOR_CODE_CLOSE .. color .. n .. "\n"
            end
        end
        info.tooltipText = descText
        UIDropDownMenu_AddButton(info)
    end

    if Transmog:tableSize(transmogOutfits) < 20 then
        local _, _, _, color = GetItemQualityColor(2)

        local newOutfit = {}
        newOutfit.text = color .. "+ New Outfit"
        newOutfit.value = 1
        newOutfit.arg1 = 1
        newOutfit.checked = false
        newOutfit.func = Transmog_NewOutfitPopup
        UIDropDownMenu_AddButton(newOutfit)
    end

end

-- Uses the server-filtered appearance bucket to keep saved outfits aligned with
-- the active transmog configuration and the item currently equipped in a slot.
function Transmog:IsOutfitAppearanceCompatible(slot, itemID)
    if itemID == 0 then
        return true
    end

    if itemID == self.HIDDEN_ITEM_ID then
        return self.hideableSlots[slot] == true
    end

    local equippedLink = GetInventoryItemLink('player', slot)
    if not equippedLink then
        return false
    end

    local _, _, _, _, _, itemClass, itemSubclass = GetItemInfo(equippedLink)
    if not itemClass or not itemSubclass then
        return false
    end

    local bucket = self:ItemClassStrToNum(itemClass) + self:ItemSubclassStrToNum(itemSubclass)
    local slotData = self.transmogDataFromServer[slot]
    local appearances = slotData and slotData[bucket]
    if not appearances then
        return false
    end

    for _, appearanceID in ipairs(appearances) do
        if tonumber(appearanceID) == itemID then
            return true
        end
    end

    return false
end

-- Loads a saved outfit's transmog selections onto all equipment slots.
function Transmog_LoadOutfit(self, outfit)
    UIDropDownMenu_SetText(TransmogFrameOutfits, outfit)

    Transmog.currentOutfit = outfit

    Transmog:EnableOutfitSaveButton()

    TransmogFrameDeleteOutfit:Enable()

    Transmog:hideItemBorders()

    for slot, itemID in pairs(transmogOutfits[outfit]) do

        if not Transmog:IsOutfitAppearanceCompatible(slot, itemID) then
            twfdebug("Skipping incompatible outfit appearance " .. itemID .. " for slot " .. slot)
        else

        local eq_slot, tex
        local hasItemEquipped = false

        if GetInventoryItemLink('player', slot) then
            hasItemEquipped = true
        end

        if hasItemEquipped then

            if itemID == 0 then
                local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', slot), "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, equip_slot, outfitTex = GetItemInfo(eqItemLink)
                eq_slot = equip_slot
                tex = outfitTex
            else
                local _, _, _, _, _, _, _, _, equip_slot, outfitTex = GetItemInfo(itemID)
                eq_slot = equip_slot
                tex = outfitTex
            end

            local frame

            frame = Transmog:frameFromInvType(eq_slot, slot)

            if hasItemEquipped then
                TransmogFramePlayerModel:TryOn(itemID)
            end

            if frame then

                getglobal(frame:GetName() .. "ItemIcon"):SetTexture(tex)

                if Transmog.transmogStatusToServer[slot] ~= itemID then
                    getglobal(frame:GetName() .. 'BorderHi'):Show()
                    getglobal(frame:GetName() .. 'AutoCast'):SetAlpha(0.3)
                end

                if itemID == 0 or not hasItemEquipped then
                    getglobal(frame:GetName() .. 'BorderHi'):Hide()
                    getglobal(frame:GetName() .. 'AutoCast'):Hide()
                end

            end

            Transmog.transmogStatusToServer[slot] = itemID
            if frame then
                Transmog:UpdateSlotGlow(frame:GetName(), slot)
            end
        end

        end

    end
    Transmog:calculateCost()
end

-- Saves the current transmog selections as a saved outfit.
function Transmog_SaveOutfit()
	transmogOutfits[Transmog.currentOutfit] = {}
    for InventorySlotId, itemID in pairs(Transmog.transmogStatusFromServer) do
        if itemID ~= 0 then
            transmogOutfits[Transmog.currentOutfit][InventorySlotId] = itemID
        end
    end
    for InventorySlotId, itemID in pairs(Transmog.transmogStatusToServer) do
        if itemID ~= 0 then
            transmogOutfits[Transmog.currentOutfit][InventorySlotId] = itemID
        end
    end
    TransmogFrameSaveOutfit:Disable()
end

-- Enables the save outfit button when an outfit is currently selected.
function Transmog:EnableOutfitSaveButton()
    if self.currentOutfit ~= nil then
        TransmogFrameSaveOutfit:Enable()
    end
end

-- Deletes the currently selected outfit.
function Transmog_deleteOutfit()
    transmogOutfits[Transmog.currentOutfit] = nil
    TransmogFrameSaveOutfit:Disable()
    TransmogFrameDeleteOutfit:Disable()
    Transmog.currentOutfit = nil
    UIDropDownMenu_SetText(TransmogFrameOutfits, "Outfits")
    Transmog_revert()
end

StaticPopupDialogs["TRANSMOG_NEW_OUTFIT"] = {
    text = "Enter Outfit Name:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function()
        local outfitName = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        if outfitName == '' then
            StaticPopup_Show('TRANSMOG_OUTFIT_EMPTY_NAME')
            return
        end
        if transmogOutfits[outfitName] then
            StaticPopup_Show('TRANSMOG_OUTFIT_EXISTS')
            return
        end
        transmogOutfits[outfitName] = {}
        UIDropDownMenu_SetText(TransmogFrameOutfits, outfitName)
        Transmog.currentOutfit = outfitName
        Transmog:EnableOutfitSaveButton()
        Transmog_SaveOutfit()
        getglobal(this:GetParent():GetName() .. "EditBox"):SetText('')
    end,
    timeout = 0,
    whileDead = 0,
    hideOnEscape = 1,
};

StaticPopupDialogs["TRANSMOG_OUTFIT_EXISTS"] = {
    text = "Outfit Name already exists.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["TRANSMOG_OUTFIT_EMPTY_NAME"] = {
    text = "Outfit Name not valid.",
    button1 = "Okay",
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_DELETE_OUTFIT"] = {
    text = "Delete Outfit ?",
    button1 = TEXT(YES),
    button2 = TEXT(NO),
    OnAccept = function()
        Transmog_deleteOutfit()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
};

-- Shows the dialog for creating a new outfit.
function Transmog_NewOutfitPopup()
    StaticPopup_Show('TRANSMOG_NEW_OUTFIT')
end
