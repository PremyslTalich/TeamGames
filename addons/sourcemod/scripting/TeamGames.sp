// -----
// - pøidat cvar na zapínání/vypínání ff podle stavu hry (aby nestøíkala krev) - ??? - OTESTOVAT
// - natives na stavy hry (g_Game[ GameProgress ]) - OTESTOVAT
// - round limit - OTESTOVAT
//
// - Nìkterý forwardky pøedìlat z ET_Ignore na úplný forwardky - možná... - OTESTOVAT
	// - TG_OnPlayerTeam
	// - TG_OnGamePreparePre
//
// - TG_OnPlayerDamage - OTESTOVAT
//
// - TG_FenceCreate, TG_FenceDestroy a TG_FencePlayerCross - OTESTOVAT
// - fence - dodìlat convary (punish pøi høe/mimo hru) - OTESTOVAT
// - Udìlat forwardku na pøekroèení laserovýho plotu - OTESTOVAT
// - tg_fence_height - OTESTOVAT
//
// - OTESTOVAT novej typ forwardek
// - OTESTOVAT itemy v main menu
//
// - upravit poøadí parametrù forwardek - HOTOVO
// - opravit schizofrenii modulù a itemù na jenom itemy - HOTOVO
// - pøedìlat nastavování ff pomocí SetConVarStringSilent - OTESTOVAT
//
// - pøidat funkci na pøidávání ConVarù modulù do jednoho configu ???????????????????
//
// - Zredukovat nativky a øešit pøes stocky
// - Pøidat možnost potøebného admin flagu pro spuštìní hry (i zobrazení v menu) ??? - OTESTOVAT
// - Pøi unloadnutí pluginu hry odebrat hru ze seznamu her - OTESTOVAT
//
// - pøidat morecolors i do color phrases ??? - OTESTOVAT
// - SetConVarStringSilent - pøidat odebrání notify flagu - OTESTOVAT
//
//
// - Pøed registrací knihovny naloadovat z configu do standartního pole - used = false - OTESTOVAT
// 		- Pøi registraci itemu/hry kouknout do std. pole a doplnit údaje podle potøeby + used = true - OTESTOVAT
//
//
// - Odstranit z phrases "Color prefix" a "Color default" speciální kódy a nahradit klasicky \x01 atd... - OTESTOVAT
// - Otestovat !tg menu admin flag
// - Savy zbraní - dodìlat flashe - na loadování pøidat spoždìní/menu s potvrzením o navrácení (game end) ????? - pøidat ukládání poètu HE, SMK, FB - OTESTOVAT
// - Dodìlat laserový ploty - OTESTOVAT a DOVYMYSLET - udìlat TG_ShowFencesMenu() - OTESTOVAT
// - Odstranit nutnost alespoò jednoho hráèe v teamu pro spuštìní hry - OTESTOVAT
// - Pomìry teamù - OTESTOVAT
// - Opravit bug s granátem a ff - OTESTOVAT
// -----
// ----- OPRAVY -----
// - SetPlayerTeam - jméno hry pøi pøehození hráèù po konci hry - OTESTOVAT
// - u menu nahradit %t za %T - OTESTOVAT - OPRAVIT
// - pøidat druhou možnost výroby plotu nastøelením hvìzdièek (body A a C) ???
// - vyrobit TeamgGames-Store modul
// + pøidat nativky na logování do tg logù - OTESTOVAT
// - StopGame -> opravit bug v "if( g_LogCvar )" - OTESTOVAT
// - pro adminy pøidat možnost zakázat/povolit hry
//
// - OTESTOVAT jak všechno funguje s novým teamem....
//
// - TEST teamu pøi Event_WeaponDrop v HS only - HOTOVO
// - OPRAVIT vracení zbraní u násilnýho pøerušení hry - OTESTOVAT
// - U vracení zbraní jako první vrátit nùž - OTESTOVAT
// ------------------

#pragma semicolon 1

#include <sourcemod>
// #include <geoip>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <teamgames>
#include <convar_append>
#undef REQUIRE_PLUGIN
#include <scp>
#include <updater>

#define UPDATE_URL		"http://fastdl.battleforce.cz/pluginsupdate/TeamGames/TeamGames_UpdateFile.txt"
#define SERVER_IP		"176.9.78.107:27110"

