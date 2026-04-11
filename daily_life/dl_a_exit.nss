#include "dl_core_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oExit = GetExitingObject();

    DL_OnAreaExitBootstrap(oArea, oExit);

    object oPC = GetFirstPC();
    string sActor = GetIsObjectValid(oExit) ? GetName(oExit) : "<invalid>";
    string sLog = "[DL][AREA_EXIT] area=" + GetName(oArea) +
                  " actor=" + sActor +
                  " tier=" + IntToString(DL_GetAreaTier(oArea)) +
                  " reg=" + IntToString(GetLocalInt(oArea, DL_L_AREA_REG_COUNT));

    if (GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, sLog);
    }
    PrintString(sLog);
}
