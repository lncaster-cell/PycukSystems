// NPC hidden/projection + simulation LOD baseline.
// Goal: near-zero cost for ambient NPC outside player interest, with deterministic reveal/resync.

const string NPC_BHVR_CFG_LOD_EXEMPT = "npc_cfg_lod_exempt";
const string NPC_BHVR_CFG_LOD_RUNNING_HIDE = "npc_cfg_lod_running_hide";
const string NPC_BHVR_CFG_LOD_RUNNING_HIDE_DISTANCE = "npc_cfg_lod_running_hide_distance";
const string NPC_BHVR_CFG_LOD_RUNNING_REVEAL_DISTANCE = "npc_cfg_lod_running_reveal_distance";
const string NPC_BHVR_CFG_LOD_RUNNING_DEBOUNCE_SEC = "npc_cfg_lod_running_debounce_sec";
const string NPC_BHVR_CFG_LOD_RUNNING_SCAN_INTERVAL_SEC = "npc_cfg_lod_running_scan_interval_sec";
const string NPC_BHVR_CFG_LOD_PHASE_STEP_SEC = "npc_cfg_lod_phase_step_sec";
const string NPC_BHVR_CFG_LOD_MIN_HIDDEN_SEC = "npc_cfg_lod_min_hidden_sec";
const string NPC_BHVR_CFG_LOD_MIN_VISIBLE_SEC = "npc_cfg_lod_min_visible_sec";
const string NPC_BHVR_CFG_LOD_REVEAL_COOLDOWN_SEC = "npc_cfg_lod_reveal_cooldown_sec";
const string NPC_BHVR_CFG_LOD_PHYSICAL_HIDE_ENABLED = "npc_cfg_lod_physical_hide_enabled";
const string NPC_BHVR_CFG_LOD_PHYSICAL_HIDE = "npc_cfg_lod_physical_hide";
const string NPC_BHVR_CFG_LOD_PHYSICAL_MIN_HIDDEN_SEC = "npc_cfg_lod_physical_min_hidden_sec";
const string NPC_BHVR_CFG_LOD_PHYSICAL_MIN_VISIBLE_SEC = "npc_cfg_lod_physical_min_visible_sec";
const string NPC_BHVR_CFG_LOD_PHYSICAL_COOLDOWN_SEC = "npc_cfg_lod_physical_cooldown_sec";

const string NPC_BHVR_VAR_LOD_HIDDEN_AT = "npc_lod_hidden_at";
const string NPC_BHVR_VAR_LOD_LAST_TOGGLE_AT = "npc_lod_last_toggle_at";
const string NPC_BHVR_VAR_LOD_PROJECTED_SLOT = "npc_lod_projected_slot";
const string NPC_BHVR_VAR_LOD_PROJECTED_ROUTE = "npc_lod_projected_route";
const string NPC_BHVR_VAR_LOD_PROJECTED_ROUTE_TAG = "npc_lod_projected_route_tag";
const string NPC_BHVR_VAR_LOD_PROJECTED_STATE = "npc_lod_projected_state";
const string NPC_BHVR_VAR_LOD_PROJECTED_WP_INDEX = "npc_lod_projected_wp_index";
const string NPC_BHVR_VAR_LOD_PROJECTED_WP_COUNT = "npc_lod_projected_wp_count";
const string NPC_BHVR_VAR_LOD_PROJECTED_WP_LOOP = "npc_lod_projected_wp_loop";
const string NPC_BHVR_VAR_LOD_LAST_REVEAL_AT = "npc_lod_last_reveal_at";
const string NPC_BHVR_VAR_LOD_PHYSICAL_HIDDEN = "npc_lod_physical_hidden";
const string NPC_BHVR_VAR_LOD_LAST_PHYSICAL_TOGGLE_AT = "npc_lod_last_physical_toggle_at";
const string NPC_BHVR_VAR_LOD_LAST_DISTANCE_CHECK_AT = "npc_lod_last_distance_check_at";

