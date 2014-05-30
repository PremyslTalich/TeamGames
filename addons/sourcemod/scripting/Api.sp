//------------------------------------------------------------------------------------------------
// Natives
public Native_GetPlayerTeam( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( !Client_IsIngame( client ) || !IsPlayerAlive( client ) || GetClientTeam( client ) != CS_TEAM_T )
		return _:ErrorTeam;

	return _:g_PlayerData[ client ][ Team ];
}

public Native_SetPlayerTeam( Handle:plugin, numParams )
{
	if(	SwitchToTeam( GetNativeCell( 1 ), GetNativeCell( 2 ), TG_Team:GetNativeCell( 3 ) ) != 1 )
		return false;

	return true;
}

public Native_IsPlayerRedOrBlue( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( !Client_IsIngame( client ) || !IsPlayerAlive( client ) || GetClientTeam( client ) != CS_TEAM_T )
		return false;
	
	return TG_IsTeamRedOrBlue( g_PlayerData[ client ][ Team ] );
}

public Native_InOppositeTeams( Handle:plugin, numParams )
{
	new client1 = GetNativeCell( 1 );
	new client2 = GetNativeCell( 2 );

	if( g_PlayerData[ client1 ][ Team ] == NoneTeam )
		return false;

	if( g_PlayerData[ client2 ][ Team ] == NoneTeam )
		return false;

	if( g_PlayerData[ client1 ][ Team ] != g_PlayerData[ client2 ][ Team ] )
		return true;
	else
		return false;
}

public Native_GetTeamFromString( Handle:plugin, numParams )
{
	decl String:team[ 64 ];	
	GetNativeString( 1, team, sizeof( team ) );
	
	if( StrEqual( team, "RedTeam", false ) || StrEqual( team, "red", false ) || team[ 0 ] == '1' )
		return _:RedTeam;
	else if( StrEqual( team, "BlueTeam", false ) || StrEqual( team, "blue", false ) || team[ 0 ] == '2' )
		return _:BlueTeam;
	else if( StrEqual( team, "NoneTeam", false ) || StrEqual( team, "none", false ) || team[ 0 ] == '0' )
		return _:NoneTeam;
	else
		return _:ErrorTeam;
}

public Native_SwitchRandomRedToBlue( Handle:plugin, numParams )
{
	new client = TG_GetRandomClient( RedTeam );

	if( !Client_IsIngame( client ) || !IsPlayerAlive( client ) )
		return 0;

	if(	SwitchToTeam( -1, client, BlueTeam ) != 0 )
		return ( -1 * client );

	#if defined DEBUG
	LogMessage( "[TG DEBUG] SwitchRandomRedToBlue switched player %N.", client );
	#endif

	return client;
}

public Native_IsGameTypeAvailable( Handle:plugin, numParams )
{
	return IsGameTypeAvailable( TG_GameType:GetNativeCell( 1 ) );
}

public Native_LoadPlayerWeapons( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( !Client_IsIngame( client ) || !IsPlayerAlive( client ) || GetClientTeam( client ) == CS_TEAM_CT )
		return false;

	PlayerEquipmentLoad( client );

	return true;
}

public Native_FenceCreate( Handle:plugin, numParams )
{
	new Float:a[ 3 ], Float:c[ 3 ];

	GetNativeArray( 1, a, 3 );
	GetNativeArray( 2, c, 3 );

	CreateFence( a, c );
}

public Native_FenceDestroy( Handle:plugin, numParams )
{
	DestroyFence();
}

public Native_FencePlayerCross( Handle:plugin, numParams )
{
	FencePunishPlayer( GetNativeCell( 1 ), bool:GetNativeCell( 2 ) );
}

public Native_TG_SpawnMark( Handle:plugin, numParams )
{
	new Float:pos[ 3 ];

	new client = GetNativeCell( 1 );
	new TG_Team:team = TG_Team:GetNativeCell( 2 );
	GetNativeArray( 3, pos, 3 );
	new Float:time = GetNativeCell( 4 );
	new bool:fireEvent = GetNativeCell( 5 );
	new bool:count = GetNativeCell( 6 );

	return SpawnMark( client, team, pos[ 0 ], pos[ 1 ], pos[ 2 ], time, count, fireEvent );
}

public Native_GetTeamCount( Handle:plugin, numParams )
{
	return GetCountPlayersInTeam( TG_Team:GetNativeCell( 1 ) );
}

public Native_ClearTeam( Handle:plugin, numParams )
{
	ClearTeam( TG_Team:GetNativeCell( 1 ) );
}

public Native_SetTeamsLock( Handle:plugin, numParams )
{
	g_TeamsLock = GetNativeCell( 1 );
}

public Native_GetTeamsLock( Handle:plugin, numParams )
{
	return g_TeamsLock;
}

