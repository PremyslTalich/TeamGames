#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <teamgames>

#define MENU_ITEM_ID_SPAWNBOMB 	"BombToss-SpawnBomb"
#define MENU_ITEM_ID_TARGET 	"BombToss-Target"

#define TARGET_DOWNLOAD_PREFIX 	"BombToss-Target"

#define TARGET_TARGETNAME 		"BombToss-Target"
#define BOMB_TARGETNAME 		"BombToss"
#define BOMB_TARGETNAME_USED 	"BombToss-"

new Handle:g_hOneBomb, Handle:g_hMaxBombs;

new String:g_sTargetModel[PLATFORM_MAX_PATH];
new Float:g_fTargetPosition[3];
new g_iTargetEntity = -1;

new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_hBombList = INVALID_HANDLE;
new Handle:g_hTossedBombList = INVALID_HANDLE;

new g_iBombCounter = 0;

public Plugin:myinfo =
{
	name = "[TG] BombToss",
	author = "Raska",
	description = "",
	version = "0.8",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.BombToss.phrases");

	g_hOneBomb =  CreateConVar("tgm_bombtoss_onebomb",  "1",  "Prisoners can carry only one bomb. This is not just for this plugin, but for all bombs on server.");
	g_hMaxBombs = CreateConVar("tgm_bombtoss_maxbombs", "32", "Maximum number of bombs spawned at once.");

	HookEvent("round_start", 	Event_RoundStart, 	EventHookMode_Post);
	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode_Post);

	AutoExecConfig(_, _, "sourcemod/teamgames");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames")) {
		TG_RegMenuItem(MENU_ITEM_ID_SPAWNBOMB);
		TG_RegMenuItem(MENU_ITEM_ID_TARGET);
	}
}

public TG_OnDownloadFile(String:sFile[], String:sPrefixName[], Handle:hArgs, &bool:bKnown)
{
	if (StrEqual(sPrefixName, TARGET_DOWNLOAD_PREFIX, false)) {
		PrecacheModel(sFile);
		strcopy(g_sTargetModel, sizeof(g_sTargetModel), sFile);
		bKnown = true;
	}
}

