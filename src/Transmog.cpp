#include "Transmog.h"

Transmog* Transmog::instance()
{
    static Transmog instance;
    return &instance;
}

std::string Transmog::GetSlotName(uint8 slot)
{
    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD: return "Head";
        case EQUIPMENT_SLOT_SHOULDERS: return "Shoulders";
        case EQUIPMENT_SLOT_BODY: return "Shirt";
        case EQUIPMENT_SLOT_CHEST: return "Chest";
        case EQUIPMENT_SLOT_WAIST: return "Waist";
        case EQUIPMENT_SLOT_LEGS: return "Legs";
        case EQUIPMENT_SLOT_FEET: return "Feet";
        case EQUIPMENT_SLOT_WRISTS: return "Wrists";
        case EQUIPMENT_SLOT_HANDS: return "Hands";
        case EQUIPMENT_SLOT_BACK: return "Back";
        case EQUIPMENT_SLOT_MAINHAND: return "Main Hand";
        case EQUIPMENT_SLOT_OFFHAND: return "Off Hand";
        case EQUIPMENT_SLOT_RANGED: return "Ranged";
        case EQUIPMENT_SLOT_TABARD: return "Tabard";
        default: return "";
    }
}

std::string Transmog::GetSlotIcon(uint8 slot, uint32 width, uint32 height, int x, int y)
{
    std::ostringstream ss;
    ss << "|TInterface/PaperDoll/";
    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD: ss << "UI-PaperDoll-Slot-Head"; break;
        case EQUIPMENT_SLOT_SHOULDERS: ss << "UI-PaperDoll-Slot-Shoulder"; break;
        case EQUIPMENT_SLOT_BODY: ss << "UI-PaperDoll-Slot-Shirt"; break;
        case EQUIPMENT_SLOT_CHEST: ss << "UI-PaperDoll-Slot-Chest"; break;
        case EQUIPMENT_SLOT_WAIST: ss << "UI-PaperDoll-Slot-Waist"; break;
        case EQUIPMENT_SLOT_LEGS: ss << "UI-PaperDoll-Slot-Legs"; break;
        case EQUIPMENT_SLOT_FEET: ss << "UI-PaperDoll-Slot-Feet"; break;
        case EQUIPMENT_SLOT_WRISTS: ss << "UI-PaperDoll-Slot-Wrists"; break;
        case EQUIPMENT_SLOT_HANDS: ss << "UI-PaperDoll-Slot-Hands"; break;
        case EQUIPMENT_SLOT_BACK: ss << "UI-PaperDoll-Slot-Chest"; break;
        case EQUIPMENT_SLOT_MAINHAND: ss << "UI-PaperDoll-Slot-MainHand"; break;
        case EQUIPMENT_SLOT_OFFHAND: ss << "UI-PaperDoll-Slot-SecondaryHand"; break;
        case EQUIPMENT_SLOT_RANGED: ss << "UI-PaperDoll-Slot-Ranged"; break;
        case EQUIPMENT_SLOT_TABARD: ss << "UI-PaperDoll-Slot-Tabard"; break;
        default: ss << "UI-Backpack-EmptySlot";
    }
    ss << ":" << width << ":" << height << ":" << x << ":" << y << "|t";
    return ss.str();
}

std::string Transmog::GetItemIcon(uint32 entry, uint32 width, uint32 height, int x, int y)
{
    std::ostringstream ss;
    ss << "|TInterface";
    ItemTemplate const* temp = sObjectMgr->GetItemTemplate(entry);
    ItemDisplayInfoEntry const* dispInfo = nullptr;
    if (temp)
    {
        dispInfo = sItemDisplayInfoStore.LookupEntry(temp->DisplayInfoID);
        if (dispInfo)
            ss << "/ICONS/" << dispInfo->inventoryIcon;
    }
    if (!dispInfo)
        ss << "/InventoryItems/WoWUnknownItem01";
    ss << ":" << width << ":" << height << ":" << x << ":" << y << "|t";
    return ss.str();
}

std::string Transmog::GetItemLink(uint32 entry, WorldSession* session)
{
    if (entry == HIDDEN_ITEM_ID)
        return "(Hidden)";

    ItemTemplate const* temp = sObjectMgr->GetItemTemplate(entry);
    if (!temp)
        return "";

    int loc_idx = session->GetSessionDbLocaleIndex();
    std::string name = temp->Name1;
    if (ItemLocale const* il = sObjectMgr->GetItemLocale(entry))
        ObjectMgr::GetLocaleString(il->Name, loc_idx, name);

    std::ostringstream oss;
    oss << "|c" << std::hex << ItemQualityColors[temp->Quality] << std::dec
        << "|Hitem:" << entry << ":0:0:0:0:0:0:0:0:0|h[" << name << "]|h|r";
    return oss.str();
}

std::string Transmog::GetSlotGossipIcon(Player* player, uint8 slot)
{
    Item* equipped = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
    uint32 fakeEntry = sTransmog->GetSlotAppearance(player->GetGUID(), slot);

    if (!equipped)
        return GetSlotIcon(slot, 30, 30, -18, 0);
    if (fakeEntry == HIDDEN_ITEM_ID && TransmogRules_IsArmorSlot(slot))
        return "|TInterface/ICONS/inv_misc_enggizmos_27:30:30:-18:0|t";
    if (fakeEntry)
        return GetItemIcon(fakeEntry, 30, 30, -18, 0);
    return GetItemIcon(equipped->GetEntry(), 30, 30, -18, 0);
}

uint32 Transmog::GetVisibleEntryForSlot(Player const* player, uint8 slot, Item const* item) const
{
    if (!item || slot >= EQUIPMENT_SLOT_END)
        return 0;

    uint32 fakeEntry = GetSlotAppearance(player->GetGUID(), slot);
    if (fakeEntry == 0)
        return item->GetEntry();
    if (fakeEntry == HIDDEN_ITEM_ID)
        return TransmogRules_IsArmorSlot(slot) ? HIDDEN_ITEM_ID : item->GetEntry();

    ItemTemplate const* sourceTemplate = sObjectMgr->GetItemTemplate(fakeEntry);
    if (sourceTemplate && TransmogRules_CanTransmogrifyItemWithItem(player, item->GetTemplate(), sourceTemplate))
        return fakeEntry;

    return item->GetEntry();
}

uint16 Transmog::GetVisibleItemIndex(uint8 slot)
{
    return PLAYER_VISIBLE_ITEM_1_ENTRYID + (slot * 2);
}
