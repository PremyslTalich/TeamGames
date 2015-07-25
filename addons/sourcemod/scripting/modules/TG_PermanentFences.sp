#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <teamgames>
#include <dtc>
#include <colorvariables>
#include <menu-stocks>

#define MENU_ITEM_ID_CREATE 				"PermanentFeces-Raska-Create"
#define MENU_ITEM_ID_DELETE 				"PermanentFeces-Raska-Delete"

#define TARGET_DOWNLOAD_PREFIX_CORNER 		"PermanentFeces-Corner"
#define TARGET_DOWNLOAD_PREFIX_MATERIAL 	"PermanentFeces-Material"

#define _BRUSH_MODEL 						"models/props/cs_office/trash_can.mdl"
#define _TARGET_NAME_PREFIX					"[TG_FENCE] TG_PermanentFence"
#define _PRE_HALO 							"materials/sprites/glow01.vmt"
#define _PRE_COLOR 							{0, 255, 0, 255}

enum Enum_Fence {
	m_iIndex,
	Float:m_fPosA[3],
	Float:m_fPosC[3]
};
new Handle:g_hFences;
new g_iFencesCount;

new String:g_sFenceModel[PLATFORM_MAX_PATH];
new String:g_sFenceMaterial[PLATFORM_MAX_PATH];
new g_iPreMaterial;
new g_iPreHalo;
new g_fFenceColor[4];
new Float:g_fFenceWidth;
new Float:g_fFenceSlack;

new Handle:g_hFenceType, g_iFenceType;
new bool:g_bEnabled;

public Plugin:myinfo = {
	name = "[TG] PermanentFeces",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.PermanentFeces-Raska.phrases");
	LoadTranslations("TeamGames.settings.phrases");
	
	g_hFenceType = CreateConVar("tg_pf_fence_type", "0", "0 = beam fence, 1 = rope fence");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames") && !TG_IsModuleReged(TG_MenuItem, MENU_ITEM_ID_CREATE)) {
		TG_RegMenuItem(MENU_ITEM_ID_CREATE, "%t", "CreateFence");
		TG_RegMenuItem(MENU_ITEM_ID_DELETE, "%t", "DeleteFence");
	}
}

public OnMapStart()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/teamgames");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/teamgames/permanentfences");
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
	
	new String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/teamgames/permanentfences/%s.disabled", sMap);
	if (FileExists(sPath, false)) {
		g_bEnabled = false;
		return;
	}
	g_bEnabled = true;
	
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/teamgames/permanentfences/%s.cfg", sMap);	
	if (!FileExists(sPath, false)) {
		new Handle:hFile = OpenFile(sPath ,"w");
		WriteFileLine(hFile, "// Automatically created KeyValues file for map '%s' by TG_PermanentFences.smx", sMap);
		WriteFileLine(hFile, "\"PermanentFences\"");
		WriteFileLine(hFile, "{");
		WriteFileLine(hFile, "");
		WriteFileLine(hFile, "}");
		CloseHandle(hFile);
	}
	
	new Handle:hKeyValues = CreateKeyValues("PermanentFences");
	
	if (!FileToKeyValues(hKeyValues, sPath)) {
		LogError("Reading error in %s.", sPath);
		return;
	}
	
	g_hFences = CreateArray(_:Enum_Fence);
	g_iFencesCount = -1;
	
	PrecacheModel(_BRUSH_MODEL, true);
	g_iPreHalo = PrecacheModel(_PRE_HALO);
	
	new Float:fPosA[3], Float:fPosC[3];
	
	if (KvGotoFirstSubKey(hKeyValues)) {
		do {
			KvGetVector(hKeyValues, "PositionA", fPosA);
			KvGetVector(hKeyValues, "PositionC", fPosC);
			
			g_iFencesCount++;
			new eFence[Enum_Fence];
			eFence[m_fPosA] = fPosA;
			eFence[m_fPosC] = fPosC;
			eFence[m_iIndex] = g_iFencesCount;
			PushArrayArray(g_hFences, eFence[0]);
			
		} while (KvGotoNextKey(hKeyValues));
	}
	
	CloseHandle(hKeyValues);
}

