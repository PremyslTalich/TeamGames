#include <sourcemod>
#include <sdktools_trace>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID_TEAMGAME		"NoZoom-TeamGame"
#define GAME_ID_REDONLY			"NoZoom-RedOnly"

new String:g_WeaponName[64];
new EngineVersion:g_iEngVersion;

public Plugin:myinfo =
{
	name = "[TG] NoZoom",
	author = "Raska",
	description = "",
	version = "0.4",
	url = ""
}

new g_BeamSprite = -1;
new Float:g_fDrawLaser[MAXPLAYERS + 1][3];

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnPluginStart()
{
	LoadTranslations("TG.NoZoom.phrases");
	g_iEngVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_ID_TEAMGAME);
		TG_RegGame(GAME_ID_REDONLY, TG_RedOnly);
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID_TEAMGAME);
	TG_RemoveGame(GAME_ID_REDONLY);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_TEAMGAME)) {
		Format(name, maxSize, "%T", "GameName-TeamGame", client);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		Format(name, maxSize, "%T", "GameName-RedOnly", client);
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], iClient)
{
	if ((StrEqual(id, GAME_ID_TEAMGAME) || StrEqual(id, GAME_ID_REDONLY)) && type == TG_Game) {
		SetWeaponMenu(iClient, id);
	}
}

public TG_OnGamePrepare(const String:id[], client, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID_TEAMGAME) && !StrEqual(id, GAME_ID_REDONLY))
		return;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		SetEntityHealth(i, 100);
		g_fDrawLaser[i] = Float:{0.0, 0.0, 0.0};
	}

	HookEvent("weapon_zoom", Event_WeaponZoom, EventHookMode_Post);
	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode_Post);
}

public TG_OnGameStart(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID_TEAMGAME) && !StrEqual(id, GAME_ID_REDONLY))
		return;

	decl String:WeaponName[64];

	ResetPack(DataPack);
	ReadPackString(DataPack, WeaponName, sizeof(WeaponName));

	strcopy(g_WeaponName, sizeof(g_WeaponName), WeaponName);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerItem(i, "weapon_knife");
		GivePlayerWeaponAndAmmo(i, g_WeaponName, 200, 200);
	}
}

public TG_OnGameEnd(const String:id[], TG_Team:iTeam, winners[], winnersCount, Handle:DataPack)
{
	if (StrEqual(id, GAME_ID_TEAMGAME) || StrEqual(id, GAME_ID_REDONLY)) {
		UnhookEvent("weapon_zoom", Event_WeaponZoom);
		UnhookEvent("bullet_impact", Event_BulletImpact);
	}
}

public Action:Event_WeaponZoom(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID_TEAMGAME) && !TG_IsCurrentGameID(GAME_ID_REDONLY))
		return Plugin_Continue;


	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weaponname[64];

	GetClientWeapon(iClient, weaponname, sizeof(weaponname));

	if (StrEqual(weaponname, g_WeaponName, false) && GetClientTeam(iClient) == 2)
	{
		new weapon = GetPlayerWeaponSlot(iClient, 0);
		if (weapon != -1)
		{
			RemovePlayerItem(iClient, weapon);
			RemoveEdict(weapon);

			GivePlayerWeaponAndAmmo(iClient, g_WeaponName, 200, 200);
		}
	}

	return Plugin_Continue;
}

public Action:Event_BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if ((TG_IsCurrentGameID(GAME_ID_TEAMGAME) && TG_IsPlayerRedOrBlue(iClient)) || (TG_IsCurrentGameID(GAME_ID_REDONLY) && TG_GetPlayerTeam(iClient) == TG_RedTeam)) {
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

	TE_SetupBeamPoints(fClientPos, g_fDrawLaser[iClient], g_BeamSprite, g_BeamSprite, 0, 0, 0.5, 1.0, 1.0, 1024, 0.0, (TG_GetPlayerTeam(iClient) == TG_RedTeam) ? {220, 20, 60, 255} : {30, 144, 255, 255}, 10);
	TE_SendToAll();

	g_fDrawLaser[iClient][0] = 0.0;
	g_fDrawLaser[iClient][1] = 0.0;
	g_fDrawLaser[iClient][2] = 0.0;
}

SetWeaponMenu(iClient, const String:sID[])
{
	new Handle:hMenu = CreateMenu(SetWeaponMenu_Handler);

	SetMenuTitle(hMenu, "%T", "ChooseWeapon", iClient);
	PushMenuString(hMenu, "_GAME_ID_", sID);

	switch (g_iEngVersion) {
		case Engine_CSS: {
			AddMenuItem(hMenu, "weapon_awp", 	"AWP");
			AddMenuItem(hMenu, "weapon_scout", "Scout");
		}
		case Engine_CSGO: {
			AddMenuItem(hMenu, "weapon_awp", 	"AWP");
			AddMenuItem(hMenu, "weapon_ssg08", "Scout");
		}
	}

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 30);
}

public SetWeaponMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select)
	{
		new String:info[64], String:WeaponName[64], String:sID[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, info, sizeof(info), _, WeaponName, 64);

		if (!GetMenuString(hMenu, "_GAME_ID_", sID, sizeof(sID))) {
			return;
		}

		new Handle:hDataPack = CreateDataPack();
		WritePackString(hDataPack, info);

		if (StrEqual(sID, GAME_ID_TEAMGAME)) {
			TG_StartGame(iClient, GAME_ID_TEAMGAME, WeaponName, hDataPack, true);
		} else {
			TG_StartGame(iClient, GAME_ID_REDONLY, WeaponName, hDataPack, true);
		}
	}
}
