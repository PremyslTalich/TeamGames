#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Reload battle"
#define GAME_ID				"ReloadBattle-Raska"

new String:g_GameName[ 64 ], String:g_weapon[ 64 ];

public Plugin:myinfo =
{
	name = "TG_ReloadBattle",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public OnLibraryAdded( const String:name[] )
{
	if( !StrEqual( name, "TeamGames" ) )
		return;

	TG_RegGame( GAME_ID, DEFAULT_GAME_NAME );
	TG_GetGameName( GAME_ID, g_GameName, sizeof( g_GameName ) );
}

public OnPluginEnd()
{
	TG_UnRegGame( GAME_ID );
}

public Action:TG_OnGameSelected( const String:id[], client )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	strcopy( g_weapon, sizeof( g_weapon ), "" );
	SetWeaponMenu( client );
	
	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	decl String:weapon[ 64 ];
	
	ResetPack( DataPack );
	ReadPackString( DataPack, weapon, sizeof( weapon ) );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		Client_GiveWeaponAndAmmo( i, weapon, _, 1, _, 0, _ );
		SDKHook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
	}
	
	HookEvent( "weapon_fire", Event_WeaponFire );
	
	return;
}

public Action:Event_WeaponFire( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( TG_IsPlayerRedOrBlue( client ) )
	{
		decl String:weaponName[ 64 ];
		GetEventString( event, "weapon", weaponName, sizeof( weaponName ) );
		
		if( StrContains( g_weapon, weaponName ) != -1 )
		{
			new weapon = Client_GetWeapon( client, g_weapon );
		
			if( weapon != INVALID_ENT_REFERENCE )
				Client_SetWeaponPlayerAmmoEx( client, weapon, 1, 0 );
		}
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

public TG_OnLastInTeamDie( const String:id[], TG_Team:team, client )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	TG_StopGame( TG_GetOppositeTeam( team ) );
	
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

SetWeaponMenu( client )
{
	new Handle:menu = CreateMenu( SetWeaponMenu_Handler );

	SetMenuTitle( menu, "Reload battle - vyberte zbraň:" );
	
	AddMenuItem( menu, "weapon_deagle", "Deagle" );
	AddMenuItem( menu, "weapon_p228", 	"p228" );
	AddMenuItem( menu, "weapon_ak47", 	"AK-47" );
	AddMenuItem( menu, "weapon_m4a1", 	"M4A1" );
	AddMenuItem( menu, "weapon_m249", 	"Machine gun" );
	
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public SetWeaponMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Cancel && param2 == MenuCancel_ExitBack )
	{
		TG_ShowGamesMenu( client );
	}
	else if( action == MenuAction_Select )
	{
		decl String:info[ 64 ], String:CustomName[ 64 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		new Handle:pack = CreateDataPack();
		WritePackString( pack, info );
		
		if( StrEqual( info, "weapon_deagle" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - Deagle", g_GameName );
		else if( StrEqual( info, "weapon_p228" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - p228", g_GameName );
		else if( StrEqual( info, "weapon_ak47" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - AK-47", g_GameName );
		else if( StrEqual( info, "weapon_m4a1" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - M4A1", g_GameName );
		else if( StrEqual( info, "weapon_m249" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - Machine gun", g_GameName );
		
		strcopy( g_weapon, sizeof( g_weapon ), info );
		
		TG_StartGame( client, GAME_ID, CustomName, pack );
	}
}