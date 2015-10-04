#include <sourcemod>
#include <smlib>

// TeamGames include
#include <teamgames>

// Just for better work with game id
#define GAME_ID	"SimpleKnifeFight"

public Plugin:myinfo =
{
	// You should name your plugin "[TG] something", so they are grouped together in plugin list
	name = "[TG] SimpleKnifeFight",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	// Everything in TeamGames should be in translation files
	LoadTranslations("TG.SimpleKnifeFight.phrases");
}

// Register the game
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames")) {

		// Check if you are not double registring your game
		if (!TG_IsModuleReged(TG_Game, GAME_ID)) {

			// Register your game as FiftyFifty game
			TG_RegGame(GAME_ID, TG_FiftyFifty);
		}
	}
}

// Remove/UnRegister the game when plugin unloads
public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

// TeamGames core ask for game/menu item name (probably somebody opened TG menu)
public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	// Check if it's your game
	if (type == TG_Game && StrEqual(id, GAME_ID)) {
		Format(name, maxSize, "%T", "GameName", client);
	}
}

// Somebody selected game/menu item in TG menu
public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], client)
{
	// Check if it's your game
	if (type == TG_Game && StrEqual(sID, GAME_ID)) {

		// Start your game
			// This opens game start menu, so player can start or reject the game (don't do game preparation here).
			// Also the forward TG_OnGamePrepare is called one the start menu is confirmed
		TG_StartGame(client, GAME_ID);
	}
}

// Game preparation started
public TG_OnGamePrepare(const String:sID[], client, const String:gameSettings[], Handle:dataPack)
{
	// Check is it's your game
	if (!StrEqual(sID, GAME_ID))
		return;

	// Prepare players for your game
	for (new i = 1; i <= MaxClients; i++)
	{
		// Skip all non-team players (CTs, non-team Ts and Spectator)
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		Client_GiveWeapon(i, "weapon_knife", true);
		SetEntityHealth(i, 35);
	}
}
