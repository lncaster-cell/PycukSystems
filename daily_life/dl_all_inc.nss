const string DL_L_NPC_FAMILY = "dl_npc_family";
const string DL_L_NPC_SUBTYPE = "dl_npc_subtype";
const string DL_L_SCHEDULE_TEMPLATE = "dl_schedule_template";
const string DL_L_NPC_BASE = "dl_npc_base";
const string DL_L_NAMED = "dl_named";
const string DL_L_PERSISTENT = "dl_persistent";
const string DL_L_PERSONAL_OFFSET_MIN = "dl_personal_offset_min";
const string DL_L_ALLOWED_DIRECTIVES_MASK = "dl_allowed_directives_mask";
const string DL_L_OVERRIDE_KIND = "dl_override_kind";
const string DL_L_DIRECTIVE = "dl_current_directive";
const string DL_L_ANCHOR_GROUP = "dl_current_anchor_group";
const string DL_L_DIALOGUE_MODE = "dl_dialogue_mode";
const string DL_L_SERVICE_MODE = "dl_service_mode";
const string DL_L_ACTIVITY_KIND = "dl_activity_kind";
const string DL_L_AREA_TIER = "dl_area_tier";
const string DL_L_RESYNC_PENDING = "dl_resync_pending";
const string DL_L_RESYNC_REASON = "dl_resync_reason";
const string DL_L_DAY_TYPE_OVERRIDE = "dl_day_type_override";
const string DL_L_LAST_SLOT_REVIEW = "dl_last_slot_review";
const string DL_L_LAST_SLOT_REVIEW_REASON = "dl_last_slot_review_reason";
const string DL_L_LAST_SLOT_ASSIGNED = "dl_last_slot_assigned";
const string DL_L_LAST_SLOT_ASSIGNED_REASON = "dl_last_slot_assigned_reason";
const string DL_L_SLOT_ASSIGNED_NPC = "dl_slot_assigned_npc";
const string DL_L_LAST_BASE_LOST_SLOT = "dl_last_base_lost_slot";
const string DL_L_LAST_BASE_LOST_NPC = "dl_last_base_lost_npc";
const string DL_L_LAST_BASE_LOST_KIND = "dl_last_base_lost_kind";
const string DL_L_FUNCTION_SLOT_ID = "dl_function_slot_id";
const string DL_L_PENDING_SLOT_ID = "dl_pending_slot_id";
const string DL_L_SMOKE_TRACE = "dl_smoke_trace";

const int DL_DEBUG_NONE = 0;
const int DL_DEBUG_BASIC = 1;
const int DL_DEBUG_VERBOSE = 2;
const int DL_DEBUG_LEVEL = DL_DEBUG_BASIC;

const int DL_FAMILY_NONE = 0;
const int DL_FAMILY_LAW = 1;
const int DL_FAMILY_CRAFT = 2;
const int DL_FAMILY_TRADE_SERVICE = 3;
const int DL_FAMILY_CIVILIAN = 4;
const int DL_FAMILY_ELITE_ADMIN = 5;
const int DL_FAMILY_CLERGY = 6;

const int DL_SUBTYPE_NONE = 0;
const int DL_SUBTYPE_PATROL = 1;
const int DL_SUBTYPE_GATE_POST = 2;
const int DL_SUBTYPE_INSPECTION = 3;
const int DL_SUBTYPE_BLACKSMITH = 4;
const int DL_SUBTYPE_ARTISAN = 5;
const int DL_SUBTYPE_LABORER = 6;
const int DL_SUBTYPE_SHOPKEEPER = 7;
const int DL_SUBTYPE_INNKEEPER = 8;
const int DL_SUBTYPE_WANDERING_VENDOR = 9;
const int DL_SUBTYPE_RESIDENT = 10;
const int DL_SUBTYPE_HOMELESS = 11;
const int DL_SUBTYPE_SERVANT = 12;
const int DL_SUBTYPE_NOBLE = 13;
const int DL_SUBTYPE_OFFICIAL = 14;
const int DL_SUBTYPE_SCRIBE = 15;
const int DL_SUBTYPE_PRIEST = 16;

const int DL_SCH_NONE = 0;
const int DL_SCH_EARLY_WORKER = 1;
const int DL_SCH_SHOP_DAY = 2;
const int DL_SCH_TAVERN_LATE = 3;
const int DL_SCH_DUTY_ROTATION_DAY = 4;
const int DL_SCH_DUTY_ROTATION_NIGHT = 5;
const int DL_SCH_WANDERING_VENDOR_WINDOW = 6;
const int DL_SCH_CIVILIAN_HOME = 7;

const int DL_DAY_WEEKDAY = 1;
const int DL_DAY_REST = 2;
const int DL_DAY_CRISIS = 3;

const int DL_WIN_NONE = 0;
const int DL_WIN_SLEEP = 1;
const int DL_WIN_MORNING_PREP = 2;
const int DL_WIN_WORK_CORE = 3;
const int DL_WIN_SERVICE_CORE = 4;
const int DL_WIN_PUBLIC_IDLE = 5;
const int DL_WIN_SOCIAL = 6;
const int DL_WIN_LATE_SOCIAL = 7;
const int DL_WIN_DAY_DUTY = 8;
const int DL_WIN_NIGHT_DUTY = 9;

const int DL_BASE_NONE = 0;
const int DL_BASE_HOME = 1;
const int DL_BASE_WORKSHOP = 2;
const int DL_BASE_SHOP = 3;
const int DL_BASE_TAVERN = 4;
const int DL_BASE_BARRACKS = 5;
const int DL_BASE_TEMPLE = 6;
const int DL_BASE_OFFICE = 7;

const int DL_AG_NONE = 0;
const int DL_AG_SLEEP = 1;
const int DL_AG_WORK = 2;
const int DL_AG_SERVICE = 3;
const int DL_AG_SOCIAL = 4;
const int DL_AG_DUTY = 5;
const int DL_AG_GATE = 6;
const int DL_AG_PATROL_POINT = 7;
const int DL_AG_STREET_NEAR_BASE = 8;
const int DL_AG_WAIT = 9;
const int DL_AG_HIDE = 10;

const int DL_DIR_NONE = 0;
const int DL_DIR_SLEEP = 1;
const int DL_DIR_WORK = 2;
const int DL_DIR_SERVICE = 3;
const int DL_DIR_SOCIAL = 4;
const int DL_DIR_DUTY = 5;
const int DL_DIR_PUBLIC_PRESENCE = 6;
const int DL_DIR_HOLD_POST = 7;
const int DL_DIR_LOCKDOWN_BASE = 8;
const int DL_DIR_HIDE_SAFE = 9;
const int DL_DIR_ABSENT = 10;
const int DL_DIR_UNASSIGNED = 11;

const int DL_DLG_NONE = 0;
const int DL_DLG_WORK = 1;
const int DL_DLG_OFF_DUTY = 2;
const int DL_DLG_INSPECTION = 3;
const int DL_DLG_LOCKDOWN = 4;
const int DL_DLG_HIDE = 5;
const int DL_DLG_UNAVAILABLE = 6;

const int DL_SERVICE_NONE = 0;
const int DL_SERVICE_AVAILABLE = 1;
const int DL_SERVICE_LIMITED = 2;
const int DL_SERVICE_DISABLED = 3;

// Forward declarations for legacy compiler single-pass resolution.
int DL_NormalizeResyncReason(int nReason);
int DL_SelectStrongerResyncReason(int nCurrentReason, int nRequestedReason);

const int DL_ACT_NONE = 0;
const int DL_ACT_SLEEP = 1;
const int DL_ACT_WORK = 2;
const int DL_ACT_SERVICE_IDLE = 3;
const int DL_ACT_SOCIAL = 4;
const int DL_ACT_DUTY_IDLE = 5;
const int DL_ACT_HIDE = 6;

const int DL_OVR_NONE = 0;
const int DL_OVR_FIRE = 1;
const int DL_OVR_QUARANTINE = 2;

const int DL_AREA_FROZEN = 0;
const int DL_AREA_WARM = 1;
const int DL_AREA_HOT = 2;

const int DL_RESYNC_NONE = 0;
const int DL_RESYNC_AREA_ENTER = 1;
const int DL_RESYNC_TIER_UP = 2;
const int DL_RESYNC_SAVE_LOAD = 3;
const int DL_RESYNC_TIME_JUMP = 4;
const int DL_RESYNC_OVERRIDE_END = 5;
const int DL_RESYNC_WORKER = 6;
const int DL_RESYNC_SLOT_ASSIGNED = 7;
const int DL_RESYNC_BASE_LOST = 8;

const int DL_BUDGET_HOT = 6;
const int DL_BUDGET_WARM = 2;
const int DL_BUDGET_FROZEN = 0;

int DL_GetDefaultWorkerBudget()
{
    return DL_BUDGET_HOT;
}

int DL_GetDefaultAreaTierBudget(int nTier)
{
    if (nTier == DL_AREA_HOT)
    {
        return DL_BUDGET_HOT;
    }
    if (nTier == DL_AREA_WARM)
    {
        return DL_BUDGET_WARM;
    }
    return DL_BUDGET_FROZEN;
}

void DL_Log(int nLevel, string sMessage)
{
    if (nLevel > DL_DEBUG_LEVEL)
    {
        return;
    }

    WriteTimestampedLogEntry("[DLV1] " + sMessage);
}

void DL_LogNpc(object oNPC, int nLevel, string sMessage)
{
    string sTag = "<invalid>";
    if (GetIsObjectValid(oNPC))
    {
        sTag = GetTag(oNPC);
    }
    DL_Log(nLevel, sTag + ": " + sMessage);
}

int DL_IsValidCreature(object oNPC)
{
    return GetIsObjectValid(oNPC) && GetObjectType(oNPC) == OBJECT_TYPE_CREATURE;
}

int DL_IsAreaHot(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER) == DL_AREA_HOT;
}

int DL_IsAreaWarm(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER) == DL_AREA_WARM;
}

int DL_IsAreaFrozen(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER) == DL_AREA_FROZEN;
}

int DL_IsDirectiveVisible(int nDirective)
{
    return nDirective != DL_DIR_ABSENT
        && nDirective != DL_DIR_HIDE_SAFE
        && nDirective != DL_DIR_UNASSIGNED;
}

int DL_IsPlayableAreaPlayer(object oObject)
{
    return GetIsPC(oObject) && !GetIsDM(oObject);
}

int DL_HasAnyPlayers(object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsPlayableAreaPlayer(oObject))
        {
            return TRUE;
        }
        oObject = GetNextObjectInArea(oArea);
    }
    return FALSE;
}

int DL_HasAnyPlayersExcept(object oArea, object oIgnored)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (oObject != oIgnored && DL_IsPlayableAreaPlayer(oObject))
        {
            return TRUE;
        }
        oObject = GetNextObjectInArea(oArea);
    }
    return FALSE;
}

int DL_IsAreaAnchor(object oPoint, object oArea)
{
    return GetIsObjectValid(oPoint) && GetArea(oPoint) == oArea;
}

const int DL_ANCHOR_SEARCH_MAX_INDEX = 4;

int DL_IsAnchorMarkerType(int nObjType)
{
    return nObjType == OBJECT_TYPE_WAYPOINT || nObjType == OBJECT_TYPE_PLACEABLE;
}

string DL_GetAnchorGroupToken(int nAnchorGroup)
{
    if (nAnchorGroup == DL_AG_SLEEP) return "sleep";
    if (nAnchorGroup == DL_AG_WORK) return "work";
    if (nAnchorGroup == DL_AG_SERVICE) return "service";
    if (nAnchorGroup == DL_AG_SOCIAL) return "social";
    if (nAnchorGroup == DL_AG_DUTY) return "duty";
    if (nAnchorGroup == DL_AG_GATE) return "gate";
    if (nAnchorGroup == DL_AG_PATROL_POINT) return "patrol";
    if (nAnchorGroup == DL_AG_STREET_NEAR_BASE) return "street";
    if (nAnchorGroup == DL_AG_WAIT) return "wait";
    if (nAnchorGroup == DL_AG_HIDE) return "hide";
    return "none";
}

