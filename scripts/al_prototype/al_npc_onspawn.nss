// NPC OnSpawn: attach to NPC OnSpawn in the toolset.

#include "al_npc_acts_inc"
#include "al_npc_pair_inc"

void main()
{
    object oNpc = OBJECT_SELF;
    SetLocalInt(oNpc, "al_last_slot", -1);
    AL_InitTrainingPartner(oNpc);
    AL_InitBarPair(oNpc);

    object oArea = GetArea(oNpc);
    int bParticipant = AL_IsParticipantNPC(oNpc);

    if (bParticipant == TRUE)
    {
        AL_RegisterNPC(oNpc);

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
    else if (GetIsObjectValid(oArea) && AL_IsDebugLevelEnabled(oArea, OBJECT_INVALID, AL_DEBUG_LEVEL_L1))
    {
        string sTag = GetTag(oNpc);
        if (sTag == "")
        {
            sTag = "<no-tag>";
        }

        AL_SendDebugMessageToAreaPCs(oArea, "AL: OnSpawn ignored non-participant NPC '" + sTag + "'.");
    }
}
