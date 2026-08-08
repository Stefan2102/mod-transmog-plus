#include "Transmog.h"
#include "TransmogAddonProtocol.h"
#include "ScriptMgr.h"
#include "Chat.h"
#include "Player.h"
#include "WorldSession.h"
#include "Util.h"
#include "Tokenize.h"
#include <sstream>
#include <vector>
#include <string>
#include <string_view>
#include <algorithm>
#include <charconv>
#include <system_error>

// The addon protocol is carried through player chat messages using colon-delimited fields.
namespace TransmogAddon
{
    constexpr size_t MAX_IDS_PER_CHUNK = 20;

    // Reject partial numeric tokens so malformed addon requests cannot be accepted.
    bool ParseUint32(std::string_view text, uint32& value)
    {
        if (text.empty())
            return false;

        auto parsed = std::from_chars(text.data(), text.data() + text.size(), value, 10);
        return parsed.ec == std::errc{} && parsed.ptr == text.data() + text.size();
    }

// Prefix every response so the addon can distinguish module traffic from normal chat.
    void SendToClient(Player* player, std::string const& payload)
    {
        if (!player || !player->GetSession())
            return;

        std::string full = std::string(PREFIX) + "\t" + payload;

        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, LANG_ADDON, player, player, full);
        player->GetSession()->SendPacket(&data);
    }

    void SendOpen(Player* player)
    {
        SendToClient(player, "Open");
    }

    // Invalidate a client-side tooltip result when the server records a new appearance.
    void SendCollectionUpdated(Player* player, uint32 itemId)
    {
        SendToClient(player, "CollectionUpdated:" + std::to_string(itemId));
    }

// Status contains only non-empty slot overrides for compact client synchronization.
    void SendStatus(Player* player)
    {
        std::ostringstream out;
        uint32 count = 0;
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            uint32 fakeEntry = sTransmog->GetSlotAppearance(player->GetGUID(), slot);
            if (fakeEntry == 0)
                continue;

            out << ":" << uint32(slot) << "," << fakeEntry;
            ++count;
        }

        if (count == 0)
        {
            SendToClient(player, "TransmogStatus:0");
            return;
        }

        SendToClient(player, "TransmogStatus:" + std::to_string(count) + out.str());
    }

// Send one slot in bounded chunks because appearance lists can be large.
    void SendAvailableForSlot(Player* player, uint8 slot)
    {
        Item* targetItem = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        ItemTemplate const* targetTemplate = targetItem ? targetItem->GetTemplate() : nullptr;
        uint32 bucket = targetTemplate ? uint32(targetTemplate->Class) + uint32(targetTemplate->SubClass) : 0;

        std::vector<ItemTemplate const*> appearances = Transmog::GetValidAppearances(player, targetTemplate);
        uint32 amount = static_cast<uint32>(appearances.size());

        std::string header = "AvailableTransmogs:" + std::to_string(uint32(slot)) + ":" + std::to_string(bucket) + ":" + std::to_string(amount) + ":";

        SendToClient(player, header + "start");

        size_t i = 0;
        while (i < appearances.size())
        {
            std::ostringstream chunk;
            // Send appearance IDs in bounded chunks to match the addon protocol.
            size_t end = std::min(i + MAX_IDS_PER_CHUNK, appearances.size());
            for (size_t j = i; j < end; ++j)
            {
                if (j != i)
                    chunk << ":";
                chunk << appearances[j]->ItemId;
            }
            SendToClient(player, header + chunk.str());
            i = end;
        }

        SendToClient(player, header + "end");
    }

    void SendAvailableAll(Player* player)
    {
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            if (Transmog::GetSlotName(slot).empty())
                continue;

            SendAvailableForSlot(player, slot);
        }
    }

// The client receives either a failure flag or the applied slot and entry pair.
    void SendApplyResult(Player* player, bool success, uint8 slot, uint32 itemEntry)
    {
        if (!success)
        {
            SendToClient(player, "ApplyTransmogResult:0");
            return;
        }

        SendToClient(player, "ApplyTransmogResult:1:" + std::to_string(uint32(slot)) + "," + std::to_string(itemEntry));
    }

    void SendCost(Player* player, uint32 cost)
    {
        uint32 canPurchase = player->GetMoney() >= cost ? 1 : 0;
        SendToClient(player, "TransmogCost:" + std::to_string(cost) + ":" + std::to_string(canPurchase));
    }

    void HandleGetTransmogStatus(Player* player, std::string const&)
    {
        SendStatus(player);
    }

    // Answer collection-status requests from the account collection cache.
    void HandleGetCollectionStatus(Player* player, std::string const& args)
    {
        uint32 itemId;
        if (!ParseUint32(args, itemId) || itemId == 0)
            return;

        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(itemId);
        if (!itemTemplate ||
            (itemTemplate->Class != ITEM_CLASS_ARMOR && itemTemplate->Class != ITEM_CLASS_WEAPON) ||
            TransmogRules_CanNeverTransmog(itemTemplate))
        {
            SendToClient(player, "CollectionStatus:" + std::to_string(itemId) + ":2");
            return;
        }

        uint32 accountId = player->GetSession()->GetAccountId();
        sTransmog->LoadCollectionForAccount(accountId);

        bool collected = false;
        {
            std::shared_lock<std::shared_mutex> lock(sTransmog->collectionMutex);
            auto accountIt = sTransmog->collectionCache.find(accountId);
            collected = accountIt != sTransmog->collectionCache.end() && accountIt->second.contains(itemId);
        }

        SendToClient(player, "CollectionStatus:" + std::to_string(itemId) + ":" + (collected ? "1" : "0"));
    }

    void HandleGetAvailableTransmogs(Player* player, std::string const&)
    {
        SendAvailableAll(player);
    }