string DL_GetSubtypeAnchorToken(object oNPC, int nAnchorGroup)
{
    int nSubtype = GetLocalInt(oNPC, DL_L_NPC_SUBTYPE);

    if (nSubtype == DL_SUBTYPE_BLACKSMITH)
    {
        if (nAnchorGroup == DL_AG_WORK) return "forge";
        if (nAnchorGroup == DL_AG_SLEEP) return "bed";
        if (nAnchorGroup == DL_AG_SOCIAL) return "tavern";
    }
    if (nSubtype == DL_SUBTYPE_ARTISAN || nSubtype == DL_SUBTYPE_LABORER)
    {
        if (nAnchorGroup == DL_AG_WORK) return "workbench";
    }
    if (nSubtype == DL_SUBTYPE_SHOPKEEPER)
    {
        if (nAnchorGroup == DL_AG_SERVICE) return "counter";
    }
    if (nSubtype == DL_SUBTYPE_INNKEEPER)
    {
        if (nAnchorGroup == DL_AG_SERVICE) return "bar";
        if (nAnchorGroup == DL_AG_SOCIAL) return "tavern";
    }
    if (nSubtype == DL_SUBTYPE_GATE_POST)
    {
        if (nAnchorGroup == DL_AG_DUTY || nAnchorGroup == DL_AG_GATE) return "gate_post";
        if (nAnchorGroup == DL_AG_SLEEP) return "barracks_bed";
    }
    if (nSubtype == DL_SUBTYPE_PATROL)
    {
        if (nAnchorGroup == DL_AG_DUTY || nAnchorGroup == DL_AG_PATROL_POINT) return "patrol_point";
    }
    if (nAnchorGroup == DL_AG_STREET_NEAR_BASE) return "street";
    if (nAnchorGroup == DL_AG_HIDE) return "inside";
    return DL_GetAnchorGroupToken(nAnchorGroup);
}

string DL_BuildIndexedAnchorTag(string sPrefix, string sToken, int nIndex)
{
    return sPrefix + "_" + sToken + "_" + IntToString(nIndex);
}

string DL_GetAnchorTagCandidate(object oNPC, int nAnchorGroup, int nIndex)
{
    return DL_BuildIndexedAnchorTag(GetTag(oNPC), DL_GetAnchorGroupToken(nAnchorGroup), nIndex);
}

string DL_GetBaseAnchorTagCandidate(object oNPC, int nAnchorGroup, int nIndex)
{
    object oBase = GetLocalObject(oNPC, DL_L_NPC_BASE);
    if (!GetIsObjectValid(oBase)) return "";
    return DL_BuildIndexedAnchorTag(GetTag(oBase), DL_GetAnchorGroupToken(nAnchorGroup), nIndex);
}

string DL_GetSpecializedAnchorTagCandidate(object oNPC, int nAnchorGroup, int nIndex)
{
    object oBase = GetLocalObject(oNPC, DL_L_NPC_BASE);
    string sToken = DL_GetSubtypeAnchorToken(oNPC, nAnchorGroup);
    if (sToken == "") return "";
    if (GetIsObjectValid(oBase))
    {
        return DL_BuildIndexedAnchorTag(GetTag(oBase), sToken, nIndex);
    }
    return sToken + "_" + IntToString(nIndex);
}

string DL_GetAreaAnchorTagCandidate(object oNPC, object oArea, int nAnchorGroup, int nIndex)
{
    if (!GetIsObjectValid(oArea)) return "";
    return DL_BuildIndexedAnchorTag(GetTag(oArea), DL_GetSubtypeAnchorToken(oNPC, nAnchorGroup), nIndex);
}

int DL_IsFamilyInFirstPlayableSlice(int nFamily)
{
    return nFamily == DL_FAMILY_LAW || nFamily == DL_FAMILY_CRAFT || nFamily == DL_FAMILY_TRADE_SERVICE;
}

int DL_IsSubtypeAllowedForFamily(int nFamily, int nSubtype)
{
    if (nSubtype == DL_SUBTYPE_NONE) return TRUE;
    if (nFamily == DL_FAMILY_LAW)
    {
        return nSubtype == DL_SUBTYPE_PATROL || nSubtype == DL_SUBTYPE_GATE_POST || nSubtype == DL_SUBTYPE_INSPECTION;
    }
    if (nFamily == DL_FAMILY_CRAFT)
    {
        return nSubtype == DL_SUBTYPE_BLACKSMITH || nSubtype == DL_SUBTYPE_ARTISAN || nSubtype == DL_SUBTYPE_LABORER;
    }
    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        return nSubtype == DL_SUBTYPE_SHOPKEEPER || nSubtype == DL_SUBTYPE_INNKEEPER || nSubtype == DL_SUBTYPE_WANDERING_VENDOR;
    }
    return FALSE;
}

int DL_IsNamed(object oNPC)
{
    return GetLocalInt(oNPC, DL_L_NAMED) == TRUE;
}

int DL_IsPersistent(object oNPC)
{
    return GetLocalInt(oNPC, DL_L_PERSISTENT) == TRUE;
}

int DL_GetNpcFamily(object oNPC)
{
    int nFamily = GetLocalInt(oNPC, DL_L_NPC_FAMILY);
    if (DL_IsFamilyInFirstPlayableSlice(nFamily)) return nFamily;
    return DL_FAMILY_NONE;
}

int DL_GetNpcSubtype(object oNPC)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = GetLocalInt(oNPC, DL_L_NPC_SUBTYPE);
    if (DL_IsSubtypeAllowedForFamily(nFamily, nSubtype)) return nSubtype;
    return DL_SUBTYPE_NONE;
}

int DL_IsDailyLifeNpc(object oNPC)
{
    return DL_GetNpcFamily(oNPC) != DL_FAMILY_NONE;
}

int DL_GetDefaultScheduleTemplateForProfile(int nFamily, int nSubtype)
{
    if (nFamily == DL_FAMILY_LAW)
    {
        if (nSubtype == DL_SUBTYPE_GATE_POST) return DL_SCH_DUTY_ROTATION_DAY;
        return DL_SCH_DUTY_ROTATION_NIGHT;
    }
    if (nFamily == DL_FAMILY_CRAFT) return DL_SCH_EARLY_WORKER;
    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        if (nSubtype == DL_SUBTYPE_INNKEEPER) return DL_SCH_TAVERN_LATE;
        if (nSubtype == DL_SUBTYPE_WANDERING_VENDOR) return DL_SCH_WANDERING_VENDOR_WINDOW;
        return DL_SCH_SHOP_DAY;
    }
    return DL_SCH_CIVILIAN_HOME;
}

int DL_GetDefaultScheduleTemplate(object oNPC)
{
    return DL_GetDefaultScheduleTemplateForProfile(DL_GetNpcFamily(oNPC), DL_GetNpcSubtype(oNPC));
}

int DL_GetScheduleTemplate(object oNPC)
{
    int nTemplate = GetLocalInt(oNPC, DL_L_SCHEDULE_TEMPLATE);
    if (nTemplate != DL_SCH_NONE) return nTemplate;
    return DL_GetDefaultScheduleTemplate(oNPC);
}

int DL_GetNpcBaseKind(object oNPC)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);

    if (nFamily == DL_FAMILY_LAW) return DL_BASE_BARRACKS;
    if (nFamily == DL_FAMILY_CRAFT) return DL_BASE_WORKSHOP;
    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        if (nSubtype == DL_SUBTYPE_INNKEEPER) return DL_BASE_TAVERN;
        return DL_BASE_SHOP;
    }
    return DL_BASE_HOME;
}

object DL_GetNpcBase(object oNPC)
{
    return GetLocalObject(oNPC, DL_L_NPC_BASE);
}

string DL_GetFunctionSlotId(object oNPC)
{
    return GetLocalString(oNPC, DL_L_FUNCTION_SLOT_ID);
}

int DL_GetDefaultAllowedDirectivesMaskForFamily(int nFamily)
{
    if (nFamily == DL_FAMILY_LAW)
    {
        return (1 << DL_DIR_SLEEP) | (1 << DL_DIR_DUTY) | (1 << DL_DIR_HOLD_POST) | (1 << DL_DIR_PUBLIC_PRESENCE) | (1 << DL_DIR_HIDE_SAFE) | (1 << DL_DIR_LOCKDOWN_BASE) | (1 << DL_DIR_ABSENT);
    }
    if (nFamily == DL_FAMILY_CRAFT)
    {
        return (1 << DL_DIR_SLEEP) | (1 << DL_DIR_WORK) | (1 << DL_DIR_SOCIAL) | (1 << DL_DIR_PUBLIC_PRESENCE) | (1 << DL_DIR_HIDE_SAFE) | (1 << DL_DIR_LOCKDOWN_BASE) | (1 << DL_DIR_ABSENT);
    }
    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        return (1 << DL_DIR_SLEEP) | (1 << DL_DIR_SERVICE) | (1 << DL_DIR_SOCIAL) | (1 << DL_DIR_PUBLIC_PRESENCE) | (1 << DL_DIR_HIDE_SAFE) | (1 << DL_DIR_LOCKDOWN_BASE) | (1 << DL_DIR_ABSENT);
    }
    return (1 << DL_DIR_SLEEP) | (1 << DL_DIR_SOCIAL) | (1 << DL_DIR_PUBLIC_PRESENCE) | (1 << DL_DIR_HIDE_SAFE) | (1 << DL_DIR_ABSENT);
}

int DL_GetDefaultAllowedDirectivesMask(object oNPC)
{
    return DL_GetDefaultAllowedDirectivesMaskForFamily(DL_GetNpcFamily(oNPC));
}

int DL_GetAllowedDirectivesMask(object oNPC)
{
    int nMask = GetLocalInt(oNPC, DL_L_ALLOWED_DIRECTIVES_MASK);
    if (nMask != 0) return nMask;
    return DL_GetDefaultAllowedDirectivesMask(oNPC);
}

int DL_HasBase(object oNPC)
{
    return GetIsObjectValid(DL_GetNpcBase(oNPC));
}

int DL_SupportsDirective(object oNPC, int nDirective)
{
    int nMask = DL_GetAllowedDirectivesMask(oNPC);
    if (nMask == 0) return TRUE;
    return (nMask & (1 << nDirective)) != 0;
}

int DL_GetAreaTier(object oArea)
{
    return GetLocalInt(oArea, DL_L_AREA_TIER);
}

void DL_SetAreaTier(object oArea, int nTier)
{
    SetLocalInt(oArea, DL_L_AREA_TIER, nTier);
}

int DL_ShouldRunDailyLifeTier(int nTier)
{
    return nTier == DL_AREA_HOT || nTier == DL_AREA_WARM;
}

int DL_ShouldRunDailyLife(object oArea)
{
    return DL_ShouldRunDailyLifeTier(DL_GetAreaTier(oArea));
}

void DL_OnAreaBecameHot(object oArea)
{
    DL_SetAreaTier(oArea, DL_AREA_HOT);
    DL_Log(DL_DEBUG_BASIC, "Area HOT: " + GetTag(oArea));
}

void DL_OnAreaBecameWarm(object oArea)
{
    DL_SetAreaTier(oArea, DL_AREA_WARM);
    DL_Log(DL_DEBUG_BASIC, "Area WARM: " + GetTag(oArea));
}

void DL_OnAreaBecameFrozen(object oArea)
{
    DL_SetAreaTier(oArea, DL_AREA_FROZEN);
    DL_Log(DL_DEBUG_BASIC, "Area FROZEN: " + GetTag(oArea));
}

int DL_GetDaysInMonth(int nYear, int nMonth)
{
    return 28;
}

int DL_GetAbsoluteDayNumber()
{
    int nYear = GetCalendarYear();
    int nMonth = GetCalendarMonth();
    int nDay = GetCalendarDay();

    if (nYear < 0)
    {
        nYear = 0;
    }
    if (nMonth < 1)
    {
        nMonth = 1;
    }
    if (nMonth > 12)
    {
        nMonth = 12;
    }
    if (nDay < 0)
    {
        nDay = 0;
    }
    if (nDay > 28)
    {
        nDay = 28;
    }

    return (nYear * 336) + ((nMonth - 1) * 28) + nDay;
}

int DL_DetermineDayType(object oArea)
{
    int nOverride = GetLocalInt(oArea, DL_L_DAY_TYPE_OVERRIDE);
    if (nOverride != 0) return nOverride;
    if ((DL_GetAbsoluteDayNumber() % 7) == 0) return DL_DAY_REST;
    return DL_DAY_WEEKDAY;
}

int DL_GetPersonalTimeOffset(object oNPC)
{
    return GetLocalInt(oNPC, DL_L_PERSONAL_OFFSET_MIN);
}

int DL_GetCurrentMinuteOfDay()
{
    return (GetTimeHour() * 60) + GetTimeMinute();
}

