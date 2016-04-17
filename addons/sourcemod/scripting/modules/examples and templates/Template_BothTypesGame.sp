#include <sourcemod>
#include <teamgames>

#define GAME_TG	"GAME_ID_TEAMGAME"
#define GAME_RO	"GAME_ID_REDONLY"

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
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_TG, TG_TeamGame);
		TG_RegGame(GAME_RO, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_TG);
	TG_RemoveGame(GAME_RO);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type == TG_Game) {
		if (StrEqual(id, GAME_TG))
			Format(name, maxSize, "%T", "GameName-TeamGame", client);

		if (StrEqual(id, GAME_RO))
			Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], client)
{
	if (type == TG_Game && (StrEqual(id, GAME_TG) || StrEqual(id, GAME_RO)))
		TG_StartGame(client, id);
}

public TG_OnGamePrepare(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (StrEqual(id, GAME_TG) || StrEqual(id, GAME_RO)) {
		// code here
	}

}

public TG_OnGameStart(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (StrEqual(id, GAME_TG)) {
		// code here
	}

	if (StrEqual(id, GAME_RO)) {
		// code here
	}
}

public TG_OnGameEnd(const String:id[], TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (StrEqual(id, GAME_TG)) {
		// code here
	}

	if (StrEqual(id, GAME_RO)) {
		// code here
	}
}
