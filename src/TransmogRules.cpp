#include "Transmog.h"

// ==========================================
// ANONYMOUS NAMESPACE
// ==========================================

namespace
{
    constexpr uint32 ArmorSpellIds[4] = { 750, 8737, 9077, 9078 };
    constexpr uint32 ArmorTiers[4] =
    {
        ITEM_SUBCLASS_ARMOR_PLATE,
        ITEM_SUBCLASS_ARMOR_MAIL,
        ITEM_SUBCLASS_ARMOR_LEATHER,
        ITEM_SUBCLASS_ARMOR_CLOTH
    };
}

// ==========================================
// IS ARMOR SLOT / IS ARMOR PROFICIENCY SPELL
// ==========================================

bool TransmogRules_IsArmorSlot(uint8 slot)
{
    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD:
        case EQUIPMENT_SLOT_SHOULDERS:
        case EQUIPMENT_SLOT_BODY:
        case EQUIPMENT_SLOT_CHEST:
        case EQUIPMENT_SLOT_WAIST:
        case EQUIPMENT_SLOT_LEGS:
        case EQUIPMENT_SLOT_FEET:
        case EQUIPMENT_SLOT_WRISTS:
        case EQUIPMENT_SLOT_HANDS:
        case EQUIPMENT_SLOT_BACK:
        case EQUIPMENT_SLOT_TABARD:
            return true;
        default:
            return false;
    }
}

bool TransmogRules_IsArmorProficiencySpell(uint32 spellId)
{
    return spellId == 750 || spellId == 8737 || spellId == 9077 || spellId == 9078;
}

// ==========================================
// ITEM FITS IN SLOT
// ==========================================

bool TransmogRules_ItemFitsInSlot(ItemTemplate const* proto, uint8 slot)
{
    switch (slot)
    {
        case EQUIPMENT_SLOT_HEAD: return proto->InventoryType == INVTYPE_HEAD;
        case EQUIPMENT_SLOT_SHOULDERS: return proto->InventoryType == INVTYPE_SHOULDERS;
        case EQUIPMENT_SLOT_BODY: return proto->InventoryType == INVTYPE_BODY;
        case EQUIPMENT_SLOT_CHEST: return proto->InventoryType == INVTYPE_CHEST || proto->InventoryType == INVTYPE_ROBE;
        case EQUIPMENT_SLOT_WAIST: return proto->InventoryType == INVTYPE_WAIST;
        case EQUIPMENT_SLOT_LEGS: return proto->InventoryType == INVTYPE_LEGS;
        case EQUIPMENT_SLOT_FEET: return proto->InventoryType == INVTYPE_FEET;
        case EQUIPMENT_SLOT_WRISTS: return proto->InventoryType == INVTYPE_WRISTS;
        case EQUIPMENT_SLOT_HANDS: return proto->InventoryType == INVTYPE_HANDS;
        case EQUIPMENT_SLOT_BACK: return proto->InventoryType == INVTYPE_CLOAK;
        case EQUIPMENT_SLOT_TABARD: return proto->InventoryType == INVTYPE_TABARD;
        case EQUIPMENT_SLOT_MAINHAND: return proto->InventoryType == INVTYPE_WEAPON || proto->InventoryType == INVTYPE_WEAPONMAINHAND || proto->InventoryType == INVTYPE_2HWEAPON;
        case EQUIPMENT_SLOT_OFFHAND: return proto->InventoryType == INVTYPE_WEAPON || proto->InventoryType == INVTYPE_WEAPONOFFHAND || proto->InventoryType == INVTYPE_SHIELD || proto->InventoryType == INVTYPE_HOLDABLE || proto->InventoryType == INVTYPE_2HWEAPON;
        case EQUIPMENT_SLOT_RANGED: return proto->InventoryType == INVTYPE_RANGED || proto->InventoryType == INVTYPE_RANGEDRIGHT || proto->InventoryType == INVTYPE_THROWN;
        default: return false;
    }
}

// ==========================================
// IS RANGED WEAPON
// ==========================================