#define DOWNLOADS_CONFIG 	"configs/teamgames/downloads.ini"
#define MODULES_CONFIG 		"configs/teamgames/modules.cfg"

#define FF_DMG_MODIFIER	0.3125

// #define DEBUG

new Handle:gh_LogTime = INVALID_HANDLE, bool:g_LogCvar = true, String:g_LogFile[ PLATFORM_MAX_PATH ];
new Handle:gh_ForceAutoKick = INVALID_HANDLE, Handle:gh_ForceTKPunish = INVALID_HANDLE, Handle:gh_FriendlyFire = INVALID_HANDLE;
new Handle:gh_MenuPercent = INVALID_HANDLE, Handle:gh_MenuFlag = INVALID_HANDLE;

new Handle:Forward_OnPlayerDamage = INVALID_HANDLE;
new Handle:Forward_OnPlayerDeath = INVALID_HANDLE;
new Handle:Forward_OnPlayerTeam = INVALID_HANDLE;
new Handle:Forward_OnLaserFenceCreatePre = INVALID_HANDLE;
new Handle:Forward_OnLaserFenceCrossed = INVALID_HANDLE;
new Handle:Forward_OnLaserFenceDestroyed = INVALID_HANDLE;
new Handle:Forward_OnMarkSpawn = INVALID_HANDLE;
new Handle:Forward_OnGameSelected = INVALID_HANDLE;
new Handle:Forward_OnGamePreparePre = INVALID_HANDLE;
new Handle:Forward_OnGamePrepare = INVALID_HANDLE;
new Handle:Forward_OnGameStart = INVALID_HANDLE;
new Handle:Forward_OnGameStartError = INVALID_HANDLE;
new Handle:Forward_OnGameEnd = INVALID_HANDLE;
new Handle:Forward_OnLastInTeamDie = INVALID_HANDLE;
new Handle:Forward_OnMenuItemDisplay = INVALID_HANDLE;
new Handle:Forward_OnMenuItemSelected = INVALID_HANDLE;
new Handle:Forward_OnUnknownFilePrefixLoaded = INVALID_HANDLE;

#include "ModuleData.sp"
#include "PlayerData.sp"
#include "Games.sp"
#include "Teams.sp"
#include "LaserFences.sp"
#include "Chat.sp"
#include "Marks.sp"
#include "ConfigFiles.sp"
#include "Commands.sp"
#include "Api.sp"

public Plugin:myinfo =
{
	name = 			"TeamGames",
	author = 		"Raska",
	description = 	"Platform (core plugin) for team based games for prisoners and provides a few useful things for wardens.",
	version = 		"0.2.5",
	url = 			""
}

