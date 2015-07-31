public OnEntityCreated(iEntity, const String:sClassName[])
{
	if (iEntity > MaxClients && IsValidEntity(iEntity) && StrEqual(sClassName, "trigger_multiple")) {
		SDKHook(iEntity, SDKHook_Spawn, Hook_Spawn);
	}
}

public Action:Hook_Spawn(iEntity, iActivator, iCaller, UseType:iType, Float:fValue)
{
	decl String:sTargetName[256];
	GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));

	if (DTC_StrHasPrefix(sTargetName, "TG_TEAM", false)) {
		HookSingleEntityOutput(iEntity, "OnStartTouch", Hook_MapTrigger_Team);
	} else if (DTC_StrHasPrefix(sTargetName, "TG_FENCE", false)) {
		HookSingleEntityOutput(iEntity, "OnEndTouch", Hook_LaserFenceOnEndTouch);
	}
}

//------------------------------------------------------------------------------------------------
// Hooks

public Hook_MapTrigger_Team(const String:sOutput[], iCaller, iActivator, Float:fDelay)
{
	if (!Client_IsIngame(iActivator) || GetClientTeam(iActivator) != CS_TEAM_T) {
		return;
	}

	new String:sTargetName[DTC_MAX_LINE_LEN];
	GetEntPropString(iCaller, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));

	new Handle:hArgs = DTC_GetArgs(sTargetName);

	if (hArgs != INVALID_HANDLE) {
		new TG_Team:iTeam = GetTGTeamFromDTCArg(hArgs, 1);

		if (iTeam == TG_ErrorTeam) {
			return;
		}

		SwitchToTeam(-1, iActivator, iTeam);
		CloseHandle(hArgs);
	}
}
