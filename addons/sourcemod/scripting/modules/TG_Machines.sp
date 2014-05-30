#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Machines + 500 HP"
#define GAME_ID				"Machines500HP-Raska"

public Plugin:myinfo =
{
	name = "TG_Machines + 500 HP",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

new g_BeamSprite = -1;
new g_HaloSprite = -1;
new g_TracerColor[ 3 ][ 4 ] =
{
	{   0,   0,   0,   0 },
	{ 220,  20,  60, 255 },
	{  30, 144, 255, 255 }
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel( "materials/sprites/laserbeam.vmt" );
	g_HaloSprite = PrecacheModel( "materials/sprites/glow01.vmt" );
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
		
		GivePlayerItem( i, "weapon_knife" );
		SetEntityHealth( i, 500 );
	}
	
	HookEvent( "bullet_impact", Event_BulletImpact, EventHookMode_Post );
	
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
		
		Client_GiveWeaponAndAmmo( i, "weapon_m249", true, 900 );
		SDKHook( i, SDKHook_WeaponDrop, Hook_WeaponDrop );
	}
	
	return;
}

public Action:Event_BulletImpact( Handle:event,const String:name[],bool:dontBroadcast )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new TG_Team:team = TG_GetPlayerTeam( client );
	
	if( TG_IsTeamRedOrBlue( team ) )
	{
		new Float:pos[ 3 ];
		new Float:pos_c[ 3 ];
		
		pos[ 0 ] = GetEventFloat( event, "y" );
		pos[ 1 ] = GetEventFloat( event, "x" );
		pos[ 2 ] = GetEventFloat( event, "z" );
		
		GetClientEyePosition( client, pos_c );
		pos_c[ 2 ] -= 4;
		
		TE_SetupBeamPoints( pos_c, pos, g_BeamSprite, g_HaloSprite, 0, 0, 0.125, 1.0, 1.0, 1024, 0.0, g_TracerColor[ _:team ], 10 );
		TE_SendToAll();
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
