#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID				"CocktailParty"

public Plugin:myinfo =
{
	name = "[TG] CocktailParty",
	author = "Raska",
	description = "",
	version = "0.2",
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
	LoadTranslations("TG.CocktailParty.phrases");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames") && !TG_IsModuleReged(TG_Game, GAME_ID))
		TG_RegGame(GAME_ID, TG_FiftyFifty, "%t", "GameName");
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_OnMenuGameDisplay(const String:sID[], iClient, String:sName[])
{
	if (StrEqual(sID, GAME_ID))
		Format(sName, TG_MODULE_NAME_LENGTH, "%T", "GameName", iClient);
}

public Action:TG_OnGameSelected(const String:sID[], iClient)
{
	if (!StrEqual(sID, GAME_ID, true))
		return Plugin_Continue;

	TG_StartGame(iClient, GAME_ID);

	return Plugin_Continue;
}

public TG_OnGameStart(const String:sID[], iClient, const String:GameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID, true))
		return;
	
	HookEvent("molotov_detonate", Event_MolotovDetonate);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;
		
		Client_GiveWeapon(i, "weapon_molotov", true);
	}
}

public Action:Event_MolotovDetonate(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (TG_IsPlayerRedOrBlue(iClient)) {
		
		new iMolotov = GivePlayerItem(iClient, "weapon_molotov");
		if (iMolotov != INVALID_ENT_REFERENCE) {
			Client_SetActiveWeapon(iClient, iMolotov);
		}
	}

	return Plugin_Continue;
}

public TG_OnGameEnd(const String:id[], TG_Team:iTeam, winners[], winnersCount, Handle:DataPack)
{
	if (StrEqual(id, GAME_ID)) {
		UnhookEvent("molotov_detonate", Event_MolotovDetonate);
	}
}
