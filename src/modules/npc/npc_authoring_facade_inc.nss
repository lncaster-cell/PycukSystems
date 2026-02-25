// NPC authoring facade (preset-first human contract -> existing runtime locals).
// Thin layer: only normalizes npc_cfg_* authoring locals and derives runtime defaults.

const string NPC_BHVR_CFG_ROLE = "npc_cfg_role";
const string NPC_BHVR_CFG_SLOT_DAWN_ROUTE = "npc_cfg_slot_dawn_route";
const string NPC_BHVR_CFG_SLOT_MORNING_ROUTE = "npc_cfg_slot_morning_route";
const string NPC_BHVR_CFG_SLOT_AFTERNOON_ROUTE = "npc_cfg_slot_afternoon_route";
const string NPC_BHVR_CFG_SLOT_EVENING_ROUTE = "npc_cfg_slot_evening_route";
const string NPC_BHVR_CFG_SLOT_NIGHT_ROUTE = "npc_cfg_slot_night_route";
const string NPC_BHVR_CFG_ALERT_ROUTE = "npc_cfg_alert_route";

// Legacy/compat authoring locals (migration-only path).
const string NPC_BHVR_CFG_SCHEDULE = "npc_cfg_schedule";
const string NPC_BHVR_CFG_WORK_ROUTE = "npc_cfg_work_route";
const string NPC_BHVR_CFG_HOME_ROUTE = "npc_cfg_home_route";
const string NPC_BHVR_CFG_LEISURE_ROUTE = "npc_cfg_leisure_route";

const string NPC_BHVR_CFG_FORCE_REACTIVE = "npc_cfg_force_reactive"; // canonical reactive override
const string NPC_BHVR_CFG_ALLOW_PHYSICAL_HIDE = "npc_cfg_allow_physical_hide";

const string NPC_BHVR_CFG_CITY = "npc_cfg_city";
const string NPC_BHVR_CFG_CLUSTER = "npc_cfg_cluster";
const string NPC_BHVR_CFG_AREA_PROFILE = "npc_cfg_area_profile";

const string NPC_BHVR_CFG_DERIVED_ROLE = "npc_cfg_derived_role";
const string NPC_BHVR_CFG_DERIVED_SCHEDULE = "npc_cfg_derived_schedule"; // legacy-derived marker
const string NPC_BHVR_CFG_DERIVED_AREA_PROFILE = "npc_cfg_derived_area_profile";
const string NPC_BHVR_CFG_DERIVED_CLUSTER_OWNER = "npc_cfg_derived_cluster_owner";

string NpcBhvrAuthoringNormalizeTokenOrDefault(string sValue, string sFallback)
{
    string sNormalized;

    sNormalized = GetStringLowerCase(sValue);
    if (GetStringLength(sNormalized) <= 0)
    {
        return sFallback;
    }

    return sNormalized;
}

int NpcBhvrAuthoringHasStringLocal(object oTarget, string sKey)
{
    return GetStringLength(GetLocalString(oTarget, sKey)) > 0;
}

void NpcBhvrAuthoringSetStringIfMissing(object oTarget, string sKey, string sValue)
{
    if (!GetIsObjectValid(oTarget) || GetStringLength(sValue) <= 0)
    {
        return;
    }

    if (NpcBhvrAuthoringHasStringLocal(oTarget, sKey))
    {
        return;
    }

    SetLocalString(oTarget, sKey, sValue);
}

void NpcBhvrAuthoringSetIntIfMissing(object oTarget, string sKey, int nValue)
{
    if (!GetIsObjectValid(oTarget))
    {
        return;
    }

    if (GetLocalInt(oTarget, sKey) != 0)
    {
        return;
    }

    SetLocalInt(oTarget, sKey, nValue);
}


void NpcBhvrAuthoringApplyNpcSlotRouteIfPresent(object oNpc, string sCfgKey, string sSlot)
{
    string sRoute;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    sRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(GetLocalString(oNpc, sCfgKey), oNpc);
    if (sRoute == "")
    {
        return;
    }

    NpcBhvrAuthoringSetStringIfMissing(oNpc, NpcBhvrActivitySlotRouteProfileKey(sSlot), sRoute);
}

void NpcBhvrAuthoringApplyNpcAlertRouteIfPresent(object oNpc)
{
    string sAlertRoute;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    sAlertRoute = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(GetLocalString(oNpc, NPC_BHVR_CFG_ALERT_ROUTE), oNpc);
    if (sAlertRoute == "")
    {
        return;
    }

    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_ALERT, sAlertRoute);
}

