new Handle:g_hLogTime, bool:g_bLogCvar, String:g_sLogFile[PLATFORM_MAX_PATH];
new Handle:g_hAutoUpdate;

new Handle:g_hModuleDefVisibility;

new Handle:g_hMenuPercent, Float:g_fMenuPercent;

new Handle:g_hSelfDamage, g_iSelfDamage;

new Handle:g_hRoundLimit, g_iRoundLimit;
new Handle:g_hMoveSurvivors, g_iMoveSurvivors;
new Handle:g_hSaveWeapons, g_iSaveWeapons;
new Handle:g_hRebelAttack, g_iRebelAttack;
new Handle:g_hKillFrags, Handle:g_hKillScore;

new Handle:g_hChangeTeamDelay, Float:g_fChangeTeamDelay;
new Handle:g_hTeamDiff, g_iTeamDiff;
new Handle:g_hTeamAttack, bool:g_bTeamAttack;
new Handle:g_hNotifyPlayerTeam, g_iNotifyPlayerTeam, Handle:g_hNotifyTimer;

new Handle:g_hAllowMark, bool:g_bAllowMark;
new Handle:g_hMarkLife, Float:g_fMarkLife;
new Handle:g_hMarkLaser, Float:g_fMarkLaser;
new Handle:g_hMarkLimit, g_iMarkLimit, g_iMarkLimitCounter;

new Handle:g_hImportantMsg, bool:g_bImportantMsg;
new Handle:g_hAllowTeamPrefix, bool:g_bAllowTeamPrefix;

new Handle:g_hFenceType, g_iFenceType;
new Handle:g_hFenceHeight, Float:g_fFenceHeight;
new Handle:g_hFenceNotify, g_iFenceNotify;
new Handle:g_hFencePunishLength, Float:g_fFencePunishLength;
new Handle:g_hFencePunishColorSettings, g_iFencePunishColorSettings;
new Handle:g_hFencePunishColor, g_iFencePunishColor[3];
new Handle:g_hFenceFreeze, g_iFenceFreeze;

new Handle:g_hForceAutoKick;
new Handle:g_hForceTKPunish;
new Handle:g_hFriendlyFire, g_iFriendlyFire;
new Handle:g_hFFReduction;

LoadConVars()
{
	g_fMenuPercent       	= GetConVarFloat(g_hMenuPercent);

	g_iSelfDamage         	= GetConVarInt(g_hSelfDamage);

	g_iRoundLimit         	= GetConVarInt(g_hRoundLimit);
	g_iMoveSurvivors      	= GetConVarInt(g_hMoveSurvivors);
	g_iSaveWeapons        	= GetConVarInt(g_hSaveWeapons);
	g_iRebelAttack        	= GetConVarInt(g_hRebelAttack);

	g_fChangeTeamDelay    	= GetConVarFloat(g_hChangeTeamDelay);
	g_iTeamDiff           	= GetConVarInt(g_hTeamDiff);
	g_bTeamAttack         	= GetConVarBool(g_hTeamAttack);
	g_iNotifyPlayerTeam   	= GetConVarInt(g_hNotifyPlayerTeam);

	g_bAllowMark          	= GetConVarBool(g_hAllowMark);
	g_iMarkLimit          	= GetConVarInt(g_hMarkLimit);
	g_fMarkLife           	= GetConVarFloat(g_hMarkLife);
	g_fMarkLaser          	= GetConVarFloat(g_hMarkLaser);

	g_bImportantMsg        	= GetConVarBool(g_hImportantMsg);
	g_bAllowTeamPrefix    	= GetConVarBool(g_hAllowTeamPrefix);

	g_iFenceType                = GetConVarInt(g_hFenceType);
	g_fFenceHeight              = GetConVarFloat(g_hFenceHeight);
	g_iFenceNotify              = GetConVarInt(g_hFenceNotify);
	g_fFencePunishLength        = GetConVarFloat(g_hFencePunishLength);
	g_iFenceFreeze              = GetConVarInt(g_hFenceFreeze);
	g_iFencePunishColorSettings = GetConVarInt(g_hFencePunishColorSettings);
	GetConVarColorToArray(g_hFencePunishColor, g_iFencePunishColor);

	if (GetConVarBool(g_hForceAutoKick))
		SetConVarIntSilent("mp_autokick", 0);

	if (GetConVarBool(g_hForceTKPunish))
		SetConVarIntSilent("mp_tkpunish", 0);

	g_iFriendlyFire = GetConVarInt(g_hFriendlyFire);
	if (g_iFriendlyFire == 1) {
		SetConVarIntSilent("mp_friendlyfire", 1);
	} else if (g_iFriendlyFire == 2) {
		SetConVarIntSilent("mp_friendlyfire", 0);
	}

	if (g_iEngineVersion == Engine_CSGO && GetConVarBool(g_hFFReduction)) {
		SetConVarIntSilent("ff_damage_reduction_bullets", 		1);
		SetConVarIntSilent("ff_damage_reduction_grenade", 		1);
		SetConVarIntSilent("ff_damage_reduction_grenade_self", 	1);
		SetConVarIntSilent("ff_damage_reduction_other", 		1);
	}
}

