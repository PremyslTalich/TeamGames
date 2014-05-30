#include <sourcemod>
#include <smlib>
#include <teamgames>

#define DEFAULT_GAME_NAME	"Knife fight"
#define GAME_ID				"KnifeFight-Raska"

new String:g_GameName[ 64 ];

public Plugin:myinfo =
{
	name = "TG_KnifeFight",
	author = "Raska",
	description = "",
	version = "0.5",
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
	
	SetHPMenu( client );
	
	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	ResetPack( DataPack );
	new hp = ReadPackCell( DataPack );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		Client_GiveWeapon( i, "weapon_knife", true );
		SetEntityHealth( i, hp );
	}
	
	return;
}

public TG_OnLastInTeamDie( const String:id[], TG_Team:team )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	TG_StopGame( TG_GetOppositeTeam( team ), true, true );
	
	return;
}

SetHPMenu( client )
{
	new Handle:menu = CreateMenu( SetHPMenu_Handler );

	SetMenuTitle( menu, "Knife fight - vyberte počet HP:" );
	AddMenuItem( menu, "35", "35 HP" );
	AddMenuItem( menu, "100", "100 HP" );
	AddMenuItem( menu, "300", "300 HP" );
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public SetHPMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
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
		new hp = StringToInt( info );
		
		WritePackCell( pack, hp );
		Format( CustomName, sizeof( CustomName ), "%s{settings} - %d HP", g_GameName, hp );
		
		TG_StartGame( client, GAME_ID, CustomName, pack );
	}
}
