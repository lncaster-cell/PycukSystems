const string DL_L_NPC_BLOCKED_DIAGNOSTIC = "dl_npc_blocked_diagnostic";
const string DL_L_NPC_DIAG_LAST_SIG = "dl_npc_diag_last_sig";

string DL_GetDirectiveLabel(int nDirective)
{
    if (nDirective == DL_DIR_SLEEP)
    {
        return "sleep";
    }
    if (nDirective == DL_DIR_WORK)
    {
        return "work";
    }
    if (nDirective == DL_DIR_SOCIAL)
    {
        return "social";
    }
    return "none";
}

string DL_GetNpcProblemSummary(object oNpc)
{
    string sTransitionDiag = GetLocalString(oNpc, DL_L_NPC_TRANSITION_DIAGNOSTIC);
    if (sTransitionDiag != "")
    {
        return "transition:" + sTransitionDiag;
    }

    string sSleepDiag = GetLocalString(oNpc, DL_L_NPC_SLEEP_DIAGNOSTIC);
    if (sSleepDiag != "")
    {
        return "sleep:" + sSleepDiag;
    }

    string sWorkDiag = GetLocalString(oNpc, DL_L_NPC_WORK_DIAGNOSTIC);
    if (sWorkDiag != "")
    {
        return "work:" + sWorkDiag;
    }

    string sBlockedDiag = GetLocalString(oNpc, DL_L_NPC_BLOCKED_DIAGNOSTIC);
    if (sBlockedDiag != "")
    {
        return "blocked:" + sBlockedDiag;
    }

    string sTransitionStatus = GetLocalString(oNpc, DL_L_NPC_TRANSITION_STATUS);
    if (sTransitionStatus != "" && sTransitionStatus != "transitioning")
    {
        return "transition_status:" + sTransitionStatus;
    }

    string sSleepStatus = GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS);
    if (sSleepStatus != "" && sSleepStatus != "on_bed")
    {
        return "sleep_status:" + sSleepStatus;
    }

    string sWorkStatus = GetLocalString(oNpc, DL_L_NPC_WORK_STATUS);
    if (sWorkStatus != "" && sWorkStatus != "on_anchor")
    {
        return "work_status:" + sWorkStatus;
    }

    return "ok";
}

void DL_LogNpcDiagnostic(object oNpc, string sSource)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    string sProblem = DL_GetNpcProblemSummary(oNpc);
    string sLog = "[DL][NPC] src=" + sSource +
                  " npc=" + GetName(oNpc) +
                  " hour=" + IntToString(GetTimeHour()) +
                  " profile=" + GetLocalString(oNpc, DL_L_NPC_PROFILE_ID) +
                  " directive=" + DL_GetDirectiveLabel(GetLocalInt(oNpc, DL_L_NPC_DIRECTIVE)) +
                  " state=" + GetLocalString(oNpc, DL_L_NPC_STATE) +
                  " problem=" + sProblem +
                  " sleep_status=" + GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS) +
                  " sleep_target=" + GetLocalString(oNpc, DL_L_NPC_SLEEP_TARGET) +
                  " work_status=" + GetLocalString(oNpc, DL_L_NPC_WORK_STATUS) +
                  " work_target=" + GetLocalString(oNpc, DL_L_NPC_WORK_TARGET) +
                  " transition_status=" + GetLocalString(oNpc, DL_L_NPC_TRANSITION_STATUS) +
                  " transition_target=" + GetLocalString(oNpc, DL_L_NPC_TRANSITION_TARGET);

    DL_LogRuntime(sLog);
}

string DL_GetNpcDiagnosticSignature(object oNpc)
{
    return DL_GetDirectiveLabel(GetLocalInt(oNpc, DL_L_NPC_DIRECTIVE)) + "|" +
           GetLocalString(oNpc, DL_L_NPC_STATE) + "|" +
           DL_GetNpcProblemSummary(oNpc) + "|" +
           GetLocalString(oNpc, DL_L_NPC_SLEEP_STATUS) + "|" +
           GetLocalString(oNpc, DL_L_NPC_SLEEP_TARGET) + "|" +
           GetLocalString(oNpc, DL_L_NPC_WORK_STATUS) + "|" +
           GetLocalString(oNpc, DL_L_NPC_WORK_TARGET) + "|" +
           GetLocalString(oNpc, DL_L_NPC_TRANSITION_STATUS) + "|" +
           GetLocalString(oNpc, DL_L_NPC_TRANSITION_TARGET);
}

void DL_MaybeLogNpcDiagnostic(object oNpc, string sSource, int bForce)
{
    if (!GetIsObjectValid(oNpc))
    {
        return;
    }

    string sSignature = DL_GetNpcDiagnosticSignature(oNpc);
    if (!bForce && GetLocalString(oNpc, DL_L_NPC_DIAG_LAST_SIG) == sSignature)
    {
        return;
    }

    SetLocalString(oNpc, DL_L_NPC_DIAG_LAST_SIG, sSignature);
    DL_LogNpcDiagnostic(oNpc, sSource);
}
