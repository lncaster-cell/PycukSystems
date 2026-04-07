#include "dl_all_inc"

void main()
{
    object oSeen = GetLastPerceived();
    if (DL_ShouldEmitPerceptionEvent(OBJECT_SELF, oSeen))
    {
        DL_SignalNpcUserDefined(OBJECT_SELF, DL_UD_PERCEPTION);
    }
}
