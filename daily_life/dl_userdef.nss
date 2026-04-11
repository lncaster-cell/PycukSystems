#include "dl_core_inc"

void main()
{
    int nEvent = GetUserDefinedEventNumber();
    object oNpc = OBJECT_SELF;
    object oModule = GetModule();

    DL_HandleNpcUserDefined(oNpc, nEvent);

    object oPC = GetFirstPC();
    string sLog = "[DL][USERDEF] npc=" + GetName(oNpc) +
                  " event=" + IntToString(nEvent) +
                  " kind=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND)) +
                  " seq=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_EVENT_SEQ)) +
                  " pending=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING)) +
                  " state=" + GetLocalString(oNpc, DL_L_NPC_STATE) +
                  " reg=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_REG_ON)) +
                  " spawn=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_SPAWN_COUNT)) +
                  " death=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_DEATH_COUNT));

    if (GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, sLog);
    }
    PrintString(sLog);
}
