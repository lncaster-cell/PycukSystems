// Door OnOpen helper: attach to Door OnOpen in the toolset.
// Starts/restarts a 10 second timer and closes the door when timer expires.

void AL_CloseDoorIfTimerIsCurrent(object oDoor, int nToken)
{
    if (!GetIsObjectValid(oDoor))
    {
        return;
    }

    if (GetLocalInt(oDoor, "al_auto_close_token") != nToken)
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
    int nToken = GetLocalInt(oDoor, "al_auto_close_token") + 1;
    SetLocalInt(oDoor, "al_auto_close_token", nToken);

    DelayCommand(10.0, AL_CloseDoorIfTimerIsCurrent(oDoor, nToken));
}
