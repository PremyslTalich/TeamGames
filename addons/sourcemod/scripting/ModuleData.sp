#define MAX_MENU_ITEMS 64
#define MAX_GAMES 64

new Handle:h_Timer_CountDownGamePrepare = INVALID_HANDLE;
new g_Timer_CountDownGamePrepare_counter = 4;

enum gamestatusinfo
{
	TG_GameProgress:GameProgress,
	String:GameID[ 64 ],
	String:GameCustomName[ 64 ],
	Handle:GameDataPack,
	GameStarter
}
new g_Game[ gamestatusinfo ];

ClearGameStatusInfo()
{
	g_Game[ GameProgress ] = NoGame;
	strcopy( g_Game[ GameID ], 64, "Core_NoGame" );
	strcopy( g_Game[ GameCustomName ], 64, "" );
	TG_KillHandle( g_Game[ GameDataPack ] );
	g_Game[ GameStarter ] = 0;
}

enum MenuItemStruct
{
	bool:Used,
	String:Id[ 64 ],
    String:DefaultName[ 64 ],
    String:RequiredFlag[ 16 ],
	Separator
}
new g_MenuItemList[ MAX_MENU_ITEMS ][ MenuItemStruct ];
new g_MenuItemListEnd = 0;

enum GameStruct
{
	bool:Used,
	String:Id[ 64 ],
    String:Name[ 64 ],
    String:RequiredFlag[ 16 ],
	TG_GameType:GameType,
	Separator
}
new g_GameList[ MAX_GAMES ][ GameStruct ];
new g_GameListEnd = 0;

bool:ExistMenuItem( const String:id[] )
{
	if( GetMenuItemIndex( id ) >= 0 )
		return true;

	return false;
}

bool:ExistGame( const String:id[] )
{
	if( GetGameIndex( id ) >= 0 )
		return true;

	return false;
}

GetMenuItemIndex( const String:id[], bool:OnlyUsed = true )
{
	for( new i = 0; i < MAX_MENU_ITEMS; i++ )
	{
		if( !g_MenuItemList[ i ][ Used ] && OnlyUsed )
			continue;

		if( StrEqual( g_MenuItemList[ i ][ Id ], id ) )
			return i;
	}

	return -1;
}

GetGameIndex( const String:id[], bool:OnlyUsed = true )
{
	for( new i = 0; i < MAX_GAMES; i++ )
	{
		if( !g_GameList[ i ][ Used ] && OnlyUsed )
			continue;

		if( StrEqual( g_GameList[ i ][ Id ], id ) )
			return i;
	}

	return -1;
}

GetCountAllGames()
{
	new count = 0;

	for( new i = 0; i < MAX_GAMES; i++ )
	{
		if( !g_GameList[ i ][ Used ] )
			continue;

		count++;
	}

	return count;
}

RemoveAllTGMenuItems()
{
	for( new i = 0; i < MAX_MENU_ITEMS; i++ )
		g_MenuItemList[ i ][ Used ] = false;
}

RemoveAllGames()
{
	for( new i = 0; i < MAX_GAMES; i++ )
		g_GameList[ i ][ Used ] = false;
}

bool:IsGameDisabled( const String:id[ 64 ] )
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Games" );
	FileToKeyValues( kv, path );

	if( !KvJumpToKey( kv, id ) )
	{
		CloseHandle( kv );
		return false;
	}
	
	new bool:disabled = bool:KvGetNum( kv, "disabled", 0 );
	CloseHandle( kv );

	return disabled;
}

bool:IsMenuItemDisabled( const String:id[ 64 ] )
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "MainMenu" );
	FileToKeyValues( kv, path );

	if( !KvJumpToKey( kv, id ) )
	{
		CloseHandle( kv );
		return false;
	}
	
	new bool:disabled = bool:KvGetNum( kv, "disabled", 0 );
	CloseHandle( kv );

	return disabled;
}

bool:IsGameTypeAvailable( TG_GameType:type )
{
	if( type == FiftyFifty )
	{
		if( GetCountPlayersInTeam( RedTeam ) == GetCountPlayersInTeam( BlueTeam ) && GetCountPlayersInTeam( RedTeam ) > 0 )
			return true;
	}
	else if( type == RedOnly )
	{
		if( GetCountPlayersInTeam( RedTeam ) >= 2 && GetCountPlayersInTeam( BlueTeam ) == 0 )
			return true;
	}

	return false;
}

ListGames( client )
{
	if( Client_IsValid( client ) )
	{
		PrintToConsole( client, "\n[TeamGames] Games list" );
		PrintToConsole( client, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
		PrintToConsole( client, "|     | Game name                                                        | Game ID                                                          |" );
		PrintToConsole( client, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
	}
	else
	{
		PrintToServer( "\n[TeamGames] Games list" );
		PrintToServer( "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
		PrintToServer( "|     | Game name                                                        | Game ID                                                          |" );
		PrintToServer( "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
	}
	
	new index = 1;
	
	for( new i = 0; i < MAX_GAMES; i++ )
	{
		if( !g_GameList[ i ][ Used ] )
			continue;
		
		if( Client_IsValid( client ) )
			PrintToConsole( client, "| #%2d | %64s | %64s |", index, g_GameList[ i ][ Name ], g_GameList[ i ][ Id ] );
		else		
			PrintToServer( "| #%2d | %64s | %64s |", index, g_GameList[ i ][ Name ], g_GameList[ i ][ Id ] );
		
		index++;
	}
	
	if( Client_IsValid( client ) )
		PrintToConsole( client, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+\n" );
	else
		PrintToServer( "+-----+------------------------------------------------------------------+------------------------------------------------------------------+\n" );
}

ListMenuItems( client )
{
	if( Client_IsValid( client ) )
	{
		PrintToConsole( client, "\n[TeamGames] Menu items list" );
		PrintToConsole( client, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
		PrintToConsole( client, "|     | Default menu item name                                           | Menu item ID                                                     |" );
		PrintToConsole( client, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
	}
	else
	{
		PrintToServer( "\n[TeamGames] Menu items list" );
		PrintToServer( "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
		PrintToServer( "|     | Default menu item name                                           | Menu item ID                                                     |" );
		PrintToServer( "+-----+------------------------------------------------------------------+------------------------------------------------------------------+" );
	}
	
	new index = 1;
	
	for( new i = 0; i < MAX_MENU_ITEMS; i++ )
	{
		if( !g_MenuItemList[ i ][ Used ] )
			continue;
		
		if( Client_IsValid( client ) )
			PrintToConsole( client, "| #%2d | %64s | %64s |", index, g_MenuItemList[ i ][ DefaultName ], g_MenuItemList[ i ][ Id ] );
		else		
			PrintToServer( "| #%2d | %64s | %64s |", index, g_MenuItemList[ i ][ DefaultName ], g_MenuItemList[ i ][ Id ] );
		
		index++;
	}
	
	if( Client_IsValid( client ) )
		PrintToConsole( client, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+\n" );
	else
		PrintToServer( "+-----+------------------------------------------------------------------+------------------------------------------------------------------+\n" );
}
