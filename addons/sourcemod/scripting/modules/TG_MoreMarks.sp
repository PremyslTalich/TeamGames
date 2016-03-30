#include <sourcemod>
#include <teamgames>

#define CONFIG "configs/teamgames/moremarks.cfg"

public Plugin:myinfo =
{
	name = "[TG] MoreMarks",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

enum MM_Types
{
	MM_Invalid = 0,
	MM_Model,
	MM_Tesla,
	MM_SmokeStack,
	MM_Steam,
	MM_SpotLight,
	MM_Beam,
	MM_Circle,
	MM_Sprite
}

enum MM_LastMark
{
	LM_Client,
	TG_Team:LM_Team,
	Float:LM_Position[3],
	String:LM_Mark[16]
}

new Handle:g_hMarks;
new g_iLastMark[3][MM_LastMark];
new Handle:g_hMarkTemplate[3];
new Handle:g_hMarkLastTemplate[3];
new Handle:g_hTempEntComponents;

public OnPluginStart()
{
	g_hMarks = CreateTrie();
	g_hTempEntComponents = CreateArray();

	CreateDirectoryPath(CONFIG, 511, true);
}

public OnPluginEnd()
{
	if (g_hMarks == INVALID_HANDLE)
		return;

	KillAllComponents();
}

public OnMapStart()
{
	for (new iTeam = _:TG_RedTeam; iTeam <= _:TG_BlueTeam; ++iTeam) {
		if (g_hMarkTemplate[iTeam] != INVALID_HANDLE) {
			CloseHandle(g_hMarkTemplate[iTeam]);
			g_hMarkTemplate[iTeam] = INVALID_HANDLE;
		}

		if (g_hMarkLastTemplate[iTeam] != INVALID_HANDLE) {
			CloseHandle(g_hMarkLastTemplate[iTeam]);
			g_hMarkLastTemplate[iTeam] = INVALID_HANDLE;
		}
    }

	LoadConfig();
}

public TG_OnMarkSpawned(iClient, TG_Team:iTeam, Float:fPos[3], Float:fLife, Handle:hMark, iMarkEnt)
{
	if (g_hMarkTemplate[iTeam] == INVALID_HANDLE) {
		LogError("Missing %s mark definition in %s !", (iTeam == TG_RedTeam) ? "red" : "blue", CONFIG);
		return;
	}

	new Handle:hComponents;
	new String:sMark[16];
	Format(sMark, sizeof(sMark), "%d", _:hMark);

	if (g_hMarkLastTemplate[iTeam] != INVALID_HANDLE) {
		if (g_iLastMark[iTeam][LM_Mark] != '\0') {
			if (GetTrieValue(g_hMarks, g_iLastMark[iTeam][LM_Mark], hComponents)) {
				KillComponents(hComponents);

				new Float:fLastMarkPos[3];
				fLastMarkPos[0] = g_iLastMark[iTeam][LM_Position][0];
				fLastMarkPos[1] = g_iLastMark[iTeam][LM_Position][1];
				fLastMarkPos[2] = g_iLastMark[iTeam][LM_Position][2];

				SpawnComponents(g_hMarkTemplate[iTeam], hComponents, fLastMarkPos, g_iLastMark[iTeam][LM_Client]);
			}

			// Just to be surely sure
			strcopy(g_iLastMark[iTeam][LM_Mark], 16, "");
		}

		g_iLastMark[iTeam][LM_Client] = iClient;
		g_iLastMark[iTeam][LM_Team] = iTeam;
		g_iLastMark[iTeam][LM_Position][0] = fPos[0];
		g_iLastMark[iTeam][LM_Position][1] = fPos[1];
		g_iLastMark[iTeam][LM_Position][2] = fPos[2];
		strcopy(g_iLastMark[iTeam][LM_Mark], 16, sMark);
	}

	hComponents = CreateArray();
	if (g_hMarkLastTemplate[iTeam] != INVALID_HANDLE) {
		SpawnComponents(g_hMarkLastTemplate[iTeam], hComponents, fPos, iClient);
	} else {
		SpawnComponents(g_hMarkTemplate[iTeam], hComponents, fPos, iClient);
	}
	SetTrieValue(g_hMarks, sMark, hComponents);
}

public TG_OnMarkDestroyed(iClient, TG_Team:iTeam, Float:fPos[3], Float:fLife, Handle:hMark, iMarkEnt)
{
	new String:sMark[16];
	new Handle:hComponents;
	Format(sMark, sizeof(sMark), "%d", _:hMark);

	if (GetTrieValue(g_hMarks, sMark, hComponents)) {
		KillComponents(hComponents);
		CloseHandle(hComponents);
		RemoveFromTrie(g_hMarks, sMark);
	}
}

SpawnComponents(Handle:hTemplate, Handle:hComponents, Float:fPos[3], iClient)
{
	if (hTemplate != INVALID_HANDLE) {
		new iComponentsCount = GetArraySize(hTemplate);
		new Handle:hComponent;
		new MM_Types:iType;

		for (new i = 0; i < iComponentsCount; i++) {
			hComponent = Handle:GetArrayCell(hTemplate, i);

			if (GetTrieValue(hComponent, "__type__", iType)) {
				switch (iType) {
					case MM_Model, MM_Tesla, MM_SmokeStack, MM_SpotLight, MM_Steam, MM_Sprite: {
						new iEnt = SpawnEntityComponent(iType, hComponent, fPos, iClient);

						if (IsValidEntity(iEnt)) {
							PushArrayCell(hComponents, iEnt);
						}
					}
					case MM_Beam, MM_Circle: {
						new iTempEnt = SpawnTempEntityComponent(iType, hComponent, fPos);

						if (iTempEnt != 0) {
							PushArrayCell(hComponents, iTempEnt);
							PushArrayCell(g_hTempEntComponents, iTempEnt);
						}
					}
				}
			}
		}
	}
}

SpawnEntityComponent(MM_Types:iType, Handle:hComponent, Float:fPos[3], iClient)
{
	switch (iType) {
		case MM_Model: {
			return SpawnModel(hComponent, fPos, iClient);
		}
		case MM_Tesla: {
			return SpawnTesla(hComponent, fPos);
		}
		case MM_SmokeStack: {
			return SpawnSmokeStack(hComponent, fPos);
		}
		case MM_Steam: {
			return SpawnSteam(hComponent, fPos, iClient);
		}
		case MM_SpotLight: {
			return SpawnSpotLight(hComponent, fPos, iClient);
		}
		case MM_Sprite: {
			return SpawnSprite(hComponent, fPos);
		}
	}

	return -1;
}

SpawnTempEntityComponent(MM_Types:iType, Handle:hComponent, Float:fPos[3])
{
	switch (iType) {
		case MM_Beam: {
			return SpawnBeam(hComponent, fPos);
		}
		case MM_Circle: {
			return SpawnCircle(hComponent, fPos);
		}
	}

	return 0;
}

KillComponent(iComponentEntity)
{
	if (IsValidEntity(iComponentEntity)) {
		new String:sClassName[64];
		GetEntityClassname(iComponentEntity, sClassName, sizeof(sClassName));

		if (StrEqual(sClassName, "prop_dynamic")) {
			new iRotor = GetEntPropEnt(iComponentEntity, Prop_Send, "m_hOwnerEntity");

			if (IsValidEntity(iRotor)) {
				AcceptEntityInput(iRotor, "KillHierarchy");
			}
		} else {
			AcceptEntityInput(iComponentEntity, "LightOff");
			AcceptEntityInput(iComponentEntity, "Kill");
		}
	}
}

KillComponents(Handle:hComponents)
{
	new iCount = GetArraySize(hComponents);
	new iComponent, iTempEnt;

	for (new i = iCount - 1; i >= 0; i--) {
		iComponent = GetArrayCell(hComponents, i);

		KillComponent(iComponent);
		RemoveFromArray(hComponents, i);

		if ((iTempEnt = FindValueInArray(g_hTempEntComponents, iComponent)) != -1) {
			RemoveFromArray(g_hTempEntComponents, iTempEnt);
		}
	}
}

KillAllComponents()
{
	new Handle:hMarks = CreateTrieSnapshot(g_hMarks);
	new iMarksCount = TrieSnapshotLength(hMarks);
	new String:sMark[16];
	new Handle:hComponents;

	for (new i = 0; i < iMarksCount; i++) {
		if (GetTrieSnapshotKey(hMarks, i, sMark, sizeof(sMark)) > 0 && GetTrieValue(g_hMarks, sMark, hComponents)) {
			KillComponents(hComponents);
			CloseHandle(hComponents);
		}
	}

	CloseHandle(hMarks);
}

LoadConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sKey[64], String:sValue[64];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG);

	new Handle:hKV = CreateKeyValues("MoreMarks");

	if (!FileToKeyValues(hKV, sPath)) {
		LogError("Cannot read from file %s !", CONFIG);
		return;
	}

	new MM_Types:iType;
	new String:sMarkKey[48];

	for (new iLast = 0; iLast <= 1; ++iLast) {
		for (new iTeam = _:TG_RedTeam; iTeam <= _:TG_BlueTeam; ++iTeam) {
			Format(sMarkKey, sizeof(sMarkKey), "%s%s", (TG_Team:iTeam == TG_RedTeam) ? "red" : "blue", (iLast == 0) ? "" : "-last");
			if (KvJumpToKey(hKV, sMarkKey)) {
				if (KvGotoFirstSubKey(hKV, false)) {
					if (iLast == 0) {
						g_hMarkTemplate[iTeam] = CreateArray();
					} else {
						g_hMarkLastTemplate[iTeam] = CreateArray();
					}

					do {
						new Handle:hComponent = CreateTrie();

						KvGetSectionName(hKV, sKey, sizeof(sKey));
						iType = GetMarkTypeFromName(sKey);

						SetTrieValue(hComponent, "__type__", _:iType);

						if (KvGotoFirstSubKey(hKV, false)) {
							do {
								KvGetSectionName(hKV, sKey, sizeof(sKey));
								KvGetString(hKV, NULL_STRING, sValue,  sizeof(sValue));
								StringToLower(sKey);

								switch (iType) {
									case MM_Model: {
										if (StrEqual(sKey, "model", false)) {
											PrecacheModel(sValue, true);
										}
									}
									case MM_Tesla, MM_Sprite: {
										if (StrEqual(sKey, "material", false)) {
											PrecacheDecal(sValue, true);
										}
									}
									case MM_SmokeStack: {
										if (StrEqual(sKey, "material", false)) {
											ReplaceStringEx(sValue, sizeof(sValue), "materials/", "");
											PrecacheDecal(sValue, true);
										}
									}
									case MM_Beam, MM_Circle: {
										if (StrEqual(sKey, "material", false)) {
											SetTrieValue(hComponent, sKey, PrecacheModel(sValue, true));
											continue;
										}
									}
								}

								SetTrieString(hComponent, sKey, sValue);
							}
							while (KvGotoNextKey(hKV, false));

							KvGoBack(hKV);
						}

						if (iLast == 0) {
							PushArrayCell(g_hMarkTemplate[iTeam], hComponent);
						} else {
							PushArrayCell(g_hMarkLastTemplate[iTeam], hComponent);
						}
					}
					while (KvGotoNextKey(hKV, false));
				}
			}

			KvRewind(hKV);
		}
	}

	CloseHandle(hKV);
}

