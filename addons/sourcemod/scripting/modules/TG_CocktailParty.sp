#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID "CocktailParty"

public Plugin:myinfo =
{
	name = "[TG] CocktailParty",
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
	LoadTranslations("TG.CocktailParty.phrases");
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

	TG_StartGame(client, GAME_ID, gameType);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	HookEvent("molotov_detonate", Event_MolotovDetonate);

	for (new i = 1; i <= MaxClients; i++) {
		if (!TG_IsPlayerRedOrBlue(i))
			continue;

		Client_GiveWeapon(i, "weapon_molotov", true);
		TG_AttachPlayerHealthBar(i);
	}
}

public Action:Event_MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsPlayerRedOrBlue(client)) {
		new molotov = GivePlayerItem(client, "weapon_molotov");
		if (molotov != INVALID_ENT_REFERENCE) {
			Client_SetActiveWeapon(client, molotov);
		}
	}

	return Plugin_Continue;
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	UnhookEvent("molotov_detonate", Event_MolotovDetonate);
}
