// Module 3 activity include.
// Здесь размещается адаптированный контентный слой активностей (AL primitives -> module3 namespace).

const string MODULE3_VAR_ACTIVITY_SLOT = "module3_activity_slot";
const string MODULE3_VAR_ACTIVITY_ROUTE = "module3_activity_route";

void Module3ActivityOnSpawn(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // TODO(module3): bind AL-derived activity profile on spawn.
    if (GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT) == "")
    {
        SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT, "default");
    }
}

void Module3ActivityOnIdleTick(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // TODO(module3): route/slot orchestration will be implemented in follow-up tasks.
}