int DL_DetermineScheduleWindow(int nTemplate, int nDayType, int nMinuteOfDay, int nOffset)
{
    int nMinute = (nMinuteOfDay + nOffset) % 1440;
    if (nMinute < 0)
    {
        nMinute += 1440;
    }

    if (nTemplate == DL_SCH_EARLY_WORKER)
    {
        if (nMinute < 360) return DL_WIN_SLEEP;
        if (nMinute < 480) return DL_WIN_MORNING_PREP;
        if (nMinute < 1020) return DL_WIN_WORK_CORE;
        if (nMinute < 1260) return DL_WIN_SOCIAL;
        return DL_WIN_SLEEP;
    }
    if (nTemplate == DL_SCH_SHOP_DAY)
    {
        if (nMinute < 420) return DL_WIN_SLEEP;
        if (nMinute < 540) return DL_WIN_MORNING_PREP;
        if (nMinute < 1140) return DL_WIN_SERVICE_CORE;
        if (nMinute < 1260) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_SLEEP;
    }
    if (nTemplate == DL_SCH_TAVERN_LATE)
    {
        if (nMinute < 600) return DL_WIN_SLEEP;
        if (nMinute < 900) return DL_WIN_PUBLIC_IDLE;
        if (nMinute < 1380) return DL_WIN_LATE_SOCIAL;
        return DL_WIN_SLEEP;
    }
    if (nTemplate == DL_SCH_DUTY_ROTATION_DAY)
    {
        if (nMinute < 360) return DL_WIN_SLEEP;
        if (nMinute < 1080) return DL_WIN_DAY_DUTY;
        if (nMinute < 1260) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_SLEEP;
    }
    if (nTemplate == DL_SCH_DUTY_ROTATION_NIGHT)
    {
        if (nMinute < 420) return DL_WIN_NIGHT_DUTY;
        if (nMinute < 960) return DL_WIN_SLEEP;
        if (nMinute < 1200) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_NIGHT_DUTY;
    }
    if (nTemplate == DL_SCH_WANDERING_VENDOR_WINDOW)
    {
        if (nMinute < 420) return DL_WIN_SLEEP;
        if (nMinute < 1020) return DL_WIN_SERVICE_CORE;
        if (nMinute < 1200) return DL_WIN_PUBLIC_IDLE;
        return DL_WIN_SLEEP;
    }
    if (nDayType == DL_DAY_REST)
    {
        if (nMinute < 480) return DL_WIN_SLEEP;
        if (nMinute < 1140) return DL_WIN_PUBLIC_IDLE;
        if (nMinute < 1260) return DL_WIN_SOCIAL;
        return DL_WIN_SLEEP;
    }
    if (nMinute < 360) return DL_WIN_SLEEP;
    if (nMinute < 1020) return DL_WIN_PUBLIC_IDLE;
    if (nMinute < 1200) return DL_WIN_SOCIAL;
    return DL_WIN_SLEEP;
}

int DL_GetTopOverride(object oNPC, object oArea)
{
    int nOverride = GetLocalInt(oNPC, DL_L_OVERRIDE_KIND);
    if (nOverride != DL_OVR_NONE) return nOverride;
    nOverride = GetLocalInt(oArea, DL_L_OVERRIDE_KIND);
    if (nOverride != DL_OVR_NONE) return nOverride;
    return GetLocalInt(GetModule(), DL_L_OVERRIDE_KIND);
}

int DL_HasCriticalOverride(object oNPC, object oArea)
{
    int nOverride = DL_GetTopOverride(oNPC, oArea);
    return nOverride == DL_OVR_FIRE || nOverride == DL_OVR_QUARANTINE;
}

int DL_IsLawFamilyOverrideExempt(object oNPC)
{
    return DL_GetNpcFamily(oNPC) == DL_FAMILY_LAW;
}

int DL_ShouldSuppressMaterialization(object oNPC, int nOverrideKind)
{
    if (nOverrideKind == DL_OVR_FIRE || nOverrideKind == DL_OVR_QUARANTINE)
    {
        return !DL_IsLawFamilyOverrideExempt(oNPC);
    }
    return FALSE;
}

int DL_ShouldDisableService(object oNPC, int nOverrideKind)
{
    if (nOverrideKind == DL_OVR_FIRE) return TRUE;
    if (nOverrideKind == DL_OVR_QUARANTINE) return !DL_IsLawFamilyOverrideExempt(oNPC);
    return FALSE;
}

int DL_IsSocialScheduleWindow(int nScheduleWindow)
{
    return nScheduleWindow == DL_WIN_SOCIAL || nScheduleWindow == DL_WIN_LATE_SOCIAL;
}

int DL_IsDutyScheduleWindow(int nScheduleWindow)
{
    return nScheduleWindow == DL_WIN_DAY_DUTY || nScheduleWindow == DL_WIN_NIGHT_DUTY;
}

int DL_IsDutyDirective(int nDirective)
{
    return nDirective == DL_DIR_DUTY || nDirective == DL_DIR_HOLD_POST;
}

int DL_IsWorkOrServiceDirective(int nDirective)
{
    return nDirective == DL_DIR_WORK || nDirective == DL_DIR_SERVICE;
}

int DL_IsUnavailableDirective(int nDirective)
{
    return nDirective == DL_DIR_UNASSIGNED || nDirective == DL_DIR_ABSENT;
}

int DL_ResolveDirectiveFromSchedule(object oNPC, int nScheduleWindow, int nDayType)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);
    if (!DL_HasBase(oNPC)) return DL_DIR_ABSENT;
    if (nScheduleWindow == DL_WIN_SLEEP) return DL_DIR_SLEEP;
    if (nFamily == DL_FAMILY_LAW)
    {
        if (DL_IsDutyScheduleWindow(nScheduleWindow))
        {
            if (nSubtype == DL_SUBTYPE_GATE_POST) return DL_DIR_HOLD_POST;
            return DL_DIR_DUTY;
        }
        if (nScheduleWindow == DL_WIN_PUBLIC_IDLE) return DL_DIR_PUBLIC_PRESENCE;
        return DL_DIR_SLEEP;
    }
    if (nFamily == DL_FAMILY_CRAFT)
    {
        if (nScheduleWindow == DL_WIN_WORK_CORE) return DL_DIR_WORK;
        if (DL_IsSocialScheduleWindow(nScheduleWindow) || nDayType == DL_DAY_REST) return DL_DIR_SOCIAL;
        return DL_DIR_PUBLIC_PRESENCE;
    }
    if (nFamily == DL_FAMILY_TRADE_SERVICE)
    {
        if (nScheduleWindow == DL_WIN_SERVICE_CORE) return DL_DIR_SERVICE;
        if (nScheduleWindow == DL_WIN_LATE_SOCIAL)
        {
            if (nSubtype == DL_SUBTYPE_INNKEEPER) return DL_DIR_SERVICE;
            return DL_DIR_SOCIAL;
        }
        if (nScheduleWindow == DL_WIN_SOCIAL) return DL_DIR_SOCIAL;
        return DL_DIR_PUBLIC_PRESENCE;
    }
    if (DL_IsSocialScheduleWindow(nScheduleWindow)) return DL_DIR_SOCIAL;
    return DL_DIR_PUBLIC_PRESENCE;
}

int DL_ApplyOverrideToDirective(object oNPC, int nDirective, int nOverrideKind)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);
    if (nOverrideKind == DL_OVR_FIRE)
    {
        if (nFamily == DL_FAMILY_LAW) return DL_DIR_HOLD_POST;
        return DL_DIR_HIDE_SAFE;
    }
    if (nOverrideKind == DL_OVR_QUARANTINE)
    {
        if (nFamily == DL_FAMILY_LAW)
        {
            if (nSubtype == DL_SUBTYPE_GATE_POST) return DL_DIR_HOLD_POST;
            return DL_DIR_DUTY;
        }
        return DL_DIR_LOCKDOWN_BASE;
    }
    return nDirective;
}

int DL_GetSupportedFallbackDirective(object oNPC)
{
    if (DL_SupportsDirective(oNPC, DL_DIR_SLEEP)) return DL_DIR_SLEEP;
    if (DL_SupportsDirective(oNPC, DL_DIR_SOCIAL)) return DL_DIR_SOCIAL;
    if (DL_SupportsDirective(oNPC, DL_DIR_PUBLIC_PRESENCE)) return DL_DIR_PUBLIC_PRESENCE;
    if (DL_SupportsDirective(oNPC, DL_DIR_ABSENT)) return DL_DIR_ABSENT;
    return DL_DIR_ABSENT;
}

int DL_ResolveDirective(object oNPC, object oArea)
{
    int nDayType = DL_DetermineDayType(oArea);
    int nMinute = DL_GetCurrentMinuteOfDay();
    int nOffset = DL_GetPersonalTimeOffset(oNPC);
    int nTemplate = DL_GetScheduleTemplate(oNPC);
    int nWindow = DL_DetermineScheduleWindow(nTemplate, nDayType, nMinute, nOffset);
    int nDirective = DL_ResolveDirectiveFromSchedule(oNPC, nWindow, nDayType);
    int nOverrideKind = DL_GetTopOverride(oNPC, oArea);
    nDirective = DL_ApplyOverrideToDirective(oNPC, nDirective, nOverrideKind);
    if (!DL_SupportsDirective(oNPC, nDirective)) return DL_GetSupportedFallbackDirective(oNPC);
    return nDirective;
}

int DL_ResolveAnchorGroup(object oNPC, int nDirective)
{
    if (nDirective == DL_DIR_SLEEP) return DL_AG_SLEEP;
    if (nDirective == DL_DIR_WORK) return DL_AG_WORK;
    if (nDirective == DL_DIR_SERVICE) return DL_AG_SERVICE;
    if (nDirective == DL_DIR_SOCIAL) return DL_AG_SOCIAL;
    if (nDirective == DL_DIR_DUTY)
    {
        if (DL_GetNpcSubtype(oNPC) == DL_SUBTYPE_PATROL) return DL_AG_PATROL_POINT;
        return DL_AG_DUTY;
    }
    if (nDirective == DL_DIR_HOLD_POST) return DL_AG_GATE;
    if (nDirective == DL_DIR_LOCKDOWN_BASE || nDirective == DL_DIR_HIDE_SAFE) return DL_AG_HIDE;
    if (nDirective == DL_DIR_PUBLIC_PRESENCE) return DL_AG_STREET_NEAR_BASE;
    return DL_AG_NONE;
}

int DL_ResolveDialogueMode(object oNPC, int nDirective, int nOverrideKind)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);
    if (nOverrideKind == DL_OVR_FIRE)
    {
        if (nFamily == DL_FAMILY_LAW && DL_IsDutyDirective(nDirective))
        {
            return DL_DLG_INSPECTION;
        }
        return DL_DLG_HIDE;
    }
    if (DL_IsWorkOrServiceDirective(nDirective)) return DL_DLG_WORK;
    if (DL_IsDutyDirective(nDirective))
    {
        if (nFamily == DL_FAMILY_LAW || nSubtype == DL_SUBTYPE_INSPECTION || nSubtype == DL_SUBTYPE_GATE_POST)
        {
            return DL_DLG_INSPECTION;
        }
        return DL_DLG_OFF_DUTY;
    }
    if (nDirective == DL_DIR_LOCKDOWN_BASE) return DL_DLG_LOCKDOWN;
    if (nDirective == DL_DIR_HIDE_SAFE) return DL_DLG_HIDE;
    if (DL_IsUnavailableDirective(nDirective)) return DL_DLG_UNAVAILABLE;
    return DL_DLG_OFF_DUTY;
}

int DL_ResolveServiceMode(object oNPC, int nDirective, int nOverrideKind)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    if (DL_ShouldDisableService(oNPC, nOverrideKind)) return DL_SERVICE_DISABLED;
    if (DL_IsUnavailableDirective(nDirective)) return DL_SERVICE_NONE;
    if (nFamily == DL_FAMILY_TRADE_SERVICE && nDirective == DL_DIR_SERVICE) return DL_SERVICE_AVAILABLE;
    if (nFamily == DL_FAMILY_CRAFT && nDirective == DL_DIR_WORK) return DL_SERVICE_LIMITED;
    return DL_SERVICE_DISABLED;
}

void DL_SetDialogueMode(object oNPC, int nDialogueMode)
{
    SetLocalInt(oNPC, DL_L_DIALOGUE_MODE, nDialogueMode);
}

void DL_SetServiceMode(object oNPC, int nServiceMode)
{
    SetLocalInt(oNPC, DL_L_SERVICE_MODE, nServiceMode);
}

void DL_ApplyResolvedInteractionState(object oNPC, int nDirective, int nAnchorGroup, int nDialogueMode, int nServiceMode)
{
    SetLocalInt(oNPC, DL_L_DIRECTIVE, nDirective);
    SetLocalInt(oNPC, DL_L_ANCHOR_GROUP, nAnchorGroup);
    DL_SetDialogueMode(oNPC, nDialogueMode);
    DL_SetServiceMode(oNPC, nServiceMode);
}

