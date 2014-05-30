#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <teamgames> // include TeamGames features

#define MENU_ITEM_ID "BombToss-Raska" // define for BombToss item id
#define MENU_ITEM_NAME "Spawnout bombu" // define for BombToss item default name

#define TARGET_MATERIAL "materials/sprites/laserbeam.vmt"
#define TARGET_HALO "materials/sprites/glow01.vmt"
#define LASER_COLOR { 255, 0, 0, 255 }

new g_TargetMaterial = -1;
new g_TargetHalo = -1;
new Float:g_TargetPosition[ 3 ];

new Handle:gh_timer = INVALID_HANDLE;
new Handle:gh_BombList = INVALID_HANDLE;

new String:g_ItemName[ 64 ];

new g_MaxBombs = 32;
new g_BombCounter = 0;

public Plugin:myinfo =
{
	name = "TG_BombToss",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

public OnPluginStart()
{
	HookEvent( "round_start", 	Event_RoundStart, 	EventHookMode_Post );
	HookEvent( "bullet_impact", Event_BulletImpact, EventHookMode_Post );
	
	g_TargetMaterial = PrecacheModel( TARGET_MATERIAL );
	g_TargetHalo = PrecacheModel( TARGET_HALO );
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	TG_KillTimer( gh_timer );
	
	if( gh_BombList != INVALID_HANDLE )
		CloseHandle( gh_BombList );
	
	gh_BombList = CreateArray();
	
	g_BombCounter = 0;
	g_TargetPosition[ 0 ] = 0.0;
	g_TargetPosition[ 1 ] = 0.0;
	g_TargetPosition[ 2 ] = 0.0;
}

public OnLibraryAdded( const String:name[] )
{
    if( StrEqual( name, "TeamGames" ) )
	{
		TG_AddMenuItem( MENU_ITEM_ID, MENU_ITEM_NAME ); // registrer module
		TG_KvAddInt( MenuItem, MENU_ITEM_ID, "MaxBombsCount", 32 ); // add keyValue to modules config (default configs/teamgames/modules.cfg) - this will NOT OVERWRITE IF EXIST
		
		g_MaxBombs = TG_KvGetInt( MenuItem, MENU_ITEM_ID, "MaxBombsCount", 32 ); // get value of kayValue in modules config
		TG_GetMenuItemName( MENU_ITEM_ID, g_ItemName, sizeof( g_ItemName ) ); // get changed item name (item name can be changed in modules config)
	}
}

public OnPluginEnd()
{
	TG_RemoveMenuItem( MENU_ITEM_ID ); // remove menu item
	
	TG_KillTimer( gh_timer );
}

public TG_OnMenuItemSelected( const String:id[], client ) // somebody selected BombToss item in menu
{
	if( !StrEqual( id, MENU_ITEM_ID, true ) )
		return;
	
	if( g_BombCounter >= g_MaxBombs )
		return;
	
	decl Float:ClientPosition[ 3 ], Float:ClientAngles[ 3 ];
	GetClientAbsOrigin( client, ClientPosition );
	GetClientAbsAngles( client, ClientAngles );
	
	NormalizeVector( ClientAngles, ClientAngles );
	ScaleVector( ClientAngles, 32.0 );
	
	new weapon = CreateEntityByName( "weapon_c4" );
	DispatchKeyValue( weapon, "targetname", MENU_ITEM_ID );
	DispatchKeyValue( weapon, "Solid", "6" );
	DispatchSpawn( weapon );
	TeleportEntity( weapon, ClientPosition, NULL_VECTOR, ClientAngles );	
	SetEntData( weapon, FindSendPropInfo( "CBaseEntity", "m_CollisionGroup" ), 2, 4, true );
	g_BombCounter++;
	
	TG_LogRoundMessage( MENU_ITEM_ID, "Player %L spawned bomb. (%d bombs remaining)", client, g_MaxBombs - g_BombCounter );
	
	TurnTimerOn();		
	TG_ShowMainMenu( client );
	
	return;
}

public TG_OnMenuItemDisplay( const String:id[], client, &TG_MenuItemStatus:status, String:name[] ) // somebody is viewing menu with BombToss menu item
{
	if( g_BombCounter < g_MaxBombs )
		status = Active;
	else
		status = Inactive;
	
	Format( name, 64, "%s (%d)", g_ItemName, g_MaxBombs - g_BombCounter );
}

public OnClientPutInServer( client )
{
	SDKHook( client, SDKHook_WeaponCanUse, 	 Hook_OnWeaponCanUse );
	SDKHook( client, SDKHook_WeaponDropPost, Hook_WeaponDrop );
}

public Action:Hook_OnWeaponCanUse( client, weapon )
{
	decl String:WeaponClassName[ 32 ];
	GetEdictClassname( weapon, WeaponClassName, sizeof( WeaponClassName ) );

	if( StrEqual( WeaponClassName, "weapon_c4" ) )
	{
		decl String:WeaponTargetName[ 64 ];
		GetEntPropString( weapon, Prop_Data, "m_iName", WeaponTargetName, sizeof( WeaponTargetName ) );
		
		if( StrEqual( WeaponTargetName, MENU_ITEM_ID ) )
		{
			PushArrayCell( gh_BombList, weapon );
		}
		else if( StrStartWith( WeaponTargetName, "BombToss-Raska-" ) )
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Hook_WeaponDrop( client, weapon )
{
	if( FindValueInArray( gh_BombList, weapon ) != -1 )
	{
		decl String:WeaponTargetName[ 64 ];
				
		Format( WeaponTargetName, sizeof( WeaponTargetName ), "%s-%d", MENU_ITEM_ID, GetClientUserId( client ) );			
		Entity_SetName( weapon, WeaponTargetName );
		SetEntityRenderColor( weapon, GetRandomInt( 0, 255 ), GetRandomInt( 0, 255 ), GetRandomInt( 0, 255 ), 255 );
		
		RemoveFromArray( gh_BombList, FindValueInArray( gh_BombList, weapon ) );
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if( gh_timer == INVALID_HANDLE )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( Client_IsIngame( client ) && IsPlayerAlive( client ) && GetClientTeam( client ) == CS_TEAM_CT )
	{
		new entity = GetClientAimTarget( client, false );
		
		if( entity == -1 )
			return Plugin_Continue;
		
		decl String:EntityClassName[ 32 ];
		GetEdictClassname( entity, EntityClassName, sizeof( EntityClassName ) );

		if( StrEqual( EntityClassName, "weapon_c4" ) )
		{
			decl String:EntityTargetName[ 64 ];
			GetEntPropString( entity, Prop_Data, "m_iName", EntityTargetName, sizeof( EntityTargetName ) );
			
			if( StrStartWith( EntityTargetName, MENU_ITEM_ID ) )
			{
				if( GetClientButtons( client ) & IN_USE )
				{
					GetEntPropVector( entity, Prop_Send, "m_vecOrigin", g_TargetPosition );
				}
				else
				{
					AcceptEntityInput( entity, "Kill" );
				
					g_BombCounter--;
					
					if( g_BombCounter < 1 && gh_timer != INVALID_HANDLE )
					{
						TG_KillTimer( gh_timer );
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

TurnTimerOn()
{
	if( gh_timer == INVALID_HANDLE )
		gh_timer = CreateTimer( 0.2, Timer_BombLookEvent, _, TIMER_REPEAT );
}

public Action:Timer_BombLookEvent( Handle:timer, Handle:DataPack )
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !Client_IsIngame( i ) )
			continue;
		
		ShowBombOwner( i, GetClientAimTarget( i, false ) );		
	}
		
	if( g_TargetPosition[ 0 ] != 0.0 && g_TargetPosition[ 1 ] != 0.0 && g_TargetPosition[ 2 ] != 0.0 )
	{
		new Float:PositionEnd[ 3 ];
		PositionEnd = g_TargetPosition;
		PositionEnd[ 2 ] += 64;
		TE_SetupBeamPoints( g_TargetPosition, PositionEnd, g_TargetMaterial, g_TargetHalo, 2, 1, 0.2, 1.0, 1.0, 0, 0.0, { 255, 0, 0, 255 }, 1 );
		TE_SendToAll();
	}
	
	return Plugin_Continue;
}

ShowBombOwner( client, bomb )
{
	if( !Client_IsIngame( client ) )
		return;
	
	if( !IsValidEdict( bomb ) )
		return;
	
	decl String:EntityClassName[ 32 ];
	GetEdictClassname( bomb, EntityClassName, sizeof( EntityClassName ) );

	if( !StrEqual( EntityClassName, "weapon_c4" ) )
		return;
		
	decl String:BombTargetName[ 64 ];
	GetEntPropString( bomb, Prop_Data, "m_iName", BombTargetName, sizeof( BombTargetName ) );

	if( ReplaceString( BombTargetName, sizeof( BombTargetName ), "BombToss-Raska-", "" ) != 1 )
		return;
	
	new user = GetClientOfUserId( StringToInt( BombTargetName ) );
	if( user != -1 )
	{
		if( g_TargetPosition[ 0 ] != 0.0 && g_TargetPosition[ 1 ] != 0.0 && g_TargetPosition[ 2 ] != 0.0 )
		{
			new Float:distance[ 3 ];
			GetEntPropVector( bomb, Prop_Send, "m_vecOrigin", distance );
			MakeVectorFromPoints( g_TargetPosition, distance, distance );
			Client_PrintHintText( client, "Zahodil: %N (vzdálenost: %.2f)", user, GetVectorLength( distance ) );
		}
		else
			Client_PrintHintText( client, "Zahodil: %N", user );
	}
}
