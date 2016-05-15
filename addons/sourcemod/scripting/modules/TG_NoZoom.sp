#include <sourcemod>
#include <sdktools_trace>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID "NoZoom"

new String:g_weaponName[64];
new EngineVersion:g_engVersion;

public Plugin:myinfo =
{
	name = "[TG] NoZoom",
	author = "Raska",
	description = "",
	version = "0.5",
	url = ""
}

new g_beamSprite = -1;
new Float:g_drawLaser[MAXPLAYERS + 1][3];

public OnMapStart()
{
	g_beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnPluginStart()
{
	LoadTranslations("TG.NoZoom.phrases");
	g_engVersion = GetEngineVersion();
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

	SetWeaponMenu(client, gameType);
}

public TG_OnGamePrepare(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		SetEntityHealth(i, 100);
		TG_AttachPlayerHealthBar(i);
		g_drawLaser[i] = Float:{0.0, 0.0, 0.0};
	}

	HookEvent("weapon_zoom", Event_WeaponZoom, EventHookMode_Post);
	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode_Post);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	new String:weaponName[64];

	ResetPack(dataPack);
	ReadPackString(dataPack, weaponName, sizeof(weaponName));

	strcopy(g_weaponName, sizeof(g_weaponName), weaponName);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerItem(i, "weapon_knife");
		GivePlayerWeaponAndAmmo(i, g_weaponName, 200, 200);
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	UnhookEvent("weapon_zoom", Event_WeaponZoom);
	UnhookEvent("bullet_impact", Event_BulletImpact);
}

public Action:Event_WeaponZoom(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponName[64];

	GetClientWeapon(client, weaponName, sizeof(weaponName));

	if (StrEqual(weaponName, g_weaponName, false) && GetClientTeam(client) == 2) {
		new weapon = GetPlayerWeaponSlot(client, 0);
		if (weapon != -1) {
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);

			GivePlayerWeaponAndAmmo(client, g_weaponName, 200, 200);
		}
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((TG_IsCurrentGameID(GAME_ID) && TG_IsPlayerRedOrBlue(client)) || (TG_IsCurrentGameID(GAME_ID) && TG_GetPlayerTeam(client) == TG_RedTeam)) {
		g_drawLaser[client][0] = GetEventFloat(event, "x");
		g_drawLaser[client][1] = GetEventFloat(event, "y");
		g_drawLaser[client][2] = GetEventFloat(event, "z");

		RequestFrame(Frame_DrawLaser, client);
	}

	return Plugin_Continue;
}

public Frame_DrawLaser(any:client)
{
	if (g_drawLaser[client][0] == 0.0 && g_drawLaser[client][1] == 0.0 && g_drawLaser[client][2] == 0.0)
		return;

	new Float:clientPos[3];
	GetClientEyePosition(client, clientPos);
	clientPos[2] -= 4;

	TE_SetupBeamPoints(clientPos, g_drawLaser[client], g_beamSprite, g_beamSprite, 0, 0, 0.5, 1.0, 1.0, 1024, 0.0, (TG_GetPlayerTeam(client) == TG_RedTeam) ? {220, 20, 60, 255} : {30, 144, 255, 255}, 10);
	TE_SendToAll();

	g_drawLaser[client][0] = 0.0;
	g_drawLaser[client][1] = 0.0;
	g_drawLaser[client][2] = 0.0;
}

SetWeaponMenu(client, TG_GameType:gameType)
{
	new Handle:menu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(menu, "%T", "ChooseWeapon", client);
	PushMenuCell(menu, "_GAME_TYPE_", _:gameType);

	switch (g_engVersion) {
		case Engine_CSS: {
			AddMenuItem(menu, "weapon_awp", 	"AWP");
			AddMenuItem(menu, "weapon_scout", "Scout");
		}
		case Engine_CSGO: {
			AddMenuItem(menu, "weapon_awp", 	"AWP");
			AddMenuItem(menu, "weapon_ssg08", "Scout");
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public SetWeaponMenu_Handler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select) {
		new String:info[64], String:weaponName[TG_GAME_SETTINGS_LENGTH];
		GetMenuItem(menu, key, info, sizeof(info), _, weaponName, sizeof(weaponName));

		new TG_GameType:gameType = TG_GameType:GetMenuCell(menu, "_GAME_TYPE_");

		new Handle:dataPack = CreateDataPack();
		WritePackString(dataPack, info);

		TG_StartGame(client, GAME_ID, gameType, weaponName, dataPack, true);
	}
}
