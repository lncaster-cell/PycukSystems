// NPC runtime mode helpers: explicit split between ambient and reactive layers.

const int NPC_BHVR_LAYER_AMBIENT = 1;
const int NPC_BHVR_LAYER_REACTIVE = 2;

const int NPC_BHVR_DISPATCH_MODE_AMBIENT_ONLY = 1;
const int NPC_BHVR_DISPATCH_MODE_HYBRID = 2;
const int NPC_BHVR_DISPATCH_MODE_REACTIVE_ONLY = 3;

const int NPC_BHVR_AREA_INTEREST_UNKNOWN = 0;
const int NPC_BHVR_AREA_INTEREST_ACTIVE = 1;
const int NPC_BHVR_AREA_INTEREST_BACKGROUND = 2;

const int NPC_BHVR_SIM_LOD_FULL = 0;
const int NPC_BHVR_SIM_LOD_REDUCED = 1;
const int NPC_BHVR_SIM_LOD_PROJECTED = 2;

const int NPC_BHVR_PROJECTED_VISIBLE = 0;
const int NPC_BHVR_PROJECTED_HIDDEN = 1;

const string NPC_BHVR_VAR_DISPATCH_MODE = "npc_dispatch_mode";
const string NPC_BHVR_CFG_DISPATCH_MODE = "npc_cfg_dispatch_mode";
const string NPC_BHVR_VAR_NPC_LAYER = "npc_runtime_layer";
const string NPC_BHVR_CFG_NPC_FORCE_REACTIVE = "npc_cfg_force_reactive";
// Deprecated compatibility-only knobs (not canonical human-facing authoring).
const string NPC_BHVR_CFG_NPC_LAYER = "npc_cfg_layer";

// Cluster/LOD extension points for Ambient Life V3.
const string NPC_BHVR_VAR_AREA_CLUSTER_OWNER = "npc_area_cluster_owner";
const string NPC_BHVR_VAR_AREA_INTEREST_STATE = "npc_area_interest_state";
const string NPC_BHVR_VAR_NPC_SIM_LOD = "npc_npc_sim_lod";
const string NPC_BHVR_VAR_NPC_PROJECTED_STATE = "npc_npc_projected_state";

int NpcBhvrNormalizeDispatchMode(int nMode)
{
    if (nMode == NPC_BHVR_DISPATCH_MODE_AMBIENT_ONLY ||
        nMode == NPC_BHVR_DISPATCH_MODE_REACTIVE_ONLY)
    {
        return nMode;
    }

    return NPC_BHVR_DISPATCH_MODE_HYBRID;
}

int NpcBhvrResolveAreaDispatchMode(object oArea)
{
    object oModule;
    int nMode;
    int nResolvedMode;

    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_DISPATCH_MODE_HYBRID;
    }

    // Do not treat runtime mirror as authoritative input: this value is a
    // derived cache and must be recomputed from config sources.
    nMode = GetLocalInt(oArea, NPC_BHVR_CFG_DISPATCH_MODE);

    if (nMode <= 0)
    {
        oModule = GetModule();
        nMode = GetLocalInt(oModule, NPC_BHVR_CFG_DISPATCH_MODE);
    }

    nResolvedMode = NpcBhvrNormalizeDispatchMode(nMode);
    // Keep compatibility mirror for diagnostics/external consumers.
    SetLocalInt(oArea, NPC_BHVR_VAR_DISPATCH_MODE, nResolvedMode);
    return nResolvedMode;
}

int NpcBhvrNormalizeNpcLayer(int nLayer)
{
    if (nLayer == NPC_BHVR_LAYER_REACTIVE)
    {
        return NPC_BHVR_LAYER_REACTIVE;
    }

    return NPC_BHVR_LAYER_AMBIENT;
}

int NpcBhvrResolveNpcLayer(object oNpc)
{
    object oArea;
    int nLayer;
    int nDispatchMode;

    if (!GetIsObjectValid(oNpc))
    {
        return NPC_BHVR_LAYER_AMBIENT;
    }

    // Always resolve from config + area mode so runtime does not stick on
    // stale cached layer after config/dispatch changes.
    if (GetLocalInt(oNpc, NPC_BHVR_CFG_NPC_FORCE_REACTIVE) == TRUE)
    {
        nLayer = NPC_BHVR_LAYER_REACTIVE;
    }

    if (nLayer <= 0)
    {
        nLayer = GetLocalInt(oNpc, NPC_BHVR_CFG_NPC_LAYER);
    }


    oArea = GetArea(oNpc);
    nDispatchMode = NpcBhvrResolveAreaDispatchMode(oArea);
    if (nDispatchMode == NPC_BHVR_DISPATCH_MODE_REACTIVE_ONLY)
    {
        nLayer = NPC_BHVR_LAYER_REACTIVE;
    }

    nLayer = NpcBhvrNormalizeNpcLayer(nLayer);
    // Keep compatibility mirror for diagnostics/external consumers.
    SetLocalInt(oNpc, NPC_BHVR_VAR_NPC_LAYER, nLayer);
    return nLayer;
}

