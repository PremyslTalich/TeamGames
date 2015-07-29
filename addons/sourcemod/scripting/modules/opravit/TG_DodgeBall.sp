#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define GAME_ID			"DodgeBall-Raska"
#define GAME_GRAVITY	0.6

public Plugin:myinfo =
{
	name = "TG_DodgeBall",
	author = "Raska",
	description = "",
	version = "0.4",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations( "TG.DodgeBall-Raska.phrases" );
	
	if( LibraryExists( "TeamGames" ) && !TG_IsModuleReged( TG_Game, GAME_ID ) )
		TG_RegGame( GAME_ID, TG_FiftyFifty, "%t", "GameName" );
}

public OnLibraryAdded( const String:name[] )
{
	if( StrEqual( name, "TeamGames" ) )
		TG_RegGame( GAME_ID, TG_FiftyFifty, "%t", "GameName" );
}

public OnPluginEnd()
{
	TG_RemoveGame( GAME_ID );
}

public TG_OnMenuGameDisplay( const String:id[], iClient, String:name[] )
{
	if( StrEqual( id, GAME_ID ) )
		Format( name, TG_MODULE_NAME_LENGTH, "%T", "GameName", iClient );
}

public TG_OnGameSelected( const String:id[], iClient )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	TG_StartGame( iClient, GAME_ID );
}


public TG_OnGameStart( const String:id[], iClient, const String:GameSettings[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		SetEntityHealth( i, 1 );
		SetEntityGravity( i, GAME_GRAVITY );
		Client_GiveWeapon( i, "weapon_flashbang", true );
	}
}

public Action:Event_FlashBangDetonate( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;

	new iClient = GetClientOfUserId( GetEventInt( event, "userid" ) );

	if( TG_IsPlayerRedOrBlue( iClient ) )
		Client_GiveWeapon( iClient, "weapon_flashbang", true );

	return Plugin_Continue;
}

public TG_OnTeamEmpty( const String:id[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	TG_StopGame( TG_GetOppositeTeam( team ) );
}

public TG_OnGameEnd( const String:id[], TG_Team:iTeam, winners[], winnersCount, Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		SetEntityGravity( i, 1.0 )
	}
	
	return;
}

public OnEntityCreated( entity, const String:classname[] )
{
    if( StrEqual( classname, "flashbang_projectile" ) )
        CreateTimer( 1.5, Timer_RemoveFlashbang, entity );
}

public Action:Timer_RemoveFlashbang( Handle:hTimer, any:entity )
{
	if( !TG_IsCurrentGameID( GAME_ID ) || !IsValidEntity( entity ) )
		return Plugin_Continue;

	new owner = GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" );

	if( TG_IsPlayerRedOrBlue( owner ) )
	{
		AcceptEntityInput( entity, "Kill" );

		Client_GiveWeapon( owner, "weapon_flashbang", true );
	}
	
	return Plugin_Continue;
}