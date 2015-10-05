#include <sourcemod>
#include <teamgames>

#define GAME_ID	"GAME_ID"

public Plugin:myinfo =
{
	name = "[TG] ",
	author = "",
	description = "",
	version = "",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.GAME.phrases");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames") && !TG_IsModuleReged(TG_Game, GAME_ID))
		TG_RegGame(GAME_ID);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;
	
	Format(name, maxSize, "%T", "GameName", client);
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], client)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;
	
	TG_StartGame(client, GAME_ID);
}

public TG_OnGamePrepare(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	// code here
}

public TG_OnGameStart(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	// code here
}

public TG_OnGameEnd(const String:id[], TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	// code here
}