void DL_RefreshInteractionState(object oNPC, object oArea)
{
    int nDirective = DL_ResolveDirective(oNPC, oArea);
    int nOverride = DL_GetTopOverride(oNPC, oArea);
    DL_ApplyResolvedInteractionState(
        oNPC,
        nDirective,
        DL_ResolveAnchorGroup(oNPC, nDirective),
        DL_ResolveDialogueMode(oNPC, nDirective, nOverride),
        DL_ResolveServiceMode(oNPC, nDirective, nOverride)
    );
}

void DL_SetInteractionStateExplicit(object oNPC, int nDirective, int nDialogueMode, int nServiceMode)
{
    DL_ApplyResolvedInteractionState(
        oNPC,
        nDirective,
        DL_ResolveAnchorGroup(oNPC, nDirective),
        nDialogueMode,
        nServiceMode
    );
}

int DL_IsAnchorContextAllowed(object oNPC, object oPoint)
{
    if (!GetIsObjectValid(oPoint) || !GetIsObjectValid(oNPC)) return FALSE;
    return GetArea(oNPC) == GetArea(oPoint);
}

object DL_FindAnchorByTag(object oArea, string sTag)
{
    object oObj;
    int nObjType;
    if (!GetIsObjectValid(oArea) || sTag == "") return OBJECT_INVALID;
    oObj = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObj))
    {
        nObjType = GetObjectType(oObj);
        if (DL_IsAnchorMarkerType(nObjType) && GetTag(oObj) == sTag)
        {
            return oObj;
        }
        oObj = GetNextObjectInArea(oArea);
    }
    return OBJECT_INVALID;
}

object DL_FindFallbackAnchorPoint(object oNPC, object oArea, int nAnchorGroup)
{
    object oBase = DL_GetNpcBase(oNPC);
    object oPoint;
    if (DL_IsAreaAnchor(oBase, oArea) && DL_IsAnchorContextAllowed(oNPC, oBase)) return oBase;
    oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, DL_AG_WAIT, 1));
    if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint)) return oPoint;
    oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, 1));
    if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint)) return oPoint;
    return OBJECT_INVALID;
}

object DL_FindFallbackAnchorPointIgnoringPolicy(object oNPC, object oArea, int nAnchorGroup)
{
    object oBase = DL_GetNpcBase(oNPC);
    object oPoint;
    if (DL_IsAreaAnchor(oBase, oArea)) return oBase;
    oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, DL_AG_WAIT, 1));
    if (GetIsObjectValid(oPoint)) return oPoint;
    oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, 1));
    if (GetIsObjectValid(oPoint)) return oPoint;
    return OBJECT_INVALID;
}

object DL_FindAnchorPoint(object oNPC, object oArea, int nAnchorGroup)
{
    int i = 1;
    object oPoint;
    while (i <= DL_ANCHOR_SEARCH_MAX_INDEX)
    {
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetBaseAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint) && DL_IsAnchorContextAllowed(oNPC, oPoint)) return oPoint;
        i += 1;
    }
    return DL_FindFallbackAnchorPoint(oNPC, oArea, nAnchorGroup);
}

object DL_FindAnchorPointIgnoringPolicy(object oNPC, object oArea, int nAnchorGroup)
{
    int i = 1;
    object oPoint;
    while (i <= DL_ANCHOR_SEARCH_MAX_INDEX)
    {
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetBaseAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetSpecializedAnchorTagCandidate(oNPC, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nAnchorGroup, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        i += 1;
    }
    return DL_FindFallbackAnchorPointIgnoringPolicy(oNPC, oArea, nAnchorGroup);
}

int DL_ResolveActivityKind(object oNPC, int nDirective, int nAnchorGroup)
{
    if (nDirective == DL_DIR_SLEEP) return DL_ACT_SLEEP;
    if (nDirective == DL_DIR_WORK) return DL_ACT_WORK;
    if (nDirective == DL_DIR_SERVICE) return DL_ACT_SERVICE_IDLE;
    if (nDirective == DL_DIR_SOCIAL || nAnchorGroup == DL_AG_SOCIAL) return DL_ACT_SOCIAL;
    if (nDirective == DL_DIR_DUTY || nDirective == DL_DIR_HOLD_POST) return DL_ACT_DUTY_IDLE;
    if (nDirective == DL_DIR_HIDE_SAFE || nDirective == DL_DIR_LOCKDOWN_BASE) return DL_ACT_HIDE;
    return DL_ACT_NONE;
}

void DL_ApplyActivity(object oNPC, int nActivityKind)
{
    SetLocalInt(oNPC, DL_L_ACTIVITY_KIND, nActivityKind);
}

void DL_ApplyActivityAndMove(object oNPC, int nActivityKind, object oPoint)
{
    DL_ApplyActivity(oNPC, nActivityKind);
    AssignCommand(oNPC, ClearAllActions());
    if (GetIsObjectValid(oPoint)) AssignCommand(oNPC, ActionMoveToObject(oPoint, TRUE));
}

const int DL_SLOT_REVIEW_TTL_SECONDS = 60;

string DL_MakeSlotProfileKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_profile_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotReviewKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_review_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotReviewInitKey(string sFunctionSlotId)
{
    return DL_MakeSlotReviewKey(sFunctionSlotId, "initialized");
}

int DL_GetCurrentSlotReviewTick()
{
    return (GetTimeHour() * 3600) + (GetTimeMinute() * 60) + GetTimeSecond();
}

string DL_MakeBaseLostNpcKey(object oNPC, string sField)
{
    return "dl_base_lost_npc_" + ObjectToString(oNPC) + "_" + sField;
}

string DL_MakeBaseLostSlotKey(string sFunctionSlotId, string sField)
{
    return "dl_base_lost_slot_" + sFunctionSlotId + "_" + sField;
}

string DL_MakeSlotAssignedNpcKey(object oNPC, string sField)
{
    return "dl_slot_assigned_npc_" + ObjectToString(oNPC) + "_" + sField;
}

string DL_MakeSlotAssignedSlotKey(string sFunctionSlotId, string sField)
{
    return "dl_slot_assigned_slot_" + sFunctionSlotId + "_" + sField;
}

void DL_RecordSlotAssignedBootstrap(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    string sNpcSlotKey;
    string sSlotNpcKey;
    if (!GetIsObjectValid(oNPC) || sFunctionSlotId == "") return;
    sNpcSlotKey = DL_MakeSlotAssignedNpcKey(oNPC, "slot");
    sSlotNpcKey = DL_MakeSlotAssignedSlotKey(sFunctionSlotId, "npc");
    SetLocalString(oModule, sNpcSlotKey, sFunctionSlotId);
    SetLocalObject(oModule, sSlotNpcKey, oNPC);
}

void DL_ClearSlotAssignedBootstrapForNpcOrSlot(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    if (GetIsObjectValid(oNPC))
    {
        DeleteLocalString(oModule, DL_MakeSlotAssignedNpcKey(oNPC, "slot"));
    }
    if (sFunctionSlotId != "")
    {
        DeleteLocalObject(oModule, DL_MakeSlotAssignedSlotKey(sFunctionSlotId, "npc"));
    }
}

string DL_GetSlotAssignedBootstrapSlotForNpc(object oNPC)
{
    if (!GetIsObjectValid(oNPC)) return "";
    return GetLocalString(GetModule(), DL_MakeSlotAssignedNpcKey(oNPC, "slot"));
}

object DL_GetSlotAssignedBootstrapNpcForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "") return OBJECT_INVALID;
    return GetLocalObject(GetModule(), DL_MakeSlotAssignedSlotKey(sFunctionSlotId, "npc"));
}

void DL_StageFunctionSlotProfile(string sFunctionSlotId, int nFamily, int nSubtype, int nSchedule, object oBase)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;
    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot profile stage ignored: empty function slot id");
        return;
    }
    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");
    SetLocalInt(oModule, sFamilyKey, nFamily);
    SetLocalInt(oModule, sSubtypeKey, nSubtype);
    SetLocalInt(oModule, sScheduleKey, nSchedule);
    SetLocalObject(oModule, sBaseKey, oBase);
}

void DL_ClearFunctionSlotProfile(string sFunctionSlotId)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;
    if (sFunctionSlotId == "") return;
    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");
    DeleteLocalInt(oModule, sFamilyKey);
    DeleteLocalInt(oModule, sSubtypeKey);
    DeleteLocalInt(oModule, sScheduleKey);
    DeleteLocalObject(oModule, sBaseKey);
}

int DL_HasStagedFunctionSlotProfile(string sFunctionSlotId)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;
    if (sFunctionSlotId == "") return FALSE;
    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");
    if (GetLocalInt(oModule, sFamilyKey) > DL_FAMILY_NONE) return TRUE;
    if (GetLocalInt(oModule, sSubtypeKey) > DL_SUBTYPE_NONE) return TRUE;
    if (GetLocalInt(oModule, sScheduleKey) > DL_SCH_NONE) return TRUE;
    if (GetIsObjectValid(GetLocalObject(oModule, sBaseKey))) return TRUE;
    return FALSE;
}

int DL_NormalizeSlotReviewReason(int nReason)
{
    if (nReason == DL_RESYNC_BASE_LOST || nReason == DL_RESYNC_SLOT_ASSIGNED) return nReason;
    return DL_RESYNC_BASE_LOST;
}

void DL_RecordBaseLostEvent(object oNPC, string sFunctionSlotId, int nDirective)
{
    object oModule = GetModule();
    string sNpcSlotKey = DL_MakeBaseLostNpcKey(oNPC, "slot");
    string sNpcKindKey = DL_MakeBaseLostNpcKey(oNPC, "kind");
    // Per-NPC/per-slot keys are transient; cleanup paths must call DL_ClearBaseLostEventForNpcOrSlot.
    SetLocalString(oModule, sNpcSlotKey, sFunctionSlotId);
    SetLocalInt(oModule, sNpcKindKey, nDirective);
    if (sFunctionSlotId != "")
    {
        string sSlotNpcKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc");
        string sSlotKindKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind");
        SetLocalObject(oModule, sSlotNpcKey, oNPC);
        SetLocalInt(oModule, sSlotKindKey, nDirective);
    }
    SetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT, sFunctionSlotId);
    SetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC, oNPC);
    SetLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND, nDirective);
}

void DL_ClearBaseLostEventForNpcOrSlot(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    string sNpcSlotKey = DL_MakeBaseLostNpcKey(oNPC, "slot");
    string sNpcKindKey = DL_MakeBaseLostNpcKey(oNPC, "kind");
    DeleteLocalString(oModule, sNpcSlotKey);
    DeleteLocalInt(oModule, sNpcKindKey);
    if (sFunctionSlotId != "")
    {
        string sSlotNpcKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc");
        string sSlotKindKey = DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind");
        DeleteLocalObject(oModule, sSlotNpcKey);
        DeleteLocalInt(oModule, sSlotKindKey);
    }
}

string DL_GetBaseLostSlotForNpc(object oNPC)
{
    return GetLocalString(GetModule(), DL_MakeBaseLostNpcKey(oNPC, "slot"));
}

int DL_GetBaseLostKindForNpc(object oNPC)
{
    return GetLocalInt(GetModule(), DL_MakeBaseLostNpcKey(oNPC, "kind"));
}

object DL_GetBaseLostNpcForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "") return OBJECT_INVALID;
    return GetLocalObject(GetModule(), DL_MakeBaseLostSlotKey(sFunctionSlotId, "npc"));
}

int DL_GetBaseLostKindForSlot(string sFunctionSlotId)
{
    if (sFunctionSlotId == "") return DL_DIR_NONE;
    return GetLocalInt(GetModule(), DL_MakeBaseLostSlotKey(sFunctionSlotId, "kind"));
}

void DL_ApplyAssignedSlotProfile(object oNPC, string sFunctionSlotId)
{
    object oModule = GetModule();
    string sFamilyKey;
    string sSubtypeKey;
    string sScheduleKey;
    string sBaseKey;
    int nFamily;
    int nSubtype;
    int nSchedule;
    object oBase;
    sFamilyKey = DL_MakeSlotProfileKey(sFunctionSlotId, "family");
    sSubtypeKey = DL_MakeSlotProfileKey(sFunctionSlotId, "subtype");
    sScheduleKey = DL_MakeSlotProfileKey(sFunctionSlotId, "schedule");
    sBaseKey = DL_MakeSlotProfileKey(sFunctionSlotId, "base");
    nFamily = GetLocalInt(oModule, sFamilyKey);
    nSubtype = GetLocalInt(oModule, sSubtypeKey);
    nSchedule = GetLocalInt(oModule, sScheduleKey);
    oBase = GetLocalObject(oModule, sBaseKey);
    if (nFamily > DL_FAMILY_NONE) SetLocalInt(oNPC, DL_L_NPC_FAMILY, nFamily);
    if (nSubtype > DL_SUBTYPE_NONE) SetLocalInt(oNPC, DL_L_NPC_SUBTYPE, nSubtype);
    if (nSchedule > DL_SCH_NONE) SetLocalInt(oNPC, DL_L_SCHEDULE_TEMPLATE, nSchedule);
    if (GetIsObjectValid(oBase))
    {
        SetLocalObject(oNPC, DL_L_NPC_BASE, oBase);
    }
    else
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "Slot profile base ignored: invalid base object for slot " + sFunctionSlotId);
    }
}

