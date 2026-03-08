// NPC pair subsystem helpers: training + bar pair validation/resync.

#include "al_constants_inc"
#include "al_debug_inc"

void AL_InitTrainingPartner(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    object oExistingPartner = GetLocalObject(oNpc, AL_L_TRAINING_PARTNER);
    if (GetIsObjectValid(oExistingPartner))
    {
        object oAreaSelf = GetArea(oNpc);
        object oAreaPartner = GetArea(oExistingPartner);

        if (GetIsObjectValid(oAreaSelf) && oAreaPartner == oAreaSelf)
        {
            object oPartnerBacklink = GetLocalObject(oExistingPartner, AL_L_TRAINING_PARTNER);
            if (oPartnerBacklink == oNpc)
            {
                // Keep early-return only for a fully valid, symmetric in-area pair.
                return;
            }

            // Partner points elsewhere: drop only the stale one-sided link on this NPC.
            DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);
        }
        else
        {
            // Existing partner is stale (invalid or in another area).
            DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);
        }
    }

    string sTag = GetTag(oNpc);
    string sAreaPartnerKey = "";
    string sAreaSelfKey = "";
    string sAreaPartnerRefKey = "";
    int bResetCache = FALSE;

    if (sTag == "FACTION_NPC1")
    {
        sAreaSelfKey = AL_L_TRAINING_NPC1;
        sAreaPartnerKey = AL_L_TRAINING_NPC2;
        sAreaPartnerRefKey = AL_L_TRAINING_NPC2_REF;
    }
    else if (sTag == "FACTION_NPC2")
    {
        sAreaSelfKey = AL_L_TRAINING_NPC2;
        sAreaPartnerKey = AL_L_TRAINING_NPC1;
        sAreaPartnerRefKey = AL_L_TRAINING_NPC1_REF;
    }

    if (sAreaPartnerKey == "")
    {
        return;
    }

    object oArea = GetArea(oNpc);
    object oPartner = OBJECT_INVALID;

    if (GetIsObjectValid(oArea))
    {
        // Area locals seeded via toolset/bootstrap:
        // AL_L_TRAINING_NPC1_REF / AL_L_TRAINING_NPC2_REF point to the pair.
        if (GetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED))
        {
            object oCachedSelf = GetLocalObject(oArea, sAreaSelfKey);
            object oCachedPartner = GetLocalObject(oArea, sAreaPartnerKey);
            if (!GetIsObjectValid(oCachedSelf) || !GetIsObjectValid(oCachedPartner))
            {
                SetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED, FALSE);
                DeleteLocalObject(oArea, sAreaSelfKey);
                DeleteLocalObject(oArea, sAreaPartnerKey);
                bResetCache = TRUE;
            }
        }
        SetLocalObject(oArea, sAreaSelfKey, oNpc);
        oPartner = GetLocalObject(oArea, sAreaPartnerKey);
    }

    if (!GetIsObjectValid(oPartner))
    {
        if (GetIsObjectValid(oArea))
        {
            object oRefPartner = GetLocalObject(oArea, sAreaPartnerRefKey);
            if (GetIsObjectValid(oRefPartner) && GetArea(oRefPartner) == oArea)
            {
                oPartner = oRefPartner;
                SetLocalObject(oArea, sAreaPartnerKey, oPartner);
            }
        }
    }

    if (GetIsObjectValid(oArea) && bResetCache)
    {
        object oAreaNpc1 = GetLocalObject(oArea, AL_L_TRAINING_NPC1);
        object oAreaNpc2 = GetLocalObject(oArea, AL_L_TRAINING_NPC2);
        int bHasRestoredPair = GetIsObjectValid(oAreaNpc1)
            && GetIsObjectValid(oAreaNpc2)
            && GetArea(oAreaNpc1) == oArea
            && GetArea(oAreaNpc2) == oArea;

        SetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED, bHasRestoredPair);

        if (!bHasRestoredPair && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: training partner cache reset; pair restore failed.");
        }
    }

    if (GetIsObjectValid(oPartner) && oPartner != oNpc)
    {
        SetLocalObject(oNpc, AL_L_TRAINING_PARTNER, oPartner);

        if (GetArea(oPartner) == GetArea(oNpc))
        {
            SetLocalObject(oPartner, AL_L_TRAINING_PARTNER, oNpc);
        }
    }
}

