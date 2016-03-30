enum MarkStruct
{
	String:Sprite[PLATFORM_MAX_PATH],
	String:Color[16],
	Alpha,
	Float:High,
    Float:Scale,
	LaserSprite,
	Float:LaserWidth,
	LaserColor[4]
}
new g_Mark[3][MarkStruct];
new Handle:g_hMarks;

public Action:Event_BulletImpact(Handle:hEvent,const String:sName[],bool:bDontBroadcast)
{
	if (!GetConVarBool(g_hAllowMark) || (g_iMarkLimitCounter >= GetConVarInt(g_hMarkLimit) && !GetConVarBool(g_hMarkInfinite)))
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

Handle:SpawnMark(iClient, TG_Team:iTeam, Float:fX, Float:fY, Float:fZ, Float:fTime = 0.0, bool:bCount = true, bool:bFireEvent = true, bool:bBlockDMG = true)
{
	if (bCount && g_iMarkLimitCounter >= GetConVarInt(g_hMarkLimit)) {
		if (GetConVarBool(g_hMarkInfinite)) {
			DestroyOldestMark();
		} else {
			return INVALID_HANDLE;
		}
	}

	new iMark = INVALID_ENT_REFERENCE;
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
			return INVALID_HANDLE;
	}

	if (GetConVarInt(g_hMarkBlockDMG) == 1 || (GetConVarInt(g_hMarkBlockDMG) == 2 && iTeam == TG_RedTeam)) {
		if (bBlockDMG) {
			g_PlayerData[iClient][MarkBlockDMG] = true;

			new iWeapon = Client_GetActiveWeapon(iClient);
			if (iWeapon != INVALID_ENT_REFERENCE) {
				SetEntProp(iWeapon, Prop_Send, "m_iClip1", GetEntProp(iWeapon, Prop_Send, "m_iClip1") + 1);
			}

			RequestFrame(Frame_MarkBlockDMG, iClient);
		}
	}


	if (g_Mark[iTeam][Sprite][0] != '\0' && IsDecalPrecached(g_Mark[iTeam][Sprite])) {
		fPos[2] += g_Mark[iTeam][High];

		if ((iMark = CreateEntityByName("env_sprite")) != -1) {
			DispatchKeyValue(iMark, "model", g_Mark[iTeam][Sprite]);
			DispatchKeyValueFloat(iMark, "scale", g_Mark[iTeam][Scale]);

			DispatchKeyValue(iMark, "rendermode", "5");
			DispatchKeyValue(iMark, "spawnflags", "1");

			DispatchKeyValue(iMark, "rendercolor", g_Mark[iTeam][Color]);
			DispatchKeyValueNum(iMark, "RenderAmt", g_Mark[iTeam][Alpha]);

			DispatchSpawn(iMark);
			TeleportEntity(iMark, fPos, NULL_VECTOR, NULL_VECTOR);
		}
	}

	new Handle:hMarkPack;
	new Handle:hMark = CreateDataTimer(fLife, Timer_KillMark, hMarkPack, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(hMarkPack, iMark);
	WritePackCell(hMarkPack, iClient);
	WritePackCell(hMarkPack, iTeam);
	WritePackFloat(hMarkPack, fPos[0]);
	WritePackFloat(hMarkPack, fPos[1]);
	WritePackFloat(hMarkPack, fPos[2]);
	WritePackFloat(hMarkPack, fLife);

	PushArrayCell(g_hMarks, _:hMark);

	if (bCount)
		g_iMarkLimitCounter++;

	g_PlayerData[iClient][AbleToMark] = false;

	if (GetConVarFloat(g_hMarkSpawnDelay) > 0.0) {
		CreateTimer(GetConVarFloat(g_hMarkSpawnDelay), Timer_AbleToMark, iClient);
	} else {
		RequestFrame(Frame_AbleToMark, iClient);
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

	Call_StartForward(Forward_OnMarkSpawned);
	Call_PushCell(iClient);
	Call_PushCell(iTeam);
	Call_PushArray(fPos, 3);
	Call_PushFloat(fLife);
	Call_PushCell(_:hMark);
	Call_PushCell(iMark);
	Call_Finish();


	return hMark;
}

public Action:Timer_KillMark(Handle:hTimer, Handle:hDataPack)
{
	new i = FindValueInArray(g_hMarks, _:hTimer);

	if (i != -1) {
		ResetPack(hDataPack);
		new iMark = ReadPackCell(hDataPack);
		new iClient = ReadPackCell(hDataPack);
		new iTeam = ReadPackCell(hDataPack);
		new Float:fPos[3];
		fPos[0] = ReadPackFloat(hDataPack);
		fPos[1] = ReadPackFloat(hDataPack);
		fPos[2] = ReadPackFloat(hDataPack);
		new Float:fLife = ReadPackFloat(hDataPack);

		if(IsValidEntity(iMark)) {
			AcceptEntityInput(iMark, "Kill");
		}
		RemoveFromArray(g_hMarks, i);

		if (g_iMarkLimitCounter > 0)
			g_iMarkLimitCounter--;

		Call_StartForward(Forward_OnMarkDestroyed);
		Call_PushCell(iClient);
		Call_PushCell(iTeam);
		Call_PushArray(fPos, 3);
		Call_PushFloat(fLife);
		Call_PushCell(hTimer);
		Call_PushCell(iMark);
		Call_Finish();
	}
}

DestroyOldestMark()
{
	if (GetArraySize(g_hMarks) > 0) {
		TriggerTimer(Handle:GetArrayCell(g_hMarks, 0));
	}
}

public Action:Timer_AbleToMark(Handle:hTimer, any:iClient)
{
	g_PlayerData[iClient][AbleToMark] = true;
}

public Frame_AbleToMark(any:iClient)
{
	g_PlayerData[iClient][AbleToMark] = true;
}
public Frame_MarkBlockDMG(any:iClient)
{
	g_PlayerData[iClient][MarkBlockDMG] = false;
}
