#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID	"Machines500HP"

public Plugin:myinfo =
{
	name = "[TG] Machines + 500 HP",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
};

new EngineVersion:g_iEngVersion;
new g_BeamSprite = -1;
new Handle:g_hReffilAmmo;
new Float:g_fDrawLaser[MAXPLAYERS + 1][3];

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnPluginStart()
{
	LoadTranslations("TG.Machines.phrases");
	g_iEngVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames") && !TG_IsModuleReged(TG_Game, GAME_ID))
		TG_RegGame(GAME_ID, TG_FiftyFifty);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], &TG_MenuItemStatus:status)
{
	if (type == TG_Game && StrEqual(id, GAME_ID))
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "GameName", client);
}

public TG_OnGameSelected(const String:id[], iClient)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	TG_StartGame(iClient, GAME_ID, _, _, true);
}

public TG_OnGamePrepare(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	HookEvent("bullet_impact", Event_BulletImpact);

	if (g_hReffilAmmo != INVALID_HANDLE) {
		KillTimer(g_hReffilAmmo);
	}
	g_hReffilAmmo = CreateTimer(7.0, Timer_RefillAmmo, _, TIMER_REPEAT);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		switch (g_iEngVersion) {
			case Engine_CSS: {
				GivePlayerWeaponAndAmmo(i, "weapon_m249", _, 0);
			}
			case Engine_CSGO: {
				GivePlayerWeaponAndAmmo(i, "weapon_negev", _, 0);
			}
		}

		SetEntityHealth(i, 500);
	}
}

public TG_OnGameEnd(const String:id[], TG_Team:iTeam, winners[], winnersCount, Handle:DataPack)
{
	if (StrEqual(id, GAME_ID)) {
		UnhookEvent("bullet_impact", Event_BulletImpact);

		if (g_hReffilAmmo != INVALID_HANDLE) {
			KillTimer(g_hReffilAmmo);
		}
		g_hReffilAmmo = INVALID_HANDLE;
	}
}

public Action:Timer_RefillAmmo(Handle:hTimer)
{
	if (!TG_IsCurrentGameID(GAME_ID)) {
		return Plugin_Stop;
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			new String:sWeapon[64];
			new iWeapon = Client_GetActiveWeaponName(i, sWeapon, sizeof(sWeapon));

			if (iWeapon != INVALID_ENT_REFERENCE) {
				if (g_iEngVersion == Engine_CSS && StrEqual(sWeapon, "weapon_m249")) {
					SetPlayerWeaponAmmo(i, iWeapon, _, 100);
				} else if (g_iEngVersion == Engine_CSGO && StrEqual(sWeapon, "weapon_negev")) {
					SetPlayerWeaponAmmo(i, iWeapon, _, 150);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((TG_IsCurrentGameID(GAME_ID) && TG_IsPlayerRedOrBlue(iClient))) {
		g_fDrawLaser[iClient][0] = GetEventFloat(event, "x");
		g_fDrawLaser[iClient][1] = GetEventFloat(event, "y");
		g_fDrawLaser[iClient][2] = GetEventFloat(event, "z");

		RequestFrame(Frame_DrawLaser, iClient);
	}

	return Plugin_Continue;
}

public Frame_DrawLaser(any:iClient)
{
	if (g_fDrawLaser[iClient][0] == 0.0 && g_fDrawLaser[iClient][1] == 0.0 && g_fDrawLaser[iClient][2] == 0.0) {
		return;
	}

	new Float:fClientPos[3];
	GetClientEyePosition(iClient, fClientPos);
	fClientPos[2] -= 4;

	TE_SetupBeamPoints(fClientPos, g_fDrawLaser[iClient], g_BeamSprite, g_BeamSprite, 0, 0, 0.125, 1.0, 1.0, 1024, 0.0, (TG_GetPlayerTeam(iClient) == TG_RedTeam) ? {220, 20, 60, 255} : {30, 144, 255, 255}, 10);
	TE_SendToAll();

	g_fDrawLaser[iClient][0] = 0.0;
	g_fDrawLaser[iClient][1] = 0.0;
	g_fDrawLaser[iClient][2] = 0.0;
}
