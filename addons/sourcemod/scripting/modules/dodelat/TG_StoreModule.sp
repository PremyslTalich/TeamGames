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

public TG_OnGamePrepare( const String:id[], iClient, const String:GameSettings[], Handle:DataPack )
{
	new credits = TG_KvGetInt( TG_Game, id, "StoreModule-base", 10 );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( TG_GetPlayerTeam( i ) == TG_RedTeam || TG_GetPlayerTeam( i ) == TG_BlueTeam )
			Store_GiveCredits( GetSteamAccountID( i ), credits );
	}
}

public TG_OnGameEnd( const String:id[], TG_Team:iTeam, winners[], winnersCount )
{
	new credits = TG_KvGetInt( TG_Game, id, "StoreModule-win", 40 );
	
	for( new i = 0; i < winnersCount; i++ )
	{
		Store_GiveCredits( GetSteamAccountID( winners[ i ] ), credits );
	}
}
