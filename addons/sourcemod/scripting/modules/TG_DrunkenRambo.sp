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
	version = "0.9",
	url = ""
}

new String:g_overlay[PLATFORM_MAX_PATH];
new String:g_skin[PLATFORM_MAX_PATH];
new String:g_originalSkin[PLATFORM_MAX_PATH];
new Handle:g_reffilAmmo;
new g_rambo, g_fog;
new EngineVersion:g_engVersion;

new Handle:g_fogEnable;
new Handle:g_fogCol, String:g_fogColor[18];
new Handle:g_fogDist, Float:g_fogDistance;

public OnPluginStart()
{
	LoadTranslations("TG.DrunkenRambo.phrases");
	g_engVersion = GetEngineVersion();

	g_fogEnable =  CreateConVar("tgm_drunkenrambo_fog_enable", 	"1", 		"Enable fog for rambo? (1 = yes, 0 = no)");
	g_fogCol =     CreateConVar("tgm_drunkenrambo_fog_color", 	"255 0 0", 	"RGB color code of the fog.");
	g_fogDist =    CreateConVar("tgm_drunkenrambo_fog_distance",  "448.0", 	"Distance from rambo, where the \"fog wall\" starts.", _, true, 64.0);

	HookConVarChange(g_fogCol, OnConVarChanged);
	HookConVarChange(g_fogDist, OnConVarChanged);

	AutoExecConfig(_, _, "sourcemod/teamgames");
}

public OnConVarChanged(Handle:conVar, const String:oldValue[], const String:newValue[])
{
	LoadConVars();
}

public OnConfigsExecuted()
{
	LoadConVars();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames"))
		TG_RegGame(GAME_ID, TG_RedOnly);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_OnDownloadFile(String:file[], String:prefixName[], Handle:args, &bool:known)
{
	if (StrEqual(prefixName, DTC_PREFIX_OVERLAY, false)) {
		ReplaceStringEx(file, PLATFORM_MAX_PATH, "materials/", "");
		PrecacheDecal(file, true);
		strcopy(g_overlay, sizeof(g_overlay), file);
		known = true;
	} else if (StrEqual(prefixName, DTC_PREFIX_SKIN, false)) {
		PrecacheModel(file);
		strcopy(g_skin, sizeof(g_skin), file);
		known = true;
	}
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], nameSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	Format(name, nameSize, "%T", "GameName", client);
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	TG_ShowPlayerSelectMenu(client, SelectPlayerHandeler, true, false, true, gameType, "%T", "ChooseRambo", client);
}