public Native_RegGame( Handle:plugin, numParams )
{
	if( !ExistMenuItemsConfigFile() )
	{
		ThrowNativeError( 10, "Game registration Failed! Config file (ConVar \"tg_modules_config\") must exist! (Error - \"TG_RegGame #10\")" );
		return 10;
	}

	if( g_GameListEnd > MAX_GAMES - 1 )
	{
		ThrowNativeError( 9, "Game registration Failed! Reached maximum count of games! (Error - \"TG_RegGame #9\")" );
		return 9;
	}

	decl String:name[ 64 ], String:id[ 64 ], String:flag[ 16 ];

	if( GetNativeString( 1, id, sizeof( id ) ) != SP_ERROR_NONE )
	{
		ThrowNativeError( 1, "Game registration Failed! Couldn't get Arg1 (Game ID)! (Error - \"TG_RegGame #1\")" );
		return 1;
	}

	if( IsGameDisabled( id ) )
		return 5;

	if( StrStartWith( id, "Core_" ) )
	{
		ThrowNativeError( 4, "Game registration Failed! Game ID can't start with \"Core_\" - it's reserved for core! (Error - \"TG_RegGame #4\")" );
		return 4;
	}

	if( ExistGame( id ) )
	{
		ThrowNativeError( 3, "Game registration Failed! Game ID (\"%s\") must be unique! (Error - \"TG_RegGame #3\")", id );
		return 3;
	}

	if( GetNativeString( 2, name, sizeof( name ) ) != SP_ERROR_NONE )
	{
		ThrowNativeError( 2, "Game registration Failed! Couldn't get Arg2 (Game name)! (Error - \"TG_RegGame #2\")" );
		return 2;
	}

	new TG_GameType:type = GetNativeCell( 3 );

	strcopy( flag, sizeof( flag ), "" );

	new index = GetGameIndex( id, false );

	if( index == -1 )
	{
		index = g_GameListEnd;
		g_GameListEnd++;

		strcopy( g_GameList[ index ][ Id ], 64, id );
		strcopy( g_GameList[ index ][ Name ], 64, name );
		strcopy( g_GameList[ index ][ RequiredFlag ], 16, flag );
		SaveGameToConfig( id, name, flag );
	}

	g_GameList[ index ][ Used ] = true;
	g_GameList[ index ][ GameType ] = type;

	#if defined DEBUG
	LogMessage( "[TG DEBUG] Registred game index = '%d', id = '%s', name = '%s', flag = '%s', type = '%d'. (g_GameListEnd = '%d')", index, g_GameList[ index ][ Id ], g_GameList[ index ][ Name ], g_GameList[ index ][ RequiredFlag ], g_GameList[ index ][ GameType ], g_GameListEnd );
	#endif
	
	return 0;
}

public Native_UnRegGame( Handle:plugin, numParams )
{
	decl String:id[ 64 ];

	if( GetNativeString( 1, id, sizeof( id ) ) != SP_ERROR_NONE )
	{
		ThrowNativeError( 1, "Game unregistration Failed! Couldn't get Arg2 (Game ID)! (Error - \"TG_UnRegGame #1\")" );
		return 1;
	}

	if( !ExistGame( id ) )
	{
		ThrowNativeError( 2, "Game unregistration Failed! No game with \"GAME_ID\" = \"%s\" found! (Error - \"TG_UnRegGame #2\")", id );
		return 2;
	}

	g_GameList[ GetGameIndex( id ) ][ Used ] = false;

	return 0;
}

public Native_GetRegGames( Handle:plugin, numParams )
{
	new Handle:GamesArray = INVALID_HANDLE;

	GamesArray = CreateArray( 64 );

	for( new i = 0; i < MAX_GAMES; i++ )
	{
		if( !g_GameList[ i ][ Used ] )
			continue;

		PushArrayString( GamesArray, g_GameList[ i ][ Id ] );
	}

	return _:GamesArray;
}

public Native_ShowMainMenu( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( Client_IsIngame( client ) )
		MainMenu( client );
}

public Native_ShowGamesMenu( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( Client_IsIngame( client ) )
		GamesMenu( client );
}

public Native_ShowTeamsMenu( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( Client_IsIngame( client ) )
		TeamsMenu( client );
}

public Native_ShowFencesMenu( Handle:plugin, numParams )
{
	new client = GetNativeCell( 1 );

	if( Client_IsIngame( client ) )
		FencesMenu( client );
}

public Native_AddMenuItem( Handle:plugin, numParams )
{
	if( !ExistMenuItemsConfigFile() )
	{
		ThrowNativeError( 6, "Main menu item registration Failed! Config file (ConVar \"tg_modules_config\") must exist! (Error - \"TG_AddMenuItem #6\")" );
		return 6;
	}

	if( g_MenuItemListEnd > MAX_MENU_ITEMS - 1 )
	{
		ThrowNativeError( 5, "Main menu item registration Failed! Reached maximum count of main menu items! (Error - \"TG_AddMenuItem #5\")" );
		return 5;
	}

	decl String:ItemName[ 64 ], String:ItemId[ 64 ], String:ItemFlag[ 16 ];

	if( GetNativeString( 1, ItemId, sizeof( ItemId ) ) != SP_ERROR_NONE )
	{
		ThrowNativeError( 2, "Main menu item registration Failed! Couldn't get Arg1 (Item ID)! (Error - \"TG_AddMenuItem #2\")" );
		return 2;
	}

	if( IsMenuItemDisabled( ItemId ) )
		return 5;

	if( StrStartWith( ItemId, "Core_" ) )
	{
		ThrowNativeError( 4, "Main menu item registration Failed! Item ID can't start with \"Core_\" - it's reserved for core items! (Error - \"TG_AddMenuItem #4\")" );
		return 4;
	}

	if( ExistMenuItem( ItemId ) )
	{
		ThrowNativeError( 3, "Main menu item registration Failed! Item ID (\"%s\") must be unique! (Error - \"TG_AddMenuItem #3\")", ItemId );
		return 3;
	}

	if( GetNativeString( 2, ItemName, sizeof( ItemName ) ) != SP_ERROR_NONE )
	{
		ThrowNativeError( 1, "Main menu item registration Failed! Couldn't get Arg2 (Item name)! (Error - \"TG_AddMenuItem #1\")" );
		return 1;
	}

	strcopy( ItemFlag, sizeof( ItemFlag ), "" );

	new ItemIndex = GetMenuItemIndex( ItemId, false );

	if( ItemIndex == -1 )
	{
		ItemIndex = g_MenuItemListEnd;
		g_MenuItemListEnd++;

		strcopy( g_MenuItemList[ ItemIndex ][ Id ], 64, ItemId );
		strcopy( g_MenuItemList[ ItemIndex ][ DefaultName ], 64, ItemName );
		strcopy( g_MenuItemList[ ItemIndex ][ RequiredFlag ], 16, ItemFlag );
		SaveMenuItemToConfig( ItemId, ItemName, ItemFlag );
	}

	g_MenuItemList[ ItemIndex ][ Used ] = true;

	#if defined DEBUG
	LogMessage( "[TG DEBUG] Registred item id = '%s', name = '%s', flag = '%s'.", ItemId, ItemName, ItemFlag );
	#endif

	return 0;
}