public TG_OnDownloadFile(String:sFile[], String:sPrefixName[], Handle:hArgs, &bool:bKnown)
{
	if (StrEqual(sPrefixName, TARGET_DOWNLOAD_PREFIX_CORNER) || StrEqual(sPrefixName, TARGET_DOWNLOAD_PREFIX_MATERIAL)) {
		bKnown = true;
		
		decl String:sMap[64], String:sPath[PLATFORM_MAX_PATH];
		GetCurrentMap(sMap, sizeof(sMap));
		
		BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/teamgames/permanentfences/%s.disabled", sMap);
		if (FileExists(sPath, false)) {
			g_bEnabled = false;
			return;
		}
		g_bEnabled = true;
	}
	
	if (StrEqual(sPrefixName, TARGET_DOWNLOAD_PREFIX_CORNER)) {
		PrecacheModel(sFile);
		strcopy(g_sFenceModel, sizeof(g_sFenceModel), sFile);
	} else if (StrEqual(sPrefixName, TARGET_DOWNLOAD_PREFIX_MATERIAL)) {
		strcopy(g_sFenceMaterial, sizeof(g_sFenceMaterial), sFile);
		g_iPreMaterial = PrecacheModel(g_sFenceMaterial);
		ReplaceStringEx(g_sFenceMaterial, sizeof(g_sFenceMaterial), "materials/", "");
		PrecacheModel(g_sFenceMaterial);
		
		g_fFenceWidth = DTC_GetArgFloat(hArgs, 1, 2.0);
		
		g_fFenceColor[0] = DTC_GetArgNum(hArgs, 2, 255);
		g_fFenceColor[1] = DTC_GetArgNum(hArgs, 3, 255);
		g_fFenceColor[2] = DTC_GetArgNum(hArgs, 4, 255);
		g_fFenceColor[3] = DTC_GetArgNum(hArgs, 5, 255);
		
		g_fFenceSlack = DTC_GetArgFloat(hArgs, 6, 0.0);		
	}
}

public OnPluginEnd()
{
	TG_RemoveMenuItem(MENU_ITEM_ID_CREATE);
	TG_RemoveMenuItem(MENU_ITEM_ID_DELETE);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled) {
		return;
	}
	
	g_iFenceType = GetConVarInt(g_hFenceType);
	
	if (g_hFences != INVALID_HANDLE) {
		new iFencesCount = GetArraySize(g_hFences);
		new iIndex;
		new Float:fPosA[3], Float:fPosC[3];
		new eFence[Enum_Fence];
		
		for (new i = 0; i < iFencesCount; i++) {
			GetArrayArray(g_hFences, i, eFence[0]);
			
			iIndex = eFence[m_iIndex];
			fPosA[0] = eFence[m_fPosA][0];
			fPosA[1] = eFence[m_fPosA][1];
			fPosA[2] = eFence[m_fPosA][2];
			fPosC[0] = eFence[m_fPosC][0];
			fPosC[1] = eFence[m_fPosC][1];
			fPosC[2] = eFence[m_fPosC][2];
			
			CreateFence(fPosA, fPosC, iIndex);
		}
	}
}

public TG_OnMenuItemDisplay(const String:id[], iClient, &TG_MenuItemStatus:status, String:name[])
{
	if (StrEqual(id, MENU_ITEM_ID_CREATE)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "CreateFence", iClient);
		
		if (!g_bEnabled) {
			status = TG_Disabled;
		}
	} else if (StrEqual(id, MENU_ITEM_ID_DELETE)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "DeleteFence", iClient);
		
		if (!g_bEnabled) {
			status = TG_Disabled;
		}
	}
}

