#include "dl_activity_archive_anim_inc"
#include "dl_transition_inc"

// Step 05+: resolver/materialization skeleton.
// Scope: basic BLACKSMITH/GATE_POST/TRADER WORK/SLEEP window split.

const string DL_L_NPC_DIRECTIVE = "dl_npc_directive";
const string DL_L_NPC_MAT_REQ = "dl_npc_mat_req";
const string DL_L_NPC_MAT_TAG = "dl_npc_mat_tag";
const string DL_L_NPC_DIALOGUE_MODE = "dl_npc_dialogue_mode";
const string DL_L_NPC_SERVICE_MODE = "dl_npc_service_mode";
const string DL_L_NPC_PROFILE_ID = "dl_profile_id";
const string DL_L_NPC_STATE = "dl_state";
const string DL_L_NPC_SLEEP_PHASE = "dl_npc_sleep_phase";
const string DL_L_NPC_SLEEP_STATUS = "dl_npc_sleep_status";
const string DL_L_NPC_SLEEP_TARGET = "dl_npc_sleep_target";
const string DL_L_NPC_SLEEP_DIAGNOSTIC = "dl_npc_sleep_diagnostic";
const string DL_L_NPC_WORK_KIND = "dl_npc_work_kind";
const string DL_L_NPC_WORK_TARGET = "dl_npc_work_target";
const string DL_L_NPC_WORK_STATUS = "dl_npc_work_status";
const string DL_L_NPC_WORK_DIAGNOSTIC = "dl_npc_work_diagnostic";
const string DL_L_NPC_GUARD_SHIFT_START = "dl_guard_shift_start";
const string DL_L_NPC_ACTIVITY_ID = "dl_npc_activity_id";
const string DL_L_NPC_ANIM_SET = "dl_npc_anim_set";
const string DL_L_NPC_CACHE_SLEEP_APPROACH = "dl_cache_sleep_approach";
const string DL_L_NPC_CACHE_SLEEP_BED = "dl_cache_sleep_bed";
const string DL_L_NPC_CACHE_WORK_FORGE = "dl_cache_work_forge";
const string DL_L_NPC_CACHE_WORK_CRAFT = "dl_cache_work_craft";
const string DL_L_NPC_CACHE_WORK_POST = "dl_cache_work_post";
const string DL_L_NPC_CACHE_WORK_TRADE = "dl_cache_work_trade";
const string DL_L_NPC_CACHE_MEAL = "dl_cache_meal";
const string DL_L_NPC_CACHE_SOCIAL_A = "dl_cache_social_a";
const string DL_L_NPC_CACHE_SOCIAL_B = "dl_cache_social_b";
const string DL_L_NPC_CACHE_PUBLIC = "dl_cache_public";
const string DL_L_NPC_CACHE_WORK_PRIMARY = "dl_cache_work_primary";
const string DL_L_NPC_CACHE_WORK_SECONDARY = "dl_cache_work_secondary";
const string DL_L_NPC_CACHE_WORK_FETCH = "dl_cache_work_fetch";
const string DL_L_NPC_CACHE_HOME_AREA = "dl_cache_home_area";
const string DL_L_NPC_CACHE_WORK_AREA = "dl_cache_work_area";
const string DL_L_NPC_CACHE_MEAL_AREA = "dl_cache_meal_area";
const string DL_L_NPC_CACHE_SOCIAL_AREA = "dl_cache_social_area";
const string DL_L_NPC_CACHE_PUBLIC_AREA = "dl_cache_public_area";
const string DL_L_NPC_FOCUS_STATUS = "dl_npc_focus_status";
const string DL_L_NPC_FOCUS_TARGET = "dl_npc_focus_target";
const string DL_L_NPC_FOCUS_DIAGNOSTIC = "dl_npc_focus_diagnostic";
const string DL_L_NPC_SOCIAL_SLOT = "dl_social_slot";
const string DL_L_NPC_SOCIAL_PARTNER_TAG = "dl_social_partner_tag";
const string DL_L_NPC_WEEKEND_MODE = "dl_weekend_mode";
const string DL_L_NPC_WEEKEND_SHIFT_LENGTH = "dl_weekend_shift_length";
const string DL_L_NPC_HOME_AREA_TAG = "dl_home_area_tag";
const string DL_L_NPC_HOME_SLOT = "dl_home_slot";
const string DL_L_NPC_WORK_AREA_TAG = "dl_work_area_tag";
const string DL_L_NPC_MEAL_AREA_TAG = "dl_meal_area_tag";
const string DL_L_NPC_SOCIAL_AREA_TAG = "dl_social_area_tag";
const string DL_L_NPC_PUBLIC_AREA_TAG = "dl_public_area_tag";
const string DL_L_NPC_WAKE_HOUR = "dl_wake_hour";
const string DL_L_NPC_SLEEP_HOURS = "dl_sleep_hours";
const string DL_L_NPC_SHIFT_START = "dl_shift_start";
const string DL_L_NPC_SHIFT_LENGTH = "dl_shift_length";
const string DL_L_NPC_DIAG_LAST_KEY = "dl_diag_last_key";
const string DL_L_NPC_DIAG_LAST_MINUTE = "dl_diag_last_minute";
const string DL_L_MODULE_CHAT_DEBUG = "dl_chat_debug";
const string DL_L_MODULE_CHAT_DEBUG_NPC_TAG = "dl_chat_debug_npc_tag";
const string DL_L_NPC_CHAT_LAST_EVENT_SIG = "dl_chat_last_event_sig";
const string DL_L_NPC_CHAT_STUCK_SIG = "dl_chat_stuck_sig";
const string DL_L_NPC_CHAT_STUCK_SINCE = "dl_chat_stuck_since";
const string DL_L_NPC_CHAT_STUCK_LAST_LOG = "dl_chat_stuck_last_log";

