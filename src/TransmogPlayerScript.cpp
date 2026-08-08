#include "Transmog.h"
#include "TransmogAddonProtocol.h"
#include "Chat.h"

// Player hooks maintain account collections and slot state across lifecycle events.
class TransmogPlayerScript : public PlayerScript
{
public:
    TransmogPlayerScript() : PlayerScript("TransmogPlayerScript", {
        PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_LOGOUT,
        PLAYERHOOK_ON_DELETE,
        PLAYERHOOK_ON_EQUIP,
        PLAYERHOOK_ON_UNEQUIP_ITEM,
        PLAYERHOOK_ON_LEARN_SPELL,
        PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT
    }) { }

// Load shared account data before applying stored visible appearances.
    void OnPlayerLogin(Player* player) override
    {
        uint32 accountId = player->GetSession()->GetAccountId();
        sTransmog->LoadCollectionForAccount(accountId);

        {
            std::unique_lock<std::shared_mutex> lock(sTransmog->collectionMutex);
            // Keep the account cache alive until the last character using it logs out.
            ++sTransmog->collectionRefCounts[accountId];
        }

        sTransmog->LoadPlayerSlots(player->GetGUID());
        sTransmog->RefreshAllSlots(player);
    }

// Release both per-player state and the account cache reference.
    void OnPlayerLogout(Player* player) override
    {
        sTransmog->UnloadPlayerSlots(player->GetGUID());
        sTransmog->ClearSelection(player->GetGUID());
        sTransmog->UnrefCollectionForAccount(player->GetSession()->GetAccountId());
    }

// Character-owned slot records must not survive character deletion.
    void OnPlayerDelete(ObjectGuid guid, uint32) override
    {
        CharacterDatabase.Execute("DELETE FROM mod_transmog_plus WHERE Owner = {}", guid.GetCounter());
    }

// Re-evaluate the stored appearance against the newly equipped item.
    void OnPlayerEquip(Player* player, Item* item, uint8, uint8, bool) override
    {
        if (!item)
            return;

        ItemTemplate const* itemTemplate = item->GetTemplate();
        if (itemTemplate->Class != ITEM_CLASS_ARMOR && itemTemplate->Class != ITEM_CLASS_WEAPON)
            return;

        if (TransmogRules_CanNeverTransmog(itemTemplate))
            return;

        uint32 accountId = player->GetSession()->GetAccountId();
        uint32 itemId = itemTemplate->ItemId;

        sTransmog->LoadCollectionForAccount(accountId);

        if (sTransmog->AddCollectedAppearance(accountId, itemId))
        {
            CharacterDatabase.Execute("INSERT INTO mod_transmog_plus_appearances (account_id, item_template_id) VALUES ({}, {})", accountId, itemId);
            TransmogAddon::SendCollectionUpdated(player, itemId);
            ChatHandler(player->GetSession()).PSendSysMessage("{} {}", Transmog::GetItemLink(itemId, player->GetSession()), Tstr(player->GetSession(), LANG_TRANSMOG_APPEARANCE_ADDED));
        }
    }

// Clear the visible override while the equipment slot is empty.
    void OnPlayerUnequip(Player* player, Item*) override
    {
        if (!sTransmog->Enable)
            return;

        ObjectGuid guid = player->GetGUID();
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            if (!player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot) && sTransmog->GetSlotAppearance(guid, slot) != 0)
                sTransmog->RefreshSlot(player, slot);
        }
    }

// New armor proficiency can make additional collected tiers valid.
    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        if (!sTransmog->Enable)
            return;

        if (TransmogRules_IsArmorProficiencySpell(spellId))
            sTransmog->RefreshAllSlots(player);
    }

// Reapply after core visibility updates so the client keeps the transmog display.
    void OnPlayerAfterSetVisibleItemSlot(Player* player, uint8 slot, Item* item) override
    {
        if (!sTransmog->Enable)
            return;

        sTransmog->ApplySlot(player, slot, item);
    }
};

void AddSC_TransmogPlayerScript()
{
    new TransmogPlayerScript();
}
