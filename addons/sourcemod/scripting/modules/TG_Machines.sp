#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID	"Machines500HP"

public Plugin:myinfo =
{
	name = "[TG] Machines + 500 HP",
	author = "Raska",
	description = "",
	version = "0.4",
	url = ""
};

new EngineVersion:g_engVersion;
new g_beamSprite = -1;
new Handle:g_reffilAmmo;
new Float:g_drawLaser[MAXPLAYERS + 1][3];

public OnMapStart()
{
	g_beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnPluginStart()
{
	LoadTranslations("TG.Machines.phrases");
	g_engVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames"))
		TG_RegGame(GAME_ID, TG_TeamGame | TG_RedOnly);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], nameSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	Format(name, nameSize, "%T", "GameName", client);
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	TG_StartGame(client, GAME_ID, gameType, _, _, true);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	HookEvent("bullet_impact", Event_BulletImpact);

	if (g_reffilAmmo != INVALID_HANDLE) {
		KillTimer(g_reffilAmmo);
	}
	g_reffilAmmo = CreateTimer(7.0, Timer_RefillAmmo, _, TIMER_REPEAT);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		switch (g_engVersion) {
			case Engine_CSS: {
				GivePlayerWeaponAndAmmo(i, "weapon_m249", _, 0);
			}
			case Engine_CSGO: {
				GivePlayerWeaponAndAmmo(i, "weapon_negev", _, 0);
			}
		}

		SetEntityHealth(i, 500);
		TG_AttachPlayerHealthBar(i, 500);
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (StrEqual(id, GAME_ID)) {
		UnhookEvent("bullet_impact", Event_BulletImpact);

		if (g_reffilAmmo != INVALID_HANDLE) {
			KillTimer(g_reffilAmmo);
		}
		g_reffilAmmo = INVALID_HANDLE;
	}
}

public Action:Timer_RefillAmmo(Handle:timer)
{
	if (!TG_IsCurrentGameID(GAME_ID)) {
		return Plugin_Stop;
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			new String:weaponName[64];
			new weapon = Client_GetActiveWeaponName(i, weaponName, sizeof(weaponName));

			if (weapon != INVALID_ENT_REFERENCE) {
				if (g_engVersion == Engine_CSS && StrEqual(weaponName, "weapon_m249")) {
					SetPlayerWeaponAmmo(i, weapon, _, 100);
				} else if (g_engVersion == Engine_CSGO && StrEqual(weaponName, "weapon_negev")) {
					SetPlayerWeaponAmmo(i, weapon, _, 150);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((TG_IsCurrentGameID(GAME_ID) && TG_IsPlayerRedOrBlue(client))) {
		g_drawLaser[client][0] = GetEventFloat(event, "x");
		g_drawLaser[client][1] = GetEventFloat(event, "y");
		g_drawLaser[client][2] = GetEventFloat(event, "z");

		RequestFrame(Frame_DrawLaser, client);
	}

	return Plugin_Continue;
}

public Frame_DrawLaser(any:client)
{
	if (g_drawLaser[client][0] == 0.0 && g_drawLaser[client][1] == 0.0 && g_drawLaser[client][2] == 0.0) {
		return;
	}

	new Float:clientPos[3];
	GetClientEyePosition(client, clientPos);
	clientPos[2] -= 4;

	TE_SetupBeamPoints(clientPos, g_drawLaser[client], g_beamSprite, g_beamSprite, 0, 0, 0.125, 1.0, 1.0, 1024, 0.0, (TG_GetPlayerTeam(client) == TG_RedTeam) ? {220, 20, 60, 255} : {30, 144, 255, 255}, 10);
	TE_SendToAll();

	g_drawLaser[client][0] = 0.0;
	g_drawLaser[client][1] = 0.0;
	g_drawLaser[client][2] = 0.0;
}
