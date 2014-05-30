//------------------------------------------------------------------------------------------------
// All forwards
//------------------------------------------------------------------------------------------------
/*
*/
//------------------------------------------------------------------------------------------------

/**
 * When somebody (or plugin) switched player to team.
 *
 * @param activator		Client index of activator of function to switch player (-1 or 0 = plugin).
 * @param client		Client index of switched player.
 * @param TeamBefore	Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam) before switch.
 * @param TeamAfter		Team index (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam) after switch.
 * @noreturn
 */
forward Action:TG_OnPlayerTeam( client, activator, TG_Team:TeamBefore, TG_Team:TeamAfter );

/**
 * When somebody cross the laser fence.
 *
 * @param client		Client index.
 * @noreturn
 */
forward Action:TG_OnLaserFenceCrossed( client, Float:FreezeTime );

/**
 * Before fence is created.
 *
 * @param a		Float array of coordinates of point a.
 * @param c		Float array of coordinates of point c.
 * @noreturn
 */
forward Action:TG_OnLaserFenceCreatePre( Float:a[ 3 ], Float:c[ 3 ] );

/**
 * Before fence is destroyed.
 *
 * @param a		Float array of coordinates of point a.
 * @param c		Float array of coordinates of point c.
 * @noreturn
 */
forward TG_OnLaserFenceDestroyed( Float:a[ 3 ], Float:c[ 3 ] );

forward Action:TG_OnMarkSpawn( client, TG_Team:team, Float:position[ 3 ], Float:life );

/**
 * When the player selected game in games TeamGames menu.
 *
 * @param client		Client index.
 * @param id			Game ID of selected game.
 * @noreturn
 */
forward Action:TG_OnGameSelected( const String:id[], client );

/**
 * When modul called TG_StartGame().
 *
 * @param client		Client index who started game.
 * @param id			Game ID given via TG_StartGame().
 * @param CustomName	Custom game name given via TG_StartGame().
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward Action:TG_OnGamePreparePre( const String:id[], client, const String:CustomName[], Handle:DataPack );

/**
 * When modul called TG_StartGame() and player confirm game start menu.
 *
 * @param client		Client index started game.
 * @param id			Game ID given via TG_StartGame().
 * @param CustomName	Custom game name given via TG_StartGame().
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack );

/**
 * When modul called TG_StartGame() + 5 seconds.
 *
 * @param client		Client index started game.
 * @param id			Game ID given via TG_StartGame().
 * @param CustomName	Custom game name given via TG_StartGame().
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack );

/**
 * When some error happened in TG_StartGame().
 *
 * @param id				Game ID given via TG_StartGame().
 * @param client			Client index given via TG_StartGame().
 * @param ErrorID			ErrorID of TG_StartGame().
 * @param ErrorDescription	ErrorDescription string of TG_StartGame().
 * @noreturn
 */
forward TG_OnGameStartError( const String:id[], client, ErrorID, const String:ErrorDescription[] );

/**
 * When the game is in progress (TG_GameProgress:InProgress or TG_GameProgress:InPreparation) and a player (in RedTeam or BlueTeam) get damage from a player (in RedTeam or BlueTeam).
 *
 * @param attacker		Client index of attacker.
 * @param victim		Client index of victim.
 * @param inflictor		Inflictor entity index.
 * @param damage		Amount of damage.
 * @param damagetype	Bitfield of damage types
 * @noreturn
 */
forward TG_OnPlayerDamage( &attacker, victim, &inflictor, &Float:damage, &damagetype );

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
forward TG_OnPlayerDeath( attacker, TG_Team:attackerTeam, victim, TG_Team:victimTeam, TG_Team:team, weapon, bool:headshot, TG_GameProgress:GameProgress );

/**
 * When modul called TG_StopGame().
 *
 * @param id			Game ID of stoped game.
 * @param team			Winner team given via TG_StopGame().
 * @param winners		Array of winners (all alive players in winner team).
 * @param DataPack		Datapack handle given via TG_StartGame().
 * @noreturn
 */
forward TG_OnGameEnd( const String:id[], TG_Team:team, winners[], winnersCount, Handle:DataPack );

/**
 * When the last player from team die.
 *
 * @param id			Game ID of current game.
 * @param team			Team of the last player.
 * @param client		Client index of the last player.
 * @noreturn
 */
forward TG_OnLastInTeamDie( const String:id[], TG_Team:team, client );

/**
 * When the player selected item in TeamGames main menu.
 *
 * @param client		Client index.
 * @param id			Item ID of selected item.
 * @noreturn
 */
forward TG_OnMenuItemSelected( const String:id[], client );

forward TG_OnMenuItemDisplay( const String:id[], client, &TG_MenuItemStatus:status, String:name[] );

forward TG_OnUnknownFilePrefixLoaded( const String:prefix[], const String:file[], &bool:known = false );