// NPC pair subsystem helpers: training + bar pair validation/resync.
// Contract: *_REF locals are authoritative for role/source identity,
// while AL_L_TRAINING_NPC1/2 + AL_L_BAR_* are derived runtime cache only.

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
            if (oPartnerBacklink != oNpc)
            {
                // Partner points elsewhere: drop only the stale one-sided link on this NPC.
                DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);
            }
        }
        else
        {
            // Existing partner is stale (invalid or in another area).
            DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);
        }
    }

    object oArea = GetArea(oNpc);
    object oTrainingNpc1Ref = OBJECT_INVALID;
    object oTrainingNpc2Ref = OBJECT_INVALID;
    string sAreaPartnerKey = "";
    string sAreaSelfKey = "";
    string sAreaPartnerRefKey = "";
    object oRefPartner = OBJECT_INVALID;
    int bCacheRefMismatchRepaired = FALSE;

    if (GetIsObjectValid(oArea))
    {
        oTrainingNpc1Ref = GetLocalObject(oArea, AL_L_TRAINING_NPC1_REF);
        oTrainingNpc2Ref = GetLocalObject(oArea, AL_L_TRAINING_NPC2_REF);
    }

    if (oNpc == oTrainingNpc1Ref)
    {
        sAreaSelfKey = AL_L_TRAINING_NPC1;
        sAreaPartnerKey = AL_L_TRAINING_NPC2;
        sAreaPartnerRefKey = AL_L_TRAINING_NPC2_REF;
    }
    else if (oNpc == oTrainingNpc2Ref)
    {
        sAreaSelfKey = AL_L_TRAINING_NPC2;
        sAreaPartnerKey = AL_L_TRAINING_NPC1;
        sAreaPartnerRefKey = AL_L_TRAINING_NPC1_REF;
    }

    if (sAreaPartnerKey == "")
    {
        if (GetIsObjectValid(oArea) && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: training partner init skipped for " + GetName(oNpc) + " (not matched to al_training_npc1_ref/al_training_npc2_ref).");
        }
        return;
    }

    object oPartner = OBJECT_INVALID;

    if (GetIsObjectValid(oArea))
    {
        // Resolve partner role from authoritative refs first.
        oRefPartner = GetLocalObject(oArea, sAreaPartnerRefKey);
        if (!GetIsObjectValid(oRefPartner) || GetArea(oRefPartner) != oArea)
        {
            oRefPartner = OBJECT_INVALID;
        }

        // Runtime cache may accelerate lookup only when consistent with refs.
        object oCachedSelf = GetLocalObject(oArea, sAreaSelfKey);
        object oCachedPartner = GetLocalObject(oArea, sAreaPartnerKey);

        if (GetIsObjectValid(oCachedSelf) && (oCachedSelf != oNpc || GetArea(oCachedSelf) != oArea))
        {
            DeleteLocalObject(oArea, sAreaSelfKey);
            bCacheRefMismatchRepaired = TRUE;
            oCachedSelf = OBJECT_INVALID;
        }

        if (GetIsObjectValid(oCachedPartner))
        {
            int bPartnerMismatch = (oCachedPartner != oRefPartner);
            if (GetArea(oCachedPartner) != oArea)
            {
                bPartnerMismatch = TRUE;
            }

            if (bPartnerMismatch)
            {
                DeleteLocalObject(oArea, sAreaPartnerKey);
                bCacheRefMismatchRepaired = TRUE;
                oCachedPartner = OBJECT_INVALID;
            }
        }

        SetLocalObject(oArea, sAreaSelfKey, oNpc);

        if (GetIsObjectValid(oRefPartner))
        {
            oPartner = oCachedPartner;
            if (!GetIsObjectValid(oPartner))
            {
                oPartner = oRefPartner;
                SetLocalObject(oArea, sAreaPartnerKey, oPartner);
            }
        }
        else
        {
            DeleteLocalObject(oArea, sAreaPartnerKey);
        }

        SetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED, GetIsObjectValid(oRefPartner));

        if (bCacheRefMismatchRepaired && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: cache/ref mismatch repaired.");
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
            if (oBack != oNpc)
            {
                // Existing pair is asymmetric in the same area, so this local link
                // is stale and must not be reused for requirement checks.
                DeleteLocalObject(oNpc, AL_L_BAR_PAIR);

                if (AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
                {
                    AL_SendDebugMessageToAreaPCs(oArea, "AL: asymmetric bar pair repaired for " + GetName(oNpc) + ".");
                }
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
    int bCacheRefMismatchRepaired = FALSE;

    // Resolve roles from refs first; cache is only a runtime accelerator after ref check.
    if (!GetIsObjectValid(oPartnerRef) || GetArea(oPartnerRef) != oArea)
    {
        oPartnerRef = OBJECT_INVALID;
    }

    object oCachedSelf = GetLocalObject(oArea, sAreaSelfKey);
    object oCachedPartner = GetLocalObject(oArea, sAreaPartnerKey);

    if (GetIsObjectValid(oCachedSelf) && (oCachedSelf != oNpc || GetArea(oCachedSelf) != oArea))
    {
        DeleteLocalObject(oArea, sAreaSelfKey);
        bCacheRefMismatchRepaired = TRUE;
        oCachedSelf = OBJECT_INVALID;
    }

    if (GetIsObjectValid(oCachedPartner))
    {
        int bPartnerMismatch = (oCachedPartner != oPartnerRef);
        if (GetArea(oCachedPartner) != oArea)
        {
            bPartnerMismatch = TRUE;
        }

        if (bPartnerMismatch)
        {
            DeleteLocalObject(oArea, sAreaPartnerKey);
            bCacheRefMismatchRepaired = TRUE;
            oCachedPartner = OBJECT_INVALID;
        }
    }

    SetLocalObject(oArea, sAreaSelfKey, oNpc);

    if (GetIsObjectValid(oPartnerRef))
    {
        oPartner = oCachedPartner;
        if (!GetIsObjectValid(oPartner))
        {
            oPartner = oPartnerRef;
            SetLocalObject(oArea, sAreaPartnerKey, oPartner);
        }
    }
    else
    {
        // Reference was replaced/invalidated: keep runtime pair unbound until a valid NPC appears.
        DeleteLocalObject(oArea, sAreaPartnerKey);
    }

    if (bCacheRefMismatchRepaired && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
    {
        AL_SendDebugMessageToAreaPCs(oArea, "AL: cache/ref mismatch repaired.");
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
