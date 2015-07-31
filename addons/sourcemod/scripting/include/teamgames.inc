#if defined _teamgames_included_
  #endinput
#endif
#define _teamgames_included_

#include <menus>
#include <smlib>

public SharedPlugin:__pl_teamgames =
{
	name = "TeamGames",
	file = "TeamGames.smx",
	required = 1
};

public __pl_teamgames_SetNTVOptional()
{
	MarkNativeAsOptional("TG_GetPlayerTeam");
	MarkNativeAsOptional("TG_SetPlayerTeam");
	MarkNativeAsOptional("TG_IsGameTypeAvailable");
	MarkNativeAsOptional("TG_LoadPlayerWeapons");
	MarkNativeAsOptional("TG_FenceCreate");
	MarkNativeAsOptional("TG_FenceDestroy");
	MarkNativeAsOptional("TG_FencePlayerCross");
	MarkNativeAsOptional("TG_SpawnMark");
	MarkNativeAsOptional("TG_GetTeamCount");
	MarkNativeAsOptional("TG_ClearTeam");
	MarkNativeAsOptional("TG_SetTeamsLock");
	MarkNativeAsOptional("TG_GetTeamsLock");
	MarkNativeAsOptional("TG_RegGame");
	MarkNativeAsOptional("TG_RemoveGame");
	MarkNativeAsOptional("TG_GetAddedGames");
	MarkNativeAsOptional("TG_ShowPlayerSelectMenu");
	MarkNativeAsOptional("TG_FakeSelect");
	MarkNativeAsOptional("TG_RegMenuItem");
	MarkNativeAsOptional("TG_RemoveMenuItem");
	MarkNativeAsOptional("TG_GetMenuItemName");
	MarkNativeAsOptional("TG_IsModuleReged");
	MarkNativeAsOptional("TG_GetRegedModules");
	MarkNativeAsOptional("TG_StartGame");
	MarkNativeAsOptional("TG_GetCurrentGameID");
	MarkNativeAsOptional("TG_IsCurrentGameID");
	MarkNativeAsOptional("TG_GetCurrentDataPack");
	MarkNativeAsOptional("TG_GetCurrentStarter");
	MarkNativeAsOptional("TG_GetCurrentGameSettings");
	MarkNativeAsOptional("TG_GetGameDefaultName");
	MarkNativeAsOptional("TG_GetGameType");
	MarkNativeAsOptional("TG_StopGame");
	MarkNativeAsOptional("TG_SetModuleVisibility");
	MarkNativeAsOptional("TG_GetModuleVisibility");
	MarkNativeAsOptional("TG_GetGameStatus");
	MarkNativeAsOptional("TG_IsGameStatus");
	MarkNativeAsOptional("TG_LogMessage");
	MarkNativeAsOptional("TG_LogRoundMessage");
	MarkNativeAsOptional("TG_LogGameMessage");
}

//------------------------------------------------------------------------------------------------
// Defines
#define TG_MODULE_ID_LENGTH 	64
#define TG_MODULE_NAME_LENGTH 	64
#define TG_GAME_SETTINGS_LENGTH 64

//------------------------------------------------------------------------------------------------
// Enums
enum TG_Team
{
	TG_ErrorTeam = -1, // eg: CTs, death Ts, etc...
	TG_NoneTeam,
	TG_RedTeam,
	TG_BlueTeam
};

enum TG_GameProgress
{
	TG_NoGame = 0, // TG_GetCurrentGameID and TG_GetGameName("CurrentGameId") returns "Core_NoGame"
	TG_InPreparation,
	TG_InProgress
};

enum TG_GameType
{
	TG_All_ = -1, // do not use this (Only core use this "type")
	TG_FiftyFifty,
	TG_RedOnly
};

enum TG_MenuItemStatus
{
	TG_Active = 0,
	TG_Inactive, // item is in menu, but not selectable
	TG_Disabled // this will block adding item to menu
};

enum TG_ModuleType
{
	TG_Game = 0,
	TG_MenuItem
};

enum TG_PlayerTrigger
{
	TG_Death,
	TG_Rebel,
	TG_ChangeTGTeam,
	TG_GameEnd,
	TG_Disconnect,
	TG_Other // currently not used
};

//------------------------------------------------------------------------------------------------
// Func tags
functag public TG_PlayerSelectMenuHandler(activator, client, bool:IsRandom);

//------------------------------------------------------------------------------------------------
// TeamGames includes
#include <teamgames-natives>
#include <teamgames-forwards>
#include <teamgames-stocks>