SpawnModel(Handle:hComponent, Float:fPos[3], iClient)
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fOrigin[3];

	new iModel = CreateEntityByName("prop_dynamic_override");
	if (iModel == -1) {
		return -1;
	}

	new iRotor = -1;
	new iRotation = GetComponentInt(hComponent, "rotation", 0);

	if (iRotation != 0) {
		if ((iRotor = CreateEntityByName("func_rotating")) == -1) {
			RemoveEdict(iModel);
			return -1;
		}
	}

	GetComponentString(hComponent, "angles", sValue, sizeof(sValue), "0 0 0");

	new Float:fAngles[3];
	GetVectorFromString(sValue, fAngles);

	if (ExistComponentKey(hComponent, "playerangle")) {
		new Float:fPlayerAngles[3];
		GetClientAbsAngles(iClient, fPlayerAngles);
		AddVectors(fAngles, fPlayerAngles, fAngles);
	}

	DispatchKeyValueVector(iModel, "angles", fAngles);

	GetComponentString(hComponent, "model", sValue, sizeof(sValue), "");
	DispatchKeyValue(iModel, "model", sValue);
	DispatchKeyValueNum(iModel, "skin", GetComponentInt(hComponent, "skin", 0));

	GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
	DispatchKeyValue(iModel, "rendercolor", sValue);
	DispatchKeyValueNum(iModel, "renderamt", GetComponentInt(hComponent, "alpha", 255));

	DispatchKeyValue(iModel, "rendermode", "1");
	DispatchKeyValue(iModel, "renderfx", "0");
	DispatchKeyValue(iModel, "spawnflags", "4");

	GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
	GetVectorFromString(sValue, fOrigin);
	AddVectors(fPos, fOrigin, fOrigin);
	DispatchKeyValueVector(iModel, "origin", fOrigin);

	if (iRotation != 0) {
		DispatchKeyValueVector(iRotor, "origin", fOrigin);
		DispatchKeyValue(iRotor, "friction", "0");
		DispatchKeyValue(iRotor, "dmg", "0");
		DispatchKeyValue(iRotor, "solid", "0");
		DispatchKeyValue(iRotor, "spawnflags", (iRotation > 0) ? "64" : "66");
		DispatchKeyValueNum(iRotor, "maxspeed", (iRotation > 0) ? iRotation : -1 * iRotation);

		DispatchSpawn(iRotor);
		TeleportEntity(iRotor, fOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iRotor, "Start");
	}

	DispatchSpawn(iModel);
	TeleportEntity(iModel, fOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(iModel, MOVETYPE_NONE);

	if (iRotation != 0) {
		SetVariantString("!activator");
		AcceptEntityInput(iModel, "SetParent", iRotor, iRotor);
		SetEntPropEnt(iModel, Prop_Send, "m_hEffectEntity", iRotor);
		SetEntPropEnt(iModel, Prop_Send, "m_hOwnerEntity", iRotor);
	}

	return iModel;
}

