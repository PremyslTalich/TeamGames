CreateDownloadTableConfigFileIfNotExist()
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), DOWNLOADS_CONFIG );
	
	CreateConfigDirectoryIfNotExist();
	
	if( !FileExists( path, false ) )
	{
		new Handle:fileHandle = OpenFile( path, "w" );
		WriteFileLine( fileHandle, "// Automaticaly created file by TeamGames.smx" );
		WriteFileLine( fileHandle, "// Everything here will player download" );
		WriteFileLine( fileHandle, "// comment" );
		WriteFileLine( fileHandle, "# comment" );
		WriteFileLine( fileHandle, "; comment" );
		WriteFileLine( fileHandle, "// <team> = {RedTeam, Red, 1} | {BlueTeam, Blue, 2} | {NoneTeam, None, 0}\n" );
		WriteFileLine( fileHandle, "// [GamePrepare <time left>]				// Sound file played in preparation (<time left> sec. left) for game. (*.wav or *.mp3) (<time left> = 1|2|3|4|5)" );
		WriteFileLine( fileHandle, "// [GameStart] 								// Sound file played on game start. (*.wav or *.mp3)" );
		WriteFileLine( fileHandle, "// [GameEnd <team>] 						// Sound file played on game end when <team> win. (*.wav or *.mp3)" );
		WriteFileLine( fileHandle, "// [PlayerSkin <team>] 						// Model file used for <team> skin. (*.mdl)" );
		WriteFileLine( fileHandle, "// [Mark <team> <vertical offset> <scale>] 	// Material file used for <team> mark. (*.vmt), <offset> = +Z coordinate (float), <scale> = material scale - 1.0 = normal (float)\n" );
		CloseHandle( fileHandle );
	}
}


bool:ExistMenuItemsConfigFile()
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	return FileExists( path );
}

CreateModulesConfigFileIfNotExist()
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );
	
	CreateConfigDirectoryIfNotExist();
	
	if( !FileExists( path, false ) )
	{
		new Handle:fileHandle = OpenFile( path, "w" );
		WriteFileLine( fileHandle, "\"Root\"" );
		WriteFileLine( fileHandle, "{" );
		WriteFileLine( fileHandle, "	\"MainMenu\"" );
		WriteFileLine( fileHandle, "	{" );
		WriteFileLine( fileHandle, "		\"Core_TeamsMenu\"{}" );
		WriteFileLine( fileHandle, "		\"Core_GamesMenu\"{}" );
		WriteFileLine( fileHandle, "		\"Core_FencesMenu\"{}" );	
		WriteFileLine( fileHandle, "		\"Core_StopGame\"{ \"separator\" \"prepend\" }" );
		WriteFileLine( fileHandle, "		\"Core_GamesRoundLimitInfo\"{ \"disabled\" \"1\" }" );
		WriteFileLine( fileHandle, "		\"Core_Separator\"{}" );
		WriteFileLine( fileHandle, "	}" );
		WriteFileLine( fileHandle, "	\"Games\"{}" );
		WriteFileLine( fileHandle, "}" );
		CloseHandle( fileHandle );
	}
}

CreateConfigDirectoryIfNotExist()
{
	decl String:path[ PLATFORM_MAX_PATH ];
	
	BuildPath( Path_SM, path, sizeof( path ), DOWNLOADS_CONFIG );	
	strcopy( path, FindCharInString( path, '/', true ) + 1, path );
	
	if( !DirExists( path ) )
		CreateDirectory( path, 511 );
	
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );	
	strcopy( path, FindCharInString( path, '/', true ) + 1, path );
	
	if( !DirExists( path ) )
		CreateDirectory( path, 511 );
}

