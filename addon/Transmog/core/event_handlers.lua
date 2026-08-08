local Transmog = _G.Transmog
local TransmogFrame_Find = string.find
local TransmogFrame_ToNumber = tonumber

Transmog:RegisterEvent("GOSSIP_SHOW")
Transmog:RegisterEvent("GOSSIP_CLOSED")
Transmog:RegisterEvent("UNIT_INVENTORY_CHANGED")
Transmog:RegisterEvent("CHAT_MSG_ADDON")

Transmog:SetScript("OnEvent", function()

    if event then
        if event == "GOSSIP_SHOW" then
            if Transmog.serverRequestsOverlay then
                Transmog.serverRequestsOverlay = nil

                if Transmog.delayedLoad:IsVisible() then
                    twfdebug("Transmog addon loading retry in 5s.")
                else
                    HideUIPanel(GossipFrame)
                    TransmogFrame:Show()
                end
            end
            return
        end
        if event == "GOSSIP_CLOSED" then
            TransmogFrame:Hide()
            return
        end
        if event == "UNIT_INVENTORY_CHANGED" then

            twfdebug(event)

            if Transmog:EquippedItemsChanged() then

                twfdebug("equipped items changed")

                if TransmogFrame:IsVisible() then
                    twfdebug("visible")
                    Transmog.gearChangedDelay.delay = 1
                else
                    twfdebug("not visible")
                    Transmog.gearChangedDelay.delay = 2
                end
                Transmog:LockPlayerItems()
                Transmog.gearChangedDelay:Show()

            else
                twfdebug("equipped items not changed")
            end

            return
        end
        if event == 'CHAT_MSG_ADDON' then

            if arg1 == "TW_CHAT_MSG_WHISPER" then
                local message = arg2
                local from = arg4
                if string.find(message, 'INSShowTransmogs', 1, true) then
                    SendAddonMessage("TW_CHAT_MSG_WHISPER<" .. from .. ">", "INSTransmogs:start", "GUILD")
                    for InventorySlotId, itemID in pairs(Transmog.transmogStatusFromServer) do
                        if itemID ~= 0 then

                            local TransmogItemName = GetItemInfo(itemID)

                            if TransmogItemName then
                                -- check if we actually have an item equipped
                                if GetInventoryItemLink('player', InventorySlotId) then
                                    local _, _, eqItemLink = TransmogFrame_Find(GetInventoryItemLink('player', InventorySlotId), "(item:%d+:%d+:%d+:%d+)");
                                    local eName = GetItemInfo(eqItemLink)
                                    SendAddonMessage("TW_CHAT_MSG_WHISPER<" .. from .. ">", "INSTransmogs:" .. eName .. ":" .. TransmogItemName, "GUILD")
                                end
                            end
                        end
                    end
                    SendAddonMessage("TW_CHAT_MSG_WHISPER<" .. from .. ">", "INSTransmogs:end", "GUILD")
                end
                return
            end

			if TransmogFrame_Find(arg1, Transmog.prefix, 1, true) then

				twfdebug("CHAT_MSG_ADDON " .. arg2)
				local message = arg2

				if TransmogFrame_Find(message, "Open", 1, true) then
					-- Server requests the transmog UI to open.
					Transmog.serverRequestsOverlay = true
					return
				end

				if TransmogFrame_Find(message, "AvailableTransmogs", 1, true) then

					-- Format: AvailableTransmogs:slot:class+subclass:amount:start|id1:id2:...|end

					local ex = TransmogFrame_Explode(message, ":")

					local slot = TransmogFrame_ToNumber(ex[2])+1
					local itemClass = TransmogFrame_ToNumber(ex[3])
					local amount = TransmogFrame_ToNumber(ex[4])

					if not Transmog.numTransmogs[slot] then
						Transmog.numTransmogs[slot] = {}
					end

					Transmog.numTransmogs[slot][itemClass] = amount

					if TransmogFrame_Find(ex[5], "start", 1, true) then
						if not Transmog.transmogDataFromServer[slot] then
							Transmog.transmogDataFromServer[slot] = {}
						end
						Transmog.transmogDataFromServer[slot][itemClass] = {}
					elseif TransmogFrame_Find(ex[5], "end", 1, true) then
						Transmog:prepareAvailableTransmogs(slot, itemClass)
					else
						for i, itemID in ipairs(ex) do
							if i > 4 then
								itemID = TransmogFrame_ToNumber(itemID)
								if itemID ~= 0 then
									Transmog:cacheItem(itemID)

									table.insert(Transmog.transmogDataFromServer[slot][itemClass], itemID)
								end
							end
						end
					end
					return
				end
				if TransmogFrame_Find(message, "TransmogStatus", 1, true) then

					-- Format: TransmogStatus:amount:slot1,itemID1:slot2,itemID2:...

					local dataEx = TransmogFrame_Explode(message, ":")
					if dataEx[2] then
						Transmog.transmogStatusFromServer = {}
						Transmog.transmogStatusToServer = {}

						for _, InventorySlotId in pairs(Transmog.inventorySlots) do
							Transmog.transmogStatusFromServer[InventorySlotId] = 0
							Transmog.transmogStatusToServer[InventorySlotId] = 0
						end

						local amount = TransmogFrame_ToNumber(dataEx[2])
						if amount > 0 then
							for i, d in ipairs(dataEx) do
								if i > 2 then
									local slotStatus = TransmogFrame_Explode(d, ",")
									local InventorySlotId = TransmogFrame_ToNumber(slotStatus[1])+1
									local itemID = TransmogFrame_ToNumber(slotStatus[2])
									Transmog.transmogStatusFromServer[InventorySlotId] = itemID
									Transmog.transmogStatusToServer[InventorySlotId] = itemID
									if TransmogFrame_ToNumber(itemID) ~= 0 then
										Transmog:cacheItem(itemID)
									end
								end
							end
						end
                        Transmog:RefreshPendingGlows()
                        Transmog:transmogStatus()
					end
					return
				end
				if TransmogFrame_Find(message, "NewTransmog", 1, true) then
					-- Format: NewTransmog:itemID
					local dataEx = TransmogFrame_Explode(message, "NewTransmog:")
					twfdebug("NewaTransmog " .. dataEx[2])
					if string.find(message, "|r") then
						twfdebug("1message: [" .. message .. "] contains r")
					end
					if string.find(message, "|r", 1, true) then
						twfdebug("2message: [" .. message .. "] contains r")
					end
					if dataEx[2] and TransmogFrame_ToNumber(dataEx[2]) then
						twfdebug("new transmog " .. dataEx[2])
						Transmog:addWonItem(TransmogFrame_ToNumber(dataEx[2]))
					else
						twfdebug("new transmog not number :[" .. dataEx[2] .. "]")
					end
					return
				end
				if TransmogFrame_Find(message, "TransmogCost", 1, true) then

					-- Format: TransmogCost:cost:canPurchase
					local dataEx = TransmogFrame_Explode(message, ":")
					if dataEx[2] and dataEx[3] then
						local cost = TransmogFrame_ToNumber(dataEx[2])
						local canPurchase = TransmogFrame_ToNumber(dataEx[3])
						Transmog:updateCost(cost, canPurchase)
					end
					return
				end
				if TransmogFrame_Find(message, "ApplyTransmogResult", 1, true) then

					-- Format: ApplyTransmogResult:success:slot1,itemID1:slot2,itemID2:...

					local dataEx = TransmogFrame_Explode(message, ":")
					if dataEx[2] then
						local success = TransmogFrame_ToNumber(dataEx[2])
						local data = {}
						if dataEx[3] then
							for i, str in ipairs(dataEx) do
								if i > 2 then
									local ex = TransmogFrame_Explode(str, ",")
									if ex[1] and ex[2] then
										local slot = TransmogFrame_ToNumber(ex[1])+1
										local itemID = TransmogFrame_ToNumber(ex[2])
										table.insert(data, {slot, itemID})
									end
								end
							end
						end

						Transmog:ApplyTransmogResult(success, data)
					end
					return
				end
				return
			end
        end
    end
end)
