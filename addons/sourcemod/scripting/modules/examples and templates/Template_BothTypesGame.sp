#include <sourcemod>
#include <teamgames>

#define GAME_FF	"GAME_ID_FIFTYFIFTY"
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
	if (StrEqual(sName, "TeamGames") {
		TG_RegGame(GAME_FF);
		TG_RegGame(GAME_RO, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_FF);
	TG_RemoveGame(GAME_RO);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type == TG_Game) {
		if (StrEqual(id, GAME_FF))
			Format(name, maxSize, "%T", "GameName-FiftyFifty", client);

		if (StrEqual(id, GAME_RO))
			Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], client)
{
	if (type == TG_Game && (StrEqual(id, GAME_FF) || StrEqual(id, GAME_RO)))
		TG_StartGame(client, id);
}

public TG_OnGamePrepare(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (StrEqual(id, GAME_FF) || StrEqual(id, GAME_RO)) {
		// code here
	}

}

public TG_OnGameStart(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (StrEqual(id, GAME_FF)) {
		// code here
	}

	if (StrEqual(id, GAME_RO)) {
		// code here
	}
}

public TG_OnGameEnd(const String:id[], TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (StrEqual(id, GAME_FF)) {
		// code here
	}

	if (StrEqual(id, GAME_RO)) {
		// code here
	}
}
