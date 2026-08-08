local Transmog = _G.Transmog
local TransmogFrame_Find = string.find
local TransmogFrame_ToNumber = tonumber

-- Updates the UI to reflect current transmog status from the server.
function Transmog:transmogStatus()
	twfdebug("TransmogStatus")

    for InventorySlotId, itemID in pairs(self.transmogStatusFromServer) do
		if itemID ~= 0 then

			if itemID == Transmog.HIDDEN_ITEM_ID then
				if GetInventoryItemLink('player', InventorySlotId) then
					local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
					local eName = GetItemInfo(eqItemLink)
					self.equippedTransmogs[eName] = "(Hidden)"
				end
			else

				local TransmogItemName = GetItemInfo(itemID)

				if TransmogItemName then
					if GetInventoryItemLink('player', InventorySlotId) then
						local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
						local eName = GetItemInfo(eqItemLink)
						self.equippedTransmogs[eName] = TransmogItemName
					end
				else
					twfdebug("Slot: "..InventorySlotId.. " itemID: " .. itemID)
					self:cacheItem(itemID)
				end
			end
        end
    end

    -- add paperdoll textures
    for slotName, InventorySlotId in pairs(self.inventorySlots) do
        local frame = getglobal(slotName)
        if frame then

            local texture
            local texEx = TransmogFrame_Explode(frame:GetName(), 'Slot')
            texture = string.lower(texEx[1])

            if texture == 'wrist' then
                texture = texture .. 's'
            end
            if texture == 'back' then
                texture = 'chest'
            end

            getglobal(frame:GetName() .. 'ItemIcon'):SetTexture('Interface\\Paperdoll\\ui-paperdoll-slot-' .. texture)
            getglobal(frame:GetName() .. 'NoEquip'):Show()
            getglobal(frame:GetName() .. 'BorderHi'):Hide()

            AddButtonOnEnterTextTooltip(frame, self.inventorySlotNames[InventorySlotId], "There is no equipped item in this slot", true)
        end
    end

    -- add item textures
    for slotName, InventorySlotId in pairs(self.inventorySlots) do
        self.equippedItems[InventorySlotId] = 0
        if GetInventoryItemLink('player', InventorySlotId) then

            local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
            local itemName, _, _, _, _, _, _, _, _, tex = GetItemInfo(eqItemLink)

            self.equippedItems[InventorySlotId] = self:IDFromLink(eqItemLink)

            local frame = getglobal(slotName)

            if frame then

                frame:Enable()
                frame:SetID(InventorySlotId)

                getglobal(frame:GetName() .. 'AutoCast'):Hide()
                getglobal(frame:GetName() .. 'AutoCast'):SetModel("Interface\\Buttons\\UI-AutoCastButton.mdx")
                getglobal(frame:GetName() .. 'AutoCast'):SetAlpha(0.3)

                getglobal(frame:GetName() .. 'NoEquip'):Hide()

                getglobal(frame:GetName() .. 'Revert'):Hide()

                if self.transmogStatusFromServer[InventorySlotId] and self.transmogStatusFromServer[InventorySlotId] ~= 0 then
                    getglobal(frame:GetName() .. 'BorderHi'):Show()

                    if self.transmogStatusFromServer[InventorySlotId] == Transmog.HIDDEN_ITEM_ID then
                        AddButtonOnEnterTooltipFashion(frame, eqItemLink, "(Hidden)", true)

                        local emptyTexture = string.lower(TransmogFrame_Explode(slotName, 'Slot')[1])
                        if emptyTexture == 'wrist' then
                            emptyTexture = emptyTexture .. 's'
                        end
                        if emptyTexture == 'back' then
                            emptyTexture = 'chest'
                        end
                        getglobal(frame:GetName() .. 'ItemIcon'):SetTexture('Interface\\Paperdoll\\ui-paperdoll-slot-' .. emptyTexture)
                    else
                        AddButtonOnEnterTooltipFashion(frame, eqItemLink, self.equippedTransmogs[itemName], true)

                        local _, _, _, _, _, _, _, _, _, TransmogTex = GetItemInfo(self.transmogStatusFromServer[InventorySlotId])

                        getglobal(frame:GetName() .. 'ItemIcon'):SetTexture(TransmogTex)
                    end

                    getglobal(frame:GetName() .. 'Revert'):Show()
                else
                    getglobal(frame:GetName() .. 'BorderHi'):Hide()
                    AddButtonOnEnterTooltipFashion(frame, eqItemLink)
                    getglobal(frame:GetName() .. 'ItemIcon'):SetTexture(tex)
                end
            end
        end
    end

    self:calculateCost()
end

-- Sends all pending transmog changes to the server.
function Apply_OnClick()

    local pending = 0
    for InventorySlotId, itemID in pairs(Transmog.transmogStatusToServer) do
        if Transmog.transmogStatusFromServer[InventorySlotId] ~= itemID then
            pending = pending + 1
        end
    end
    Transmog.pendingApplyCount = pending

    TransmogFrameApplyButton:Disable()

    for InventorySlotId, itemID in pairs(Transmog.transmogStatusToServer) do
        if Transmog.transmogStatusFromServer[InventorySlotId] ~= itemID then
            if itemID ~= 0 then
                Transmog:aSend("Apply:" .. (InventorySlotId - 1) .. ":" .. itemID)
            else
                Transmog:aSend("Remove:" .. (InventorySlotId - 1))
            end
        end
    end
end

-- Handles the server response after applying transmog changes.
function Transmog:ApplyTransmogResult(success, data)

	twfdebug("ApplyTransmogResult success: "..success)

	if success == 1 then
		for i, pair in ipairs(data) do
			local slot = pair[1]
			local itemID = pair[2]
			if itemID == 0 then
				Transmog:addTransmogAnim(slot, 'reset')
			else
				Transmog:addTransmogAnim(slot)
			end

			Transmog.transmogStatusFromServer[slot] = itemID
			Transmog.transmogStatusToServer[slot] = itemID
        end

        Transmog:RefreshPendingGlows()
        Transmog.pendingApplyCount = Transmog.pendingApplyCount - 1
        if Transmog.pendingApplyCount <= 0 then
			PlaySoundFile("Interface\\AddOns\\Transmog\\assets\\ui_transmogrify_apply.ogg", "Dialog");
			Transmog:transmogStatus()
		end
	end
end
