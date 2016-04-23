#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID_TEAMGAME		"WildWest-TeamGame"
#define GAME_ID_REDONLY			"WildWest-RedOnly"

new g_iPlayerRevolver[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "[TG] WildWest",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

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
	LoadTranslations("TG.WildWest.phrases");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		TG_RegGame(GAME_ID_TEAMGAME, TG_TeamGame);
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
	if (type != TG_Game) {
		return;
	}

	if (StrEqual(id, GAME_ID_TEAMGAME)) {
		TG_StartGame(iClient, GAME_ID_TEAMGAME, _, _, true);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		TG_StartGame(iClient, GAME_ID_REDONLY, _, _, true);
	}
}

public TG_OnGameStart(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID_TEAMGAME) && !StrEqual(sID, GAME_ID_REDONLY))
		return;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (TG_IsPlayerRedOrBlue(i)) {
			new iRevolver = GivePlayerWeaponAndAmmo(i, "weapon_revolver");

			TG_AttachPlayerHealthBar(i);

			g_iPlayerRevolver[i] = iRevolver;
			RequestFrame(Frame_BlockAttack2, i);
		} else {
			g_iPlayerRevolver[i] = -1;
		}
	}
}

public TG_OnPlayerLeaveGame(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	g_iPlayerRevolver[iClient] = -1;
}

public Frame_BlockAttack2(any:iClient)
{
	if (IsValidEntity(g_iPlayerRevolver[iClient]) && TG_IsPlayerRedOrBlue(iClient)) {
		SetEntPropFloat(g_iPlayerRevolver[iClient], Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 1.0);
		SetPlayerWeaponAmmo(iClient, g_iPlayerRevolver[iClient], _, 8);
		RequestFrame(Frame_BlockAttack2, iClient);
	} else {
		g_iPlayerRevolver[iClient] = -1;
	}
}
