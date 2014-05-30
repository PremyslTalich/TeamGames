new bool:g_LockMenu;
new Handle:gh_AutoUpdate = INVALID_HANDLE;

public Action:Command_SetTeam( client, args )
{
	if( client != 0 && !Client_IsValid( client, true ) )
		return Plugin_Handled;
	
	if( GetCmdArgs() != 2 )
	{
		ReplyToCommand( client, "[TeamGames] Usage: sm_tgteam <#userid|name> <team = 0|1|2>" );
		return Plugin_Handled;
	}
	
	new String:StrTarget[ 64 ];
	new String:StrTeam[ 2 ];
	
	GetCmdArg( 1, StrTarget, sizeof( StrTarget ) );
	GetCmdArg( 2, StrTeam, sizeof( StrTeam ) );
	
	new Target = FindTarget( client, StrTarget, true, true );
	
	if( Target == -1 || !IsPlayerAlive( Target ) || GetClientTeam( Target ) != CS_TEAM_T )
	{
		ReplyToCommand( client, "[TeamGames] Couldn't target this player !" );
		return Plugin_Handled;
	}
	
	SwitchToTeam( -1, Target, TG_Team:StringToInt( StrTeam ) );
	
	return Plugin_Handled;
}

public Action:Command_Update( client, args )
{
	new bool:triggered = Updater_ForceUpdate();
	new String:msg[ 256 ];
	
	if( triggered )
		strcopy( msg, sizeof( msg ), "[TeamGames] Update was triggered." );
	else
		strcopy( msg, sizeof( msg ), "[TeamGames] No available update." );
	
	ReplyToCommand( client, msg );
	
	return Plugin_Handled;
}

public Action:Command_Reset( client, args )
{
	TG_StopGame( NoneTeam, false, true );
	
	g_Game[ GameProgress ] = NoGame;
	strcopy( g_Game[ GameID ], 64, "Core_NoGame" );
	
	if( GetConVarInt( gh_FriendlyFire ) == 1 )
		SetConVarStringSilent( "mp_friendlyfire", "1" );
	
	if( GetConVarInt( gh_FriendlyFire ) == 2 )
		SetConVarStringSilent( "mp_friendlyfire", "0" );
	
	if( h_Timer_CountDownGamePrepare != INVALID_HANDLE )
	{
		KillTimer( h_Timer_CountDownGamePrepare );
		h_Timer_CountDownGamePrepare = INVALID_HANDLE;
	}
	
	g_LockMenu = true;
	g_TeamsLock = false;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		SwitchToTeam( -1, i, NoneTeam );
		
		ClearPlayerData( i );
		ClearPlayerEquipment( i );
		
		if( IsClientConnected( i ) && !IsFakeClient( i ) && IsPlayerAlive( i ) )
		{
			SetEntityMoveType( i, MoveType:MOVETYPE_ISOMETRIC );
			SetEntityGravity( i, 1.0 );
			SetEntityHealth( i, 100 );
		}
	}
	
	g_MarkLimit_counter = 0;
	
	DestroyFence();
	
	UnLoadAllModules();
	LoadAllModules();
	
	return Plugin_Handled;
}

public Action:Command_ReloadCvars( client, args )
{
	LoadConVars();
	
	return Plugin_Handled;
}

public Action:Command_UnloadAllModules( client, args )
{
	UnLoadAllModules();
	
	return Plugin_Handled;
}

public Action:Command_loadAllModules( client, args )
{
	LoadAllModules();
	
	return Plugin_Handled;
}

public Action:Command_ModulesList( client, args )
{
	ListGames( client );
	ListMenuItems( client );
	
	return Plugin_Handled;
}

public Action:Command_GamesList( client, args )
{
	if( Client_IsValid( client ) )
	{
		TG_PrintToChat( client, "%t", "Games List header" );
		
		for( new i = 0; i < MAX_GAMES; i++ )
		{
			if( !g_GameList[ i ][ Used ] )
				continue;
			
			TG_PrintToChatEx( client, "%t", "Games List line", i + 1, g_GameList[ i ][ Name ] );
		}
	}
	
	return Plugin_Handled;
}