public Native_RemoveMenuItem( Handle:plugin, numParams )
{
	decl String:id[ 64 ];

	if( GetNativeString( 1, id, sizeof( id ) ) != SP_ERROR_NONE )
	{
		ThrowNativeError( 1, "Main menu item unregistration Failed! Couldn't get Arg1 (Item ID)! (Error - \"TG_RemoveMenuItem #1\")" );
		return 1;
	}

	if( !ExistMenuItem( id ) )
	{
		ThrowNativeError( 2, "Main menu item unregistration Failed! No menu item with \"ITEM_ID\" = \"%s\" found! (Error - \"TG_RemoveMenuItem #2\")", id );
		return 2;
	}

	g_MenuItemList[ GetMenuItemIndex( id ) ][ Used ] = false;

	return 0;
}

public Native_GetMenuItemName( Handle:plugin, numParams )
{
	new len = GetNativeCell( 3 );

	if( len < 64 )
		return 1;

	decl String:name[ 64 ], String:id[ 64 ];
	GetNativeString( 1, id, sizeof( id ) );

	if( !ExistMenuItem( id ) )
		return 2;

	strcopy( name, 64, g_MenuItemList[ GetMenuItemIndex( id ) ][ DefaultName ] );
	SetNativeString( 2, name, 64 );

	return 0;
}

public Native_KvAddString( Handle:plugin, numParams )
{
	decl String:path[ PLATFORM_MAX_PATH ], String:id[ 64 ], String:key[ 512 ], String:value[ 512 ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );

	if( !FileToKeyValues( kv, path ) )
	{
		LogError( "Can't open file '%s' !", MODULES_CONFIG );
		return false;
	}

	if( TG_ModuleType:GetNativeCell( 1 ) == MenuItem )
	{
		KvJumpToKey( kv, "MainMenu" );
	}
	else
	{
		KvJumpToKey( kv, "Games" );
	}

	GetNativeString( 2, id, sizeof( id ) );

	if( !KvJumpToKey( kv, id ) )
	{
		LogError( "Module with id '%s' wasn't found !", id );
		return false;
	}

	GetNativeString( 3, key, sizeof( key ) );

	if( KvJumpToKey( kv, key ) )
		return false;

	GetNativeString( 4, value, sizeof( value ) );
	KvSetString( kv, key, value );
	KvRewind( kv );

	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );
	new Handle:file = OpenFile( path, "w" );
	SaveKvToFile( kv, file );

	CloseHandle( file );
	CloseHandle( kv );

	return true;
}

public Native_KvSetString( Handle:plugin, numParams )
{
	decl String:path[ PLATFORM_MAX_PATH ], String:id[ 64 ], String:key[ 512 ], String:value[ 512 ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );

	if( !FileToKeyValues( kv, path ) )
		return false;

	if( TG_ModuleType:GetNativeCell( 1 ) == MenuItem )
	{
		KvJumpToKey( kv, "MainMenu" );
	}
	else
	{
		KvJumpToKey( kv, "Games" );
	}

	GetNativeString( 2, id, sizeof( id ) );

	if( !KvJumpToKey( kv, id ) )
		return false;

	GetNativeString( 3, key, sizeof( key ) );
	GetNativeString( 4, value, sizeof( value ) );

	KvSetString( kv, key, value );
	KvRewind( kv );

	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );
	new Handle:file = OpenFile( path, "w" );
	SaveKvToFile( kv, file );

	CloseHandle( file );
	CloseHandle( kv );

	return true;
}

public Native_KvGetString( Handle:plugin, numParams )
{
	new maxsize = GetNativeCell( 5 );
	decl String:path[ PLATFORM_MAX_PATH ], String:id[ 64 ], String:key[ 512 ], String:defaultValue[ 512 ], String:value[ 512 ];
	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );

	new Handle:kv = CreateKeyValues( "Root" );

	GetNativeString( 6, defaultValue, sizeof( defaultValue ) );

	if( !FileToKeyValues( kv, path ) )
	{
		SetNativeString( 4, defaultValue, maxsize );
		return false;
	}

	if( TG_ModuleType:GetNativeCell( 1 ) == MenuItem )
	{
		KvJumpToKey( kv, "MainMenu" );
	}
	else
	{
		KvJumpToKey( kv, "Games" );
	}

	GetNativeString( 2, id, sizeof( id ) );

	if( !KvJumpToKey( kv, id ) )
	{
		SetNativeString( 4, defaultValue, maxsize );
		return false;
	}

	GetNativeString( 3, key, sizeof( key ) );

	KvGetString( kv, key, value, sizeof( value ), defaultValue );
	SetNativeString( 4, value, maxsize );
	KvRewind( kv );

	BuildPath( Path_SM, path, sizeof( path ), MODULES_CONFIG );
	new Handle:file = OpenFile( path, "w" );
	SaveKvToFile( kv, file );

	CloseHandle( file );
	CloseHandle( kv );

	return true;
}

