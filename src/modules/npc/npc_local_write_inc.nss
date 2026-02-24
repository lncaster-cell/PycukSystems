// Local variable write helpers for hot paths.

void NpcBhvrSetLocalIntIfChanged(object oScope, string sVar, int nValue)
{
    if (!GetIsObjectValid(oScope))
    {
        return;
    }

    if (GetLocalInt(oScope, sVar) == nValue)
    {
        return;
    }

    SetLocalInt(oScope, sVar, nValue);
}

void NpcBhvrSetLocalStringIfChanged(object oScope, string sVar, string sValue)
{
    if (!GetIsObjectValid(oScope))
    {
        return;
    }

    if (GetLocalString(oScope, sVar) == sValue)
    {
        return;
    }

    SetLocalString(oScope, sVar, sValue);
}
