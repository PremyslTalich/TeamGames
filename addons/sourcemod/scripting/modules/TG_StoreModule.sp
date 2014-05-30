#include <sourcemod>
#include <teamgames>
#include <store>

public Plugin:myinfo =
{
	name = "TG_StoreModule",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public TG_OnGamePrepare( const String:id[], client, const String:CustomName[], Handle:DataPack )
{
	new credits = TG_KvGetInt( Game, id, "StoreModule-base", 10 );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == RedTeam || TG_GetPlayerTeam( i ) == BlueTeam )
			Store_GiveCredits( GetSteamAccountID( i ), credits );
	}
}

public TG_OnGameEnd( const String:id[], TG_Team:team, winners[], winnersCount )
{
	new credits = TG_KvGetInt( Game, id, "StoreModule-win", 40 );
	
	for( new i = 0; i < winnersCount; i++ )
	{
		Store_GiveCredits( GetSteamAccountID( winners[ i ] ), credits );
	}
}
