// ConVars
new Handle:gh_TeamDiff = INVALID_HANDLE;
new Handle:gh_MoveRebels = INVALID_HANDLE, bool:g_MoveRebels = true;
new Handle:gh_NotifyPlayerTeam = INVALID_HANDLE, g_NotifyPlayerTeam = 1, Handle:gh_NotifyTimer = INVALID_HANDLE;
new Handle:gh_ChangeTeamDelay = INVALID_HANDLE, Float:g_ChangeTeamDelay;
new Handle:gh_MoveSurvivors = INVALID_HANDLE;

new String:g_TeamSkin[ 3 ][ PLATFORM_MAX_PATH ];

new bool:g_TeamsLock = false;

new g_BlickColorRed[ 3 ] = { 255, 255, 0 };
new g_BlickColorGreen[ 3 ] = { 255, 0, 0 };
new g_BlickColorBlue[ 3 ] = { 255, 0, 255 };

enum OverlayStruct
{
	String:OverlayName[ PLATFORM_MAX_PATH ]
}
new g_Overlay[ 3 ][ OverlayStruct ];

public Action:Timer_HintTeam( Handle:timer )
{		
	if( g_NotifyPlayerTeam == 0 || g_NotifyPlayerTeam == 4 )
	{
		TG_KillTimer( timer );
		return Plugin_Handled;		
	}
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !Client_IsIngame( i ) )
			continue;
		
		NotifyPlayerTeam( i, g_PlayerData[ i ][ Team ] );
	}
	
	return Plugin_Handled;
}

public Action:Timer_SwitchAble( Handle:timer, any:client )
{		
	g_PlayerData[ client ][ AbleToSwitch ] = true;	
	return Plugin_Handled;
}

TeamsMenu( client )
{
	new Handle:menu = CreateMenu( TeamsMenu_Handler );
	new String:TransMsg[ 256 ];
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu teams title", client );
	SetMenuTitle( menu, TransMsg );
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu teams move to red", client );
	AddMenuItem( menu, "red", TransMsg );
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu teams move to blue", client );
	AddMenuItem( menu, "blue", TransMsg );
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu teams move to none", client );
	AddMenuItem( menu, "none", TransMsg );
	
	AddMenuItem( menu, "spacer", "spacer", ITEMDRAW_SPACER );
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu teams move all to none", client );
	AddMenuItem( menu, "AllNone", TransMsg );
	
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public TeamsMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Select )
	{
		decl String:info[ 32 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		if( StrEqual( info, "AllNone" ) )
		{
			ClearTeams();
			TeamsMenu( client );
		}
		
		new target = GetClientAimTarget( client, false );
		if( target > 0 )
		{
			#if defined DEBUG
			LogMessage( "[TG DEBUG] Switch player %N to team %d (%s).", target, _:TG_GetTeamFromString( info ), info );
			#endif
			
			SwitchToTeam( client, target, TG_GetTeamFromString( info ) );
		}
		
		TeamsMenu( client );
	}
	else if( action == MenuAction_Cancel && param2 == MenuCancel_ExitBack )
	{
		MainMenu( client );
	}
}