public OnPluginEnd()
{
	TG_RemoveMenuItem(MENU_ITEM_ID_SPAWNBOMB);
	TG_RemoveMenuItem(MENU_ITEM_ID_TARGET);

	g_hTimer = INVALID_HANDLE;
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_WeaponCanUse, 		Hook_OnWeaponCanUse);
	SDKHook(iClient, SDKHook_WeaponDropPost, 	Hook_WeaponDrop);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_hTimer = INVALID_HANDLE;

	if (g_hBombList != INVALID_HANDLE) {
		CloseHandle(g_hBombList);
	}

	g_hBombList = CreateArray();

	if (g_hTossedBombList != INVALID_HANDLE) {
		CloseHandle(g_hTossedBombList);
	}

	g_hTossedBombList = CreateArray();

	g_iBombCounter = 0;
	RemoveTarget();
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_MenuItem) {
		return;
	}

	if (StrEqual(id, MENU_ITEM_ID_SPAWNBOMB)) {
		if (g_iBombCounter < GetConVarInt(g_hMaxBombs)) {
			status = TG_Active;
		} else {
			status = TG_Inactive;
		}

		Format(name, maxSize, "%T", "SpawnBomb", client, GetConVarInt(g_hMaxBombs) - g_iBombCounter);
	} else if (StrEqual(id, MENU_ITEM_ID_TARGET)) {
		Format(name, maxSize, "%T", "SpawnTarget", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], iClient) // somebody selected BombToss item in menu
{
	if (type != TG_MenuItem) {
		return;
	}

	if (StrEqual(id, MENU_ITEM_ID_SPAWNBOMB, true)) {
		if (g_iBombCounter >= GetConVarInt(g_hMaxBombs)){
			return;
		}

		decl Float:ClientPosition[3];
		GetClientAbsOrigin(iClient, ClientPosition);

		new iWeapon = CreateEntityByName("weapon_c4");
		DispatchKeyValue(iWeapon, "targetname", BOMB_TARGETNAME);
		DispatchKeyValue(iWeapon, "Solid", "6");
		DispatchSpawn(iWeapon);
		TeleportEntity(iWeapon, ClientPosition, NULL_VECTOR, NULL_VECTOR);
		SetEntData(iWeapon, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
		g_iBombCounter++;

		TG_LogRoundMessage("BombToss", "Player %L spawned bomb. (%d bombs remaining)", iClient, GetConVarInt(g_hMaxBombs) - g_iBombCounter);

		TurnTimerOn();
		TG_FakeSelect(iClient, TG_MenuItem, "Core_MainMenu");
	} else if (StrEqual(id, MENU_ITEM_ID_TARGET, true)) {
		if (!IsModelPrecached(g_sTargetModel)) {
			return;
		}

		RemoveTarget();

		g_iTargetEntity = CreateEntityByName("prop_physics_override");

		if (!IsValidEntity(g_iTargetEntity)) {
			return;
		}

		GetClientAbsOrigin(iClient, g_fTargetPosition);

		DispatchKeyValue(g_iTargetEntity, "targetname", TARGET_TARGETNAME);
		DispatchKeyValue(g_iTargetEntity, "model", g_sTargetModel);
		DispatchKeyValue(g_iTargetEntity, "spawnflags", "4");
		DispatchSpawn(g_iTargetEntity);
		TeleportEntity(g_iTargetEntity, g_fTargetPosition, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(g_iTargetEntity, g_sTargetModel);
		SetEntityMoveType(g_iTargetEntity, MOVETYPE_NONE);

		TG_LogRoundMessage("BombToss", "Player %L spawned target.", iClient);

		TG_FakeSelect(iClient, TG_MenuItem, "Core_MainMenu");
	}

	return;
}

public Action:Hook_OnWeaponCanUse(iClient, weapon) // hook pickup bomb
{
	decl String:sWeaponClassName[32];
	GetEdictClassname(weapon, sWeaponClassName, sizeof(sWeaponClassName));

	if (StrEqual(sWeaponClassName, "weapon_c4")) {
		if (GetConVarBool(g_hOneBomb) && Client_GetWeapon(iClient, "weapon_c4") != INVALID_ENT_REFERENCE)
			return Plugin_Handled;

		decl String:sWeaponTargetName[64];
		GetEntPropString(weapon, Prop_Data, "m_iName", sWeaponTargetName, sizeof(sWeaponTargetName));

		if (StrEqual(sWeaponTargetName, BOMB_TARGETNAME)) {
			PushArrayCell(g_hBombList, weapon);
		} else if (StrContains(sWeaponTargetName, BOMB_TARGETNAME_USED) == 0) {
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Hook_WeaponDrop(iClient, weapon) // hook drop bomb
{
	if (g_hBombList == INVALID_HANDLE) {
		g_hBombList = CreateArray();
	}

	if (FindValueInArray(g_hBombList, weapon) != -1) {
		decl String:sWeaponTargetName[64];

		Format(sWeaponTargetName, sizeof(sWeaponTargetName), "%s%d", BOMB_TARGETNAME_USED, GetClientUserId(iClient));
		Entity_SetName(weapon, sWeaponTargetName);
		SetEntityRenderColor(weapon, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
		PushArrayCell(g_hTossedBombList, weapon);

		RemoveFromArray(g_hBombList, FindValueInArray(g_hBombList, weapon));
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast) // hook shot to bomb or target
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (Client_IsIngame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == CS_TEAM_CT) {
		new iEntity = GetClientAimTarget(iClient, false);

		if (g_iTargetEntity != -1 && iEntity == g_iTargetEntity) {
			RemoveTarget();
			return Plugin_Continue;
		}

		if (g_hTimer == INVALID_HANDLE) {
			return Plugin_Continue;
		}

		if (iEntity < 0 || !IsValidEdict(iEntity)) {
			return Plugin_Continue;
		}

		decl String:EntityClassName[32];
		GetEdictClassname(iEntity, EntityClassName, sizeof(EntityClassName));

		if (g_iBombCounter > 0 && StrEqual(EntityClassName, "weapon_c4")) {
			decl String:sEntityTargetName[64];
			GetEntPropString(iEntity, Prop_Data, "m_iName", sEntityTargetName, sizeof(sEntityTargetName));

			if (StrContains(sEntityTargetName, BOMB_TARGETNAME) == 0) {
				AcceptEntityInput(iEntity, "Kill");

				new iBomb = FindValueInArray(g_hTossedBombList, iEntity);

				if (iBomb != -1) {
					RemoveFromArray(g_hTossedBombList, iBomb);
				} else {
					iBomb = FindValueInArray(g_hBombList, iEntity);

					if (iBomb != -1) {
						RemoveFromArray(g_hBombList, iBomb);
					}
				}

				g_iBombCounter--;

				if (g_iBombCounter < 1 && g_hTimer != INVALID_HANDLE) {
					g_hTimer = INVALID_HANDLE;
				}
			}
		}
	}

	return Plugin_Continue;
}

TurnTimerOn()
{
	if (g_hTimer == INVALID_HANDLE) {
		g_hTimer = CreateTimer(0.2, Timer_BombLookEvent, _, TIMER_REPEAT);
	}
}

public Action:Timer_BombLookEvent(Handle:hTimer)
{
	if (g_hTimer == INVALID_HANDLE) {
		return Plugin_Stop;
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (!Client_IsIngame(i)) {
			continue;
		}

		ShowBombInfo(i, GetClientAimTarget(i, false));
	}

	return Plugin_Continue;
}

ShowBombInfo(iClient, iEntity)
{
	if (!Client_IsIngame(iClient) || !IsValidEntity(iEntity) || g_iBombCounter == 0) {
		return;
	}

	if (g_iTargetEntity == iEntity) {
		new iSize = GetArraySize(g_hTossedBombList);

		if (iSize < 1) {
			return;
		}

		new iNearest = GetArrayCell(g_hTossedBombList, 0);
		new iFarthest = GetArrayCell(g_hTossedBombList, 0);
		new Float:fNearest = GetBombDistance(iNearest);
		new Float:fFarthest = fNearest;
		new iBomb, Float:fDistance;

		for (new i = 1; i < iSize; i++) {
			iBomb = GetArrayCell(g_hTossedBombList, i);
			fDistance = GetBombDistance(iBomb);

			if (fDistance > fFarthest) {
				fFarthest = fDistance;
				iFarthest = iBomb;
			} else if (fDistance < fNearest) {
				fNearest = fDistance;
				iNearest = iBomb;
			}
		}

		new String:sNearest[64], String:sFarthest[64];
		GetEntPropString(iNearest, Prop_Data, "m_iName", sNearest, sizeof(sNearest));
		GetEntPropString(iFarthest, Prop_Data, "m_iName", sFarthest, sizeof(sFarthest));

		if (ReplaceString(sNearest, sizeof(sNearest), BOMB_TARGETNAME_USED, "") != 1) {
			return;
		}

		if (ReplaceString(sFarthest, sizeof(sFarthest), BOMB_TARGETNAME_USED, "") != 1) {
			return;
		}

		new String:sNearestUser[64], String:sFarthestUser[64];
		new iNearestUser = GetClientOfUserId(StringToInt(sNearest));
		new iFarthestUser = GetClientOfUserId(StringToInt(sFarthest));

		if (iNearestUser != -1) {
			GetClientName(iNearestUser, sNearestUser, sizeof(sNearestUser));
		}

		if (iFarthestUser != -1) {
			GetClientName(iFarthestUser, sFarthestUser, sizeof(sFarthestUser));
		}

		PrintHintText(iClient, "%T", "TargetInfo", iClient, sNearestUser, fNearest, sFarthestUser, fFarthest);

	} else {

		decl String:sClassName[64];
		GetEdictClassname(iEntity, sClassName, sizeof(sClassName));

		if (!StrEqual(sClassName, "weapon_c4")) {
			return;
		}

		decl String:sBombTargetName[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", sBombTargetName, sizeof(sBombTargetName));

		if (ReplaceString(sBombTargetName, sizeof(sBombTargetName), BOMB_TARGETNAME_USED, "") != 1) {
			return;
		}

		new iUser = GetClientOfUserId(StringToInt(sBombTargetName));
		if (iUser != -1) {
			decl String:sUser[64];
			GetClientName(iUser, sUser, sizeof(sUser));

			if (IsTargetSpawned()) {
				new Float:fDistance[3], Float:fBomb[3];
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fBomb);
				MakeVectorFromPoints(g_fTargetPosition, fBomb, fDistance);
				PrintHintText(iClient, "%T", "BombInfoWithTarget", iClient, sUser, GetVectorLength(fDistance));
			} else {
				PrintHintText(iClient, "%T", "BombInfo", iClient, sUser);
			}
		}
	}
}

bool:IsTargetSpawned()
{
	return (g_iTargetEntity != -1);
}

RemoveTarget()
{
	g_fTargetPosition[0] = 0.0;
	g_fTargetPosition[1] = 0.0;
	g_fTargetPosition[2] = 0.0;

	if (IsValidEdict(g_iTargetEntity)) {
		RemoveEdict(g_iTargetEntity);
	}

	g_iTargetEntity = -1;
}

Float:GetBombDistance(iBomb)
{
	new Float:fDistance[3], Float:fBombPosition[3];
	GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", fBombPosition);
	MakeVectorFromPoints(g_fTargetPosition, fBombPosition, fDistance);

	return GetVectorLength(fDistance);
}
