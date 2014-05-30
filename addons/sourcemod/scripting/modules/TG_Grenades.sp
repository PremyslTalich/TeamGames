#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"HE Grenades"
#define GAME_ID				"Grenades-Raska"

public Plugin:myinfo =
{
	name = "TG_Grenades",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

public OnPluginStart()
{
	HookEvent( "hegrenade_detonate", Event_HEGrenadeDetonate );
}

public OnLibraryAdded( const String:name[] )
{
	if( !StrEqual( name, "TeamGames" ) )
		return;

	TG_RegGame( GAME_ID, DEFAULT_GAME_NAME );
}

public OnPluginEnd()
{
	TG_UnRegGame( GAME_ID );
}

public Action:TG_OnGameSelected( const String:id[], client )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;

	TG_StartGame( client, GAME_ID );

	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;

		SetEntityHealth( i, 50 );
	}

	return;
}

public TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;

		Client_GiveWeapon( i, "weapon_hegrenade", true );
	}

	return;
}

public Action:Event_HEGrenadeDetonate( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;

	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	if( TG_IsPlayerRedOrBlue( client ) )
		Client_GiveWeapon( client, "weapon_hegrenade", true );

	return Plugin_Continue;
}

public TG_OnLastInTeamDie( const String:id[], TG_Team:team )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	TG_StopGame( TG_GetOppositeTeam( team ) );

	return;
}
