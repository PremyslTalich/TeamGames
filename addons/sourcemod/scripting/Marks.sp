new Handle:gh_AllowMark = INVALID_HANDLE, bool:g_AllowMark = true;
new Handle:gh_MarkLife = INVALID_HANDLE, Float:g_MarkLife;
new Handle:gh_MarkLimit = INVALID_HANDLE, g_MarkLimit, g_MarkLimit_counter;

enum MarkStruct
{
	Sprite,
	Float:High,
    Float:Scale
}
new g_Mark[ 3 ][ MarkStruct ];

public Action:Event_BulletImpact( Handle:event,const String:name[],bool:dontBroadcast )
{
	if( g_AllowMark == false || g_MarkLimit_counter >= g_MarkLimit )
		return Plugin_Continue;
	
	if( g_Mark[ RedTeam ][ Sprite ] == 0 && g_Mark[ BlueTeam ][ Sprite ] == 0 )
		return Plugin_Continue;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( Client_IsIngame( client ) && IsPlayerAlive( client ) && GetClientTeam( client ) == CS_TEAM_CT && g_PlayerData[ client ][ AbleToMark ] )
	{
		if( ( GetClientButtons( client ) & IN_USE ) && g_Mark[ RedTeam ][ Sprite ] != 0 )
		{
			SpawnMark( client, RedTeam, GetEventFloat( event, "x" ), GetEventFloat( event, "y" ), GetEventFloat( event, "z" ) );
		}
		else if( ( GetClientButtons( client ) & IN_SPEED ) && g_Mark[ BlueTeam ][ Sprite ] != 0 )
		{
			SpawnMark( client, BlueTeam, GetEventFloat( event, "x" ), GetEventFloat( event, "y" ), GetEventFloat( event, "z" ) );
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_MarkLimit( Handle:timer )
{
	if( g_MarkLimit_counter > 0 )
		g_MarkLimit_counter--;
	
	return Plugin_Continue;
}

public Action:Timer_AbleToMark( Handle:timer, any:client )
{
	g_PlayerData[ client ][ AbleToMark ] = true;
	return Plugin_Continue;
}

bool:SpawnMark( client, TG_Team:team, Float:x, Float:y, Float:z, Float:time = 0.0, bool:count = true, bool:fireEvent = true )
{
	new Float:pos[ 3 ];
	pos[ 0 ] = x;
	pos[ 1 ] = y;
	pos[ 2 ] = z;
	
	new Float:life;
	if( time > 0.0 )
		life = time;
	else
		life = g_MarkLife;
	
	if( fireEvent )
	{
		new Action:result = Plugin_Continue;
		Call_StartForward( Forward_OnMarkSpawn );
		Call_PushCell( client );
		Call_PushCell( team );
		Call_PushArray( pos, 3 );
		Call_PushFloat( life );
		Call_Finish( result );
		if( result != Plugin_Continue )
			return false;		
	}
	
	pos[ 2 ] += g_Mark[ team ][ High ];
	
	TE_SetupGlowSprite( pos, g_Mark[ team ][ Sprite ], life, g_Mark[ team ][ Scale ], 255 );
	TE_SendToAll();
	
	if( count )
	{
		g_PlayerData[ client ][ AbleToMark ] = false;
		CreateTimer( 0.01, Timer_AbleToMark, client );
		
		g_MarkLimit_counter++;
		CreateTimer( g_MarkLife, Timer_MarkLimit );
	}
	
	return true;
}
