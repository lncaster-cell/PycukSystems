#include "dl_core_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oModule = GetModule();

    DL_RunAreaWorkerTick(oArea);

    string sLog = "[DL][HB] area=" + GetName(oArea) +
                  " tier=" + IntToString(DL_GetAreaTier(oArea)) +
                  " tick=" + IntToString(GetLocalInt(oArea, DL_L_AREA_WORKER_TICK)) +
                  " worker=" + IntToString(GetLocalInt(oModule, DL_L_MODULE_WORKER_TICKS)) +
                  " reg=" + IntToString(GetLocalInt(oArea, DL_L_AREA_REG_COUNT)) +
                  " cur=" + IntToString(DL_GetAreaWorkerCursor(oArea)) +
                  " budget=" + IntToString(DL_GetAreaWorkerBudget(oArea)) +
                  " rs_pend=" + IntToString(GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_PENDING)) +
                  " rs_touch=" + IntToString(GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_TOUCHED)) +
                  " rs_done=" + IntToString(GetLocalInt(oArea, DL_L_AREA_ENTER_RESYNC_DONE));

    DL_LogRuntime(sLog);
}
