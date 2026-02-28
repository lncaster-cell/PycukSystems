// NPC activity migration/runtime-key helpers.

string NpcBhvrSafeHash(string sValue, int nLength)
{
    string sDigits;
    int nHash;
    int nIndex;
    string sChar;
    int nCode;
    string sResult;

    if (nLength <= 0)
    {
        return "";
    }

    sDigits = "0123456789abcdefghijklmnopqrstuvwxyz";
    nHash = 5381;
    nIndex = 0;

    while (nIndex < GetStringLength(sValue))
    {
        sChar = GetSubString(sValue, nIndex, 1);
        nCode = FindSubString("abcdefghijklmnopqrstuvwxyz0123456789_", sChar);
        if (nCode < 0)
        {
            nCode = 36;
        }

        nHash = (nHash * 33 + nCode + 1) % 2147483647;
        nIndex = nIndex + 1;
    }

    sResult = "";
    nIndex = 0;
    while (nIndex < nLength)
    {
        sResult = GetSubString(sDigits, nHash % 36, 1) + sResult;
        nHash = nHash / 36;
        nIndex = nIndex + 1;
    }

    return sResult;
}

string NpcBhvrSafeId(string sRawId, int nTargetLength)
{
    string sSource;
    string sSafe;
    string sChar;
    string sHash;
    int nIndex;

    if (nTargetLength <= 0)
    {
        return "";
    }

    sSource = GetStringLowerCase(sRawId);
    if (sSource == "")
    {
        sSource = "id";
    }

    sSafe = "";
    nIndex = 0;
    while (nIndex < GetStringLength(sSource))
    {
        sChar = GetSubString(sSource, nIndex, 1);
        if (FindSubString("abcdefghijklmnopqrstuvwxyz0123456789", sChar) >= 0)
        {
            sSafe = sSafe + sChar;
        }
        else if (GetStringLength(sSafe) == 0 || GetSubString(sSafe, GetStringLength(sSafe) - 1, 1) != "_")
        {
            sSafe = sSafe + "_";
        }

        nIndex = nIndex + 1;
    }

    while (GetStringLength(sSafe) > 0 && GetSubString(sSafe, 0, 1) == "_")
    {
        sSafe = GetSubString(sSafe, 1, GetStringLength(sSafe) - 1);
    }
    while (GetStringLength(sSafe) > 0 && GetSubString(sSafe, GetStringLength(sSafe) - 1, 1) == "_")
    {
        sSafe = GetSubString(sSafe, 0, GetStringLength(sSafe) - 1);
    }

    if (sSafe == "")
    {
        sSafe = "id";
    }

    sHash = NpcBhvrSafeHash(sSafe, NPC_BHVR_LOCAL_KEY_HASH_LENGTH);
    if (nTargetLength <= GetStringLength(sHash) + 1)
    {
        return GetSubString(sHash, 0, nTargetLength);
    }

    if (GetStringLength(sSafe) > nTargetLength - GetStringLength(sHash) - 1)
    {
        sSafe = GetSubString(sSafe, 0, nTargetLength - GetStringLength(sHash) - 1);
    }

    return sSafe + "_" + sHash;
}

string NpcBhvrLocalKey(string sPrefix, string sIdSuffix)
{
    int nSuffixMax;

    nSuffixMax = NPC_BHVR_LOCAL_KEY_MAX_LENGTH - GetStringLength(sPrefix);
    if (nSuffixMax <= 0)
    {
        return GetSubString(sPrefix, 0, NPC_BHVR_LOCAL_KEY_MAX_LENGTH);
    }

    return sPrefix + NpcBhvrSafeId(sIdSuffix, nSuffixMax);
}

string NpcBhvrActivityRouteCountKey(string sRouteId)
{
    return NpcBhvrLocalKey("nb_rc_", sRouteId);
}

string NpcBhvrActivityRouteLoopKey(string sRouteId)
{
    return NpcBhvrLocalKey("nb_rl_", sRouteId);
}

string NpcBhvrActivityRouteTagKey(string sRouteId)
{
    return NpcBhvrLocalKey("nb_rt_", sRouteId);
}

string NpcBhvrActivityRoutePauseTicksKey(string sRouteId)
{
    return NpcBhvrLocalKey("nb_rp_", sRouteId);
}

string NpcBhvrActivityRoutePointActivityKey(string sRouteId, int nIndex)
{
    return NpcBhvrLocalKey("nb_ra_", sRouteId + "_" + IntToString(nIndex));
}

string NpcBhvrActivityRouteMigratedFlagKey(string sRouteId)
{
    return "migrated_" + sRouteId;
}

string NpcBhvrActivityRouteMigratedIntFlagKey(string sRuntimeKey)
{
    return "migrated_int_" + sRuntimeKey;
}

