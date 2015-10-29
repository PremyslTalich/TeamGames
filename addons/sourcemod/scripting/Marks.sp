enum MarkStruct
{
	Sprite,
	Float:High,
    Float:Scale,
	String:LaserSprite,
	Float:LaserWidth,
	LaserColor[4]
}
new g_Mark[3][MarkStruct];

public Action:Event_BulletImpact(Handle:hEvent,const String:sName[],bool:bDontBroadcast)
{
	if (!GetConVarBool(g_hAllowMark) || g_iMarkLimitCounter >= GetConVarInt(g_hMarkLimit))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (Client_IsIngame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == CS_TEAM_CT && g_PlayerData[iClient][AbleToMark]) {
		new Float:fX = GetEventFloat(hEvent, "x");
		new Float:fY = GetEventFloat(hEvent, "y");
		new Float:fZ = GetEventFloat(hEvent, "z");

		if (GetClientButtons(iClient) & IN_USE) {
			SpawnMark(iClient, TG_RedTeam, fX, fY, fZ);
		} else if (GetClientButtons(iClient) & IN_SPEED) {
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
		fLife = GetConVarFloat(g_hMarkLife);

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

	if (GetConVarBool(g_hMarkBlockDMG)) {
		g_PlayerData[iClient][MarkBlockDMG] = true;

		new iWeapon = Client_GetActiveWeapon(iClient);
		if (iWeapon != INVALID_ENT_REFERENCE) {
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", GetEntProp(iWeapon, Prop_Send, "m_iClip1") + 1);
		}

		RequestFrame(Frame_MarkBlockDMG, iClient);
	}


	if (g_Mark[iTeam][Sprite] != 0) {
		fPos[2] += g_Mark[iTeam][High];

		TE_SetupGlowSprite(fPos, g_Mark[iTeam][Sprite], fLife, g_Mark[iTeam][Scale], 255);
		TE_SendToAll();
	}

	if (bCount) {
		g_PlayerData[iClient][AbleToMark] = false;
		RequestFrame(Frame_AbleToMark, iClient);

		g_iMarkLimitCounter++;
		CreateTimer(GetConVarFloat(g_hMarkLife), Timer_MarkLimit);
	}

	if (GetConVarFloat(g_hMarkLaser) > 0.0 && Client_IsIngame(iClient) && g_Mark[iTeam][LaserSprite] != 0) {
		new Float:fClientPos[3];

		GetClientEyePosition(iClient, fClientPos);
		fClientPos[2] -= 16;

		new iLaserColor[4];
		iLaserColor[0] = g_Mark[iTeam][LaserColor][0];
		iLaserColor[1] = g_Mark[iTeam][LaserColor][1];
		iLaserColor[2] = g_Mark[iTeam][LaserColor][2];
		iLaserColor[3] = g_Mark[iTeam][LaserColor][3];

		TE_SetupBeamPoints(fClientPos, fPos, g_Mark[iTeam][LaserSprite], g_Mark[iTeam][LaserSprite], 0, 0, GetConVarFloat(g_hMarkLaser), g_Mark[iTeam][LaserWidth], g_Mark[iTeam][LaserWidth], 1024, 0.0, iLaserColor, 0);
		TE_SendToAll();
	}

	return true;
}

public Frame_AbleToMark(any:iClient)
{
	g_PlayerData[iClient][AbleToMark] = true;
}
public Frame_MarkBlockDMG(any:iClient)
{
	g_PlayerData[iClient][MarkBlockDMG] = false;
}