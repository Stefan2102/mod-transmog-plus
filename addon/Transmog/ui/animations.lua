local Transmog = _G.Transmog
local TransmogFrame_Find = string.find
local GAME_YELLOW = "|cffffd200"
Transmog.slotGlowFrames = {}

-- Returns the native glow frame associated with an equipment slot.
function Transmog:GetSlotGlowFrame(slotName)
    local glow = self.slotGlowFrames[slotName]
    if glow then
        return glow
    end

    local anchor = getglobal(slotName)
    if not anchor then
        return nil
    end

    glow = CreateFrame("Frame", "Transmog" .. slotName .. "SlotGlow", anchor, "AutoCastShineTemplate")
    glow:SetFrameStrata("HIGH")
    glow:SetWidth(30)
    glow:SetHeight(30)
    glow:SetPoint("CENTER", anchor, "CENTER", -3, 2)
    glow:Hide()

    self.slotGlowFrames[slotName] = glow
    return glow
end

-- Shows the gold native glow for an active or modified equipment slot.
function Transmog:ShowSlotGlow(slotName)
    local glow = self:GetSlotGlowFrame(slotName)
    if glow then
        AutoCastShine_AutoCastStart(glow, 1, 0.82, 0.1)
        glow:Show()
    end
end

-- Hides the native glow for one equipment slot.
function Transmog:HideSlotGlow(slotName)
    local glow = self.slotGlowFrames[slotName]
    if glow then
        AutoCastShine_AutoCastStop(glow)
        glow:Hide()
    end
end

-- Updates the native glow from the local/server transmog state.
function Transmog:UpdateSlotGlow(slotName, slotId)
    local serverItem = self.transmogStatusFromServer[slotId]
    local localItem = self.transmogStatusToServer[slotId]
    if serverItem ~= nil and localItem ~= nil and serverItem ~= localItem then
        self:ShowSlotGlow(slotName)
    else
        self:HideSlotGlow(slotName)
    end
end

-- Reconciles all equipment-slot glows with pending transmog changes.
function Transmog:RefreshPendingGlows()
    for slotName, slotId in pairs(self.inventorySlots) do
        self:UpdateSlotGlow(slotName, slotId)
    end
end


-- Queues a slot for the apply/reset animation sequence.
function Transmog:addTransmogAnim(id, reset)
	twfdebug("addTransmogAnim id: "..id)

    for slotName, InventorySlotId in pairs(self.inventorySlots) do
        if id == InventorySlotId then
            local frame = getglobal(slotName)
            if frame then
                self.itemAnimationFrames[self:tableSize(self.itemAnimationFrames) + 1] = {
                    ['frame'] = frame,
                    ['borderHi'] = getglobal(frame:GetName() .. "BorderHi"),
                    ['borderFull'] = getglobal(frame:GetName() .. "BorderFull"),
                    ['autocast'] = getglobal(frame:GetName() .. "AutoCast"),
                    ['reset'] = reset,
                    ['dir'] = 1
                }
                break
            end
        end
    end

    if self:tableSize(self.itemAnimationFrames) == self:tableSize(self.applyTimer.actions) then
        self.itemAnimation:Show()
    end
end

-- Hides autocast animation overlays on all equipment slots.
function Transmog:HidePlayerItemsAnimation()
    HeadSlotAutoCast:Hide()
    ShoulderSlotAutoCast:Hide()
    BackSlotAutoCast:Hide()
    ChestSlotAutoCast:Hide()
    WristSlotAutoCast:Hide()
    HandsSlotAutoCast:Hide()
    WaistSlotAutoCast:Hide()
    LegsSlotAutoCast:Hide()
    FeetSlotAutoCast:Hide()
    MainHandSlotAutoCast:Hide()
    SecondaryHandSlotAutoCast:Hide()
    RangedSlotAutoCast:Hide()
    self:RefreshPendingGlows()
end

-- Hides selection borders while retaining state-based pending glows.
function Transmog:hidePlayerItemsBorders()
    HeadSlotBorderSelected:Hide()
    ShoulderSlotBorderSelected:Hide()
    BackSlotBorderSelected:Hide()
    ChestSlotBorderSelected:Hide()
    WristSlotBorderSelected:Hide()
    HandsSlotBorderSelected:Hide()
    WaistSlotBorderSelected:Hide()
    LegsSlotBorderSelected:Hide()
    FeetSlotBorderSelected:Hide()
    MainHandSlotBorderSelected:Hide()
    SecondaryHandSlotBorderSelected:Hide()
    RangedSlotBorderSelected:Hide()
    self:RefreshPendingGlows()