void NpcBhvrActivityPrewarmRouteRuntime(object oOwner, string sRouteId, object oMetricScope)
{
    string sRouteIdNormalized;

    if (!GetIsObjectValid(oOwner))
    {
        return;
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oMetricScope);
    if (GetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_ROUTE_ID) == sRouteIdNormalized)
    {
        return;
    }

    SetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_ROUTE_ID, sRouteIdNormalized);
    SetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_COUNT_KEY, NpcBhvrActivityRouteCountKey(sRouteIdNormalized));
    SetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_LOOP_KEY, NpcBhvrActivityRouteLoopKey(sRouteIdNormalized));
    SetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_TAG_KEY, NpcBhvrActivityRouteTagKey(sRouteIdNormalized));
    SetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_PAUSE_KEY, NpcBhvrActivityRoutePauseTicksKey(sRouteIdNormalized));
}

string NpcBhvrActivityGetPrewarmedRuntimeKey(object oOwner, string sRouteId, string sRuntimeKeyVar, string sRouteKeyPrefix, object oMetricScope)
{
    string sRouteIdNormalized;
    string sRuntimeKey;

    if (!GetIsObjectValid(oOwner))
    {
        return "";
    }

    sRouteIdNormalized = NpcBhvrActivityNormalizeRouteIdOrDefault(sRouteId, oMetricScope);
    if (GetLocalString(oOwner, NPC_BHVR_VAR_ROUTE_RUNTIME_ROUTE_ID) != sRouteIdNormalized)
    {
        NpcBhvrActivityPrewarmRouteRuntime(oOwner, sRouteIdNormalized, oMetricScope);
    }

    sRuntimeKey = GetLocalString(oOwner, sRuntimeKeyVar);
    if (sRuntimeKey == "")
    {
        sRuntimeKey = NpcBhvrLocalKey(sRouteKeyPrefix, sRouteIdNormalized);
        SetLocalString(oOwner, sRuntimeKeyVar, sRuntimeKey);
    }

    return sRuntimeKey;
}

int NpcBhvrActivityReadMigratedRouteInt(object oOwner, string sRouteId, string sRuntimeKey, string sLegacyPrefix)
{
    int nValue;
    string sMigratedFlagKey;
    string sMigratedIntFlagKey;
    string sLegacyKey;

    sMigratedIntFlagKey = NpcBhvrActivityRouteMigratedIntFlagKey(sRuntimeKey);
    if (GetLocalInt(oOwner, sMigratedIntFlagKey) == TRUE)
    {
        return GetLocalInt(oOwner, sRuntimeKey);
    }

    nValue = GetLocalInt(oOwner, sRuntimeKey);
    if (nValue != 0)
    {
        SetLocalInt(oOwner, sMigratedIntFlagKey, TRUE);
        return nValue;
    }

    sLegacyKey = sLegacyPrefix + sRouteId;
    nValue = GetLocalInt(oOwner, sLegacyKey);
    if (nValue != 0)
    {
        SetLocalInt(oOwner, sRuntimeKey, nValue);
        SetLocalInt(oOwner, sMigratedIntFlagKey, TRUE);
        DeleteLocalInt(oOwner, sLegacyKey);
        return nValue;
    }

    SetLocalInt(oOwner, sRuntimeKey, NPC_BHVR_CFG_INT_UNSET);
    SetLocalInt(oOwner, sMigratedIntFlagKey, TRUE);

    sMigratedFlagKey = NpcBhvrActivityRouteMigratedFlagKey(sRouteId);
    SetLocalInt(oOwner, sMigratedFlagKey, TRUE);

    return NPC_BHVR_CFG_INT_UNSET;
}

string NpcBhvrActivityReadMigratedRouteString(object oOwner, string sRouteId, string sRuntimeKey, string sLegacyPrefix)
{
    string sValue;
    string sMigratedFlagKey;
    string sLegacyKey;

    sValue = GetLocalString(oOwner, sRuntimeKey);
    if (sValue != "")
    {
        return sValue;
    }

    sMigratedFlagKey = NpcBhvrActivityRouteMigratedFlagKey(sRouteId);
    if (GetLocalInt(oOwner, sMigratedFlagKey) == TRUE)
    {
        return "";
    }

    sLegacyKey = sLegacyPrefix + sRouteId;
    sValue = GetLocalString(oOwner, sLegacyKey);
    if (sValue != "")
    {
        SetLocalString(oOwner, sRuntimeKey, sValue);
        DeleteLocalString(oOwner, sLegacyKey);
    }

    SetLocalInt(oOwner, sMigratedFlagKey, TRUE);
    return sValue;
}

void NpcBhvrActivityPrewarmAreaRuntime(object oArea)
{
    if (!GetIsObjectValid(oArea))
    {
        return;
    }

    NpcBhvrActivityPrewarmRouteRuntime(oArea, NPC_BHVR_ACTIVITY_ROUTE_DEFAULT, oArea);
}
