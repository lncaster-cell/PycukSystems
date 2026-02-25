// NPC cluster lifecycle supervisor.
// Lightweight orchestration layer: manages area lifecycle state by cluster ownership
// and interest/grace policy, without running NPC simulation itself.

const string NPC_BHVR_VAR_CLUSTER_LAST_HOT_AT = "npc_cluster_last_hot_at";
const string NPC_BHVR_VAR_CLUSTER_GRACE_UNTIL_AT = "npc_cluster_grace_until_at";
const string NPC_BHVR_VAR_CLUSTER_LAST_TRANSITION_AT = "npc_cluster_last_transition_at";
const string NPC_BHVR_VAR_CLUSTER_IS_INTERIOR = "npc_area_is_interior";
const string NPC_BHVR_CFG_CLUSTER_IS_INTERIOR = "npc_cfg_area_is_interior";
const string NPC_BHVR_CFG_CLUSTER_GRACE_SEC = "npc_cfg_cluster_grace_sec";
const string NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP = "npc_cfg_cluster_interior_soft_cap";
const string NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP = "npc_cfg_cluster_interior_hard_cap";
const string NPC_BHVR_CFG_CLUSTER_TRANSITION_RATE = "npc_cfg_cluster_transition_rate";
const string NPC_BHVR_CFG_CLUSTER_TRANSITION_BURST = "npc_cfg_cluster_transition_burst";

const int NPC_BHVR_CLUSTER_DEFAULT_GRACE_SEC = 20;
const int NPC_BHVR_CLUSTER_DEFAULT_INTERIOR_SOFT_CAP = 2;
const int NPC_BHVR_CLUSTER_DEFAULT_INTERIOR_HARD_CAP = 4;
const int NPC_BHVR_CLUSTER_DEFAULT_TRANSITION_RATE = 4;
const int NPC_BHVR_CLUSTER_DEFAULT_TRANSITION_BURST = 8;

string NpcBhvrClusterKey(string sPrefix, string sCluster)
{
    return sPrefix + sCluster;
}

string NpcBhvrClusterTokensKey(string sCluster)
{
    return NpcBhvrClusterKey("npc_cluster_tokens_", sCluster);
}

string NpcBhvrClusterUpdatedAtKey(string sCluster)
{
    return NpcBhvrClusterKey("npc_cluster_tokens_updated_", sCluster);
}

string NpcBhvrClusterMetricKey(string sMetricPrefix, string sCluster)
{
    return NpcBhvrClusterKey(sMetricPrefix, sCluster);
}

int NpcBhvrClampAtLeast(int nValue, int nMin)
{
    if (nValue < nMin)
    {
        return nMin;
    }

    return nValue;
}

string NpcBhvrClusterResolveOwner(object oArea)
{
    string sOwner;

    if (!GetIsObjectValid(oArea))
    {
        return "";
    }

    sOwner = NpcBhvrAreaGetClusterOwner(oArea);
    if (GetStringLength(sOwner) > 0)
    {
        return sOwner;
    }

    sOwner = GetTag(oArea);
    if (GetStringLength(sOwner) <= 0)
    {
        sOwner = "default";
    }

    NpcBhvrAreaSetClusterOwner(oArea, sOwner);
    return sOwner;
}

int NpcBhvrClusterAreaIsInterior(object oArea)
{
    int nFlag;

    if (!GetIsObjectValid(oArea))
    {
        return FALSE;
    }

    nFlag = GetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_IS_INTERIOR);
    if (nFlag == 0)
    {
        nFlag = GetLocalInt(oArea, NPC_BHVR_CFG_CLUSTER_IS_INTERIOR);
    }

    return nFlag == TRUE;
}

int NpcBhvrClusterResolveGraceSec(object oArea)
{
    object oModule;
    int nGrace;

    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_CLUSTER_DEFAULT_GRACE_SEC;
    }

    nGrace = GetLocalInt(oArea, NPC_BHVR_CFG_CLUSTER_GRACE_SEC);
    if (nGrace > 0)
    {
        return nGrace;
    }

    oModule = GetModule();
    nGrace = GetLocalInt(oModule, NPC_BHVR_CFG_CLUSTER_GRACE_SEC);
    if (nGrace > 0)
    {
        return nGrace;
    }

    return NPC_BHVR_CLUSTER_DEFAULT_GRACE_SEC;
}

