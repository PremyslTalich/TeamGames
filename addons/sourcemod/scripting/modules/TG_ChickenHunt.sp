#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>
#include <emitsoundany>
#include <colorvariables>

#define GAME_ID_FIFTYFIFTY 	"ChickenHunt-FiftyFifty"
#define GAME_ID_REDONLY 	"ChickenHunt-RedOnly"
#define WAVE_COUNT 			5

public Plugin:myinfo =
{
	name = "[TG] ChickenHunt",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

new g_iTeamScore[3];
new g_iPlayerScore[MAXPLAYERS + 1];
new g_iWaveCount;
new bool:g_bFiftyFifty;
new Handle:g_hChickens;
new Handle:g_hCollisionTimer;
new Handle:g_hPrintScoreTimer;
new String:g_sChickenSpawnSound[PLATFORM_MAX_PATH];

public APLRes:AskPluginLoad2(Handle:hMySelf, bool:bLate, String:sError[], iErrMax)
{
	if (GetEngineVersion() != Engine_CSGO) {
		Format(sError, iErrMax, "Not supported engine version detected! This tg game is only for CS:GO.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("TG.ChickenHunt.phrases");
	CLoadPluginConfig("TeamGames");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_ID_FIFTYFIFTY);
		TG_RegGame(GAME_ID_REDONLY, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID_FIFTYFIFTY);
	TG_RemoveGame(GAME_ID_REDONLY);
}

public TG_OnDownloadFile(String:sFile[], String:sPrefixName[], Handle:hArgs, &bool:known)
{
	if (StrEqual(sPrefixName, "ChickenHunt-SpawnSound")) {
		ReplaceStringEx(sFile, PLATFORM_MAX_PATH, "sound/", "");
		PrecacheSoundAny(sFile, true);
		strcopy(g_sChickenSpawnSound, sizeof(g_sChickenSpawnSound), sFile);
		known = true;
	}
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_FIFTYFIFTY)) {
		Format(name, maxSize, "%T", "GameName-FiftyFifty", client);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], iClient)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(sID, GAME_ID_FIFTYFIFTY)) {
		TG_StartGame(iClient, GAME_ID_FIFTYFIFTY, _, _, _, _, false);
	} else if (StrEqual(sID, GAME_ID_REDONLY)) {
		TG_StartGame(iClient, GAME_ID_REDONLY, _, _, _, _, false);
	}
}

public TG_OnGamePrepare(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (StrEqual(id, GAME_ID_FIFTYFIFTY)) {
		g_bFiftyFifty = true;
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		g_bFiftyFifty = false;
	} else {
		return;
	}

	if (g_bFiftyFifty) {
		g_iTeamScore[TG_RedTeam] = 0;
		g_iTeamScore[TG_BlueTeam] = 0;
	} else {
		for (new i = 1; i <= MaxClients; i++) {
			g_iPlayerScore[i] = 0;
		}
	}

	g_iWaveCount = WAVE_COUNT;
	SpawnChickenWave();

	if (g_hPrintScoreTimer != INVALID_HANDLE) {
		KillTimer(g_hPrintScoreTimer);
	}

	g_hPrintScoreTimer = CreateTimer(0.1, Timer_PrintScore, _, TIMER_REPEAT);
}

public Action:Timer_PrintScore(Handle:hTimer)
{
	PrintScore();
}

public TG_OnGameStart(const String:sID[], iClient, const String:GameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID_FIFTYFIFTY) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerItem(i, "weapon_knife");
	}
}

public TG_OnTeamEmpty(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (StrEqual(sID, GAME_ID_FIFTYFIFTY)) {
		TG_StopGame(TG_GetOppositeTeam(iTeam));
	} else if (StrEqual(sID, GAME_ID_REDONLY) && iTeam == TG_RedTeam) {
		new iWinner = Array_FindHighestValue(g_iPlayerScore, MAXPLAYERS + 1);

		if (g_iPlayerScore[iWinner] > 0) {
			new Handle:hWinner = CreateArray();
			PushArrayCell(hWinner, iWinner);
			TG_StopGame(TG_RedTeam, hWinner);
		} else {
			TG_StopGame(TG_RedTeam);
		}
	}
}

