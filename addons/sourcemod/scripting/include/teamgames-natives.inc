#if defined _teamgames_natives_included_
  #endinput
#endif
#define _teamgames_natives_included_

/**
 * Get client TeamGames team.
 *
 * @param client		Client index.
 * @return				TG team.
 */
native TG_Team:TG_GetPlayerTeam(client);

/**
 * Set client TeamGames team
 *
 * @param activator		Activator client index (use non valid client index for set client team without the activator).
 *
 * 						valid client index = Checks teams lock and move delay. Uses phrases PlayerMove-NoneTeam|RedTeam|BlueTeam.
 *
 * 						0 = Checks teams lock and move delay. No phrase in chat.
 *
 * 						-1 = No lock or delay checks. Uses phrases PlayerMove-RedTeam|BlueTeam-Game (only if there is running game).
 * @param client		Client index to move.
 * @param team			TG team to move to.
 * @return				True on success, false on failure.
 */
native bool:TG_SetPlayerTeam(activator, client, TG_Team:team);

/**
 * Check if the given game type is available depending on TeamGames teams population.
 *
 * @param type			Game type.
 * $return 				True on success, false on failure.
 */
native bool:TG_IsGameTypeAvailable(TG_GameType:type);

/**
 * Loads saved player weapons, health and armor.
 *
 * @param client		Client index.
 * @return				True on success, false on failure.
 */
native bool:TG_LoadPlayerWeapons(client);

/**
 * Create fence from two points (a, c) on diagonale.
 *
 * @param a			Array with x,y,z coordinates of point a.
 * @param c			Array with x,y,z coordinates of point c.
 * @return			True on success, false on failure.
 */
native bool:TG_FenceCreate(Float:a[3], Float:c[3]);

/**
 * Destroy existing fence.
 *
 * @noreturn
 */
native TG_FenceDestroy();

/**
 * Punish player for crossing the laser fence.
 *
 * @param client			Client index.
 * @param CallForward		Call forward TG_OnLaserFenceCrossed ?
 * @noreturn
 */
native TG_FencePlayerCross(client, bool:callForward = true);

/**
 * Spawn mark.
 *
 * @param client 		Client index of who spawned the mark. Use 0 for no client.
 * @param team 			TG team who owns the mark.
 * @param position 		Mark's position.
 * @param life 			Mark's life.
 * @param callForward 	Call forward TG_OnMarkSpawn?
 * @param counter 		Use marks counter (works only for valid clients).
 * @return 				True on success, false on failure.
 */
native bool:TG_SpawnMark(client, TG_Team:team, Float:position[3], Float:life = 0.0, bool:callForward = true, bool:counter = false);

/**
 * Get count of players in the given TeamGames team.
 *
 * @param team			TG team to count players in.
 * @return				Count (>= 0) of players in the given team.
 */
native TG_GetTeamCount(TG_Team:team);

/**
 * Remove all players from the given TeamGames team.
 *
 * @param team			TG team
 * @noreturn
 */
native TG_ClearTeam(TG_Team:team);

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
 * @return				True or false (true = teams are locked, false = teams are unlocked).
 */
native bool:TG_GetTeamsLock();

/**
 * Register Game to TeamGames.
 *
 * @param name			Game name (showed in games menu via TG_ShowGamesMenu).
 * @param id			Game ID (!!! MUST BE UNIQUE !!!).
 * @return				0 on success, otherwise on failure.
 */
native TG_RegGame(const String:id[64], TG_GameType:type = TG_FiftyFifty);

/**
 * Check if the given module is registred.
 *
 * @param type			Module type
 * @param id			Module ID
 * @return				True if the given module is registred, false otherwise.
 */
native bool:TG_IsModuleReged(TG_ModuleType:type, const String:id[]);

/**
 * Retrieves all registred modules of the given type.
 *
 * @param type 			Module type
 * @return 				Handle to adt array with module ids on success, INVALID_HANDLE otherwise.
 */
native Handle:TG_GetRegedModules(TG_ModuleType:type);

/**
 * Unregister (remove) game from TeamGames.
 *
 * @param id			Game ID.
 * @return				0 on success, otherwise on failure.
 */
native TG_RemoveGame(const String:id[]);

/**
 * Fake player select in TeamGames menu
 *
 * @param client 		Client index
 * @param type 			Module type
 * @param id 			Module ID
 * @noreturn
 */
native TG_FakeSelect(client, TG_ModuleType:type, String:id[]);

/**
 * Register (add) item to TeamGames main menu.
 *
 * @param name			Item name (showed in main menu via TG_ShowMainMenu).
 * @param id			Item ID (!!! MUST BE UNIQUE !!!).
 * @return				0 on success, otherwise on failure.
 */
native TG_RegMenuItem(const String:id[64]);

/**
 * Unregister (remove) item from TeamGames main menu.
 *
 * @param id			Item ID.
 * @return				0 on success, otherwise on failure.
 */
native TG_RemoveMenuItem(const String:id[]);

/**
 * Retrieves module name.
 *
 * @param type			Module type.
 * @param id			Module ID.
 * @param client		Client used as translation target. Use LANG_SERVER for default name.
 * @param name			Buffer to store the name.
 * @param size			Buffer max size.
 * @return				Returns game type of the given game id.
 */
