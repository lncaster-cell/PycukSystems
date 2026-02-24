// NPC Bhvr activity include.
// Здесь размещается адаптированный контентный слой активностей (AL primitives -> npc namespace).

const string NPC_BHVR_VAR_ACTIVITY_SLOT = "npc_activity_slot";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE = "npc_activity_route";
const string NPC_BHVR_VAR_ACTIVITY_STATE = "npc_activity_state";
const string NPC_BHVR_VAR_ACTIVITY_COOLDOWN = "npc_activity_cooldown";
const string NPC_BHVR_VAR_ACTIVITY_LAST = "npc_activity_last";
const string NPC_BHVR_VAR_ACTIVITY_LAST_TS = "npc_activity_last_ts";
const string NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE = "npc_activity_route_effective";

const string NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX = "npc_route_profile_slot_";
const string NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT = "npc_route_profile_default";

const string NPC_BHVR_ACTIVITY_SLOT_DEFAULT = "default";
const string NPC_BHVR_ACTIVITY_SLOT_PRIORITY = "priority";
const string NPC_BHVR_ACTIVITY_SLOT_CRITICAL = "critical";

const string NPC_BHVR_ACTIVITY_ROUTE_DEFAULT = "default_route";
const string NPC_BHVR_ACTIVITY_ROUTE_PRIORITY = "priority_patrol";
const string NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE = "critical_safe";

const int NPC_BHVR_ACTIVITY_HINT_IDLE = 1;
const int NPC_BHVR_ACTIVITY_HINT_PATROL = 2;
const int NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE = 3;

string NpcBhvrActivitySlotRouteProfileKey(string sSlot)
{
    return NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + sSlot;
}

string NpcBhvrActivityResolveRouteProfile(object oNpc, string sSlot)
{
    object oArea;
    string sRoute;

    if (!GetIsObjectValid(oNpc))
    {
        return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
    }

    sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    if (sRoute != "")
    {
        return NpcBhvrActivityAdapterNormalizeRoute(sRoute);
    }

    sRoute = GetLocalString(oNpc, NpcBhvrActivitySlotRouteProfileKey(sSlot));
    if (sRoute != "")
    {
        return NpcBhvrActivityAdapterNormalizeRoute(sRoute);
    }

    sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT);
    if (sRoute != "")
    {
        return NpcBhvrActivityAdapterNormalizeRoute(sRoute);
    }

    oArea = GetArea(oNpc);
    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
    }

    sRoute = GetLocalString(oArea, NpcBhvrActivitySlotRouteProfileKey(sSlot));
    if (sRoute != "")
    {
        return NpcBhvrActivityAdapterNormalizeRoute(sRoute);
    }

    sRoute = GetLocalString(oArea, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT);
    if (sRoute != "")
    {
        return NpcBhvrActivityAdapterNormalizeRoute(sRoute);
    }

    return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
}

string NpcBhvrActivityAdapterNormalizeSlot(string sSlot)
{
    // AL-concept adapter: slot-group normalization in npc namespace.
    if (sSlot == NPC_BHVR_ACTIVITY_SLOT_PRIORITY)
    {
        return NPC_BHVR_ACTIVITY_SLOT_PRIORITY;
    }

    if (sSlot == NPC_BHVR_ACTIVITY_SLOT_CRITICAL)
    {
        return NPC_BHVR_ACTIVITY_SLOT_CRITICAL;
    }

    return NPC_BHVR_ACTIVITY_SLOT_DEFAULT;
}

string NpcBhvrActivityAdapterNormalizeRoute(string sRouteId)
{
    // AL-concept adapter: route-id normalization in npc namespace.
    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY)
    {
        return NPC_BHVR_ACTIVITY_ROUTE_PRIORITY;
    }

    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE)
    {
        return NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE;
    }

    return NPC_BHVR_ACTIVITY_ROUTE_DEFAULT;
}

