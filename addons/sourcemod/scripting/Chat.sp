new Handle:gh_DoubleMsg = INVALID_HANDLE, bool:g_DoubleMsg = true;
new Handle:gh_AllowTeamPrefix = INVALID_HANDLE;
new Handle:gh_PluginChatPrefix = INVALID_HANDLE, String:CHAT_BANNER[ 32 ];

public Action:Hook_TextMsg( UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init )
{
	decl String:buffer[ MAX_NAME_LENGTH ];
	buffer[ 0 ] = EOS;
	BfReadString( bf, buffer, sizeof( buffer ), false );
	
	if( g_Game[ GameProgress ] == NoGame )
		return Plugin_Continue;
	
	if( StrContains( buffer, "Game_teammate_attack" ) != -1 || StrContains( buffer, "Killed_Teammate" ) != -1  )
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action:OnChatMessage( &author, Handle:recipients, String:name[], String:message[] )
{
	if( GetConVarBool( gh_AllowTeamPrefix ) == false )
		return Plugin_Continue;
	
	if( g_PlayerData[ author ][ Team ] == RedTeam )
	{
		Format( name, MAXLENGTH_NAME, "%t%t \x03%s", "TGColor-redteam", "Chat prefix Red team", name );
		return Plugin_Changed;
	}
	else if( g_PlayerData[ author ][ Team ] == BlueTeam )
	{
		Format( name, MAXLENGTH_NAME, "%t%t \x03%s", "TGColor-blueteam", "Chat prefix Blue team", name );
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
