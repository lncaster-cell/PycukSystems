#include "dl_core_inc"
#include "dl_blocked_inc"

void main()
{
    int nEvent = GetUserDefinedEventNumber();
    object oNpc = OBJECT_SELF;
    int nEventKind = GetLocalInt(oNpc, DL_L_NPC_EVENT_KIND);

    if (nEvent != DL_UD_PIPELINE_NPC_EVENT)
    {
        return;
    }

    if (nEventKind == DL_NPC_EVENT_BLOCKED)
    {
        DL_HandleNpcBlocked(oNpc);
        DL_MaybeLogNpcDiagnostic(oNpc, "userdef_blocked", FALSE);
        return;
    }

    DL_HandleNpcUserDefined(oNpc, nEvent);
    DL_MaybeLogNpcDiagnostic(oNpc, "userdef_lifecycle", FALSE);
}
