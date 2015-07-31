enum MarkStruct
{
	e_Sprite,
	Float:e_High,
    Float:e_Scale,
	String:e_LaserSprite,
	Float:e_LaserWidth,
	e_LaserColor[4]
}
new g_Mark[3][MarkStruct];

public Action:Event_BulletImpact(Handle:hEvent,const String:sName[],bool:bDontBroadcast)
{
	if (g_bAllowMark == false || g_iMarkLimitCounter >= g_iMarkLimit)
		return Plugin_Continue;

	if (g_Mark[TG_RedTeam][e_Sprite] == 0 && g_Mark[TG_BlueTeam][e_Sprite] == 0)
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (Client_IsIngame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == CS_TEAM_CT && g_PlayerData[iClient][AbleToMark]) {
		new Float:fX = GetEventFloat(hEvent, "x");
		new Float:fY = GetEventFloat(hEvent, "y");
		new Float:fZ = GetEventFloat(hEvent, "z");

		if ((GetClientButtons(iClient) & IN_USE) && g_Mark[TG_RedTeam][e_Sprite] != 0) {
			SpawnMark(iClient, TG_RedTeam, fX, fY, fZ);
		} else if ((GetClientButtons(iClient) & IN_SPEED) && g_Mark[TG_BlueTeam][e_Sprite] != 0) {
			SpawnMark(iClient, TG_BlueTeam, fX, fY, fZ);
		}
	}

	return Plugin_Continue;
}

public Action:Timer_MarkLimit(Handle:hTimer)
{
	if (g_iMarkLimitCounter > 0)
		g_iMarkLimitCounter--;

	return Plugin_Continue;
}

public Action:Timer_AbleToMark(Handle:hTimer, any:iClient)
{
	g_PlayerData[iClient][AbleToMark] = true;
	return Plugin_Continue;
}

bool:SpawnMark(iClient, TG_Team:iTeam, Float:fX, Float:fY, Float:fZ, Float:fTime = 0.0, bool:bCount = true, bool:bFireEvent = true)
{
	new Float:fPos[3];
	fPos[0] = fX;
	fPos[1] = fY;
	fPos[2] = fZ;

	new Float:fLife;
	if (fTime > 0.0)
		fLife = fTime;
	else
		fLife = g_fMarkLife;

	if (bFireEvent) {
		new Action:result = Plugin_Continue;
		Call_StartForward(Forward_OnMarkSpawn);
		Call_PushCell(iClient);
		Call_PushCell(iTeam);
		Call_PushArray(fPos, 3);
		Call_PushFloat(fLife);
		Call_Finish(result);
		if (result != Plugin_Continue)
			return false;
	}

	Call_StartForward(Forward_OnMarkSpawned);
	Call_PushCell(iClient);
	Call_PushCell(iTeam);
	Call_PushArray(fPos, 3);
	Call_PushFloat(fLife);
	Call_Finish();

	fPos[2] += g_Mark[iTeam][e_High];

	TE_SetupGlowSprite(fPos, g_Mark[iTeam][e_Sprite], fLife, g_Mark[iTeam][e_Scale], 255);
	TE_SendToAll();

	if (bCount) {
		g_PlayerData[iClient][AbleToMark] = false;
		CreateTimer(0.01, Timer_AbleToMark, iClient);

		g_iMarkLimitCounter++;
		CreateTimer(g_fMarkLife, Timer_MarkLimit);
	}

	if (g_fMarkLaser > 0.0 && Client_IsIngame(iClient) && g_Mark[iTeam][e_LaserSprite] != 0) {
		new Float:fClientPos[3];

		GetClientEyePosition(iClient, fClientPos);
		fClientPos[2] -= 16;

		new iLaserColor[4];
		iLaserColor[0] = g_Mark[iTeam][e_LaserColor][0];
		iLaserColor[1] = g_Mark[iTeam][e_LaserColor][1];
		iLaserColor[2] = g_Mark[iTeam][e_LaserColor][2];
		iLaserColor[3] = g_Mark[iTeam][e_LaserColor][3];

		TE_SetupBeamPoints(fClientPos, fPos, g_Mark[iTeam][e_LaserSprite], g_Mark[iTeam][e_LaserSprite], 0, 0, g_fMarkLaser, g_Mark[iTeam][e_LaserWidth], g_Mark[iTeam][e_LaserWidth], 1024, 0.0, iLaserColor, 0);
		TE_SendToAll();
	}

	return true;
}