const string DL_PROFILE_BLACKSMITH = "blacksmith";
const string DL_PROFILE_GATE_POST = "gate_post";
const string DL_PROFILE_TRADER = "trader";
const string DL_PROFILE_DOMESTIC_WORKER = "domestic_worker";

const string DL_STATE_IDLE = "idle";
const string DL_STATE_SLEEP = "sleep";
const string DL_STATE_WORK = "work";
const string DL_STATE_SOCIAL = "social";
const string DL_STATE_MEAL = "meal";
const string DL_STATE_PUBLIC = "public";

const string DL_DIALOGUE_IDLE = "idle";
const string DL_DIALOGUE_SLEEP = "sleep";
const string DL_DIALOGUE_WORK = "work";
const string DL_DIALOGUE_SOCIAL = "social";

const string DL_SERVICE_OFF = "off";
const string DL_SERVICE_AVAILABLE = "available";

const string DL_MAT_SLEEP = "sleep";
const string DL_MAT_WORK = "work";
const string DL_MAT_SOCIAL = "social";
const string DL_MAT_MEAL = "meal";
const string DL_MAT_PUBLIC = "public";

const int DL_DIR_NONE = 0;
const int DL_DIR_SLEEP = 1;
const int DL_DIR_WORK = 2;
const int DL_DIR_SOCIAL = 3;
const int DL_DIR_MEAL = 4;
const int DL_DIR_PUBLIC = 5;
const int DL_SLEEP_PHASE_NONE = 0;
const int DL_SLEEP_PHASE_MOVING = 1;
const int DL_SLEEP_PHASE_JUMPING = 2;
const int DL_SLEEP_PHASE_ON_BED = 3;

const float DL_SLEEP_APPROACH_RADIUS = 1.50;
const float DL_SLEEP_BED_RADIUS = 1.10;
const float DL_WORK_ANCHOR_RADIUS = 1.60;