// Parse and validate untrusted addon input before calling the shared apply path.
    void HandleApply(Player* player, std::string const& args)
    {
        std::vector<std::string_view> parts = Acore::Tokenize(args, ':', false);
        if (parts.size() != 2)
        {
            SendApplyResult(player, false, 0, 0);
            return;
        }

        uint32 parsedSlot;
        uint32 itemEntry;
        if (!ParseUint32(parts[0], parsedSlot) || !ParseUint32(parts[1], itemEntry) ||
            parsedSlot >= EQUIPMENT_SLOT_END || itemEntry == 0)
        {
            SendApplyResult(player, false, 0, 0);
            return;
        }

        uint8 slot = static_cast<uint8>(parsedSlot);
        TransmogApplyResult result = sTransmog->ApplyAppearance(player, slot, itemEntry);
        bool success = result == TransmogApplyResult::Success ||
            result == TransmogApplyResult::AlreadyApplied;
        SendApplyResult(player, success, slot, itemEntry);
    }

// Removal is a state reset and does not require an appearance collection check.
    void HandleRemove(Player* player, std::string const& args)
    {
        uint32 parsedSlot;
        if (!ParseUint32(args, parsedSlot) || parsedSlot >= EQUIPMENT_SLOT_END)
        {
            SendApplyResult(player, false, 0, 0);
            return;
        }

        uint8 slot = static_cast<uint8>(parsedSlot);

        sTransmog->SetSlotAppearance(player, slot, 0);
        sTransmog->RefreshSlot(player, slot);
        SendApplyResult(player, true, slot, 0);
    }

    void HandleRemoveAll(Player* player, std::string const&)
    {
        sTransmog->ClearAllSlots(player);
        sTransmog->RefreshAllSlots(player);
        SendStatus(player);
    }

// Calculate the same per-entry pricing used by appearance application.
    void HandleCalculateCost(Player* player, std::string const& args)
    {
        uint32 totalCost = 0;

        for (std::string_view pairStr : Acore::Tokenize(args, ',', false))
        {
            if (pairStr.empty())
                continue;

            size_t colon = pairStr.find(':');
            if (colon == std::string_view::npos)
                continue;

            uint32 parsedSlot;
            uint32 itemEntry;
            if (!ParseUint32(pairStr.substr(0, colon), parsedSlot) ||
                !ParseUint32(pairStr.substr(colon + 1), itemEntry) ||
                parsedSlot >= EQUIPMENT_SLOT_END || itemEntry == 0)
                continue;

            totalCost += sTransmog->GetAppearanceCost(itemEntry);
        }

        SendCost(player, totalCost);
    }

// Dispatch only recognized module commands and ignore unrelated chat traffic.
    void Dispatch(Player* player, std::string const& message)
    {
        size_t colon = message.find(':');
        std::string command = colon == std::string::npos ? message : message.substr(0, colon);
        std::string args = colon == std::string::npos ? std::string() : message.substr(colon + 1);

        if (command == "GetTransmogStatus")
            HandleGetTransmogStatus(player, args);
        // Keep tooltip collection requests on the same authenticated addon channel.
        else if (command == "GetCollectionStatus")
            HandleGetCollectionStatus(player, args);
        else if (command == "GetAvailableTransmogs")
            HandleGetAvailableTransmogs(player, args);
        else if (command == "Apply")
            HandleApply(player, args);
        else if (command == "Remove")
            HandleRemove(player, args);
        else if (command == "RemoveAll")
            HandleRemoveAll(player, args);
        else if (command == "CalculateCost")
            HandleCalculateCost(player, args);
    }
}

class TransmogAddonProtocolScript : public PlayerScript
{
public:
    TransmogAddonProtocolScript() : PlayerScript("TransmogAddonProtocolScript",
        {
            PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT
        }) { }

// Consume addon whisper commands without interfering with ordinary player chat.
    bool OnPlayerCanUseChat(Player* player, uint32 /*type*/, uint32 lang, std::string& msg, Player* receiver) override
    {
        if (!sTransmog->Enable)
            return true;

        if (lang != LANG_ADDON || !receiver || receiver != player)
            return true;

        std::string const prefixTab = std::string(TransmogAddon::PREFIX) + "\t";
        if (msg.compare(0, prefixTab.size(), prefixTab) != 0)
            return true;

        TransmogAddon::Dispatch(player, msg.substr(prefixTab.size()));
        return false;
    }
};

void AddSC_TransmogAddonProtocol()
{
    new TransmogAddonProtocolScript();
}
