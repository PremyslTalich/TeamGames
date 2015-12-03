#include <sourcemod>
#include <teamgames>

public Plugin:myinfo =
{
	name = "[TG] MoreMarks",
	author = "Raska",
	description = "",
	version = "0.1",
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

new Handle:g_hMark[3];
new Handle:g_hSpawnedMarks;

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public OnPluginEnd()
{
	if (g_hSpawnedMarks == INVALID_HANDLE)
		return;

	new iMarksCount = GetArraySize(g_hSpawnedMarks);
	new iMark;

	for (new i = 0; i < iMarksCount; i++) {
		iMark = GetArrayCell(g_hSpawnedMarks, i);

		if (IsValidEntity(iMark)) {
			AcceptEntityInput(iMark, "LightOff");
			AcceptEntityInput(iMark, "Kill");
		}
	}
}

public OnConfigsExecuted()
{
	if (g_hSpawnedMarks != INVALID_HANDLE) {
		CloseHandle(g_hSpawnedMarks);
	}
	g_hSpawnedMarks = CreateArray();

	for (new iTeam = _:TG_RedTeam; iTeam <= _:TG_BlueTeam; ++iTeam) {
		if (g_hMark[iTeam] != INVALID_HANDLE) {
			CloseHandle(g_hMark[iTeam]);
		}

		g_hMark[iTeam] = CreateArray();
    }

	LoadConfig();
}

public OnMapEnd()
{
	if (g_hSpawnedMarks != INVALID_HANDLE) {
		CloseHandle(g_hSpawnedMarks);
		g_hSpawnedMarks = INVALID_HANDLE;
	}

	for (new iTeam = _:TG_RedTeam; iTeam <= _:TG_BlueTeam; ++iTeam) {
		if (g_hMark[iTeam] != INVALID_HANDLE) {
			CloseHandle(g_hMark[iTeam]);
		}

		g_hMark[iTeam] = INVALID_HANDLE;
    }
}

public Action:Event_RoundStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if (g_hSpawnedMarks != INVALID_HANDLE) {
		ClearArray(g_hSpawnedMarks);
	} else {
		g_hSpawnedMarks = CreateArray();
	}

	return Plugin_Continue;
}

public TG_OnMarkSpawned(iClient, TG_Team:iTeam, Float:fPos[3], Float:fLife)
{
	if (g_hMark[iTeam] != INVALID_HANDLE) {
		new iComponentCount = GetArraySize(g_hMark[iTeam]);
		new Handle:hComponent;
		new MM_Types:iType;

		for (new i = 0; i < iComponentCount; i++) {
			hComponent = Handle:GetArrayCell(g_hMark[iTeam], i);

			if (GetTrieValue(hComponent, "__type__", iType)) {
				switch (iType) {
					case MM_Model, MM_Tesla, MM_SmokeStack, MM_SpotLight, MM_Steam: {
						new iRotor = -1;
						new iEnt = SpawnEntityComponent(iType, hComponent, fPos, iClient, iRotor);

						if (IsValidEntity(iEnt)) {
							PushArrayCell(g_hSpawnedMarks, iEnt);
							CreateTimer(fLife, Timer_RemoveMark, iEnt);
						}

						if (IsValidEntity(iRotor)) {
							PushArrayCell(g_hSpawnedMarks, iRotor);
							CreateTimer(fLife, Timer_RemoveMark, iRotor);
						}
					}
					case MM_Beam: {
						SpawnBeam(hComponent, fPos, fLife);
					}
					case MM_Circle: {
						SpawnCircle(hComponent, fPos, fLife);
					}
					case MM_Sprite: {
						SpawnSprite(hComponent, fPos, fLife);
					}
				}
			}
		}
	}
}

