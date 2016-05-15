#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>
#include <emitsoundany>
#include <colorvariables>

#define GAME_ID 	"ChickenHunt"
#define WAVE_COUNT 	5

public Plugin:myinfo =
{
	name = "[TG] ChickenHunt",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

new g_teamScore[3];
new g_playerScore[MAXPLAYERS + 1];
new g_waveCount;
new TG_GameType:g_gametype;
new Handle:g_chickens;
new Handle:g_collisionTimer;
new Handle:g_printScoreTimer;
new String:g_chickenSpawnSound[PLATFORM_MAX_PATH];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_CSGO) {
		Format(error, err_max, "Not supported engine version detected! This tg game is only for CS:GO.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("TG.ChickenHunt.phrases");
	CLoadPluginConfig("TeamGames");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames")) {
		TG_RegGame(GAME_ID, TG_TeamGame | TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_OnDownloadFile(String:file[], String:prefixName[], Handle:args, &bool:known)
{
	if (StrEqual(prefixName, "ChickenHunt-SpawnSound")) {
		ReplaceStringEx(file, PLATFORM_MAX_PATH, "sound/", "");
		PrecacheSoundAny(file, true);
		strcopy(g_chickenSpawnSound, sizeof(g_chickenSpawnSound), file);
		known = true;
	}
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], nameSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID)) {
		return;
	}

	Format(name, nameSize, "%T", "GameName", client);
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID)) {
		return;
	}

	g_gametype = gameType;
	TG_StartGame(client, GAME_ID, gameType);
}

public TG_OnGamePrepare(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID)) {
		return;
	}

	if (g_gametype == TG_TeamGame) {
		g_teamScore[TG_RedTeam] = 0;
		g_teamScore[TG_BlueTeam] = 0;
	} else if (g_gametype == TG_RedOnly) {
		for (new i = 1; i <= MaxClients; i++) {
			g_playerScore[i] = 0;
		}
	}

	g_waveCount = WAVE_COUNT;
	SpawnChickenWave();

	if (g_printScoreTimer != INVALID_HANDLE) {
		KillTimer(g_printScoreTimer);
	}

	g_printScoreTimer = CreateTimer(0.1, Timer_PrintScore, _, TIMER_REPEAT);
}

public Action:Timer_PrintScore(Handle:timer)
{
	PrintScore();
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerItem(i, "weapon_knife");
	}
}

