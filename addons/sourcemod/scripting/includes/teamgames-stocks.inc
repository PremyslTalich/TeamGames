//------------------------------------------------------------------------------------------------
// All stocks
//------------------------------------------------------------------------------------------------
/*
*/
//------------------------------------------------------------------------------------------------

#include <cstrike>

/**
 * Get the other team index.
 *
 * @param team			Team index (1 = RedTeam, 2 = BlueTeam).
 * @return				Return {BlueTeam (if @param team == RedTeam), RedTeam (if @param team == BlueTeam)}.
 */
stock TG_Team:TG_GetOppositeTeam( TG_Team:team )
{
	if( team == RedTeam )
		return BlueTeam;
	else if( team == BlueTeam )
		return RedTeam;
	else
		return NoneTeam;
}

stock bool:TG_IsTeamRedOrBlue( TG_Team:team )
{
	if( team == RedTeam || team == BlueTeam )
		return true;
	else
		return false;
}

stock bool:TG_IsTeamValid( TG_Team:team )
{
	if( TG_IsTeamRedOrBlue( team ) || team == NoneTeam )
		return true;
	else
		return false;
}

stock TG_PushMenuString( Handle:hndl, const String:id[], const String:data[] )
{
	AddMenuItem( hndl, id, data, ITEMDRAW_NOTEXT );
}

stock TG_PushMenuCell( Handle:hndl, const String:id[], data )
{
	decl String:DataString[ 64 ];
	IntToString( data, DataString, sizeof( DataString ) );
	AddMenuItem( hndl, id, DataString, ITEMDRAW_NOTEXT );
}

stock TG_PushMenuFloat( Handle:hndl, const String:id[], Float:data )
{
	decl String:DataString[ 64 ];
	FloatToString( data, DataString, sizeof( DataString ) );
	AddMenuItem( hndl, id, DataString, ITEMDRAW_NOTEXT );
}

stock bool:TG_GetMenuString( Handle:hndl, const String:id[], String:Buffer[], size )
{
	new ItemCount = GetMenuItemCount( hndl );
	decl String:info[ 64 ], String:data[ 64 ];
	
	for( new i = 0; i < ItemCount; i++ )
	{
		GetMenuItem( hndl, i, info, sizeof( info ), _, data, sizeof( data ) );
		
		if( StrEqual( info, id ) )
		{	
			strcopy( Buffer, size, data );
			return true;
		}
	}	
	return false;
}

stock TG_GetMenuCell( Handle:hndl, const String:id[], DefaultValue = 0 )
{
	new ItemCount = GetMenuItemCount( hndl );
	decl String:info[ 64 ], String:data[ 64 ];
	
	for( new i = 0; i < ItemCount; i++ )
	{
		GetMenuItem( hndl, i, info, sizeof( info ), _, data, sizeof( data ) );
		
		if( StrEqual( info, id ) )
			return StringToInt( data );
	}	
	return DefaultValue;
}

stock Float:TG_GetMenuFloat( Handle:hndl, const String:id[], Float:DefaultValue = 0.0 )
{
	new ItemCount = GetMenuItemCount( hndl );
	decl String:info[ 64 ], String:data[ 64 ];
	
	for( new i = 0; i < ItemCount; i++ )
	{
		GetMenuItem( hndl, i, info, sizeof( info ), _, data, sizeof( data ) );
		
		if( StrEqual( info, id ) )
			return StringToFloat( data );
	}	
	return DefaultValue;
}

stock TG_CopyMenuAny( Handle:source, Handle:dest, const String:id[] )
{
	new ItemCount = GetMenuItemCount( source );
	decl String:info[ 64 ], String:data[ 64 ];
	
	for( new i = 0; i < ItemCount; i++ )
	{
		GetMenuItem( source, i, info, sizeof( info ), _, data, sizeof( data ) );
		
		if( StrEqual( info, id ) )
			AddMenuItem( dest, id, data, ITEMDRAW_NOTEXT );
	}
}

stock bool:TG_SwitchRandomRedToBlueMulti( count )
{
	for( new i = 1; i <= count; i++ )
	{
		if( TG_SwitchRandomRedToBlue() <= 0 )
			return false;
	}
	
	return true;
}

stock bool:TG_KillHandle( Handle:hndl )
{
	if( hndl != INVALID_HANDLE )
	{
		CloseHandle( hndl );
		hndl = INVALID_HANDLE;
		return true;
	}
	return false;
}

stock bool:TG_KillTimer( Handle:hndl )
{
	if( hndl != INVALID_HANDLE )
	{
		KillTimer( hndl );
		hndl = INVALID_HANDLE;
		return true;
	}
	return false;
}

