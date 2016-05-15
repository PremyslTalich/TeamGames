#include <sourcemod>
#include <smlib>
#include <teamgames>
#include <menu-stocks>

#define GAME_ID	"KnifeFight"

public Plugin:myinfo =
{
	name = "[TG] KnifeFight",
	author = "Raska",
	description = "",
	version = "0.7",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.KnifeFight.phrases");
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

	SetHPMenu(client, gameType);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	ResetPack(dataPack);
	new hp = ReadPackCell(dataPack);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		Client_GiveWeapon(i, "weapon_knife", true);
		SetEntityHealth(i, hp);

		TG_AttachPlayerHealthBar(i, hp);
	}
}

SetHPMenu(client, TG_GameType:gameType)
{
	new Handle:menu = CreateMenu(SetHPMenu_Handler);

	SetMenuTitle(menu, "%T", "ChooseHP", client);
	AddMenuItem(menu, "35", "35 HP");
	AddMenuItem(menu, "100", "100 HP");
	AddMenuItem(menu, "300", "300 HP");

	PushMenuCell(menu, "_GAME_TYPE_", _:gameType);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public SetHPMenu_Handler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select) {
		new String:info[64], String:settings[TG_GAME_SETTINGS_LENGTH];
		GetMenuItem(menu, key, info, sizeof(info), _, settings, sizeof(settings));

		new TG_GameType:gameType = TG_GameType:GetMenuCell(menu, "_GAME_TYPE_");

		new Handle:dataPack = CreateDataPack();
		WritePackCell(dataPack, StringToInt(info));

		TG_StartGame(client, GAME_ID, gameType, settings, dataPack);
	}
}