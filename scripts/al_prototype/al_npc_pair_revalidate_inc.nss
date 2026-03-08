// NPC pair wake-time revalidation helpers.

#include "al_debug_inc"

// Include layering contract (one-way):
// - al_npc_pair_revalidate_inc -> {al_debug_inc}
// - al_npc_acts_inc            -> compatibility wrapper only (no runtime logic)
//                                 forwards to {al_npc_activity_apply_inc, al_npc_sleep_inc, al_npc_pair_revalidate_inc}.
// This module is intentionally isolated from route/activity includes.

void AL_ClearAreaPairKeyIfStale(object oArea, string sAreaKey)
{
    if (!GetIsObjectValid(oArea) || sAreaKey == "")
    {
        return;
    }

    object oAreaPair = GetLocalObject(oArea, sAreaKey);
    if (GetIsObjectValid(oAreaPair) && GetArea(oAreaPair) != oArea)
    {
        DeleteLocalObject(oArea, sAreaKey);
    }
}

void AL_RevalidateAreaPairLinksForWake(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    object oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        DeleteLocalObject(oNpc, "al_training_partner");
        DeleteLocalObject(oNpc, "al_bar_pair");
        return;
    }

    int bDebug = AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1);
    int bClearedTraining = FALSE;
    int bClearedBar = FALSE;

    object oTrainingPartner = GetLocalObject(oNpc, "al_training_partner");
    if (GetIsObjectValid(oTrainingPartner))
    {
        if (GetArea(oTrainingPartner) != oArea
            || GetLocalObject(oTrainingPartner, "al_training_partner") != oNpc)
        {
            DeleteLocalObject(oNpc, "al_training_partner");
            bClearedTraining = TRUE;
        }
    }

    object oBarPair = GetLocalObject(oNpc, "al_bar_pair");
    if (GetIsObjectValid(oBarPair))
    {
        if (GetArea(oBarPair) != oArea
            || GetLocalObject(oBarPair, "al_bar_pair") != oNpc)
        {
            DeleteLocalObject(oNpc, "al_bar_pair");
            bClearedBar = TRUE;
        }
    }

    // Keep area-level runtime pair cache clean so slot wake/resync never reuses stale links.
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc1");
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc2");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_bartender");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_barmaid");
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc1_ref");
    AL_ClearAreaPairKeyIfStale(oArea, "al_training_npc2_ref");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_bartender_ref");
    AL_ClearAreaPairKeyIfStale(oArea, "al_bar_barmaid_ref");

    if (bDebug)
    {
        if (bClearedTraining)
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: wake revalidation cleared stale training link for " + GetName(oNpc) + ".");
        }

        if (bClearedBar)
        {
            AL_SendDebugMessageToAreaPCs(oArea, "AL: wake revalidation cleared stale bar link for " + GetName(oNpc) + ".");
        }
    }
}