const int NPC_BHVR_LOD_RUNNING_HIDE_DISTANCE_DEFAULT = 35;
const int NPC_BHVR_LOD_RUNNING_REVEAL_DISTANCE_DEFAULT = 25;
const int NPC_BHVR_LOD_RUNNING_DEBOUNCE_SEC_DEFAULT = 6;
const int NPC_BHVR_LOD_RUNNING_SCAN_INTERVAL_SEC_DEFAULT = 3;
const int NPC_BHVR_LOD_PHASE_STEP_SEC_DEFAULT = 12;
const int NPC_BHVR_LOD_MIN_HIDDEN_SEC_DEFAULT = 5;
const int NPC_BHVR_LOD_MIN_VISIBLE_SEC_DEFAULT = 4;
const int NPC_BHVR_LOD_REVEAL_COOLDOWN_SEC_DEFAULT = 2;
const int NPC_BHVR_LOD_PHYSICAL_HIDE_ENABLED_DEFAULT = FALSE;
const int NPC_BHVR_LOD_PHYSICAL_MIN_HIDDEN_SEC_DEFAULT = 8;
const int NPC_BHVR_LOD_PHYSICAL_MIN_VISIBLE_SEC_DEFAULT = 8;
const int NPC_BHVR_LOD_PHYSICAL_COOLDOWN_SEC_DEFAULT = 6;

int NpcBhvrPendingNow();
int NpcBhvrAreaGetState(object oArea);
int NpcBhvrAreaGetInterestState(object oArea);
int NpcBhvrResolveNpcLayer(object oNpc);
int NpcBhvrGetNpcSimulationLod(object oNpc);
void NpcBhvrSetNpcSimulationLod(object oNpc, int nLod);
int NpcBhvrGetNpcProjectedState(object oNpc);
void NpcBhvrSetNpcProjectedState(object oNpc, int nState);
int NpcBhvrActivityNormalizeWaypointIndex(int nIndex, int nCount, int bLoop);
int NpcBhvrActivityResolveRouteCount(object oNpc, string sRouteId);
int NpcBhvrActivityResolveRouteLoop(object oNpc, string sRouteId);
string NpcBhvrActivityResolveRouteTag(object oNpc, string sRouteId);
void NpcBhvrActivityRefreshProfileState(object oNpc);
string NpcBhvrRegistrySlotKey(int nIndex);

int NpcBhvrLodResolveConfig(object oArea, string sKey, int nDefault)
{
    object oModule;
    int nValue;

    if (GetIsObjectValid(oArea))
    {
        nValue = GetLocalInt(oArea, sKey);
        if (nValue > 0)
        {
            return nValue;
        }
    }

    oModule = GetModule();
    nValue = GetLocalInt(oModule, sKey);
    if (nValue > 0)
    {
        return nValue;
    }

    return nDefault;
}

int NpcBhvrLodIsAmbientCandidate(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return FALSE;
    }

    if (GetLocalInt(oNpc, NPC_BHVR_CFG_LOD_EXEMPT) == TRUE)
    {
        return FALSE;
    }

    return NpcBhvrResolveNpcLayer(oNpc) == NPC_BHVR_LAYER_AMBIENT;
}

int NpcBhvrLodPhysicalHidePolicyAllowed(object oNpc, object oArea)
{
    int nEnabled;

    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    nEnabled = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_PHYSICAL_HIDE_ENABLED, NPC_BHVR_LOD_PHYSICAL_HIDE_ENABLED_DEFAULT);
    if (nEnabled != TRUE)
    {
        return FALSE;
    }

    if (GetLocalInt(oNpc, NPC_BHVR_CFG_LOD_PHYSICAL_HIDE) != TRUE)
    {
        return FALSE;
    }

    return TRUE;
}