SaveKvToFile( Handle:kv, Handle:file, lvl = 0 )
{
	decl String:key[ 512 ], String:ParentTabs[ 128 ];
	
	do
	{
		KvGetSectionName( kv, key, sizeof( key ) );
		GetTabs( ParentTabs, sizeof( ParentTabs ), lvl );
		
		if( KvGotoFirstSubKey( kv, false ) )
		{
			WriteFileLine( file, "%s\"%s\"", ParentTabs, key );
			WriteFileLine( file, "%s{", ParentTabs );
			
			SaveKvToFile( kv, file, lvl + 1 );
			KvGoBack( kv );
			
			WriteFileLine( file, "%s}", ParentTabs );
		}
		else
		{
			decl String:ChildTabs[ 128 ];
			decl String:keyValue[ 512 ], String:keyName[ 512 ];
			
			GetTabs( ChildTabs, sizeof( ChildTabs ), lvl );
			KvGetSectionName( kv, keyName, sizeof( keyName ) );
			
			if( KvGetDataType( kv, NULL_STRING ) != KvData_None )
			{
				KvGetString( kv, NULL_STRING, keyValue, sizeof( keyValue ) );
				WriteFileLine( file, "%s\"%s\"\t\"%s\"", ChildTabs, keyName, keyValue );
			}
			else
			{
				WriteFileLine( file, "%s\"%s\"{}", ParentTabs, keyName );
			}
		}
	}
	while( KvGotoNextKey( kv, false ) );
}

GetTabs( String:buff[], size, count )
{
	strcopy( buff, size, "" );
	
	for( new i = 0; i < count; i++ )
		Format( buff, size, "%s\t", buff );
}

GetSeparatorType( const String:separator[] )
{
	if( strlen( separator ) == 0 || StrEqual( separator, "none" ) )
		return 0;
	else if( StrEqual( separator, "prepend", false ) )
		return -1;
	else if( StrEqual( separator, "append", false ) )
		return 1;
	else if( StrEqual( separator, "both", false ) )
		return 2;

	return 0;
}

