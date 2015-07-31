#if defined _teamgames_natives_included_
  #endinput
#endif
#define _teamgames_natives_included_
//------------------------------------------------------------------------------------------------
// All natives
//------------------------------------------------------------------------------------------------
/*
*/
//------------------------------------------------------------------------------------------------

/**
 * Get client team (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam), client must be valid and connected.
 *
 * @param client		Client index.
 * @return				{0, 1, 2} on success (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam), -1 on failure.
 */
native TG_Team:TG_GetPlayerTeam(client);

/**
 * Set client team (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam), client and activator must be valid and connected.
 * This native use phrases "PLAYER_MOVED_TO_NONE", "PLAYER_MOVED_TO_RED" and "PLAYER_MOVED_TO_BLUE".
 *
 * @param activator		Activator client index (use non valid client index for set client team without an activator - doesn't use any phrase).
 * @param client		Client index.
 * @param team			Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam).
 * @return				True on success, false on failure.
 */
native TG_SetPlayerTeam(activator, client, TG_Team:iTeam);

native bool:TG_IsGameTypeAvailable(TG_GameType:type);

/**
 * Loads saved player weapons, health and armor.
 *
 * @param client		Client index.
 * @return				True on success, false on failure.
 */
native bool:TG_LoadPlayerWeapons(client);

/**
 * Create fence from two points (a, c)
 *
 * @param a			Array with x,y,z coordinates of point a.
 * @param c			Array with x,y,z coordinates of point c.
 * @noreturn
 */
native TG_FenceCreate(Float:a[3], Float:c[3]);

/**
 * Destroy existed fence.
 *
 * @noreturn
 */
native TG_FenceDestroy();

/**
 * Punish player due to cross the laser fence.
 *
 * @param client			Client index.
 * @param CallForward		Call forward TG_OnLaserFenceCrossed ?.
 * @noreturn
 */
native TG_FencePlayerCross(client, bool:CallForward = true);

native bool:TG_SpawnMark(client, TG_Team:iTeam, Float:position[3], Float:life = 0.0, bool:fireEvent = true, bool:counter = false);

/**
 * Get team count of connected and alive players.
 *
 * @param team			Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam).
 * @return				Count (>= 0) of players in team (@param team).
 */
native TG_GetTeamCount(TG_Team:iTeam);

/**
 * Switch all players in team (@param team) to NoneTeam.
 *
 * @param team			Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam).
 * @noreturn
 */
native TG_ClearTeam(TG_Team:iTeam);

/**
 * Set teams lock.
 *
 * @param lock			True or false (true = lock teams, false = unlock teams).
 * @noreturn
 */
native TG_SetTeamsLock(bool:lock);

/**
 * Get teams lock.
 *
 * @param lock			True or false (true = lock teams, false = unlock teams).
 * @return				True or false (true = teams are locked, false = teams are unlocked).
 */
native bool:TG_GetTeamsLock();

/**
 * Register Game to TeamGames.
 *
 * @param name			Game name (showed in games menu via TG_ShowGamesMenu).
 * @param id			Game ID (!!! MUST BE UNIQUE !!!).
 * @return				0 on success, otherwise on failure (1 = TG_RegGame #1, 2 = TG_RegGame #2, 3 = TG_RegGame #3).
 *
 * Error - "TG_RegGame #1"		Game registration Failed! Couldn't get Arg1 (Game name)!
 * Error - "TG_RegGame #2"		Game registration Failed! Couldn't get Arg2 (Game ID)!
 * Error - "TG_RegGame #3"		Game registration Failed! Game ID (Arg2) must be unique!
 * Error - "TG_RegGame #4"		Game registration Failed! Game name "Core_NoGame" is reserved!
 * Error - "TG_RegGame #5"		Game registration Failed! Game ID "Core_NoGame" is reserved!
 */
native TG_RegGame(const String:id[64], TG_GameType:type = TG_FiftyFifty, const String:NameFormat[], any:...);

native bool:TG_IsModuleReged(TG_ModuleType:iType, const String:id[]);

native Handle:TG_GetRegedModules(TG_ModuleType:type);

/**
 * Unregister Game from TeamGames.
 *
 * @param id			Game ID.
 * @return				0 on success, otherwise on failure (1 = TG_RegGame #1, 2 = TG_RegGame #2).
 *
 * Error - "TG_RegGame #1"		Game unregistration Failed! Couldn't get Arg1 (Game ID)!
 * Error - "TG_RegGame #2"		Game unregistration Failed! No game with "Game ID" = (Arg2) found!
 */
native TG_RemoveGame(const String:id[]);

/**
 * Get all registred game IDs.
 *
 * @return				Handle to dynamic array with game IDs. YOU MUST CLOSE THAT HANDLE !!!
 */
native TG_GetAddedGames();

native TG_FakeSelect(iClient, TG_ModuleType:iType, String:sID[]);