int NpcBhvrClusterResolveInteriorSoftCap(object oArea)
{
    object oModule;
    int nCap;

    nCap = GetLocalInt(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP);
    if (nCap <= 0)
    {
        oModule = GetModule();
        nCap = GetLocalInt(oModule, NPC_BHVR_CFG_CLUSTER_INTERIOR_SOFT_CAP);
    }

    if (nCap <= 0)
    {
        nCap = NPC_BHVR_CLUSTER_DEFAULT_INTERIOR_SOFT_CAP;
    }

    return NpcBhvrClampAtLeast(nCap, 1);
}

int NpcBhvrClusterResolveInteriorHardCap(object oArea)
{
    object oModule;
    int nCap;

    nCap = GetLocalInt(oArea, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP);
    if (nCap <= 0)
    {
        oModule = GetModule();
        nCap = GetLocalInt(oModule, NPC_BHVR_CFG_CLUSTER_INTERIOR_HARD_CAP);
    }

    if (nCap <= 0)
    {
        nCap = NPC_BHVR_CLUSTER_DEFAULT_INTERIOR_HARD_CAP;
    }

    return NpcBhvrClampAtLeast(nCap, 1);
}

int NpcBhvrClusterResolveTransitionRate(object oArea)
{
    object oModule;
    int nRate;

    nRate = GetLocalInt(oArea, NPC_BHVR_CFG_CLUSTER_TRANSITION_RATE);
    if (nRate <= 0)
    {
        oModule = GetModule();
        nRate = GetLocalInt(oModule, NPC_BHVR_CFG_CLUSTER_TRANSITION_RATE);
    }

    if (nRate <= 0)
    {
        nRate = NPC_BHVR_CLUSTER_DEFAULT_TRANSITION_RATE;
    }

    return NpcBhvrClampAtLeast(nRate, 1);
}

int NpcBhvrClusterResolveTransitionBurst(object oArea)
{
    object oModule;
    int nBurst;

    nBurst = GetLocalInt(oArea, NPC_BHVR_CFG_CLUSTER_TRANSITION_BURST);
    if (nBurst <= 0)
    {
        oModule = GetModule();
        nBurst = GetLocalInt(oModule, NPC_BHVR_CFG_CLUSTER_TRANSITION_BURST);
    }

    if (nBurst <= 0)
    {
        nBurst = NPC_BHVR_CLUSTER_DEFAULT_TRANSITION_BURST;
    }

    return NpcBhvrClampAtLeast(nBurst, 1);
}

int NpcBhvrClusterTryConsumeTransitionToken(object oArea, string sCluster, int nNow)
{
    object oModule;
    string sTokensKey;
    string sUpdatedKey;
    int nTokens;
    int nUpdatedAt;
    int nRate;
    int nBurst;
    int nRefill;

    oModule = GetModule();
    sTokensKey = NpcBhvrClusterTokensKey(sCluster);
    sUpdatedKey = NpcBhvrClusterUpdatedAtKey(sCluster);

    nRate = NpcBhvrClusterResolveTransitionRate(oArea);
    nBurst = NpcBhvrClusterResolveTransitionBurst(oArea);

    nTokens = GetLocalInt(oModule, sTokensKey);
    nUpdatedAt = GetLocalInt(oModule, sUpdatedKey);

    if (nUpdatedAt <= 0)
    {
        nTokens = nBurst;
        nUpdatedAt = nNow;
    }

    if (nNow > nUpdatedAt)
    {
        nRefill = (nNow - nUpdatedAt) * nRate;
        nTokens = nTokens + nRefill;
        if (nTokens > nBurst)
        {
            nTokens = nBurst;
        }
        nUpdatedAt = nNow;
    }

    if (nTokens <= 0)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_CLUSTER_RATE_LIMIT_HIT_TOTAL);
        NpcBhvrMetricInc(oModule, NpcBhvrClusterMetricKey("npc_metric_cluster_rate_limit_hit_total_", sCluster));
        SetLocalInt(oModule, sTokensKey, 0);
        SetLocalInt(oModule, sUpdatedKey, nUpdatedAt);
        return FALSE;
    }

    nTokens = nTokens - 1;
    SetLocalInt(oModule, sTokensKey, nTokens);
    SetLocalInt(oModule, sUpdatedKey, nUpdatedAt);
    return TRUE;
}

