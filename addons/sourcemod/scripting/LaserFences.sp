#define FENCE_PRECACHE_HALO "materials/sprites/glow01.vmt"
#define FENCE_PRE_COLOR {0, 255, 0, 255}

new g_iFenceColor[4];
new Float:g_fFenceWidth;
new String:g_sFenceMaterial[PLATFORM_MAX_PATH];
new String:g_sFenceCornerModel[PLATFORM_MAX_PATH];

new g_iFenceMaterialPrecache = -1;
new g_iFenceHalo = -1;

new bool:g_bFencesMenuMapVisibility;

new Float:g_fFenceRectangleA[3], Float:g_fFenceRectangleB[3], Float:g_fFenceRectangleC[3], Float:g_fFenceRectangleD[3];
new bool:g_bFenceRectangle = false;

FencesMenu(iClient)
{
	new Float:fPos[3];
	GetClientAbsOrigin(iClient, fPos);

	new Handle:hDataPack = CreateDataPack();
	WritePackCell(hDataPack, iClient);
	WritePackFloat(hDataPack, fPos[0]);
	WritePackFloat(hDataPack, fPos[1]);
	WritePackFloat(hDataPack, fPos[2]);

	new Handle:hTimer = CreateTimer(0.1, Timer_FenceRectanglePre, hDataPack, TIMER_REPEAT);

	new Handle:hSubMenu = CreateMenu(FencesMenu_Rectangle_Handler);
	decl String:sTransMsg[256];
	Format(sTransMsg, sizeof(sTransMsg), "%T", "MenuFences-Confirm", iClient);
	SetMenuTitle(hSubMenu, sTransMsg);
	AddMenuItem(hSubMenu, "FENCES_MENU_CONFIRM", sTransMsg);
	PushMenuCell(hSubMenu, "-DATAPACK-", _:hDataPack);
	PushMenuCell(hSubMenu, "-TIMER-", _:hTimer);
	SetMenuExitBackButton(hSubMenu, true);
	DisplayMenu(hSubMenu, iClient, MENU_TIME_FOREVER);
}

public Action:Timer_FenceRectanglePre(Handle:hTimer, Handle:hDataPack) // Rectangle pre draw
{
	decl Float:fA[3], Float:fC[3];
	new iClient;

	ResetPack(hDataPack);
	iClient = ReadPackCell(hDataPack);
	fA[0] = ReadPackFloat(hDataPack);
	fA[1] = ReadPackFloat(hDataPack);
	fA[2] = ReadPackFloat(hDataPack) + 12.0;

	GetClientAbsOrigin(iClient, fC);

	TempEnt_Square(fA, fC, 0.11, FENCE_PRE_COLOR, 1.0, g_iFenceMaterialPrecache, g_iFenceHalo);

	fA[2] += 18.0;
	if (GetConVarFloat(g_hFenceHeight) < fA[2])
		return Plugin_Continue;

	TempEnt_Square(fA, fC, 0.11, FENCE_PRE_COLOR, 1.0, g_iFenceMaterialPrecache, g_iFenceHalo);

	fA[2] += 18.0;
	if (GetConVarFloat(g_hFenceHeight) < fA[2])
		return Plugin_Continue;

	TempEnt_Square(fA, fC, 0.11, FENCE_PRE_COLOR, 1.0, g_iFenceMaterialPrecache, g_iFenceHalo);

	return Plugin_Continue;
}

