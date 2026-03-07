// NPC OnDeath: attach to NPC OnDeath in the toolset.

#include "al_debug_inc"
#include "al_npc_reg_inc"

void main()
{
    object oNpc = OBJECT_SELF;
    object oPartner = GetLocalObject(oNpc, "al_training_partner");
    if (GetIsObjectValid(oPartner))
    {
        DeleteLocalObject(oPartner, "al_training_partner");
    }
    DeleteLocalObject(oNpc, "al_training_partner");

    object oBarPair = GetLocalObject(oNpc, "al_bar_pair");
    if (GetIsObjectValid(oBarPair))
    {
        DeleteLocalObject(oBarPair, "al_bar_pair");
    }
    DeleteLocalObject(oNpc, "al_bar_pair");

    object oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        object oNpc1Ref = GetLocalObject(oArea, "al_training_npc1_ref");
        object oNpc2Ref = GetLocalObject(oArea, "al_training_npc2_ref");
        int bResetTrainingCache = FALSE;

        if (oNpc == oNpc1Ref)
        {
            DeleteLocalObject(oArea, "al_training_npc1");
            bResetTrainingCache = TRUE;
        }
        else if (oNpc == oNpc2Ref)
        {
            DeleteLocalObject(oArea, "al_training_npc2");
            bResetTrainingCache = TRUE;
        }

        if (bResetTrainingCache)
        {
            SetLocalInt(oArea, "al_training_partner_cached", FALSE);

            if (GetLocalInt(oArea, "al_debug") == 1)
            {
                AL_SendDebugMessageToAreaPCs(oArea,
                    "AL: training partner cache reset on death of " + GetName(oNpc) + ".");
            }
        }
    }

    if (GetIsObjectValid(oArea))
    {
        if (GetLocalObject(oArea, "al_bar_bartender") == oNpc)
        {
            DeleteLocalObject(oArea, "al_bar_bartender");

            object oBartenderRef = GetLocalObject(oArea, "al_bar_bartender_ref");
            if (!GetIsObjectValid(oBartenderRef) || oBartenderRef == oNpc)
            {
                DeleteLocalObject(oArea, "al_bar_bartender_ref");
            }
        }
        if (GetLocalObject(oArea, "al_bar_barmaid") == oNpc)
        {
            DeleteLocalObject(oArea, "al_bar_barmaid");

            object oBarmaidRef = GetLocalObject(oArea, "al_bar_barmaid_ref");
            if (!GetIsObjectValid(oBarmaidRef) || oBarmaidRef == oNpc)
            {
                DeleteLocalObject(oArea, "al_bar_barmaid_ref");
            }
        }
    }
    AL_UnregisterNPC(oNpc);
}
