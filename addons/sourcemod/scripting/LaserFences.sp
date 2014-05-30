// ConVars
new Handle:gh_FenceHeight = INVALID_HANDLE, Float:g_FenceHeight = 71.0;
new Handle:gh_FenceNotify = INVALID_HANDLE, g_FenceNotify = 2;
new Handle:gh_FencePunishLength = INVALID_HANDLE, Float:g_FencePunishLength = 1.0;
new Handle:gh_FenceColor = INVALID_HANDLE, g_FenceColor = 1;
new Handle:gh_FenceFreeze = INVALID_HANDLE, g_FenceFreeze = 1;

#define FENCE_MATERIAL "materials/sprites/laserbeam.vmt"
#define FENCE_HALO "materials/sprites/glow01.vmt"
#define LASER_COLOR { 255, 0, 0, 255 }

new g_FenceMaterial = -1;
new g_FenceHalo = -1;

new Float:g_FenceRectangleA[ 3 ], Float:g_FenceRectangleB[ 3 ], Float:g_FenceRectangleC[ 3 ], Float:g_FenceRectangleD[ 3 ];
new bool:g_FenceRectangle = false;

FencesMenu( client )
{
	new Handle:menu = CreateMenu( FencesMenu_Handler );
	decl String:TransMsg[ 256 ];
	
	Format( TransMsg, sizeof( TransMsg ), "%T", "Menu fences title", client );
	SetMenuTitle( menu, TransMsg );
	
	if( !g_FenceRectangle )
	{
		Format( TransMsg, sizeof( TransMsg ), "%T", "Menu fences rectangle", client );
		AddMenuItem( menu, "FENCE_RECTANGLE", TransMsg );
	}
	else
	{
		Format( TransMsg, sizeof( TransMsg ), "%T", "Menu fences rectangle off", client );
		AddMenuItem( menu, "FENCE_RECTANGLE_OFF", TransMsg );
	}
	
	SetMenuExitBackButton( menu, true );
	DisplayMenu( menu, client, 30 );
}