public FencesMenu_Rectangle_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey) // Rectangle hMenu handler
{
	if (iAction == MenuAction_Select) {
		decl String:sKey[32];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));

		if (StrEqual(sKey, "FENCES_MENU_CONFIRM")) {
			new Float:fA[3], Float:fC[3], Handle:hDataPack = INVALID_HANDLE;
			hDataPack = Handle:GetMenuCell(hMenu, "-DATAPACK-");
			ResetPack(hDataPack);
			iClient = ReadPackCell(hDataPack);
			fA[0] = ReadPackFloat(hDataPack);
			fA[1] = ReadPackFloat(hDataPack);
			fA[2] = ReadPackFloat(hDataPack);

			GetClientAbsOrigin(iClient, fC);
			CreateFence(fA, fC, iClient);

			MainMenu(iClient);
		}

		CloseHandle(Handle:GetMenuCell(hMenu, "-DATAPACK-"));
		CloseHandle(Handle:GetMenuCell(hMenu, "-TIMER-"));
	} else if (iAction == MenuAction_Cancel) {
		if (iKey == MenuCancel_Disconnected || iKey == MenuCancel_Interrupted || iKey == MenuCancel_Exit || iKey == MenuCancel_ExitBack) {
			CloseHandle(Handle:GetMenuCell(hMenu, "-DATAPACK-"));
			CloseHandle(Handle:GetMenuCell(hMenu, "-TIMER-"));
			MainMenu(iClient);
		}
	}
}

bool:CreateFence(Float:fA[3], Float:fC[3], iClient = 0)
{
	if (GetConVarInt(g_hFenceType) == 0) {
		return false;
	}
	DestroyFence();

	new Action:iResult = Plugin_Continue;
	Call_StartForward(Forward_OnLaserFenceCreate);
	Call_PushCell(iClient);
	Call_PushArray(fA, 3);
	Call_PushArray(fC, 3);
	Call_Finish(iResult);
	if (iResult != Plugin_Continue)
		return false;

	Call_StartForward(Forward_OnLaserFenceCreated);
	Call_PushCell(iClient);
	Call_PushArray(fA, 3);
	Call_PushArray(fC, 3);
	Call_Finish();

	CreateFencePoints(fA, fC);
	CreateBrushTrigger();
	CreateFenceCornerModels();
	g_bFenceRectangle = true;

	if (GetConVarInt(g_hFenceType) == 1) {
		fA[2] += 12.0; fC[2] += 12.0;
		SpawnBeamSquare(fA, fC, "__TG_FenceBeamRope_1_", g_sFenceMaterial, g_fFenceWidth, g_iFenceColor);

		fA[2] += 18.0; fC[2] += 18.0;
		SpawnBeamSquare(fA, fC, "__TG_FenceBeamRope_2_", g_sFenceMaterial, g_fFenceWidth, g_iFenceColor);

		fA[2] += 18.0; fC[2] += 18.0;
		SpawnBeamSquare(fA, fC, "__TG_FenceBeamRope_3_", g_sFenceMaterial, g_fFenceWidth, g_iFenceColor);
	} else if (GetConVarInt(g_hFenceType) == 2) {
		fA[2] += 12.0; fC[2] += 12.0;
		SpawnRopeSquare(fA, fC, "__TG_FenceBeamRope_1_", g_sFenceMaterial, g_fFenceWidth);

		fA[2] += 18.0; fC[2] += 18.0;
		SpawnRopeSquare(fA, fC, "__TG_FenceBeamRope_2_", g_sFenceMaterial, g_fFenceWidth);

		fA[2] += 18.0; fC[2] += 18.0;
		SpawnRopeSquare(fA, fC, "__TG_FenceBeamRope_3_", g_sFenceMaterial, g_fFenceWidth);
	}

	return true;
}

DestroyFence()
{
	if (g_bFenceRectangle) {
		Call_StartForward(Forward_OnLaserFenceDestroyed);
		Call_PushArray(g_fFenceRectangleA, 3);
		Call_PushArray(g_fFenceRectangleC, 3);
		Call_Finish();
	}

	g_bFenceRectangle = false;
	DestroyBrushTriggerAndBeamRope();
}

