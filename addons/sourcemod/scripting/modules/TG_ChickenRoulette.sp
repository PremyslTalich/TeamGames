#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>
#include <emitsoundany>

#define GAME_ID "ChickenRoulette"

public Plugin:myinfo =
{
	name = "[TG] ChickenRoulette",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

new g_chickens[MAXPLAYERS + 1] = {-1, ...};
new String:g_chickenSpawnSound[PLATFORM_MAX_PATH];
new String:g_chickenKillSound[PLATFORM_MAX_PATH];

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
	LoadTranslations("TG.ChickenRoulette.phrases");
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
	if (StrEqual(prefixName, "ChickenRoulette-SpawnSound")) {
		ReplaceStringEx(file, PLATFORM_MAX_PATH, "sound/", "");
		PrecacheSoundAny(file, true);
		strcopy(g_chickenSpawnSound, sizeof(g_chickenSpawnSound), file);
		known = true;
	} else if (StrEqual(prefixName, "ChickenRoulette-KillSound")) {
		ReplaceStringEx(file, PLATFORM_MAX_PATH, "sound/", "");
		PrecacheSoundAny(file, true);
		strcopy(g_chickenKillSound, sizeof(g_chickenKillSound), file);
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

	TG_StartGame(client, GAME_ID, gameType);
}

public TG_OnGamePrepare(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID)) {
		return;
	}

	KillChickens();

	new Handle:players = CreateArray();

	for (new i = 1; i <= MaxClients; i++) {
		if ((gameType == TG_TeamGame && TG_IsPlayerRedOrBlue(i)) || (gameType == TG_RedOnly && TG_GetPlayerTeam(i) == TG_RedTeam)) {
			PushArrayCell(players, i);
		}
	}

	for (new i = 1; i <= MaxClients; i++) {
		if ((gameType == TG_TeamGame && TG_IsPlayerRedOrBlue(i)) || (gameType == TG_RedOnly && TG_GetPlayerTeam(i) == TG_RedTeam)) {
			new playersCount = GetArraySize(players);
			if (playersCount > 0) {
				new random = GetRandomInt(0, playersCount - 1);
				new chicken = SpawnChicken(GetArrayCell(players, random));
				RemoveFromArray(players, random);

				if (IsValidEntity(chicken)) {
					g_chickens[i] = chicken;
				}
			}
		}
	}

	CloseHandle(players);
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

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	KillChickens();
}

public Action:TG_OnTraceAttack(bool:ingame, victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (!ingame || !TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	if (TG_IsPlayerRedOrBlue(victim) && TG_IsPlayerRedOrBlue(attacker)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

KillChickens()
{
	for (new i = 1; i <= MaxClients; i++) {
		if (g_chickens[i] > 0 && IsValidEntity(g_chickens[i])) {
			AcceptEntityInput(g_chickens[i], "kill");
		}

		g_chickens[i] = -1;
	}
}

GetPlayerByChicken(chicken)
{
	for (new i = 1; i <= MaxClients; i++) {
		if (g_chickens[i] == chicken && TG_IsPlayerRedOrBlue(i)) {
			return i;
		}
	}

	return 0;
}

public Hook_ChickenDeath(const String: output[], chicken, client, Float: delay)
{
	new victim = GetPlayerByChicken(chicken);

	if (victim != 0) {
		if (Client_IsIngame(victim) && IsPlayerAlive(victim)) {
			SetEntityHealth(victim, 1);
			SDKHooks_TakeDamage(victim, client, client, 10.0);

			if (g_chickenKillSound[0] != '\0') {
				EmitSoundToAllAny(g_chickenKillSound);
			}

			new Float:clientPos[3];

			GetClientAbsOrigin(client, clientPos);
			clientPos[2] += 8.0;
			SpawnParticles(clientPos);
		}

		g_chickens[victim] = -1;
	}
}

SpawnChicken(client)
{
	new chicken = CreateEntityByName("chicken");

	if (chicken != -1) {
		new Float:clientPos[3];

		GetClientAbsOrigin(client, clientPos);
		clientPos[2] += 8.0;

		DispatchKeyValue(chicken, "glowenabled", "1");
		DispatchKeyValue(chicken, "glowcolor", "255 255 255");
		DispatchKeyValue(chicken, "rendercolor", "255 255 255");
		DispatchKeyValue(chicken, "modelscale", "1");
		DispatchKeyValue(chicken, "skin", (GetRandomInt(0,1) == 0) ? "0" : "1");
		DispatchSpawn(chicken);

		SetEntProp(chicken, Prop_Send, "m_bShouldGlow", true);
		SetEntProp(chicken, Prop_Send, "m_nGlowStyle", 0);
		SetEntPropFloat(chicken, Prop_Send, "m_flGlowMaxDist", 10000000.0);
		SetEntProp(chicken, Prop_Send, "m_clrGlow", ((0 & 0xFF) << 16) | ((0 & 0xFF) << 8) | ((255 & 0xFF) << 0));

		TeleportEntity(chicken, clientPos, NULL_VECTOR, NULL_VECTOR);

		HookSingleEntityOutput(chicken, "OnBreak", Hook_ChickenDeath);
		SDKHook(chicken, SDKHook_ShouldCollide, Hook_ChickenCollide);

		EventWeaponFire(client);
		SpawnParticles(clientPos);

		if (g_chickenKillSound[0] != '\0') {
			EmitSoundToAllAny(g_chickenSpawnSound);
		}
	}

	return chicken;
}

public bool:Hook_ChickenCollide(entity, collisiongroup, contentsmask, bool:originalResult)
{
	return (contentsmask == 33570827 || contentsmask == 1174421515 || contentsmask == 1107320971 || contentsmask == 1174421507);
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
