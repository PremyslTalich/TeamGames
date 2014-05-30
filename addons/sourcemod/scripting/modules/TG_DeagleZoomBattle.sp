#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Deagle zoom battle"
#define GAME_ID				"DeagleZoomBattle-Raska"

public Plugin:myinfo =
{
	name = "TG_DeagleZoomBattle",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

new PlayerZoomLevel[ MAXPLAYERS + 1 ];

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

public TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		Client_GiveWeaponAndAmmo( i, "weapon_deagle", true, 900 );
		SDKHook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
		PlayerZoomLevel[ i ] = 90;
		SetEntProp( i, Prop_Send, "m_iFOV", PlayerZoomLevel[ i ] );
	}
	
	HookEvent( "weapon_fire", Event_WeaponFire, EventHookMode_Pre );
	HookEvent( "player_hurt", Event_PlayerHurt, EventHookMode_Post );
	HookEvent( "player_death", Event_PlayerDeath, EventHookMode_Post );
	
	return;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( TG_GetPlayerTeam( client ) != NoneTeam )
	{
		PlayerZoomLevel[ client ] -= 10;
		
		if( PlayerZoomLevel[ client ] < 20 )
			PlayerZoomLevel[ client ] = 20;
		
		SetEntProp( client, Prop_Send, "m_iFOV", PlayerZoomLevel[ client ] );
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	if( !Client_IsValid( client, true ) )
		return Plugin_Continue;
	
	if( TG_IsPlayerRedOrBlue( client ) )
	{
		if( PlayerZoomLevel[ client ] <= 20 )
			return Plugin_Continue;
		
		PlayerZoomLevel[ client ] += 10;
		
		if( PlayerZoomLevel[ client ] > 90 )
			PlayerZoomLevel[ client ] = 90;
		
		SetEntProp( client, Prop_Send, "m_iFOV", PlayerZoomLevel[ client ] );
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	if( !Client_IsValid( client, true ) )
		return Plugin_Continue;
	
	if( TG_IsPlayerRedOrBlue( client ) )
	{
		PlayerZoomLevel[ client ] = 90;		
		SetEntProp( client, Prop_Send, "m_iFOV", PlayerZoomLevel[ client ] );
		SDKUnhook( client, SDKHook_WeaponDrop, Hook_WeaponDrop );
	}
	
	return Plugin_Continue;
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

public TG_OnLastInTeamDie( const String:id[], TG_Team:team )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	TG_StopGame( TG_GetOppositeTeam( team ), true, true );
	
	return;
}

public TG_OnGameEnd( const String:id[], TG_Team:team, winners[], winnersCount )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		SDKUnhook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
	}
	
	return;
}