void AL_InitBarPair(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    object oExistingPair = GetLocalObject(oNpc, AL_L_BAR_PAIR);
    if (GetIsObjectValid(oExistingPair))
    {
        if (GetArea(oExistingPair) == oArea)
        {
            object oBack = GetLocalObject(oExistingPair, AL_L_BAR_PAIR);
            if (oBack == oNpc)
            {
                return;
            }

            // Existing pair is asymmetric in the same area, so this local link
            // is stale and must not be reused for requirement checks.
            DeleteLocalObject(oNpc, AL_L_BAR_PAIR);

            if (AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
            {
                AL_SendDebugMessageToAreaPCs(oArea, "AL: asymmetric bar pair repaired for " + GetName(oNpc) + ".");
            }
        }
        else
        {
            DeleteLocalObject(oNpc, AL_L_BAR_PAIR);

            if (AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
            {
                AL_SendDebugMessageToAreaPCs(oArea, "AL: stale bar pair reset for " + GetName(oNpc) + ".");
            }
        }
    }

    object oBartenderRef = GetLocalObject(oArea, AL_L_BAR_BARTENDER_REF);
    object oBarmaidRef = GetLocalObject(oArea, AL_L_BAR_BARMAID_REF);
    string sAreaPartnerKey = "";
    string sAreaSelfKey = "";
    object oPartnerRef = OBJECT_INVALID;

    if (oNpc == oBartenderRef)
    {
        // Symmetric role mapping: bartender looks up barmaid and vice versa.
        sAreaSelfKey = AL_L_BAR_BARTENDER;
        sAreaPartnerKey = AL_L_BAR_BARMAID;
        oPartnerRef = oBarmaidRef;
    }
    else if (oNpc == oBarmaidRef)
    {
        sAreaSelfKey = AL_L_BAR_BARMAID;
        sAreaPartnerKey = AL_L_BAR_BARTENDER;
        oPartnerRef = oBartenderRef;
    }

    if (sAreaPartnerKey == "")
    {
        return;
    }

    object oPartner = OBJECT_INVALID;

    // Area locals seeded via toolset/bootstrap:
    // AL_L_BAR_BARTENDER_REF / AL_L_BAR_BARMAID_REF point to the pair.
    object oCachedSelf = GetLocalObject(oArea, sAreaSelfKey);
    object oCachedPartner = GetLocalObject(oArea, sAreaPartnerKey);
    if (!GetIsObjectValid(oCachedSelf)
        || !GetIsObjectValid(oCachedPartner)
        || GetArea(oCachedSelf) != oArea
        || GetArea(oCachedPartner) != oArea)
    {
        DeleteLocalObject(oArea, sAreaSelfKey);
        DeleteLocalObject(oArea, sAreaPartnerKey);
    }

    SetLocalObject(oArea, sAreaSelfKey, oNpc);
    oPartner = GetLocalObject(oArea, sAreaPartnerKey);
    if (GetIsObjectValid(oPartner) && GetArea(oPartner) != oArea)
    {
        DeleteLocalObject(oArea, sAreaPartnerKey);
        oPartner = OBJECT_INVALID;
    }

    if (!GetIsObjectValid(oPartner))
    {
        if (GetIsObjectValid(oPartnerRef) && GetArea(oPartnerRef) == oArea)
        {
            oPartner = oPartnerRef;
            SetLocalObject(oArea, sAreaPartnerKey, oPartner);
        }
        else
        {
            // Reference was replaced/invalidated: keep runtime pair unbound until a valid NPC appears.
            DeleteLocalObject(oArea, sAreaPartnerKey);
            oPartner = OBJECT_INVALID;
        }
    }

    if (GetIsObjectValid(oPartner) && oPartner != oNpc)
    {
        // Always set the link on both ends so requirement checks behave identically.
        SetLocalObject(oNpc, AL_L_BAR_PAIR, oPartner);
        SetLocalObject(oPartner, AL_L_BAR_PAIR, oNpc);
        return;
    }

    // Keep unbound state explicit when no valid partner exists.
    DeleteLocalObject(oNpc, AL_L_BAR_PAIR);
}