void NpcBhvrLodTryApplyPhysicalHide(object oNpc, int nNow)
{
    object oArea;
    int bHidden;
    int nLastToggle;
    int nMinVisible;
    int nCooldown;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    oArea = GetArea(oNpc);
    if (!NpcBhvrLodPhysicalHidePolicyAllowed(oNpc, oArea))
    {
        return;
    }

    bHidden = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PHYSICAL_HIDDEN) == TRUE;
    if (bHidden)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_HIDE_SUPPRESSED_TOTAL);
        return;
    }

    nLastToggle = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_PHYSICAL_TOGGLE_AT);
    nMinVisible = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_PHYSICAL_MIN_VISIBLE_SEC, NPC_BHVR_LOD_PHYSICAL_MIN_VISIBLE_SEC_DEFAULT);
    nCooldown = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_PHYSICAL_COOLDOWN_SEC, NPC_BHVR_LOD_PHYSICAL_COOLDOWN_SEC_DEFAULT);
    if (nLastToggle > 0 && ((nNow - nLastToggle) < nMinVisible || (nNow - nLastToggle) < nCooldown))
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_COOLDOWN_HIT_TOTAL);
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_FALLBACK_LOGICAL_ONLY_TOTAL);
        return;
    }

    SetScriptHidden(oNpc, TRUE);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PHYSICAL_HIDDEN, TRUE);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_PHYSICAL_TOGGLE_AT, nNow);
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_HIDE_APPLIED_TOTAL);
}

void NpcBhvrLodTryApplyPhysicalReveal(object oNpc, int nNow)
{
    object oArea;
    int bHidden;
    int nLastToggle;
    int nMinHidden;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    oArea = GetArea(oNpc);
    if (!NpcBhvrLodPhysicalHidePolicyAllowed(oNpc, oArea))
    {
        return;
    }

    bHidden = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PHYSICAL_HIDDEN) == TRUE;
    if (!bHidden)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_REVEAL_SUPPRESSED_TOTAL);
        return;
    }

    nLastToggle = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_PHYSICAL_TOGGLE_AT);
    nMinHidden = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_PHYSICAL_MIN_HIDDEN_SEC, NPC_BHVR_LOD_PHYSICAL_MIN_HIDDEN_SEC_DEFAULT);
    if (nLastToggle > 0 && (nNow - nLastToggle) < nMinHidden)
    {
        // Consistency override: reveal is required to match projected truth when NPC becomes visible.
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_COOLDOWN_HIT_TOTAL);
    }

    SetScriptHidden(oNpc, FALSE);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PHYSICAL_HIDDEN, FALSE);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_PHYSICAL_TOGGLE_AT, nNow);
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_PHYSICAL_REVEAL_APPLIED_TOTAL);
}

void NpcBhvrLodCaptureProjectionState(object oNpc, int nNow)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_HIDDEN_AT, nNow);
    SetLocalString(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_SLOT, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE));
    SetLocalString(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_ROUTE, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE));
    SetLocalString(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_ROUTE_TAG, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG));
    SetLocalString(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_STATE, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_STATE));
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_WP_INDEX, GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX));
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_WP_COUNT, GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT));
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_WP_LOOP, GetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP));
}

void NpcBhvrLodHideNpc(object oNpc, int nLod, int nNow)
{
    int nCurrent;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    nCurrent = NpcBhvrGetNpcSimulationLod(oNpc);
    if (NpcBhvrGetNpcProjectedState(oNpc) == NPC_BHVR_PROJECTED_HIDDEN)
    {
        if (nCurrent == nLod)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_HIDE_SUPPRESSED_TOTAL);
            NpcBhvrLodTryApplyPhysicalHide(oNpc, nNow);
            return;
        }

        // Already hidden: avoid repeated snapshot/clear-actions churn.
        NpcBhvrSetNpcSimulationLod(oNpc, nLod);
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_HIDE_SUPPRESSED_TOTAL);
        NpcBhvrLodTryApplyPhysicalHide(oNpc, nNow);
        return;
    }

    NpcBhvrLodCaptureProjectionState(oNpc, nNow);
    NpcBhvrSetNpcProjectedState(oNpc, NPC_BHVR_PROJECTED_HIDDEN);
    NpcBhvrSetNpcSimulationLod(oNpc, nLod);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_TOGGLE_AT, nNow);

    ClearAllActions(TRUE);
    NpcBhvrLodTryApplyPhysicalHide(oNpc, nNow);

    if (nLod == NPC_BHVR_SIM_LOD_PROJECTED)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_FROZEN_TOTAL);
    }
    else
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_HIDDEN_TOTAL);
    }
}