public TG_OnGameEnd(const String:sID[], TG_Team:iTeam, winners[], winnersCount)
{
	if (!StrEqual(sID, GAME_ID_FIFTYFIFTY) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	KillChickens();

	if (g_hCollisionTimer != INVALID_HANDLE) {
		KillTimer(g_hCollisionTimer);
		g_hCollisionTimer = INVALID_HANDLE;
	}

	if (g_hPrintScoreTimer != INVALID_HANDLE) {
		KillTimer(g_hPrintScoreTimer);
		g_hPrintScoreTimer = INVALID_HANDLE;
	}

	return;
}

public Action:TG_OnTraceAttack(bool:ingame, victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!TG_IsCurrentGameID(GAME_ID_FIFTYFIFTY) && !TG_IsCurrentGameID(GAME_ID_REDONLY))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(victim) && TG_IsPlayerRedOrBlue(attacker)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool:SpawnChickenWave()
{
	KillChickens();

	if (g_iWaveCount < 1) {
		return false;
	}
	g_iWaveCount--;

	new Float:fClientPos[3];
	g_hChickens = CreateArray();

	for (new i = 1; i <= MaxClients; i++) {
		if ((g_bFiftyFifty && !TG_IsPlayerRedOrBlue(i)) || (!g_bFiftyFifty && TG_GetPlayerTeam(i) != TG_RedTeam)) {
			continue;
		}

		GetClientAbsOrigin(i, fClientPos);
		fClientPos[2] += 8.0;

		// for (new n = 0; n < 2; n++) {
		for (new n = 0; n < GetRandomInt(1, 2); n++) {
			SpawnChicken(fClientPos);
		}

		EventWeaponFire(i);
		SpawnParticles(fClientPos);
	}

	if (g_sChickenSpawnSound[0] != '\0' && g_iWaveCount != WAVE_COUNT - 1) {
		EmitSoundToAllAny(g_sChickenSpawnSound);
	}

	return true;
}

KillChickens()
{
	if (g_hChickens != INVALID_HANDLE) {
		new iChicken;

		for (new i = 0; i < GetArraySize(g_hChickens); i++) {
			iChicken = GetArrayCell(g_hChickens, i);

			if (IsValidEntity(iChicken)) {
				AcceptEntityInput(iChicken, "kill");
			}
		}

		CloseHandle(g_hChickens);
	}

	g_hChickens = INVALID_HANDLE;
}

public Hook_ChickenDeath(const String: sOutput[], iChicken, iClient, Float: fDelay)
{
	new iChickenIndex = FindValueInArray(g_hChickens, iChicken);
	if (iChickenIndex != -1) {

		if (TG_IsPlayerRedOrBlue(iClient)) {
			AddScore(iClient);
		}

		RemoveFromArray(g_hChickens, iChickenIndex);

		if (GetArraySize(g_hChickens) == 0) {

			if (!SpawnChickenWave()) {
				if (g_bFiftyFifty) {
					TG_StopGame((g_iTeamScore[TG_RedTeam] == g_iTeamScore[TG_BlueTeam]) ? TG_NoneTeam : (g_iTeamScore[TG_RedTeam] > g_iTeamScore[TG_BlueTeam]) ? TG_RedTeam : TG_BlueTeam);
				} else {
					new iWinner = Array_FindHighestValue(g_iPlayerScore, MAXPLAYERS + 1);

					if (g_iPlayerScore[iWinner] > 0) {
						new Handle:hWinner = CreateArray();
						PushArrayCell(hWinner, iWinner);
						TG_StopGame(TG_RedTeam, hWinner);
					} else {
						TG_StopGame(TG_RedTeam);
					}
				}
			}
		}
	}
}

SpawnChicken(const Float:fPos[3])
{
	new iChicken = CreateEntityByName("chicken");

	if (iChicken != -1) {
		DispatchKeyValue(iChicken, "glowenabled", "1");
		DispatchKeyValue(iChicken, "glowcolor", "255 255 255");
		DispatchKeyValue(iChicken, "rendercolor", "255 255 255");
		DispatchKeyValue(iChicken, "modelscale", "1");
		DispatchKeyValue(iChicken, "skin", (GetRandomInt(0,1) == 0) ? "0" : "1");
		DispatchSpawn(iChicken);

		SetEntProp(iChicken, Prop_Data, "m_takedamage", 0, 1);

		TeleportEntity(iChicken, fPos, NULL_VECTOR, NULL_VECTOR);

		if (g_hCollisionTimer != INVALID_HANDLE) {
			KillTimer(g_hCollisionTimer);
			g_hCollisionTimer = INVALID_HANDLE;
		}

		PushArrayCell(g_hChickens, iChicken);
		HookSingleEntityOutput(iChicken, "OnBreak", Hook_ChickenDeath);

		SDKHook(iChicken, SDKHook_ShouldCollide, Hook_ChickenCollide);
		g_hCollisionTimer = CreateTimer(3.0, Timer_SetChickenTakeDamage);
	}

	return iChicken;
}

public Action:Timer_SetChickenTakeDamage(Handle:hTimer)
{
	if (g_hChickens != INVALID_HANDLE) {
		new iChicken;

		for (new i = 0; i < GetArraySize(g_hChickens); i++) {
			iChicken = GetArrayCell(g_hChickens, i);

			if (IsValidEntity(iChicken)) {
				SetEntProp(iChicken, Prop_Data, "m_takedamage", 2, 1);
				SetEntProp(iChicken, Prop_Send, "m_clrGlow", ((0 & 0xFF) << 16) | ((0 & 0xFF) << 8) | ((255 & 0xFF) << 0));
			} else {
				RemoveFromArray(g_hChickens, i);
			}
		}
	}

	g_hCollisionTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public bool:Hook_ChickenCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	return (contentsmask == 33570827 || contentsmask == 1174421515 || contentsmask == 1107320971 || contentsmask == 1174421507);
}

AddScore(iClient)
{
	if (g_bFiftyFifty) {
		g_iTeamScore[TG_GetPlayerTeam(iClient)]++;
	} else {
		g_iPlayerScore[iClient]++;
	}

	PrintScore();
}

PrintScore()
{
	if (g_bFiftyFifty) {
		PrintHintTextToAll("%t", "ScoreBoard-FiftyFifty", g_iWaveCount, g_iTeamScore[TG_RedTeam], g_iTeamScore[TG_BlueTeam]);
	} else {
		new iHighest[2], iLowest[2];
		decl String:sHighest[64], String:sLowest[64];

		for (new i = 1; i <= MaxClients; i++)
		{
			if (TG_GetPlayerTeam(i) != TG_RedTeam)
				continue;

			if (g_iPlayerScore[i] >= iHighest[1]) {
				iHighest[0] = i;
				iHighest[1] = g_iPlayerScore[i];
			}

			if (g_iPlayerScore[i] <= iLowest[1]) {
				iLowest[0] = i;
				iLowest[1] = g_iPlayerScore[i];
			}
		}

		FormatEx(sHighest, sizeof(sHighest), "%N", iHighest[0]);
		FormatEx(sLowest, sizeof(sLowest), "%N", iLowest[0]);

		PrintHintTextToAll("%t", "ScoreBoard-RedOnly", g_iWaveCount, sHighest, iHighest[1], sLowest, iLowest[1]);
	}
}

EventWeaponFire(iClient)
{
	new Handle:hEvent = CreateEvent("weapon_fire");
	if (hEvent != INVALID_HANDLE) {
		SetEventInt(hEvent, "userid", GetClientUserId(iClient));
		SetEventString(hEvent, "weapon", "awp");
		SetEventBool(hEvent, "silenced", false);
		FireEvent(hEvent);
	}
}

SpawnParticles(Float:fPos[3])
{
	new iParticles = CreateEntityByName("info_particle_system");
	if (IsValidEntity(iParticles)) {
		DispatchKeyValue(iParticles, "effect_name", "chicken_gone_feathers");
		DispatchKeyValue(iParticles, "angles", "-90 0 0");
		DispatchSpawn(iParticles);

		TeleportEntity(iParticles, fPos, NULL_VECTOR, NULL_VECTOR);

		ActivateEntity(iParticles);
		AcceptEntityInput(iParticles, "Start");

		CreateTimer(5.0, Timer_KillEntity, iParticles);
	}
}

public Action:Timer_KillEntity(Handle:hTimer, any:iEntity)
{
	AcceptEntityInput(iEntity, "kill");
}