bool TransmogRules_IsRangedWeapon(uint32 itemClass, uint32 subClass)
{
    return itemClass == ITEM_CLASS_WEAPON && (
        subClass == ITEM_SUBCLASS_WEAPON_BOW ||
        subClass == ITEM_SUBCLASS_WEAPON_GUN ||
        subClass == ITEM_SUBCLASS_WEAPON_CROSSBOW);
}

// ==========================================
// IS VALID OFFHAND ARMOR / IS TIERED ARMOR SUBCLASS
// ==========================================

bool TransmogRules_IsValidOffhandArmor(uint32 subClass, uint32 invType)
{
    return subClass == ITEM_SUBCLASS_ARMOR_BUCKLER ||
        (subClass == ITEM_SUBCLASS_ARMOR_MISC && invType == INVTYPE_HOLDABLE) ||
        subClass == ITEM_SUBCLASS_ARMOR_SHIELD;
}

bool TransmogRules_IsTieredArmorSubclass(uint32 subClass)
{
    return subClass == ITEM_SUBCLASS_ARMOR_PLATE ||
        subClass == ITEM_SUBCLASS_ARMOR_MAIL ||
        subClass == ITEM_SUBCLASS_ARMOR_LEATHER ||
        subClass == ITEM_SUBCLASS_ARMOR_CLOTH;
}

// ==========================================
// GET HIGHEST ARMOR TIER / TIER AVAILABLE
// ==========================================

bool TransmogRules_GetHighestArmorTier(Player const* player, uint32& highest)
{
    for (int i = 0; i < 4; ++i)
    {
        if (player->HasSpell(ArmorSpellIds[i]))
        {
            highest = ArmorTiers[i];
            return true;
        }
    }
    highest = ITEM_SUBCLASS_ARMOR_CLOTH;
    return false;
}

bool TransmogRules_TierAvailable(Player const* player, uint32 tier)
{
    if (!TransmogRules_IsTieredArmorSubclass(tier))
        return false;

    uint32 highest = ITEM_SUBCLASS_ARMOR_CLOTH;
    TransmogRules_GetHighestArmorTier(player, highest);

    switch (highest)
    {
        case ITEM_SUBCLASS_ARMOR_PLATE: return true;
        case ITEM_SUBCLASS_ARMOR_MAIL: return tier != ITEM_SUBCLASS_ARMOR_PLATE;
        case ITEM_SUBCLASS_ARMOR_LEATHER: return tier == ITEM_SUBCLASS_ARMOR_LEATHER || tier == ITEM_SUBCLASS_ARMOR_CLOTH;
        case ITEM_SUBCLASS_ARMOR_CLOTH: return tier == ITEM_SUBCLASS_ARMOR_CLOTH;
        default: return false;
    }
}

// ==========================================
// IS ALLOWED / IS NOT ALLOWED
// ==========================================

bool TransmogRules_IsAllowed(uint32 entry)
{
    return sTransmog->Allowed.find(entry) != sTransmog->Allowed.end();
}

bool TransmogRules_IsNotAllowed(uint32 entry)
{
    return sTransmog->NotAllowed.find(entry) != sTransmog->NotAllowed.end();
}

// ==========================================
// IS ALLOWED QUALITY
// ==========================================

bool TransmogRules_IsAllowedQuality(uint32 quality)
{
    switch (quality)
    {
        case ITEM_QUALITY_POOR: return sTransmog->AllowPoor;
        case ITEM_QUALITY_NORMAL: return sTransmog->AllowCommon;
        case ITEM_QUALITY_UNCOMMON: return sTransmog->AllowUncommon;
        case ITEM_QUALITY_RARE: return sTransmog->AllowRare;
        case ITEM_QUALITY_EPIC: return sTransmog->AllowEpic;
        case ITEM_QUALITY_LEGENDARY: return sTransmog->AllowLegendary;
        case ITEM_QUALITY_ARTIFACT: return sTransmog->AllowArtifact;
        case ITEM_QUALITY_HEIRLOOM: return sTransmog->AllowHeirloom;
        default: return false;
    }
}