const string DL_WORK_KIND_FORGE = "forge";
const string DL_WORK_KIND_CRAFT = "craft";
const string DL_WORK_KIND_FETCH = "fetch";
const string DL_WORK_KIND_POST = "post";
const string DL_WORK_KIND_TRADE = "trade";
const string DL_WORK_KIND_DOMESTIC = "domestic";
const string DL_WEEKEND_MODE_OFF_PUBLIC = "off_public";
const string DL_WEEKEND_MODE_REDUCED_WORK = "reduced_work";
const string DL_MEAL_KIND_BREAKFAST = "breakfast";
const string DL_MEAL_KIND_LUNCH = "lunch";
const string DL_MEAL_KIND_DINNER = "dinner";
const int DL_CHAT_STUCK_THRESHOLD_MIN = 5;
const int DL_CHAT_STUCK_LOG_INTERVAL_MIN = 5;
const int DL_CHAT_MARKUP_COOLDOWN_MIN = 120;

// Forward declarations for symbols implemented in includes that are
// textually attached later in this file.
int DL_IsActivePipelineNpc(object oNpc);
object DL_GetHomeArea(object oNpc);
object DL_GetWorkArea(object oNpc);

#include "dl_sched_inc"

void DL_LogChat(string sMessage)
{
    object oPc = GetFirstPC();
    while (GetIsObjectValid(oPc))
    {
        SendMessageToPC(oPc, "[DL] " + sMessage);
        oPc = GetNextPC();
    }
}
int DL_IsChatDebugEnabledForNpc(object oNpc)
{
    object oModule = GetModule();
    if (GetLocalInt(oModule, DL_L_MODULE_CHAT_DEBUG) != TRUE)
    {
        return FALSE;
    }

    string sFilterTag = GetLocalString(oModule, DL_L_MODULE_CHAT_DEBUG_NPC_TAG);
    if (sFilterTag == "" || !GetIsObjectValid(oNpc))
    {
        return TRUE;
    }

    return GetTag(oNpc) == sFilterTag;
}
string DL_GetDirectiveDebugLabel(int nDirective)
{
    if (nDirective == DL_DIR_SLEEP)
    {
        return "SLEEP";
    }
    if (nDirective == DL_DIR_WORK)
    {
        return "WORK";
    }
    if (nDirective == DL_DIR_MEAL)
    {
        return "MEAL";
    }
    if (nDirective == DL_DIR_SOCIAL)
    {
        return "SOCIAL";
    }
    if (nDirective == DL_DIR_PUBLIC)
    {
        return "PUBLIC";
    }
    return "NONE";
}
void DL_LogChatDebugEvent(object oNpc, string sKind, string sPayload)
{
    if (!GetIsObjectValid(oNpc) || !DL_IsChatDebugEnabledForNpc(oNpc))
    {
        return;
    }

    string sSig = sKind + "|" + sPayload;
    if (GetLocalString(oNpc, DL_L_NPC_CHAT_LAST_EVENT_SIG) == sSig)
    {
        return;
    }

    SetLocalString(oNpc, DL_L_NPC_CHAT_LAST_EVENT_SIG, sSig);
    DL_LogChat("npc=" + GetTag(oNpc) + " " + sPayload);
}
void DL_LogDirectiveChange(object oNpc, int nPrevDirective, int nDirective)
{
    if (nDirective == nPrevDirective)
    {
        return;
    }

    DL_LogChatDebugEvent(
        oNpc,
        "directive",
        "dir=" + DL_GetDirectiveDebugLabel(nDirective) +
            " prev=" + DL_GetDirectiveDebugLabel(nPrevDirective) +
            " minute=" + IntToString(DL_GetNowMinuteOfDay())
    );
}
void DL_LogStuckState(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc) || !DL_IsChatDebugEnabledForNpc(oNpc))
    {
        return;
    }

    string sState = "";
    string sTarget = "";
    if (nDirective == DL_DIR_SLEEP)
    {
        sState = GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS);
        if (sState == "moving_to_approach" || sState == "jumping_to_bed")
        {
            sTarget = GetLocalString(oNpc, DL_L_NPC_SLEEP_TARGET);
        }
    }
    else if (nDirective == DL_DIR_WORK)
    {
        sState = GetLocalString(oNpc, DL_L_NPC_WORK_STATUS);
        if (sState == "moving_to_anchor")
        {
            sTarget = GetLocalString(oNpc, DL_L_NPC_WORK_TARGET);
        }
    }
    else if (nDirective == DL_DIR_MEAL || nDirective == DL_DIR_SOCIAL || nDirective == DL_DIR_PUBLIC)
    {
        sState = GetLocalString(oNpc, DL_L_NPC_FOCUS_STATUS);
        if (sState == "moving_to_anchor")
        {
            sTarget = GetLocalString(oNpc, DL_L_NPC_FOCUS_TARGET);
        }
    }

    if (sTarget == "")
    {
        DeleteLocalString(oNpc, DL_L_NPC_CHAT_STUCK_SIG);
        DeleteLocalInt(oNpc, DL_L_NPC_CHAT_STUCK_SINCE);
        return;
    }

    int nNowAbsMin = DL_GetAbsoluteMinute();
    string sSig = DL_GetDirectiveDebugLabel(nDirective) + "|" + sState + "|" + sTarget;
    if (GetLocalString(oNpc, DL_L_NPC_CHAT_STUCK_SIG) != sSig)
    {
        SetLocalString(oNpc, DL_L_NPC_CHAT_STUCK_SIG, sSig);
        SetLocalInt(oNpc, DL_L_NPC_CHAT_STUCK_SINCE, nNowAbsMin);
        DeleteLocalInt(oNpc, DL_L_NPC_CHAT_STUCK_LAST_LOG);
        return;
    }

    int nSince = GetLocalInt(oNpc, DL_L_NPC_CHAT_STUCK_SINCE);
    int nLastLog = GetLocalInt(oNpc, DL_L_NPC_CHAT_STUCK_LAST_LOG);
    if ((nNowAbsMin - nSince) < DL_CHAT_STUCK_THRESHOLD_MIN ||
        (nLastLog > 0 && (nNowAbsMin - nLastLog) < DL_CHAT_STUCK_LOG_INTERVAL_MIN))
    {
        return;
    }

    SetLocalInt(oNpc, DL_L_NPC_CHAT_STUCK_LAST_LOG, nNowAbsMin);
    DL_LogChat("npc=" + GetTag(oNpc) +
              " stuck dir=" + DL_GetDirectiveDebugLabel(nDirective) +
              " state=" + sState +
              " target=" + sTarget);
}
void DL_LogMarkupIssueOnce(object oNpc, string sKey, string sMessage)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int nNowAbsMin = DL_GetAbsoluteMinute();
    string sLastKey = GetLocalString(oNpc, DL_L_NPC_DIAG_LAST_KEY);
    int nLastMin = GetLocalInt(oNpc, DL_L_NPC_DIAG_LAST_MINUTE);
    if (sLastKey == sKey && (nNowAbsMin - nLastMin) < DL_CHAT_MARKUP_COOLDOWN_MIN)
    {
        return;
    }

    SetLocalString(oNpc, DL_L_NPC_DIAG_LAST_KEY, sKey);
    SetLocalInt(oNpc, DL_L_NPC_DIAG_LAST_MINUTE, nNowAbsMin);
    if (DL_IsChatDebugEnabledForNpc(oNpc))
    {
        DL_LogChat(sMessage);
    }
}