SpawnEntityComponent(MM_Types:iType, Handle:hComponent, Float:fPos[3], iClient, iRotorEntity = -1)
{
	switch (iType) {
		case MM_Model: {
			return SpawnModel(hComponent, fPos, iRotorEntity, iClient);
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
	}

	return -1;
}

public Action:Timer_RemoveMark(Handle:hTimer, any:iEnt)
{
	new i = FindValueInArray(g_hSpawnedMarks, iEnt);

	if (i != -1) {
		if (IsValidEntity(iEnt)) {
			AcceptEntityInput(iEnt, "LightOff");
			AcceptEntityInput(iEnt, "Kill");
		}

		RemoveFromArray(g_hSpawnedMarks, i);
	}
}

LoadConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH], String:sKey[64], String:sValue[64];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/teamgames/moremarks.cfg");

	new Handle:hKV = CreateKeyValues("MoreMarks");

	if (!FileToKeyValues(hKV, sPath))
		return;

	new MM_Types:iType;
	for (new iTeam = _:TG_RedTeam; iTeam <= _:TG_BlueTeam; ++iTeam) {
		if (KvJumpToKey(hKV, (TG_Team:iTeam == TG_RedTeam) ? "red" : "blue" )) {
			if (KvGotoFirstSubKey(hKV, false)) {
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
								case MM_Tesla: {
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
								case MM_Beam, MM_Circle, MM_Sprite: {
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

					PushArrayCell(g_hMark[iTeam], hComponent);
				}
				while (KvGotoNextKey(hKV, false));
			}
		}

		KvRewind(hKV);
	}

	CloseHandle(hKV);
}

SpawnModel(Handle:hComponent, Float:fPos[3], &iRotorEntity, iClient)
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fOrigin[3];

	new iModel = CreateEntityByName("prop_dynamic_override");
	if (iModel == -1) {
		AcceptEntityInput(iModel, "Kill");
		return -1;
	}

	new iRotor = -1;
	new iRotation = GetComponentInt(hComponent, "rotation", 0);

	if (iRotation != 0) {
		if ((iRotor = CreateEntityByName("func_rotating")) == -1) {
			AcceptEntityInput(iModel, "Kill");
			AcceptEntityInput(iRotor, "Kill");
			return -1;
		}
	}

	iRotorEntity = iRotor;

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

SpawnBeam(Handle:hComponent, Float:fPos[3], Float:fLife)
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fStart[3], Float:fEnd[3];
	new iColor[4];
	new iMaterial;
	GetTrieValue(hComponent, "material", iMaterial);

	if (iMaterial == 0) {
		return;
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

	new Float:fWidthStart = GetComponentFloat(hComponent, "width-start", 1.0);
	new Float:fWidthEnd = GetComponentFloat(hComponent, "width-end", 1.0);
	new Float:fAmplitude = GetComponentFloat(hComponent, "amplitude", 0.0);

	TE_SetupBeamPoints(fStart, fEnd, iMaterial, 0, 0, 0, fLife, fWidthStart, fWidthEnd, 0, fAmplitude, iColor, 0);
	TE_SendToAll();
}

SpawnCircle(Handle:hComponent, Float:fPos[3], Float:fLife)
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fOrigin[3];
	new iColor[4];
	new iMaterial;
	GetTrieValue(hComponent, "material", iMaterial);

	if (iMaterial == 0) {
		return;
	}

	GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
	GetVectorFromString(sValue, fOrigin);
	AddVectors(fPos, fOrigin, fOrigin);

	GetComponentString(hComponent, "color", sValue, sizeof(sValue), "255 255 255");
	iColor[3] = GetComponentInt(hComponent, "alpha", 255);
	GetVectorFromString(sValue, iColor, false);

	new Float:fRadius = GetComponentFloat(hComponent, "radius", 32.0) * 2;
	new Float:fAmplitude = GetComponentFloat(hComponent, "amplitude", 0.0);

	TE_SetupBeamRingPoint(fOrigin, fRadius - 0.5, fRadius, iMaterial, 0, 0, 0, fLife, GetComponentFloat(hComponent, "width", 1.0), fAmplitude, iColor, 0, 0);
	TE_SendToAll();
}

SpawnSprite(Handle:hComponent, Float:fPos[3], Float:fLife)
{
	new String:sValue[PLATFORM_MAX_PATH];
	new Float:fOrigin[3];
	new iMaterial;
	GetTrieValue(hComponent, "material", iMaterial);

	if (iMaterial == 0) {
		return;
	}

	GetComponentString(hComponent, "position", sValue, sizeof(sValue), "0 0 0");
	GetVectorFromString(sValue, fOrigin);
	AddVectors(fPos, fOrigin, fOrigin);

	TE_SetupGlowSprite(fOrigin, iMaterial, fLife, GetComponentFloat(hComponent, "size", 1.0), GetComponentInt(hComponent, "brightness", 255));
	TE_SendToAll();
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