stock bool:TG_ClientHasAdminFlag( any:client, const String:FlagName[] )
{
	if( strlen( FlagName ) == 0 )
		return false;
	
	if( GetUserAdmin( client ) != INVALID_ADMIN_ID )
	{
		new AdminFlag:flag;
		
		if( !FindFlagByName( FlagName, flag ) )
		{
			if( !FindFlagByChar( FlagName[ 0 ], flag ) )
				return false;
		}
		
		if( GetAdminFlag( GetUserAdmin( client ), flag ) )
			return true;
	}
	return false;
}

stock bool:TG_IsStringColor( const String:buffer[] )
{
	decl String:color[ 32 ];
	strcopy( color, sizeof( color ), buffer );
	
	if( color[ 0 ] == '' || color[ 0 ] == '' || color[ 0 ] == '' || color[ 0 ] == '' )
	{
		if( strlen( color ) == 1 )
			return true;
	}
	
	if( color[ 0 ] == '{' && color[ strlen( color ) - 1 ] == '}' )
	{
		strcopy( color, strlen( color ) - 2, color[ 1 ] );
				
		decl value;
		CCheckTrie();
		
		if( GetTrieValue( CTrie, color, value ) )
			return true;
		else
			return false;
	}
	
	if( color[ 0 ] != '' || strlen( color ) != 7 )
		return false;
	
	for( new i = 1; i < strlen( color ); i++ )
	{
		if( IsCharNumeric( color[ i ] ) )
			continue;
			
		if( StrContains( "abcdef", color[ i ], false ) )
			continue;
		
		return false;
	}	
	return true;
}

new String:__TG_COLORS__[ 7 ][ 2 ][] = 
{
	{ "{redteam}", 	  "TGColor-redteam"    },
	{ "{blueteam}",   "TGColor-blueteam"   },
	{ "{prefix}", 	  "TGColor-prefix"     },
	{ "{default}", 	  "TGColor-default"    },
	{ "{settings}",   "TGColor-settings"   },
	{ "{highlight}",  "TGColor-highlight"  },
	{ "{highlight2}", "TGColor-highlight2" }
};

stock TG_ProcessPhrasesColors( String:msg[], size )
{
	decl String:colorcode[ 64 ];
	
	for( new i = 0; i < 7; i++ )
	{
		if( FindCharInString( msg, '{' ) == -1 || FindCharInString( msg, '}' ) == -1 )
			break;
		
		Format( colorcode, sizeof( colorcode ), "%t", __TG_COLORS__[ i ][ 1 ] );
		ReplaceString( msg, size, __TG_COLORS__[ i ][ 0 ], colorcode, true );
	}
	
	CReplaceColorCodes( msg, _, _, size );
}

// stock TG_ProcessPhrasesColors( String:msg[], size )
// {
	// TG_inner_colors_replace( msg, size, "{redteam}", 	"TGColor-redteam" );
	// TG_inner_colors_replace( msg, size, "{blueteam}", 	"TGColor-blueteam" );
	// TG_inner_colors_replace( msg, size, "{prefix}", 	"TGColor-prefix" );
	// TG_inner_colors_replace( msg, size, "{default}", 	"TGColor-default" );
	// TG_inner_colors_replace( msg, size, "{settings}", 	"TGColor-settings" );
	// TG_inner_colors_replace( msg, size, "{highlight}", 	"TGColor-highlight" );
	// TG_inner_colors_replace( msg, size, "{highlight2}", "TGColor-highlight2" );
	
	// CReplaceColorCodes( msg, _, _, size );
// }

// stock TG_inner_colors_replace( String:msg[], size, String:colorname[], String:colortr[] )
// {
	// if( FindCharInString( msg, '{' ) == -1 || FindCharInString( msg, '}' ) == -1 )
		// return;
	
	// decl String:colorcode[ 64 ];
	
	// Format( colorcode, sizeof( colorcode ), "%t", colortr );
	// ReplaceString( msg, size, colorname, colorcode, true );
// }

