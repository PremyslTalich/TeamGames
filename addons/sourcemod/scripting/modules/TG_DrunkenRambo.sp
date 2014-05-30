#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Drunken Rambo" // use your own game name
#define GAME_ID				"DrunkenRambo-Raska" // use your own game id

// new String:g_GameName[ 64 ];

public Plugin:myinfo =
{
	name = "TG_DrunkenRambo", // use name with prefix "TG_"
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

public OnLibraryAdded( const String:name[] )
{
	if( !StrEqual( name, "TeamGames" ) )
		return;
	
	TG_RegGame( GAME_ID, DEFAULT_GAME_NAME, RedOnly ); // register my game
}

public OnPluginEnd()
{
	TG_UnRegGame( GAME_ID );
}

public Action:TG_OnGameSelected( const String:id[], client ) // some choose game in !tg games menu
{
	if( !StrEqual( id, GAME_ID, true ) ) // ignore if this is not my game
		return Plugin_Continue;

	TG_StartGame( client, GAME_ID ); // start game

	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	TG_SwitchRandomRedToBlue();

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == RedTeam )
		{
			SetEntityHealth( i, 100 );
		}
		else if( TG_GetPlayerTeam( i ) == BlueTeam )
		{
			SetEntityHealth( i, 10 );

			SetEntData( i, FindSendPropOffs( "CBasePlayer", "m_iFOV" ), 105, 4, true );
			SetEntData( i, FindSendPropOffs( "CBasePlayer", "m_iDefaultFOV" ), 105, 4, true );
			Client_SetScreenOverlay( i, "effects/strider_pinch_dudv" );
			
			SDKHook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
		}
	}

	return;
}

public Action:Hook_WeaponDrop( client, weapon )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	if( TG_IsPlayerRedOrBlue( client ) )
	{
		if( IsValidEdict( weapon ) )
			AcceptEntityInput( weapon, "Kill" );
	}
	
	return Plugin_Continue;
}

public TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == RedTeam ) // Filter all RedTeam players
		{
			Client_GiveWeaponAndAmmo( i, "weapon_knife", true );
		}
		else if( TG_GetPlayerTeam( i ) == BlueTeam ) // Filter all BlueTeam players
		{
			Client_GiveWeaponAndAmmo( i, "weapon_m249", true, 0 );
			SetEntData( Client_GetActiveWeapon( i ), FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" ), 1000, 4, true );
		}
	}

	return;
}

public TG_OnLastInTeamDie( const String:id[], TG_Team:team )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	TG_StopGame( TG_GetOppositeTeam( team ) );

	return;
}

public TG_OnGameEnd( const String:id[], TG_Team:team, winners[], winnersCount ) // game ended, time to reset player's HP etc.
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) ) // Filter of all NoneTeam players and CTs
			continue;
		
		SDKUnhook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );

		SetEntData( i, FindSendPropOffs( "CBasePlayer", "m_iFOV" ), 90, 4, true );
		SetEntData( i, FindSendPropOffs( "CBasePlayer", "m_iDefaultFOV" ), 90, 4, true );
		Client_SetScreenOverlay( i, "" );
	}

	return;
}