CreateFencePoints(Float:fA[3], Float:fC[3])
{
	g_fFenceRectangleA = fA;
	g_fFenceRectangleC = fC;

	if (fC[0] <= fA[0] && fC[1] <= fA[1]) {
		g_fFenceRectangleA = fC;
		g_fFenceRectangleC = fA;
	} else if (fA[0] >= fC[0] && fA[1] <= fC[1]) {
		g_fFenceRectangleA[0] = fC[0];
		g_fFenceRectangleC[0] = fA[0];
	} else if (fA[0] <= fC[0] && fA[1] >= fC[1]) {
		g_fFenceRectangleA[1] = fC[1];
		g_fFenceRectangleC[1] = fA[1];
	}

	g_fFenceRectangleB[0] = g_fFenceRectangleC[0];
	g_fFenceRectangleB[1] = g_fFenceRectangleA[1];
	g_fFenceRectangleD[0] = g_fFenceRectangleA[0];
	g_fFenceRectangleD[1] = g_fFenceRectangleC[1];

	g_fFenceRectangleA[2] += 12.0;
	g_fFenceRectangleB[2] = g_fFenceRectangleA[2];
	g_fFenceRectangleD[2] = g_fFenceRectangleA[2];
	g_fFenceRectangleC[2] = g_fFenceRectangleA[2];
}

CreateBrushTrigger()
{
	new Float:fStart[3], Float:fEnd[3];
	fStart = g_fFenceRectangleA;
	fEnd = g_fFenceRectangleC;
	fStart[2] -= 12.0;
	fEnd[2] -= 12.0;

	fStart[0] += 15.0;
	fStart[1] += 15.0;

	fEnd[0] -= 15.0;
	fEnd[1] -= 15.0;

	new Float:fVec[3];
	MakeVectorFromPoints(fStart, fEnd, fVec);

	new Float:fOrigin[3];
	fOrigin[0] = (fStart[0] + fEnd[0]) / 2;
	fOrigin[1] = (fStart[1] + fEnd[1]) / 2;
	fOrigin[2] = fStart[2];

	new Float:fMinBounds[3], Float:fMaxBounds[3];
	fMinBounds[0] = -1 * (fVec[0] / 2);
	fMaxBounds[0] = fVec[0] / 2;
	fMinBounds[1] = -1 * (fVec[1] / 2);
	fMaxBounds[1] = fVec[1] / 2;
	fMinBounds[2] = 0.0;
	fMaxBounds[2] = 128.0;

	new iEntity = CreateEntityByName("trigger_multiple");

	DispatchKeyValue(iEntity, "spawnflags", "64");
	DispatchKeyValue(iEntity, "targetname", "TG_LaserFence");
	DispatchKeyValue(iEntity, "wait", "0");

	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	SetEntProp(iEntity, Prop_Data, "m_spawnflags", 64);

	TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);

	SetEntityModel(iEntity, "models/props/cs_office/trash_can.mdl");

	SetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMinBounds);
	SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMaxBounds);

	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);

	new iEntityEffect = GetEntProp(iEntity, Prop_Send, "m_fEffects");
	iEntityEffect |= 32;
	SetEntProp(iEntity, Prop_Send, "m_fEffects", iEntityEffect);

	HookSingleEntityOutput(iEntity, "OnEndTouch", Hook_LaserFenceOnEndTouch);
}

CreateFenceCornerModels()
{
	CreateCornerModel(g_fFenceRectangleA);
	CreateCornerModel(g_fFenceRectangleB);
	CreateCornerModel(g_fFenceRectangleC);
	CreateCornerModel(g_fFenceRectangleD);
}

CreateCornerModel(Float:fPos[3])
{
	if (!IsModelPrecached(g_sFenceCornerModel))
		return;

	new Float:fOrigin[3];
	fOrigin = fPos;
	fOrigin[2] -= 12.0;

	new iEntity = CreateEntityByName("prop_dynamic_override");

	if (!IsValidEntity(iEntity))
		return;

	DispatchKeyValue(iEntity, "targetname", "__TG_LaserFenceCorner__");
	DispatchKeyValue(iEntity, "model", g_sFenceCornerModel);
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(iEntity, g_sFenceCornerModel);
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
}

