#include <sourcemod>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Hot Potato"
#define GAME_ID				"HotPotato-Raska"

public Plugin:myinfo =
{
	name = "TG_HotPotato",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

enum VictimInfo
{
	BombEntity,
	VictimEntity,
	Float:VictimSpeed,
	String:VictimColor[ 24 ],
	String:VictimColorPre[ 24 ]
}
new g_victim[ VictimInfo ];

new Handle:gh_SlapTimer = INVALID_HANDLE;
new bool:g_ToLastMan = false;
new String:g_GameName[ 64 ];

public OnPluginStart()
{
	HookEvent( "bomb_pickup",  Event_BombPickUp, EventHookMode_Post );
}

public OnLibraryAdded( const String:name[] )
{
    if( StrEqual( name, "TeamGames" ) )
	{
		TG_RegGame( GAME_ID, DEFAULT_GAME_NAME, RedOnly );
		TG_KvAddFloat( Game, GAME_ID, "BomberSpeed", 1.1 );
		
		g_victim[ VictimSpeed ] = TG_KvGetFloat( Game, GAME_ID, "BomberSpeed", 1.1 );
		TG_GetGameName( GAME_ID, g_GameName, sizeof( g_GameName ) );
	}
}

public OnPluginEnd()
{
	TG_UnRegGame( GAME_ID );
}

public Action:TG_OnGameSelected( const String:id[], client )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	ModuleSetTypeGameMenu( client );
	
	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	new user = TG_GetRandomClient( RedTeam );
	
	if( Client_IsIngame( user ) )
	{
		MakeClientVictim( user );
		
		g_victim[ BombEntity ] = Weapon_CreateForOwner( user, "weapon_c4" );
	}
	else
		TG_StopGame( NoneTeam, true, true );
	
	return;
}

public TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	if( !Client_IsIngame( g_victim[ VictimEntity ] ) )
		TG_StopGame( NoneTeam, true, true );
	
	gh_SlapTimer = CreateTimer( 0.2, Timer_SlapClient, _, TIMER_REPEAT );
	
	return;
}

public Action:Timer_SlapClient( Handle:timer, Handle:DataPack )
{
	if( !Client_IsIngame( g_victim[ VictimEntity ] ) )
		return Plugin_Continue;
	
	new OldHealth = GetClientHealth( g_victim[ VictimEntity ] );
	new NewHealth = OldHealth - 1;
	
	if( NewHealth <= 0 )
	{
		Client_RemoveAllWeapons( g_victim[ VictimEntity ], "", true );
		ForcePlayerSuicide( g_victim[ VictimEntity ] );
	}
	else
	{
		SetEntityHealth( g_victim[ VictimEntity ], NewHealth );
	}
	
	return Plugin_Continue;
}

public Action:Event_BombPickUp( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( TG_GetPlayerTeam( client ) == RedTeam && TG_IsCurrentGameID( GAME_ID ) )
	{
		TG_SetPlayerTeam( -1, g_victim[ VictimEntity ], RedTeam );
		SetEntPropFloat( g_victim[ VictimEntity ], Prop_Data, "m_flLaggedMovementValue", 1.0 );
		
		MakeClientVictim( client );
	}
	
	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCrossed( client, Float:FreezeTime )
{
	if( g_victim[ VictimEntity ] == client )
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public TG_OnPlayerDeath( attacker, TG_Team:attackerTeam, victim, TG_Team:victimTeam, TG_Team:team, weapon, bool:headshot, TG_GameProgress:GameProgress ) //
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return;
	
	if( victim != g_victim[ VictimEntity ] )
		return;
	
	if( g_ToLastMan && TG_GetTeamCount( RedTeam ) >= 2 )
	{
		new user = TG_GetRandomClient( RedTeam );
		
		if( Client_IsIngame( user ) )
		{
			MakeClientVictim( user );
			g_victim[ BombEntity ] = Weapon_CreateForOwner( user, "weapon_c4" );
		}
		else
			TG_StopGame( NoneTeam );
	}
	else
	{
		TG_KillTimer( gh_SlapTimer );
		TG_StopGame( NoneTeam );
	}
	
	return;
}

public TG_OnGameEnd( const String:id[], TG_Team:team, winners[], winnersCount )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	if( Client_IsIngame( g_victim[ VictimEntity ] ) )
		DispatchKeyValue( g_victim[ VictimEntity ], "rendercolor", g_victim[ VictimColorPre ] );
	
	g_victim[ VictimEntity ] = 0;
	TG_KillTimer( gh_SlapTimer );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		SetEntPropFloat( i, Prop_Data, "m_flLaggedMovementValue", 1.0 );
	}
	
	return;
}

ModuleSetTypeGameMenu( client )
{
	new Handle:menu = CreateMenu( ModuleSetTypeGameMenu_Handler );

	SetMenuTitle( menu, "Hot Potato - vyberte typ hry:" );
	AddMenuItem( menu, "OneDeath", "Pouze jedna mrtvola" );
	AddMenuItem( menu, "LastManStanding", "Do posledního muže" );
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public ModuleSetTypeGameMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Cancel && param2 == MenuCancel_ExitBack )
	{
		TG_ShowGamesMenu( client );
	}
	else if( action == MenuAction_Select )
	{
		decl String:info[ 64 ], String:CustomName[ 64 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		if( StrEqual( info, "OneDeath" ) )
		{
			g_ToLastMan = false;
			Format( CustomName, sizeof( CustomName ), "%s{settings} - Pouze jedna mrtvola", g_GameName );
		}
		else if( StrEqual( info, "LastManStanding" ) )
		{
			g_ToLastMan = true;
			Format( CustomName, sizeof( CustomName ), "%s{settings} - Do posledního muže", g_GameName );
		}
		
		TG_StartGame( client, GAME_ID, CustomName );
	}
}

MakeClientVictim( client )
{
	if( Client_IsIngame( g_victim[ VictimEntity ] ) )
	{
		DispatchKeyValue( g_victim[ VictimEntity ], "rendercolor", g_victim[ VictimColorPre ] );
		SetEntPropFloat( g_victim[ VictimEntity ], Prop_Data, "m_flLaggedMovementValue", 1.0 );
	}
	
	g_victim[ VictimEntity ] = client;
	new offset = GetEntSendPropOffs( client, "m_clrRender", true );
	Format( g_victim[ VictimColorPre ], 24, "%d %d %d", GetEntData( client, offset, 1 ), GetEntData( client, offset + 1, 1 ), GetEntData( client, offset + 2, 1 ) );
	
	SetEntPropFloat( g_victim[ VictimEntity ], Prop_Data, "m_flLaggedMovementValue", g_victim[ VictimSpeed ] );
	DispatchKeyValue( g_victim[ VictimEntity ], "rendercolor", g_victim[ VictimColor ] );
}
