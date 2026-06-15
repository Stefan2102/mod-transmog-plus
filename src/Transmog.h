#ifndef DEF_TRANSMOG_H
#define DEF_TRANSMOG_H

#include "Player.h"
#include "ItemTemplate.h"
#include "Config.h"
#include "ScriptMgr.h"
#include "ObjectGuid.h"
#include "UpdateFields.h"
#include "ObjectMgr.h"
#include "Item.h"
#include "WorldSession.h"
#include "DatabaseEnv.h"
#include "GameEventMgr.h"
#include <array>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <sstream>
#include <shared_mutex>
#include <mutex>

constexpr uint32 HIDDEN_ITEM_ID = 999999;
constexpr uint8 MAX_ITEMS_PER_PAGE = 20;

enum MenuId : uint32
{
    MENU_MAIN = 1000,
    MENU_SELECT_SLOT,
    MENU_HIDE_SLOT,
    MENU_REMOVE_SLOT,
    MENU_REMOVE_ALL,
    MENU_APPLY,
    MENU_PAGE
};

enum TransmogString : uint32
{
    LANG_TRANSMOG_OK = 1,
    LANG_TRANSMOG_EMPTY_SLOT,
    LANG_TRANSMOG_INVALID_SRC,
    LANG_TRANSMOG_ALL_REMOVED,
    LANG_TRANSMOG_HIDDEN,
    LANG_TRANSMOG_SLOT_REMOVED,
    LANG_TRANSMOG_NO_MONEY,
    LANG_TRANSMOG_REMOVE_ALL,
    LANG_TRANSMOG_REMOVE_ALL_ASK,
    LANG_TRANSMOG_BACK,
    LANG_TRANSMOG_HIDE_SLOT,
    LANG_TRANSMOG_REMOVE_SLOT,
    LANG_TRANSMOG_NEXT_PAGE,
    LANG_TRANSMOG_PREVIOUS_PAGE,
    LANG_TRANSMOG_NO_APPEARANCES,
    LANG_TRANSMOG_APPEARANCE_ADDED,
    LANG_TRANSMOG_FREE
};

inline std::string const& Tstr(WorldSession* session, uint32 id)
{
    return *session->GetModuleString("mod-transmog", id);
}

class Transmog
{
public:
    static Transmog* instance();

    void LoadConfig();

    bool Enable;
    uint32 PriceCopper;
    bool AllowHiddenTransmog;
    bool HiddenTransmogIsFree;

    std::set<uint32> Allowed;
    std::set<uint32> NotAllowed;

    bool AllowPoor;
    bool AllowCommon;
    bool AllowUncommon;
    bool AllowRare;
    bool AllowEpic;
    bool AllowLegendary;
    bool AllowArtifact;
    bool AllowHeirloom;

    bool AllowMixedArmorTypes;
    bool AllowMixedOffhandArmorTypes;
    bool AllowLowerTiers;
    bool AllowMixedWeaponHandedness;
    bool AllowFishingPoles;
    uint8 AllowMixedWeaponTypes;

    bool IgnoreReqRace;
    bool IgnoreReqClass;
    bool IgnoreReqSkill;
    bool IgnoreReqSpell;
    bool IgnoreReqEvent;
    bool IgnoreReqStats;

    std::unordered_map<uint32, std::unordered_set<uint32>> collectionCache;
    std::unordered_map<uint32, uint32> collectionRefCounts;
    std::unordered_map<ObjectGuid, std::array<uint32, EQUIPMENT_SLOT_END>> slotMap;
    std::unordered_map<ObjectGuid, uint8> selectionCache;
    mutable std::shared_mutex slotMapMutex;
    mutable std::shared_mutex collectionMutex;

    void LoadCollectionForAccount(uint32 accountId);
    void UnrefCollectionForAccount(uint32 accountId);
    bool AddCollectedAppearance(uint32 accountId, uint32 itemId);

    void LoadPlayerSlots(ObjectGuid guid);
    void UnloadPlayerSlots(ObjectGuid guid);
    void SetSlotAppearance(Player* player, uint8 slot, uint32 fakeEntry);
    uint32 GetSlotAppearance(ObjectGuid guid, uint8 slot) const;
    void ApplySlot(Player* player, uint8 slot, Item* item);
    void RefreshSlot(Player* player, uint8 slot);
    void RefreshAllSlots(Player* player);
    void ClearAllSlots(Player* player);
    uint32 GetVisibleEntryForSlot(Player const* player, uint8 slot, Item const* item) const;

    uint8 GetSelectedSlot(ObjectGuid guid) const;
    void SetSelectedSlot(ObjectGuid guid, uint8 slot);
    void ClearSelection(ObjectGuid guid);

    static std::string GetSlotName(uint8 slot);
    static std::string GetSlotIcon(uint8 slot, uint32 width, uint32 height, int x, int y);
    static std::string GetItemIcon(uint32 entry, uint32 width, uint32 height, int x, int y);
    static std::string GetItemLink(uint32 entry, WorldSession* session);
    static std::string GetSlotGossipIcon(Player* player, uint8 slot);
    static uint16 GetVisibleItemIndex(uint8 slot);
};

#define sTransmog Transmog::instance()

bool TransmogRules_IsArmorSlot(uint8 slot);
bool TransmogRules_IsArmorProficiencySpell(uint32 spellId);
bool TransmogRules_IsRangedWeapon(uint32 itemClass, uint32 subClass);
bool TransmogRules_CanNeverTransmog(ItemTemplate const* proto);
bool TransmogRules_IsItemTransmogrifiable(Player const* player, ItemTemplate const* proto);
bool TransmogRules_SuitableForTransmogrification(Player const* player, ItemTemplate const* proto);
bool TransmogRules_CanTransmogrifyItemWithItem(Player const* player, ItemTemplate const* target, ItemTemplate const* source);

#endif
