// Module 3 activity include.
// Здесь размещается адаптированный контентный слой активностей (AL primitives -> module3 namespace).

const string MODULE3_VAR_ACTIVITY_SLOT = "module3_activity_slot";
const string MODULE3_VAR_ACTIVITY_ROUTE = "module3_activity_route";
const string MODULE3_VAR_ACTIVITY_STATE = "module3_activity_state";
const string MODULE3_VAR_ACTIVITY_COOLDOWN = "module3_activity_cooldown";

const string MODULE3_ACTIVITY_SLOT_DEFAULT = "default";
const string MODULE3_ACTIVITY_SLOT_PRIORITY = "priority";

const string MODULE3_ACTIVITY_ROUTE_DEFAULT = "default_route";
const string MODULE3_ACTIVITY_ROUTE_PRIORITY = "priority_patrol";

const int MODULE3_ACTIVITY_HINT_IDLE = 1;
const int MODULE3_ACTIVITY_HINT_PATROL = 2;

int Module3ActivityMapRouteHint(string sRouteId)
{
    // Adapter mapping: module3_* profile -> AL-like activity semantics.
    if (sRouteId == MODULE3_ACTIVITY_ROUTE_PRIORITY)
    {
        return MODULE3_ACTIVITY_HINT_PATROL;
    }

    return MODULE3_ACTIVITY_HINT_IDLE;
}

void Module3ActivityApplyDefaultRoute(object oNpc)
{
    SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_STATE, "idle_default");
    SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, 1);
}

void Module3ActivityApplyPriorityRoute(object oNpc)
{
    SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_STATE, "idle_priority_patrol");
    SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, 2);
}

void Module3ActivityOnSpawn(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Минимальная инициализация profile-state в module3_* namespace.
    if (GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT) == "")
    {
        SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT, MODULE3_ACTIVITY_SLOT_DEFAULT);
    }

    if (GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_ROUTE) == "")
    {
        SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_ROUTE, MODULE3_ACTIVITY_ROUTE_DEFAULT);
    }

    if (GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_STATE) == "")
    {
        SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_STATE, "spawn_ready");
    }

    if (GetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN) < 0)
    {
        SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, 0);
    }
}

void Module3ActivityOnIdleTick(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int nCooldown = GetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN);
    if (nCooldown > 0)
    {
        SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, nCooldown - 1);
        return;
    }

    string sSlot = GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT);
    string sRoute = GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_ROUTE);
    int nRouteHint;

    if (sSlot == "")
    {
        sSlot = MODULE3_ACTIVITY_SLOT_DEFAULT;
    }

    if (sRoute == "")
    {
        sRoute = MODULE3_ACTIVITY_ROUTE_DEFAULT;
    }

    nRouteHint = Module3ActivityMapRouteHint(sRoute);

    // Минимальный dispatcher: приоритетная ветка + fallback default route.
    if (sSlot == MODULE3_ACTIVITY_SLOT_PRIORITY || nRouteHint == MODULE3_ACTIVITY_HINT_PATROL)
    {
        Module3ActivityApplyPriorityRoute(oNpc);
        return;
    }

    Module3ActivityApplyDefaultRoute(oNpc);
}
