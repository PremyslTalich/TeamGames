#if defined _teamgames_forwards_included_
  #endinput
#endif
#define _teamgames_forwards_included_

/**
 * When somebody (or plugin) switched player to team.
 *
 * @param activator		Client index of activator of function to switch player (-1 or 0 = plugin).
 * @param client		Client index of switched player.
 * @param TeamBefore	Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam) before switch.
 * @param TeamAfter		Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam) after switch.
 * @noreturn
 */
forward Action:TG_OnPlayerTeam(client, activator, TG_Team:teamBefore, TG_Team:teamAfter);

forward Action:TG_OnPlayerRebel(client, TG_Team:team);

/**
 * When somebody cross the laser fence.
 *
 * @param client		Client index.
 * @noreturn
 */
forward Action:TG_OnLaserFenceCross(client, Float:freezeTime);
forward TG_OnLaserFenceCrossed(client, Float:freezeTime);

/**
 * Before fence is created.
 *
 * @param a		Float array of coordinates of point a.
 * @param c		Float array of coordinates of point c.
 * @noreturn
 */
forward Action:TG_OnLaserFenceCreate(client, Float:a[3], Float:c[3]);
forward Action:TG_OnLaserFenceCreated(client, Float:a[3], Float:c[3]);

/**
 * Before fence is destroyed.
 *
 * @param a		Float array of coordinates of point a.
 * @param c		Float array of coordinates of point c.
 * @noreturn
 */
forward TG_OnLaserFenceDestroyed(Float:a[3], Float:c[3]);

forward Action:TG_OnMarkSpawn(client, TG_Team:team, Float:position[3], Float:life);
forward TG_OnMarkSpawned(client, TG_Team:team, Float:position[3], Float:life);

// forward TG_OnMenuGameDisplay(const String:id[], client, String:name[]);

/**
 * When the player selected game in games TeamGames menu.
 *
 * @param client		Client index.
 * @param id			Game ID of selected game.
 * @noreturn
 */
forward Action:TG_OnGameSelect(const String:id[], client);
forward TG_OnGameSelected(const String:id[], client);

/**
 * When modul called TG_StartGame().
 *
 * @param client		Client index who started game.
 * @param id			Game ID given via TG_StartGame().
 * @param GameSettings	Custom game name given via TG_StartGame().
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward Action:TG_OnGameStartMenu(const String:id[], client, const String:gameSettings[], Handle:dataPack);

/**
 * When modul called TG_StartGame() and player confirm game start menu.
 *
 * @param client		Client index started game.
 * @param id			Game ID given via TG_StartGame().
 * @param GameSettings	Custom game name given via TG_StartGame().
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward TG_OnGamePrepare(const String:id[], client, const String:gameSettings[], Handle:dataPack);

/**
 * When modul called TG_StartGame() + 5 seconds.
 *
 * @param client		Client index started game.
 * @param id			Game ID given via TG_StartGame().
 * @param GameSettings	Custom game name given via TG_StartGame().
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward TG_OnGameStart(const String:id[], client, const String:gameSettings[], Handle:dataPack);

/**
 * When some error happened in TG_StartGame().
 *
 * @param id				Game ID given via TG_StartGame().
 * @param client			Client index given via TG_StartGame().
 * @param ErrorID			ErrorID of TG_StartGame().
 * @param ErrorDescription	ErrorDescription string of TG_StartGame().
 * @noreturn
 */
forward TG_OnGameStartError(const String:id[], client, errorID, const String:errorDescription[]);

forward Action:TG_OnTraceAttack(bool:inTeamGame, victim, &attacker, &inflictor, &Float:damage, &damageType, &ammoType, hitBox, hitGroup);
forward Action:TG_OnPlayerDamage(bool:inTeamGame, victim, &attacker, &inflictor, &Float:damage, &damageType);

/**
 * When player (from RedTeam or BlueTeam) die.
 *
 * @param attacker		Client index of attacker.
 * @param attackerTeam	Attacker's team index.
 * @param victim		Client index of victim.
 * @param victimTeam	Victim's team index.
 * @param weapon		Weapon name killer used.
 * @param headshot		True if headshot, false otherwise.
 * @noreturn
 */
forward TG_OnPlayerDeath(attacker, TG_Team:attackerTeam, victim, TG_Team:victimTeam, bool:headshot, const String:weapon[], TG_GameProgress:gameProgress, const String:gameID[]);

/**
 * When modul called TG_StopGame().
 *
 * @param id			Game ID of stoped game.
 * @param team			Winner team given via TG_StopGame().
 * @param winners		Array of winners (all alive players in winner team).
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward TG_OnGameEnd(const String:id[], TG_Team:team, winners[], winnersCount, Handle:dataPack);

forward TG_OnTeamEmpty(const String:id[], client, TG_Team:team, TG_PlayerTrigger:trigger);

forward TG_OnPlayerLeaveGame(const String:id[], client, TG_Team:team, TG_PlayerTrigger:trigger);

forward Action:TG_OnMenuDisplay(client);
forward TG_OnMenuDisplayed(client);

/**
 * When the player selected item in TeamGames main menu.
 *
 * @param client		Client index.
 * @param id			Item ID of selected item.
 * @noreturn
 */
forward Action:TG_OnMenuItemSelect(const String:id[], client);
forward TG_OnMenuItemSelected(const String:id[], client);

forward TG_OnDownloadFile(String:file[], String:prefixName[], Handle:args, &bool:known);

forward TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], &TG_MenuItemStatus:status);