public TG_OnTeamEmpty(const String:id[], TG_GameType:gameType, client, TG_Team:team, TG_PlayerTrigger:trigger)
{
	if (!StrEqual(id, GAME_ID))
		return;

	if (g_gametype == TG_TeamGame) {
		TG_StopGame(TG_GetOppositeTeam(team));
	} else if (g_gametype == TG_RedOnly && team == TG_RedTeam) {
		new iWinner = Array_FindHighestValue(g_playerScore, MAXPLAYERS + 1);

		if (g_playerScore[iWinner] > 0) {
			new Handle:hWinner = CreateArray();
			PushArrayCell(hWinner, iWinner);
			TG_StopGame(TG_RedTeam, hWinner);
		} else {
			TG_StopGame(TG_RedTeam);
		}
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	KillChickens();

	if (g_collisionTimer != INVALID_HANDLE) {
		KillTimer(g_collisionTimer);
		g_collisionTimer = INVALID_HANDLE;
	}

	if (g_printScoreTimer != INVALID_HANDLE) {
		KillTimer(g_printScoreTimer);
		g_printScoreTimer = INVALID_HANDLE;
	}

	return;
}

public Action:TG_OnTraceAttack(bool:ingame, victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(victim) && TG_IsPlayerRedOrBlue(attacker)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool:SpawnChickenWave()
{
	KillChickens();

	if (g_waveCount < 1) {
		return false;
	}
	g_waveCount--;

	new Float:clientPos[3];
	g_chickens = CreateArray();

	for (new i = 1; i <= MaxClients; i++) {
		if ((g_gametype == TG_TeamGame && !TG_IsPlayerRedOrBlue(i)) || (g_gametype == TG_RedOnly && TG_GetPlayerTeam(i) != TG_RedTeam)) {
			continue;
		}

		GetClientAbsOrigin(i, clientPos);
		clientPos[2] += 8.0;

		// for (new n = 0; n < 2; n++) {
		for (new n = 0; n < GetRandomInt(1, 2); n++) {
			SpawnChicken(clientPos);
		}

		EventWeaponFire(i);
		SpawnParticles(clientPos);
	}

	if (g_chickenSpawnSound[0] != '\0' && g_waveCount != WAVE_COUNT - 1) {
		EmitSoundToAllAny(g_chickenSpawnSound);
	}

	return true;
}

KillChickens()
{
	if (g_chickens != INVALID_HANDLE) {
		for (new i = 0; i < GetArraySize(g_chickens); i++) {
			new chicken = GetArrayCell(g_chickens, i);

			if (IsValidEntity(chicken)) {
				AcceptEntityInput(chicken, "kill");
			}
		}

		CloseHandle(g_chickens);
	}

	g_chickens = INVALID_HANDLE;
}

public Hook_ChickenDeath(const String: output[], chicken, client, Float: delay)
{
	new chickenIndex = FindValueInArray(g_chickens, chicken);
	if (chickenIndex != -1) {

		if (TG_IsPlayerRedOrBlue(client)) {
			AddScore(client);
		}

		RemoveFromArray(g_chickens, chickenIndex);

		if (GetArraySize(g_chickens) == 0) {

			if (!SpawnChickenWave()) {
				if (g_gametype == TG_TeamGame) {
					TG_StopGame((g_teamScore[TG_RedTeam] == g_teamScore[TG_BlueTeam]) ? TG_NoneTeam : (g_teamScore[TG_RedTeam] > g_teamScore[TG_BlueTeam]) ? TG_RedTeam : TG_BlueTeam);
				} else if (g_gametype == TG_RedOnly) {
					new iWinner = Array_FindHighestValue(g_playerScore, MAXPLAYERS + 1);

					if (g_playerScore[iWinner] > 0) {
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

SpawnChicken(const Float:pos[3])
{
	new chicken = CreateEntityByName("chicken");

	if (chicken != -1) {
		DispatchKeyValue(chicken, "glowenabled", "1");
		DispatchKeyValue(chicken, "glowcolor", "255 255 255");
		DispatchKeyValue(chicken, "rendercolor", "255 255 255");
		DispatchKeyValue(chicken, "modelscale", "1");
		DispatchKeyValue(chicken, "skin", (GetRandomInt(0,1) == 0) ? "0" : "1");
		DispatchSpawn(chicken);

		SetEntProp(chicken, Prop_Send, "m_bShouldGlow", true);
		SetEntProp(chicken, Prop_Send, "m_nGlowStyle", 0);
		SetEntPropFloat(chicken, Prop_Send, "m_flGlowMaxDist", 10000000.0);
		SetEntProp(chicken, Prop_Data, "m_takedamage", 0, 1);

		TeleportEntity(chicken, pos, NULL_VECTOR, NULL_VECTOR);

		if (g_collisionTimer != INVALID_HANDLE) {
			KillTimer(g_collisionTimer);
			g_collisionTimer = INVALID_HANDLE;
		}

		PushArrayCell(g_chickens, chicken);
		HookSingleEntityOutput(chicken, "OnBreak", Hook_ChickenDeath);

		SDKHook(chicken, SDKHook_ShouldCollide, Hook_ChickenCollide);
		g_collisionTimer = CreateTimer(3.0, Timer_SetChickenTakeDamage);
	}

	return chicken;
}

public Action:Timer_SetChickenTakeDamage(Handle:timer)
{
	if (g_chickens != INVALID_HANDLE) {
		for (new i = 0; i < GetArraySize(g_chickens); i++) {
			new chicken = GetArrayCell(g_chickens, i);

			if (IsValidEntity(chicken)) {
				SetEntProp(chicken, Prop_Data, "m_takedamage", 2, 1);
				SetEntProp(chicken, Prop_Send, "m_clrGlow", ((0 & 0xFF) << 16) | ((0 & 0xFF) << 8) | ((255 & 0xFF) << 0));
			} else {
				RemoveFromArray(g_chickens, i);
			}
		}
	}

	g_collisionTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public bool:Hook_ChickenCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	return (contentsmask == 33570827 || contentsmask == 1174421515 || contentsmask == 1107320971 || contentsmask == 1174421507);
}

AddScore(client)
{
	if (g_gametype == TG_TeamGame) {
		g_teamScore[TG_GetPlayerTeam(client)]++;
	} else if (g_gametype == TG_RedOnly) {
		g_playerScore[client]++;
	}

	PrintScore();
}

PrintScore()
{
	if (g_gametype == TG_TeamGame) {
		PrintHintTextToAll("%t", "ScoreBoard-TeamGame", g_waveCount, g_teamScore[TG_RedTeam], g_teamScore[TG_BlueTeam]);
	} else if (g_gametype == TG_RedOnly) {
		new highest[2], lowest[2];
		decl String:highestMsg[64], String:lowestMsg[64];

		for (new i = 1; i <= MaxClients; i++)
		{
			if (TG_GetPlayerTeam(i) != TG_RedTeam)
				continue;

			if (g_playerScore[i] >= highest[1]) {
				highest[0] = i;
				highest[1] = g_playerScore[i];
			}

			if (g_playerScore[i] <= lowest[1]) {
				lowest[0] = i;
				lowest[1] = g_playerScore[i];
			}
		}

		FormatEx(highestMsg, sizeof(highestMsg), "%N", highest[0]);
		FormatEx(lowestMsg, sizeof(lowestMsg), "%N", lowest[0]);

		PrintHintTextToAll("%t", "ScoreBoard-RedOnly", g_waveCount, highestMsg, highest[1], lowestMsg, lowest[1]);
	}
}

EventWeaponFire(client)
{
	new Handle:event = CreateEvent("weapon_fire");
	if (event != INVALID_HANDLE) {
		SetEventInt(event, "userid", GetClientUserId(client));
		SetEventString(event, "weapon", "awp");
		SetEventBool(event, "silenced", false);
		FireEvent(event);
	}
}

SpawnParticles(Float:pos[3])
{
	new particles = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particles)) {
		DispatchKeyValue(particles, "effect_name", "chicken_gone_feathers");
		DispatchKeyValue(particles, "angles", "-90 0 0");
		DispatchSpawn(particles);

		TeleportEntity(particles, pos, NULL_VECTOR, NULL_VECTOR);

		ActivateEntity(particles);
		AcceptEntityInput(particles, "Start");

		CreateTimer(5.0, Timer_KillEntity, particles);
	}
}

public Action:Timer_KillEntity(Handle:timer, any:entity)
{
	AcceptEntityInput(entity, "kill");
}