void NpcBhvrClusterMetricTransition(object oArea, string sCluster, int nFromState, int nToState)
{
    object oModule;

    oModule = GetModule();
    NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_CLUSTER_TRANSITIONS_TOTAL);
    NpcBhvrMetricInc(oModule, NpcBhvrClusterMetricKey("npc_metric_cluster_transitions_total_", sCluster));

    if (nFromState == NPC_BHVR_AREA_STATE_PAUSED && nToState == NPC_BHVR_AREA_STATE_RUNNING)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_CLUSTER_PAUSE_RESUME_TOTAL);
        NpcBhvrMetricInc(oModule, NpcBhvrClusterMetricKey("npc_metric_cluster_pause_resume_total_", sCluster));
    }
    else if (nFromState == NPC_BHVR_AREA_STATE_PAUSED && nToState == NPC_BHVR_AREA_STATE_STOPPED)
    {
        NpcBhvrMetricInc(oArea, NPC_BHVR_METRIC_CLUSTER_PAUSE_STOP_TOTAL);
        NpcBhvrMetricInc(oModule, NpcBhvrClusterMetricKey("npc_metric_cluster_pause_stop_total_", sCluster));
    }
}

void NpcBhvrClusterApplyTargetState(object oArea, int nTargetState, int nNow)
{
    int nState;
    string sCluster;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nState = NpcBhvrAreaGetState(oArea);
    if (nState == nTargetState)
    {
        return;
    }

    sCluster = NpcBhvrClusterResolveOwner(oArea);
    if (!NpcBhvrClusterTryConsumeTransitionToken(oArea, sCluster, nNow))
    {
        return;
    }

    if (nTargetState == NPC_BHVR_AREA_STATE_RUNNING)
    {
        NpcBhvrAreaActivate(oArea);
    }
    else if (nTargetState == NPC_BHVR_AREA_STATE_PAUSED)
    {
        NpcBhvrAreaPause(oArea);
    }
    else
    {
        NpcBhvrAreaStop(oArea);
    }

    NpcBhvrClusterMetricTransition(oArea, sCluster, nState, nTargetState);
    SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_LAST_TRANSITION_AT, nNow);
}

int NpcBhvrClusterDesiredStateForArea(object oArea, int nNow)
{
    int nPlayers;
    int nGraceUntil;
    int nGraceSec;

    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_AREA_STATE_STOPPED;
    }

    nPlayers = NpcBhvrGetCachedPlayerCountInternal(oArea);
    if (nPlayers > 0)
    {
        NpcBhvrAreaSetInterestState(oArea, NPC_BHVR_AREA_INTEREST_ACTIVE);
        SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_LAST_HOT_AT, nNow);
        nGraceSec = NpcBhvrClusterResolveGraceSec(oArea);
        SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_GRACE_UNTIL_AT, nNow + nGraceSec);
        return NPC_BHVR_AREA_STATE_RUNNING;
    }

    nGraceUntil = GetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_GRACE_UNTIL_AT);
    if (nGraceUntil <= 0)
    {
        nGraceSec = NpcBhvrClusterResolveGraceSec(oArea);
        nGraceUntil = GetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_LAST_HOT_AT) + nGraceSec;
    }

    if (nGraceUntil > nNow)
    {
        NpcBhvrAreaSetInterestState(oArea, NPC_BHVR_AREA_INTEREST_BACKGROUND);
        return NPC_BHVR_AREA_STATE_PAUSED;
    }

    NpcBhvrAreaSetInterestState(oArea, NPC_BHVR_AREA_INTEREST_UNKNOWN);
    return NPC_BHVR_AREA_STATE_STOPPED;
}

int NpcBhvrClusterCountRunningInteriorByOwner(string sCluster)
{
    object oArea;
    int nCount;

    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        if (NpcBhvrAreaGetClusterOwner(oArea) == sCluster &&
            NpcBhvrClusterAreaIsInterior(oArea) &&
            NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_RUNNING)
        {
            nCount = nCount + 1;
        }

        oArea = GetNextArea();
    }

    return nCount;
}

object NpcBhvrClusterPickOldestIdleInterior(string sCluster, object oExclude)
{
    object oArea;
    object oBest;
    int nBestHot;
    int nAreaHot;

    nBestHot = 2147483647;
    oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        if (oArea != oExclude &&
            NpcBhvrAreaGetClusterOwner(oArea) == sCluster &&
            NpcBhvrClusterAreaIsInterior(oArea) &&
            NpcBhvrGetCachedPlayerCountInternal(oArea) <= 0 &&
            NpcBhvrAreaGetState(oArea) == NPC_BHVR_AREA_STATE_RUNNING)
        {
            nAreaHot = GetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_LAST_HOT_AT);
            if (nAreaHot <= 0)
            {
                nAreaHot = 1;
            }

