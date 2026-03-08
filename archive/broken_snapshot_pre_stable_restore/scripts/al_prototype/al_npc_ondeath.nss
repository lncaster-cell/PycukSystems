// NPC OnDeath: attach to NPC OnDeath in the toolset.

#include "al_constants_inc"
#include "al_debug_inc"
#include "al_npc_reg_inc"

void main()
{
    object oNpc = OBJECT_SELF;
    object oPartner = GetLocalObject(oNpc, AL_L_TRAINING_PARTNER);
    if (GetIsObjectValid(oPartner))
    {
        DeleteLocalObject(oPartner, AL_L_TRAINING_PARTNER);
    }
    DeleteLocalObject(oNpc, AL_L_TRAINING_PARTNER);

    object oBarPair = GetLocalObject(oNpc, AL_L_BAR_PAIR);
    if (GetIsObjectValid(oBarPair))
    {
        DeleteLocalObject(oBarPair, AL_L_BAR_PAIR);
    }
    DeleteLocalObject(oNpc, AL_L_BAR_PAIR);

    object oArea = GetArea(oNpc);
    if (GetIsObjectValid(oArea))
    {
        object oNpc1Ref = GetLocalObject(oArea, AL_L_TRAINING_NPC1_REF);
        object oNpc2Ref = GetLocalObject(oArea, AL_L_TRAINING_NPC2_REF);
        int bResetTrainingCache = FALSE;

        if (oNpc == oNpc1Ref)
        {
            DeleteLocalObject(oArea, AL_L_TRAINING_NPC1);
            bResetTrainingCache = TRUE;
        }
        else if (oNpc == oNpc2Ref)
        {
            DeleteLocalObject(oArea, AL_L_TRAINING_NPC2);
            bResetTrainingCache = TRUE;
        }

        if (bResetTrainingCache)
        {
            SetLocalInt(oArea, AL_L_TRAINING_PARTNER_CACHED, FALSE);

            AL_DebugLogL1(oArea, oNpc, "AL: training partner cache reset on death of " + GetName(oNpc) + ".");
        }
    }

    if (GetIsObjectValid(oArea))
    {
        if (GetLocalObject(oArea, AL_L_BAR_BARTENDER) == oNpc)
        {
            DeleteLocalObject(oArea, AL_L_BAR_BARTENDER);
        }
        if (GetLocalObject(oArea, AL_L_BAR_BARMAID) == oNpc)
        {
            DeleteLocalObject(oArea, AL_L_BAR_BARMAID);
        }
    }
    AL_UnregisterNPC(oNpc);
}
