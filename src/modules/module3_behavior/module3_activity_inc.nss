// Module 3 activity include.
// Здесь размещается адаптированный контентный слой активностей (AL primitives -> module3 namespace).

const string MODULE3_VAR_ACTIVITY_SLOT = "module3_activity_slot";
const string MODULE3_VAR_ACTIVITY_ROUTE = "module3_activity_route";
const string MODULE3_VAR_ACTIVITY_STATE = "module3_activity_state";
const string MODULE3_VAR_ACTIVITY_COOLDOWN = "module3_activity_cooldown";
const string MODULE3_VAR_ACTIVITY_LAST = "module3_activity_last";
const string MODULE3_VAR_ACTIVITY_LAST_TS = "module3_activity_last_ts";

const string MODULE3_ACTIVITY_SLOT_DEFAULT = "default";
const string MODULE3_ACTIVITY_SLOT_PRIORITY = "priority";
const string MODULE3_ACTIVITY_SLOT_CRITICAL = "critical";

const string MODULE3_ACTIVITY_ROUTE_DEFAULT = "default_route";
const string MODULE3_ACTIVITY_ROUTE_PRIORITY = "priority_patrol";
const string MODULE3_ACTIVITY_ROUTE_CRITICAL_SAFE = "critical_safe";

const int MODULE3_ACTIVITY_HINT_IDLE = 1;
const int MODULE3_ACTIVITY_HINT_PATROL = 2;
const int MODULE3_ACTIVITY_HINT_CRITICAL_SAFE = 3;

string Module3ActivityAdapterNormalizeSlot(string sSlot)
{
    // AL-concept adapter: slot-group normalization in module3 namespace.
    if (sSlot == MODULE3_ACTIVITY_SLOT_PRIORITY)
    {
        return MODULE3_ACTIVITY_SLOT_PRIORITY;
    }

    if (sSlot == MODULE3_ACTIVITY_SLOT_CRITICAL)
    {
        return MODULE3_ACTIVITY_SLOT_CRITICAL;
    }

    return MODULE3_ACTIVITY_SLOT_DEFAULT;
}

string Module3ActivityAdapterNormalizeRoute(string sRouteId)
{
    // AL-concept adapter: route-id normalization in module3 namespace.
    if (sRouteId == MODULE3_ACTIVITY_ROUTE_PRIORITY)
    {
        return MODULE3_ACTIVITY_ROUTE_PRIORITY;
    }

    if (sRouteId == MODULE3_ACTIVITY_ROUTE_CRITICAL_SAFE)
    {
        return MODULE3_ACTIVITY_ROUTE_CRITICAL_SAFE;
    }

    return MODULE3_ACTIVITY_ROUTE_DEFAULT;
}

int Module3ActivityMapRouteHint(string sRouteId)
{
    // Adapter mapping: module3_* profile -> AL-like activity semantics.
    if (sRouteId == MODULE3_ACTIVITY_ROUTE_CRITICAL_SAFE)
    {
        return MODULE3_ACTIVITY_HINT_CRITICAL_SAFE;
    }

    if (sRouteId == MODULE3_ACTIVITY_ROUTE_PRIORITY)
    {
        return MODULE3_ACTIVITY_HINT_PATROL;
    }

    return MODULE3_ACTIVITY_HINT_IDLE;
}

void Module3ActivityAdapterStampTransition(object oNpc, string sState)
{
    SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_STATE, sState);
    SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_LAST, sState);
    SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_LAST_TS, GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond());
}

int Module3ActivityAdapterIsCriticalSafe(string sSlot, int nRouteHint)
{
    return sSlot == MODULE3_ACTIVITY_SLOT_CRITICAL || nRouteHint == MODULE3_ACTIVITY_HINT_CRITICAL_SAFE;
}

int Module3ActivityAdapterIsPriority(string sSlot, int nRouteHint)
{
    return sSlot == MODULE3_ACTIVITY_SLOT_PRIORITY || nRouteHint == MODULE3_ACTIVITY_HINT_PATROL;
}

void Module3ActivityApplyCriticalSafeRoute(object oNpc)
{
    Module3ActivityAdapterStampTransition(oNpc, "idle_critical_safe");
    SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, 1);
}

void Module3ActivityApplyDefaultRoute(object oNpc)
{
    Module3ActivityAdapterStampTransition(oNpc, "idle_default");
    SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, 1);
}

void Module3ActivityApplyPriorityRoute(object oNpc)
{
    Module3ActivityAdapterStampTransition(oNpc, "idle_priority_patrol");
    SetLocalInt(oNpc, MODULE3_VAR_ACTIVITY_COOLDOWN, 2);
}

void Module3ActivityOnSpawn(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Обязательная spawn-инициализация profile-state в module3_* namespace.
    SetLocalString(
        oNpc,
        MODULE3_VAR_ACTIVITY_SLOT,
        Module3ActivityAdapterNormalizeSlot(GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT))
    );

    SetLocalString(
        oNpc,
        MODULE3_VAR_ACTIVITY_ROUTE,
        Module3ActivityAdapterNormalizeRoute(GetLocalString(oNpc, MODULE3_VAR_ACTIVITY_ROUTE))
    );

    Module3ActivityAdapterStampTransition(oNpc, "spawn_ready");

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

    sSlot = Module3ActivityAdapterNormalizeSlot(sSlot);
    sRoute = Module3ActivityAdapterNormalizeRoute(sRoute);
    SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_SLOT, sSlot);
    SetLocalString(oNpc, MODULE3_VAR_ACTIVITY_ROUTE, sRoute);

    nRouteHint = Module3ActivityMapRouteHint(sRoute);

    // Dispatcher: CRITICAL-safe -> priority -> default fallback.
    if (Module3ActivityAdapterIsCriticalSafe(sSlot, nRouteHint))
    {
        Module3ActivityApplyCriticalSafeRoute(oNpc);
        return;
    }

    if (Module3ActivityAdapterIsPriority(sSlot, nRouteHint))
    {
        Module3ActivityApplyPriorityRoute(oNpc);
        return;
    }

    Module3ActivityApplyDefaultRoute(oNpc);
}