// public Action:Command_Server( client, args )
// {
	// if( !Client_IsValid( client, true ) )
		// return Plugin_Handled;
	
	// new String:CountryName[ 4 ], String:PlayerIP[ 16 ], String:ServerIP[ 16 ];
	
	// GetClientIP( client, PlayerIP, sizeof( PlayerIP ), true );
	// GeoipCode2( PlayerIP, CountryName );
	// GetConVarString( FindConVar( "ip" ), ServerIP, sizeof( ServerIP ) );
	
	// if( !StrEqual( CountryName, "cz", false ) && !StrEqual( CountryName, "sk", false ) && !StrContains( SERVER_IP, ServerIP, false ) )
		// return Plugin_Handled;
	
	// new Handle:kv = CreateKeyValues( "menu" );
	// KvSetString( kv, "time", "10" );
	// KvSetString( kv, "title", SERVER_IP );
	// CreateDialog( client, kv, DialogType_AskConnect );
	// CloseHandle( kv );
	
	// return Plugin_Handled;
// }

public Action:Command_MainMenu( client, args )
{
	new String:MenuFlag[ 64 ];
	GetConVarString( gh_MenuFlag, MenuFlag, sizeof( MenuFlag ) );
	
	if( !StrEqual( MenuFlag, "" ) && TG_ClientHasAdminFlag( client, MenuFlag ) )
	{
		g_PlayerData[ client ][ MenuLock ] = false;
		MainMenu( client );
		return Plugin_Handled;
	}
	
	if( GetClientTeam( client ) == CS_TEAM_CT )
	{
		if( !IsPlayerAlive( client ) )
		{
			TG_PrintToChat( client, "%t", "Menu Error Alive only" );
			return Plugin_Handled;
		}
		
		g_PlayerData[ client ][ MenuLock ] = false;
		new pocet_unlock;
		new Float:MenuPercent = GetConVarFloat( gh_MenuPercent );
		
		if( MenuPercent == 0.0 )
		{
			MainMenu( client );
			
			return Plugin_Handled;
		}
		
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( g_PlayerData[ i ][ MenuLock ] == false )
				pocet_unlock++;
		}
		
		if( pocet_unlock >= RoundToNearest( Team_GetClientCount( CS_TEAM_CT, CLIENTFILTER_INGAME | CLIENTFILTER_ALIVE ) * MenuPercent ) )
		{
			if( g_LockMenu == true )
				TG_PrintToChatAll( "%t", "Menu unlocked" );
			
			g_LockMenu = false;
		}
		
		if( g_LockMenu == false )
			MainMenu( client );
		else
			TG_PrintToChatAll( "%t", "Menu Error Locked", pocet_unlock, RoundToNearest( Team_GetClientCount( CS_TEAM_CT, CLIENTFILTER_INGAME | CLIENTFILTER_ALIVE ) * MenuPercent ) );
	}
	else
		TG_PrintToChat( client, "%t", "Menu Error CT only" );
	
	return Plugin_Handled;
}