void NpcBhvrAuthoringApplyNpcSlotRoutes(object oNpc)
{
    NpcBhvrAuthoringApplyNpcSlotRouteIfPresent(oNpc, NPC_BHVR_CFG_SLOT_DAWN_ROUTE, NPC_BHVR_ACTIVITY_SLOT_DAWN);
    NpcBhvrAuthoringApplyNpcSlotRouteIfPresent(oNpc, NPC_BHVR_CFG_SLOT_MORNING_ROUTE, NPC_BHVR_ACTIVITY_SLOT_MORNING);
    NpcBhvrAuthoringApplyNpcSlotRouteIfPresent(oNpc, NPC_BHVR_CFG_SLOT_AFTERNOON_ROUTE, NPC_BHVR_ACTIVITY_SLOT_AFTERNOON);
    NpcBhvrAuthoringApplyNpcSlotRouteIfPresent(oNpc, NPC_BHVR_CFG_SLOT_EVENING_ROUTE, NPC_BHVR_ACTIVITY_SLOT_EVENING);
    NpcBhvrAuthoringApplyNpcSlotRouteIfPresent(oNpc, NPC_BHVR_CFG_SLOT_NIGHT_ROUTE, NPC_BHVR_ACTIVITY_SLOT_NIGHT);

    NpcBhvrAuthoringApplyNpcAlertRouteIfPresent(oNpc);
}

string NpcBhvrAuthoringResolveNpcRouteDefault(object oNpc)
{
    string sRoute;

    sRoute = GetLocalString(oNpc, NPC_BHVR_CFG_LEISURE_ROUTE);
    if (GetStringLength(sRoute) > 0)
    {
        return sRoute;
    }

    sRoute = GetLocalString(oNpc, NPC_BHVR_CFG_HOME_ROUTE);
    if (GetStringLength(sRoute) > 0)
    {
        return sRoute;
    }

    sRoute = GetLocalString(oNpc, NPC_BHVR_CFG_WORK_ROUTE);
    if (GetStringLength(sRoute) > 0)
    {
        return sRoute;
    }

    return "";
}

void NpcBhvrAuthoringApplyNpcSchedulePreset(object oNpc, string sSchedule, string sRouteWork, string sRouteHome, string sRouteLeisure)
{
    // Canonical route-by-time slot map.
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_DAWN, sRouteHome);
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_MORNING, sRouteWork);
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_AFTERNOON, sRouteWork);
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_EVENING, sRouteLeisure);
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_NIGHT, sRouteHome);

    if (sSchedule == "always_home")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, TRUE);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteHome);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, NPC_BHVR_ACTIVITY_SLOT_NIGHT);
        return;
    }

    if (sSchedule == "always_static")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, FALSE);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteHome);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, NPC_BHVR_ACTIVITY_SLOT_AFTERNOON);
        return;
    }

    if (sSchedule == "night_guard")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, TRUE);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_NIGHT, sRouteWork);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteLeisure);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, NPC_BHVR_ACTIVITY_SLOT_EVENING);
        return;
    }

    if (sSchedule == "tavern_late")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, TRUE);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_EVENING, sRouteWork);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteHome);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, NPC_BHVR_ACTIVITY_SLOT_AFTERNOON);
        return;
    }

    if (sSchedule == "day_shop")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, TRUE);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_MORNING, sRouteWork);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_SLOT_PREFIX + NPC_BHVR_ACTIVITY_SLOT_AFTERNOON, sRouteWork);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteHome);
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, NPC_BHVR_ACTIVITY_SLOT_MORNING);
        return;
    }

    if (sSchedule == "custom")
    {
        // Deprecated compatibility: custom no longer opens arbitrary runtime tuning.
        // We only allow default route fallback and keep slot/daypart flow canonical.
        NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteLeisure);
        return;
    }

    // day_worker default
    NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, TRUE);
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ROUTE_PROFILE_DEFAULT, sRouteHome);
    NpcBhvrAuthoringSetStringIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT, NPC_BHVR_ACTIVITY_SLOT_MORNING);
}

void NpcBhvrAuthoringApplyNpcRolePreset(object oNpc, string sRole)
{
    if (sRole == "guard")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_CFG_NPC_LAYER, NPC_BHVR_LAYER_REACTIVE);
        return;
    }

    if (sRole == "static")
    {
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_CFG_NPC_LAYER, NPC_BHVR_LAYER_AMBIENT);
        NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_VAR_ACTIVITY_SCHEDULE_ENABLED, FALSE);
        return;
    }

    // citizen/worker/merchant/innkeeper fall back to ambient defaults.
    NpcBhvrAuthoringSetIntIfMissing(oNpc, NPC_BHVR_CFG_NPC_LAYER, NPC_BHVR_LAYER_AMBIENT);
}

