// Step 04 worker smoke.

#include "dl_core_inc"

void main()
{
    object oArea = OBJECT_SELF;
    object oModule = GetModule();

    if (GetObjectType(oArea) != OBJECT_TYPE_AREA)
    {
        oArea = GetArea(GetFirstPC());
    }

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    SetLocalInt(oModule, DL_L_MODULE_ENABLED, TRUE);
    SetLocalString(oModule, DL_L_MODULE_CONTRACT_VERSION, DL_CONTRACT_VERSION_A0);

    DeleteLocalInt(oArea, DL_L_AREA_WORKER_CURSOR);
    DeleteLocalInt(oArea, DL_L_AREA_WORKER_BUDGET);

    DL_BootstrapAreaTier(oArea);
    DL_RunAreaWorkerTick(oArea);

    SetLocalInt(oArea, "dl_smk_work_cur", DL_GetAreaWorkerCursor(oArea));
    SetLocalInt(oArea, "dl_smk_work_tik", GetLocalInt(oArea, DL_L_AREA_WORKER_TICK));
}