public SelectPlayerHandeler(activator, client, bool:isRandom, any:gameType)
{
	if (Client_IsIngame(client)) {
		new Handle:dataPack = CreateDataPack();
		WritePackCell(dataPack, client);

		TG_StartGame(activator, GAME_ID, TG_GameType:gameType, "", dataPack, true);
	}
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	ResetPack(dataPack);
	g_rambo = ReadPackCell(dataPack);

	g_fog = -1;
	if (GetConVarBool(g_fogEnable)) {
		g_fog = CreateFog();
	}

	if (g_reffilAmmo != INVALID_HANDLE) {
		KillTimer(g_reffilAmmo);
	}
	g_reffilAmmo = CreateTimer(7.0, Timer_RefillAmmo, _, TIMER_REPEAT);

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_GetPlayerTeam(i) != TG_RedTeam)
			continue;

		if (i == g_rambo) {
			SetEntityHealth(i, 10);
			SetFovAndOverlay(i, 120, g_overlay);

			SetVariantString("TeamGames_DrunkenRambo_Fog");
			AcceptEntityInput(i, "SetFogController");

			if (g_skin[0] != '\0' && IsModelPrecached(g_skin)) {
				GetClientModel(i, g_originalSkin, sizeof(g_originalSkin));
				SetEntityModel(i, g_skin);
			}

			switch (g_engVersion) {
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

public TG_OnPlayerLeaveGame(const String:id[], TG_GameType:gameType, client, TG_Team:team, TG_PlayerTrigger:trigger)
{
	if (!StrEqual(id, GAME_ID))
		return;

	if (client == g_rambo) {
		new Handle:winners = CreateArray();

		for (new i = 0; i < MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(winners, i);
			}
		}

		TG_StopGame(TG_RedTeam, winners);
	} else if (team == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:winners = CreateArray();
		PushArrayCell(winners, g_rambo);

		TG_StopGame(TG_RedTeam, winners);
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	if (g_skin[0] != '\0' && IsModelPrecached(g_skin) && Client_IsIngame(g_rambo) && IsPlayerAlive(g_rambo)) {
		SetEntityModel(g_rambo, g_originalSkin);
	}

	if (IsValidEntity(g_fog)) {
		AcceptEntityInput(g_fog, "kill");

		new fog = FindEntityByClassname(-1, "env_fog_controller");
		if (fog != -1 && Client_IsIngame(g_rambo)) {
			new String:sTargetName[64];
			GetEntPropString(fog, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));

			if (sTargetName[0] == '\0') {
				strcopy(sTargetName, sizeof(sTargetName), "TeamGames_DrunkenRambo_OriginalFog");
				DispatchKeyValue(fog, "targetname", sTargetName);
			}

			SetVariantString(sTargetName);
			AcceptEntityInput(g_rambo, "SetFogController");
		}
	}

	g_fog = -1;

	if (g_reffilAmmo != INVALID_HANDLE) {
		KillTimer(g_reffilAmmo);
	}
	g_reffilAmmo = INVALID_HANDLE;

	SetFovAndOverlay(g_rambo, 90, "");
	g_rambo = 0;
}

public Action:Timer_RefillAmmo(Handle:timer)
{
	if (!TG_IsCurrentGameID(GAME_ID) || !Client_IsIngame(g_rambo)) {
		return Plugin_Stop;
	}

	new String:weapon[64];
	new weaponEntity = Client_GetActiveWeaponName(g_rambo, weapon, sizeof(weapon));

	if (weaponEntity != INVALID_ENT_REFERENCE) {
		if (g_engVersion == Engine_CSS && StrEqual(weapon, "weapon_m249")) {
			SetPlayerWeaponAmmo(g_rambo, weaponEntity, 100, 0);
		} else if (g_engVersion == Engine_CSGO && StrEqual(weapon, "weapon_m249")) {
			SetPlayerWeaponAmmo(g_rambo, weaponEntity, 100, 0);
		}
	}

	return Plugin_Continue;
}

CreateFog()
{
	new fog = CreateEntityByName("env_fog_controller");

	if (fog != -1) {
		DispatchKeyValue(fog, "targetname", "TeamGames_DrunkenRambo_Fog");
		DispatchKeyValue(fog, "fogenable", "1");
		DispatchKeyValue(fog, "fogblend", "0");
		DispatchKeyValue(fog, "fogcolor", g_fogColor);
		DispatchKeyValue(fog, "fogcolor2", g_fogColor);
		DispatchKeyValueFloat(fog, "fogstart", 64.0);
		DispatchKeyValueFloat(fog, "fogend", g_fogDistance);
		DispatchKeyValueFloat(fog, "fogmaxdensity", 1.0);
		DispatchSpawn(fog);

		AcceptEntityInput(fog, "TurnOn");
	}

	return fog;
}

SetFovAndOverlay(client, fov, const String:overlay[])
{
	if (!Client_IsIngame(client))
		return;

	SetEntProp(client, Prop_Send, "m_iFOV", fov);
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", fov);

	if (overlay[0] == '\0' || IsDecalPrecached(overlay)) {
		Client_SetScreenOverlay(client, overlay);
	}
}

LoadConVars()
{
	g_fogDistance = GetConVarFloat(g_fogDist);
	GetConVarString(g_fogCol, g_fogColor, sizeof(g_fogColor));
}