            if (!GetIsObjectValid(oBest) || nAreaHot < nBestHot)
            {
                oBest = oArea;
                nBestHot = nAreaHot;
            }
        }

        oArea = GetNextArea();
    }

    return oBest;
}

void NpcBhvrClusterUpdateRunningMetricForOwner(string sCluster)
{
    object oModule;
    int nRunning;

    oModule = GetModule();
    nRunning = NpcBhvrClusterCountRunningInteriorByOwner(sCluster);
    NpcBhvrMetricSet(oModule, NpcBhvrClusterMetricKey("npc_metric_cluster_running_interiors_", sCluster), nRunning);
}

void NpcBhvrClusterEnforceInteriorCaps(object oArea, int nNow)
{
    string sCluster;
    int nSoftCap;
    int nHardCap;
    int nRunning;
    object oVictim;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    sCluster = NpcBhvrClusterResolveOwner(oArea);
    nSoftCap = NpcBhvrClusterResolveInteriorSoftCap(oArea);
    nHardCap = NpcBhvrClusterResolveInteriorHardCap(oArea);
    if (nHardCap < nSoftCap)
    {
        nHardCap = nSoftCap;
    }

    nRunning = NpcBhvrClusterCountRunningInteriorByOwner(sCluster);

    while (nRunning > nHardCap)
    {
        oVictim = NpcBhvrClusterPickOldestIdleInterior(sCluster, oArea);
        if (!GetIsObjectValid(oVictim))
        {
            break;
        }

        NpcBhvrMetricInc(oVictim, NPC_BHVR_METRIC_CLUSTER_HARD_CAP_HIT_TOTAL);
        NpcBhvrClusterApplyTargetState(oVictim, NPC_BHVR_AREA_STATE_STOPPED, nNow);
        nRunning = NpcBhvrClusterCountRunningInteriorByOwner(sCluster);
    }

    while (nRunning > nSoftCap)
    {
        oVictim = NpcBhvrClusterPickOldestIdleInterior(sCluster, oArea);
        if (!GetIsObjectValid(oVictim))
        {
            break;
        }

        NpcBhvrMetricInc(oVictim, NPC_BHVR_METRIC_CLUSTER_SOFT_CAP_HIT_TOTAL);
        NpcBhvrClusterApplyTargetState(oVictim, NPC_BHVR_AREA_STATE_PAUSED, nNow);
        nRunning = NpcBhvrClusterCountRunningInteriorByOwner(sCluster);
    }

    NpcBhvrClusterUpdateRunningMetricForOwner(sCluster);
}

void NpcBhvrClusterOnPlayerAreaEnter(object oArea, int nNow)
{
    int nGraceSec;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrClusterResolveOwner(oArea);
    NpcBhvrAreaSetInterestState(oArea, NPC_BHVR_AREA_INTEREST_ACTIVE);
    SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_LAST_HOT_AT, nNow);
    nGraceSec = NpcBhvrClusterResolveGraceSec(oArea);
    SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_GRACE_UNTIL_AT, nNow + nGraceSec);

    NpcBhvrClusterApplyTargetState(oArea, NPC_BHVR_AREA_STATE_RUNNING, nNow);
    NpcBhvrClusterEnforceInteriorCaps(oArea, nNow);
}

void NpcBhvrClusterOnPlayerAreaExit(object oArea, int nNow)
{
    int nGraceSec;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrClusterResolveOwner(oArea);
    SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_LAST_HOT_AT, nNow);
    nGraceSec = NpcBhvrClusterResolveGraceSec(oArea);
    SetLocalInt(oArea, NPC_BHVR_VAR_CLUSTER_GRACE_UNTIL_AT, nNow + nGraceSec);
    NpcBhvrAreaSetInterestState(oArea, NPC_BHVR_AREA_INTEREST_BACKGROUND);

    NpcBhvrClusterApplyTargetState(oArea, NPC_BHVR_AREA_STATE_PAUSED, nNow);
    NpcBhvrClusterEnforceInteriorCaps(oArea, nNow);
}

void NpcBhvrClusterOrchestrateArea(object oArea)
{
    int nNow;
    int nTarget;

    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    nNow = NpcBhvrPendingNow();
    NpcBhvrClusterResolveOwner(oArea);

    nTarget = NpcBhvrClusterDesiredStateForArea(oArea, nNow);
    NpcBhvrClusterApplyTargetState(oArea, nTarget, nNow);
    NpcBhvrClusterEnforceInteriorCaps(oArea, nNow);
}