LoadDownLoadTableConfig()
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), DOWNLOADS_CONFIG );
	
	new Handle:fileHandle = OpenFile( path, "r" );
	decl String:DownloadFilePrefix[ 128 ], String:DownloadFile[ PLATFORM_MAX_PATH ], String:PrefixArg[ 128 ];
	while( !IsEndOfFile( fileHandle ) && ReadFileLine( fileHandle, DownloadFile, sizeof( DownloadFile ) ) )
	{
		DownloadFilePrefix[ 0 ] = EOS;
		
		TrimString( DownloadFile );
		
		if( DownloadFile[ 0 ] == '/' && DownloadFile[ 1 ] == '/' )
			continue;
		
		if( DownloadFile[ 0 ] == '#' || DownloadFile[ 0 ] == ';' )
			continue;
		
		if( DownloadFile[ 0 ] == '[' )
		{
			strcopy( DownloadFilePrefix, FindCharInString( DownloadFile, ']' ) + 2, DownloadFile );
			ReplaceStringEx( DownloadFile, sizeof( DownloadFile ) , DownloadFilePrefix, "" );
		}
		
		if( StrEqual( DownloadFile, "", false ) )
			continue;
		
		ReplaceString( DownloadFile, sizeof( DownloadFile ) , "//", "\0", false );
		ReplaceString( DownloadFile, sizeof( DownloadFile ) , "#", "\0", false );
		ReplaceString( DownloadFile, sizeof( DownloadFile ) , ";", "\0", false );
		ReplaceString( DownloadFile, sizeof( DownloadFile ) , "\t", "", false );
		
		TrimString( DownloadFile );
		
		if( StrEqual( DownloadFile, "", false ) )
			continue;
		
		if( !FileExists( DownloadFile, false ) && !FileExists( DownloadFile, true ) )
		{
			LogError( "File '%s' wasn't found! This file has prefix '%s' (empty if none).", DownloadFile, DownloadFilePrefix );
			continue;
		}
		
		AddFileToDownloadsTable( DownloadFile );
		
		#if defined DEBUG
		LogMessage( "[TG DEBUG] Added '%s' to download table.", DownloadFile );
		#endif
		
		if( DownloadFilePrefix[ 0 ] != EOS )
		{
			if( StrStartWith( DownloadFilePrefix, "[GamePrepare" ) )
			{
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 1, "0" );
				
				if( StringToInt( PrefixArg ) > 0 || StringToInt( PrefixArg ) < 6 )
				{
					ReplaceStringEx( DownloadFile, sizeof( DownloadFile ), "sound/", "" );
					PrecacheSound( DownloadFile, true );
					strcopy(  g_GamePrepare[ StringToInt( PrefixArg ) ], PLATFORM_MAX_PATH, DownloadFile );
				}		
			}
			else if( StrEqual( DownloadFilePrefix, "[GameStart]", false ) )
			{
				ReplaceStringEx( DownloadFile, sizeof( DownloadFile ), "sound/", "" );
				PrecacheSound( DownloadFile, true );
				strcopy( g_GameStart, PLATFORM_MAX_PATH, DownloadFile );
			}
			else if( StrStartWith( DownloadFilePrefix, "[GameEnd" ) )
			{
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 1, "ERROR" );
				new TG_Team:team = TG_GetTeamFromString( PrefixArg );
				
				if( team == ErrorTeam )
				{
					LogError( "Bad file prefix argument \"%s\" (file: \"%s\") !", PrefixArg, DownloadFile );
					continue;
				}
				
				ReplaceStringEx( DownloadFile, sizeof( DownloadFile ), "sound/", "" );
				PrecacheSound( DownloadFile, true );
				
				strcopy( g_GameEnd[ team ], PLATFORM_MAX_PATH, DownloadFile );
			}
			else if( StrStartWith( DownloadFilePrefix, "[PlayerSkin" ) )
			{
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 1, "ERROR" );
				new TG_Team:team = TG_GetTeamFromString( PrefixArg );
				
				if( !TG_IsTeamRedOrBlue( team ) )
				{
					LogError( "Bad file prefix argument \"%s\" (file: \"%s\") !", PrefixArg, DownloadFile );
					continue;
				}
				
				PrecacheModel( DownloadFile );
				strcopy( g_TeamSkin[ team ], PLATFORM_MAX_PATH, DownloadFile );
			}
			else if( StrStartWith( DownloadFilePrefix, "[Mark" ) )
			{
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 1, "ERROR" );
				new TG_Team:team = TG_GetTeamFromString( PrefixArg );
				
				if( !TG_IsTeamRedOrBlue( team ) )
				{
					LogError( "Bad file prefix argument \"%s\" (file: \"%s\") !", PrefixArg, DownloadFile );
					continue;
				}
				
				g_Mark[ team ][ Sprite ] = PrecacheModel( DownloadFile );
				
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 2, "12.0" );
				g_Mark[ team ][ High ] = StringToFloat( PrefixArg );
				
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 3, "1.0" );
				g_Mark[ team ][ Scale ] = StringToFloat( PrefixArg );
			}
			else if( StrStartWith( DownloadFilePrefix, "[TeamOverlay" ) )
			{
				TG_GetPrefixArg( PrefixArg, sizeof( PrefixArg ), DownloadFilePrefix, 1, "ERROR" );
				new TG_Team:team = TG_GetTeamFromString( PrefixArg );
				
				if( !TG_IsTeamRedOrBlue( team ) )
				{
					LogError( "Bad file prefix argument \"%s\" (file: \"%s\") !", PrefixArg, DownloadFile );
					continue;
				}
				
				PrecacheDecal( DownloadFile, true );
				
				ReplaceStringEx( DownloadFile, sizeof( DownloadFile ), "materials/", "" );
				strcopy( g_Overlay[ team ][ OverlayName ], PLATFORM_MAX_PATH, DownloadFile );
			}
			else
			{
				new bool:known = false;
				Call_StartForward( Forward_OnUnknownFilePrefixLoaded );
				Call_PushString( DownloadFilePrefix );
				Call_PushString( DownloadFile );
				Call_PushCellRef( known );
				Call_Finish();
				
				if( !known )
					LogError( "Unknown file prefix \"%s\" (file: \"%s\") !", DownloadFilePrefix, DownloadFile );
			}
		}
	}
	CloseHandle( fileHandle );
}

SaveMenuItemToConfig( const String:id[ 64 ], String:name[ 64 ], String:flag[ 16 ] )
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );
	FileToKeyValues( kv, path );

	KvJumpToKey( kv, "MainMenu" );

	KvJumpToKey( kv, id, true );
	KvSetString( kv, "name", name );
	
	if( strlen( flag ) > 0 )
		KvSetString( kv, "RequiredFlag", flag );
	
	KvRewind( kv );
	
	new Handle:file = OpenFile( path, "w" );
	SaveKvToFile( kv, file );
	
	CloseHandle( file );
	CloseHandle( kv );
}

