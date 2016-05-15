#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID	"TaserMania"

public Plugin:myinfo =
{
	name = "[TG] TaserMania",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
};

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
	LoadTranslations("TG.TaserMania.phrases");
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

	TG_StartGame(client, id, gameType);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	HookEvent("weapon_fire", Event_WeaponFire);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		GivePlayerWeaponAndAmmo(i, "weapon_taser", 0, 2);
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[64];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsCurrentGameID(GAME_ID) && TG_IsPlayerRedOrBlue(client)) {
		GetEventString(event, "weapon", weapon, sizeof(weapon));

		if (StrEqual(weapon, "weapon_taser")) {
			SetPlayerWeaponAmmo(client, Client_GetActiveWeapon(client), _, 2);
		}
	}

	return Plugin_Continue;
}

public TG_OnPlayerLeaveGame(const String:id[], TG_GameType:gameType, client, TG_Team:team, TG_PlayerTrigger:trigger){
	if (gameType == TG_RedOnly && team == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:winners = CreateArray();

		for (new i = 1; i <= MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(winners, i);
				break;
			}
		}

		TG_StopGame(TG_RedTeam, winners);
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	UnhookEvent("weapon_fire", Event_WeaponFire);
}
