#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define GAME_ID					"DrunkenRambo"
#define DTC_PREFIX_OVERLAY		"DrunkenRambo-Overlay"
#define DTC_PREFIX_SKIN			"DrunkenRambo-Skin"

public Plugin:myinfo =
{
	name = "[TG] DrunkenRambo",
	author = "Raska",
	description = "",
	version = "0.7",
	url = ""
}

new String:g_sOverlay[PLATFORM_MAX_PATH];
new String:g_sSkin[PLATFORM_MAX_PATH];
new String:g_sOriginalSkin[PLATFORM_MAX_PATH];
new Handle:g_hReffilAmmo;
new g_iRambo, g_iFog;
new EngineVersion:g_iEngVersion;

new Handle:g_hFogEnable, bool:g_bFogEnable;
new Handle:g_hFogColor, String:g_sFogColor[18];
new Handle:g_hFogDistance, Float:g_fFogDistance;

public OnPluginStart()
{
	LoadTranslations("TG.DrunkenRambo.phrases");
	g_iEngVersion = GetEngineVersion();

	g_hFogEnable = CreateConVar("tg_dr_fog_enable", "1", "Enable fog for rambo? (1 = yes, 0 = no)");
	g_hFogColor = CreateConVar("tg_dr_fog_color", "255 0 0", "RGB color code of the fog.");
	g_hFogDistance = CreateConVar("tg_dr_fog_distance", "448.0", "Distance from rambo, where the \"fog wall\" starts.", _, true, 64.0);

	HookConVarChange(g_hFogEnable, OnConVarChanged);
	HookConVarChange(g_hFogColor, OnConVarChanged);
	HookConVarChange(g_hFogDistance, OnConVarChanged);
}

public OnConVarChanged(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	LoadConVars();
}

public OnConfigsExecuted()
{
	LoadConVars();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames") && !TG_IsModuleReged(TG_Game, GAME_ID))
		TG_RegGame(GAME_ID, TG_RedOnly);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_OnDownloadFile(String:sFile[], String:sPrefixName[], Handle:hArgs, &bool:bKnown)
{
	if (StrEqual(sPrefixName, DTC_PREFIX_OVERLAY, false)) {
		ReplaceStringEx(sFile, PLATFORM_MAX_PATH, "materials/", "");
		PrecacheDecal(sFile, true);
		strcopy(g_sOverlay, sizeof(g_sOverlay), sFile);
		bKnown = true;
	} else if (StrEqual(sPrefixName, DTC_PREFIX_SKIN, false)) {
		PrecacheModel(sFile);
		strcopy(g_sSkin, sizeof(g_sSkin), sFile);
		bKnown = true;
	}
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type == TG_Game && StrEqual(id, GAME_ID))
		Format(name, maxSize, "%T", "GameName", client);
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], iClient)
{
	if (type == TG_Game && StrEqual(sID, GAME_ID))
		TG_ShowPlayerSelectMenu(iClient, TG_RedTeam, SelectPlayerHandeler, "%T", "ChooseRambo", iClient);
}

public SelectPlayerHandeler(iActivator, iClient, bool:bIsRandom)
{
	if (Client_IsIngame(iClient)) {
		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iClient);

		TG_StartGame(iActivator, GAME_ID, "", hDataPack, true);
	}
}

public TG_OnGamePrepare(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID, true))
		return;

	ResetPack(hDataPack);
	g_iRambo = ReadPackCell(hDataPack);

	g_iFog = -1;
	if (g_bFogEnable) {
		g_iFog = CreateFog();
	}

	if (g_hReffilAmmo != INVALID_HANDLE) {
		KillTimer(g_hReffilAmmo);
	}
	g_hReffilAmmo = CreateTimer(7.0, Timer_RefillAmmo, _, TIMER_REPEAT);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (TG_GetPlayerTeam(i) != TG_RedTeam)
			continue;

		if (i == g_iRambo) {
			SetEntityHealth(i, 10);
			SetFovAndOverlay(i, 120, g_sOverlay);

			SetVariantString("TeamGames_DrunkenRambo_Fog");
			AcceptEntityInput(i, "SetFogController");

			if (g_sSkin[0] != '\0' && IsModelPrecached(g_sSkin)) {
				GetClientModel(i, g_sOriginalSkin, sizeof(g_sOriginalSkin));
				SetEntityModel(i, g_sSkin);
			}

			switch (g_iEngVersion) {
				case Engine_CSS: {
					GivePlayerWeaponAndAmmo(i, "weapon_m249", 100, 0);
				}
				case Engine_CSGO: {
					GivePlayerWeaponAndAmmo(i, "weapon_m249", 100, 0);
				}
			}
		} else {
			GivePlayerItem(i, "weapon_knife");

			if (GetRandomInt(1, 5) == 1) {
				GivePlayerItem(i, "weapon_taser");
				SetEntityHealth(i, 50);
			} else {
				SetEntityHealth(i, 100);
			}
		}
	}
}