void DL_ApplyMaterializationSkeleton(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    if (nDirective == DL_DIR_SLEEP)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_SLEEP);
        return;
    }

    if (nDirective == DL_DIR_WORK)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_WORK);
        return;
    }

    if (nDirective == DL_DIR_SOCIAL)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_SOCIAL);
        return;
    }

    if (nDirective == DL_DIR_MEAL)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_MEAL);
        return;
    }

    if (nDirective == DL_DIR_PUBLIC)
    {
        SetLocalInt(oNpc, DL_L_NPC_MAT_REQ, TRUE);
        SetLocalString(oNpc, DL_L_NPC_MAT_TAG, DL_MAT_PUBLIC);
        return;
    }

    DeleteLocalInt(oNpc, DL_L_NPC_MAT_REQ);
    DeleteLocalString(oNpc, DL_L_NPC_MAT_TAG);
}

#include "dl_anchor_cache_inc"
#include "dl_presentation_inc"
#include "dl_sleep_inc"
#include "dl_work_inc"
#include "dl_focus_inc"

void DL_SetInteractionModes(object oNpc, string sDialogue, string sService)
{
    SetLocalString(oNpc, DL_L_NPC_DIALOGUE_MODE, sDialogue);
    SetLocalString(oNpc, DL_L_NPC_SERVICE_MODE, sService);
}
int DL_IsProfileServiceAvailable(string sProfile)
{
    return sProfile != DL_PROFILE_GATE_POST;
}
void DL_ApplyIdleLikeDirectiveState(object oNpc, int bSocial)
{
    SetLocalString(oNpc, DL_L_NPC_STATE, bSocial ? DL_STATE_SOCIAL : DL_STATE_IDLE);
    DL_SetInteractionModes(
        oNpc,
        bSocial ? DL_DIALOGUE_SOCIAL : DL_DIALOGUE_IDLE,
        DL_SERVICE_OFF
    );
    DL_ClearSleepExecutionState(oNpc);
    DL_ClearWorkExecutionState(oNpc);
    DL_ClearFocusExecutionState(oNpc);
    DL_ClearActivityPresentation(oNpc);
}
void DL_ApplyDirectiveSkeleton(object oNpc, int nDirective)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    int nPrevDirective = GetLocalInt(oNpc, DL_L_NPC_DIRECTIVE);
    SetLocalInt(oNpc, DL_L_NPC_DIRECTIVE, nDirective);
    DL_LogDirectiveChange(oNpc, nPrevDirective, nDirective);

    if (nDirective == DL_DIR_SLEEP)
    {
        DL_ClearWorkExecutionState(oNpc);
        DL_ClearFocusExecutionState(oNpc);
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_SLEEP);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_SLEEP, DL_SERVICE_OFF);
        DL_ApplyArchiveActivityPresentation(oNpc, nDirective);
        DL_ExecuteSleepDirective(oNpc);
    }
    else if (nDirective == DL_DIR_WORK)
    {
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_WORK);
        string sProfile = GetLocalString(oNpc, DL_L_NPC_PROFILE_ID);
        DL_SetInteractionModes(
            oNpc,
            DL_DIALOGUE_WORK,
            DL_IsProfileServiceAvailable(sProfile) ? DL_SERVICE_AVAILABLE : DL_SERVICE_OFF
        );

        DL_ClearSleepExecutionState(oNpc);
        DL_ClearFocusExecutionState(oNpc);
        DL_ExecuteWorkDirective(oNpc);
    }
    else if (nDirective == DL_DIR_MEAL)
    {
        DL_ClearSleepExecutionState(oNpc);
        DL_ClearWorkExecutionState(oNpc);
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_MEAL);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_IDLE, DL_SERVICE_OFF);
        DL_ExecuteMealDirective(oNpc);
        DL_ClearActivityPresentation(oNpc);
    }
    else if (nDirective == DL_DIR_SOCIAL)
    {
        DL_ClearSleepExecutionState(oNpc);
        DL_ClearWorkExecutionState(oNpc);
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_SOCIAL);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_SOCIAL, DL_SERVICE_OFF);
        DL_ExecuteSocialDirective(oNpc);
        DL_ClearActivityPresentation(oNpc);
    }
    else if (nDirective == DL_DIR_PUBLIC)
    {
        DL_ClearSleepExecutionState(oNpc);
        DL_ClearWorkExecutionState(oNpc);
        SetLocalString(oNpc, DL_L_NPC_STATE, DL_STATE_PUBLIC);
        DL_SetInteractionModes(oNpc, DL_DIALOGUE_IDLE, DL_SERVICE_OFF);
        DL_ExecutePublicDirective(oNpc);
        DL_ClearActivityPresentation(oNpc);
    }
    else
    {
        DL_ApplyIdleLikeDirectiveState(oNpc, FALSE);
    }

    DL_ApplyMaterializationSkeleton(oNpc, nDirective);
    DL_LogStuckState(oNpc, nDirective);
}