public Native_StartGame( Handle:plugin, numParams )
{
	new client, DataPack;
	client = GetNativeCell( 1 );

	new String:id[ 64 ], String:name[ 64 ], String:CustomName[ 64 ], String:MenuItemStartGame[ 64 ], String:MenuTitle[ 64 ];
	GetNativeString( 2, id, sizeof( id ) );

	strcopy( name, sizeof( name ), g_GameList[ GetGameIndex( id ) ][ Name ] );

	if( GetNativeString( 3, CustomName, sizeof( CustomName ) ) != SP_ERROR_NONE || CustomName[ 0 ] == EOS )
		strcopy( CustomName, sizeof( CustomName ), name );

	DataPack = GetNativeCell( 4 );
	
	new Action:result = Plugin_Continue;
	Call_StartForward( Forward_OnGamePreparePre );
	Call_PushString( id );
	Call_PushCell( client );
	Call_PushString( CustomName );
	Call_PushCell( DataPack );
	Call_Finish( result );
	if( result != Plugin_Continue )
	{
		CloseHandle( Handle:DataPack );
		return 1;
	}

	Format( MenuTitle, sizeof( MenuTitle ), "%T", "Menu games start title", client, name );
	Format( MenuItemStartGame, sizeof( MenuItemStartGame ), "%T", "Menu games start", client );

	new Handle:menu = CreateMenu( GameStartMenu_Handler );
	SetMenuTitle( menu, MenuTitle );
	AddMenuItem( menu, "START_GAME", MenuItemStartGame );
	TG_PushMenuCell( menu, "-CLIENT-", client );
	TG_PushMenuString( menu, "-GAMEID-", id );
	TG_PushMenuString( menu, "-CUSTOMNAME-", CustomName );
	TG_PushMenuCell( menu, "-DATAPACK-", _:DataPack );
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );

	return 0;
}

public Native_GetCurrentGameID( Handle:plugin, numParams )
{
	new len = GetNativeCell( 2 );

	if( len < 64 )
		return false;

	if( !StrEqual( g_Game[ GameID ], "Core_NoGame" ) )
	{
		new String:id[ 64 ];
		
		strcopy( id, 64, g_Game[ GameID ] );

		SetNativeString( 1, id, 64 );
	}
	else
		SetNativeString( 1, "Core_NoGame", 64 );

	return true;
}

public Native_IsCurrentGameID( Handle:plugin, numParams )
{
	decl String:id[ 64 ];
	GetNativeString( 1, id, sizeof( id ) );

	if( StrEqual( g_Game[ GameID ], id ) )
		return true;
	else
		return false;
}

public Native_GetCurrentDataPack( Handle:plugin, numParams )
{
	return _:g_Game[ GameDataPack ];
}

public Native_GetCurrentStarter( Handle:plugin, numParams )
{
	return g_Game[ GameStarter ];
}

public Native_GetCurrentCustomName( Handle:plugin, numParams )
{
	new len = GetNativeCell( 2 );

	if( len < 64 )
		return false;

	if( g_Game[ GameProgress ] != NoGame )
	{
		SetNativeString( 1, g_Game[ GameCustomName ], 64 );
	}
	else
		SetNativeString( 1, "Core_NoGame", 64 );

	return true;
}

public Native_GetGameName( Handle:plugin, numParams )
{
	new len = GetNativeCell( 3 );

	if( len < 64 )
		return 1;

	decl String:name[ 64 ], String:id[ 64 ];

	GetNativeString( 1, id, sizeof( id ) );

	if( !ExistGame( id ) )
		return 2;

	strcopy( name, 64, g_GameList[ GetGameIndex( id ) ][ Name ] );

	SetNativeString( 2, name, 64 );

	return 0;
}

public Native_GetGameType( Handle:plugin, numParams )
{
	decl String:id[ 64 ];

	if( GetNativeString( 1, id, sizeof( id ) ) != SP_ERROR_NONE )
		return 1;

	if( !ExistGame( id ) )
		return 2;

	return _:g_GameList[ GetGameIndex( id ) ][ GameType ];
}

