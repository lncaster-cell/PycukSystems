// Door OnOpen helper: attach to Door OnOpen in the toolset.
// Starts/restarts a 10 second timer and closes the door when timer expires.

#include "al_constants_inc"

void AL_CloseDoorIfTimerIsCurrent(object oDoor, int nToken)
{
    if (!GetIsObjectValid(oDoor))
    {
        return;
    }

    if (GetLocalInt(oDoor, AL_L_AUTO_CLOSE_TOKEN) != nToken)
    {
        return;
    }

    if (!GetIsOpen(oDoor))
    {
        return;
    }

    AssignCommand(oDoor, ActionCloseDoor(oDoor));
}

void main()
{
    object oDoor = OBJECT_SELF;
    int nToken = GetLocalInt(oDoor, AL_L_AUTO_CLOSE_TOKEN) + 1;
    SetLocalInt(oDoor, AL_L_AUTO_CLOSE_TOKEN, nToken);

    DelayCommand(10.0, AL_CloseDoorIfTimerIsCurrent(oDoor, nToken));
}