int NpcBhvrLodFastForwardSameSlot(object oNpc, int nNow)
{
    int nHiddenAt;
    int nElapsed;
    int nStepSec;
    int nSteps;
    int nWpCount;
    int bWpLoop;
    int nWpIndex;
    string sRoute;

    nHiddenAt = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_HIDDEN_AT);
    if (nHiddenAt <= 0 || nNow <= nHiddenAt)
    {
        return FALSE;
    }

    sRoute = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE);
    nWpCount = NpcBhvrActivityResolveRouteCount(oNpc, sRoute);
    bWpLoop = NpcBhvrActivityResolveRouteLoop(oNpc, sRoute);
    if (nWpCount <= 0)
    {
        return FALSE;
    }

    nStepSec = NpcBhvrLodResolveConfig(GetArea(oNpc), NPC_BHVR_CFG_LOD_PHASE_STEP_SEC, NPC_BHVR_LOD_PHASE_STEP_SEC_DEFAULT);
    if (nStepSec <= 0)
    {
        nStepSec = NPC_BHVR_LOD_PHASE_STEP_SEC_DEFAULT;
    }

    nElapsed = nNow - nHiddenAt;
    nSteps = nElapsed / nStepSec;
    if (nSteps <= 0)
    {
        return FALSE;
    }

    nWpIndex = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_WP_INDEX);
    nWpIndex = NpcBhvrActivityNormalizeWaypointIndex(nWpIndex + nSteps, nWpCount, bWpLoop);

    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, nWpCount);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, bWpLoop);
    SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, nWpIndex);
    SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, NpcBhvrActivityResolveRouteTag(oNpc, sRoute));
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_FAST_FORWARD_TOTAL);
    return TRUE;
}

void NpcBhvrLodRevealResync(object oNpc, int nNow)
{
    string sProjectedSlot;
    string sCurrentSlot;
    int nRevealCooldown;
    int nLastToggle;
    int bFastForwarded;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (NpcBhvrGetNpcProjectedState(oNpc) != NPC_BHVR_PROJECTED_HIDDEN)
    {
        if (NpcBhvrGetNpcSimulationLod(oNpc) != NPC_BHVR_SIM_LOD_FULL)
        {
            NpcBhvrSetNpcSimulationLod(oNpc, NPC_BHVR_SIM_LOD_FULL);
        }
        else
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_REVEAL_SUPPRESSED_TOTAL);
        }
        return;
    }

    nRevealCooldown = NpcBhvrLodResolveConfig(GetArea(oNpc), NPC_BHVR_CFG_LOD_REVEAL_COOLDOWN_SEC, NPC_BHVR_LOD_REVEAL_COOLDOWN_SEC_DEFAULT);
    nLastToggle = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_TOGGLE_AT);
    if (nLastToggle > 0 && (nNow - nLastToggle) < nRevealCooldown)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_REVEAL_COOLDOWN_HIT_TOTAL);
        return;
    }

    NpcBhvrActivityRefreshProfileState(oNpc);

    sProjectedSlot = GetLocalString(oNpc, NPC_BHVR_VAR_LOD_PROJECTED_SLOT);
    sCurrentSlot = GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_SLOT_EFFECTIVE);

    if (sProjectedSlot != "" && sProjectedSlot != sCurrentSlot)
    {
        // Slot changed while hidden: re-anchor to canonical schedule result.
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, 1);
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, NpcBhvrActivityResolveRouteCount(oNpc, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE)));
        SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, NpcBhvrActivityResolveRouteLoop(oNpc, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE)));
        SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, NpcBhvrActivityResolveRouteTag(oNpc, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE)));
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_REVEAL_SLOT_CHANGE_TOTAL);
    }
    else
    {
        bFastForwarded = NpcBhvrLodFastForwardSameSlot(oNpc, nNow);
        if (!bFastForwarded)
        {
            // Safe fallback: canonical re-anchor when phase restore is not reliable.
            SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_INDEX, 1);
            SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_COUNT, NpcBhvrActivityResolveRouteCount(oNpc, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE)));
            SetLocalInt(oNpc, NPC_BHVR_VAR_ACTIVITY_WP_LOOP, NpcBhvrActivityResolveRouteLoop(oNpc, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE)));
            SetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_TAG, NpcBhvrActivityResolveRouteTag(oNpc, GetLocalString(oNpc, NPC_BHVR_VAR_ACTIVITY_ROUTE_EFFECTIVE)));
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_REANCHOR_FALLBACK_TOTAL);
        }
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_REVEAL_SAME_SLOT_TOTAL);
    }

    NpcBhvrSetNpcProjectedState(oNpc, NPC_BHVR_PROJECTED_VISIBLE);
    NpcBhvrSetNpcSimulationLod(oNpc, NPC_BHVR_SIM_LOD_FULL);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_TOGGLE_AT, nNow);
    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_REVEAL_AT, nNow);
    NpcBhvrLodTryApplyPhysicalReveal(oNpc, nNow);
    NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_REVEAL_RESYNC_TOTAL);
}