public OnPluginStart()
{
	LoadTranslations( "TeamGames.phrases" );
	LoadTranslations( "TeamGames_settings.phrases" );

	Forward_OnPlayerDamage = 	 		CreateGlobalForward( "TG_OnPlayerDamage", 				ET_Hook, 	Param_CellByRef, 	Param_Cell, 		Param_CellByRef, 	Param_FloatByRef, 	Param_CellByRef );
	Forward_OnPlayerDeath = 	 		CreateGlobalForward( "TG_OnPlayerDeath", 				ET_Ignore, 	Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_String, 	Param_Cell, 	Param_Cell );
	Forward_OnPlayerTeam = 	 			CreateGlobalForward( "TG_OnPlayerTeam", 				ET_Event, 	Param_Cell, 		Param_Cell, 		Param_Cell, 		Param_Cell );
	Forward_OnLaserFenceCreatePre = 	CreateGlobalForward( "TG_OnLaserFenceCreatePre", 		ET_Event, 	Param_Array, 		Param_Array );
	Forward_OnLaserFenceCrossed = 		CreateGlobalForward( "TG_OnLaserFenceCrossed", 			ET_Hook, 	Param_Cell, 		Param_FloatByRef );
	Forward_OnLaserFenceDestroyed = 	CreateGlobalForward( "TG_OnLaserFenceDestroyed", 		ET_Ignore, 	Param_Array, 		Param_Array );
	Forward_OnMarkSpawn = 				CreateGlobalForward( "TG_OnMarkSpawn", 					ET_Hook, 	Param_Cell,			Param_Cell, 		Param_Array, 		Param_Float );
	Forward_OnGameSelected = 			CreateGlobalForward( "TG_OnGameSelected",				ET_Event, 	Param_String,		Param_Cell );
	Forward_OnGamePreparePre =  		CreateGlobalForward( "TG_OnGamePreparePre",				ET_Event, 	Param_String,		Param_Cell, 		Param_String, 		Param_Cell );
	Forward_OnGamePrepare =  			CreateGlobalForward( "TG_OnGamePrepare",				ET_Ignore, 	Param_String,		Param_Cell, 		Param_String, 		Param_Cell );
	Forward_OnGameStart = 	 			CreateGlobalForward( "TG_OnGameStart", 					ET_Ignore, 	Param_String,		Param_Cell, 		Param_String, 		Param_Cell );
	Forward_OnGameStartError = 			CreateGlobalForward( "TG_OnGameStartError",				ET_Ignore, 	Param_String,		Param_Cell, 		Param_Cell, 		Param_String );
	Forward_OnLastInTeamDie = 	 		CreateGlobalForward( "TG_OnLastInTeamDie", 				ET_Ignore, 	Param_String,		Param_Cell,			Param_Cell );
	Forward_OnGameEnd = 	 			CreateGlobalForward( "TG_OnGameEnd", 					ET_Ignore, 	Param_String,		Param_Cell, 		Param_Array, 		Param_Cell, 		Param_Cell );
	Forward_OnMenuItemDisplay = 		CreateGlobalForward( "TG_OnMenuItemDisplay", 			ET_Ignore, 	Param_String,		Param_Cell, 		Param_CellByRef, 	Param_String );
	Forward_OnMenuItemSelected = 		CreateGlobalForward( "TG_OnMenuItemSelected", 			ET_Ignore, 	Param_String,		Param_Cell );
	Forward_OnUnknownFilePrefixLoaded =	CreateGlobalForward( "TG_OnUnknownFilePrefixLoaded", 	ET_Ignore, 	Param_String,		Param_String,		Param_CellByRef );

	gh_AutoUpdate = 			CreateConVar( "tg_autoupdate", 				"1", 			"Should TeamGames plugin use Updater? (https://forums.alliedmods.net/showthread.php?t=169095) (1 = true, 0 = false)" );
	gh_LogTime = 				CreateConVar( "tg_logtime", 				"72.0", 		"How long should logs be hold (in hours) (\"hours = 0.0\" -> logging turned off)", _, true, 0.0, true, 600.0 );

	gh_MenuPercent = 			CreateConVar( "tg_menu_percent", 			"0.6", 			"How many percent of alive CTs must use !tg to unlock !tg menu (0.0 = no limit)", _, true, 0.0, true, 1.0 );
	gh_MenuFlag = 				CreateConVar( "tg_menu_adminflag_allow",	"generic", 		"Allow to use locked !tg menu via admin flag. Leave blank for disallow acces locked !tg menu via admin flag." );

	gh_RoundLimit = 			CreateConVar( "tg_game_roundlimit", 		"-1", 			"How many games could be played in one round. (-1 = no limit)" );
	gh_MoveSurvivors = 			CreateConVar( "tg_game_movesurvivors",		"2",			"Should be survivors (after game end) moved to \"NoneTeam\"?\n\t0 = don't move them\n\t1 = move them\n\t2 = let the game decide)" );
	gh_SaveWeapons = 			CreateConVar( "tg_game_saveweapons",		"2",			"Should survivors recieve striped weapons, health and armor in game preparation?\n\t0 = no\n\t1 = yes\n\t2 = let the game decide)" );

	gh_ChangeTeamDelay =		CreateConVar( "tg_team_changedelay",		"2.0", 			"How many seconds after team change should be player immune from changing team.", _, true, 0.0, true, 600.0 );
	gh_TeamDiff = 				CreateConVar( "tg_team_diff",				"1",			"How should be teams differentiated? (0 = color, 1 = skin)" );
	gh_MoveRebels = 			CreateConVar( "tg_team_moverebels",			"1",			"Move T who attacked CT to \"NoneTeam\"? (1 = true, 0 = false)" );

	gh_AllowMark = 				CreateConVar( "tg_mark_allow",				"1",			"Should be marks enabled? (1 = true, 0 = false)" );
	gh_MarkLimit = 				CreateConVar( "tg_mark_limit",				"20",			"How many marks could be spawned at the moment" );
	gh_MarkLife = 				CreateConVar( "tg_mark_life",				"20.0",			"How many seconds should be one mark spawned", _, true, 0.5, true, 600.0 );

	gh_DoubleMsg = 				CreateConVar( "tg_chat_doublemsg",			"1",			"Should be important messages (translations: Game preparation, Game started, Team won Red team and Team won Blue team) printed twice? (1 = true, 0 = false)" ); //
	gh_AllowTeamPrefix = 		CreateConVar( "tg_chat_teamprefix",			"1",			"Should be chat name prefix used (for player in team red or team blue)? (1 = true, 0 = false) (require plugin \"simple-chatprocessor.smx\")" );
	gh_PluginChatPrefix = 		CreateConVar( "tg_chat_pluginprefix",		"1",			"Please, DO NOT recompile with custom prefix.\n\t0 = \"[TeamGames]\"\n\t1 = \"[TG]\"\n\t2 = \"[SM]\"" );

	gh_NotifyPlayerTeam = 		CreateConVar( "tg_notifyplayerteam",		"2",			"Location for notification about player's team.\n\t0 = turned off\n\t1 = KeyHint text (bottom-right)\n\t2 = hsay\n\t3 = tg hud)\n\t4 = screen overlay (this might break other overlays!)" );

	gh_FenceHeight = 			CreateConVar( "tg_fence_height",			"72.0",			"Height of fence. (Player can jump over fence)", _, true, 12.0, true, 1024.0 );
	gh_FenceNotify = 			CreateConVar( "tg_fence_notify",			"2",			"Notify in chat that player crossed laser fence?\n\t0 = no\n\t1 = yes\n\t2 = only when game is in progress)" );
	gh_FencePunishLength = 		CreateConVar( "tg_fence_punishlength",		"1.0",			"Time in seconds to punish (color and freeze) player who crossed laser fence.", _, true, 0.0, true, 600.0 );
	gh_FenceFreeze = 			CreateConVar( "tg_fence_freeze",			"1",			"Freeze player who crossed laser fence.\n\t0 = no\n\t1 = yes\n\t2 = only when game is in progress)" );
	gh_FenceColor = 			CreateConVar( "tg_fence_color",				"1",			"Color player who crossed laser fence?\n\t0 = no\n\t1 = yes\n\t = only when game is in progress)" );

	gh_ForceAutoKick = 			CreateConVar( "tg_cvar_autokick",			"1",			"Force set convar \"mp_autokick 0\" every map start? (1 = true, 0 = false)" );
	gh_ForceTKPunish = 			CreateConVar( "tg_cvar_tkpunish",			"1",			"Force set convar \"mp_tkpunish 0\" every map start? (1 = true, 0 = false)" );
	gh_FriendlyFire = 			CreateConVar( "tg_cvar_friendlyfire",		"1",			"0 = do not change \"mp_friendlyfire\"\n1 = set \"mp_friendlyfire 1\" every map start\n2 = set \"mp_friendlyfire 1\" when game is in progress and set \"mp_friendlyfire 0\" otherwise." );

	RegConsoleCmd( "sm_teamgames",	Command_MainMenu, 	"TeamGames main menu" );
	RegConsoleCmd( "sm_tg", 		Command_MainMenu, 	"TeamGames main menu" );
	RegConsoleCmd( "sm_games", 		Command_GamesList,	"List of all loaded games." );
	// RegConsoleCmd( "sm_server", Command_Server,	  "Connect to BattleForce.cz jailbreak server (only for CZ/SK players). Do not try block this command!" );

	RegAdminCmd( "sm_tgteam", 	Command_SetTeam,	 	 	ADMFLAG_CUSTOM1, 	"Set player team (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam)." );
	RegAdminCmd( "sm_tglist",  	Command_ModulesList, 		ADMFLAG_ROOT,		"List of all games and custom (modules) menu items." );
	RegAdminCmd( "sm_tgreset", 	Command_Reset, 			 	ADMFLAG_CUSTOM1, 	"Reset all important values and variables in TeamGames and reloads all modules and games (all plugins in cstrike/addons/sourcemod/plugins/ with prefix \"TG_\") (first aid, when something is wrong/bug)" );
	RegAdminCmd( "sm_tgunload", Command_UnloadAllModules,	ADMFLAG_ROOT,		"Unload all modules and games (all plugins in cstrike/addons/sourcemod/plugins/ with prefix \"TG_\")" );
	RegAdminCmd( "sm_tgload", 	Command_loadAllModules,  	ADMFLAG_ROOT, 		"Load all modules and games (all plugins in cstrike/addons/sourcemod/plugins/ with prefix \"TG_\")" );
	RegAdminCmd( "sm_tgcvars", 	Command_ReloadCvars, 	 	ADMFLAG_CONVARS, 	"Reload all convar settings." );
	RegAdminCmd( "sm_tgupdate", Command_Update, 		 	ADMFLAG_ROOT, 		"Check and try to update TeamGames via updater.smx" );

	HookEvent( "round_start", 	Event_RoundStart, 	EventHookMode_Post );
	HookEvent( "round_end", 	Event_RoundEnd, 	EventHookMode_Post );
	HookEvent( "player_hurt", 	Event_PlayerHurt, 	EventHookMode_Post );
	HookEvent( "player_death", 	Event_PlayerDeath, 	EventHookMode_Post );
	HookEvent( "bullet_impact", Event_BulletImpact, EventHookMode_Post );

	HookUserMessage( GetUserMessageId( "TextMsg" ), Hook_TextMsg, true );
	
	RemoveAllTGMenuItems();
	RemoveAllGames();

	ClearGameStatusInfo();

	g_LockMenu = true;

	for( new i = 1; i <= MaxClients; i++ )
	{
		ClearPlayerData( i );
		ClearPlayerEquipment( i );
	}

	g_MarkLimit_counter = 0;

	// AutoExecConfigAppend();
}

