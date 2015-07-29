#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID_FIFTYFIFTY	"TaserMania-FiftyFifty"
#define GAME_ID_REDONLY		"TaserMania-RedOnly"

public Plugin:myinfo =
{
	name = "[TG] TaserMania",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
};

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
	LoadTranslations("TG.TaserMania-Raska.phrases");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames")) {
		if (!TG_IsModuleReged(TG_Game, GAME_ID_FIFTYFIFTY))
			TG_RegGame(GAME_ID_FIFTYFIFTY, TG_FiftyFifty, "%t", "GameName-FiftyFifty");
		
		if (!TG_IsModuleReged(TG_Game, GAME_ID_REDONLY))
			TG_RegGame(GAME_ID_REDONLY, TG_RedOnly, "%t", "GameName-RedOnly");
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID_FIFTYFIFTY);
	TG_RemoveGame(GAME_ID_REDONLY);
}

public TG_OnMenuGameDisplay(const String:id[], iClient, String:name[])
{
	if (StrEqual(id, GAME_ID_FIFTYFIFTY)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "GameName-FiftyFifty", iClient);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "GameName-RedOnly", iClient);
	}
}

public TG_OnGameSelected(const String:id[], iClient)
{
	if (StrEqual(id, GAME_ID_FIFTYFIFTY)) {
		TG_StartGame(iClient, GAME_ID_FIFTYFIFTY);
	} else if (StrEqual(id, GAME_ID_REDONLY)) {
		TG_StartGame(iClient, GAME_ID_REDONLY);
	}
}

public TG_OnGamePrepare(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID_FIFTYFIFTY) && !StrEqual(id, GAME_ID_REDONLY))
		return;
	
	HookEvent("weapon_fire", Event_WeaponFire);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;
		
		GivePlayerWeaponAndAmmo(i, "weapon_taser", 1, 1);
	}
}

public Action:Event_WeaponFire(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	decl String:sWeapon[64];
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if ((TG_IsCurrentGameID(GAME_ID_FIFTYFIFTY) && TG_IsPlayerRedOrBlue(iClient)) || (TG_IsCurrentGameID(GAME_ID_REDONLY) && TG_GetPlayerTeam(iClient) == TG_RedTeam)) {
		GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));
		
		if (StrEqual(sWeapon, "taser")) {
			SetPlayerWeaponAmmo(iClient, Client_GetActiveWeapon(iClient), _, 1);
		}
	}
	
	return Plugin_Continue;
}

public TG_OnPlayerLeaveGame(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger){
	if (StrEqual(sID, GAME_ID_REDONLY) && iTeam == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:hWinners = CreateArray();
		
		for (new i = 1; i <= MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(hWinners, i);
				break;
			}
		}
		
		TG_StopGame(TG_RedTeam, hWinners);		
	}
}

public TG_OnGameEnd(const String:id[], TG_Team:iTeam, winners[], winnersCount, Handle:DataPack)
{
	if (StrEqual(id, GAME_ID_FIFTYFIFTY) || StrEqual(id, GAME_ID_REDONLY)) {
		UnhookEvent("weapon_fire", Event_WeaponFire);
	}
}