end

-- Disables and desaturates all player equipment slots during gear changes.
function Transmog:LockPlayerItems()
    for slot, _ in pairs(Transmog.inventorySlots) do
        getglobal(slot):Disable()
        SetDesaturation(getglobal(slot .. 'ItemIcon'), 1);
    end
end

Transmog.applyTimer = CreateFrame("Frame")
Transmog.applyTimer:Hide()

Transmog.applyTimer:SetScript("OnShow", function()
    this.startTime = GetTime()
    Transmog.applyTimer.actionIndex = 0
end)
Transmog.applyTimer:SetScript("OnHide", function()
end)

Transmog.applyTimer.actions = {}
Transmog.applyTimer.actionIndex = 0

Transmog.applyTimer:SetScript("OnUpdate", function()
    local plus = 0.1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        Transmog.applyTimer.actionIndex = Transmog.applyTimer.actionIndex + 1

        local action = Transmog.applyTimer.actions[Transmog.applyTimer.actionIndex]

        if action then
            if action.type == 'do' then
                Transmog:aSend("Apply:" .. action.serverSlot .. ":" .. action.itemId)
                action.sent = true
            else
                if action.type == 'reset' then
                    Transmog:aSend("Remove:" .. action.serverSlot)
                    action.sent = true
                end
            end
        end

        local allDone = true
        for _, action in ipairs(Transmog.applyTimer.actions) do
            if not action.sent then
                allDone = false
            end
        end
        if allDone then
            Transmog.applyTimer:Hide()
        end
        this.startTime = GetTime()
    end
end)

Transmog.itemAnimation = CreateFrame("Frame")
Transmog.itemAnimation:Hide()

Transmog.itemAnimation:SetScript("OnShow", function()
    this.startTime = GetTime()
    for _, frame in ipairs(Transmog.itemAnimationFrames) do
        frame.autocast:Hide()
        if frame.reset then
            frame.borderFull:Show()
            frame.borderFull:SetAlpha(.9)
            frame.borderHi:Show()
            frame.borderHi:SetWidth(48)
            frame.borderHi:SetHeight(48)
        else
            frame.borderFull:Show()
            frame.borderFull:SetAlpha(.2)
            frame.borderHi:Show()
            frame.borderHi:SetWidth(32)
            frame.borderHi:SetHeight(32)
        end
    end
end)
Transmog.itemAnimation:SetScript("OnHide", function()
    Transmog.currentTransmogSlot = nil
    Transmog_switchTab('items')

    Transmog:aSend("GetTransmogStatus")

    Transmog:calculateCost(0)
end)

Transmog.itemAnimationFrames = {}

Transmog.itemAnimation:SetScript("OnUpdate", function()
    local plus = 0.01
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        for index, frame in ipairs(Transmog.itemAnimationFrames) do
            if frame.reset then
                frame.borderFull:SetAlpha(frame.borderFull:GetAlpha() - 0.05)
                if frame.borderHi:GetWidth() > 32 then
                    frame.borderHi:SetWidth(frame.borderHi:GetWidth() - 0.5)
                    frame.borderHi:SetHeight(frame.borderHi:GetHeight() - 0.5)
                end
            else
                frame.borderFull:SetAlpha(frame.borderFull:GetAlpha() + 0.05 * frame.dir)
                if frame.borderHi:GetWidth() < 48 then
                    frame.borderHi:SetWidth(frame.borderHi:GetWidth() + 0.5)
                    frame.borderHi:SetHeight(frame.borderHi:GetHeight() + 0.5)
                end
            end
            if frame.borderFull:GetAlpha() >= 1 then
                frame.dir = -1
            end
            if frame.borderFull:GetAlpha() <= 0.1 then
                frame.borderHi:Hide()
                frame.borderHi:SetWidth(48)
                frame.borderHi:SetHeight(48)

                Transmog.itemAnimationFrames[index] = nil
            end
        end

        if Transmog:tableSize(Transmog.itemAnimationFrames) == 0 then
            Transmog.itemAnimation:Hide()
        end

        this.startTime = GetTime()

    end
end)

Transmog.delayedLoad = CreateFrame("Frame")
Transmog.delayedLoad:Hide()

