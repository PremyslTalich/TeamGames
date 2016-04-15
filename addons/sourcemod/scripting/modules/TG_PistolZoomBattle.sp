#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID_TEAMGAME	"PistolZoomBattle-TeamGame"
#define GAME_ID_REDONLY		"PistolZoomBattle-RedOnly"

public Plugin:myinfo =
{
	name = "[TG] PistolZoomBattle",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

new PlayerZoomLevel[MAXPLAYERS + 1];
new EngineVersion:g_iEngVersion;

public OnPluginStart()
{
	LoadTranslations("TG.PistolZoomBattle.phrases");
	g_iEngVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_ID_TEAMGAME);
		TG_RegGame(GAME_ID_REDONLY, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID_TEAMGAME);
	TG_RemoveGame(GAME_ID_REDONLY);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_TEAMGAME)) {
		Format(name, maxSize, "%T", "GameName-TeamGame", client);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], iClient)
{
	if ((StrEqual(sID, GAME_ID_TEAMGAME) || StrEqual(sID, GAME_ID_REDONLY)) && type == TG_Game)
		SetWeaponMenu(iClient, sID);
}

public TG_OnGameStart(const String:sID[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(sID, GAME_ID_TEAMGAME) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	decl String:sWeapon[64];

	ResetPack(DataPack);
	ReadPackString(DataPack, sWeapon, sizeof(sWeapon));

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerWeaponAndAmmo(i, sWeapon, -1, 900);
		PlayerZoomLevel[i] = 90;
		SetEntProp(i, Prop_Send, "m_iFOV", PlayerZoomLevel[i]);
		SetEntProp(i, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[i]);
	}

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	return;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID_TEAMGAME) && !TG_IsCurrentGameID(GAME_ID_REDONLY))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsPlayerRedOrBlue(iClient)) {
		PlayerZoomLevel[iClient] -= 10;

		if (PlayerZoomLevel[iClient] < 10)
			PlayerZoomLevel[iClient] = 10;

		SetEntProp(iClient, Prop_Send, "m_iFOV", PlayerZoomLevel[iClient]);
		SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[iClient]);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID_TEAMGAME) && !TG_IsCurrentGameID(GAME_ID_REDONLY))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!Client_IsValid(iClient, true))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(iClient)) {
		if (PlayerZoomLevel[iClient] <= 10)
			return Plugin_Continue;

		PlayerZoomLevel[iClient] += 10;

		if (PlayerZoomLevel[iClient] > 90)
			PlayerZoomLevel[iClient] = 90;

		SetEntProp(iClient, Prop_Send, "m_iFOV", PlayerZoomLevel[iClient]);
		SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[iClient]);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID_TEAMGAME) && !TG_IsCurrentGameID(GAME_ID_REDONLY))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!Client_IsValid(iClient, true))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(iClient)) {
		PlayerZoomLevel[iClient] = 90;
		SetEntProp(iClient, Prop_Send, "m_iFOV", PlayerZoomLevel[iClient]);
		SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[iClient]);
	}

	return Plugin_Continue;
}

public TG_OnPlayerLeaveGame(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (StrEqual(sID, GAME_ID_TEAMGAME) || StrEqual(sID, GAME_ID_REDONLY)) {
		if (TG_IsTeamRedOrBlue(iTeam) && Client_IsIngame(iClient)) {
			SetEntProp(iClient, Prop_Send, "m_iFOV", 90);
			SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", 90);
		}
	}
}

SetWeaponMenu(iClient, const String:sID[])
{
	new Handle:hMenu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(hMenu, "%T", "ChooseWeapon", iClient);

	PushMenuString(hMenu, "_GAME_ID_", sID);

	switch (g_iEngVersion) {
		case Engine_CSS: {
			AddMenuItem(hMenu, "weapon_deagle", 	"Deagle");
			AddMenuItem(hMenu, "weapon_usp", 		"USP");
			AddMenuItem(hMenu, "weapon_glock", 		"Glock-18");
			AddMenuItem(hMenu, "weapon_p228", 		"p228");
			AddMenuItem(hMenu, "weapon_fiveseven", 	"Five-seveN");
		}
		case Engine_CSGO: {
			AddMenuItem(hMenu, "weapon_deagle", 		"Deagle");
			AddMenuItem(hMenu, "weapon_usp_silencer", 	"USP-S");
			AddMenuItem(hMenu, "weapon_glock", 			"Glock-18");
			AddMenuItem(hMenu, "weapon_p250", 			"p250");
			AddMenuItem(hMenu, "weapon_tec9", 			"Tec-9");
			AddMenuItem(hMenu, "weapon_fiveseven", 		"Five-seveN");
		}
	}

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public SetWeaponMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		new String:sKey[64], String:sWeaponName[64], String:sID[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey), _, sWeaponName, 64);

		if (!GetMenuString(hMenu, "_GAME_ID_", sID, sizeof(sID))) {
			return;
		}

		new Handle:hDataPack = CreateDataPack();
		WritePackString(hDataPack, sKey);

		if (StrEqual(sID, GAME_ID_TEAMGAME)) {
			TG_StartGame(iClient, GAME_ID_TEAMGAME, sWeaponName, hDataPack, true);
		} else {
			TG_StartGame(iClient, GAME_ID_REDONLY, sWeaponName, hDataPack, true);
		}
	}
}