int NpcBhvrLodNearestPlayerDistance(object oArea, object oNpc)
{
    object oIter;
    int nBest;
    int nDist;

    if (!GetIsObjectValid(oArea) || !GetIsObjectValid(oNpc))
    {
        return 999999;
    }

    nBest = 999999;
    oIter = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oIter))
    {
        if (GetIsPC(oIter) && !GetIsDM(oIter))
        {
            nDist = FloatToInt(GetDistanceBetween(oNpc, oIter));
            if (nDist < nBest)
            {
                nBest = nDist;
                if (nBest <= 5)
                {
                    return nBest;
                }
            }
        }

        oIter = GetNextObjectInArea(oArea);
    }

    return nBest;
}

int NpcBhvrLodShouldHideInRunningArea(object oNpc, object oArea, int nNow)
{
    int nHideEnabled;
    int nHideDistance;
    int nRevealDistance;
    int nDebounce;
    int nMinHiddenSec;
    int nMinVisibleSec;
    int nLastToggle;
    int nProjected;
    int nNearest;
    int nScanInterval;
    int nLastScan;

    if (!GetIsObjectValid(oNpc) || !GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    if (!NpcBhvrLodIsAmbientCandidate(oNpc))
    {
        return FALSE;
    }

    nHideEnabled = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE, TRUE);
    if (nHideEnabled != TRUE)
    {
        return FALSE;
    }

    nDebounce = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_RUNNING_DEBOUNCE_SEC, NPC_BHVR_LOD_RUNNING_DEBOUNCE_SEC_DEFAULT);
    nScanInterval = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_RUNNING_SCAN_INTERVAL_SEC, NPC_BHVR_LOD_RUNNING_SCAN_INTERVAL_SEC_DEFAULT);
    if (nScanInterval <= 0)
    {
        nScanInterval = NPC_BHVR_LOD_RUNNING_SCAN_INTERVAL_SEC_DEFAULT;
    }
    nMinHiddenSec = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_MIN_HIDDEN_SEC, NPC_BHVR_LOD_MIN_HIDDEN_SEC_DEFAULT);
    nMinVisibleSec = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_MIN_VISIBLE_SEC, NPC_BHVR_LOD_MIN_VISIBLE_SEC_DEFAULT);
    nLastToggle = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_TOGGLE_AT);

    nHideDistance = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_RUNNING_HIDE_DISTANCE, NPC_BHVR_LOD_RUNNING_HIDE_DISTANCE_DEFAULT);
    nRevealDistance = NpcBhvrLodResolveConfig(oArea, NPC_BHVR_CFG_LOD_RUNNING_REVEAL_DISTANCE, NPC_BHVR_LOD_RUNNING_REVEAL_DISTANCE_DEFAULT);
    if (nRevealDistance > nHideDistance)
    {
        nRevealDistance = nHideDistance;
    }

    nNearest = NpcBhvrLodNearestPlayerDistance(oArea, oNpc);
    nProjected = NpcBhvrGetNpcProjectedState(oNpc);

    if (nProjected == NPC_BHVR_PROJECTED_HIDDEN)
    {
        if (nLastToggle > 0 && (nNow - nLastToggle) < nMinHiddenSec)
        {
            NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_HIDE_DEBOUNCE_HIT_TOTAL);
            return TRUE;
        }

        return nNearest > nRevealDistance;
    }

    nLastScan = GetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_DISTANCE_CHECK_AT);
    if (nLastScan > 0 && (nNow - nLastScan) < nScanInterval)
    {
        return FALSE;
    }

    if (nLastToggle > 0 && (nNow - nLastToggle) < nDebounce)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_HIDE_DEBOUNCE_HIT_TOTAL);
        return FALSE;
    }

    if (nLastToggle > 0 && (nNow - nLastToggle) < nMinVisibleSec)
    {
        NpcBhvrMetricInc(oNpc, NPC_BHVR_METRIC_LOD_HIDE_DEBOUNCE_HIT_TOTAL);
        return FALSE;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_LOD_LAST_DISTANCE_CHECK_AT, nNow);
    return nNearest > nHideDistance;
}

