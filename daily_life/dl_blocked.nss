#include "dl_core_inc"
#include "dl_blocked_inc"

void main()
{
    object oNpc = OBJECT_SELF;
    object oBlocker = GetBlockingDoor();

    if (!DL_IsActivePipelineNpc(oNpc))
    {
        return;
    }

    if (!DL_IsRuntimeEnabled())
    {
        return;
    }

    if (!GetIsObjectValid(oBlocker))
    {
        SetLocalString(oNpc, DL_L_NPC_BLOCKED_DIAGNOSTIC, "blocked_invalid_object");
        return;
    }

    DL_RequestNpcBlockedSignal(oNpc, oBlocker);

    string sLog = "[DL][BLOCKED_SIGNAL] npc=" + GetName(oNpc) +
                  " blocker=" + GetTag(oBlocker) +
                  " type=" + IntToString(GetObjectType(oBlocker)) +
                  " kind=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND)) +
                  " seq=" + IntToString(GetLocalInt(oNpc, DL_L_NPC_EVENT_SEQ));

    DL_LogRuntime(sLog);
}
