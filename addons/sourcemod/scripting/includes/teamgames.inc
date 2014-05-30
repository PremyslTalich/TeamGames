#if defined _teamgames_included_
  #endinput
#endif
#define _teamgames_included_

#include <menus>
#include <smlib>
#include <morecolors>

public SharedPlugin:__pl_teamgames = 
{
	name = "TeamGames",
	file = "TeamGames.smx",
	required = 1
};

//------------------------------------------------------------------------------------------------
// Enums
enum TG_Team
{
	ErrorTeam = -1,
	NoneTeam,
	RedTeam,
	BlueTeam
}

enum TG_GameProgress
{
	NoGame = 0, // TG_GetCurrentGameID and TG_GetGameName("CurrentGameId") returns "Core_NoGame"
	InPreparation,
	InProgress
};

enum TG_GameType
{
	FiftyFifty = 0,
	RedOnly
}

enum TG_MenuItemStatus
{
	Active = 0,
	Inactive,
	Disabled // this won't add item to menu
}

enum TG_ModuleType
{
	Game = 0,
	MenuItem
}

//------------------------------------------------------------------------------------------------
// TeamGames includes
#include <teamgames-natives>
#include <teamgames-forwards>
#include <teamgames-stocks>
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// How to use colors (!!! MUST USE FUNCTION: LoadTranslations( "TeamGames.phrases" ); !!!)
// RedTeam: 		PrintToChatAll( "%t red team", "Red team" );
//
// Or just use TG_PrintToChat natives.. ;-)
//------------------------------------------------------------------------------------------------

