// Area tier bootstrap smoke.

#include "dl_core_inc"

void main()
{
    object oArea = OBJECT_SELF;
    if (!DL_IsAreaObject(oArea))
    {
        oArea = GetArea(GetFirstPC());
    }

    if (!DL_IsAreaObject(oArea))
    {
        return;
    }

    DeleteLocalInt(oArea, DL_L_AREA_TIER);
    DL_BootstrapAreaTier(oArea);

    SetLocalInt(oArea, "dl_smk_tier_value", DL_GetAreaTier(oArea));
}