void DL_RequestAssignedNpcResync(object oNPC)
{
    int nCurrentReason;
    int nRequestedReason;
    int nSelectedReason;

    if (!GetIsObjectValid(oNPC)) return;

    nCurrentReason = DL_NormalizeResyncReason(GetLocalInt(oNPC, DL_L_RESYNC_REASON));
    nRequestedReason = DL_NormalizeResyncReason(DL_RESYNC_SLOT_ASSIGNED);
    nSelectedReason = DL_SelectStrongerResyncReason(nCurrentReason, nRequestedReason);

    SetLocalInt(oNPC, DL_L_RESYNC_PENDING, TRUE);
    if (nSelectedReason != nCurrentReason)
    {
        SetLocalInt(oNPC, DL_L_RESYNC_REASON, nSelectedReason);
    }
}

void DL_ClearFunctionSlotReviewState(object oModule, string sFunctionSlotId)
{
    string sLastTickKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick");
    string sLastTickSetKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick_set");
    string sLastReasonKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason");
    string sAttemptsKey = DL_MakeSlotReviewKey(sFunctionSlotId, "attempts");
    string sInitializedKey = DL_MakeSlotReviewInitKey(sFunctionSlotId);
    DeleteLocalInt(oModule, sLastTickKey);
    DeleteLocalInt(oModule, sLastTickSetKey);
    DeleteLocalInt(oModule, sLastReasonKey);
    DeleteLocalInt(oModule, sAttemptsKey);
    DeleteLocalInt(oModule, sInitializedKey);
}

void DL_RequestFunctionSlotReview(string sFunctionSlotId, int nReason)
{
    object oModule = GetModule();
    string sLastTickKey;
    string sLastTickSetKey;
    string sLastReasonKey;
    string sAttemptsKey;
    string sInitializedKey;
    int nNowTick;
    int nLastTick;
    int bHasLastTick;
    int nElapsed;
    int nLastReason;
    int nAttemptCount;
    int bInitialized;
    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot review requested with empty function slot id");
        return;
    }
    sLastTickKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick");
    sLastTickSetKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_tick_set");
    sLastReasonKey = DL_MakeSlotReviewKey(sFunctionSlotId, "last_reason");
    sAttemptsKey = DL_MakeSlotReviewKey(sFunctionSlotId, "attempts");
    sInitializedKey = DL_MakeSlotReviewInitKey(sFunctionSlotId);
    nReason = DL_NormalizeSlotReviewReason(nReason);
    nNowTick = DL_GetCurrentSlotReviewTick();
    bInitialized = GetLocalInt(oModule, sInitializedKey);
    nLastTick = GetLocalInt(oModule, sLastTickKey);
    nLastReason = GetLocalInt(oModule, sLastReasonKey);
    nAttemptCount = GetLocalInt(oModule, sAttemptsKey) + 1;
    nElapsed = nNowTick - nLastTick;
    if (nElapsed < 0) nElapsed += 86400;
    SetLocalInt(oModule, sAttemptsKey, nAttemptCount);
    if (bInitialized && nLastReason == nReason && nElapsed >= 0 && nElapsed < DL_SLOT_REVIEW_TTL_SECONDS)
    {
        DL_Log(DL_DEBUG_VERBOSE, "Slot review deduplicated: " + sFunctionSlotId + ", reason=" + IntToString(nReason) + ", attempts=" + IntToString(nAttemptCount) + ", elapsed=" + IntToString(nElapsed) + ", ttl=" + IntToString(DL_SLOT_REVIEW_TTL_SECONDS));
        return;
    }
    if (bInitialized && nLastReason == nReason && nElapsed >= DL_SLOT_REVIEW_TTL_SECONDS)
    {
        DL_Log(DL_DEBUG_BASIC, "Slot review re-requested after ttl: " + sFunctionSlotId + ", reason=" + IntToString(nReason) + ", attempts=" + IntToString(nAttemptCount) + ", elapsed=" + IntToString(nElapsed) + ", ttl=" + IntToString(DL_SLOT_REVIEW_TTL_SECONDS));
    }
    SetLocalString(oModule, DL_L_LAST_SLOT_REVIEW, sFunctionSlotId);
    SetLocalInt(oModule, DL_L_LAST_SLOT_REVIEW_REASON, nReason);
    SetLocalInt(oModule, sLastTickSetKey, TRUE);
    SetLocalInt(oModule, sLastTickKey, nNowTick);
    SetLocalInt(oModule, sLastReasonKey, nReason);
    SetLocalInt(oModule, sInitializedKey, TRUE);
    DL_Log(DL_DEBUG_BASIC, "Slot review requested: " + sFunctionSlotId + ", reason=" + IntToString(nReason) + ", attempts=" + IntToString(nAttemptCount));
}

void DL_OnFunctionSlotAssigned(string sFunctionSlotId, object oNPC)
{
    object oModule = GetModule();
    if (sFunctionSlotId == "")
    {
        DL_Log(DL_DEBUG_BASIC, "Slot assigned callback ignored: empty function slot id");
        return;
    }
    SetLocalString(oModule, DL_L_LAST_SLOT_ASSIGNED, sFunctionSlotId);
    SetLocalInt(oModule, DL_L_LAST_SLOT_ASSIGNED_REASON, DL_RESYNC_SLOT_ASSIGNED);
    SetLocalObject(oModule, DL_L_SLOT_ASSIGNED_NPC, oNPC);
    if (GetLocalString(oModule, DL_L_LAST_SLOT_REVIEW) == sFunctionSlotId)
    {
        DeleteLocalString(oModule, DL_L_LAST_SLOT_REVIEW);
        DeleteLocalInt(oModule, DL_L_LAST_SLOT_REVIEW_REASON);
    }
    DL_ClearFunctionSlotReviewState(oModule, sFunctionSlotId);
    if (GetIsObjectValid(oNPC))
    {
        // Persist pending slot directly on NPC so bootstrap does not depend on module-wide buffers.
        SetLocalString(oNPC, DL_L_PENDING_SLOT_ID, sFunctionSlotId);
        SetLocalString(oNPC, DL_L_FUNCTION_SLOT_ID, sFunctionSlotId);
        DL_RecordSlotAssignedBootstrap(oNPC, sFunctionSlotId);

        DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);
        DL_ClearFunctionSlotProfile(sFunctionSlotId);
        DL_RequestAssignedNpcResync(oNPC);
    }
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "Slot assigned: " + sFunctionSlotId);
}

const string DL_L_CONV_STORE_OBJECT = "dl_conv_store_object";
const string DL_L_CONV_STORE_TAG = "dl_conv_store_tag";
const string DL_L_CONV_STORE_AREA_TAGS = "dl_conv_store_area_tags";
const string DL_L_CONV_STORE_MARKUP = "dl_conv_store_markup";
const string DL_L_CONV_STORE_MARKDOWN = "dl_conv_store_markdown";

int DL_ShouldSkipConversationPrepare(object oNPC)
{
    int nDirective;
    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC)) return TRUE;
    nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    return nDirective == DL_DIR_ABSENT || nDirective == DL_DIR_UNASSIGNED;
}

int DL_PrepareConversationState(object oNPC)
{
    object oArea;
    if (DL_ShouldSkipConversationPrepare(oNPC)) return FALSE;
    oArea = GetArea(oNPC);
    if (!GetIsObjectValid(oArea)) return FALSE;
    DL_RefreshInteractionState(oNPC, oArea);
    return TRUE;
}

void DL_FinalizeConversationState(object oNPC)
{
    if (DL_ShouldSkipConversationPrepare(oNPC)) return;
    if (GetIsObjectValid(GetArea(oNPC))) DL_RefreshInteractionState(oNPC, GetArea(oNPC));
}

int DL_IsConversationAvailable(object oNPC)
{
    int nDirective;
    if (!DL_IsValidCreature(oNPC)) return FALSE;
    if (!DL_IsDailyLifeNpc(oNPC)) return TRUE;
    nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    return nDirective != DL_DIR_ABSENT && nDirective != DL_DIR_UNASSIGNED;
}

int DL_HasDialogueMode(object oNPC, int nDialogueMode)
{
    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC)) return FALSE;
    return GetLocalInt(oNPC, DL_L_DIALOGUE_MODE) == nDialogueMode;
}

int DL_HasServiceMode(object oNPC, int nServiceMode)
{
    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC)) return FALSE;
    return GetLocalInt(oNPC, DL_L_SERVICE_MODE) == nServiceMode;
}

int DL_CanOpenConversationStore(object oNPC)
{
    int nServiceMode;
    if (!DL_IsValidCreature(oNPC) || !DL_IsDailyLifeNpc(oNPC)) return FALSE;
    nServiceMode = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    return nServiceMode == DL_SERVICE_AVAILABLE || nServiceMode == DL_SERVICE_LIMITED;
}

int DL_IsConversationStoreCandidate(object oStore, string sStoreTag)
{
    if (!GetIsObjectValid(oStore)) return FALSE;
    if (GetObjectType(oStore) != OBJECT_TYPE_STORE) return FALSE;
    return GetTag(oStore) == sStoreTag;
}

int DL_IsConversationStoreSearchArea(object oArea)
{
    // OBJECT_TYPE_AREA is not available in the legacy NWN2 compiler constant set.
    return GetIsObjectValid(oArea);
}

void DL_LogConversationStoreAreaConflict(object oNPC, object oArea, string sStoreTag)
{
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "conversation store tag conflict in area: area_tag=" + GetTag(oArea) + ", store_tag=" + sStoreTag);
}

void DL_LogConversationStoreSearchConflict(object oNPC, string sStoreTag)
{
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "conversation store tag conflict across search context: store_tag=" + sStoreTag);
}

void DL_LogConversationStoreCacheTagMismatch(object oNPC, object oStore, string sStoreTag)
{
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "conversation store cache rejected due to tag mismatch: expected_tag=" + sStoreTag + ", cached_store_tag=" + GetTag(oStore));
}

int DL_CountConversationStoresInArea(object oArea, string sStoreTag)
{
    object oObject;
    int nMatchCount = 0;
    if (!DL_IsConversationStoreSearchArea(oArea)) return 0;
    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsConversationStoreCandidate(oObject, sStoreTag)) nMatchCount += 1;
        oObject = GetNextObjectInArea(oArea);
    }
    return nMatchCount;
}

object DL_FindConversationStoreInArea(object oArea, string sStoreTag)
{
    object oObject;
    if (!DL_IsConversationStoreSearchArea(oArea)) return OBJECT_INVALID;
    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsConversationStoreCandidate(oObject, sStoreTag)) return oObject;
        oObject = GetNextObjectInArea(oArea);
    }
    return OBJECT_INVALID;
}

