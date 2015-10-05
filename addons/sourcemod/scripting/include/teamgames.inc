#if defined _teamgames_included_
  #endinput
#endif
#define _teamgames_included_

#include <menus>

public SharedPlugin:__pl_teamgames =
{
	name = "TeamGames",
	file = "TeamGames.smx",
	required = 1
};

public __pl_teamgames_SetNTVOptional()
{
	// MarkNativeAsOptional("TG_GetPlayerTeam");
	// .
	// .
	// .
}

//------------------------------------------------------------------------------------------------
// Defines
#define TG_MODULE_ID_LENGTH 	64
#define TG_MODULE_NAME_LENGTH 	64
#define TG_GAME_SETTINGS_LENGTH 64

//------------------------------------------------------------------------------------------------
// Enums

/**
 * TeamGames teams
 */
enum TG_Team
{
	TG_ErrorTeam = -1, // CTs, dead Ts, etc...
	TG_NoneTeam, // Ts who are not in TeamGames team
	TG_RedTeam, // Ts who are in TeamGames Red team
	TG_BlueTeam // Ts who are in TeamGames Blue team
};

/**
 * TeamGames game status
 */
enum TG_GameProgress
{
	TG_NoGame = 0, // There is no game running or in preparation. TG_GetCurrentGameID and TG_GetGameName("CurrentGameId") returns "Core_NoGame"
	TG_InPreparation, // The game is in preparation
	TG_InProgress // The game is running
};

/**
 * TeamGames game type
 */
enum TG_GameType
{
	TG_All_ = -1, // do not use this (Only core use this "type")
	TG_FiftyFifty, // FiftyFifty game type: RedTeam vs. BlueTeam (by default both with the same number of players)
	TG_RedOnly // RedOnly game type: only red players are allowed
};

/**
 * TeamGames module type
 */
enum TG_ModuleType
{
	TG_Game = 0, // Game module
	TG_MenuItem // Menu item (appears in TeamGames main menu)
};

/**
 * TeamGames menu item status
 */
enum TG_MenuItemStatus
{
	TG_Active = 0, // Menu item is in menu and selecable
	TG_Inactive, // Menu item is in menu, but not selectable
	TG_Disabled // Menu item is not in menu
};

/**
 * TeamGames player triggers/reasons of leaving game or emptying team
 */
enum TG_PlayerTrigger
{
	TG_Death, // Player died
	TG_Rebel, // Player became a rebel
	TG_ChangeTGTeam, // Player changed TeamGames team
	TG_GameEnd, // TeamGames game ended
	TG_Disconnect, // Player disconnected
	TG_Other // Currently not used
};

//------------------------------------------------------------------------------------------------
// TeamGames includes
#include <teamgames-natives>
#include <teamgames-forwards>
#include <teamgames-stocks>
