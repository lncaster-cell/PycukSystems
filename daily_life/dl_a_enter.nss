#include "dl_core_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oEnter = GetEnteringObject();

    DL_OnAreaEnterBootstrap(oArea, oEnter);

    string sActor = GetIsObjectValid(oEnter) ? GetName(oEnter) : "<invalid>";
    string sLog = "[DL][AREA_ENTER] area=" + GetName(oArea) +
                  " actor=" + sActor +
                  " tier=" + IntToString(DL_GetAreaTier(oArea)) +
                  " reg=" + IntToString(GetLocalInt(oArea, DL_L_AREA_REG_COUNT)) +
                  " resync_req=" + IntToString(GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_PENDING));

    DL_LogRuntime(sLog);
}
