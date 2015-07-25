#include <sourcemod>
#include <smlib>
#include <sdkhooks>
#include <teamgames>
#include <entity_prop_stocks>

#define GAME_ID		"Frosty-Raska"

new bool:g_FrozenPlayers[ MAXPLAYERS + 1 ];
new Handle:g_SlapTimer;

public Plugin:myinfo =
{
	name = "TG_Frosty",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations( "TG.Frosty-Raska.phrases" );
	
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

public Action:TG_OnGameSelected( const String:id[], iClient )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return Plugin_Continue;
	
	TG_StartGame( iClient, GAME_ID );
	
	return Plugin_Continue;
}

public TG_OnGamePrepare( const String:id[], iClient, const String:GameSettings[], Handle:DataPack )
{
	if( !StrEqual( id, GAME_ID, true ) )
		return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		g_FrozenPlayers[ i ] = false;
		
		if( !TG_IsPlayerRedOrBlue( i ) )
			continue;
		
		Client_GiveWeapon( i, "weapon_knife", true );
		// FakeClientCommand( i, "+duck" );
		// SDKHook(i, SDKHook_PreThink, OnPreThink);
	}
	
	g_SlapTimer = CreateTimer( 0.2, Timer_SlapClient, _, TIMER_REPEAT );
}

public Action:TG_OnPlayerDamage( &attacker, victim, &inflictor, &Float:damage, &damagetype, bool:InDifferentTeams )
{
	damage = 0.0;
	
	if( !g_FrozenPlayers[ attacker ] && !g_FrozenPlayers[ victim ] )
	{
		g_FrozenPlayers[ victim ] = true;
		// Client_RemoveAllWeapons( victim );
	}
	
	return Plugin_Changed;
}

public Action:Timer_SlapClient( Handle:hTimer )
{
	if( !TG_IsCurrentGameID( GAME_ID ) )
		return Plugin_Continue;
	
	if( g_SlapTimer == INVALID_HANDLE )
		return Plugin_Stop;
	
	new OldHealth;
	new NewHealth;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !g_FrozenPlayers[ i ] || !Client_IsIngame( i ) )
			continue;
		
		OldHealth = GetClientHealth( i );
		NewHealth = OldHealth - 1;
		
		if( NewHealth <= 0 )
			ForcePlayerSuicide( i );
		else
			SetEntityHealth( i, NewHealth );
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd( iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon )
{
	// if( g_FrozenPlayers[ iClient ] )
	// if( TG_IsCurrentGameID( GAME_ID ) )
	// {
		// if( buttons & IN_FORWARD )
			// SetEntityFlags( iClient, ( buttons |= FL_ATCONTROLS ) );
		
		// if( buttons & IN_BACK )
			// SetEntityFlags( iClient, ( buttons |= FL_ATCONTROLS ) );
		
		// if( buttons & IN_MOVELEFT )
			// SetEntityFlags( iClient, ( buttons |= FL_ATCONTROLS ) );
		
		// if( buttons & IN_MOVERIGHT )
			// SetEntityFlags( iClient, ( buttons |= FL_ATCONTROLS ) );
		
		buttons |= IN_DUCK;
	
	// return Plugin_Changed;
	// }
	
	// return Plugin_Continue;
}

// public OnPreThink(iClient)
// {
    // SetEntProp(iClient, Prop_Send, "m_bDucking", 1);
	// SetEntityFlags(iClient, GetEntityFlags(iClient)|FL_DUCKING); 
// } 

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
	
	g_SlapTimer = INVALID_HANDLE;
	
	return;
}