/**
 * Prints a message to all clients in the chat area. Use tg prefix and process tg color codes (and motecolors.inc codes).
 *
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock TG_PrintToChatAll( const String:format[], any:... )
{
	decl String:msg[ 512 ];
	VFormat( msg, sizeof( msg ), format, 2 );
	
	if( FindCharInString( msg, '{' ) != -1 )
		TG_ProcessPhrasesColors( msg, sizeof( msg ) );

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !Client_IsIngame( i ) )
			continue;

		TG_PrintToChat( i, msg );
	}
}

stock TG_PrintToChatAllEx( const String:format[], any:... )
{
	decl String:msg[ 512 ];
	VFormat( msg, sizeof( msg ), format, 2 );
	
	if( FindCharInString( msg, '{' ) != -1 )
		TG_ProcessPhrasesColors( msg, sizeof( msg ) );

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !Client_IsIngame( i ) )
			continue;

		TG_PrintToChatEx( i, msg );
	}
}

stock bool:StrStartWith( const String:source[], const String:prefix[], bool:CaseSensitive = false )
{
	for( new i = 0; i < strlen( prefix ); i++ )
	{
		if( source[ i ] != prefix[ i ] && CaseSensitive )
			return false;
		
		if( CharToLower( source[ i ] ) != CharToLower( prefix[ i ] ) )
			return false;
	}
	
	return true;
}

stock bool:TG_GetPrefixArg( String:ArgBuffer[], size, const String:prefix[], Arg, const String:DefaultValue[] )
{
	decl String:ArgsString[ 128 ];
	strcopy( ArgsString, sizeof( ArgsString ), prefix[ FindCharInString( prefix, ' ' ) ] );
	TrimString( ArgsString );
	ArgBuffer[ 0 ] = EOS;
	ArgBuffer[ 1 ] = EOS;
	Arg -= 1;
	
	new ArgNumber = 0;
	new bool:IsQuoted = false;
	
	for( new i = 0; i < strlen( ArgsString ) - 1; i++ )
	{
		if( ArgsString[ i ] == '\\' )
			i++;
		
		if( ArgsString[ i ] == ' ' && !IsQuoted )
		{
			ArgNumber++;
			IsQuoted = false;
		}
		else if( ArgsString[ i ] == '"' && ArgsString[ i - 1 ] != '\\' )
		{
			if( IsQuoted )
				IsQuoted = false;
			else
				IsQuoted = true;
		}
		else if( Arg == ArgNumber )
		{
			ArgBuffer[ strlen( ArgBuffer ) ] = ArgsString[ i ];
			ArgBuffer[ strlen( ArgBuffer ) + 1 ] = EOS;
		}
	}
	
	if( ArgBuffer[ 0 ] == EOS )
	{
		strcopy( ArgBuffer, size, DefaultValue );
		return false;
	}
	
	return true;
}

stock bool:TG_KvAddInt( TG_ModuleType:type = MenuItem, const String:id[], const String:key[], value )
{
	decl String:buffer[ 512 ];
	IntToString( value, buffer, sizeof( buffer ) );
	
	return bool:TG_KvAddString( type, id, key, buffer );
}

stock bool:TG_KvAddFloat( TG_ModuleType:type = MenuItem, const String:id[], const String:key[], Float:value )
{
	decl String:buffer[ 512 ];
	FloatToString( value, buffer, sizeof( buffer ) );
	
	return bool:TG_KvAddString( type, id, key, buffer );
}

stock bool:TG_KvSetInt( TG_ModuleType:type = MenuItem, const String:id[], const String:key[], value )
{
	decl String:buffer[ 512 ];
	IntToString( value, buffer, sizeof( buffer ) );
	
	return bool:TG_KvSetString( type, id, key, buffer );
}

stock bool:TG_KvSetFloat( TG_ModuleType:type = MenuItem, const String:id[], const String:key[], Float:value )
{
	decl String:buffer[ 512 ];
	FloatToString( value, buffer, sizeof( buffer ) );
	
	return bool:TG_KvSetString( type, id, key, buffer );
}

stock TG_KvGetInt( TG_ModuleType:type = MenuItem, const String:id[], const String:key[], defultValue = 0 )
{
	decl String:buffer[ 512 ];
	
	if( !TG_KvGetString( type, id, key, buffer, sizeof( buffer ), "" ) )
		return defultValue;
	else
		return StringToInt( buffer );
}

stock Float:TG_KvGetFloat( TG_ModuleType:type = MenuItem, const String:id[], const String:key[], Float:defultValue = 0.0 )
{
	decl String:buffer[ 512 ];
	
	if( !TG_KvGetString( type, id, key, buffer, sizeof( buffer ), "" ) )
		return defultValue;
	else
		return StringToFloat( buffer );
}

stock TG_GetRandomClient( TG_Team:team )
{
	decl clients[ MAXPLAYERS + 1 ];
	new count = 0;

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( Client_IsIngame( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == CS_TEAM_T && TG_GetPlayerTeam( i ) == team )
		{
			clients[ count ] = i;
			count++;			
		}
	}

	if( count == 0 )
		return 0;

	return clients[ GetRandomInt( 0, count - 1 ) ];
}
