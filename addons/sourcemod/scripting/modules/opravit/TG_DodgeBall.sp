#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define GAME_NAME	"Smoke DodgeBall"
#define GAME_ID		"DodgeBall-Raska"

public Plugin:myinfo =
{
	name = "TeamGamesModul_DodgeBall",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

new Handle:g_timerDodgeBall = INVALID_HANDLE;

public OnAllPluginsLoaded()
{
	TG_RegGame( GAME_NAME, GAME_ID, { 2, 3 } );
}

public Action:TG_OnGameSelected( client, const String:id[] )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	ModulStartMenu( client );
	
	return Plugin_Continue;
}

public Action:TG_OnGamePrepare( const String:id[] )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == 1 || TG_GetPlayerTeam( i ) == 2 )
		{
			Client_RemoveAllWeapons( i, "", true );
			SetEntityHealth( i, 1 );
			SetEntityGravity( i, 0.6 );
		}
	}
	
	return Plugin_Continue;
}

public Action:TG_OnGameStart( const String:id[] )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == 1 || TG_GetPlayerTeam( i ) == 2 )
		{
			Client_GiveWeapon( i, "weapon_smokegrenade", true );
		}
	}
	
	g_timerDodgeBall = CreateTimer( 1.0, Timer_EquipDodgeBall, _, TIMER_REPEAT );	
	
	return Plugin_Continue;
}

public Action:Timer_EquipDodgeBall( Handle:timer )
{		
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Handled;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == 1 || TG_GetPlayerTeam( i ) == 2 )
		{
			if( GetPlayerWeaponSlot( i, CS_SLOT_GRENADE ) == -1 )
			{
				Client_GiveWeapon( i, "weapon_smokegrenade", true );
			}
		}
	}
	
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[])
{
	if( TG_IsCurrentGameID( GAME_ID ) )
	{	
		if(StrEqual(classname, "env_particlesmokegrenade"))
		{
			SDKHook(entity, SDKHook_Spawn, OnSmokeSpawned);
		}
	}
}

public Action:OnSmokeSpawned(entity, activator, caller, UseType:type, Float:value)
{
	RemoveEdict(entity);
}

public Action:TG_OnTeamSurvive( team, const String:id[] )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	TG_StopGame( team, 0 );
	
	return Plugin_Continue;
}

public Action:TG_OnGameEnd( team, Handle:winners, const String:id[] )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == 1 || TG_GetPlayerTeam( i ) == 2 )
		{
			Client_RemoveAllWeapons( i, "", true );
			Client_GiveWeapon( i, "weapon_knife", true );
			SetEntityHealth( i, 100 );
			TG_SetPlayerTeam( -1, i, NoneTeam );
		}
		
		if( Client_IsValid( i, true ) )
			SetEntityGravity( i, 1.0 )
	}
	
	if( g_timerDodgeBall != INVALID_HANDLE )
	{
		KillTimer( g_timerDodgeBall );
		g_timerDodgeBall = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

ModulStartMenu( client )
{
	new Handle:menu = CreateMenu( ModulStartMenu_Handler );

	SetMenuTitle( menu, "DodgeBall - začít hru:" );
	AddMenuItem( menu, "START_GAME", "Začít hru*" );
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public ModulStartMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Cancel && param2 == MenuCancel_ExitBack )
	{
		TG_ShowGamesMenu( client );
	}
	else if( action == MenuAction_Select )
	{
		decl String:info[ 64 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		if( StrEqual( info, "START_GAME" ) )
		{
			TG_StartGame( client, GAME_ID );
		}
	}
}