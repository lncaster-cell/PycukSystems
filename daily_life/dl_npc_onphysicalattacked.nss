#include "dl_all_inc"

void main()
{
    if (DL_ShouldEmitAttackEvent(OBJECT_SELF))
    {
        DL_SignalNpcUserDefined(OBJECT_SELF, DL_UD_PHYSICAL_ATTACKED);
    }
}