Transmog.delayedLoad:SetScript("OnShow", function()
    twfdebug("delayedLoad show")
    this.startTime = GetTime()
end)
Transmog.delayedLoad:SetScript("OnHide", function()
    Transmog:LoadOnce()
    Transmog:Reset(true)
end)

Transmog.delayedLoad:SetScript("OnUpdate", function()
    local gt = GetTime() * 1000
    local st = (this.startTime + 1) * 1000
    if gt >= st then
        Transmog.delayedLoad:Hide()
    end
end)

Transmog.newTransmogAlert = CreateFrame("Frame")
Transmog.newTransmogAlert:Hide()
Transmog.newTransmogAlert.wonItems = {}

-- Hides the transmog alert anchor window, resetting it to a plain backdrop.
function Transmog.newTransmogAlert:HideAnchor()
    NewTransmogAlertFrame:SetBackdrop({
        bgFile = "",
        tile = true,
    })
    NewTransmogAlertFrame:EnableMouse(false)
    NewTransmogAlertFrameTitle:Hide()
    NewTransmogAlertFrameTestPlacement:Hide()
    NewTransmogAlertFrameClosePlacement:Hide()
end

Transmog.delayAddWonItem = CreateFrame("Frame")
Transmog.delayAddWonItem:Hide()
Transmog.delayAddWonItem.data = {}

Transmog.delayAddWonItem:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
Transmog.delayAddWonItem:SetScript("OnUpdate", function()
    local plus = 0.2
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        local atLeastOne = false
        for id, data in pairs(Transmog.delayAddWonItem.data) do
            if Transmog.delayAddWonItem.data[id] then
                atLeastOne = true
                Transmog:addWonItem(id)
                Transmog.delayAddWonItem.data[id] = nil
            end
        end

        if not atLeastOne then
            Transmog.delayAddWonItem:Hide()
        end
    end
end)

Transmog.gearChangedDelay = CreateFrame("Frame")
Transmog.gearChangedDelay:Hide()
Transmog.gearChangedDelay.delay = 1

Transmog.gearChangedDelay:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
Transmog.gearChangedDelay:SetScript("OnUpdate", function()
    local gt = GetTime() * 1000
    local st = (this.startTime + Transmog.gearChangedDelay.delay) * 1000
    if gt >= st then

        selectTransmogSlot(-1)
        Transmog_revert()
        Transmog.gearChangedDelay:Hide()
    end
end)

-- Displays a new-collection alert for a newly acquired transmog appearance.
function Transmog:addWonItem(itemID)
    local name, linkString, quality, level, min_level, class, subclass, stack, inv_type, tex, price = GetItemInfo(itemID)

	twfdebug("addWonItem itemID: " .. itemID)

	if not name or not quality then
		twfdebug("delayed")
		self.delayAddWonItem.data[itemID] = true
		self.delayAddWonItem:Show()
		return false
	end

    if name then

        local _, _, itemLink = TransmogFrame_Find(linkString, "(item:%d+:%d+:%d+:%d+)");

        self:cacheItem(itemID)

        twfprint(GAME_YELLOW .. '[' .. name .. ']' .. HIGHLIGHT_FONT_COLOR_CODE .. ' was added to your collection.')

        local newTransmogIndex = 0
        for i = 1, self:tableSize(self.newTransmogAlert.wonItems), 1 do
            if not self.newTransmogAlert.wonItems[i].active then
                newTransmogIndex = i
                break
            end
        end

        if newTransmogIndex == 0 then
            newTransmogIndex = self:tableSize(self.newTransmogAlert.wonItems) + 1
        end

        if not self.newTransmogAlert.wonItems[newTransmogIndex] then
            self.newTransmogAlert.wonItems[newTransmogIndex] = CreateFrame("Frame", "NewTransmogAlertFrame" .. newTransmogIndex, NewTransmogAlertFrame, "TransmogWonItemTemplate")
        end

        self.newTransmogAlert.wonItems[newTransmogIndex]:SetPoint("TOP", NewTransmogAlertFrame, "BOTTOM", 0, (20 + 100 * newTransmogIndex))
        self.newTransmogAlert.wonItems[newTransmogIndex].active = true
        self.newTransmogAlert.wonItems[newTransmogIndex].frameIndex = 0
        self.newTransmogAlert.wonItems[newTransmogIndex].doAnim = true

        self.newTransmogAlert.wonItems[newTransmogIndex]:SetAlpha(0)
        self.newTransmogAlert.wonItems[newTransmogIndex]:Show()

        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetNormalTexture(tex)
        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetPushedTexture(tex)
        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'ItemName'):SetText(HIGHLIGHT_FONT_COLOR_CODE .. name)

        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetScript("OnEnter", function(self)
            FashionTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
            FashionTooltip:SetHyperlink(itemLink);
            FashionTooltip:Show();
        end)
        getglobal('NewTransmogAlertFrame' .. newTransmogIndex .. 'Icon'):SetScript("OnLeave", function(self)
            FashionTooltip:Hide();
        end)

        self:StartNewTransmogAlertAnimation()

    end
