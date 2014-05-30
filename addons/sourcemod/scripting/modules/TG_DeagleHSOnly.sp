#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Deagle + HS Only"
#define GAME_ID				"DeagleHSOnly-Raska"

public Plugin:myinfo =
{
	name = "TG_Deagle + HS Only",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

public OnLibraryAdded( const String:name[] )
{
    if( StrEqual( name, "TeamGames" ) )
	{
		TG_RegGame( GAME_ID, DEFAULT_GAME_NAME );
	}
}

public OnPluginEnd()
{
	TG_UnRegGame( GAME_ID );
}

public Action:TG_OnGameSelected( const String:id[], client )
{
	if( !StrEqual( id, GAME_ID ) )
		return Plugin_Continue;
	
	TG_StartGame( client, GAME_ID );
	
	return Plugin_Continue;
}

public TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID ) )
		return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		Client_GiveWeaponAndAmmo( i, "weapon_deagle", true, 900 );
		SDKHook( i, SDKHook_TraceAttack, Hook_TraceAttack );
		SDKHook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
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

public Action:Hook_TraceAttack( victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	if( !TG_IsPlayerRedOrBlue( attacker ) )
		return Plugin_Continue;
	
	if( hitgroup != 1 )
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public TG_OnLastInTeamDie( const String:id[], TG_Team:team, client )
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
		SDKUnhook( i, SDKHook_TraceAttack, Hook_TraceAttack );
		SDKUnhook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
	}
	
	return;
}