int NpcBhvrActivityMapRouteHint(string sRouteId)
{
    // Adapter mapping: npc_* profile -> AL-like activity semantics.
    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_CRITICAL_SAFE)
    {
        return NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE;
    }

    if (sRouteId == NPC_BHVR_ACTIVITY_ROUTE_PRIORITY)
    {
        return NPC_BHVR_ACTIVITY_HINT_PATROL;
    }

    return NPC_BHVR_ACTIVITY_HINT_IDLE;
}

void NpcBhvrActivityAdapterStampTransition(object oNpc, string sState)
{
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_STATE, sState);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_LAST, sState);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_LAST_TS, GetTimeHour() * 3600 + GetTimeMinute() * 60 + GetTimeSecond());
}

int NpcBhvrActivityAdapterIsCriticalSafe(string sSlot, int nRouteHint)
{
    return sSlot == NPC_BHVR_ACTIVITY_SLOT_CRITICAL || nRouteHint == NPC_BHVR_ACTIVITY_HINT_CRITICAL_SAFE;
}

int NpcBhvrActivityAdapterIsPriority(string sSlot, int nRouteHint)
{
    return sSlot == NPC_BHVR_ACTIVITY_SLOT_PRIORITY || nRouteHint == NPC_BHVR_ACTIVITY_HINT_PATROL;
}

void NpcBhvrActivityApplyCriticalSafeRoute(object oNpc)
{
    NpcBhvrActivityAdapterStampTransition(oNpc, "idle_critical_safe");
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, 1);
}

void NpcBhvrActivityApplyDefaultRoute(object oNpc)
{
    NpcBhvrActivityAdapterStampTransition(oNpc, "idle_default");
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, 1);
}

void NpcBhvrActivityApplyPriorityRoute(object oNpc)
{
    NpcBhvrActivityAdapterStampTransition(oNpc, "idle_priority_patrol");
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, 2);
}

void NpcBhvrActivityOnSpawn(object oNpc)
{
    string sSlot;
    string sRouteConfigured;
    string sRoute;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    // Обязательная spawn-инициализация profile-state в npc_* namespace.
    sSlot = NpcBhvrActivityAdapterNormalizeSlot(GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT));
    sRouteConfigured = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    if (sRouteConfigured != "")
    {
        sRouteConfigured = NpcBhvrActivityAdapterNormalizeRoute(sRouteConfigured);
    }

    sRoute = NpcBhvrActivityResolveRouteProfile(oNpc, sSlot);

    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, sSlot);
    if (sRouteConfigured != "")
    {
        SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE, sRouteConfigured);
    }
    else
    {
        DeleteLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    }

    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE, sRoute);

    NpcBhvrActivityAdapterStampTransition(oNpc, "spawn_ready");

    if (GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN) < 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, 0);
    }
}

void NpcBhvrActivityOnIdleTick(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int nCooldown = GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN);
    if (nCooldown > 0)
    {
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_COOLDOWN, nCooldown - 1);
        return;
    }

    string sSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT);
    string sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE);
    int nRouteHint;

    sSlot = NpcBhvrActivityAdapterNormalizeSlot(sSlot);
    sRoute = NpcBhvrActivityResolveRouteProfile(oNpc, sSlot);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, sSlot);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE, sRoute);

    nRouteHint = NpcBhvrActivityMapRouteHint(sRoute);

    // Dispatcher: CRITICAL-safe -> priority -> default fallback.
    if (NpcBhvrActivityAdapterIsCriticalSafe(sSlot, nRouteHint))
    {
        NpcBhvrActivityApplyCriticalSafeRoute(oNpc);
        return;
    }

    if (NpcBhvrActivityAdapterIsPriority(sSlot, nRouteHint))
    {
        NpcBhvrActivityApplyPriorityRoute(oNpc);
        return;
    }

    NpcBhvrActivityApplyDefaultRoute(oNpc);
}