void NpcBhvrAuthoringApplyNpcFacade(object oNpc)
{
    string sRole;
    string sSchedule;
    string sRouteWork;
    string sRouteHome;
    string sRouteLeisure;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    sRole = NpcBhvrAuthoringNormalizeTokenOrDefault(GetLocalString(oNpc, NPC_BHVR_CFG_ROLE), "citizen");

    SetLocalString(oNpc, NPC_BHVR_CFG_DERIVED_ROLE, sRole);

    NpcBhvrAuthoringApplyNpcRolePreset(oNpc, sRole);

    // Canonical path: explicit slot routes from npc_cfg_slot_*_route.
    NpcBhvrAuthoringApplyNpcSlotRoutes(oNpc);

    // Compatibility path: schedule/work/home/leisure presets are migration-only fallback.
    sSchedule = NpcBhvrAuthoringNormalizeTokenOrDefault(GetLocalString(oNpc, NPC_BHVR_CFG_SCHEDULE), "day_worker");
    sRouteWork = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(GetLocalString(oNpc, NPC_BHVR_CFG_WORK_ROUTE), oNpc);
    sRouteHome = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(GetLocalString(oNpc, NPC_BHVR_CFG_HOME_ROUTE), oNpc);
    sRouteLeisure = NpcBhvrActivityNormalizeConfiguredRouteOrEmpty(GetLocalString(oNpc, NPC_BHVR_CFG_LEISURE_ROUTE), oNpc);

    if (GetStringLength(sRouteLeisure) <= 0)
    {
        sRouteLeisure = NpcBhvrAuthoringResolveNpcRouteDefault(oNpc);
    }

    SetLocalString(oNpc, NPC_BHVR_CFG_DERIVED_SCHEDULE, sSchedule);
    NpcBhvrAuthoringApplyNpcSchedulePreset(oNpc, sSchedule, sRouteWork, sRouteHome, sRouteLeisure);

    if (GetLocalInt(oNpc, NPC_BHVR_CFG_FORCE_REACTIVE) == TRUE)
    {
        // Canonical human-facing override for reactive behavior.
        SetLocalInt(oNpc, NPC_BHVR_CFG_NPC_LAYER, NPC_BHVR_LAYER_REACTIVE);
    }

    if (GetLocalInt(oNpc, NPC_BHVR_CFG_ALLOW_PHYSICAL_HIDE) == TRUE)
    {
        SetLocalInt(oNpc, NPC_BHVR_CFG_LOD_PHYSICAL_HIDE, TRUE);
    }
}

void NpcBhvrAuthoringApplyAreaProfilePreset(object oArea, string sProfile)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (sProfile == "shop_interior")
    {
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_IS_INTERIOR, TRUE);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_DISPATCH_MODE, NPC_BHVR_DISPATCH_MODE_HYBRID);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_GRACE_SEC, 45);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP, 4);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP, 8);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE, FALSE);
        return;
    }

    if (sProfile == "house_interior")
    {
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_IS_INTERIOR, TRUE);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_DISPATCH_MODE, NPC_BHVR_DISPATCH_MODE_AMBIENT_ONLY);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_GRACE_SEC, 60);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP, 6);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP, 10);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE, FALSE);
        return;
    }

    if (sProfile == "tavern")
    {
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_IS_INTERIOR, TRUE);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_DISPATCH_MODE, NPC_BHVR_DISPATCH_MODE_HYBRID);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_GRACE_SEC, 50);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP, 8);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP, 12);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE, FALSE);
        return;
    }

    if (sProfile == "guard_post")
    {
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_IS_INTERIOR, FALSE);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_DISPATCH_MODE, NPC_BHVR_DISPATCH_MODE_REACTIVE_ONLY);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_GRACE_SEC, 20);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP, 2);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP, 4);
        NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE, TRUE);
        return;
    }

    // city_exterior default
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_IS_INTERIOR, FALSE);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_DISPATCH_MODE, NPC_BHVR_DISPATCH_MODE_HYBRID);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_GRACE_SEC, 20);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP, 2);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP, 4);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_TRANSITION_RATE, 4);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_CLUSTER_TRANSITION_BURST, 8);
    NpcBhvrAuthoringSetIntIfMissing(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE, TRUE);
}

void NpcBhvrAuthoringApplyAreaFacade(object oArea)
{
    string sCity;
    string sCluster;
    string sProfile;
    string sClusterOwner;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    sCity = NpcBhvrAuthoringNormalizeTokenOrDefault(GetLocalString(oArea, NPC_BHVR_CFG_CITY), "default");
    sCluster = NpcBhvrAuthoringNormalizeTokenOrDefault(GetLocalString(oArea, NPC_BHVR_CFG_CLUSTER), GetTag(oArea));
    sProfile = NpcBhvrAuthoringNormalizeTokenOrDefault(GetLocalString(oArea, NPC_BHVR_CFG_AREA_PROFILE), "city_exterior");

    if (GetStringLength(sCluster) <= 0)
    {
        sCluster = "default";
    }

    sClusterOwner = sCity + "_" + sCluster;
    SetLocalString(oArea, NPC_BHVR_CFG_DERIVED_AREA_PROFILE, sProfile);
    SetLocalString(oArea, NPC_BHVR_CFG_DERIVED_CLUSTER_OWNER, sClusterOwner);

    if (!NpcBhvrAuthoringHasStringLocal(oArea, NPC_BHVR_VAR_AREA_CLUSTER_OWNER))
    {
        SetLocalString(oArea, NPC_BHVR_VAR_AREA_CLUSTER_OWNER, sClusterOwner);
    }

    NpcBhvrAuthoringApplyAreaProfilePreset(oArea, sProfile);
}