public Native_GetGameRequiredFlag( Handle:plugin, numParams )
{
	new len = GetNativeCell( 3 );

	if( len < 16 )
		return 1;

	decl String:flag[ 16 ], String:id[ 64 ];

	GetNativeString( 1, id, sizeof( id ) );

	if( !ExistGame( id ) )
		return 2;

	strcopy( flag, 16, g_GameList[ GetGameIndex( id ) ][ RequiredFlag ] );

	SetNativeString( 2, flag, 16 );

	return 0;
}
public Native_StopGame( Handle:plugin, numParams )
{
	if( g_Game[ GameProgress ] != InProgress && g_Game[ GameProgress ] != InPreparation )
		return 1;

	g_Game[ GameProgress ] = NoGame;

	if( h_Timer_CountDownGamePrepare != INVALID_HANDLE )
	{
		KillTimer( h_Timer_CountDownGamePrepare );
		h_Timer_CountDownGamePrepare = INVALID_HANDLE;
	}

	new TG_Team:team = GetNativeCell( 1 );
	new clear = GetNativeCell( 2 );
	new weapons = GetNativeCell( 3 );

	if( GetConVarInt( gh_SaveWeapons ) == 1 )
	{
		weapons = true;
	}
	else if( GetConVarInt( gh_SaveWeapons ) == 2 && weapons )
	{
		weapons = true;
	}

	if( g_LogCvar )
	{
		new String:team1[ 4096 ], String:team2[ 4096 ];
		new count1, count2;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( TG_GetPlayerTeam( i ) == RedTeam )
			{
				Format( team1, sizeof( team1 ), "%s%L, ", team1, i );
				count1++;
			}

			if( TG_GetPlayerTeam( i ) == BlueTeam )
			{
				Format( team2, sizeof( team2 ), "%s%L, ", team2, i );
				count2++;
			}
		}

		if( strlen( team1 ) > 2 )
			team1[ strlen( team1 ) - 2 ] = '\0';
		else
			strcopy( team1, sizeof( team1 ), "" );

		if( strlen( team2 ) > 2 )
			team2[ strlen( team2 ) - 2 ] = '\0';
		else
			strcopy( team2, sizeof( team2 ), "" );

		TG_LogRoundMessage(    "GameEnd", "game ended (name: \"%s\") (id: \"%s\") (winner team: \"team %d\")", g_GameList[ GetGameIndex( g_Game[ GameID ] ) ][ Name ], g_Game[ GameID ], team );
		TG_LogRoundMessage( _, "{" );
		TG_LogRoundMessage( _, "\tGame name: \"%s\"", g_GameList[ GetGameIndex( g_Game[ GameID ] ) ][ Name ] );
		TG_LogRoundMessage( _, "\tGame ID: \"%s\"", g_Game[ GameID ] );
		TG_LogRoundMessage( _, "\tWinner team: \"team %d\"", _:team );
		TG_LogRoundMessage( _, "" );
		TG_LogRoundMessage( _, "\tSurvivors RedTeam:  \"%s\" (number of players: \"%d\")", team1, count1 );
		TG_LogRoundMessage( _, "\tSurvivors BlueTeam: \"%s\" (number of players: \"%d\")", team2, count2 );
		TG_LogRoundMessage( _, "}" );
	}

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_IsTeamRedOrBlue( TG_GetPlayerTeam( i ) ) )
			SetEntityMoveType( i, MoveType:MOVETYPE_ISOMETRIC );
		
		if( weapons )
			PlayerEquipmentLoad( i );
	}
	
	new winners[ MAXPLAYERS ];
	new winnersCount = 0;

	if( TG_IsTeamRedOrBlue( team ) )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( TG_GetPlayerTeam( i ) == team )
			{
				winners[ winnersCount ] = i;
				winnersCount++;
			}
		}
	}

	if( GetConVarInt( gh_FriendlyFire ) == 2 )
		SetConVarStringSilent( "mp_friendlyfire", "0" );

	Call_StartForward( Forward_OnGameEnd );
	Call_PushString( g_Game[ GameID ] );
	Call_PushCell( team );
	Call_PushArray( winners, MAXPLAYERS );
	Call_PushCell( winnersCount );
	Call_PushCell( g_Game[ GameDataPack ] );
	Call_Finish();

	if( GetConVarInt( gh_MoveSurvivors ) == 1 )
	{
		ClearTeams();
	}
	else if( GetConVarInt( gh_MoveSurvivors ) == 2 && clear )
	{
		ClearTeams();
	}

	g_TeamsLock = false;
	ClearGameStatusInfo();

	if( IsSoundPrecached( g_GameEnd[ team ] ) )
		EmitSoundToAll( g_GameEnd[ team ], _, _, _, _, 1.0, _, _, _, _, _, _ );

	if( team == RedTeam )
	{
		TG_PrintToChatAll( "%t", "Team won Red team" );
		if( g_DoubleMsg )
			TG_PrintToChatAll( "%t", "Team won Red team" );
	}
	else if( team == BlueTeam )
	{
		TG_PrintToChatAll( "%t", "Team won Blue team" );
		if( g_DoubleMsg )
			TG_PrintToChatAll( "%t", "Team won Blue team" );
	}

	return 0;
}

public Native_GetGameStatus( Handle:plugin, numParams )
{
	return _:g_Game[ GameProgress ];
}

public Native_IsGameStatus( Handle:plugin, numParams )
{
	if( g_Game[ GameProgress ] == TG_GameProgress:GetNativeCell( 1 ) )
		return true;
	else
		return false;
}

public Native_PrintToChat( Handle:plugin, numParams )
{
	decl String:msg[ 512 ];
	new client = GetNativeCell( 1 ), written;

	FormatNativeString( 0, 2, 3, sizeof( msg ), written, msg );
	Format( msg, sizeof( msg ), "%s %s", CHAT_BANNER, msg );
	
	if( FindCharInString( msg, '{' ) != -1 )
		TG_ProcessPhrasesColors( msg, sizeof( msg ) );

	if( Client_IsIngame( client ) )
		PrintToChat( client, msg );
}

public Native_PrintToChatEx( Handle:plugin, numParams )
{
	decl String:msg[ 512 ];
	new client = GetNativeCell( 1 ), written;

	FormatNativeString( 0, 2, 3, sizeof( msg ), written, msg );
	Format( msg, sizeof( msg ), "%t%s", "Color default", msg );
	
	if( FindCharInString( msg, '{' ) != -1 )
		TG_ProcessPhrasesColors( msg, sizeof( msg ) );

	if( Client_IsIngame( client ) )
		PrintToChat( client, msg );
}

