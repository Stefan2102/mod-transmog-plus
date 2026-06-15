#include "Transmog.h"

void Transmog::LoadConfig()
{
    Enable = sConfigMgr->GetOption<bool>("Transmog.Enable", true);
    PriceCopper = sConfigMgr->GetOption<uint32>("Transmog.PriceCopper", 1000);
    AllowHiddenTransmog = sConfigMgr->GetOption<bool>("Transmog.AllowHiddenTransmog", true);
    HiddenTransmogIsFree = sConfigMgr->GetOption<bool>("Transmog.HiddenTransmogIsFree", true);

    Allowed.clear();
    NotAllowed.clear();

    std::istringstream issAllowed(sConfigMgr->GetOption<std::string>("Transmog.Allowed", ""));
    while (issAllowed.good())
    {
        uint32 entry;
        issAllowed >> entry;
        if (issAllowed.fail())
            break;
        Allowed.insert(entry);
    }

    std::istringstream issNotAllowed(sConfigMgr->GetOption<std::string>("Transmog.NotAllowed", ""));
    while (issNotAllowed.good())
    {
        uint32 entry;
        issNotAllowed >> entry;
        if (issNotAllowed.fail())
            break;
        NotAllowed.insert(entry);
    }

    AllowPoor = sConfigMgr->GetOption<bool>("Transmog.AllowPoor", true);
    AllowCommon = sConfigMgr->GetOption<bool>("Transmog.AllowCommon", true);
    AllowUncommon = sConfigMgr->GetOption<bool>("Transmog.AllowUncommon", true);
    AllowRare = sConfigMgr->GetOption<bool>("Transmog.AllowRare", true);
    AllowEpic = sConfigMgr->GetOption<bool>("Transmog.AllowEpic", true);
    AllowLegendary = sConfigMgr->GetOption<bool>("Transmog.AllowLegendary", true);
    AllowArtifact = sConfigMgr->GetOption<bool>("Transmog.AllowArtifact", true);
    AllowHeirloom = sConfigMgr->GetOption<bool>("Transmog.AllowHeirloom", true);

    AllowMixedArmorTypes = sConfigMgr->GetOption<bool>("Transmog.AllowMixedArmorTypes", false);
    AllowMixedOffhandArmorTypes = sConfigMgr->GetOption<bool>("Transmog.AllowMixedOffhandArmorTypes", false);
    AllowLowerTiers = sConfigMgr->GetOption<bool>("Transmog.AllowLowerTiers", false);
    AllowMixedWeaponHandedness = sConfigMgr->GetOption<bool>("Transmog.AllowMixedWeaponHandedness", true);
    AllowFishingPoles = sConfigMgr->GetOption<bool>("Transmog.AllowFishingPoles", false);
    AllowMixedWeaponTypes = sConfigMgr->GetOption<uint8>("Transmog.AllowMixedWeaponTypes", 1);

    IgnoreReqRace = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqRace", false);
    IgnoreReqClass = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqClass", false);
    IgnoreReqSkill = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqSkill", false);
    IgnoreReqSpell = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqSpell", false);
    IgnoreReqEvent = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqEvent", false);
    IgnoreReqStats = sConfigMgr->GetOption<bool>("Transmog.IgnoreReqStats", false);
}
