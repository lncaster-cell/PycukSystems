#include "dl_core_inc"
#include "dl_blocked_inc"

void main()
{
    int nEvent = GetUserDefinedEventNumber();
    object oNpc = OBJECT_SELF;
    int nEventKind = GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND);

    if (nEvent == DL_UD_PIPELINE_NPC_EVENT && nEventKind == DL_NPC_EVENT_BLOCKED)
    {
        DL_HandleNpcBlocked(oNpc);
    }
    else
    {
        DL_HandleNpcUserDefined(oNpc, nEvent);
    }

    string sLog = "[DL][NPC] npc=" + GetName(oNpc) +
                  " hour=" + IntToString(GetTimeHour()) +
                  " profile=" + GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) +
                  " directive=" + DL_GetDirectiveLabel(GetLocalInt(oNpc, DL_L_NPC_DIRECTIVE)) +
                  " state=" + GetLocalString(oNpc, DL_L_NPC_STATE) +
                  " problem=" + DL_GetNpcProblemSummary(oNpc) +
                  " sleep_status=" + GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS) +
                  " sleep_target=" + GetLocalString(oNpc, DL_L_NPC_SLEEP_TARGET) +
                  " work_status=" + GetLocalString(oNpc, DL_L_NPC_WORK_STATUS) +
                  " work_target=" + GetLocalString(oNpc, DL_L_NPC_WORK_TARGET) +
                  " transition_status=" + GetLocalString(oNpc, DL_L_NPC_TRANSITION_STATUS) +
                  " transition_target=" + GetLocalString(oNpc, DL_L_NPC_TRANSITION_TARGET);

    DL_LogRuntime(sLog);
}