public TG_OnMenuItemSelected(const String:id[], iClient)
{
	if (StrEqual(id, MENU_ITEM_ID_CREATE, true) && g_bEnabled) {
		new Float:fPos[3];
		GetClientAbsOrigin(iClient, fPos);
		
		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iClient);
		WritePackFloat(hDataPack, fPos[0]);
		WritePackFloat(hDataPack, fPos[1]);
		WritePackFloat(hDataPack, fPos[2]);
		
		new Handle:hTimer = CreateTimer(0.1, Timer_FencePre, hDataPack, TIMER_REPEAT);
		
		new Handle:hMenu = CreateMenu(Menu_CreateFencePointC);
		SetMenuTitle(hMenu, "%T", "CreateFence-MenuTitle", iClient);
		AddMenuItemFormat(hMenu, "CreatePointC", _, "%T", "CreatePointC", iClient);
		PushMenuCell(hMenu, "-DATAPACK-", _:hDataPack);
		PushMenuCell(hMenu, "-TIMER-", _:hTimer);
		SetMenuExitButton(hMenu, true);
		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	} else if (StrEqual(id, MENU_ITEM_ID_DELETE, true) && g_bEnabled) {
		
		new iFencesCount = GetArraySize(g_hFences);
		new eFence[Enum_Fence];
		new iIndex = -1;
		new Float:fClientPos[3];
		
		GetClientAbsOrigin(iClient, fClientPos);
		
		for (new i = 0; i < iFencesCount; i++) {
			GetArrayArray(g_hFences, i, eFence[0]);
			
			if (fClientPos[0] > eFence[m_fPosA][0] && fClientPos[0] < eFence[m_fPosC][0]) {
				if (fClientPos[1] > eFence[m_fPosA][1] && fClientPos[1] < eFence[m_fPosC][1]) {
					if (fClientPos[2] > eFence[m_fPosA][2] - 1 && fClientPos[2] < eFence[m_fPosA][2] + 128.0) {
						iIndex = eFence[m_iIndex];
						break;
					}
				}
			}
		}
		
		CSkipNextPrefix();
		if (iIndex != -1) {
			DestroyFence(iIndex);
			
			CPrintToChat(iClient, "%T", "FenceDeleted", iClient);
		} else {
			CPrintToChat(iClient, "%T", "MustStandInFence", iClient);
		}
	}
}

public Action:Timer_FencePre(Handle:hTimer, Handle:hDataPack)
{
	decl Float:fPosA[3], Float:fPosC[3];
	new iClient;
	
	ResetPack(hDataPack);
	iClient = ReadPackCell(hDataPack);
	fPosA[0] = ReadPackFloat(hDataPack);
	fPosA[1] = ReadPackFloat(hDataPack);
	fPosA[2] = ReadPackFloat(hDataPack) + 12.0;	
	GetClientAbsOrigin(iClient, fPosC);
	
	TempEnt_Square(fPosA, fPosC, 0.11, _PRE_COLOR, 1.0, g_iPreMaterial, g_iPreHalo);
	
	fPosA[2] += 18.0;	
	TempEnt_Square(fPosA, fPosC, 0.11, _PRE_COLOR, 1.0, g_iPreMaterial, g_iPreHalo);
	
	fPosA[2] += 18.0;	
	TempEnt_Square(fPosA, fPosC, 0.11, _PRE_COLOR, 1.0, g_iPreMaterial, g_iPreHalo);
	
	return Plugin_Continue;
}

public Menu_CreateFencePointC(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	new Handle:hDataPack = Handle:GetMenuCell(hMenu, "-DATAPACK-");
	new Handle:hTimer = Handle:GetMenuCell(hMenu, "-TIMER-");
	
	if (iAction == MenuAction_Select) {
		new String:sKey[24];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));
		
		if (StrEqual(sKey, "CreatePointC")) {
			new Float:fPosA[3], Float:fPosC[3];
			new iUser;
			
			ResetPack(hDataPack);
			iUser = ReadPackCell(hDataPack);
			fPosA[0] = ReadPackFloat(hDataPack);
			fPosA[1] = ReadPackFloat(hDataPack);
			fPosA[2] = ReadPackFloat(hDataPack);
			GetClientAbsOrigin(iUser, fPosC);
			
			g_iFencesCount++;
			
			CreateFence(fPosA, fPosC, g_iFencesCount);
			
			new eFence[Enum_Fence];
			eFence[m_fPosA] = fPosA;
			eFence[m_fPosC] = fPosC;
			eFence[m_iIndex] = g_iFencesCount;
			PushArrayArray(g_hFences, eFence[0]);
			
			DumpFecesToFile();
			
			CSkipNextPrefix();
			CPrintToChat(iUser, "%T", "FenceCreated", iUser);			
		}
		
		CloseHandle(hDataPack);
		CloseHandle(hTimer);
	}
	else if(iAction == MenuAction_Cancel)
	{
		if(iKey == MenuCancel_Disconnected || iKey == MenuCancel_Interrupted || iKey == MenuCancel_Exit || iKey == MenuCancel_ExitBack)
		{
			CloseHandle(hDataPack);
			CloseHandle(hTimer);
		}
	}
}

