#ifndef DEF_TRANSMOG_ADDON_PROTOCOL_H
#define DEF_TRANSMOG_ADDON_PROTOCOL_H

#include "Player.h"
#include <string>

namespace TransmogAddon
{
    constexpr char const* PREFIX = "transmog";

    void SendOpen(Player* player);

    // Notify tooltip clients that an appearance became collected.
    void SendCollectionUpdated(Player* player, uint32 itemId);

    void Dispatch(Player* player, std::string const& message);
}

#endif