object DL_GetConversationStore(object oNPC)
{
    object oStore = GetLocalObject(oNPC, DL_L_CONV_STORE_OBJECT);
    object oArea;
    object oNpcArea;
    object oCandidate;
    string sAreaTags;
    string sStoreTag;
    string sAreaTag;
    int nOffset = 0;
    int nSepPos;
    int nListLen;
    int nAreaIndex;
    int nAreaMatches;
    int nTotalMatches = 0;
    sStoreTag = GetLocalString(oNPC, DL_L_CONV_STORE_TAG);
    if (sStoreTag == "") return OBJECT_INVALID;
    if (DL_IsConversationStoreCandidate(oStore, sStoreTag)) return oStore;
    if (GetIsObjectValid(oStore) && GetObjectType(oStore) == OBJECT_TYPE_STORE)
    {
        DL_LogConversationStoreCacheTagMismatch(oNPC, oStore, sStoreTag);
    }
    oNpcArea = GetArea(oNPC);
    nAreaMatches = DL_CountConversationStoresInArea(oNpcArea, sStoreTag);
    if (nAreaMatches > 1)
    {
        DL_LogConversationStoreAreaConflict(oNPC, oNpcArea, sStoreTag);
        return OBJECT_INVALID;
    }
    if (nAreaMatches == 1)
    {
        oCandidate = DL_FindConversationStoreInArea(oNpcArea, sStoreTag);
        nTotalMatches += 1;
    }
    sAreaTags = GetLocalString(oNPC, DL_L_CONV_STORE_AREA_TAGS);
    nListLen = GetStringLength(sAreaTags);
    while (nOffset < nListLen)
    {
        nSepPos = FindSubString(sAreaTags, ";", nOffset);
        if (nSepPos < 0)
        {
            sAreaTag = GetSubString(sAreaTags, nOffset, nListLen - nOffset);
            nOffset = nListLen;
        }
        else
        {
            sAreaTag = GetSubString(sAreaTags, nOffset, nSepPos - nOffset);
            nOffset = nSepPos + 1;
        }
        if (sAreaTag == "") continue;
        nAreaIndex = 0;
        oArea = GetObjectByTag(sAreaTag, nAreaIndex);
        while (GetIsObjectValid(oArea))
        {
            if (oArea == oNpcArea)
            {
                nAreaIndex += 1;
                oArea = GetObjectByTag(sAreaTag, nAreaIndex);
                continue;
            }
            if (DL_IsConversationStoreSearchArea(oArea))
            {
                nAreaMatches = DL_CountConversationStoresInArea(oArea, sStoreTag);
                if (nAreaMatches > 1)
                {
                    DL_LogConversationStoreAreaConflict(oNPC, oArea, sStoreTag);
                    return OBJECT_INVALID;
                }
                if (nAreaMatches == 1)
                {
                    oCandidate = DL_FindConversationStoreInArea(oArea, sStoreTag);
                    nTotalMatches += 1;
                }
            }
            nAreaIndex += 1;
            oArea = GetObjectByTag(sAreaTag, nAreaIndex);
        }
    }
    if (nTotalMatches > 1)
    {
        DL_LogConversationStoreSearchConflict(oNPC, sStoreTag);
        return OBJECT_INVALID;
    }
    if (nTotalMatches == 1 && GetIsObjectValid(oCandidate)) return oCandidate;
    return OBJECT_INVALID;
}

int DL_OpenConversationStore(object oNPC, object oPC)
{
    object oStore;
    int nMarkup;
    int nMarkdown;
    string sStoreTag;
    string sResolvedStoreTag;
    if (!GetIsObjectValid(oPC) || !DL_CanOpenConversationStore(oNPC)) return FALSE;
    oStore = DL_GetConversationStore(oNPC);
    sStoreTag = GetLocalString(oNPC, DL_L_CONV_STORE_TAG);
    if (!GetIsObjectValid(oStore))
    {
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "conversation store missing or invalid");
        return FALSE;
    }
    sResolvedStoreTag = GetTag(oStore);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "open conversation store: npc_tag=" + GetTag(oNPC) + ", store_tag=" + sStoreTag + ", resolved_store_tag=" + sResolvedStoreTag);
    nMarkup = GetLocalInt(oNPC, DL_L_CONV_STORE_MARKUP);
    nMarkdown = GetLocalInt(oNPC, DL_L_CONV_STORE_MARKDOWN);
    OpenStore(oStore, oPC, nMarkup, nMarkdown);
    return TRUE;
}

int DL_ShouldInstantPlace(object oNPC, object oArea, object oPoint)
{
    if (!GetIsObjectValid(oPoint)) return FALSE;
    if (GetArea(oNPC) != GetArea(oPoint)) return TRUE;
    if (DL_IsAreaHot(oArea)) return GetDistanceBetween(oNPC, oPoint) > 20.0;
    return TRUE;
}

void DL_ApplyInstantPlacement(object oNPC, object oPoint)
{
    if (!GetIsObjectValid(oPoint)) return;
    AssignCommand(oNPC, ClearAllActions());
    AssignCommand(oNPC, ActionJumpToObject(oPoint));
}

void DL_ApplyLocalWalk(object oNPC, object oPoint)
{
    if (!GetIsObjectValid(oPoint)) return;
    AssignCommand(oNPC, ClearAllActions());
    AssignCommand(oNPC, ActionMoveToObject(oPoint, TRUE));
}

void DL_ApplyPlotModeByDirective(object oNPC, int nDirective)
{
    int bShouldBePlot = (nDirective != DL_DIR_ABSENT);
    int bWasPlot = GetPlotFlag(oNPC);
    if (bWasPlot == bShouldBePlot) return;
    SetPlotFlag(oNPC, bShouldBePlot);
    if (bShouldBePlot) DL_LogNpc(oNPC, DL_DEBUG_BASIC, "plot mode restored");
    else DL_LogNpc(oNPC, DL_DEBUG_BASIC, "plot mode disabled for ABSENT");
}

void DL_ApplyUnavailableInteractionState(object oNPC, int nDirective)
{
    DL_SetInteractionStateExplicit(oNPC, nDirective, DL_DLG_UNAVAILABLE, DL_SERVICE_NONE);
    DL_ApplyPlotModeByDirective(oNPC, nDirective);
}

void DL_HideOrMarkAbsent(object oNPC, int nDirective)
{
    DL_ApplyUnavailableInteractionState(oNPC, nDirective);
}

void DL_HandleUnassignedNpc(object oNPC)
{
    string sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    AssignCommand(oNPC, ClearAllActions());
    SetLocalInt(oNPC, DL_L_ACTIVITY_KIND, DL_ACT_NONE);
    DL_ApplyUnavailableInteractionState(oNPC, DL_DIR_UNASSIGNED);
    DL_RecordBaseLostEvent(oNPC, sFunctionSlotId, DL_DIR_UNASSIGNED);
    if (sFunctionSlotId != "") DL_RequestFunctionSlotReview(sFunctionSlotId, DL_RESYNC_BASE_LOST);
    else DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost without function slot id");
}

int DL_TryRecoverBaseFromFunctionSlot(object oNPC)
{
    string sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (sFunctionSlotId == "") return FALSE;
    if (!DL_HasStagedFunctionSlotProfile(sFunctionSlotId)) return FALSE;
    DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);
    if (!DL_HasBase(oNPC)) return FALSE;
    DL_ClearFunctionSlotProfile(sFunctionSlotId);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base recovered from staged function slot profile: " + sFunctionSlotId);
    return TRUE;
}

int DL_GetPrimaryBaseAnchorGroup(object oNPC)
{
    int nFamily = DL_GetNpcFamily(oNPC);
    if (nFamily == DL_FAMILY_CRAFT) return DL_AG_WORK;
    if (nFamily == DL_FAMILY_TRADE_SERVICE) return DL_AG_SERVICE;
    if (nFamily == DL_FAMILY_LAW) return DL_AG_DUTY;
    return DL_AG_SLEEP;
}

object DL_FindProvisionalBaseAnchor(object oNPC, object oArea)
{
    int i = 1;
    int nPrimaryGroup = DL_GetPrimaryBaseAnchorGroup(oNPC);
    object oPoint;
    while (i <= 4)
    {
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, nPrimaryGroup, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, DL_AG_SLEEP, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        oPoint = DL_FindAnchorByTag(oArea, DL_GetAreaAnchorTagCandidate(oNPC, oArea, DL_AG_WAIT, i));
        if (GetIsObjectValid(oPoint)) return oPoint;
        i += 1;
    }
    return OBJECT_INVALID;
}

int DL_TryAssignProvisionalBase(object oNPC, object oArea)
{
    object oBase;
    if (!GetIsObjectValid(oArea)) return FALSE;
    oBase = DL_FindProvisionalBaseAnchor(oNPC, oArea);
    if (!GetIsObjectValid(oBase)) return FALSE;
    SetLocalObject(oNPC, DL_L_NPC_BASE, oBase);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "provisional base assigned from area anchors: " + GetTag(oBase));
    return TRUE;
}

int DL_HandleBaseLost(object oNPC, object oArea)
{
    string sFunctionSlotId;
    if (DL_HasBase(oNPC)) return FALSE;
    sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (DL_TryRecoverBaseFromFunctionSlot(oNPC))
    {
        object oModule = GetModule();
        object oLastBaseLostNpc = GetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
        string sLastBaseLostSlot = GetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
        DL_ClearBaseLostEventForNpcOrSlot(oNPC, sFunctionSlotId);
        if (oLastBaseLostNpc == oNPC || (sFunctionSlotId != "" && sLastBaseLostSlot == sFunctionSlotId))
        {
            DeleteLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
            DeleteLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
            DeleteLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND);
        }
        return FALSE;
    }
    if (DL_TryAssignProvisionalBase(oNPC, oArea))
    {
        object oModule = GetModule();
        object oLastBaseLostNpc = GetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
        string sLastBaseLostSlot = GetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
        DL_ClearBaseLostEventForNpcOrSlot(oNPC, sFunctionSlotId);
        if (oLastBaseLostNpc == oNPC || (sFunctionSlotId != "" && sLastBaseLostSlot == sFunctionSlotId))
        {
            DeleteLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
            DeleteLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
            DeleteLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND);
        }
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost cleared after provisional recovery");
        return FALSE;
    }
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost, applying handoff fallback");
    if (DL_IsNamed(oNPC) || DL_IsPersistent(oNPC))
    {
        if (sFunctionSlotId != "") DL_RequestFunctionSlotReview(sFunctionSlotId, DL_RESYNC_BASE_LOST);
        DL_ApplyUnavailableInteractionState(oNPC, DL_DIR_ABSENT);
        DL_RecordBaseLostEvent(oNPC, sFunctionSlotId, DL_DIR_ABSENT);
        DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost branch=ABSENT");
        return TRUE;
    }
    DL_HandleUnassignedNpc(oNPC);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "base lost branch=UNASSIGNED");
    return TRUE;
}

void DL_MaterializeNpc(object oNPC, object oArea)
{
    int nDirective;
    int nOverride;
    int nAnchorGroup;
    int nDialogueMode;
    int nServiceMode;
    object oPoint;
    object oPolicyFilteredAnchor;
    if (DL_HandleBaseLost(oNPC, oArea)) return;
    nDirective = DL_ResolveDirective(oNPC, oArea);
    nOverride = DL_GetTopOverride(oNPC, oArea);
    nAnchorGroup = DL_ResolveAnchorGroup(oNPC, nDirective);
    nDialogueMode = DL_ResolveDialogueMode(oNPC, nDirective, nOverride);
    nServiceMode = DL_ResolveServiceMode(oNPC, nDirective, nOverride);
    DL_ApplyResolvedInteractionState(oNPC, nDirective, nAnchorGroup, nDialogueMode, nServiceMode);
    DL_ApplyPlotModeByDirective(oNPC, nDirective);
    if (!DL_IsDirectiveVisible(nDirective) || DL_ShouldSuppressMaterialization(oNPC, nOverride))
    {
        return;
    }
    oPoint = DL_FindAnchorPoint(oNPC, oArea, nAnchorGroup);
    if (!GetIsObjectValid(oPoint))
    {
        oPolicyFilteredAnchor = DL_FindAnchorPointIgnoringPolicy(oNPC, oArea, nAnchorGroup);
        if (GetIsObjectValid(oPolicyFilteredAnchor))
        {
            DL_LogNpc(oNPC, DL_DEBUG_BASIC, "anchor filtered by policy, marking absent: " + GetTag(oPolicyFilteredAnchor));
        }
        else
        {
            DL_LogNpc(oNPC, DL_DEBUG_BASIC, "anchor not found, marking absent");
        }
        DL_ApplyUnavailableInteractionState(oNPC, DL_DIR_ABSENT);
        return;
    }
    if (GetArea(oNPC) != GetArea(oPoint)) DL_LogNpc(oNPC, DL_DEBUG_BASIC, "cross-area jump to anchor: " + GetTag(oPoint));
    if (DL_ShouldInstantPlace(oNPC, oArea, oPoint)) DL_ApplyInstantPlacement(oNPC, oPoint);
    else DL_ApplyLocalWalk(oNPC, oPoint);
    DL_ApplyActivity(oNPC, DL_ResolveActivityKind(oNPC, nDirective, nAnchorGroup));
}

int DL_ShouldResync(object oNPC, int nReason)
{
    if (!DL_IsDailyLifeNpc(oNPC)) return FALSE;
    if (!DL_IsPersistent(oNPC) && !DL_IsNamed(oNPC)) return GetLocalInt(oNPC, DL_L_RESYNC_PENDING) == TRUE;
    return nReason != DL_RESYNC_NONE;
}

int DL_NormalizeResyncReason(int nReason)
{
    if (nReason == DL_RESYNC_NONE) return DL_RESYNC_WORKER;
    return nReason;
}