CreateFence(Float:a[3], Float:c[3], iIndex)
{
	new String:sTargetName[256];	
	new Float:fPosA[3], Float:fPosB[3], Float:fPosC[3], Float:fPosD[3];
	new Float:fPos[3], Float:fMax[3], Float:fMin[3], Float:fDiagonal[3];
	
	fPosA = a;
	fPosC = c;
	
	if (c[0] <= a[0] && c[1] <= a[1]) {
		fPosA = c;
		fPosC = a;
	} else if (a[0] >= c[0] && a[1] <= c[1]) {
		fPosA[0] = c[0];
		fPosC[0] = a[0];
	} else if (a[0] <= c[0] && a[1] >= c[1]) {
		fPosA[1] = c[1];
		fPosC[1] = a[1];
	}
	
	a = fPosA;
	c = fPosC;
	
	fPosB[0] = fPosC[0];
	fPosB[1] = fPosA[1];
	fPosD[0] = fPosA[0];
	fPosD[1] = fPosC[1];	
	fPosB[2] = fPosC[2] = fPosD[2] = fPosA[2];
	
	new Float:fCorners[4][3];
	fCorners[0] = fPosA;
	fCorners[1] = fPosB;
	fCorners[2] = fPosC;
	fCorners[3] = fPosD;
	
	fPosA[0] += 15.0;
	fPosA[1] += 15.0;
	
	fPosC[0] -= 15.0;
	fPosC[1] -= 15.0;
	
	MakeVectorFromPoints(fPosA, fPosC, fDiagonal);
	
	fPos[0] = (fPosA[0] + fPosC[0]) / 2;
	fPos[1] = (fPosA[1] + fPosC[1]) / 2;
	fPos[2] = fPosA[2];
	
	fMin[0] = -1 * (fDiagonal[0] / 2);
	fMax[0] = fDiagonal[0] / 2;
	fMin[1] = -1 * (fDiagonal[1] / 2);
	fMax[1] = fDiagonal[1] / 2;
	fMin[2] = 0.0;
	fMax[2] = 128.0;
	
	Format(sTargetName, sizeof(sTargetName), "%s_%d", _TARGET_NAME_PREFIX, iIndex);
	
	CreateFenceBrush(fPos, fMax, fMin, sTargetName);
	
	CreateFenceCorner(fCorners[0], sTargetName);
	CreateFenceCorner(fCorners[1], sTargetName);
	CreateFenceCorner(fCorners[2], sTargetName);
	CreateFenceCorner(fCorners[3], sTargetName);
	
	fCorners[0][2] = fCorners[1][2] = fCorners[2][2] = fCorners[3][2] += 12.0;
	
	for (new i = 0; i < 3; i++) {
		Format(sTargetName, sizeof(sTargetName), "%s_%d_%d", _TARGET_NAME_PREFIX, iIndex, i);
		
		if (g_iFenceType == 0) {
			CreateFenceBeamSquare(fCorners, sTargetName);
		} else {
			CreateFenceRopeSquare(fCorners, sTargetName);
		}
		
		fCorners[0][2] = fCorners[1][2] = fCorners[2][2] = fCorners[3][2] += 18.0;
	}
}

CreateFenceBrush(Float:fPos[3], Float:fMax[3], Float:fMin[3], const String:sTargetName[])
{
	new iEntity = CreateEntityByName("trigger_multiple");
	
	DispatchKeyValue(iEntity, "spawnflags", "64");
	DispatchKeyValue(iEntity, "targetname", sTargetName);
	DispatchKeyValue(iEntity, "wait", "0");
	
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	SetEntProp(iEntity, Prop_Data, "m_spawnflags", 64);
	
	TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityModel(iEntity, _BRUSH_MODEL);
	
	SetEntPropVector(iEntity, Prop_Send, "m_vecMins", fMin);
	SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", fMax);
	
	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
	
	new iEntityEffects = GetEntProp(iEntity, Prop_Send, "m_fEffects");
	iEntityEffects |= 32;
	SetEntProp(iEntity, Prop_Send, "m_fEffects", iEntityEffects);
}

