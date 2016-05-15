#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID	"PistolZoomBattle"

public Plugin:myinfo =
{
	name = "[TG] PistolZoomBattle",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

new PlayerZoomLevel[MAXPLAYERS + 1];
new EngineVersion:g_engVersion;

public OnPluginStart()
{
	LoadTranslations("TG.PistolZoomBattle.phrases");
	g_engVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames")) {
		TG_RegGame(GAME_ID, TG_TeamGame | TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
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

	SetWeaponMenu(client, gameType);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	decl String:weapon[64];

	ResetPack(dataPack);
	ReadPackString(dataPack, weapon, sizeof(weapon));

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerWeaponAndAmmo(i, weapon, -1, 900);
		PlayerZoomLevel[i] = 90;
		SetEntProp(i, Prop_Send, "m_iFOV", PlayerZoomLevel[i]);
		SetEntProp(i, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[i]);
		TG_AttachPlayerHealthBar(i);
	}

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsPlayerRedOrBlue(client)) {
		PlayerZoomLevel[client] -= 10;

		if (PlayerZoomLevel[client] < 10)
			PlayerZoomLevel[client] = 10;

		SetEntProp(client, Prop_Send, "m_iFOV", PlayerZoomLevel[client]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[client]);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!Client_IsValid(client, true))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(client)) {
		if (PlayerZoomLevel[client] <= 10)
			return Plugin_Continue;

		PlayerZoomLevel[client] += 10;

		if (PlayerZoomLevel[client] > 90)
			PlayerZoomLevel[client] = 90;

		SetEntProp(client, Prop_Send, "m_iFOV", PlayerZoomLevel[client]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[client]);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!Client_IsValid(client, true))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(client)) {
		PlayerZoomLevel[client] = 90;
		SetEntProp(client, Prop_Send, "m_iFOV", PlayerZoomLevel[client]);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", PlayerZoomLevel[client]);
	}

	return Plugin_Continue;
}

public TG_OnPlayerLeaveGame(const String:id[], TG_GameType:gameType, client, TG_Team:team, TG_PlayerTrigger:trigger)
{
	if (StrEqual(id, GAME_ID)) {
		if (TG_IsTeamRedOrBlue(team) && Client_IsIngame(client)) {
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
			SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
		}
	}
}

SetWeaponMenu(client, TG_GameType:gameType)
{
	new Handle:menu = CreateMenu(SetWeaponMenu_Handler);
	SetMenuTitle(menu, "%T", "ChooseWeapon", client);
	PushMenuCell(menu, "_GAME_TYPE_", _:gameType);

	switch (g_engVersion) {
		case Engine_CSS: {
			AddMenuItem(menu, "weapon_deagle", 		"Deagle");
			AddMenuItem(menu, "weapon_usp", 		"USP");
			AddMenuItem(menu, "weapon_glock", 		"Glock-18");
			AddMenuItem(menu, "weapon_p228", 		"p228");
			AddMenuItem(menu, "weapon_fiveseven", 	"Five-seveN");
		}
		case Engine_CSGO: {
			AddMenuItem(menu, "weapon_deagle", 			"Deagle");
			AddMenuItem(menu, "weapon_usp_silencer", 	"USP-S");
			AddMenuItem(menu, "weapon_glock", 			"Glock-18");
			AddMenuItem(menu, "weapon_p250", 			"p250");
			AddMenuItem(menu, "weapon_tec9", 			"Tec-9");
			AddMenuItem(menu, "weapon_fiveseven", 		"Five-seveN");
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public SetWeaponMenu_Handler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select) {
		new String:info[64], String:weaponName[TG_GAME_SETTINGS_LENGTH];
		GetMenuItem(menu, key, info, sizeof(info), _, weaponName, sizeof(weaponName));

		new TG_GameType:gameType = TG_GameType:GetMenuCell(menu, "_GAME_TYPE_");

		new Handle:dataPack = CreateDataPack();
		WritePackString(dataPack, info);

		TG_StartGame(client, GAME_ID, gameType, weaponName, dataPack, true);
	}
}