SwitchToTeam( any:activator, any:client, TG_Team:team )
{
	if( team == ErrorTeam )
		return 5;
	
	if( g_TeamsLock && activator >= 0 )
		return 1;
	
	if( !Client_IsIngame( client ) || GetClientTeam( client ) == CS_TEAM_CT || g_PlayerData[ client ][ Team ] == team || !TG_IsTeamValid( team ) )
		return 4;
	
	if( activator >= 0 && !g_PlayerData[ client ][ AbleToSwitch ] )
		return 2;
	
	new Action:result = Plugin_Continue;
	Call_StartForward( Forward_OnPlayerTeam );
	Call_PushCell( client );
	Call_PushCell( activator );
	Call_PushCell( g_PlayerData[ client ][ Team ] );
	Call_PushCell( team );
	Call_Finish( result );
	if( result != Plugin_Continue )
		return 3;
		
	decl String:ActivatorName[ 64 ], String:ClientName[ 64 ], String:GameName[ 64 ];
	GetClientName( client, ClientName, sizeof( ClientName ) );
	
	if( Client_IsIngame( activator ) )
		GetClientName( activator, ActivatorName, sizeof( ActivatorName ) );
	
	if( !StrEqual( g_Game[ GameID ], "Core_NoGame" ) )
		Format( GameName, 64, "\t[%s]", g_Game[ GameID ] );
	
	if( g_PlayerData[ client ][ Team ] == NoneTeam )
		GetClientModel( client, g_PlayerData[ client ][ DefaultModel ], PLATFORM_MAX_PATH );
	
	g_PlayerData[ client ][ Team ] = team;
	
	if( g_ChangeTeamDelay != 0.0 )
	{
		g_PlayerData[ client ][ AbleToSwitch ] = false;
		CreateTimer( g_ChangeTeamDelay, Timer_SwitchAble, client );
	}
	
	Blick( client, team );
	NotifyPlayerTeam( client, team, false );
	
	if( GetConVarInt( gh_TeamDiff ) == 0 )
		ColorPlayer( client, team );
	else if( GetConVarInt( gh_TeamDiff ) == 1 )
		ModelPlayer( client, team );
	
	if( Client_IsIngame( activator ) )
	{
		if( team == NoneTeam )
			TG_PrintToChatAll( "%t", "Player moved to None team", ClientName );
		else if( team == RedTeam )
			TG_PrintToChatAll( "%t", "Player moved to Red team", ActivatorName, ClientName );
		else if( team == BlueTeam )
			TG_PrintToChatAll( "%t", "Player moved to Blue team", ActivatorName, ClientName );
	}
	else if( activator == -1 && g_Game[ GameProgress ] != NoGame )
	{
		if( team == RedTeam )
			TG_PrintToChatAll( "%t", "Player moved to Red team by module", g_GameList[ GetGameIndex( g_Game[ GameID ] ) ][ Name ], ClientName );
		else if( team == BlueTeam )
			TG_PrintToChatAll( "%t", "Player moved to Blue team by module", g_GameList[ GetGameIndex( g_Game[ GameID ] ) ][ Name ], ClientName );
	}
	
	if( g_LogCvar )
	{
		if( Client_IsIngame( activator ) )
			TG_LogRoundMessage( "SetPlayerTeam", "\"%L\" moved \"%L\" to \"team %d\"", activator, client, _:team );
		else
		{
			if( g_Game[ GameProgress ] != NoGame )
				TG_LogGameMessage( g_Game[ GameID ], "SetPlayerTeam", "\"%L\" was moved to \"team %d\"", client, _:team );
			else
				TG_LogGameMessage( "Core_NoGame", "SetPlayerTeam", "\"%L\" was moved to \"team %d\"", client, _:team );
		}
	}
	
	#if defined DEBUG
	LogMessage( "[TG DEBUG] Player %N switched to team %d.", client, _:team );
	#endif
	
	return 0;
}

ModelPlayer( client, TG_Team:team )
{
	if( team == NoneTeam )
	{
		SetEntityModel( client, g_PlayerData[ client ][ DefaultModel ] );
	}
	else if( team == RedTeam || team == BlueTeam )
	{
		if( StrEqual( g_TeamSkin[ team ], "" ) || !IsModelPrecached( g_TeamSkin[ team ] ) )
			return 1;
		
		if( !FileExists( g_TeamSkin[ team ], false ) && !FileExists( g_TeamSkin[ team ], true ) )
			return 2;
		
		SetEntityModel( client, g_TeamSkin[ team ] );
	}
	
	return 0;
}