public OnLibraryAdded( const String:name[] )
{
    if( LibraryExists( "updater" ) && GetConVarBool( gh_AutoUpdate ) )
		Updater_AddPlugin( UPDATE_URL );
}

public OnMapStart()
{
	ClearGameStatusInfo();

	LoadConVars();
}

public OnMapEnd()
{
	gh_NotifyTimer = INVALID_HANDLE;
}

public OnClientPutInServer( client )
{
	SDKHook( client, SDKHook_OnTakeDamage, Hook_OnTakeDamage );
}

public OnClientDisconnect( client )
{
	ClearPlayerData( client );
	ClearPlayerEquipment( client );
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	ClearGameStatusInfo();
	
	g_LockMenu = true;
	g_TeamsLock = false;

	g_MarkLimit_counter = 0;

	DestroyFence();

	for( new i = 1; i <= MaxClients; i++ )
	{
		ClearPlayerData( i );
		ClearPlayerEquipment( i );
	}
	
	TG_LogMessage( "RoundStart", "" );
}

public Action:Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( g_NotifyPlayerTeam == 4 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( Client_IsIngame( i ) )
				ClientCommand( i, "r_screenoverlay \"\"" );
		}
	}
}

public Action:Hook_OnTakeDamage( client, &attacker, &inflictor, &Float:damage, &damagetype )
{
	if( !Client_IsValid( attacker, true ) || !Client_IsValid( client, true ) )
		return Plugin_Continue;

	if( GetClientTeam( attacker ) == CS_TEAM_CT && GetClientTeam( client ) == CS_TEAM_CT ) // CT can't hurt CT
		return Plugin_Handled;

	if( GetClientTeam( attacker ) == CS_TEAM_CT && GetClientTeam( client ) == CS_TEAM_T ) // CT can hurt T always
		return Plugin_Continue;

	if( GetClientTeam( attacker ) == CS_TEAM_T && g_PlayerData[ attacker ][ Team ] == NoneTeam && GetClientTeam( client ) == CS_TEAM_CT ) // T in NoneTeam can hurt CT always
		return Plugin_Continue;

	if( g_Game[ GameProgress ] == NoGame ) // No game
	{
		if( GetClientTeam( attacker ) == CS_TEAM_T && GetClientTeam( client ) == CS_TEAM_T ) // T can't hurt T if there is no game running
			return Plugin_Handled;

		if( GetClientTeam( attacker ) == CS_TEAM_T && GetClientTeam( client ) == CS_TEAM_CT ) // T can hurt CT if there is no game running
			return Plugin_Continue;
	}
	else if( g_Game[ GameProgress ] == InPreparation ) // Game in preparation
	{
		return Plugin_Handled;
	}
	else if( g_Game[ GameProgress ] == InProgress ) // Game in progress
	{
		if( GetClientTeam( attacker ) == CS_TEAM_T && GetClientTeam( client ) == CS_TEAM_CT ) // T can't hurt CT if game is runnging
			return Plugin_Handled;

		if( GetClientTeam( attacker ) == CS_TEAM_T && GetClientTeam( client ) == CS_TEAM_T ) // T can hurt T if game is runnging (Ts must be in different teams (exclude team 0))
		{
			if( TG_InOppositeTeams( client, attacker ) )
			{
				damage = damage / FF_DMG_MODIFIER; // modify damage (team attack damage is modified by engine, so we need to use this modification to simulate "real damage")

				new Action:result = Plugin_Continue;
				Call_StartForward( Forward_OnPlayerDamage );
				Call_PushCellRef( attacker );
				Call_PushCell( client );
				Call_PushCellRef( inflictor );
				Call_PushFloatRef( damage );
				Call_PushCellRef( damagetype );
				Call_Finish( result );

				if( result == Plugin_Handled || result == Plugin_Stop )
					return Plugin_Handled;

				return Plugin_Changed;
			}
			else
				return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );

	if( g_MoveRebels && Client_IsIngame( victim ) && Client_IsIngame( attacker ) && victim != attacker && g_Game[ GameProgress ] == NoGame )
	{
		if( GetClientTeam( attacker ) == CS_TEAM_T && GetClientTeam( victim ) == CS_TEAM_CT && g_PlayerData[ attacker ][ Team ] != NoneTeam )
			SwitchToTeam( -1, attacker, NoneTeam );
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );

	if( !Client_IsValid( victim, true ) || g_PlayerData[ victim ][ Team ] == NoneTeam )
		return Plugin_Continue;

	new bool:headshot = GetEventBool( event, "headshot" );
	new String:weapon[ 64 ];
	GetEventString( event, "weapon", weapon, sizeof( weapon ) );

	if( Client_IsValid( attacker, true ) && GetClientTeam( victim ) == CS_TEAM_T && GetClientTeam( attacker ) == CS_TEAM_T && attacker != victim )
		SetEntProp( attacker, Prop_Data, "m_iFrags", GetClientFrags( attacker ) + 2 );

	Call_StartForward( Forward_OnPlayerDeath );
	Call_PushCell( attacker );
	Call_PushCell( g_PlayerData[ attacker ][ Team ] );
	Call_PushCell( victim );
	Call_PushCell( g_PlayerData[ victim ][ Team ] );
	Call_PushString( weapon );
	Call_PushCell( headshot );
	Call_PushCell( g_Game[ GameProgress ] );
	Call_Finish();

	decl String:VictimName[ 64 ];
	GetClientName( victim, VictimName, sizeof( VictimName ) );

	TG_LogGameMessage( g_Game[ GameID ], "PlayerDeath", "\"%L\" (team %d) killed \"%L\" (team %d)", attacker, _:g_PlayerData[ attacker ][ Team ], victim, _:g_PlayerData[ victim ][ Team ] );

	if( g_PlayerData[ victim ][ Team ] == RedTeam )
		TG_PrintToChatAll( "%t", "Player death Red team", VictimName );
	else if( g_PlayerData[ victim ][ Team ] == BlueTeam )
		TG_PrintToChatAll( "%t", "Player death Blue team", VictimName );

	if( GetCountPlayersInTeam( g_PlayerData[ victim ][ Team ] ) == 0 )
	{
		TG_LogGameMessage( g_Game[ GameID ], "LastInTeamDie", "\"%L\" (team %d)", victim, _:g_PlayerData[ victim ][ Team ] );

		Call_StartForward( Forward_OnLastInTeamDie );
		Call_PushString( g_Game[ GameID ] );
		Call_PushCell( g_PlayerData[ victim ][ Team ] );
		Call_PushCell( victim );
		Call_Finish();
	}

	g_PlayerData[ victim ][ MenuLock ] = true;
	ClearPlayerEquipment( victim );
	ClearPlayerData( victim );
	
	if( g_NotifyPlayerTeam == 4 )
		ClientCommand( victim, "r_screenoverlay \"\"" );
	
	return Plugin_Continue;
}
