// NPC OnSpawn: attach to NPC OnSpawn in the toolset.

#include "al_constants_inc"
#include "al_npc_acts_inc"
#include "al_npc_reg_inc"

void AL_InitTrainingPartner(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    object oExistingPartner = GetLocalObject(oNpc, "al_training_partner");
    if (GetIsObjectValid(oExistingPartner))
    {
        object oAreaSelf = GetArea(oNpc);
        object oAreaPartner = GetArea(oExistingPartner);

        if (GetIsObjectValid(oAreaSelf) && oAreaPartner == oAreaSelf)
        {
            object oPartnerBacklink = GetLocalObject(oExistingPartner, "al_training_partner");
            if (oPartnerBacklink == oNpc)
            {
                // Keep early-return only for a fully valid, symmetric in-area pair.
                return;
            }

            // Partner points elsewhere: drop only the stale one-sided link on this NPC.
            DeleteLocalObject(oNpc, "al_training_partner");
        }
        else
        {
            // Existing partner is stale (invalid or in another area).
            DeleteLocalObject(oNpc, "al_training_partner");
        }
    }

    string sTag = GetTag(oNpc);
    string sAreaPartnerKey = "";
    string sAreaSelfKey = "";
    string sAreaPartnerRefKey = "";
    int bResetCache = FALSE;

    if (sTag == "FACTION_NPC1")
    {
        sAreaSelfKey = "al_training_npc1";
        sAreaPartnerKey = "al_training_npc2";
        sAreaPartnerRefKey = "al_training_npc2_ref";
    }
    else if (sTag == "FACTION_NPC2")
    {
        sAreaSelfKey = "al_training_npc2";
        sAreaPartnerKey = "al_training_npc1";
        sAreaPartnerRefKey = "al_training_npc1_ref";
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
        // "al_training_npc1_ref" / "al_training_npc2_ref" point to the pair.
        if (GetLocalInt(oArea, "al_training_partner_cached"))
        {
            object oCachedSelf = GetLocalObject(oArea, sAreaSelfKey);
            object oCachedPartner = GetLocalObject(oArea, sAreaPartnerKey);
            if (!GetIsObjectValid(oCachedSelf) || !GetIsObjectValid(oCachedPartner))
            {
                SetLocalInt(oArea, "al_training_partner_cached", FALSE);
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
        object oAreaNpc1 = GetLocalObject(oArea, "al_training_npc1");
        object oAreaNpc2 = GetLocalObject(oArea, "al_training_npc2");
        int bHasRestoredPair = GetIsObjectValid(oAreaNpc1)
            && GetIsObjectValid(oAreaNpc2)
            && GetArea(oAreaNpc1) == oArea
            && GetArea(oAreaNpc2) == oArea;

        SetLocalInt(oArea, "al_training_partner_cached", bHasRestoredPair);

        if (!bHasRestoredPair && GetLocalInt(oArea, "al_debug") == 1)
        {
            object oPc = GetFirstPC(FALSE);
            while (GetIsObjectValid(oPc))
            {
                if (GetArea(oPc) == oArea)
                {
                    SendMessageToPC(oPc, "AL: training partner cache reset; pair restore failed.");
                }
                oPc = GetNextPC(FALSE);
            }
        }
    }

    if (GetIsObjectValid(oPartner) && oPartner != oNpc)
    {
        SetLocalObject(oNpc, "al_training_partner", oPartner);

        if (GetArea(oPartner) == GetArea(oNpc))
        {
            SetLocalObject(oPartner, "al_training_partner", oNpc);
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

    object oExistingPair = GetLocalObject(oNpc, "al_bar_pair");
    if (GetIsObjectValid(oExistingPair))
    {
        if (GetArea(oExistingPair) == oArea)
        {
            return;
        }

        DeleteLocalObject(oNpc, "al_bar_pair");

        if (GetLocalInt(oArea, "al_debug") == 1)
        {
            object oPc = GetFirstPC(FALSE);
            while (GetIsObjectValid(oPc))
            {
                if (GetArea(oPc) == oArea)
                {
                    SendMessageToPC(oPc, "AL: stale bar pair reset for " + GetName(oNpc) + ".");
                }
                oPc = GetNextPC(FALSE);
            }
        }
    }

    object oBartenderRef = GetLocalObject(oArea, "al_bar_bartender_ref");
    object oBarmaidRef = GetLocalObject(oArea, "al_bar_barmaid_ref");
    string sAreaPartnerKey = "";
    string sAreaSelfKey = "";
    object oPartnerRef = OBJECT_INVALID;

    if (oNpc == oBartenderRef)
    {
        // Symmetric role mapping: bartender looks up barmaid and vice versa.
        sAreaSelfKey = "al_bar_bartender";
        sAreaPartnerKey = "al_bar_barmaid";
        oPartnerRef = oBarmaidRef;
    }
    else if (oNpc == oBarmaidRef)
    {
        sAreaSelfKey = "al_bar_barmaid";
        sAreaPartnerKey = "al_bar_bartender";
        oPartnerRef = oBartenderRef;
    }

    if (sAreaPartnerKey == "")
    {
        return;
    }

    object oPartner = OBJECT_INVALID;

    // Area locals seeded via toolset/bootstrap:
    // "al_bar_bartender_ref" / "al_bar_barmaid_ref" point to the pair.
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
        SetLocalObject(oNpc, "al_bar_pair", oPartner);
        SetLocalObject(oPartner, "al_bar_pair", oNpc);
    }
}

void main()
{
    object oNpc = OBJECT_SELF;
    SetLocalInt(oNpc, "al_last_slot", -1);
    AL_InitTrainingPartner(oNpc);
    AL_InitBarPair(oNpc);

    object oArea = GetArea(oNpc);
    if (AL_IsParticipantNPC(oNpc))
    {
        AL_RegisterNPC(oNpc);
    }
    else if (GetIsObjectValid(oArea) && GetLocalInt(oArea, "al_debug") == 1)
    {
        string sTag = GetTag(oNpc);
        if (sTag == "")
        {
            sTag = "<no-tag>";
        }

        object oPc = GetFirstPC(FALSE);
        while (GetIsObjectValid(oPc))
        {
            if (GetArea(oPc) == oArea)
            {
                SendMessageToPC(oPc, "AL: OnSpawn ignored non-participant NPC '" + sTag + "'.");
            }
            oPc = GetNextPC(FALSE);
        }
    }

    if (GetIsObjectValid(oArea))
    {
        int iSlotCount = GetLocalInt(oArea, "al_player_count");
        if (iSlotCount > 0)
        {
            if (GetScriptHidden(oNpc))
            {
                SetScriptHidden(oNpc, FALSE, FALSE);
            }
            SignalEvent(oNpc, EventUserDefined(AL_EVT_RESYNC));
        }
        else
        {
            SetScriptHidden(oNpc, TRUE, TRUE);
        }
    }
}