ColorPlayer( client, TG_Team:team )
{
	if( team == NoneTeam )
		DispatchKeyValue( client, "rendercolor", "255 255 255" );
	else if( team == RedTeam )
		DispatchKeyValue( client, "rendercolor", "255 0 0" );
	else if( team == BlueTeam )
		DispatchKeyValue( client, "rendercolor", "0 0 255" );
	
	return 0;
}

Blick( client, TG_Team:team )
{
	if( !TG_IsTeamValid( team ) )
		return 1;
	
	new Handle:hFadeClient = StartMessageOne( "Fade", client );
	BfWriteShort( hFadeClient, 90 ); // upraveno - 30 -> 90
	BfWriteShort( hFadeClient, 130 ); // upraveno - 70 -> 130
	BfWriteShort( hFadeClient, ( FFADE_PURGE | FFADE_IN | FFADE_STAYOUT ) );
	BfWriteByte( hFadeClient, g_BlickColorRed[ _:team ] );
	BfWriteByte( hFadeClient, g_BlickColorGreen[ _:team ] );
	BfWriteByte( hFadeClient, g_BlickColorBlue[ _:team ] );
	
	if( team == NoneTeam )
		BfWriteByte( hFadeClient, 90 ); // 50 -> 90
	else
		BfWriteByte( hFadeClient, 150 ); // 120 -> 150
	
	EndMessage();
	
	EmitSoundToClient( client, "buttons/blip2.wav", _, SNDCHAN_AUTO );
	
	return 0;
}

NotifyPlayerTeam( client, TG_Team:team, bool:IgnoreNoneTeam = true )
{
	if( g_NotifyPlayerTeam == 0 )
		return 1;
	
	if( !TG_IsTeamValid( team ) )
		return 2;
	
	if( IgnoreNoneTeam && team == NoneTeam )
		return 3;
	
	decl String:msg[ 256 ];
	
	if( team == NoneTeam )
		Format( msg, sizeof( msg ), "%t", "Hint None team" );
	else if( team == RedTeam )
		Format( msg, sizeof( msg ), "%t", "Hint Red team" );
	else if( team == BlueTeam )
		Format( msg, sizeof( msg ), "%t", "Hint Blue team" );
	
	if( g_NotifyPlayerTeam == 1 )
	{
		Client_PrintKeyHintText( client, msg );
	}
	else if( g_NotifyPlayerTeam == 2 )
	{
		Client_PrintHintText( client, msg );
	}
	else if( g_NotifyPlayerTeam == 3 )
	{
		new Handle:hndl = CreateHudSynchronizer();

		if( hndl != INVALID_HANDLE )
		{
			if( team == NoneTeam )
				SetHudTextParams( -1.0, 0.85, 5.0, 200, 200, 200, 255 );
			else if( team == RedTeam )
				SetHudTextParams( -1.0, 0.85, 5.0, 255, 0, 0, 255 );
			else if( team == BlueTeam )
				SetHudTextParams( -1.0, 0.85, 5.0, 0, 0, 255, 255 );
			
			ShowSyncHudText( client, hndl, msg );
			CloseHandle( hndl );
		}
	}
	else if( g_NotifyPlayerTeam == 4 )
	{
		if( team == NoneTeam )
			ClientCommand( client, "r_screenoverlay \"\"" );
		else if( TG_IsTeamRedOrBlue( team ) )
			ClientCommand( client, "r_screenoverlay \"%s\"", g_Overlay[ team ][ OverlayName ] );
	}
	
	return 0;
}

ClearTeam( TG_Team:team )
{
	if( !TG_IsTeamRedOrBlue( team ) )
		return -1;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !Client_IsIngame( i ) )
			continue;
		
		if( g_PlayerData[ i ][ Team ] == team )
			SwitchToTeam( -1, i, NoneTeam );
	}
	
	return 0;
}

ClearTeams()
{
	ClearTeam( RedTeam );
	ClearTeam( BlueTeam );
}
