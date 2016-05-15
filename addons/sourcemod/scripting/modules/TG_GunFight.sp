#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID		"GunFight"

public Plugin:myinfo =
{
	name = "[TG] GunFight",
	author = "Raska",
	description = "",
	version = "0.4",
	url = ""
}

new EngineVersion:g_engVersion;

public OnPluginStart()
{
	LoadTranslations("TG.GunFight.phrases");
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

		GivePlayerItem(i, "weapon_knife");
		GivePlayerWeaponAndAmmo(i, weapon);
		TG_AttachPlayerHealthBar(i);
	}
}

SetWeaponMenu(client, TG_GameType:gameType)
{
	new Handle:menu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(menu, "%T", "ChooseWeapon", client);
	PushMenuCell(menu, "_GAME_TYPE_", _:gameType);

	switch (g_engVersion) {
		case Engine_CSS: {
			AddMenuItem(menu, "weapon_deagle",	"Deagle");
			AddMenuItem(menu, "weapon_usp", 	"USP");
			AddMenuItem(menu, "weapon_glock", 	"Glock-18");
			AddMenuItem(menu, "weapon_ak47", 	"AK-47");
			AddMenuItem(menu, "weapon_m4a1", 	"M4A1");
		}
		case Engine_CSGO: {
			AddMenuItem(menu, "weapon_deagle", 			"Deagle");
			AddMenuItem(menu, "weapon_p250", 			"P250");
			AddMenuItem(menu, "weapon_mp7", 			"MP7");
			AddMenuItem(menu, "weapon_ak47", 			"AK-47");
			AddMenuItem(menu, "weapon_m4a1_silencer", 	"M4A1-S");
			AddMenuItem(menu, "weapon_nova", 			"Nova");
			AddMenuItem(menu, "weapon_m249", 			"M249 Para");
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public SetWeaponMenu_Handler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select) {
		new String:info[64], String:weapon[TG_GAME_SETTINGS_LENGTH];
		GetMenuItem(menu, key, info, sizeof(info), _, weapon, sizeof(weapon));

		new TG_GameType:gameType = TG_GameType:GetMenuCell(menu, "_GAME_TYPE_");

		new Handle:dataPack = CreateDataPack();
		WritePackString(dataPack, info);

		TG_StartGame(client, GAME_ID, gameType, weapon, dataPack, true);
	}
}
