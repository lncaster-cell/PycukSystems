// NPC pair wake-time revalidation helpers.

#include "al_constants_inc"
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

void AL_LogAreaRefOutOfArea(object oArea, string sRefKey)
{
    if (!GetIsObjectValid(oArea) || sRefKey == "")
    {
        return;
    }

    object oRef = GetLocalObject(oArea, sRefKey);
    if (!GetIsObjectValid(oRef) || GetArea(oRef) == oArea)
    {
        return;
    }

    AL_DebugLogL1(oArea, OBJECT_INVALID,
        "AL: wake revalidation warning: bootstrap ref '" + sRefKey + "' is not in current area; runtime cache kept intact.");

    AL_DebugLogL2(oArea, OBJECT_INVALID,
        "AL: wake revalidation warning: bootstrap ref '" + sRefKey + "' -> '" + GetTag(oRef)
        + "' belongs to area '" + GetTag(GetArea(oRef)) + "' (current='" + GetTag(oArea) + "'); key not cleared.");
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
        DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);
        DeleteLocalObject(oNpc, AL_L_BAR_PAIR);
        return;
    }

    int bDebug = AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1);
    int bClearedTraining = FALSE;
    int bClearedBar = FALSE;

    object oTrainingPartner = GetLocalObject(oNpc, AL_L_TRAINING_PARTNER);
    if (GetIsObjectValid(oTrainingPartner))
    {
        if (GetArea(oTrainingPartner) != oArea
            || GetLocalObject(oTrainingPartner, AL_L_TRAINING_PARTNER) != oNpc)
        {
            DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);
            bClearedTraining = TRUE;
        }
    }

    object oBarPair = GetLocalObject(oNpc, AL_L_BAR_PAIR);
    if (GetIsObjectValid(oBarPair))
    {
        if (GetArea(oBarPair) != oArea
            || GetLocalObject(oBarPair, AL_L_BAR_PAIR) != oNpc)
        {
            DeleteLocalObject(oNpc, AL_L_BAR_PAIR);
            bClearedBar = TRUE;
        }
    }

    // Area locals seeded via toolset/bootstrap:
    // - *_REF keys are long-lived configuration and must survive wake-time revalidation.
    // - non-REF pair keys are short-lived runtime cache and can be auto-cleared when stale.
    AL_ClearAreaPairKeyIfStale(oArea, AL_L_TRAINING_NPC1);
    AL_ClearAreaPairKeyIfStale(oArea, AL_L_TRAINING_NPC2);
    AL_ClearAreaPairKeyIfStale(oArea, AL_L_BAR_BARTENDER);
    AL_ClearAreaPairKeyIfStale(oArea, AL_L_BAR_BARMAID);

    AL_LogAreaRefOutOfArea(oArea, AL_L_TRAINING_NPC1_REF);
    AL_LogAreaRefOutOfArea(oArea, AL_L_TRAINING_NPC2_REF);
    AL_LogAreaRefOutOfArea(oArea, AL_L_BAR_BARTENDER_REF);
    AL_LogAreaRefOutOfArea(oArea, AL_L_BAR_BARMAID_REF);

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