public Native_LogMessage( Handle:plugin, numParams )
{
	if( !g_LogCvar )
		return;

	decl String:prefix[ 64 ], String:msg[ 512 ];
	new String:out[ 512 ];
	new written;

	GetNativeString( 1, prefix, sizeof( prefix ) );
	FormatNativeString( 0, 2, 3, sizeof( msg ), written, msg );

	if( strlen( prefix ) > 0 )
		Format( out, sizeof( out ), "[%s]", prefix );
	
	if( strlen( prefix ) > 0 && strlen( msg ) > 0 )
		StrCat( out, sizeof( out ), " " );
	
	StrCat( out, sizeof( out ), msg );
		
	LogToFileEx( g_LogFile, out );
}

public Native_LogRoundMessage( Handle:plugin, numParams )
{
	if( !g_LogCvar )
		return;

	decl String:prefix[ 64 ], String:msg[ 512 ];
	new String:out[ 512 ];
	new written;

	GetNativeString( 1, prefix, sizeof( prefix ) );
	FormatNativeString( 0, 2, 3, sizeof( msg ), written, msg );

	if( strlen( prefix ) > 0 )
		Format( out, sizeof( out ), "[%s]", prefix );
	
	if( strlen( prefix ) > 0 && strlen( msg ) > 0 )
		StrCat( out, sizeof( out ), " " );
	
	StrCat( out, sizeof( out ), msg );
	
	Format( out, sizeof( out ), "\t%s", out );

	LogToFileEx( g_LogFile, out );
}

public Native_LogGameMessage( Handle:plugin, numParams )
{
	if( !g_LogCvar )
		return;

	decl String:gameID[ 72 ], String:prefix[ 64 ], String:msg[ 512 ];
	new String:out[ 512 ];
	new written;

	if( GetNativeString( 1, gameID, sizeof( gameID ) ) != SP_ERROR_NONE )
		return;

	GetNativeString( 2, prefix, sizeof( prefix ) );
	FormatNativeString( 0, 3, 4, sizeof( msg ), written, msg );

	Format( out, sizeof( out ), "[%s]", gameID );

	if( strlen( prefix ) > 0 )
		Format( out, sizeof( out ), "%s[%s]", out, prefix );
		
	if( strlen( msg ) > 0 )
		Format( out, sizeof( out ), "%s %s", out, msg );
	
	Format( out, sizeof( out ), "\t%s", out );
	
	if( g_Game[ GameProgress ] != NoGame )
		Format( out, sizeof( out ), "\t%s", out );
	
	LogToFileEx( g_LogFile, out );
}

//------------------------------------------------------------------------------------------------
// AskPluginLoad2

public APLRes:AskPluginLoad2( Handle:myself, bool:late, String:error[], err_max )
{
	CreateNative( "TG_GetPlayerTeam", Native_GetPlayerTeam );
	CreateNative( "TG_SetPlayerTeam", Native_SetPlayerTeam );
	CreateNative( "TG_IsPlayerRedOrBlue", Native_IsPlayerRedOrBlue );
	CreateNative( "TG_InOppositeTeams", Native_InOppositeTeams );
	CreateNative( "TG_GetTeamFromString", Native_GetTeamFromString );
	CreateNative( "TG_SwitchRandomRedToBlue", Native_SwitchRandomRedToBlue );
	CreateNative( "TG_IsGameTypeAvailable", Native_IsGameTypeAvailable );

	CreateNative( "TG_LoadPlayerWeapons", Native_LoadPlayerWeapons );

	CreateNative( "TG_FenceCreate", Native_FenceCreate );
	CreateNative( "TG_FenceDestroy", Native_FenceDestroy );
	CreateNative( "TG_FencePlayerCross", Native_FencePlayerCross );

	CreateNative( "TG_SpawnMark", Native_TG_SpawnMark );

	CreateNative( "TG_GetTeamCount", Native_GetTeamCount );
	CreateNative( "TG_ClearTeam", Native_ClearTeam );
	CreateNative( "TG_SetTeamsLock", Native_SetTeamsLock );
	CreateNative( "TG_GetTeamsLock", Native_GetTeamsLock );

	CreateNative( "TG_RegGame", Native_RegGame );
	CreateNative( "TG_UnRegGame", Native_UnRegGame );
	CreateNative( "TG_GetRegGames", Native_GetRegGames );

	CreateNative( "TG_ShowMainMenu", Native_ShowMainMenu );
	CreateNative( "TG_ShowGamesMenu", Native_ShowGamesMenu );
	CreateNative( "TG_ShowTeamsMenu", Native_ShowTeamsMenu );
	CreateNative( "TG_ShowFencesMenu", Native_ShowFencesMenu );

	CreateNative( "TG_AddMenuItem", Native_AddMenuItem );
	CreateNative( "TG_RemoveMenuItem", Native_RemoveMenuItem );
	CreateNative( "TG_GetMenuItemName", Native_GetMenuItemName );

	CreateNative( "TG_KvAddString", Native_KvAddString );
	CreateNative( "TG_KvSetString", Native_KvSetString );
	CreateNative( "TG_KvGetString", Native_KvGetString );

	CreateNative( "TG_StartGame", Native_StartGame );
	CreateNative( "TG_GetCurrentGameID", Native_GetCurrentGameID );
	CreateNative( "TG_IsCurrentGameID", Native_IsCurrentGameID );
	CreateNative( "TG_GetCurrentDataPack", Native_GetCurrentDataPack );
	CreateNative( "TG_GetCurrentStarter", Native_GetCurrentStarter );
	CreateNative( "TG_GetCurrentCustomName", Native_GetCurrentCustomName );
	CreateNative( "TG_GetGameName", Native_GetGameName );
	CreateNative( "TG_GetGameType", Native_GetGameType );
	CreateNative( "TG_GetGameRequiredFlag", Native_GetGameRequiredFlag );
	CreateNative( "TG_StopGame", Native_StopGame );

	CreateNative( "TG_GetGameStatus", Native_GetGameStatus );
	CreateNative( "TG_IsGameStatus", Native_IsGameStatus );

	CreateNative( "TG_PrintToChat", Native_PrintToChat );
	CreateNative( "TG_PrintToChatEx", Native_PrintToChatEx );

	CreateNative( "TG_LogMessage", Native_LogMessage );
	CreateNative( "TG_LogRoundMessage", Native_LogRoundMessage );
	CreateNative( "TG_LogGameMessage", Native_LogGameMessage );

	CreateDownloadTableConfigFileIfNotExist();
	CreateModulesConfigFileIfNotExist();

	LoadMenuItemsConfig();
	LoadGamesMenuConfig();

	RegPluginLibrary("TeamGames");
	
	return APLRes_Success;
}

public GameStartMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Cancel )
	{
		CloseHandle( Handle:TG_GetMenuCell( menu, "-DATAPACK-" ) );
		TG_ShowGamesMenu( client );
	}
	else if( action == MenuAction_Select )
	{
		decl String:info[ 64 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );

		if( StrEqual( info, "START_GAME" ) )
		{
			decl String:CustomName[ 64 ];
			decl String:GameIdStr[ 64 ];

			TG_GetMenuString( menu, "-GAMEID-", GameIdStr, sizeof( GameIdStr ) );
			TG_GetMenuString( menu, "-CUSTOMNAME-", CustomName, sizeof( CustomName ) );
			
			TG_StartGamePreparation( TG_GetMenuCell( menu, "-CLIENT-" ), GameIdStr, CustomName, Handle:TG_GetMenuCell( menu, "-DATAPACK-" ) );
		}
	}
}

TG_StartGamePreparation( client, String:id[ 64 ], String:CustomName[ 64 ], Handle:GameCustomDataPack )
{
	new String:name[ 64 ], String:team1[ 4096 ], String:team2[ 4096 ];
	new count1, count2;

	decl String:ErrorDescription[ 512 ];
	new ErrorCode = 0;

	strcopy( name, 64, g_GameList[ GetGameIndex( id ) ][ Name ] );

	if( g_Game[ GameProgress ] == InProgress || g_Game[ GameProgress ] == InPreparation )
	{
		TG_PrintToChat( client, "%t", "StartGame Error Another game in progress" );
		Format( ErrorDescription, sizeof( ErrorDescription ), "[ERROR - TG_StartGame #%d] \"%L\" tried to start preparation for game (name: \"%s\") (id: \"%s\") (error: \"Another game in progress\")", 1, client, name, id );
		
		ErrorCode = 1;
	}

	if( !IsGameTypeAvailable( g_GameList[ GetGameIndex( id ) ][ GameType ] ) )
	{
		TG_PrintToChat( client, "%t", "StartGame Error Bad team ratio" );
		Format( ErrorDescription, sizeof( ErrorDescription ), "[ERROR - TG_StartGame #%d] \"%L\" tried to start preparation for game (name: \"%s\") (id: \"%s\") (error: \"Bad teams ratio\")", 2, client, name, id );
		
		ErrorCode = 2;
	}

	new String:MenuFlag[ 64 ];
	GetConVarString( gh_MenuFlag, MenuFlag, sizeof( MenuFlag ) );

	if( !IsPlayerAlive( client ) && !StrEqual( MenuFlag, "" ) && !TG_ClientHasAdminFlag( client, MenuFlag ) )
	{
		TG_PrintToChat( client, "%t", "StartGame Error Alive only" );
		Format( ErrorDescription, sizeof( ErrorDescription ), "[ERROR - TG_StartGame #%d] \"%L\" tried to start preparation for game (name: \"%s\") (id: \"%s\") (error: \"activator is dead and doesn't have required admin flag\")", 4, client, name, id );
		
		ErrorCode = 4;
	}

	if( ErrorCode != 0 )
	{
		TG_LogRoundMessage( "GamePrepare", ErrorDescription );
		
		Call_StartForward( Forward_OnGameStartError );
		Call_PushString( id );
		Call_PushCell( client );
		Call_PushCell( ErrorCode );
		Call_PushString( ErrorDescription );
		Call_Finish();

		TG_KillHandle( GameCustomDataPack );
		return ErrorCode;
	}

	g_Game[ GameProgress ] = InPreparation;
	
	g_Game[ GameDataPack ] = GameCustomDataPack;
	strcopy( g_Game[ GameCustomName ], 64, CustomName );
	g_Game[ GameStarter ] = client;
	
	g_TeamsLock = true;

	strcopy( g_Game[ GameID ], 64, id );

	if( g_RoundLimit > 0 )
		g_RoundLimit--;

	TG_PrintToChatAll( "%t", "Game preparation", CustomName );
	if( g_DoubleMsg )
		TG_PrintToChatAll( "%t", "Game preparation", CustomName );

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_IsPlayerRedOrBlue( i ) )
		{
			SetEntityMoveType( i, MoveType:MOVETYPE_NONE );

			SavePlayerEquipment( i );
			Client_RemoveAllWeapons( i, "", true );

			if( TG_GetPlayerTeam( i ) == RedTeam && g_LogCvar )
			{
				Format( team1, sizeof( team1 ), "%s%L, ", team1, i );
				count1++;
			}

			if( TG_GetPlayerTeam( i ) == BlueTeam && g_LogCvar )
			{
				Format( team2, sizeof( team2 ), "%s%L, ", team2, i );
				count2++;
			}
		}

		if( IsClientConnected( i ) && IsClientInGame( i ) )
			PrintToConsole( i, "\n// ----------\n\t[TeamGames] %N started preparation for game \"%s\"\n// ----------\n", client, name );
	}

	new Handle:DataPack = CreateDataPack();
	WritePackString( DataPack, CustomName );
	WritePackCell( DataPack, client );

	Call_StartForward( Forward_OnGamePrepare );
	Call_PushString( g_Game[ GameID ] );
	Call_PushCell( client );
	Call_PushString( CustomName );
	Call_PushCell( g_Game[ GameDataPack ] );
	Call_Finish();

	if( g_LogCvar )
	{
		if( strlen( team1 ) > 1 )
			team1[ strlen( team1 ) - 2 ] = '\0';

		if( strlen( team2 ) > 1 )
			team2[ strlen( team2 ) - 2 ] = '\0';
		
		TG_LogRoundMessage(    "GamePrepare", "\"%L\" started preparation for game (name: \"%s\") (id: \"%s\")", client, name, g_Game[ GameID ] );
		TG_LogRoundMessage( _, "{" );
		TG_LogRoundMessage( _, "\tModified game name: \"%s\"", CustomName );
		TG_LogRoundMessage( _, "\tGame ID: \"%s\"", g_Game[ GameID ] );
		TG_LogRoundMessage( _, "\tActivator: \"%L\"", client );
		TG_LogRoundMessage( _, "" );
		TG_LogRoundMessage( _, "\tRedTeam: \"%s\" (number of players: \"%d\")", team1, count1 );
		TG_LogRoundMessage( _, "\tBlueTeam: \"%s\" (number of players: \"%d\")", team2, count2 );
		TG_LogRoundMessage( _, "}" );
	}

	if( IsSoundPrecached( g_GamePrepare[ 5 ] ) )
		EmitSoundToAll( g_GamePrepare[ 5 ], _, _, _, _, 1.0, _, _, _, _, _, _);

	g_Timer_CountDownGamePrepare_counter = 4;
	h_Timer_CountDownGamePrepare = CreateTimer( 1.0, Timer_CountDownGamePrepare, DataPack, TIMER_REPEAT );

	return 0;
}