SaveGameToConfig( const String:id[ 64 ], const String:name[ 64 ], String:flag[ 16 ] )
{
	decl String:path[ PLATFORM_MAX_PATH ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );
	FileToKeyValues( kv, path );

	KvJumpToKey( kv, "Games" );

	KvJumpToKey( kv, id, true );
	KvSetString( kv, "name", name );
	
	if( strlen( flag ) > 0 )
		KvSetString( kv, "RequiredFlag", flag );
	
	KvRewind( kv );
	
	new Handle:file = OpenFile( path, "w" );
	SaveKvToFile( kv, file );
	
	CloseHandle( file );
	CloseHandle( kv );
}

LoadMenuItemsConfig()
{
	#if defined DEBUG
	LogMessage( "[TG DEBUG] LoadMenuItemsConfig()" );
	#endif
	g_MenuItemListEnd = 0;

	decl String:path[ PLATFORM_MAX_PATH ], String:key[ 64 ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );

	if( !FileToKeyValues( kv, path ) )
		return;

	KvJumpToKey( kv, "MainMenu" );

	if( KvGotoFirstSubKey( kv ) )
	{
		do
		{
			if( g_MenuItemListEnd >= MAX_MENU_ITEMS )
				break;
			
			if( KvGetNum( kv, "disabled", 0 ) == 1 )
				continue;
			
			KvGetString( kv, "separator", key, sizeof( key ), "none" );
			g_MenuItemList[ g_MenuItemListEnd ][ Separator ] = GetSeparatorType( key );

			KvGetSectionName( kv, g_MenuItemList[ g_MenuItemListEnd ][ Id ], 64 );
			KvGetString( kv, "RequiredFlag", g_MenuItemList[ g_MenuItemListEnd ][ RequiredFlag ], 16, "" );
			KvGetString( kv, "name", g_MenuItemList[ g_MenuItemListEnd ][ DefaultName ], 64, g_MenuItemList[ g_MenuItemListEnd ][ Id ] );

			if( StrStartWith( g_MenuItemList[ g_MenuItemListEnd ][ Id ], "Core_" ) )
				g_MenuItemList[ g_MenuItemListEnd ][ Used ] = true;
			else
				g_MenuItemList[ g_MenuItemListEnd ][ Used ] = false;
			
			#if defined DEBUG
			LogMessage( "[TG DEBUG] \tAdded item(%d) id = '%s', name = '%s'.", g_MenuItemListEnd, g_MenuItemList[ g_MenuItemListEnd ][ Id ], g_MenuItemList[ g_MenuItemListEnd ][ DefaultName ] );
			#endif
			
			g_MenuItemListEnd++;
		}
		while( KvGotoNextKey( kv ) );
	}
	
	CloseHandle( kv );
}

LoadGamesMenuConfig()
{
	#if defined DEBUG
	LogMessage( "[TG DEBUG] LoadGamesMenuConfig()" );
	#endif
	g_GameListEnd = 0;

	decl String:path[ PLATFORM_MAX_PATH ], String:key[ 64 ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );

	if( !FileToKeyValues( kv, path ) )
		return;
	
	KvJumpToKey( kv, "Games" );
	
	if( KvGotoFirstSubKey( kv ) )
	{
		do
		{
			if( g_GameListEnd >= MAX_GAMES )
				break;

			if( KvGetNum( kv, "disabled", 0 ) == 1 )
				continue;

			KvGetString( kv, "separator", key, sizeof( key ), "none" );
			g_GameList[ g_GameListEnd ][ Separator ] = GetSeparatorType( key );

			g_GameList[ g_GameListEnd ][ Used ] = false;
			KvGetSectionName( kv, g_GameList[ g_GameListEnd ][ Id ], 64 );
			KvGetString( kv, "RequiredFlag", g_GameList[ g_GameListEnd ][ RequiredFlag ], 16, "" );
			KvGetString( kv, "name", g_GameList[ g_GameListEnd ][ Name ], 64, g_GameList[ g_GameListEnd ][ Id ] );
			
			#if defined DEBUG
			LogMessage( "[TG DEBUG] \tAdded game(%d) id = '%s', name = '%s'.", g_GameListEnd, g_GameList[ g_GameListEnd ][ Id ], g_GameList[ g_GameListEnd ][ Name ] );
			#endif
			
			g_GameListEnd++;
		}
		while( KvGotoNextKey( kv ) );
	}

	CloseHandle( kv );
}
