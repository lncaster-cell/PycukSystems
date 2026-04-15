// Dispatcher/resync smoke.

#include "dl_core_inc"

void main()
{
    object oNpc = GetFirstPC();
    object oModule = GetModule();

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oModule, DL_L_MODULE_ENABLED, TRUE);
    SetLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION, DL_CONTRACT_VERSION_A0);

    DL_RequestResync(oNpc, DL_RESYNC_USER);
    int bPendingBefore = GetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING);

    DL_ProcessResync(oNpc);
    int bPendingAfter = GetLocalInt(oNpc, DL_L_NPC_RESYNC_PENDING);

    SetLocalInt(oModule, "dl_smk_sync_before", bPendingBefore);
    SetLocalInt(oModule, "dl_smk_sync_after", bPendingAfter);
}