SpawnTesla(Handle:hComponent, Float:fPos[3])
{
	new iEnt = CreateEntityByName("point_tesla");

	if (iEnt != -1) {
		new String:sValue[PLATFORM_MAX_PATH], Float:fOrigin[3];

		GetComponentString(hComponent, "material", sValue, sizeof(sValue), "materials/sprites/physbeam.vmt");
		DispatchKeyValue(iEnt, "texture", sValue);

		GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
		DispatchKeyValue(iEnt, "m_Color", sValue);

		GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
		GetVectorFromString(sValue, fOrigin);
		AddVectors(fPos, fOrigin, fOrigin);
		DispatchKeyValueVector(iEnt, "origin", fOrigin);

		DispatchKeyValueFloat(iEnt, "m_flRadius", GetComponentFloat(hComponent, "radius", 48.0));
		DispatchKeyValueNum(iEnt, "beamcount_min", GetComponentInt(hComponent, "beamcount-min", 6));
		DispatchKeyValueNum(iEnt, "beamcount_min", GetComponentInt(hComponent, "beamcount-max", 8));
		DispatchKeyValueFloat(iEnt, "thick_min", GetComponentFloat(hComponent, "thickness-min", 2.0));
		DispatchKeyValueFloat(iEnt, "thick_max", GetComponentFloat(hComponent, "thickness-max", 6.0));
		DispatchKeyValueFloat(iEnt, "lifetime_min", GetComponentFloat(hComponent, "lifetime-min", 0.2));
		DispatchKeyValueFloat(iEnt, "lifetime_max", GetComponentFloat(hComponent, "lifetime-max", 0.4));
		DispatchKeyValueFloat(iEnt, "interval_min", GetComponentFloat(hComponent, "interval-min", 0.1));
		DispatchKeyValueFloat(iEnt, "interval_max", GetComponentFloat(hComponent, "interval-max", 0.2));
		DispatchSpawn(iEnt);
		TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);

		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		AcceptEntityInput(iEnt, "DoSpark");
	}

	return iEnt;
}

