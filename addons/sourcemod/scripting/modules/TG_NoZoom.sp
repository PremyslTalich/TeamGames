#include <sourcemod>
#include <sdkhooks>
#include <sdktools_trace>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"NoZoom"
#define GAME_ID				"NoZoom-Raska"

new String:g_GameName[ 64 ];

public Plugin:myinfo =
{
	name = "TG_NoZoom",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

new g_BeamSprite = -1;
new g_HaloSprite = -1;
new String:g_WeaponName[ 64 ];

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
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
	
	ModulWeaponMenu( client );
	
	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[] )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		SetEntityHealth( i, 25 );
	}
	
	HookEvent( "weapon_zoom", Event_WeaponZoom, EventHookMode_Post );
	HookEvent( "bullet_impact", Event_BulletImpact, EventHookMode_Post );
	
	return;
}

public TG_OnGameStart( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	decl WeaponIndex;
	decl String:WeaponName[ 64 ];
	
	ResetPack( DataPack );
	ReadPackString( DataPack, WeaponName, sizeof( WeaponName ) );
	
	strcopy( g_WeaponName, sizeof( g_WeaponName ), WeaponName );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		GivePlayerItem( i, "weapon_knife" );
		WeaponIndex = GivePlayerItem( i, WeaponName );
		SetEntData( WeaponIndex, FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" ), 200, 4, true );
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

public Action:Event_WeaponZoom( Handle:event,const String:name[],bool:dontBroadcast )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;


	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new String:weaponname[ 64 ];
	
	GetClientWeapon( client, weaponname, sizeof( weaponname ) );
	
	if( StrEqual( weaponname, g_WeaponName, false ) && GetClientTeam( client ) == 2 )
	{
		new weapon = GetPlayerWeaponSlot( client, 0 );
		if( weapon != -1)
		{
			RemovePlayerItem( client, weapon );
			RemoveEdict( weapon );
			
			GivePlayerItem( client, g_WeaponName );
		}
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact( Handle:event,const String:name[],bool:dontBroadcast )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	new clientid = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
	if( !TG_IsPlayerRedOrBlue( clientid ) )
	{
		new Float:pos[ 3 ];
		new Float:pos_c[ 3 ];
		new color[4];
		
		pos[ 0 ] = GetEventFloat( event, "x" );
		pos[ 1 ] = GetEventFloat( event, "y" );
		pos[ 2 ] = GetEventFloat( event, "z" );
		
		GetClientEyePosition( clientid, pos_c );
		pos_c[ 2 ] -= 4;
		
		if( TG_GetPlayerTeam( clientid ) == RedTeam )
		{
			color = {220, 20, 60, 255};
		}
		else
		{
			color = {30, 144, 255, 255};
		}
		
		TE_SetupBeamPoints( pos_c, pos, g_BeamSprite, g_HaloSprite, 0, 0, 0.5, 1.0, 1.0, 1024, 0.0, color, 10 );
		TE_SendToAll();
	}
	
	return Plugin_Continue;
}

public bool:TraceEntityFilterPlayer(entity, mask, any:data)
{
  return data != entity;
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

ModulWeaponMenu( client )
{
	new Handle:menu = CreateMenu( ModulWeaponMenu_Handler );

	SetMenuTitle( menu, "NoZoom - vyberte zbraň:" );
	AddMenuItem( menu, "weapon_awp", "AWP" );
	AddMenuItem( menu, "weapon_scout", "Scout" );
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public ModulWeaponMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
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
		
		if( StrEqual( info, "weapon_scout" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - Scout", g_GameName );
		else if( StrEqual( info, "weapon_awp" ) )
			Format( CustomName, sizeof( CustomName ), "%s{settings} - AWP", g_GameName );
		
		TG_StartGame( client, GAME_ID, CustomName, pack );
	}
}