int DL_GetResyncReasonPriority(int nReason)
{
    if (nReason == DL_RESYNC_BASE_LOST) return 5;
    if (nReason == DL_RESYNC_SLOT_ASSIGNED) return 4;
    if (nReason == DL_RESYNC_OVERRIDE_END || nReason == DL_RESYNC_TIME_JUMP) return 3;
    if (nReason == DL_RESYNC_SAVE_LOAD || nReason == DL_RESYNC_TIER_UP) return 2;
    if (nReason == DL_RESYNC_AREA_ENTER) return 1;
    if (nReason == DL_RESYNC_WORKER) return 0;
    return -1;
}

int DL_SelectStrongerResyncReason(int nCurrentReason, int nRequestedReason)
{
    if (DL_GetResyncReasonPriority(nRequestedReason) >= DL_GetResyncReasonPriority(nCurrentReason)) return nRequestedReason;
    return nCurrentReason;
}

void DL_RequestResyncKnownNpc(object oNPC, int nReason)
{
    int nCurrentReason = DL_NormalizeResyncReason(GetLocalInt(oNPC, DL_L_RESYNC_REASON));
    nReason = DL_NormalizeResyncReason(nReason);
    SetLocalInt(oNPC, DL_L_RESYNC_PENDING, TRUE);
    SetLocalInt(oNPC, DL_L_RESYNC_REASON, DL_SelectStrongerResyncReason(nCurrentReason, nReason));
}

void DL_RequestResync(object oNPC, int nReason)
{
    if (!DL_IsDailyLifeNpc(oNPC)) return;
    DL_RequestResyncKnownNpc(oNPC, nReason);
}

void DL_RequestAreaResync(object oArea, int nReason)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject) && DL_IsDailyLifeNpc(oObject)) DL_RequestResyncKnownNpc(oObject, nReason);
        oObject = GetNextObjectInArea(oArea);
    }
}

void DL_RequestModuleResync(int nReason)
{
    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        DL_RequestAreaResync(oArea, nReason);
        oArea = GetNextArea();
    }
}

void DL_RunResync(object oNPC, object oArea, int nReason)
{
    nReason = DL_NormalizeResyncReason(nReason);
    if (!DL_ShouldResync(oNPC, nReason)) return;
    DL_MaterializeNpc(oNPC, oArea);
    DeleteLocalInt(oNPC, DL_L_RESYNC_PENDING);
    SetLocalInt(oNPC, DL_L_RESYNC_REASON, DL_RESYNC_NONE);
}

void DL_RunForcedResync(object oNPC, object oArea, int nReason)
{
    if (!DL_IsDailyLifeNpc(oNPC)) return;
    DL_RequestResyncKnownNpc(oNPC, nReason);
    DL_RunResync(oNPC, oArea, nReason);
}

const string DL_L_WORKER_CURSOR = "dl_worker_cursor";
const string DL_L_WORKER_CANDIDATE_IDX = "dl_worker_candidate_idx";
const string DL_L_WORKER_IS_CANDIDATE = "dl_worker_is_candidate";

int DL_IsWorkerCreatureObject(object oObject)
{
    return GetObjectType(oObject) == OBJECT_TYPE_CREATURE && !GetIsPC(oObject);
}

void DL_ClearWorkerCandidateMarker(object oNPC)
{
    DeleteLocalInt(oNPC, DL_L_WORKER_CANDIDATE_IDX);
    DeleteLocalInt(oNPC, DL_L_WORKER_IS_CANDIDATE);
}

void DL_ClearAreaWorkerMarkers(object oArea)
{
    object oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsWorkerCreatureObject(oObject))
        {
            DL_ClearWorkerCandidateMarker(oObject);
        }
        oObject = GetNextObjectInArea(oArea);
    }
}

string DL_DescribeResyncReason(int nReason)
{
    if (nReason == DL_RESYNC_AREA_ENTER) return "AREA_ENTER";
    if (nReason == DL_RESYNC_TIER_UP) return "TIER_UP";
    if (nReason == DL_RESYNC_SAVE_LOAD) return "SAVE_LOAD";
    if (nReason == DL_RESYNC_TIME_JUMP) return "TIME_JUMP";
    if (nReason == DL_RESYNC_OVERRIDE_END) return "OVERRIDE_END";
    if (nReason == DL_RESYNC_WORKER) return "WORKER";
    if (nReason == DL_RESYNC_SLOT_ASSIGNED) return "SLOT_ASSIGNED";
    if (nReason == DL_RESYNC_BASE_LOST) return "BASE_LOST";
    return "NONE";
}

string DL_DescribeDirective(int nDirective)
{
    if (nDirective == DL_DIR_SLEEP) return "SLEEP";
    if (nDirective == DL_DIR_WORK) return "WORK";
    if (nDirective == DL_DIR_SERVICE) return "SERVICE";
    if (nDirective == DL_DIR_SOCIAL) return "SOCIAL";
    if (nDirective == DL_DIR_DUTY) return "DUTY";
    if (nDirective == DL_DIR_PUBLIC_PRESENCE) return "PUBLIC_PRESENCE";
    if (nDirective == DL_DIR_HOLD_POST) return "HOLD_POST";
    if (nDirective == DL_DIR_LOCKDOWN_BASE) return "LOCKDOWN_BASE";
    if (nDirective == DL_DIR_HIDE_SAFE) return "HIDE_SAFE";
    if (nDirective == DL_DIR_ABSENT) return "ABSENT";
    if (nDirective == DL_DIR_UNASSIGNED) return "UNASSIGNED";
    return "NONE";
}

string DL_DescribeDialogueMode(int nDialogue)
{
    if (nDialogue == DL_DLG_WORK) return "WORK";
    if (nDialogue == DL_DLG_OFF_DUTY) return "OFF_DUTY";
    if (nDialogue == DL_DLG_INSPECTION) return "INSPECTION";
    if (nDialogue == DL_DLG_LOCKDOWN) return "LOCKDOWN";
    if (nDialogue == DL_DLG_HIDE) return "HIDE";
    if (nDialogue == DL_DLG_UNAVAILABLE) return "UNAVAILABLE";
    return "NONE";
}

string DL_DescribeServiceMode(int nService)
{
    if (nService == DL_SERVICE_AVAILABLE) return "AVAILABLE";
    if (nService == DL_SERVICE_LIMITED) return "LIMITED";
    if (nService == DL_SERVICE_DISABLED) return "DISABLED";
    return "NONE";
}

string DL_DescribeOverride(int nOverride)
{
    if (nOverride == DL_OVR_FIRE) return "FIRE";
    if (nOverride == DL_OVR_QUARANTINE) return "QUARANTINE";
    return "NONE";
}

void DL_LogSmokeSnapshot(object oNPC, object oArea, int nReason)
{
    string sMessage;
    object oModule = GetModule();
    string sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    string sLastBaseLostSlot = DL_GetBaseLostSlotForNpc(oNPC);
    int nLastBaseLostKind = DL_GetBaseLostKindForNpc(oNPC);
    object oLastBaseLostNpc = OBJECT_INVALID;
    int nDirective = GetLocalInt(oNPC, DL_L_DIRECTIVE);
    int nDialogue = GetLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    int nService = GetLocalInt(oNPC, DL_L_SERVICE_MODE);
    int nOverride = DL_GetTopOverride(oNPC, oArea);
    int nFamily = DL_GetNpcFamily(oNPC);
    int nSubtype = DL_GetNpcSubtype(oNPC);
    if (sLastBaseLostSlot == "" && sFunctionSlotId != "")
    {
        sLastBaseLostSlot = sFunctionSlotId;
    }
    if (nLastBaseLostKind == DL_DIR_NONE && sLastBaseLostSlot != "")
    {
        nLastBaseLostKind = DL_GetBaseLostKindForSlot(sLastBaseLostSlot);
    }
    if (sLastBaseLostSlot != "")
    {
        object oSlotNpc = DL_GetBaseLostNpcForSlot(sLastBaseLostSlot);
        if (GetIsObjectValid(oSlotNpc))
        {
            oLastBaseLostNpc = oSlotNpc;
        }
    }
    if (nLastBaseLostKind == DL_DIR_NONE)
    {
        nLastBaseLostKind = GetLocalInt(oModule, DL_L_LAST_BASE_LOST_KIND);
        if (sLastBaseLostSlot == "")
        {
            sLastBaseLostSlot = GetLocalString(oModule, DL_L_LAST_BASE_LOST_SLOT);
        }
        if (!GetIsObjectValid(oLastBaseLostNpc))
        {
            oLastBaseLostNpc = GetLocalObject(oModule, DL_L_LAST_BASE_LOST_NPC);
        }
    }

    sMessage =
        "smoke snapshot"
        + " reason=" + IntToString(nReason) + "(" + DL_DescribeResyncReason(nReason) + ")"
        + " family=" + IntToString(nFamily)
        + " subtype=" + IntToString(nSubtype)
        + " directive=" + IntToString(nDirective) + "(" + DL_DescribeDirective(nDirective) + ")"
        + " dialogue=" + IntToString(nDialogue) + "(" + DL_DescribeDialogueMode(nDialogue) + ")"
        + " service=" + IntToString(nService) + "(" + DL_DescribeServiceMode(nService) + ")"
        + " override=" + IntToString(nOverride) + "(" + DL_DescribeOverride(nOverride) + ")"
        + " base_lost_kind=" + IntToString(nLastBaseLostKind) + "(" + DL_DescribeDirective(nLastBaseLostKind) + ")"
        + " base_lost_slot=" + sLastBaseLostSlot;

    if (GetIsObjectValid(oLastBaseLostNpc) && oLastBaseLostNpc == oNPC)
    {
        sMessage = sMessage + " base_lost_npc=SELF";
    }
    else if (!GetIsObjectValid(oLastBaseLostNpc))
    {
        sMessage = sMessage + " base_lost_npc=UNKNOWN";
    }

    DL_LogNpc(oNPC, DL_DEBUG_BASIC, sMessage);
}

int DL_GetWorkerBudget(object oArea)
{
    return DL_GetDefaultAreaTierBudget(DL_GetAreaTier(oArea));
}

int DL_ShouldProcessNpcInWorker(object oNPC)
{
    if (!DL_IsDailyLifeNpc(oNPC))
    {
        return FALSE;
    }
    if (GetLocalInt(oNPC, DL_L_RESYNC_PENDING) == TRUE)
    {
        return TRUE;
    }
    return DL_IsPersistent(oNPC) || DL_IsNamed(oNPC);
}

void DL_ProcessNpcBudgeted(object oArea, object oNPC)
{
    int nReason = GetLocalInt(oNPC, DL_L_RESYNC_REASON);
    if (nReason == DL_RESYNC_NONE)
    {
        nReason = DL_RESYNC_WORKER;
    }
    DL_RunResync(oNPC, oArea, nReason);
    if (GetLocalInt(GetModule(), DL_L_SMOKE_TRACE) == TRUE)
    {
        DL_LogSmokeSnapshot(oNPC, oArea, nReason);
    }
}

void DL_DispatchDueJobs(object oArea, int nBudget)
{
    object oObject;
    int nCandidateCount = 0;
    int nCursor = 0;
    int nPlanned = 0;
    int nProcessed = 0;

    if (nBudget <= 0)
    {
        DL_ClearAreaWorkerMarkers(oArea);
        SetLocalInt(oArea, DL_L_WORKER_CURSOR, 0);
        return;
    }

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsWorkerCreatureObject(oObject))
        {
            if (DL_ShouldProcessNpcInWorker(oObject))
            {
                SetLocalInt(oObject, DL_L_WORKER_CANDIDATE_IDX, nCandidateCount);
                SetLocalInt(oObject, DL_L_WORKER_IS_CANDIDATE, TRUE);
                nCandidateCount += 1;
            }
            else
            {
                DL_ClearWorkerCandidateMarker(oObject);
            }
        }
        oObject = GetNextObjectInArea(oArea);
    }

    if (nCandidateCount <= 0)
    {
        SetLocalInt(oArea, DL_L_WORKER_CURSOR, 0);
        return;
    }

    nCursor = GetLocalInt(oArea, DL_L_WORKER_CURSOR) % nCandidateCount;
    if (nCursor < 0)
    {
        nCursor += nCandidateCount;
    }

    nPlanned = nBudget;
    if (nPlanned > nCandidateCount)
    {
        nPlanned = nCandidateCount;
    }

    DL_Log(DL_DEBUG_VERBOSE, "worker fairness area=" + GetTag(oArea) + " cursor=" + IntToString(nCursor) + " candidates=" + IntToString(nCandidateCount) + " budget=" + IntToString(nBudget));

    oObject = GetFirstObjectInArea(oArea);
    while (GetIsObjectValid(oObject))
    {
        if (DL_IsWorkerCreatureObject(oObject))
        {
            if (GetLocalInt(oObject, DL_L_WORKER_IS_CANDIDATE) == TRUE)
            {
                int nCandidateIndex = GetLocalInt(oObject, DL_L_WORKER_CANDIDATE_IDX);
                if (nProcessed < nPlanned)
                {
                    int nDistance = (nCandidateIndex - nCursor) % nCandidateCount;
                    if (nDistance < 0)
                    {
                        nDistance += nCandidateCount;
                    }
                    if (nDistance < nPlanned)
                    {
                        DL_ProcessNpcBudgeted(oArea, oObject);
                        nProcessed += 1;
                    }
                }
            }
            DL_ClearWorkerCandidateMarker(oObject);
        }
        oObject = GetNextObjectInArea(oArea);
    }

    SetLocalInt(oArea, DL_L_WORKER_CURSOR, (nCursor + nProcessed) % nCandidateCount);
}

