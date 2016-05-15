#include <sourcemod>
#include <cstrike>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID "ReloadBattle"

new String:g_weapon[64];
new EngineVersion:g_engVersion;

public Plugin:myinfo =
{
	name = "[TG] ReloadBattle",
	author = "Raska",
	description = "",
	version = "0.5",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.ReloadBattle.phrases");
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

	strcopy(g_weapon, sizeof(g_weapon), "");
	SetWeaponMenu(client, gameType);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	new String:weapon[64];

	ResetPack(dataPack);
	ReadPackString(dataPack, weapon, sizeof(weapon));

	strcopy(g_weapon, sizeof(g_weapon), weapon);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerWeaponAndAmmo(i, weapon, 0, 1);
		TG_AttachPlayerHealthBar(i);
	}

	HookEvent("weapon_fire", Event_WeaponFire);
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsPlayerRedOrBlue(client)) {
		decl String:weaponName[64];
		GetEventString(event, "weapon", weaponName, sizeof(weaponName));

		if (StrContains(g_weapon, weaponName) != -1) {
			RequestFrame(Frame_SetPlayerAmmo, client);
		}
	}

	return Plugin_Continue;
}

public Frame_SetPlayerAmmo(any:client)
{
	SetPlayerWeaponAmmo(client, Client_GetWeapon(client, g_weapon), 0, 1);
}

SetWeaponMenu(client, TG_GameType:gameType)
{
	new Handle:menu = CreateMenu(SetWeaponMenu_Handler);
	SetMenuTitle(menu, "%T", "ChooseWeapon", client);
	PushMenuCell(menu, "_GAME_TYPE_", _:gameType);

	switch (g_engVersion) {
		case Engine_CSS: {
			AddMenuItem(menu, "weapon_deagle",  "Deagle");
			AddMenuItem(menu, "weapon_p228", 	"p228");
			AddMenuItem(menu, "weapon_ak47", 	"AK-47");
			AddMenuItem(menu, "weapon_m4a1", 	"M4A1");
			AddMenuItem(menu, "weapon_scout", 	"Scout");
			AddMenuItem(menu, "weapon_m249", 	"Machine gun");
		}
		case Engine_CSGO: {
			AddMenuItem(menu, "weapon_deagle",  "Deagle");
			AddMenuItem(menu, "weapon_p250", 	"p250");
			AddMenuItem(menu, "weapon_ak47", 	"AK-47");
			AddMenuItem(menu, "weapon_m4a1", 	"M4A4");
			AddMenuItem(menu, "weapon_ssg08", 	"Scout");
			AddMenuItem(menu, "weapon_negev", 	"Negev");
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