native TG_GetModuleName(TG_ModuleType:type, const String:id[], client, String:name[], size);

/**
 * Start game (preparation for game and then game) with game id = @param id. And lock teams.
 *
 * @param client			Client index who start game.
 * @param id				Game ID.
 * @param CustomGameName	Custom game name to print in phrases "GAME_PREPARATION" and "GAME_STARTED".
 * @param DataPack			Datapack to pass in forwards TG_OnGamePrepare and TG_OnGameStart. If start game failed, datapack handle would be closed.
 * @noreturn
 */
native TG_StartGame(client, const String:id[], const String:gameSettings[] = "", Handle:dataPack = INVALID_HANDLE, bool:removeDroppedWeapons = false, bool:checkTeams = true, bool:endOnTeamEmpty = true);

/**
 * Retrieves current game id.
 *
 * @param id			Buffer for game id
 * @param size			Size of buffer.
 * @return				True on success, false on failure (buffer is smaller then TG_MODULE_ID_LENGTH).
 */
native TG_GetCurrentGameID(String:id[], size);

/**
 * Check if current game id is also the given game id.
 *
 * @param id			Game id.
 * @return				True on success, false otherwise.
 */
native bool:TG_IsCurrentGameID(const String:id[]);

/**
 * Retrieves current game DataPack.
 *
 * @return				DataPack Handle on success, INVALID_HANDLE otherwise (no DataPack or no running game).
 */
native Handle:TG_GetCurrentDataPack();

/**
 * Retrieves current game starter (Player who started the game).
 *
 * @return				Client index on success, 0 otherwise (no starter or no running game).
 */
native TG_GetCurrentStarter();

/**
 * Retrieves current game settings.
 *
 * @param id			Game ID.
 * @return				True on success, false otherwise (no settings or no running game).
 */
native bool:TG_GetCurrentGameSettings(String:gameSettings[], size);

/**
 * Retrieves game type.
 *
 * @param id			Game ID.
 * @return				Returns game type of the given game id.
 */
native TG_GameType:TG_GetGameType(const String:id[]);

/**
 * Stops current game.
 *
 * @param team				Winner team.
 * @param winners			Adt array of winners. If INVALID_HANDLE, living players from winner team are used.
 * @param ClearTeams		Clear teams.
 * @param ReturnWeapons		Return weapons striped in game preparation.
 * @noreturn
 */
native TG_StopGame(TG_Team:team, &Handle:winners = INVALID_HANDLE, bool:clearTeams = true, bool:returnWeapons = true);

/**
 * Set module visibility.
 *
 * @param type			Module type
 * @param id			Module ID
 * @param visibility	Module visibility
 * @return 				True on success, false otherwise.
 */
native bool:TG_SetModuleVisibility(TG_ModuleType:type, const String:id[], bool:visibility);

/**
 * Retrieves module visibility.
 *
 * @param type			Module type
 * @param id			Module ID
 * @return 				Module visibility.
 */
native bool:TG_GetModuleVisibility(TG_ModuleType:type, const String:id[]);

/**
 * Retrieves game status.
 *
 * @return 				Game status.
 */
native TG_GameProgress:TG_GetGameStatus();

/**
 * Checks if the given status is also the current status.
 *
 * @param status		Game status to check.
 * @return				True on success, false otherwise.
 */
native bool:TG_IsGameStatus(TG_GameProgress:status);

/**
 * Logs a module message to the TeamGames logs.
 *
 * @param prefix		Messge prefix.
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 */
native TG_LogMessage(const String:prefix[] = "", const String:format[] = "", any:...);

/**
 * Logs a module round message to the TeamGames logs.
 *
 * @param prefix		Messge prefix.
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 */
native TG_LogRoundMessage(const String:prefix[] = "", const String:format[] = "", any:...);

/**
 * Logs a game message to the TeamGames logs.
 *
 * @param gameID		Game ID.
 * @param prefix		Messge prefix.
 * @param format		String format.
 * @param ...			Format arguments.
 * @noreturn
 */
native TG_LogGameMessage(const String:gameID[], const String:prefix[] = "", const String:format[] = "", any:...);

/**
 * Prototype for TG_ShowPlayerSelectMenu callback.
 *
 * @param activator 	Activator's client index (who used select menu).
 * @param client 		Client index of chosen player.
 * @param IsRandom 		True if activator chosed random player, false otherwise.
 * @noreturn
 */
// typedef TG_PlayerSelectMenuHandler = function void (activator, client, bool:IsRandom);
functag public TG_PlayerSelectMenuHandler(activator, client, bool:IsRandom);

/**
 * Opens menu for choosing player from TG team.
 * 
 * If there is only one player in selected TG teams, the menu is skiped and callback is called imediately.
 * 
 * @param client      	Client index to open menu for.
 * @param callBack      Callback function to call after player selection.
 * @param redTeam      	Allow Red team in menu.
 * @param blueTeam      Allow Blue team in menu.
 * @param random      	Allow random player option in menu.
 * @param format      	Format string for menu heading.
 * @param ...      		Format string arguments.
 * @return 				False if there are no players to be in the menu, True otherwise.
 */
native TG_ShowPlayerSelectMenu(client, TG_PlayerSelectMenuHandler:callBack, bool:redTeam = true, bool:blueTeam = true, bool:random = true, const String:format[] = "", any:...);