end

function Transmog_testNewTransmogAlert()
    Transmog:addWonItem(19364)
end

-- Starts the new transmog alert animation sequence.
function Transmog:StartNewTransmogAlertAnimation()
    if self:tableSize(self.newTransmogAlert.wonItems) > 0 then
        self.newTransmogAlert.showLootWindow = true
    end
    if not self.newTransmogAlert:IsVisible() then
        self.newTransmogAlert:Show()
    end
end

Transmog.newTransmogAlert.showLootWindow = false

Transmog.newTransmogAlert:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
Transmog.newTransmogAlert:SetScript("OnUpdate", function()
    if Transmog.newTransmogAlert.showLootWindow then
        if GetTime() >= (this.startTime + 0.03) then

            this.startTime = GetTime()

            for i, d in ipairs(Transmog.newTransmogAlert.wonItems) do

                if Transmog.newTransmogAlert.wonItems[i].active then

                    local frame = getglobal('NewTransmogAlertFrame' .. i)

                    local image = 'loot_frame_xmog_'

                    getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetPoint('LEFT', 160, -9)
                    getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetWidth(36)
                    getglobal('NewTransmogAlertFrame' .. i .. 'IconNormalTexture'):SetWidth(36)
                    getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetHeight(36)
                    getglobal('NewTransmogAlertFrame' .. i .. 'IconNormalTexture'):SetHeight(36)

                    if Transmog.newTransmogAlert.wonItems[i].frameIndex < 10 then
                        image = image .. '0' .. Transmog.newTransmogAlert.wonItems[i].frameIndex
                    else
                        image = image .. Transmog.newTransmogAlert.wonItems[i].frameIndex;
                    end

                    Transmog.newTransmogAlert.wonItems[i].frameIndex = Transmog.newTransmogAlert.wonItems[i].frameIndex + 1

                    if Transmog.newTransmogAlert.wonItems[i].doAnim then

                        local backdrop = {
                            bgFile = 'Interface\\AddOns\\Transmog\\assets\\anim\\' .. image,
                            tile = false
                        };
                        if Transmog.newTransmogAlert.wonItems[i].frameIndex <= 30 then
                            frame:SetBackdrop(backdrop)
                        end
                        frame:SetAlpha(frame:GetAlpha() + 0.03)
                        getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetAlpha(frame:GetAlpha() + 0.03)
                    end
                    if Transmog.newTransmogAlert.wonItems[i].frameIndex == 35 then
                        Transmog.newTransmogAlert.wonItems[i].doAnim = false
                    end

                    if Transmog.newTransmogAlert.wonItems[i].frameIndex > 119 then
                        frame:SetAlpha(frame:GetAlpha() - 0.03)
                        getglobal('NewTransmogAlertFrame' .. i .. 'Icon'):SetAlpha(frame:GetAlpha() + 0.03)
                    end
                    if Transmog.newTransmogAlert.wonItems[i].frameIndex == 150 then

                        Transmog.newTransmogAlert.wonItems[i].frameIndex = 0
                        frame:Hide()
                        Transmog.newTransmogAlert.wonItems[i].active = false

                    end
                end
            end
        end
    end
end)

function Transmog_close_placement()
    twfprint('|cAnchor window closed. Type |cfffff569/transmog |cto show the Anchor window.')
    Transmog.newTransmogAlert:HideAnchor()
end

-- Shows the transmog alert anchor window with a draggable dialog frame.
function Transmog.newTransmogAlert:ShowAnchor()
    NewTransmogAlertFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
    })
    NewTransmogAlertFrame:EnableMouse(true)
    NewTransmogAlertFrameTitle:Show()
    NewTransmogAlertFrameTestPlacement:Show()
    NewTransmogAlertFrameClosePlacement:Show()
end