CreateFenceCorner(Float:fPos[3], const String:sTargetName[])
{
	if(!IsModelPrecached(g_sFenceModel))
		return;
	
	new iEntity = CreateEntityByName("prop_dynamic_override");
	
	if(!IsValidEntity(iEntity))
		return;
	
	DispatchKeyValue(iEntity, "targetname", sTargetName);
	DispatchKeyValue(iEntity, "model", g_sFenceModel);
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(iEntity, g_sFenceModel);
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
}

CreateFenceBeamSquare(Float:fPositions[4][3], const String:sTargetName[])
{
	new String:sPrecachedMaterial[PLATFORM_MAX_PATH];
	FormatEx(sPrecachedMaterial, sizeof(sPrecachedMaterial), "materials/%s", g_sFenceMaterial);
	
	if(!IsModelPrecached(sPrecachedMaterial))
		return;
	
	new iEntity;
	new String:sNodeName[64], String:sNextNodeName[64];
		
	for (new i; i < 4; i++) {
		iEntity = CreateEntityByName("env_beam");
		
		if(!IsValidEntity(iEntity))
			return;
		
		Format(sNodeName, sizeof(sNodeName), "%s_%d", sTargetName, i);
		
		if (i + 1 < 4) {
			Format(sNextNodeName, sizeof(sNextNodeName), "%s_%d", sTargetName, i + 1);
		} else {
			Format(sNextNodeName, sizeof(sNextNodeName), "%s_0", sTargetName);
		}
		
		DispatchKeyValue(iEntity, "targetname", sNodeName);
		DispatchKeyValue(iEntity, "texture", g_sFenceMaterial);
		DispatchKeyValueFormat(iEntity, "BoltWidth", "%f", g_fFenceWidth);
		DispatchKeyValue(iEntity, "life", "0");
		DispatchKeyValueFormat(iEntity, "rendercolor", "%d %d %d", g_fFenceColor[0], g_fFenceColor[1], g_fFenceColor[2]);
		DispatchKeyValueFormat(iEntity, "renderamt", "%d", g_fFenceColor[3]);
		DispatchKeyValue(iEntity, "TextureScroll", "0");
		DispatchKeyValue(iEntity, "LightningStart", sNodeName);
		DispatchKeyValue(iEntity, "LightningEnd", sNextNodeName);
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fPositions[i], NULL_VECTOR, NULL_VECTOR);
		
		CreateTimer(0.1, Timer_ActivateEntity, iEntity);
	}
}

CreateFenceRopeSquare(Float:fPositions[4][3], const String:sTargetName[])
{
	new String:sPrecachedMaterial[PLATFORM_MAX_PATH];
	FormatEx(sPrecachedMaterial, sizeof(sPrecachedMaterial), "materials/%s", g_sFenceMaterial);
	
	if(!IsModelPrecached(sPrecachedMaterial))
		return;
	
	new iEntity;
	new String:sNodeName[64], String:sNextNodeName[64];
		
	for (new i; i < 4; i++) {
		if (i == 0)
			iEntity = CreateEntityByName("move_rope");
		else
			iEntity = CreateEntityByName("keyframe_rope");
		
		if (!IsValidEntity(iEntity))
			return;
		
		Format(sNodeName, sizeof(sNodeName), "%s_%d", sTargetName, i);
		
		if (i + 1 < 4) {
			Format(sNextNodeName, sizeof(sNextNodeName), "%s_%d", sTargetName, i + 1);
		}
		else {
			Format(sNextNodeName, sizeof(sNextNodeName), "%s_0", sTargetName);
		}
		
		DispatchKeyValue(iEntity, "targetname", sNodeName);
		DispatchKeyValue(iEntity, "NextKey", sNextNodeName);
		DispatchKeyValue(iEntity, "RopeMaterial", g_sFenceMaterial);
		DispatchKeyValueFormat(iEntity, "Width", "%f", g_fFenceWidth);
		DispatchKeyValueFormat(iEntity, "Slack", "%d", g_fFenceSlack);
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
		TeleportEntity(iEntity, fPositions[i], NULL_VECTOR, NULL_VECTOR);
		
		CreateTimer(0.1, Timer_ActivateEntity, iEntity);
	}
}