public Hook_LaserFenceOnEndTouch(const String:sOutput[], iCaller, iActivator, Float:fDelay)
{
	if (!Client_IsIngame(iActivator) || GetClientTeam(iActivator) != CS_TEAM_T || !TG_IsTeamRedOrBlue(g_PlayerData[iActivator][Team]))
		return;

	new Float:fPos[3];
	GetClientAbsOrigin(iActivator, fPos);

	if (fPos[2] < g_fFenceRectangleA[2] + (GetConVarFloat(g_hFenceHeight) - 12.0))
		FencePunishPlayer(iActivator);
}

DestroyBrushTriggerAndBeamRope()
{
	new iEntityCount = GetMaxEntities();
	decl String:sClassName[256], String:sTargetName[256];
	for (new i = MaxClients; i < iEntityCount; i++) {
		if (!IsValidEntity(i))
			continue;

		GetEdictClassname(i, sClassName, sizeof(sClassName));
		if (StrEqual(sClassName, "trigger_multiple") || StrEqual(sClassName, "prop_dynamic") || StrEqual(sClassName, "move_rope") || StrEqual(sClassName, "keyframe_rope") || StrEqual(sClassName, "env_beam")) {
			GetEntPropString(i, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));

			if (StrEqual(sTargetName, "TG_LaserFence")) {
				UnhookSingleEntityOutput(i, "OnEndTouch", Hook_LaserFenceOnEndTouch);
				AcceptEntityInput(i, "Kill");
			} else if (StrEqual(sTargetName, "__TG_LaserFenceCorner__")) {
				RemoveEdict(i);
			} else if (StrContains(sTargetName, "__TG_FenceBeamRope_") == 0) {
				RemoveEdict(i);
			}
		}
	}
}

FencePunishPlayer(iClient, bool:CallForward = true)
{
	new Float:fTime = GetConVarFloat(g_hFencePunishLength);

	if (CallForward) {
		new Action:iResult = Plugin_Continue;
		Call_StartForward(Forward_OnLaserFenceCross);
		Call_PushCell(iClient);
		Call_PushFloatRef(fTime);
		Call_Finish(iResult);

		if (iResult == Plugin_Handled || iResult == Plugin_Stop)
			return;

		Call_StartForward(Forward_OnLaserFenceCrossed);
		Call_PushCell(iClient);
		Call_PushFloatRef(fTime);
		Call_Finish();
	}

	if (GetConVarInt(g_hFenceNotify) == 1 || (GetConVarInt(g_hFenceNotify) == 2 && g_Game[GameProgress] != TG_NoGame)) {
		decl String:sClientName[64];
		GetClientName(iClient, sClientName, sizeof(sClientName));
		CPrintToChatAll("%t" , "Fences-PlayerCross", sClientName);
	}

	if (GetConVarFloat(g_hFencePunishLength) == 0.0 || (GetConVarInt(g_hFencePunishColorSettings) == 0 && GetConVarInt(g_hFenceFreeze) == 0))
		return;

	if (!g_PlayerData[iClient][AbleToFencePunishColor])
		return;

	if (GetConVarInt(g_hFencePunishColorSettings) == 1 || (GetConVarInt(g_hFencePunishColorSettings) == 2 && g_Game[GameProgress] != TG_NoGame)) {
		g_PlayerData[iClient][AbleToFencePunishColor] = false;

		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iClient);
		WritePackCell(hDataPack, GetEntData(iClient, GetEntSendPropOffs(iClient, "m_clrRender", true), 1));
		WritePackCell(hDataPack, GetEntData(iClient, GetEntSendPropOffs(iClient, "m_clrRender", true) + 1, 1));
		WritePackCell(hDataPack, GetEntData(iClient, GetEntSendPropOffs(iClient, "m_clrRender", true) + 2, 1));
		WritePackCell(hDataPack, GetEntData(iClient, GetEntSendPropOffs(iClient, "m_clrRender", true) + 3, 1));
		SetEntityRenderColor(iClient, g_iFencePunishColor[0], g_iFencePunishColor[1], g_iFencePunishColor[2], 255);
		CreateTimer(fTime, Timer_FenceColorOff, hDataPack, 0);
	}

	if (GetConVarInt(g_hFenceFreeze) == 1 || (GetConVarInt(g_hFenceFreeze) == 2 && g_Game[GameProgress] != TG_NoGame)) {
		SetEntityMoveType(iClient, MOVETYPE_NONE);
		CreateTimer(fTime, Timer_FenceFreezeOff, iClient);
	}

	return;
}