int NpcBhvrNpcUsesReactivePath(object oNpc)
{
    return NpcBhvrResolveNpcLayer(oNpc) == NPC_BHVR_LAYER_REACTIVE;
}

int NpcBhvrAreaAllowsAmbientDispatch(object oArea)
{
    return NpcBhvrResolveAreaDispatchMode(oArea) != NPC_BHVR_DISPATCH_MODE_REACTIVE_ONLY;
}

int NpcBhvrAreaAllowsReactiveDispatch(object oArea)
{
    return NpcBhvrResolveAreaDispatchMode(oArea) != NPC_BHVR_DISPATCH_MODE_AMBIENT_ONLY;
}

void NpcBhvrAreaSetClusterOwner(object oArea, string sClusterOwner)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (GetStringLength(sClusterOwner) <= 0)
    {
        DeleteLocalString(oArea, NPC_BHVR_VAR_AREA_CLUSTER_OWNER);
        return;
    }

    SetLocalString(oArea, NPC_BHVR_VAR_AREA_CLUSTER_OWNER, sClusterOwner);
}

string NpcBhvrAreaGetClusterOwner(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return "";
    }

    return GetLocalString(oArea, NPC_BHVR_VAR_AREA_CLUSTER_OWNER);
}

void NpcBhvrAreaSetInterestState(object oArea, int nState)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    if (nState < NPC_BHVR_AREA_INTEREST_UNKNOWN || nState > NPC_BHVR_AREA_INTEREST_BACKGROUND)
    {
        nState = NPC_BHVR_AREA_INTEREST_UNKNOWN;
    }

    SetLocalInt(oArea, NPC_BHVR_VAR_AREA_INTEREST_STATE, nState);
}

int NpcBhvrAreaGetInterestState(object oArea)
{
    int nState;

    if (!GetIsObjectValid(oArea))
    {
        return NPC_BHVR_AREA_INTEREST_UNKNOWN;
    }

    nState = GetLocalInt(oArea, NPC_BHVR_VAR_AREA_INTEREST_STATE);
    if (nState < NPC_BHVR_AREA_INTEREST_UNKNOWN || nState > NPC_BHVR_AREA_INTEREST_BACKGROUND)
    {
        nState = NPC_BHVR_AREA_INTEREST_UNKNOWN;
    }

    return nState;
}

void NpcBhvrSetNpcSimulationLod(object oNpc, int nLod)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (nLod < NPC_BHVR_SIM_LOD_FULL || nLod > NPC_BHVR_SIM_LOD_PROJECTED)
    {
        nLod = NPC_BHVR_SIM_LOD_FULL;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_NPC_SIM_LOD, nLod);
}

int NpcBhvrGetNpcSimulationLod(object oNpc)
{
    int nLod;

    if (!GetIsObjectValid(oNpc))
    {
        return NPC_BHVR_SIM_LOD_FULL;
    }

    nLod = GetLocalInt(oNpc, NPC_BHVR_VAR_NPC_SIM_LOD);
    if (nLod < NPC_BHVR_SIM_LOD_FULL || nLod > NPC_BHVR_SIM_LOD_PROJECTED)
    {
        nLod = NPC_BHVR_SIM_LOD_FULL;
    }

    return nLod;
}

void NpcBhvrSetNpcProjectedState(object oNpc, int nState)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (nState != NPC_BHVR_PROJECTED_HIDDEN)
    {
        nState = NPC_BHVR_PROJECTED_VISIBLE;
    }

    SetLocalInt(oNpc, NPC_BHVR_VAR_NPC_PROJECTED_STATE, nState);
}

int NpcBhvrGetNpcProjectedState(object oNpc)
{
    if (!GetIsObjectValid(oNpc))
    {
        return NPC_BHVR_PROJECTED_VISIBLE;
    }

    if (GetLocalInt(oNpc, NPC_BHVR_VAR_NPC_PROJECTED_STATE) == NPC_BHVR_PROJECTED_HIDDEN)
    {
        return NPC_BHVR_PROJECTED_HIDDEN;
    }

    return NPC_BHVR_PROJECTED_VISIBLE;
}