//------------------------------------------------------------------------------------------------
// Timers

public Action:Timer_CountDownGamePrepare( Handle:timer, Handle:DataPack )
{
	if( g_Timer_CountDownGamePrepare_counter > 0 )
	{
		if( IsSoundPrecached( g_GamePrepare[ g_Timer_CountDownGamePrepare_counter ] ) )
			EmitSoundToAll( g_GamePrepare[ g_Timer_CountDownGamePrepare_counter ], _, _, _, _, 1.0, _, _, _, _, _, _);
		
		#if defined DEBUG
		LogMessage( "[TG DEBUG] Played file '%s'.", g_GamePrepare[ g_Timer_CountDownGamePrepare_counter ] );
		#endif
		
		g_Timer_CountDownGamePrepare_counter--;
	}
	else
	{
		if( IsSoundPrecached( g_GameStart ) )
			EmitSoundToAll( g_GameStart, _, _, _, _, 1.0, _, _, _, _, _, _ );

		if( h_Timer_CountDownGamePrepare != INVALID_HANDLE )
		{
			KillTimer( h_Timer_CountDownGamePrepare );
			h_Timer_CountDownGamePrepare = INVALID_HANDLE;
		}

		g_Timer_CountDownGamePrepare_counter = 4;

		g_Game[ GameProgress ] = InProgress;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( TG_IsTeamRedOrBlue( g_PlayerData[ i ][ Team ] ) )
				SetEntityMoveType( i, MoveType:MOVETYPE_ISOMETRIC );
		}

		decl String:CustomName[ 64 ];
		new activator = -1;
		ResetPack( DataPack );
		ReadPackString( DataPack, CustomName, sizeof( CustomName ) );
		activator = ReadPackCell( DataPack );
		CloseHandle( DataPack );

		TG_PrintToChatAll( "%t", "Game started", CustomName );
		if( g_DoubleMsg )
			TG_PrintToChatAll( "%t", "Game started", CustomName );

		if( GetConVarInt( gh_FriendlyFire ) == 2 )
			SetConVarStringSilent( "mp_friendlyfire", "1" );

		Call_StartForward( Forward_OnGameStart );
		Call_PushString( g_Game[ GameID ] );
		Call_PushCell( activator );
		Call_PushString( CustomName );
		Call_PushCell( g_Game[ GameDataPack ] );
		Call_Finish();

		TG_LogRoundMessage( "GameStart", "game started (name: \"%s\") (id: \"%s\")", g_GameList[ GetGameIndex( g_Game[ GameID ] ) ][ Name ], g_Game[ GameID ] );
	}

	return Plugin_Continue;
}