void DL_AreaWorkerTick(object oArea)
{
    if (!DL_ShouldRunDailyLife(oArea)) return;
    DL_DispatchDueJobs(oArea, DL_GetWorkerBudget(oArea));
}

const int DL_UD_BOOTSTRAP = 12001;
const int DL_UD_RESYNC = 12002;
const int DL_UD_FORCE_RESYNC = 12003;
const int DL_UD_CLEANUP = 12004;
const int DL_UD_PERCEPTION = 12005;
const int DL_UD_PHYSICAL_ATTACKED = 12006;
const int DL_UD_DISTURBED = 12007;
const int DL_UD_DAMAGED = 12008;
const int DL_UD_SPELL_CAST_AT = 12009;

const string DL_L_UD_LAST_PERCEPTION_TICK = "dl_ud_last_perception_tick";
const string DL_L_UD_LAST_ATTACK_TICK = "dl_ud_last_attack_tick";
const string DL_L_UD_LAST_DISTURBED_TICK = "dl_ud_last_disturbed_tick";
const string DL_L_UD_LAST_DAMAGED_TICK = "dl_ud_last_damaged_tick";
const string DL_L_UD_LAST_SPELL_TICK = "dl_ud_last_spell_tick";
const string DL_L_UD_COOLDOWN_INIT_SUFFIX = "_init";

const int DL_UD_PERCEPTION_COOLDOWN_SEC = 3;
const int DL_UD_ATTACK_COOLDOWN_SEC = 1;
const int DL_UD_DISTURBED_COOLDOWN_SEC = 2;
const int DL_UD_DAMAGED_COOLDOWN_SEC = 1;
const int DL_UD_SPELL_COOLDOWN_SEC = 2;

int DL_GetHookClockSeconds()
{
    return (GetTimeHour() * 3600) + (GetTimeMinute() * 60) + GetTimeSecond();
}

int DL_HasHookCooldownElapsed(object oNPC, string sKey, int nCooldownSec)
{
    string sInitKey = sKey + DL_L_UD_COOLDOWN_INIT_SUFFIX;
    int nNow = DL_GetHookClockSeconds();
    int bInitialized = GetLocalInt(oNPC, sInitKey);
    int nLast;
    int nElapsed;
    if (!bInitialized) return TRUE;
    nLast = GetLocalInt(oNPC, sKey);
    nElapsed = nNow - nLast;
    if (nElapsed < 0) nElapsed += 86400;
    return nElapsed >= nCooldownSec;
}

void DL_MarkHookCooldown(object oNPC, string sKey)
{
    string sInitKey = sKey + DL_L_UD_COOLDOWN_INIT_SUFFIX;
    SetLocalInt(oNPC, sKey, DL_GetHookClockSeconds());
    SetLocalInt(oNPC, sInitKey, TRUE);
}

int DL_IsNpcLifecycleSubject(object oNPC)
{
    if (!GetIsObjectValid(oNPC)) return FALSE;
    if (GetObjectType(oNPC) != OBJECT_TYPE_CREATURE) return FALSE;
    if (GetIsPC(oNPC)) return FALSE;
    return TRUE;
}

string DL_GetPendingBootstrapSlotId(object oNPC)
{
    string sPendingSlotId;
    string sFunctionSlotId;
    string sBootstrapSlotId;
    object oBootstrapNpc;
    if (!DL_IsNpcLifecycleSubject(oNPC)) return "";
    sPendingSlotId = GetLocalString(oNPC, DL_L_PENDING_SLOT_ID);
    if (sPendingSlotId != "") return sPendingSlotId;
    sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (sFunctionSlotId != "") return sFunctionSlotId;
    sBootstrapSlotId = DL_GetSlotAssignedBootstrapSlotForNpc(oNPC);
    oBootstrapNpc = DL_GetSlotAssignedBootstrapNpcForSlot(sBootstrapSlotId);
    if (sBootstrapSlotId != "" && oBootstrapNpc == oNPC)
    {
        DL_LogNpc(oNPC, DL_DEBUG_VERBOSE, "pending bootstrap slot fallback from per-slot mapping: " + sBootstrapSlotId);
        return sBootstrapSlotId;
    }
    return "";
}

int DL_TryBootstrapNpcProfile(object oNPC)
{
    string sFunctionSlotId;
    if (!DL_IsNpcLifecycleSubject(oNPC)) return FALSE;
    if (DL_IsDailyLifeNpc(oNPC)) return TRUE;
    sFunctionSlotId = DL_GetPendingBootstrapSlotId(oNPC);
    if (sFunctionSlotId == "") return FALSE;
    if (DL_GetFunctionSlotId(oNPC) == "") SetLocalString(oNPC, DL_L_FUNCTION_SLOT_ID, sFunctionSlotId);
    if (DL_HasStagedFunctionSlotProfile(sFunctionSlotId))
    {
        DL_ApplyAssignedSlotProfile(oNPC, sFunctionSlotId);
        DL_ClearFunctionSlotProfile(sFunctionSlotId);
    }
    if (DL_IsDailyLifeNpc(oNPC))
    {
        DL_ClearSlotAssignedBootstrapForNpcOrSlot(oNPC, sFunctionSlotId);
        DeleteLocalString(oNPC, DL_L_PENDING_SLOT_ID);
        return TRUE;
    }
    return FALSE;
}

int DL_CanEmitNpcHookEvent(object oNPC)
{
    if (!DL_IsNpcLifecycleSubject(oNPC)) return FALSE;
    if (DL_IsDailyLifeNpc(oNPC)) return TRUE;
    return DL_GetPendingBootstrapSlotId(oNPC) != "";
}

void DL_SignalNpcUserDefined(object oNPC, int nEvent)
{
    if (!GetIsObjectValid(oNPC)) return;
    SignalEvent(oNPC, EventUserDefined(nEvent));
}

int DL_RequestNpcHookResync(object oNPC, int nReason, int bForceNow)
{
    object oArea;
    if (!DL_IsNpcLifecycleSubject(oNPC)) return FALSE;
    if (!DL_TryBootstrapNpcProfile(oNPC)) return FALSE;
    oArea = GetArea(oNPC);
    if (bForceNow && GetIsObjectValid(oArea) && DL_ShouldRunDailyLife(oArea))
    {
        DL_RunForcedResync(oNPC, oArea, nReason);
        return TRUE;
    }
    DL_RequestResync(oNPC, nReason);
    return TRUE;
}

int DL_RequestNpcWorkerHookResync(object oNPC, int bForceNow)
{
    return DL_RequestNpcHookResync(oNPC, DL_RESYNC_WORKER, bForceNow);
}

int DL_IsNpcProducerEvent(int nEvent)
{
    return nEvent == DL_UD_PERCEPTION
        || nEvent == DL_UD_PHYSICAL_ATTACKED
        || nEvent == DL_UD_DISTURBED
        || nEvent == DL_UD_DAMAGED
        || nEvent == DL_UD_SPELL_CAST_AT;
}

int DL_IsPlayablePerceptionSource(object oSeen)
{
    return GetIsObjectValid(oSeen) && GetIsPC(oSeen) && !GetIsDM(oSeen);
}

int DL_ShouldEmitHookEventWithCooldown(object oNPC, string sKey, int nCooldownSec)
{
    if (!DL_CanEmitNpcHookEvent(oNPC)) return FALSE;
    if (!DL_HasHookCooldownElapsed(oNPC, sKey, nCooldownSec)) return FALSE;
    DL_MarkHookCooldown(oNPC, sKey);
    return TRUE;
}

void DL_OnNpcSpawnHook(object oNPC)
{
    if (!DL_RequestNpcWorkerHookResync(oNPC, FALSE))
    {
        DL_LogNpc(oNPC, DL_DEBUG_VERBOSE, "npc spawn hook ignored: bootstrap not ready");
        return;
    }
    DL_LogNpc(oNPC, DL_DEBUG_VERBOSE, "npc spawn hook -> worker resync requested");
}

void DL_OnNpcDeathHook(object oNPC)
{
    string sFunctionSlotId;
    if (!GetIsObjectValid(oNPC)) return;
    sFunctionSlotId = DL_GetFunctionSlotId(oNPC);
    if (sFunctionSlotId != "")
    {
        DL_RecordBaseLostEvent(oNPC, sFunctionSlotId, DL_DIR_ABSENT);
        DL_ClearBaseLostEventForNpcOrSlot(oNPC, sFunctionSlotId);
        DL_RequestFunctionSlotReview(sFunctionSlotId, DL_RESYNC_BASE_LOST);
    }
    DeleteLocalString(oNPC, DL_L_PENDING_SLOT_ID);
    DeleteLocalInt(oNPC, DL_L_RESYNC_PENDING);
    DeleteLocalInt(oNPC, DL_L_RESYNC_REASON);
    DeleteLocalInt(oNPC, DL_L_ACTIVITY_KIND);
    DeleteLocalInt(oNPC, DL_L_DIALOGUE_MODE);
    DeleteLocalInt(oNPC, DL_L_SERVICE_MODE);
    DeleteLocalInt(oNPC, DL_L_ANCHOR_GROUP);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_PERCEPTION_TICK);
    // Keep cooldown cleanup suffix in sync with DL_L_UD_COOLDOWN_INIT_SUFFIX.
    DeleteLocalInt(oNPC, DL_L_UD_LAST_PERCEPTION_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_ATTACK_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_ATTACK_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DISTURBED_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DISTURBED_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DAMAGED_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_DAMAGED_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_SPELL_TICK);
    DeleteLocalInt(oNPC, DL_L_UD_LAST_SPELL_TICK + DL_L_UD_COOLDOWN_INIT_SUFFIX);
    DL_LogNpc(oNPC, DL_DEBUG_BASIC, "npc death hook -> runtime cleanup complete");
}

void DL_OnNpcUserDefinedHook(object oNPC, int nEvent)
{
    if (!DL_IsNpcLifecycleSubject(oNPC) && nEvent != DL_UD_CLEANUP) return;
    if (nEvent == DL_UD_BOOTSTRAP)
    {
        DL_OnNpcSpawnHook(oNPC);
        return;
    }
    if (nEvent == DL_UD_CLEANUP)
    {
        DL_OnNpcDeathHook(oNPC);
        return;
    }
    if (nEvent == DL_UD_RESYNC || nEvent == DL_UD_FORCE_RESYNC)
    {
        DL_RequestNpcWorkerHookResync(oNPC, nEvent == DL_UD_FORCE_RESYNC);
        return;
    }
    if (DL_IsNpcProducerEvent(nEvent))
    {
        DL_RequestNpcWorkerHookResync(oNPC, FALSE);
        return;
    }
}

int DL_ShouldEmitPerceptionEvent(object oNPC, object oSeen)
{
    if (!DL_IsPlayablePerceptionSource(oSeen)) return FALSE;
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_PERCEPTION_TICK, DL_UD_PERCEPTION_COOLDOWN_SEC);
}

int DL_ShouldEmitAttackEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_ATTACK_TICK, DL_UD_ATTACK_COOLDOWN_SEC);
}

int DL_ShouldEmitDisturbedEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_DISTURBED_TICK, DL_UD_DISTURBED_COOLDOWN_SEC);
}

int DL_ShouldEmitDamagedEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_DAMAGED_TICK, DL_UD_DAMAGED_COOLDOWN_SEC);
}

int DL_ShouldEmitSpellEvent(object oNPC)
{
    return DL_ShouldEmitHookEventWithCooldown(oNPC, DL_L_UD_LAST_SPELL_TICK, DL_UD_SPELL_COOLDOWN_SEC);
}
