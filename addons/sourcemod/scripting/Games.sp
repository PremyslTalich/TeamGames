// ConVars
new Handle:gh_RoundLimit = INVALID_HANDLE, g_RoundLimit;
new String:g_GamePrepare[ 6 ][ PLATFORM_MAX_PATH ];
new String:g_GameEnd[ 3 ][ PLATFORM_MAX_PATH ];
new String:g_GameStart[ PLATFORM_MAX_PATH ];

GamesMenu( client, TG_GameType:type = _All )
{
	if( GetCountAllGames() > 0 )
	{
		new Handle:menu = CreateMenu( GamesMenu_Handler );
		decl String:name[ 64 ];
		decl String:TransMsg[ 256 ];
		
		Format( TransMsg, sizeof( TransMsg ), "%T", "Menu games title", client );
		SetMenuTitle( menu, TransMsg );
		
		for( new i = 0; i < g_GameListEnd; i++ )
		{
			if( !g_GameList[ i ][ Used ] )
				continue;
			
			if( g_GameList[ i ][ GameType ] != type && type != _All )
				continue;
			
			if( strlen( g_GameList[ i ][ RequiredFlag ] ) != 0 && !TG_ClientHasAdminFlag( client, g_GameList[ i ][ RequiredFlag ] ) )
				continue;
			
			AddSeperatorToMenu( menu, g_GameList[ i ][ Separator ], -1 );
			
			if( g_GameList[ i ][ GameType ] == RedOnly && type != RedOnly )
			{
				Format( name, sizeof( name ), "%s (%T)", g_GameList[ i ][ Name ], "Menu games redonly", client );
			}
			else
			{
				strcopy( name, sizeof( name ), g_GameList[ i ][ Name ] );
			}
			
			if( IsGameTypeAvailable( g_GameList[ i ][ GameType ] ) )
				AddMenuItem( menu, g_GameList[ i ][ Id ], name );
			else
				AddMenuItem( menu, g_GameList[ i ][ Id ], name, ITEMDRAW_DISABLED );
			
			AddSeperatorToMenu( menu, g_GameList[ i ][ Separator ], -1 );
		}
		
		SetMenuExitBackButton( menu, true );
		DisplayMenu( menu, client, 30 );
	}
}

public GamesMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Select )
	{
		decl String:info[ 64 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		#if defined DEBUG
		LogMessage( "[TG DEBUG] Player %L selected game (id = '%s').", client, info );
		#endif
		
		new Action:result = Plugin_Continue;
		Call_StartForward( Forward_OnGameSelected );
		Call_PushString( info );
		Call_PushCell( client );
		Call_Finish( result );
		if( result != Plugin_Continue )
			return;
	}
	else if( action == MenuAction_Cancel && param2 == MenuCancel_ExitBack )
	{
		MainMenu( client );
	}
}

LoadAllModules()
{
	new FileType:type;
	decl String:file_path[ 256 ];
	
	new Handle:dir = OpenDirectory( "addons/sourcemod/plugins" );
	if ( dir == INVALID_HANDLE )
	{
		return 1;
	}
 
	while( ReadDirEntry( dir, file_path, sizeof( file_path ), type ) )
	{
		if( type == FileType_File && StrContains( file_path, "TG_", false ) != -1 )
		{
			ServerCommand( "sm plugins load %s", file_path );
		}
	}
	
	CloseHandle( dir );
	
	TG_LogMessage( "Modules", "All modules loaded" );
	
	return 0;
}

UnLoadAllModules()
{
	new FileType:type;
	decl String:file_path[ 256 ];
	
	new Handle:dir = OpenDirectory( "addons/sourcemod/plugins" );
	if ( dir == INVALID_HANDLE )
	{
		return 1;
	}
	
	while( ReadDirEntry( dir, file_path, sizeof( file_path ), type ) )
	{
		if( type == FileType_File && StrContains( file_path, "TG_", false ) != -1 )
		{
			ServerCommand( "sm plugins unload %s", file_path );
		}
	}
	
	CloseHandle( dir );
	
	TG_LogMessage( "Modules", "All modules unloaded" );
	
	return 0;
}

TG_GameType:GetGameTypeByName( String:typestr[] )
{
	if( StrEqual( typestr, "FiftyFifty", false ) )
		return FiftyFifty;
	else if( StrEqual( typestr, "RedOnly", false ) )
		return RedOnly;
	else
		return _All;
}