SetConVarIntSilent(const String:ConVarName[256], ConVarValue)
{
	new Handle:hHndl = FindConVar(ConVarName);

	if (hHndl != INVALID_HANDLE) {
		if (Convar_HasFlags(hHndl, FCVAR_NOTIFY))
			Convar_RemoveFlags(hHndl, FCVAR_NOTIFY);

		SetConVarInt(hHndl, ConVarValue, true);
	}
}

GetConVarColorToArray(Handle:cvar, color[3])
{
	new String:sValue[9], String:sRed[3], String:sGreen[3], String:sBlue[3];
	GetConVarString(cvar, sValue, sizeof(sValue));
	FormatEx(sRed, sizeof(sRed), "%c%c", sValue[0], sValue[1]);
	FormatEx(sGreen, sizeof(sGreen), "%c%c", sValue[2], sValue[3]);
	FormatEx(sBlue, sizeof(sBlue), "%c%c", sValue[4], sValue[5]);

	StringToIntEx(sRed, color[0], 16);
	StringToIntEx(sGreen, color[1], 16);
	StringToIntEx(sBlue, color[2], 16);
}

HookConVarsChange()
{
	HookConVarChange(g_hMenuPercent             , Hook_ConVarChange);
	HookConVarChange(g_hRoundLimit              , Hook_ConVarChange);
	HookConVarChange(g_hMoveSurvivors           , Hook_ConVarChange);
	HookConVarChange(g_hSaveWeapons             , Hook_ConVarChange);
	HookConVarChange(g_hRebelAttack             , Hook_ConVarChange);
	HookConVarChange(g_hChangeTeamDelay         , Hook_ConVarChange);
	HookConVarChange(g_hTeamDiff                , Hook_ConVarChange);
	HookConVarChange(g_hTeamAttack              , Hook_ConVarChange);
	HookConVarChange(g_hNotifyPlayerTeam        , Hook_ConVarChange);
	HookConVarChange(g_hAllowMark               , Hook_ConVarChange);
	HookConVarChange(g_hMarkLimit               , Hook_ConVarChange);
	HookConVarChange(g_hMarkLife                , Hook_ConVarChange);
	HookConVarChange(g_hMarkLaser               , Hook_ConVarChange);
	HookConVarChange(g_hImportantMsg            , Hook_ConVarChange);
	HookConVarChange(g_hAllowTeamPrefix         , Hook_ConVarChange);
	HookConVarChange(g_hFenceType               , Hook_ConVarChange);
	HookConVarChange(g_hFenceHeight             , Hook_ConVarChange);
	HookConVarChange(g_hFenceNotify             , Hook_ConVarChange);
	HookConVarChange(g_hFencePunishLength       , Hook_ConVarChange);
	HookConVarChange(g_hFenceFreeze             , Hook_ConVarChange);
	HookConVarChange(g_hFencePunishColorSettings, Hook_ConVarChange);
	HookConVarChange(g_hFencePunishColor        , Hook_ConVarChange);
	HookConVarChange(g_hForceAutoKick           , Hook_ConVarChange);
	HookConVarChange(g_hForceTKPunish           , Hook_ConVarChange);
	HookConVarChange(g_hFriendlyFire            , Hook_ConVarChange);
	HookConVarChange(g_hFFReduction           	, Hook_ConVarChange);
}

public Hook_ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	LoadConVars();
}