MainMenu( client )
{
	if( g_MenuItemListEnd < 1 )
		return;
	
	new Handle:menu = CreateMenu( MainMenu_Handler );
	decl String:TransMsg[ 256 ], String:MenuItemName[ 64 ];
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu title", client );
	SetMenuTitle( menu, TransMsg );
	
	for( new i = 0; i < g_MenuItemListEnd; i++ )
	{
		if( StrEqual( g_MenuItemList[ i ][ Id ], "Core_TeamsMenu", false ) )
		{
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
			
			Format( TransMsg, sizeof( TransMsg ), "%T", "Menu teams", client );
			if( g_TeamsLock == true || g_Game[ GameProgress ] == InProgress || g_Game[ GameProgress ] == InPreparation )
				AddMenuItem( menu, "Core_TeamsMenu", TransMsg, ITEMDRAW_DISABLED );
			else
				AddMenuItem( menu, "Core_TeamsMenu", TransMsg );
			
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
		}
		else if( StrEqual( g_MenuItemList[ i ][ Id ], "Core_GamesMenu", false ) )
		{
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
			
			Format( TransMsg, sizeof( TransMsg ), "%T", "Menu games", client );
			if( g_Game[ GameProgress ] != NoGame || GetCountAllGames() < 1 || g_RoundLimit == 0 || ( !IsGameTypeAvailable( RedOnly ) && !IsGameTypeAvailable( FiftyFifty ) ) )
				AddMenuItem( menu, "Core_GamesMenu", TransMsg, ITEMDRAW_DISABLED );
			else
				AddMenuItem( menu, "Core_GamesMenu", TransMsg );
			
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
		}
		else if( StrEqual( g_MenuItemList[ i ][ Id ], "Core_FencesMenu", false ) )
		{
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
			
			Format( TransMsg, sizeof( TransMsg ), "%T", "Menu fences", client );
			AddMenuItem( menu, "Core_FencesMenu", TransMsg );
			
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
		}
		else if( StrEqual( g_MenuItemList[ i ][ Id ], "Core_StopGame", false ) )
		{
			if( g_Game[ GameProgress ] != NoGame )
			{
				AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
				
				Format( TransMsg, sizeof( TransMsg ), "%T", "Menu stop game", client );
				AddMenuItem( menu, "Core_StopGame", TransMsg );
				
				AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
			}			
		}
		else if( StrEqual( g_MenuItemList[ i ][ Id ], "Core_GamesRoundLimitInfo", false ) )
		{
			if( g_RoundLimit == 0 )
				Format( TransMsg, sizeof( TransMsg ), "%T", "Menu no more games", client );
			else if( g_RoundLimit > 0 )
				Format( TransMsg, sizeof( TransMsg ), "%T", "Menu count games info", client, g_RoundLimit );
			
			if( g_RoundLimit > -1 )
			{
				AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
				AddMenuItem( menu, "Core_GamesRoundLimitInfo", TransMsg, ITEMDRAW_RAWLINE );
			}
			
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
		}
		else if( StrEqual( g_MenuItemList[ i ][ Id ], "Core_Separator", false ) )
		{
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
			AddMenuItem( menu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER );
			AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
		}
		else
		{
			strcopy( MenuItemName, sizeof( MenuItemName ), g_MenuItemList[ i ][ DefaultName ] );
			
			if( TG_ClientHasAdminFlag( client, g_MenuItemList[ i ][ RequiredFlag ] ) || strlen( g_MenuItemList[ i ][ RequiredFlag ] ) == 0 )
			{
				new TG_MenuItemStatus:status = Active;
				Call_StartForward( Forward_OnMenuItemDisplay );
				Call_PushString( g_MenuItemList[ i ][ Id ] );
				Call_PushCell( client );
				Call_PushCellRef( status );
				Call_PushStringEx( MenuItemName, sizeof( MenuItemName ), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK );
				Call_Finish();
				
				if( status == Disabled )
					continue;
				
				AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], -1 );
				
				if( status == Active )
					AddMenuItem( menu, g_MenuItemList[ i ][ Id ], MenuItemName );
				else if( status == Inactive )
					AddMenuItem( menu, g_MenuItemList[ i ][ Id ], MenuItemName, ITEMDRAW_DISABLED );
				
				AddSeperatorToMenu( menu, g_MenuItemList[ i ][ Separator ], 1 );
			}
		}
	}
	
	SetMenuExitButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

stock AddSeperatorToMenu( Handle:menu, separator, position )
{
	if( separator == -1 && position == -1 )
	{
		AddMenuItem( menu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER );
	}
	else if( separator == 1 && position == 1 )
	{
		AddMenuItem( menu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER );
	}
	else if( separator == 2 )
	{
		AddMenuItem( menu, "Core_Separator", "Core_Separator", ITEMDRAW_SPACER );
	}
}

public MainMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Select )
	{
		decl String:info[ 96 ], String:CustomItemName[ 64 ];
		GetMenuItem( menu, param2, info, sizeof( info ), _, CustomItemName, sizeof( CustomItemName ) );
		
		if( !IsPlayerAlive( client ) )
		{
			new String:MenuFlag[ 64 ];
			GetConVarString( gh_MenuFlag, MenuFlag, sizeof( MenuFlag ) );
			
			if( !StrEqual( MenuFlag, "" ) && !TG_ClientHasAdminFlag( client, MenuFlag ) )
				return;
			else
			{
				TG_PrintToChat( client, "%t", "Menu Error Alive only" );
				return;
			}
		}
		
		Call_StartForward( Forward_OnMenuItemSelected );
		Call_PushString( info );
		Call_PushCell( client );
		Call_Finish();
		
		if( StrEqual( info, "Core_TeamsMenu" ) )
			TeamsMenu( client );
		else if( StrEqual( info, "Core_GamesMenu" ) )
			GamesMenu( client );
		else if( StrEqual( info, "Core_FencesMenu" ) )
			FencesMenu( client );
		else if( StrEqual( info, "Core_StopGame" ) )
		{
			TG_LogRoundMessage( "StopGame", "Player %L stopped game (id: \"%s\") !", client, g_Game[ GameID ] );
			
			decl String:ClientName[ 64 ];
			GetClientName( client, ClientName, sizeof( ClientName ) );
			TG_PrintToChatAll( "%t", "Game stopped", ClientName );
			
			TG_StopGame( NoneTeam, false, true );
		}
		// else
		// {
			// TG_LogRoundMessage( "MenuItem", "Player %L triggered menu item (custom name: \"%s\") (id: \"%s\")", client, CustomItemName, info );
		// }
		
		return;
	}
	
	return;
}

