local Transmog = _G.Transmog
local tonumber, hooksecurefunc = tonumber, hooksecurefunc

local PREFIX = Transmog.prefix
local STATUS_LINE = "|cfff471f5Appearance not collected|r"
local STATUS_COLLECTED = 1
local STATUS_UNCOLLECTED = 2
local STATUS_INELIGIBLE = 3

-- Keep tooltip results for the current session and avoid duplicate requests while waiting.
local statusByItem = {}
local pendingByItem = {}
local hookedTooltips = {}

-- Extract the template entry from a standard WotLK item hyperlink.
local function getItemId(link)
    if not link then
        return nil
    end

    return tonumber(string.match(link, "item:(%d+)"))
end

local function getTooltipItemId(tooltip)
    local _, link = tooltip:GetItem()
    return getItemId(link)
end

local function clearTooltipState(tooltip)
    tooltip.TransmogCollectionItemId = nil
    tooltip.TransmogCollectionLineAdded = nil
end

local function addStatusLine(tooltip, itemId)
    if not tooltip:IsShown() or tooltip.TransmogCollectionItemId ~= itemId or tooltip.TransmogCollectionLineAdded then
        return
    end

    tooltip:AddLine(STATUS_LINE)
    tooltip.TransmogCollectionLineAdded = true
    tooltip:Show()
end

-- Ask the server only when this item has no cached result and no request is pending.
local function requestStatus(itemId)
    if not itemId or statusByItem[itemId] ~= nil or pendingByItem[itemId] then
        return
    end

    pendingByItem[itemId] = true
    SendAddonMessage(PREFIX, "GetCollectionStatus:" .. itemId, "WHISPER", UnitName("player"))
end

-- Inspect a populated tooltip and apply a cached result or start a server lookup.
local function updateTooltip(tooltip)
    local itemId = getTooltipItemId(tooltip)
    if not itemId then
        return
    end

    if tooltip.TransmogCollectionItemId == itemId and tooltip.TransmogCollectionLineAdded then
        return
    end

    tooltip.TransmogCollectionItemId = itemId
    tooltip.TransmogCollectionLineAdded = false
    local status = statusByItem[itemId]
    if status == STATUS_UNCOLLECTED then
        addStatusLine(tooltip, itemId)
    elseif status == nil then
        requestStatus(itemId)
    end
end

-- Server response states: 0 = uncollected, 1 = collected, 2 = ineligible.
local function handleCollectionStatus(message)
    local itemId, state = string.match(message, "^CollectionStatus:(%d+):(%d+)$")
    itemId = tonumber(itemId)
    state = tonumber(state)
    if not itemId or not state or state < 0 or state > 2 then
        return
    end

    pendingByItem[itemId] = nil
    if state == 0 then
        statusByItem[itemId] = STATUS_UNCOLLECTED
    elseif state == 1 then
        statusByItem[itemId] = STATUS_COLLECTED
    else
        statusByItem[itemId] = STATUS_INELIGIBLE
    end

    if state ~= 0 then
        return
    end

    for tooltip in pairs(hookedTooltips) do
        if tooltip.TransmogCollectionItemId == itemId then
            addStatusLine(tooltip, itemId)
        end
    end
end

-- Newly equipped appearances are reported by the server so stale client results are corrected.
local function handleCollectionUpdated(message)
    local itemId = tonumber(string.match(message, "^CollectionUpdated:(%d+)$"))
    if not itemId then
        return
    end

    pendingByItem[itemId] = nil
    statusByItem[itemId] = STATUS_COLLECTED
end

-- Use Blizzard's tooltip hooks so existing tooltip owners, layout, and styling remain untouched.
local function hookTooltip(tooltip)
    if not tooltip or hookedTooltips[tooltip] then
        return
    end

    hookedTooltips[tooltip] = true
    tooltip:HookScript("OnTooltipSetItem", function(self)
        updateTooltip(self)
    end)
    tooltip:HookScript("OnHide", function(self)
        clearTooltipState(self)
    end)
    tooltip:HookScript("OnShow", function(self)
        local itemId = self.TransmogCollectionItemId
        if itemId and statusByItem[itemId] == STATUS_UNCOLLECTED then
            addStatusLine(self, itemId)
        end
    end)
end

-- SetItemRef covers item links opened from chat and other reference-tooltip paths.
hooksecurefunc("SetItemRef", function(link)
    local itemId = tonumber(string.match(link or "", "item:(%d+)"))
    if itemId then
        updateTooltip(ItemRefTooltip)
    end
end)

for _, tooltipName in ipairs({
    "GameTooltip",
    "ItemRefTooltip",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "ShoppingTooltip3",
    "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2",
    "ItemRefShoppingTooltip3"
}) do
    hookTooltip(_G[tooltipName])
end

-- Receive server responses and clear transient state when the character or equipment changes.
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
end

frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "CHAT_MSG_ADDON" then
        if arg1 ~= PREFIX then
            return
        end

        if string.sub(arg2, 1, 17) == "CollectionStatus:" then
            handleCollectionStatus(arg2)
        elseif string.sub(arg2, 1, 18) == "CollectionUpdated:" then
            handleCollectionUpdated(arg2)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_EQUIPMENT_CHANGED" then
        statusByItem = {}
        pendingByItem = {}
    end
end)
