// Daily Life smoke event-ingress baseline.
// Minimal check for module contract initialization.

#include "dl_core_inc"

void main()
{
    object oModule = GetModule();

    DeleteLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION);
    SetLocalInt(oModule, DL_L_MODULE_ENABLED, TRUE);

    DL_InitModuleContract();

    int bRuntimeEnabled = DL_IsRuntimeEnabled();
    SetLocalInt(oModule, "dl_smoke_ev_runtime_enabled", bRuntimeEnabled);
}
