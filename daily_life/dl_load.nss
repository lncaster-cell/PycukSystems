#include "dl_core_inc"

void main()
{
    DL_InitModuleContract();

    object oModule = GetModule();
    object oPC = GetFirstPC();
    string sLog = "[DL][LOAD] runtime=" + IntToString(DL_IsRuntimeEnabled()) +
                  " enabled=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_ENABLED)) +
                  " contract=" + GetLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION);

    if (GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, sLog);
    }
    PrintString(sLog);
}