/**
 * Register (add) item to TeamGames main menu.
 *
 * @param name			Item name (showed in main menu via TG_ShowMainMenu).
 * @param id			Item ID (!!! MUST BE UNIQUE !!!).
 * @return				0 on success, otherwise on failure (1 = TG_AddMainMenuItem #1, 2 = TG_AddMainMenuItem #2, 3 = TG_AddMainMenuItem #3).
 *
 * Error - "TG_AddMainMenuItem #1"		Modul main menu item registration Failed! Couldn't get Arg1 (Item name)!
 * Error - "TG_AddMainMenuItem #2"		Modul main menu item registration Failed! Couldn't get Arg2 (Item ID)!
 * Error - "TG_AddMainMenuItem #3"		Modul main menu item registration Failed! Item ID (Arg2) must be unique!
 */
native TG_RegMenuItem(const String:id[64], const String:NameFormat[], any:...);

/**
 * Unregister (remove) item from TeamGames main menu.
 *
 * @param id			Item ID.
 * @return				0 on success, otherwise on failure (1 = TG_RemoveMainMenuItem #1, 2 = TG_RemoveMainMenuItem #2).
 *
 * Error - "TG_RegGame #1"		Modul main menu item unregistration Failed! Couldn't get Arg1 (Item ID)!
 * Error - "TG_RegGame #2"		Modul main menu item unregistration Failed! No menu item with "Item ID" = (Arg2) found!
 */
native TG_RemoveMenuItem(const String:id[]);

native TG_GetMenuItemName(const String:id[], String:name[], size);

/**
 * Start game (preparation for game and then game) with game id = @param id. And lock teams.
 *
 * @param client			Client index who start game.
 * @param id				Game ID.
 * @param CustomGameName	Custom game name to print in phrases "GAME_PREPARATION" and "GAME_STARTED".
 * @param DataPack			Datapack to pass in forwards TG_OnGamePrepare and TG_OnGameStart. If start game failed, datapack handle would be closed.
 * @noreturn
 *
 * Fire forwards: TG_OnGamePrepare, TG_OnGameStart (after 5 seconds) and TG_OnGameStartError (if start game failed).
 */
native TG_StartGame(iClient, const String:sID[], const String:sGameSettings[] = "", Handle:hDataPack = INVALID_HANDLE, bool:bRemoveDroppedWeapons = false, bool:bCheckTeams = true, bool:bEndOnTeamEmpty = true);

/**
 * Get current game id.
 *
 * @param id			Buffer for game id
 * @param size			Size of buffer.
 * @return				True on success, false on failure (buffer is smaller then 64).
 */
native TG_GetCurrentGameID(String:id[], size);

/**
 * Is current game id.
 *
 * @param id			Tested game id.
 * @return				True if "id" = "current game id", false otherwise.
 */
native bool:TG_IsCurrentGameID(const String:id[]);

native Handle:TG_GetCurrentDataPack();

native TG_GetCurrentStarter();

native bool:TG_GetCurrentGameSettings(String:GameSettings[], size);

native TG_GetGameDefaultName(const String:id[], String:name[], size);

/**
 *	Get game type.
 *
 * @param id			Game ID.
 * @return				Return game type of the game with given Game ID.
 */
native TG_GameType:TG_GetGameType(const String:id[]);

/**
 * Stop game with game id = @param id. And unlock teams.
 *
 * @param team				Team index of winner team (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam).
 * @param ClearTeams		Clear teams? (move all players in RedTeam or BlueTeam to NoneTeam) (True/False)
 * @param ReturnWeapons		Should players recieve striped weapons in game preparation? (True/False)
 * @noreturn
 *
 * Fire forward: TG_OnGameEnd
 */
native TG_StopGame(TG_Team:iTeam, &Handle:hWinners = INVALID_HANDLE, bool:bClearTeams = true, bool:bReturnWeapons = true);

native bool:TG_SetModuleVisibility(TG_ModuleType:type, const String:id[], bool:visibility);
native bool:TG_GetModuleVisibility(TG_ModuleType:type, const String:id[]);

/**
 * Get game status (TG_Enum_GameProgress).
 *
 * @return				TG_GameProgress:status
 */
native TG_GameProgress:TG_GetGameStatus();

/**
 * Is current game status (TG_Enum_GameProgress).
 *
 * @param status		Game status to check (TG_Enum_GameProgress:status).
 * @return				True on success, false otherwise.
 */
native bool:TG_IsGameStatus(TG_GameProgress:status);

native TG_LogMessage(const String:prefix[] = "", const String:format[] = "", any:...);

native TG_LogRoundMessage(const String:prefix[] = "", const String:format[] = "", any:...);

native TG_LogGameMessage(const String:GameID[], const String:prefix[] = "", const String:format[] = "", any:...);

native TG_ShowPlayerSelectMenu(client, TG_Team:iTeam, TG_PlayerSelectMenuHandler:function, const String:format[] = "", any:...);
