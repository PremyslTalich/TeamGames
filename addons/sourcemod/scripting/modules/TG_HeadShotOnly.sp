#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID_FIFTYFIFTY	"HeadShotOnly-FiftyFifty"
#define GAME_ID_REDONLY		"HeadShotOnly-RedOnly"

public Plugin:myinfo =
{
	name = "[TG] HeadShotOnly",
	author = "Raska",
	description = "",
	version = "0.4",
	url = ""
}

new EngineVersion:g_iEngVersion;

public OnPluginStart()
{
	LoadTranslations("TG.HeadShotOnly.phrases");
	g_iEngVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_ID_FIFTYFIFTY);
		TG_RegGame(GAME_ID_REDONLY, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID_FIFTYFIFTY);
	TG_RemoveGame(GAME_ID_REDONLY);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_FIFTYFIFTY)) {
		Format(name, maxSize, "%T", "GameName-FiftyFifty", client);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], iClient)
{
	if ((StrEqual(sID, GAME_ID_FIFTYFIFTY) || StrEqual(sID, GAME_ID_REDONLY)) && type == TG_Game)
		SetWeaponMenu(iClient, sID);
}

public TG_OnGameStart(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID_FIFTYFIFTY) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	decl String:sWeapon[64];

	ResetPack(hDataPack);
	ReadPackString(hDataPack, sWeapon, sizeof(sWeapon));

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerWeaponAndAmmo(i, sWeapon, -1, 500);
	}
}

public Action:TG_OnTraceAttack(bool:ingame, victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (ingame && hitgroup != 1) {
		if ((TG_IsCurrentGameID(GAME_ID_FIFTYFIFTY) && TG_InOppositeTeams(attacker, victim)) || (TG_IsCurrentGameID(GAME_ID_REDONLY) && TG_GetPlayerTeam(attacker) == TG_GetPlayerTeam(victim))) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

SetWeaponMenu(iClient, const String:sID[])
{
	new Handle:hMenu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(hMenu, "%T", "ChooseWeapon", iClient);

	PushMenuString(hMenu, "_GAME_ID_", sID);

	switch (g_iEngVersion) {
		case Engine_CSS: {
			AddMenuItem(hMenu, "weapon_deagle", "Deagle");
			AddMenuItem(hMenu, "weapon_usp", 	"USP");
			AddMenuItem(hMenu, "weapon_glock", 	"Glock-18");
			AddMenuItem(hMenu, "weapon_ak47", 	"AK-47");
			AddMenuItem(hMenu, "weapon_m4a1", 	"M4A1");
		}
		case Engine_CSGO: {
			AddMenuItem(hMenu, "weapon_deagle", 		"Deagle");
			AddMenuItem(hMenu, "weapon_usp_silencer", 	"USP-S");
			AddMenuItem(hMenu, "weapon_glock", 			"Glock-18");
			AddMenuItem(hMenu, "weapon_ak47", 			"AK-47");
			AddMenuItem(hMenu, "weapon_m4a1", 			"M4A4");
		}
	}

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public SetWeaponMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select)
	{
		new String:sKey[64], String:sWeaponName[64], String:sID[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey), _, sWeaponName, 64);

		if (!GetMenuString(hMenu, "_GAME_ID_", sID, sizeof(sID))) {
			return;
		}

		new Handle:hDataPack = CreateDataPack();
		WritePackString(hDataPack, sKey);

		if (StrEqual(sID, GAME_ID_FIFTYFIFTY)) {
			TG_StartGame(iClient, GAME_ID_FIFTYFIFTY, sWeaponName, hDataPack, true);
		} else {
			TG_StartGame(iClient, GAME_ID_REDONLY, sWeaponName, hDataPack, true);
		}
	}
}
