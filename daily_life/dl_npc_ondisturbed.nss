#include "dl_all_inc"

void main()
{
    if (DL_ShouldEmitDisturbedEvent(OBJECT_SELF))
    {
        DL_SignalNpcUserDefined(OBJECT_SELF, DL_UD_DISTURBED);
    }
}
