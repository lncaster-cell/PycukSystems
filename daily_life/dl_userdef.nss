#include "dl_core_inc"
#include "dl_blocked_inc"

void main()
{
    int nEvent = GetUserDefinedEventNumber();
    object oNpc = OBJECT_SELF;
    object oModule = GetModule();
    int nEventKind = GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND);

    if (nEvent == DL_UD_PIPELINE_NPC_EVENT && nEventKind == DL_NPC_EVENT_BLOCKED)
    {
        DL_HandleNpcBlocked(oNpc);
    }
    else
    {
        DL_HandleNpcUserDefined(oNpc, nEvent);
    }

    string sLog = "[DL][USERDEF] npc=" + GetName(oNpc) +
                  " event=" + IntToString(nEvent) +
                  " kind=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND)) +
                  " seq=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_EVENT_SEQ)) +
                  " pending=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING)) +
                  " state=" + GetLocalString(oNpc, DL_L_NPC_STATE) +
                  " reg=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_REG_ON)) +
                  " blocked_diag=" + GetLocalString(oNpc, DL_L_NPC_BLOCKED_DIAGNOSTIC) +
                  " spawn=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_SPAWN_COUNT)) +
                  " death=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_DEATH_COUNT));

    DL_LogRuntime(sLog);
}