public Action:Timer_FenceColorOff(Handle:hTimer, Handle:hDataPack)
{
	ResetPack(hDataPack);
	new iClient = ReadPackCell(hDataPack);
	new iRed = ReadPackCell(hDataPack);
	new iGreen = ReadPackCell(hDataPack);
	new iBlue = ReadPackCell(hDataPack);
	new iAlpha = ReadPackCell(hDataPack);
	CloseHandle(hDataPack);

	SetEntityRenderColor(iClient, iRed, iGreen, iBlue, iAlpha);
	g_PlayerData[iClient][AbleToFencePunishColor] = true;

	return Plugin_Continue;
}
public Action:Timer_FenceFreezeOff(Handle:hTimer, any:iClient)
{
	SetEntityMoveType(iClient, MOVETYPE_ISOMETRIC);
	return Plugin_Continue;
}

TempEnt_Square(Float:fA[3], Float:fC[3], Float:fLife, iColor[4], Float:fWidth, iModel, iHalo)
{
	new Float:b[3];
	new Float:d[3];
	b = fA; b[1] = fC[1];
	d = fA; d[0] = fC[0];
	fC[2] = fA[2];

	TE_SetupBeamPoints(fA, b, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(b, fC, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(fC, d, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(d, fA, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();
}

SpawnBeamSquare(Float:fA[3], Float:fC[3], const String:sNodePrefix[], const String:sBeamMaterial[] = "sprites/laserbeam.vmt", Float:fWidth = 2.0, iRGBA[4] = {255, 255, 255, 255})
{
	new Float:fBeams[4][3];

	fBeams[0] = fA;
	fBeams[1] = fA;
	fBeams[2] = fC;
	fBeams[3] = fA;

	fBeams[1][1] = fC[1];
	fBeams[2][2] = fA[2];
	fBeams[3][0] = fC[0];

	SpawnBeamChain(fBeams, 4, sNodePrefix, sBeamMaterial, fWidth, iRGBA, true);
}

SpawnBeamChain(Float:fNodes[][3], iNodeCount, const String:sNodePrefix[], const String:sBeamMaterial[] = "sprites/laserbeam.vmt", Float:fWidth = 2.0, iRGBA[4] = {255, 255, 255, 255}, bool:bLastNodeToFirst = false)
{
	if (iNodeCount < 2)
		return 0;

	decl String:sMaterial[PLATFORM_MAX_PATH];
	FormatEx(sMaterial, sizeof(sMaterial), "materials/%s", sBeamMaterial);

	if (!IsModelPrecached(sMaterial)) {
		return 0;
	}

	new iEntity, i;
	decl String:sNodeName[64], String:sNextNodeName[64];

	for (; i < iNodeCount; i++) {
		iEntity = CreateEntityByName("env_beam");

		if (!IsValidEntity(iEntity))
			return i;

		Format(sNodeName, sizeof(sNodeName), "%s%d", sNodePrefix, i);

		if (iNodeCount > i + 1) {
			Format(sNextNodeName, sizeof(sNextNodeName), "%s%d", sNodePrefix, i + 1);
		} else {
			if (bLastNodeToFirst)
				Format(sNextNodeName, sizeof(sNextNodeName), "%s0", sNodePrefix);
			else
				strcopy(sNextNodeName, sizeof(sNextNodeName), "");
		}

		DispatchKeyValue(iEntity, "targetname", sNodeName);
		DispatchKeyValue(iEntity, "texture", sMaterial);
		DispatchKeyValueFormat(iEntity, "BoltWidth", "%f", fWidth);
		DispatchKeyValue(iEntity, "life", "0");
		DispatchKeyValueFormat(iEntity, "rendercolor", "%d %d %d", iRGBA[0], iRGBA[1], iRGBA[2]);
		DispatchKeyValueFormat(iEntity, "renderamt", "%d", iRGBA[3]);
		DispatchKeyValue(iEntity, "TextureScroll", "0");
		DispatchKeyValue(iEntity, "LightningStart", sNodeName);
		DispatchKeyValue(iEntity, "LightningEnd", sNextNodeName);
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fNodes[i], NULL_VECTOR, NULL_VECTOR);

		CreateTimer(0.1, Timer_ActivateEntity, iEntity);
	}

	return i;
}

SpawnRopeSquare(Float:fA[3], Float:fC[3], const String:sNodePrefix[], const String:sRopeMaterial[] = "cable/rope.vmt", Float:fWidth = 2.0, iSlack = 0)
{
	new Float:fRopes[4][3];

	fRopes[0] = fA;
	fRopes[1] = fA;
	fRopes[2] = fC;
	fRopes[3] = fA;

	fRopes[1][1] = fC[1];
	fRopes[2][2] = fA[2];
	fRopes[3][0] = fC[0];

	SpawnRope(fRopes, 4, sNodePrefix, sRopeMaterial, fWidth, iSlack, true);
}

SpawnRope(Float:fNodes[][3], iNodeCount, const String:sNodePrefix[], const String:sRopeMaterial[] = "cable/rope.vmt", Float:fWidth = 2.0, iSlack = 0, bool:bLastNodeToFirst = false)
{
	if (iNodeCount < 2)
		return 0;

	decl String:sPrecachedMaterial[PLATFORM_MAX_PATH];
	FormatEx(sPrecachedMaterial, sizeof(sPrecachedMaterial), "materials/%s", sRopeMaterial);

	if (!IsModelPrecached(sPrecachedMaterial))
		return 0;

	new iEntity, i;
	decl String:sNodeName[64], String:sNextNodeName[64];

	for (; i < iNodeCount; i++) {
		if (i == 0) {
			iEntity = CreateEntityByName("move_rope");
		} else {
			iEntity = CreateEntityByName("keyframe_rope");
		}

		if (!IsValidEntity(iEntity))
			return i;

		Format(sNodeName, sizeof(sNodeName), "%s%d", sNodePrefix, i);

		if (iNodeCount > i + 1) {
			Format(sNextNodeName, sizeof(sNextNodeName), "%s%d", sNodePrefix, i + 1);
		} else {
			if (bLastNodeToFirst) {
				Format(sNextNodeName, sizeof(sNextNodeName), "%s0", sNodePrefix);
			} else {
				strcopy(sNextNodeName, sizeof(sNextNodeName), "");
			}
		}

		DispatchKeyValue(iEntity, "targetname", sNodeName);
		DispatchKeyValue(iEntity, "NextKey", sNextNodeName);
		DispatchKeyValue(iEntity, "RopeMaterial", sRopeMaterial);
		DispatchKeyValueFormat(iEntity, "Width", "%f", fWidth);
		DispatchKeyValueFormat(iEntity, "Slack", "%d", iSlack);
		DispatchKeyValue(iEntity, "Type", "0");
		DispatchKeyValue(iEntity, "TextureScale", "1");
		DispatchKeyValue(iEntity, "Subdiv", "2");
		DispatchKeyValue(iEntity, "PositionInterpolator", "2");
		DispatchKeyValue(iEntity, "MoveSpeed", "0");
		DispatchKeyValue(iEntity, "Dangling", "0");
		DispatchKeyValue(iEntity, "Collide", "0");
		DispatchKeyValue(iEntity, "Breakable", "0");
		DispatchKeyValue(iEntity, "Barbed", "0");
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fNodes[i], NULL_VECTOR, NULL_VECTOR);

		CreateTimer(0.1, Timer_ActivateEntity, iEntity);
	}

	return i;
}

public Action:Timer_ActivateEntity(Handle:hTimer, any:iEntity)
{
	ActivateEntity(iEntity);
	AcceptEntityInput(iEntity, "TurnOn");
	return Plugin_Continue;
}