#include "dl_core_inc"

void main()
{
    DL_InitModuleContract();

    object oModule = GetModule();
    string sLog = "[DL][LOAD] runtime=" + IntToString(DL_IsRuntimeEnabled()) +
                  " enabled=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_ENABLED)) +
                  " contract=" + GetLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION);

    DL_LogRuntime(sLog);
}
