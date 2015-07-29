#include <sourcemod>
#include <smlib>
#include <sdkhooks>
#include <teamgames>

#define COCKTAILPARTY_ID	"GoGames-CocktailParty"
#define TASERMANIA_FF_ID	"GoGames-TaserMania-FiftyFifty"
#define TASERMANIA_RO_ID	"GoGames-TaserMania-RedOnly"
#define CHICKENHUNT_FF_ID	"GoGames-ChickenHunt-FiftyFifty"
#define CHICKENHUNT_RO_ID	"GoGames-ChickenHunt-RedOnly"

public Plugin:myinfo =
{
	name = "[TG] GoGames",
	author = "Raska",
	description = "",
	version = "0.1",
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
	LoadTranslations("TG.GoGames.phrases");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames")) {
		if (!TG_IsModuleReged(TG_Game, COCKTAILPARTY_ID)) {
			TG_RegGame(COCKTAILPARTY_ID, TG_FiftyFifty, "%t", "CocktailParty - GameName");
		}
		
		if (!TG_IsModuleReged(TG_Game, TASERMANIA_FF_ID)) {
			TG_RegGame(TASERMANIA_FF_ID, TG_FiftyFifty, "%t", "TaserMania-FiftyFifty - GameName");
		}
		
		if (!TG_IsModuleReged(TG_Game, TASERMANIA_RO_ID)) {
			TG_RegGame(TASERMANIA_RO_ID, TG_FiftyFifty, "%t", "TaserMania-RedOnly - GameName");
		}
		
		if (!TG_IsModuleReged(TG_Game, CHICKENHUNT_FF_ID)) {
			TG_RegGame(COCKTAILPARTY_ID, TG_FiftyFifty, "%t", "ChickenHunt-FiftyFifty - GameName");
		}
		
		if (!TG_IsModuleReged(TG_Game, CHICKENHUNT_RO_ID)) {
			TG_RegGame(COCKTAILPARTY_ID, TG_RedOnly, "%t", "ChickenHunt-RedOnly - GameName");
		}
	}
}

public OnPluginEnd()
{
	TG_RemoveGame(COCKTAILPARTY_ID);
	TG_RemoveGame(TASERMANIA_FF_ID);
	TG_RemoveGame(TASERMANIA_RO_ID);
	TG_RemoveGame(CHICKENHUNT_FF_ID);
	TG_RemoveGame(CHICKENHUNT_RO_ID);
}

public TG_OnMenuGameDisplay(const String:sID[], iClient, String:name[])
{
	if (StrEqual(sID, TASERMANIA_FF_ID)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "TaserMania-FiftyFifty - GameName", iClient);
	} else if  (StrEqual(sID, TASERMANIA_RO_ID)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "TaserMania-RedOnly - GameName", iClient);
	} else if  (StrEqual(sID, COCKTAILPARTY_ID)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "CocktailParty - GameName", iClient);
	} else if  (StrEqual(sID, CHICKENHUNT_FF_ID)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "ChickenHunt-FiftyFifty - GameName", iClient);
	} else if  (StrEqual(sID, CHICKENHUNT_RO_ID)) {
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "ChickenHunt-RedOnly - GameName", iClient);
	}
}

public TG_OnGameSelected(const String:sID[], iClient)
{
	if (StrEqual(sID, TASERMANIA_FF_ID)) {
		TG_StartGame(iClient, TASERMANIA_FF_ID, _, _, true);
	} else if  (StrEqual(sID, TASERMANIA_RO_ID)) {
		TG_StartGame(iClient, TASERMANIA_RO_ID, _, _, true);
	} else if  (StrEqual(sID, COCKTAILPARTY_ID)) {
		TG_StartGame(iClient, COCKTAILPARTY_ID, _, _, true);
	} else if  (StrEqual(sID, CHICKENHUNT_FF_ID)) {
		TG_StartGame(iClient, CHICKENHUNT_FF_ID, _, _, _, _, false);
	} else if  (StrEqual(sID, CHICKENHUNT_RO_ID)) {
		TG_StartGame(iClient, CHICKENHUNT_RO_ID, _, _, _, _, false);
	}
}

public TG_OnGamePrepare(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, TASERMANIA_ID))
		return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;
		
		GivePlayerWeaponAndAmmo(i, "weapon_taser", 1, 500);
	}
}

public TG_OnGameStart(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, COCKTAILPARTY_ID, true))
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
	if (!TG_IsCurrentGameID(COCKTAILPARTY_ID))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (TG_IsPlayerRedOrBlue(iClient)) {
		Client_GiveWeapon(iClient, "weapon_molotov", true);
	}

	return Plugin_Continue;
}


public TG_OnTeamEmpty(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (StrEqual(sID, TASERMANIA_ID)) {
		TG_StopGame(TG_GetOppositeTeam(iTeam));	
	} else if(StrEqual(sID, COCKTAILPARTY_ID)) {
		TG_StopGame(TG_GetOppositeTeam(iTeam));
	}
}
