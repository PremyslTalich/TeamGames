#include <sourcemod>
#include <smlib>
#include <teamgames>
#include <menu-stocks>

#define GAME_ID_FIFTYFIFTY	"KnifeFight-FiftyFifty"
#define GAME_ID_REDONLY		"KnifeFight-RedOnly"

public Plugin:myinfo =
{
	name = "[TG] KnifeFight",
	author = "Raska",
	description = "",
	version = "0.5",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.KnifeFight.phrases");
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
		SetHPMenu(iClient, sID);
}

public TG_OnGamePrepare(const String:sID[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(sID, GAME_ID_FIFTYFIFTY) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	ResetPack(DataPack);
	new hp = ReadPackCell(DataPack);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		Client_GiveWeapon(i, "weapon_knife", true);
		SetEntityHealth(i, hp);
	}
}

SetHPMenu(iClient, const String:sID[])
{
	new Handle:hMenu = CreateMenu(SetHPMenu_Handler);

	SetMenuTitle(hMenu, "%T", "ChooseHP", iClient);
	AddMenuItem(hMenu, "35", "35 HP");
	AddMenuItem(hMenu, "100", "100 HP");
	AddMenuItem(hMenu, "300", "300 HP");

	PushMenuString(hMenu, "_GAME_ID_", sID);

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public SetHPMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select)
	{
		new String:info[64], String:sSettings[64], String:sID[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, info, sizeof(info), _, sSettings, 64);

		if (!GetMenuString(hMenu, "_GAME_ID_", sID, sizeof(sID))) {
			return;
		}

		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, StringToInt(info));

		if (StrEqual(sID, GAME_ID_FIFTYFIFTY)) {
			TG_StartGame(iClient, GAME_ID_FIFTYFIFTY, sSettings, hDataPack);
		} else {
			TG_StartGame(iClient, GAME_ID_REDONLY, sSettings, hDataPack);
		}
	}
}