SpawnSmokeStack(Handle:hComponent, Float:fPos[3])
{
	new iEnt = CreateEntityByName("env_smokestack");

	if (iEnt != -1) {
		new String:sValue[PLATFORM_MAX_PATH], Float:fOrigin[3];

		GetComponentString(hComponent, "material", sValue, sizeof(sValue), "materials/effects/redflare.vmt");
		DispatchKeyValue(iEnt, "SmokeMaterial", sValue);

		GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
		DispatchKeyValue(iEnt, "rendercolor", sValue);

		GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
		GetVectorFromString(sValue, fOrigin);
		AddVectors(fPos, fOrigin, fOrigin);
		DispatchKeyValueVector(iEnt, "origin", fOrigin);

		DispatchKeyValueNum(iEnt, "BaseSpread", GetComponentInt(hComponent, "radius", 48));
		DispatchKeyValueNum(iEnt, "SpreadSpeed", GetComponentInt(hComponent, "spreadspeed", 0));
		DispatchKeyValueNum(iEnt, "Speed", GetComponentInt(hComponent, "speed", 30));
		DispatchKeyValueNum(iEnt, "StartSize", GetComponentInt(hComponent, "size-start", 8));
		DispatchKeyValueNum(iEnt, "EndSize", GetComponentInt(hComponent, "size-end", 8));
		DispatchKeyValueNum(iEnt, "Rate", GetComponentInt(hComponent, "emmisionrate", 24));
		DispatchKeyValueNum(iEnt, "JetLength", GetComponentInt(hComponent, "length", 32));
		DispatchKeyValueNum(iEnt, "twist", GetComponentInt(hComponent, "twist", 0));
		DispatchKeyValueNum(iEnt, "renderamt", GetComponentInt(hComponent, "alpha", 255));
		DispatchSpawn(iEnt);

		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	return iEnt;
}

SpawnSteam(Handle:hComponent, Float:fPos[3], iClient)
{
	new iEnt = CreateEntityByName("env_steam");

	if (iEnt != -1) {
		new String:sValue[PLATFORM_MAX_PATH];

		GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
		DispatchKeyValue(iEnt, "rendercolor", sValue);

		new bool:bPlayerAngle = ExistComponentKey(hComponent, "playerangle");
		GetComponentString(hComponent, "angles", sValue, sizeof(sValue), bPlayerAngle ? "180 0 0" : "-90 0 0");

		new Float:fAngles[3], Float:fOrigin[3];
		GetVectorFromString(sValue, fAngles);

		if (bPlayerAngle) {
			new Float:fPlayerAngles[3];
			GetClientAbsAngles(iClient, fPlayerAngles);
			AddVectors(fAngles, fPlayerAngles, fAngles);
		}

		DispatchKeyValueVector(iEnt, "angles", fAngles);

		GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
		GetVectorFromString(sValue, fOrigin);
		AddVectors(fPos, fOrigin, fOrigin);
		DispatchKeyValueVector(iEnt, "origin", fOrigin);

		DispatchKeyValueNum(iEnt, "StartSize", GetComponentInt(hComponent, "width-start", 4));
		DispatchKeyValueNum(iEnt, "EndSize", GetComponentInt(hComponent, "width-end", 16));
		DispatchKeyValueNum(iEnt, "Speed", GetComponentInt(hComponent, "speed", 32));
		DispatchKeyValueNum(iEnt, "JetLength", GetComponentInt(hComponent, "length", 48));
		DispatchKeyValueNum(iEnt, "renderamt", GetComponentInt(hComponent, "alpha", 255));
		DispatchKeyValue(iEnt, "SpreadSpeed", "8");
		DispatchKeyValue(iEnt, "rollspeed", "4");
		DispatchKeyValue(iEnt, "Rate", "16");
		DispatchKeyValue(iEnt, "InitialState", "1");
		DispatchSpawn(iEnt);

		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	return iEnt;
}

SpawnSpotLight(Handle:hComponent, Float:fPos[3], iClient)
{
	new iEnt = CreateEntityByName("point_spotlight");

	if (iEnt != -1) {
		new String:sValue[PLATFORM_MAX_PATH];
		new Float:fOrigin[3];

		GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
		DispatchKeyValue(iEnt, "rendercolor", sValue);

		new bool:bPlayerAngle = ExistComponentKey(hComponent, "playerangle");
		GetComponentString(hComponent, "angles", sValue, sizeof(sValue), bPlayerAngle ? "180 0 0" : "-90 0 0");

		new Float:fAngles[3];
		GetVectorFromString(sValue, fAngles);

		if (bPlayerAngle) {
			new Float:fPlayerAngles[3];
			GetClientAbsAngles(iClient, fPlayerAngles);
			AddVectors(fAngles, fPlayerAngles, fAngles);
		}

		DispatchKeyValueVector(iEnt, "angles", fAngles);

		GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
		GetVectorFromString(sValue, fOrigin);
		AddVectors(fPos, fOrigin, fOrigin);
		DispatchKeyValueVector(iEnt, "origin", fOrigin);

		DispatchKeyValueNum(iEnt, "spotlightwidth", GetComponentInt(hComponent, "width", 8));
		DispatchKeyValueNum(iEnt, "spotlightlength", GetComponentInt(hComponent, "length", 32));
		DispatchKeyValueNum(iEnt, "renderamt", GetComponentInt(hComponent, "alpha", 255));
		DispatchKeyValue(iEnt, "spawnflags", "3");
		DispatchSpawn(iEnt);

		ActivateEntity(iEnt);
		AcceptEntityInput(iEnt, "LightOn");
		TeleportEntity(iEnt, fOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	return iEnt;
}

SpawnBeam(Handle:hComponent, Float:fPos[3])
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fStart[3], Float:fEnd[3];
	new iColor[4];
	new iMaterial;
	GetTrieValue(hComponent, "material", iMaterial);

	if (iMaterial == 0) {
		return 0;
	}

	GetComponentString(hComponent, "start", sValue, sizeof(sValue), "0 0 0");
	GetVectorFromString(sValue, fStart);
	AddVectors(fPos, fStart, fStart);

	GetComponentString(hComponent, "end", sValue, sizeof(sValue), "0 0 48");
	GetVectorFromString(sValue, fEnd);
	AddVectors(fPos, fEnd, fEnd);

	GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
	iColor[3] = GetComponentInt(hComponent, "alpha", 255);
	GetVectorFromString(sValue, iColor, false);

	new Handle:hDataPack;
	new iBeam = -1 * _:CreateDataTimer(0.1, Timer_DrawBeam, hDataPack, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
	WritePackFloat(hDataPack, fStart[0]);
	WritePackFloat(hDataPack, fStart[1]);
	WritePackFloat(hDataPack, fStart[2]);
	WritePackFloat(hDataPack, fEnd[0]);
	WritePackFloat(hDataPack, fEnd[1]);
	WritePackFloat(hDataPack, fEnd[2]);
	WritePackCell(hDataPack, iColor[0]);
	WritePackCell(hDataPack, iColor[1]);
	WritePackCell(hDataPack, iColor[2]);
	WritePackCell(hDataPack, iColor[3]);
	WritePackFloat(hDataPack, GetComponentFloat(hComponent, "width-start", 1.0));
	WritePackFloat(hDataPack, GetComponentFloat(hComponent, "width-end", 1.0));
	WritePackCell(hDataPack, iMaterial);
	WritePackFloat(hDataPack, GetComponentFloat(hComponent, "amplitude", 0.0));

	return iBeam;
}

public Action:Timer_DrawBeam(Handle:hTimer, Handle:hDataPack)
{
	if (FindValueInArray(g_hTempEntComponents, -1 * _:hTimer) == -1) {
		return Plugin_Stop;
	}

	new Float:fStart[3], Float:fEnd[3], Float:fWidthStart, Float:fWidthEnd, Float:fAmplitude;
	new iColor[4], iMaterial;

	ResetPack(hDataPack);
	fStart[0] = ReadPackFloat(hDataPack);
	fStart[1] = ReadPackFloat(hDataPack);
	fStart[2] = ReadPackFloat(hDataPack);

	fEnd[0] = ReadPackFloat(hDataPack);
	fEnd[1] = ReadPackFloat(hDataPack);
	fEnd[2] = ReadPackFloat(hDataPack);

	iColor[0] = ReadPackCell(hDataPack);
	iColor[1] = ReadPackCell(hDataPack);
	iColor[2] = ReadPackCell(hDataPack);
	iColor[3] = ReadPackCell(hDataPack);

	fWidthStart = ReadPackFloat(hDataPack);
	fWidthEnd = ReadPackFloat(hDataPack);
	iMaterial = ReadPackCell(hDataPack);
	fAmplitude = ReadPackFloat(hDataPack);

	TE_SetupBeamPoints(fStart, fEnd, iMaterial, 0, 0, 0, 0.19, fWidthStart, fWidthEnd, 0, fAmplitude, iColor, 0);
	TE_SendToAll();

	return Plugin_Continue;
}

SpawnCircle(Handle:hComponent, Float:fPos[3])
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fOrigin[3];
	new iColor[4];
	new iMaterial;
	GetTrieValue(hComponent, "material", iMaterial);

	if (iMaterial == 0) {
		return 0;
	}

	GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
	GetVectorFromString(sValue, fOrigin);
	AddVectors(fPos, fOrigin, fOrigin);

	GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
	iColor[3] = GetComponentInt(hComponent, "alpha", 255);
	GetVectorFromString(sValue, iColor, false);

	new Handle:hDataPack;
	new iCircle = -1 * _:CreateDataTimer(0.1, Timer_DrawCircle, hDataPack, TIMER_REPEAT | TIMER_DATA_HNDL_CLOSE);
	WritePackFloat(hDataPack, fOrigin[0]);
	WritePackFloat(hDataPack, fOrigin[1]);
	WritePackFloat(hDataPack, fOrigin[2]);
	WritePackCell(hDataPack, iColor[0]);
	WritePackCell(hDataPack, iColor[1]);
	WritePackCell(hDataPack, iColor[2]);
	WritePackCell(hDataPack, iColor[3]);
	WritePackFloat(hDataPack, (GetComponentFloat(hComponent, "radius", 32.0) * 2));
	WritePackCell(hDataPack, iMaterial);
	WritePackFloat(hDataPack, GetComponentFloat(hComponent, "width", 1.0));
	WritePackFloat(hDataPack, GetComponentFloat(hComponent, "amplitude", 0.0));

	return iCircle;
}

public Action:Timer_DrawCircle(Handle:hTimer, Handle:hDataPack)
{
	if (FindValueInArray(g_hTempEntComponents, -1 * _:hTimer) == -1) {
		return Plugin_Stop;
	}

	new Float:fOrigin[3], Float:fRadius, Float:fWidth, Float:fAmplitude;
	new iColor[4], iMaterial;

	ResetPack(hDataPack);
	fOrigin[0] = ReadPackFloat(hDataPack);
	fOrigin[1] = ReadPackFloat(hDataPack);
	fOrigin[2] = ReadPackFloat(hDataPack);

	iColor[0] = ReadPackCell(hDataPack);
	iColor[1] = ReadPackCell(hDataPack);
	iColor[2] = ReadPackCell(hDataPack);
	iColor[3] = ReadPackCell(hDataPack);

	fRadius = ReadPackFloat(hDataPack);
	iMaterial = ReadPackCell(hDataPack);
	fWidth = ReadPackFloat(hDataPack);
	fAmplitude = ReadPackFloat(hDataPack);

	TE_SetupBeamRingPoint(fOrigin, fRadius - 0.5, fRadius, iMaterial, 0, 0, 0, 0.19, fWidth, fAmplitude, iColor, 0, 0);
	TE_SendToAll();

	return Plugin_Continue;
}

SpawnSprite(Handle:hComponent, Float:fPos[3])
{
	new iSprite = CreateEntityByName("env_sprite");

	if (iSprite != -1) {
		new String:sValue[PLATFORM_MAX_PATH];
		new Float:fOrigin[3];

		GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
		GetVectorFromString(sValue, fOrigin);
		AddVectors(fPos, fOrigin, fOrigin);

		GetComponentString(hComponent, "material", sValue, sizeof(sValue), "");
		DispatchKeyValue(iSprite, "model", sValue);
		DispatchKeyValueFloat(iSprite, "scale", GetComponentFloat(hComponent, "size", 1.0));

		DispatchKeyValue(iSprite, "rendermode", "5");
		DispatchKeyValue(iSprite, "spawnflags", "1");

		GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
		DispatchKeyValue(iSprite, "rendercolor", sValue);
		DispatchKeyValueNum(iSprite, "RenderAmt", GetComponentInt(hComponent, "alpha", 255));

		DispatchSpawn(iSprite);
		TeleportEntity(iSprite, fOrigin, NULL_VECTOR, NULL_VECTOR);
	}

	return iSprite;
}

GetComponentInt(Handle:hComponent, const String:sKey[], iDefaultValue)
{
	new String:sValue[18];

	if (GetTrieString(hComponent, sKey, sValue, sizeof(sValue))) {
		return StringToInt(sValue);
	} else {
		return iDefaultValue;
	}
}

Float:GetComponentFloat(Handle:hComponent, const String:sKey[], Float:fDefaultValue)
{
	new String:sValue[18];

	if (GetTrieString(hComponent, sKey, sValue, sizeof(sValue))) {
		return StringToFloat(sValue);
	} else {
		return fDefaultValue;
	}
}

GetComponentString(Handle:hComponent, const String:sKey[], String:sValue[], iValueSize, const String:sDefaultValue[])
{
	strcopy(sValue, iValueSize, sDefaultValue);
	GetTrieString(hComponent, sKey, sValue, iValueSize);
}

bool:ExistComponentKey(Handle:hComponent, const String:sKey[])
{
	new iValue, String:sValue[4];
	return (GetTrieValue(hComponent, sKey, iValue) || GetTrieString(hComponent, sKey, sValue, sizeof(sValue)));
}

GetVectorFromString(const String:sVector[], any:aVector[], bool:bIsFloat = true)
{
	new iArgPos, String:sArg[18];
	for (new i = 0; i < 3; i++) {
		strcopy(sArg, sizeof(sArg), "0");
		iArgPos += BreakString(sVector[iArgPos], sArg, sizeof(sArg));

		if (bIsFloat) {
			aVector[i] = StringToFloat(sArg);
		} else {
			aVector[i] = StringToInt(sArg);
		}
	}
}

MM_Types:GetMarkTypeFromName(const String:sMarkName[])
{
	if (StrContains(sMarkName, "model", false) == 0) {
		return MM_Model;
	} else if (StrContains(sMarkName, "tesla", false) == 0) {
		return MM_Tesla;
	} else if (StrContains(sMarkName, "smokestack", false) == 0) {
		return MM_SmokeStack;
	} else if (StrContains(sMarkName, "steam", false) == 0) {
		return MM_Steam;
	} else if (StrContains(sMarkName, "spotlight", false) == 0) {
		return MM_SpotLight;
	} else if (StrContains(sMarkName, "beam", false) == 0) {
		return MM_Beam;
	} else if (StrContains(sMarkName, "circle", false) == 0) {
		return MM_Circle;
	} else if (StrContains(sMarkName, "sprite", false) == 0) {
		return MM_Sprite;
	} else {
		return MM_Invalid;
	}
}

StringToLower(String:str[])
{
	new iLen = strlen(str);
	for (new i = 0; i < iLen; i++) {
		str[i] = CharToLower(str[i]);
	}
}