public TG_OnPlayerLeaveGame(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (!StrEqual(sID, GAME_ID))
		return;

	if (iClient == g_iRambo) {
		new Handle:hWinners = CreateArray();

		for (new i = 0; i < MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(hWinners, i);
			}
		}

		TG_StopGame(TG_RedTeam, hWinners);
	} else if (iTeam == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:hWinner = CreateArray();
		PushArrayCell(hWinner, g_iRambo);

		TG_StopGame(TG_RedTeam, hWinner);
	}
}

public TG_OnGameEnd(const String:sID[], TG_Team:iTeam, iWinners[], iWinnersCount, Handle:DataPack)
{
	if (StrEqual(sID, GAME_ID)) {
		if (g_sSkin[0] != '\0' && IsModelPrecached(g_sSkin) && Client_IsIngame(g_iRambo) && IsPlayerAlive(g_iRambo)) {
			SetEntityModel(g_iRambo, g_sOriginalSkin);
		}

		if (IsValidEntity(g_iFog)) {
			AcceptEntityInput(g_iFog, "kill");

			new iFog = FindEntityByClassname(-1, "env_fog_controller");
			if (iFog != -1 && Client_IsIngame(g_iRambo)) {
				new String:sTargetName[64];
				GetEntPropString(iFog, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));

				if (sTargetName[0] == '\0') {
					strcopy(sTargetName, sizeof(sTargetName), "TeamGames_DrunkenRambo_OriginalFog");
					DispatchKeyValue(iFog, "targetname", sTargetName);
				}

				SetVariantString(sTargetName);
				AcceptEntityInput(g_iRambo, "SetFogController");
			}
		}
		g_iFog = -1;

		if (g_hReffilAmmo != INVALID_HANDLE) {
			KillTimer(g_hReffilAmmo);
		}
		g_hReffilAmmo = INVALID_HANDLE;

		SetFovAndOverlay(g_iRambo, 90, "");
		g_iRambo = 0;
	}
}

public Action:Timer_RefillAmmo(Handle:hTimer)
{
	if (!TG_IsCurrentGameID(GAME_ID) || !Client_IsIngame(g_iRambo)) {
		return Plugin_Stop;
	}

	new String:sWeapon[64];
	new iWeapon = Client_GetActiveWeaponName(g_iRambo, sWeapon, sizeof(sWeapon));

	if (iWeapon != INVALID_ENT_REFERENCE) {
		if (g_iEngVersion == Engine_CSS && StrEqual(sWeapon, "weapon_m249")) {
			SetPlayerWeaponAmmo(g_iRambo, iWeapon, 100, 0);
		} else if (g_iEngVersion == Engine_CSGO && StrEqual(sWeapon, "weapon_m249")) {
			SetPlayerWeaponAmmo(g_iRambo, iWeapon, 100, 0);
		}
	}

	return Plugin_Continue;
}

CreateFog()
{
	new iFog = CreateEntityByName("env_fog_controller");

	if (iFog != -1) {
		DispatchKeyValue(iFog, "targetname", "TeamGames_DrunkenRambo_Fog");
		DispatchKeyValue(iFog, "fogenable", "1");
		DispatchKeyValue(iFog, "fogblend", "0");
		DispatchKeyValue(iFog, "fogcolor", g_sFogColor);
		DispatchKeyValue(iFog, "fogcolor2", g_sFogColor);
		DispatchKeyValueFloat(iFog, "fogstart", 64.0);
		DispatchKeyValueFloat(iFog, "fogend", g_fFogDistance);
		DispatchKeyValueFloat(iFog, "fogmaxdensity", 1.0);
		DispatchSpawn(iFog);

		AcceptEntityInput(iFog, "TurnOn");
	}

	return iFog;
}

SetFovAndOverlay(iClient, iFov, const String:sOverlay[])
{
	if (!Client_IsIngame(iClient))
		return;

	SetEntProp(iClient, Prop_Send, "m_iFOV", iFov);
	SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", iFov);

	if (sOverlay[0] == '\0' || IsDecalPrecached(sOverlay)) {
		Client_SetScreenOverlay(iClient, sOverlay);
	}
}

LoadConVars()
{
	g_bFogEnable = GetConVarBool(g_hFogEnable);
	g_fFogDistance = GetConVarFloat(g_hFogDistance);
	GetConVarString(g_hFogColor, g_sFogColor, sizeof(g_sFogColor));
}