public FencesMenu_Handler( Handle:menu, MenuAction:action, client, param2 )
{
	if( action == MenuAction_Select )
	{
		decl String:info[ 32 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		if( StrEqual( info, "FENCE_RECTANGLE" ) )
		{
			new Float:pos[ 3 ];
			GetClientAbsOrigin( client, pos );
			
			new Handle:datapack = CreateDataPack();
			WritePackCell( datapack, client );
			WritePackFloat( datapack, pos[ 0 ] );
			WritePackFloat( datapack, pos[ 1 ] );
			WritePackFloat( datapack, pos[ 2 ] );
			
			new Handle:timer = CreateTimer( 0.1, Timer_FenceRectanglePre, datapack, TIMER_REPEAT );
			
			new Handle:submenu = CreateMenu( FencesMenu_Rectangle_Handler );
			decl String:TransMsg[ 256 ];			
			Format( TransMsg, sizeof( TransMsg ), "%T", "Menu fences confirm", client );
			SetMenuTitle( submenu, TransMsg );
			AddMenuItem( submenu, "FENCES_MENU_CONFIRM", TransMsg );
			TG_PushMenuCell( submenu, "-DATAPACK-", _:datapack );
			TG_PushMenuCell( submenu, "-TIMER-", _:timer );
			SetMenuExitBackButton( submenu, true );
			DisplayMenu( submenu, client, MENU_TIME_FOREVER );
		}
		else if( StrEqual( info, "FENCE_RECTANGLE_OFF" ) )
		{
			DestroyFence();
			FencesMenu( client );
		}
	}
	else if( action == MenuAction_Cancel && param2 == MenuCancel_ExitBack )
	{
		MainMenu( client );
	}
}

public Action:Timer_FenceRectanglePre( Handle:timer, Handle:DataPack ) // Rectangle pre draw
{
	decl Float:a[ 3 ], Float:b[ 3 ], Float:c[ 3 ], Float:d[ 3 ];
	new client;
	
	ResetPack( DataPack );
	client = ReadPackCell( DataPack );
	a[ 0 ] = ReadPackFloat( DataPack );
	a[ 1 ] = ReadPackFloat( DataPack );
	a[ 2 ] = ReadPackFloat( DataPack ) + 12.0;
	
	GetClientAbsOrigin( client, c );
	
	b[ 2 ] = a[ 2 ];
	d[ 2 ] = a[ 2 ];
	c[ 2 ] = a[ 2 ];
	
	b[ 0 ] = c[ 0 ];
	b[ 1 ] = a[ 1 ];
	
	d[ 0 ] = a[ 0 ];
	d[ 1 ] = c[ 1 ];
	
	TE_SetupBeamPoints( a, b, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( b, c, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( c, d, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( d, a, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	a[ 2 ] += 18.0;
	
	if( g_FenceHeight < a[ 2 ] )
		return Plugin_Continue;
	
	b[ 2 ] += 18.0;
	d[ 2 ] += 18.0;
	c[ 2 ] += 18.0;
	TE_SetupBeamPoints( a, b, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( b, c, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( c, d, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( d, a, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	a[ 2 ] += 18.0;
	
	if( g_FenceHeight < a[ 2 ] )
		return Plugin_Continue;
	
	b[ 2 ] += 18.0;
	d[ 2 ] += 18.0;
	c[ 2 ] += 18.0;
	TE_SetupBeamPoints( a, b, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( b, c, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( c, d, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( d, a, g_FenceMaterial, g_FenceHalo, 2, 1, 0.11, 1.0, 1.0, 0, 0.0, { 0, 255, 0, 255 }, 1 );
	TE_SendToAll();
	
	return Plugin_Continue;
}

public Action:Timer_FenceRectangle( Handle:timer )
{
	if( !g_FenceRectangle )
		KillTimer( timer );
	
	decl Float:a[ 3 ];
	decl Float:b[ 3 ];
	decl Float:c[ 3 ];
	decl Float:d[ 3 ];
	
	a = g_FenceRectangleA;
	b = g_FenceRectangleB;
	c = g_FenceRectangleC;
	d = g_FenceRectangleD;
	
	TE_SetupBeamPoints( a, b, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();                                               
	TE_SetupBeamPoints( b, c, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();                                               
	TE_SetupBeamPoints( c, d, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();                                               
	TE_SetupBeamPoints( d, a, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();	
	a[ 2 ] += 18.0;
	
	if( g_FenceHeight < a[ 2 ] )
		return Plugin_Continue;
	
	b[ 2 ] += 18.0;
	d[ 2 ] += 18.0;
	c[ 2 ] += 18.0;
	TE_SetupBeamPoints( a, b, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();                                               
	TE_SetupBeamPoints( b, c, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();                                               
	TE_SetupBeamPoints( c, d, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();                                               
	TE_SetupBeamPoints( d, a, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();	
	a[ 2 ] += 18.0;
	
	if( g_FenceHeight < a[ 2 ] )
		return Plugin_Continue;
	
	b[ 2 ] += 18.0;
	d[ 2 ] += 18.0;
	c[ 2 ] += 18.0;
	TE_SetupBeamPoints( a, b, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( b, c, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( c, d, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();
	TE_SetupBeamPoints( d, a, g_FenceMaterial, g_FenceHalo, 2, 1, 1.1, 1.0, 1.0, 0, 0.0, LASER_COLOR, 1 );
	TE_SendToAll();
	
	return Plugin_Continue;
}

public FencesMenu_Rectangle_Handler( Handle:menu, MenuAction:action, client, param2 ) // Rectangle menu handler
{
	if( action == MenuAction_Select )
	{
		decl String:info[ 32 ];
		GetMenuItem( menu, param2, info, sizeof( info ) );
		
		if( StrEqual( info, "FENCES_MENU_CONFIRM" ) )
		{
			new Float:a[ 3 ], Float:c[ 3 ], Handle:DataPack = INVALID_HANDLE;
			DataPack = Handle:TG_GetMenuCell( menu, "-DATAPACK-" );
			ResetPack( DataPack );
			client = ReadPackCell( DataPack );
			a[ 0 ] = ReadPackFloat( DataPack );
			a[ 1 ] = ReadPackFloat( DataPack );
			a[ 2 ] = ReadPackFloat( DataPack );
			
			GetClientAbsOrigin( client, c );
			
			CreateFence( a, c );
			
			MainMenu( client );
		}
		
		CloseHandle( Handle:TG_GetMenuCell( menu, "-DATAPACK-" ) );
		CloseHandle( Handle:TG_GetMenuCell( menu, "-TIMER-" ) );
	}
	else if( action == MenuAction_Cancel )
	{
		if( param2 == MenuCancel_Disconnected || param2 == MenuCancel_Interrupted || param2 == MenuCancel_Exit || param2 == MenuCancel_ExitBack )
		{
			CloseHandle( Handle:TG_GetMenuCell( menu, "-DATAPACK-" ) );
			CloseHandle( Handle:TG_GetMenuCell( menu, "-TIMER-" ) );
			FencesMenu( client );
		}
	}
}

CreateFence( Float:a[ 3 ], Float:c[ 3 ] )
{
	DestroyFence();
	
	new Action:result = Plugin_Continue;
	Call_StartForward( Forward_OnLaserFenceCreatePre );
	Call_PushArray( a, 3 );
	Call_PushArray( c, 3 );
	Call_Finish( result );
	if( result != Plugin_Continue )
		return;
	
	CreateFencePoints( a, c );
	CreateBrushTrigger( g_FenceRectangleA, g_FenceRectangleC );
	g_FenceRectangle = true;
	CreateTimer( 1.0, Timer_FenceRectangle, _, TIMER_REPEAT );
}

DestroyFence()
{
	if( g_FenceRectangle )
	{
		Call_StartForward( Forward_OnLaserFenceDestroyed );
		Call_PushArray( g_FenceRectangleA, 3 );
		Call_PushArray( g_FenceRectangleC, 3 );
		Call_Finish();
	}
	
	g_FenceRectangle = false;
	DestroyBrushTrigger();
}

CreateFencePoints( Float:a[ 3 ], Float:c[ 3 ] )
{
	g_FenceRectangleA = a;
	g_FenceRectangleC = c;
	
	if( c[ 0 ] <= a[ 0 ] && c[ 1 ] <= a[ 1 ] )// 3
	{
		g_FenceRectangleA = c;
		g_FenceRectangleC = a;
	}
	else if( a[ 0 ] >= c[ 0 ] && a[ 1 ] <= c[ 1 ] ) // 2
	{
		g_FenceRectangleA[ 0 ] = c[ 0 ];
		g_FenceRectangleC[ 0 ] = a[ 0 ];
	}
	else if( a[ 0 ] <= c[ 0 ] && a[ 1 ] >= c[ 1 ] ) // 4
	{
		g_FenceRectangleA[ 1 ] = c[ 1 ];
		g_FenceRectangleC[ 1 ] = a[ 1 ];
	}
	
	g_FenceRectangleB[ 0 ] = g_FenceRectangleC[ 0 ];
	g_FenceRectangleB[ 1 ] = g_FenceRectangleA[ 1 ];
	g_FenceRectangleD[ 0 ] = g_FenceRectangleA[ 0 ];
	g_FenceRectangleD[ 1 ] = g_FenceRectangleC[ 1 ];
	
	g_FenceRectangleA[ 2 ] += 12.0;
	g_FenceRectangleB[ 2 ] = g_FenceRectangleA[ 2 ];
	g_FenceRectangleD[ 2 ] = g_FenceRectangleA[ 2 ];
	g_FenceRectangleC[ 2 ] = g_FenceRectangleA[ 2 ];
}

CreateBrushTrigger( Float:a[ 3 ], Float:c[ 3 ] )
{
	new Float:start[ 3 ], Float:end[ 3 ];
	start = a;
	end = c;
	start[ 2 ] -= 12.0;
	end[ 2 ] = start[ 2 ];
	
	start[ 0 ] += 15.0;
	start[ 1 ] += 15.0;
	
	end[ 0 ] -= 15.0;
	end[ 1 ] -= 15.0;
	
	new Float:vec[ 3 ];
	MakeVectorFromPoints( start, end, vec );
	
	new Float:origin[ 3 ];
	origin[ 0 ] = ( start[ 0 ] + end[ 0 ] ) / 2;
	origin[ 1 ] = ( start[ 1 ] + end[ 1 ] ) / 2;
	origin[ 2 ] = start[ 2 ];
	
	new Float:minbounds[ 3 ], Float:maxbounds[ 3 ];
	minbounds[ 0 ] = -1 * ( vec[ 0 ] / 2 );
	maxbounds[ 0 ] = vec[ 0 ] / 2;
	minbounds[ 1 ] = -1 * ( vec[ 1 ] / 2 );
	maxbounds[ 1 ] = vec[ 1 ] / 2;
	minbounds[ 2 ] = 0.0;
	maxbounds[ 2 ] = 128.0;
	
	new entindex = CreateEntityByName("trigger_multiple");
	
	DispatchKeyValue( entindex, "spawnflags", "64" );
	DispatchKeyValue( entindex, "targetname", "TG_RectangleLaserFense" );
	DispatchKeyValue( entindex, "wait", "0" );
	
	DispatchSpawn( entindex );
	ActivateEntity( entindex );
	SetEntProp( entindex, Prop_Data, "m_spawnflags", 64 );
	
	TeleportEntity( entindex, origin, NULL_VECTOR, NULL_VECTOR );
	
	SetEntityModel( entindex, "models/props/cs_office/vending_machine.mdl" );
	
	SetEntPropVector( entindex, Prop_Send, "m_vecMins", minbounds );
	SetEntPropVector( entindex, Prop_Send, "m_vecMaxs", maxbounds );
	
	SetEntProp( entindex, Prop_Send, "m_nSolidType", 2 );
	
	new enteffects = GetEntProp( entindex, Prop_Send, "m_fEffects" );
	enteffects |= 32;
	SetEntProp( entindex, Prop_Send, "m_fEffects", enteffects );
	
	HookSingleEntityOutput( entindex, "OnEndTouch", Hook_LaserFenceOnEndTouch );
}

public Hook_LaserFenceOnEndTouch( const String:output[], caller, activator, Float:delay )
{
	if( !Client_IsIngame( activator ) || GetClientTeam( activator ) == CS_TEAM_CT || !TG_IsTeamRedOrBlue( g_PlayerData[ activator ][ Team ] ) )
		return;
	
	decl String:TriggerName[ 256 ];
	GetEntPropString( caller, Prop_Data, "m_iName", TriggerName, sizeof( TriggerName ) );
	
	if( !StrEqual( TriggerName, "TG_RectangleLaserFense", true ) )
		return;
	
	new Float:pos[ 3 ];
	GetClientAbsOrigin( activator, pos );
	
	if( pos[ 2 ] < g_FenceRectangleA[ 2 ] + ( g_FenceHeight - 12.0 ) )
		FencePunishPlayer( activator );
}

DestroyBrushTrigger()
{
	new EntCount = GetMaxEntities();
	decl String:ClassName[ 256 ], String:TriggerName[ 256 ];
	for( new i = MaxClients; i < EntCount; i++ )
	{
		if( IsValidEntity( i ) && IsValidEdict( i ) )
		{
			GetEdictClassname( i, ClassName, sizeof( ClassName ) );
			
			if( StrEqual( ClassName, "trigger_multiple", true ) )
			{
				GetEntPropString( i, Prop_Data, "m_iName", TriggerName, sizeof( TriggerName ) );
				
				if( StrEqual( TriggerName, "TG_RectangleLaserFense", true ) )
				{
					UnhookSingleEntityOutput( i, "OnEndTouch", Hook_LaserFenceOnEndTouch );
					AcceptEntityInput( i, "Kill" );
				}
			}
		}
	}
}

FencePunishPlayer( client, bool:CallForward = true )
{
	new Float:time = g_FencePunishLength;
	
	if( CallForward )
	{
		new Action:result = Plugin_Continue;
		Call_StartForward( Forward_OnLaserFenceCrossed );
		Call_PushCell( client );
		Call_PushFloatRef( time );
		Call_Finish( result );
		
		if( result == Plugin_Handled || result == Plugin_Stop )
			return;
	}
	
	if( g_FenceNotify == 1 || ( g_FenceNotify == 2 && g_Game[ GameProgress ] != NoGame ) )
	{
		decl String:ClientName[ 64 ];
		GetClientName( client, ClientName, sizeof( ClientName ) );
		TG_PrintToChatAll( "%t" , "Fences player crossed", ClientName );
	}
	
	if( g_FencePunishLength == 0.0 || ( g_FenceColor == 0 && g_FenceFreeze == 0 ) )
		return;
	
	if( g_FenceColor == 1 || ( g_FenceColor == 2 && g_Game[ GameProgress ] != NoGame ) )
	{
		new Handle:DataPack = CreateDataPack();
		WritePackCell( DataPack, client );
		WritePackCell( DataPack, GetEntData( client, GetEntSendPropOffs( client, "m_clrRender", true ), 1 ) );
		WritePackCell( DataPack, GetEntData( client, GetEntSendPropOffs( client, "m_clrRender", true ) + 1, 1 ) );
		WritePackCell( DataPack, GetEntData( client, GetEntSendPropOffs( client, "m_clrRender", true ) + 2, 1 ) );
		WritePackCell( DataPack, GetEntData( client, GetEntSendPropOffs( client, "m_clrRender", true ) + 3, 1 ) );
		SetEntityRenderColor( client, 0, 255, 0, 0 );
		CreateTimer( time, Timer_FenceColorOff, DataPack, 0 );
	}
	
	if( g_FenceFreeze == 1 || ( g_FenceFreeze == 2 && g_Game[ GameProgress ] != NoGame ) )
	{
		SetEntityMoveType( client, MOVETYPE_NONE );
		CreateTimer( time, Timer_FenceFreezeOff, client );
	}
	
	return;
}

public Action:Timer_FenceColorOff( Handle:timer, Handle:DataPack )
{
	ResetPack( DataPack );
	new client = ReadPackCell( DataPack );
	new red = ReadPackCell( DataPack );
	new green = ReadPackCell( DataPack );
	new blue = ReadPackCell( DataPack );
	new alpha = ReadPackCell( DataPack );
	CloseHandle( DataPack );
	
	SetEntityRenderColor( client, red, green, blue, alpha );
	
	return Plugin_Continue;
}
public Action:Timer_FenceFreezeOff( Handle:timer, any:client )
{
	SetEntityMoveType( client, MOVETYPE_ISOMETRIC );
	
	return Plugin_Continue;
}