void NpcBhvrLodApplyForAreaStateToNpc(object oNpc, int nAreaState, int nNow)
{
    object oArea;

    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (!NpcBhvrLodIsAmbientCandidate(oNpc))
    {
        NpcBhvrSetNpcSimulationLod(oNpc, NPC_BHVR_SIM_LOD_FULL);
        NpcBhvrSetNpcProjectedState(oNpc, NPC_BHVR_PROJECTED_VISIBLE);
        NpcBhvrLodTryApplyPhysicalReveal(oNpc, nNow);
        return;
    }

    oArea = GetArea(oNpc);

    if (nAreaState == NPC_BHVR_AREA_STATE_STOPPED)
    {
        NpcBhvrLodHideNpc(oNpc, NPC_BHVR_SIM_LOD_PROJECTED, nNow);
        return;
    }

    if (nAreaState == NPC_BHVR_AREA_STATE_PAUSED)
    {
        NpcBhvrLodHideNpc(oNpc, NPC_BHVR_SIM_LOD_REDUCED, nNow);
        return;
    }

    if (NpcBhvrLodShouldHideInRunningArea(oNpc, oArea, nNow))
    {
        NpcBhvrLodHideNpc(oNpc, NPC_BHVR_SIM_LOD_REDUCED, nNow);
        return;
    }

    NpcBhvrLodRevealResync(oNpc, nNow);
}

void NpcBhvrLodApplyAreaState(object oArea, int nAreaState)
{
    int nCount;
    int nIndex;
    int nNow;
    object oNpc;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nNow = NpcBhvrPendingNow();
    nCount = GetLocalInt(oArea, NPC_BHVR_VAR_REGISTRY_COUNT);
    nIndex = 1;

    while (nIndex <= nCount)
    {
        oNpc = GetLocalObject(oArea, NpcBhvrRegistrySlotKey(nIndex));
        if (GetIsObjectValid(oNpc) && GetArea(oNpc) == oArea)
        {
            NpcBhvrLodApplyForAreaStateToNpc(oNpc, nAreaState, nNow);
        }

        nIndex = nIndex + 1;
    }
}

// Called from idle fan-out before expensive activity refresh.
// TRUE means caller should skip idle processing for this NPC.
int NpcBhvrLodShouldSkipIdleTick(object oNpc)
{
    object oArea;
    int nAreaState;
    int nNow;

    if (!GetIsObjectValid(oNpc))
    {
        return TRUE;
    }

    oArea = GetArea(oNpc);
    nAreaState = NpcBhvrAreaGetState(oArea);
    nNow = NpcBhvrPendingNow();

    NpcBhvrLodApplyForAreaStateToNpc(oNpc, nAreaState, nNow);
    if (NpcBhvrGetNpcProjectedState(oNpc) == NPC_BHVR_PROJECTED_HIDDEN)
    {
        return TRUE;
    }

    return NpcBhvrGetNpcSimulationLod(oNpc) != NPC_BHVR_SIM_LOD_FULL;
}
