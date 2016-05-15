#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID "WildWest"

new g_playerRevolver[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TG] WildWest",
	author = "Raska",
	description = "",
	version = "0.4",
	url = ""
}

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
	LoadTranslations("TG.WildWest.phrases");
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

	TG_StartGame(client, GAME_ID, gameType, _, _, true);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			new revolver = GivePlayerWeaponAndAmmo(i, "weapon_revolver");

			TG_AttachPlayerHealthBar(i);

			g_playerRevolver[i] = revolver;
			RequestFrame(Frame_BlockAttack2, i);
		} else {
			g_playerRevolver[i] = -1;
		}
	}
}

public TG_OnPlayerLeaveGame(const String:id[], TG_GameType:gameType, client, TG_Team:team, TG_PlayerTrigger:trigger)
{
	g_playerRevolver[client] = -1;
}

public Frame_BlockAttack2(any:client)
{
	if (IsValidEntity(g_playerRevolver[client]) && TG_IsPlayerRedOrBlue(client)) {
		SetEntPropFloat(g_playerRevolver[client], Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.0);
		SetPlayerWeaponAmmo(client, g_playerRevolver[client], _, 8);
		RequestFrame(Frame_BlockAttack2, client);
	} else {
		g_playerRevolver[client] = -1;
	}
}
