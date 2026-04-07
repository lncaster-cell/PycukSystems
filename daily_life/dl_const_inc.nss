#ifndef DL_CONST_INC_NSS
#define DL_CONST_INC_NSS

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

#endif