// ==========================================
// CAN NEVER TRANSMOG
// ==========================================

bool TransmogRules_CanNeverTransmog(ItemTemplate const* proto)
{
    return proto->InventoryType == INVTYPE_BAG ||
        proto->InventoryType == INVTYPE_RELIC ||
        proto->InventoryType == INVTYPE_FINGER ||
        proto->InventoryType == INVTYPE_TRINKET ||
        proto->InventoryType == INVTYPE_AMMO ||
        proto->InventoryType == INVTYPE_QUIVER ||
        proto->InventoryType == INVTYPE_NECK;
}

// ==========================================
// IS ITEM TRANSMOGRIFIABLE
// ==========================================

bool TransmogRules_IsItemTransmogrifiable(Player const* player, ItemTemplate const* proto)
{
    if (!proto)
        return false;

    if (TransmogRules_IsNotAllowed(proto->ItemId))
        return false;

    if (!sTransmog->AllowFishingPoles && proto->Class == ITEM_CLASS_WEAPON && proto->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE)
        return false;

    if (!TransmogRules_IsAllowedQuality(proto->Quality))
        return false;

    if (!sTransmog->IgnoreReqEvent && proto->HolidayId && !IsHolidayActive((HolidayIds)proto->HolidayId))
        return false;

    if (!sTransmog->IgnoreReqStats)
    {
        if (!proto->RandomProperty && !proto->RandomSuffix && proto->StatsCount > 0)
        {
            bool found = false;
            for (uint8 i = 0; i < proto->StatsCount; ++i)
            {
                if (proto->ItemStat[i].ItemStatValue != 0)
                {
                    found = true;
                    break;
                }
            }
            if (!found)
                return false;
        }
    }

    return true;
}

// ==========================================
// SUITABLE FOR TRANSMOGRIFICATION
// ==========================================

bool TransmogRules_SuitableForTransmogrification(Player const* player, ItemTemplate const* proto)
{
    if (!player || !proto)
        return false;

    if (proto->Class != ITEM_CLASS_ARMOR && proto->Class != ITEM_CLASS_WEAPON)
        return false;

    if (TransmogRules_IsAllowed(proto->ItemId))
        return true;

    if (!TransmogRules_IsItemTransmogrifiable(player, proto))
        return false;

    uint32 subclassSkill = proto->GetSkill();
    if (proto->SubClass > 0 && subclassSkill && player->GetSkillValue(subclassSkill) == 0)
    {
        if (proto->Class == ITEM_CLASS_ARMOR && !sTransmog->AllowMixedArmorTypes)
            return false;

        if (proto->Class == ITEM_CLASS_WEAPON && sTransmog->AllowMixedWeaponTypes != 2)
            return false;
    }

    if (proto->HasFlag2(ITEM_FLAG2_FACTION_HORDE) && player->GetTeamId() != TEAM_HORDE)
        return false;

    if (proto->HasFlag2(ITEM_FLAG2_FACTION_ALLIANCE) && player->GetTeamId() != TEAM_ALLIANCE)
        return false;

    if (!sTransmog->IgnoreReqClass && (proto->AllowableClass & player->getClassMask()) == 0)
        return false;

    if (!sTransmog->IgnoreReqRace && (proto->AllowableRace & player->getRaceMask()) == 0)
        return false;

    if (!sTransmog->IgnoreReqSkill && proto->RequiredSkill != 0)
    {
        if (player->GetSkillValue(proto->RequiredSkill) == 0)
            return false;
        if (player->GetSkillValue(proto->RequiredSkill) < proto->RequiredSkillRank)
            return false;
    }

    if (!sTransmog->IgnoreReqSpell && proto->RequiredSpell != 0 && !player->HasSpell(proto->RequiredSpell))
        return false;

    if (sTransmog->AllowLowerTiers && TransmogRules_TierAvailable(player, proto->SubClass))
        return true;

    return true;
}