DestroyFence(iIndex)
{
	new iFencesCount = GetArraySize(g_hFences);
	new eFence[Enum_Fence];
	
	for (new i = 0; i < iFencesCount; i++) {
		GetArrayArray(g_hFences, i, eFence[0]);
		
		if (eFence[m_iIndex] == iIndex) {
			RemoveFromArray(g_hFences, i);
			break;
		}
	}
	
	new iEntityCount = GetMaxEntities();
	new String:sClassName[256], String:sTargetName[256], String:sTargetNamePrefix[256];
	
	Format(sTargetNamePrefix, sizeof(sTargetNamePrefix), "%s_%d", _TARGET_NAME_PREFIX, iIndex);
	
	for (new iEntity = MaxClients; iEntity < iEntityCount; iEntity++) {
		if (IsValidEntity(iEntity)) {
			GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
			
			if (StrEqual(sClassName,"trigger_multiple")) {
				GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
				
				if (StrContains(sTargetName, sTargetNamePrefix) == 0) {
					AcceptEntityInput(iEntity, "Kill");
				}
			} else if (StrEqual(sClassName, "prop_dynamic") || StrEqual(sClassName, "move_rope") || StrEqual(sClassName, "keyframe_rope") || StrEqual(sClassName, "env_beam")) {
				GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, sizeof(sTargetName));
				
				if (StrContains(sTargetName, sTargetNamePrefix) == 0) {
					RemoveEdict(iEntity);
				}
			}
		}
	}
	
	DumpFecesToFile();
}

TempEnt_Square(Float:fPosA[3], Float:fPosC[3], Float:fLife, iColor[4], Float:fWidth, iModel, iHalo)
{
	new Float:fPosB[3];
	new Float:fPosD[3];
	fPosB = fPosA; fPosB[1] = fPosC[1];
	fPosD = fPosA; fPosD[0] = fPosC[0];
	fPosC[2] = fPosA[2];
	
	TE_SetupBeamPoints(fPosA, fPosB, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();                                               
	TE_SetupBeamPoints(fPosB, fPosC, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();                                               
	TE_SetupBeamPoints(fPosC, fPosD, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();                                               
	TE_SetupBeamPoints(fPosD, fPosA, iModel, iHalo, 1, 0, fLife, fWidth, fWidth, 0, 0.0, iColor, 0);
	TE_SendToAll();
}

DumpFecesToFile()
{
	new String:sMap[64];	
	GetCurrentMap(sMap, sizeof(sMap));
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/teamgames/permanentfences/%s.cfg", sMap);
	
	new Handle:hFile = OpenFile(sPath ,"w");
	WriteFileLine(hFile, "// Automatically created KeyValues file for map '%s' by TG_PermanentFences.smx", sMap);
	WriteFileLine(hFile, "\"PermanentFences\"");
	WriteFileLine(hFile, "{");
	WriteFileLine(hFile, "");
	WriteFileLine(hFile, "}");
	CloseHandle(hFile);
	
	new Handle:hKeyValues = CreateKeyValues("PermanentFences");
	
	if (!FileToKeyValues(hKeyValues, sPath)) {
		LogError("Writing error in %s.", sPath);
		return;
	}
	
	new iFencesCount = GetArraySize(g_hFences);
	new String:sIndex[24];
	new Float:fPosA[3], Float:fPosC[3];
	new eFence[Enum_Fence];
	
	for (new i = 0; i < iFencesCount; i++) {
		GetArrayArray(g_hFences, i, eFence[0]);
		IntToString(i, sIndex, sizeof(sIndex));
		
		KvJumpToKey(hKeyValues, sIndex, true);
		
		fPosA[0] = eFence[m_fPosA][0];
		fPosA[1] = eFence[m_fPosA][1];
		fPosA[2] = eFence[m_fPosA][2];
		fPosC[0] = eFence[m_fPosC][0];
		fPosC[1] = eFence[m_fPosC][1];
		fPosC[2] = eFence[m_fPosC][2];
		
		KvSetVector(hKeyValues, "PositionA", fPosA);
		KvSetVector(hKeyValues, "PositionC", fPosC);
		
		KvGoBack(hKeyValues);
	}
	
	KvRewind(hKeyValues);
	KeyValuesToFile(hKeyValues, sPath);
	CloseHandle(hKeyValues);
}

public Action:Timer_ActivateEntity(Handle:hTimer, any:iEntity)
{
	ActivateEntity(iEntity);
	AcceptEntityInput(iEntity, "TurnOn"); 
	return Plugin_Continue;
}