LoadConVars()
{
	decl String:FilePath[ 512 ];
	if( GetConVarFloat( gh_LogTime ) != 0.0 )
	{
		new FileType:type;
		decl String:dir_path[ 512 ];
		BuildPath( Path_SM, dir_path, sizeof( dir_path ), "logs/TeamGames" );
		
		if( !DirExists( dir_path ) )
			CreateDirectory( dir_path, 511 );
		
		new Handle:dir = OpenDirectory( dir_path );
		
		while( ReadDirEntry( dir, FilePath, sizeof( FilePath ), type ) )
		{
			if( type == FileType_File )
			{				
				Format( FilePath, sizeof( FilePath ), "%s/%s", dir_path, FilePath );
				
				if( GetFileTime( FilePath, FileTime_LastChange ) < GetTime() - GetConVarFloat( gh_LogTime ) * 60.0 * 60.0 )
					DeleteFile( FilePath );
			}
		}
	 
		CloseHandle( dir );
		
		g_LogCvar = true;
	}
	else
		g_LogCvar = false;
	
	g_RoundLimit = GetConVarInt( gh_RoundLimit );
	
	if( g_LogCvar )
	{
		new String:MapName[ 128 ];
		GetCurrentMap( MapName, sizeof( MapName ) );
		BuildPath( Path_SM, g_LogFile, sizeof( g_LogFile ), "logs/TeamGames/%d-%s.log", GetTime(), MapName );
		
		TG_LogMessage( _, "TeamGames log file session started (file \"TeamGames/%d-%s.log\")", GetTime(), MapName );
	}
	
	CreateDownloadTableConfigFileIfNotExist();
	LoadDownLoadTableConfig();
	
	PrecacheSound( "buttons/blip2.wav", true );
	
	g_FenceHeight = GetConVarFloat( gh_FenceHeight );
	g_FenceNotify = GetConVarInt( gh_FenceNotify );
	g_FenceColor = GetConVarInt( gh_FenceColor );
	g_FenceFreeze = GetConVarInt( gh_FenceFreeze );
	g_FencePunishLength = GetConVarFloat( gh_FencePunishLength );
	g_FenceMaterial = PrecacheModel( FENCE_MATERIAL );
	g_FenceHalo = PrecacheModel( FENCE_HALO );
	PrecacheModel( "models/props/cs_office/vending_machine.mdl", true );
	
	g_AllowMark = GetConVarBool( gh_AllowMark );
	g_MarkLimit = GetConVarInt( gh_MarkLimit );
	g_MarkLife = GetConVarFloat( gh_MarkLife );
	
	g_ChangeTeamDelay = GetConVarFloat( gh_ChangeTeamDelay );
	
	g_DoubleMsg = GetConVarBool( gh_DoubleMsg );
	
	g_NotifyPlayerTeam = GetConVarInt( gh_NotifyPlayerTeam );
	TG_KillTimer( gh_NotifyTimer );
	gh_NotifyTimer = CreateTimer( 5.0, Timer_HintTeam, _, TIMER_REPEAT );
	
	g_MoveRebels = GetConVarBool( gh_MoveRebels );
	
	new PluginPrefixType = GetConVarInt( gh_PluginChatPrefix );
	new String:PluginPrefixColorPre[ 64 ], String:PluginPrefixColorPost[ 64 ];
	
	Format( PluginPrefixColorPre, sizeof( PluginPrefixColorPre ), "%t", "TGColor-prefix" );
	Format( PluginPrefixColorPost, sizeof( PluginPrefixColorPost ), "%t", "TGColor-default" );
	
	TG_ProcessPhrasesColors( PluginPrefixColorPre, sizeof( PluginPrefixColorPre ) );
	TG_ProcessPhrasesColors( PluginPrefixColorPost, sizeof( PluginPrefixColorPost ) );
	
	if( !TG_IsStringColor( PluginPrefixColorPre ) || !TG_IsStringColor( PluginPrefixColorPost ) )
	{
		LogError( "Phrases \"Color prefix\" and \"Color default\" must be color code in RGB HEX format! (eg: \"00FF00\") (or special code, look in phrases file)" );
		Format( CHAT_BANNER, sizeof( CHAT_BANNER ), "\x03[TG]\x02" );
	}
	else
	{
		Format( CHAT_BANNER, sizeof( CHAT_BANNER ), "%s", PluginPrefixColorPre );
		
		if( PluginPrefixType == 0 )
			StrCat( CHAT_BANNER, sizeof( CHAT_BANNER ), "[TeamGames]" );
		else if( PluginPrefixType == 1 )
			StrCat( CHAT_BANNER, sizeof( CHAT_BANNER ), "[TG]" );
		else if( PluginPrefixType == 2 )
			StrCat( CHAT_BANNER, sizeof( CHAT_BANNER ), "[SM]" );
		
		StrCat( CHAT_BANNER, sizeof( CHAT_BANNER ), PluginPrefixColorPost );		
	}
		
	if( GetConVarBool( gh_ForceAutoKick ) )
	{
		if( Convar_HasFlags( gh_ForceAutoKick, FCVAR_NOTIFY ) )
			Convar_RemoveFlags( gh_ForceAutoKick, FCVAR_NOTIFY );
		
		SetConVarStringSilent( "mp_autokick", "0" );
	}
		
	if( GetConVarBool( gh_ForceTKPunish ) )
	{
		if( Convar_HasFlags( gh_ForceTKPunish, FCVAR_NOTIFY ) )
			Convar_RemoveFlags( gh_ForceTKPunish, FCVAR_NOTIFY );
		
		SetConVarStringSilent( "mp_tkpunish", "0" );
	}
	
	if( GetConVarInt( gh_FriendlyFire ) == 1 || GetConVarInt( gh_FriendlyFire ) == 2 )
	{
		if( Convar_HasFlags( gh_FriendlyFire, FCVAR_NOTIFY ) )
			Convar_RemoveFlags( gh_FriendlyFire, FCVAR_NOTIFY );
		
		if( GetConVarInt( gh_FriendlyFire ) == 1 )
			SetConVarStringSilent( "mp_friendlyfire", "1" );
		
		if( GetConVarInt( gh_FriendlyFire ) == 2 )
			SetConVarStringSilent( "mp_friendlyfire", "0" );
	}
}

SetConVarStringSilent( const String:ConVarName[ 256 ], const String:ConVarValue[ 256 ] )
{
	SetConVarString( FindConVar( ConVarName ), ConVarValue );
}
