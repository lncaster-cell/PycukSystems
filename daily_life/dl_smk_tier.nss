// Area tier bootstrap smoke.

#include "dl_core_inc"

void main()
{
    object oArea = OBJECT_SELF;
    if (GetObjectType(oArea) != OBJECT_TYPE_AREA)
    {
        oArea = GetArea(GetFirstPC());
    }

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    DeleteLocalInt(oArea, DL_L_AREA_TIER);
    DL_BootstrapAreaTier(oArea);

    SetLocalInt(oArea, "dl_smk_tier_value", DL_GetAreaTier(oArea));
}
