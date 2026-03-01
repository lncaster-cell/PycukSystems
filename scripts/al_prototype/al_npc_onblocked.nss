// NPC OnBlocked: attach to NPC OnBlocked in the toolset.
// Tries to open a nearby closed door when movement is blocked.

void AL_TryOpenNearestDoor(object oNpc)
{
    object oDoor = GetNearestObject(OBJECT_TYPE_DOOR, oNpc, 1);
    if (!GetIsObjectValid(oDoor))
    {
        return;
    }

    if (GetDistanceBetween(oNpc, oDoor) > 3.0)
    {
        return;
    }

    if (GetIsOpen(oDoor))
    {
        return;
    }

    AssignCommand(oNpc, ActionOpenDoor(oDoor));
}

void main()
{
    object oNpc = OBJECT_SELF;
    AL_TryOpenNearestDoor(oNpc);
}
