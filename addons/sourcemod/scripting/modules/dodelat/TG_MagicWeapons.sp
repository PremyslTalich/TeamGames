#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define GAME_ID "MagicWeapons-Raska"
#define EFFECT_LENGTH 5.0

public Plugin:myinfo =
{
	name = "[TG] MagicWeapons",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

enum MagicEffect
{
	None = 0,
	Freeze,
	Burn,
	Explode
}

new MagicEffect:g_iPlayerClass[MAXPLAYERS + 1] = {None, ...};

new MagicEffect:g_iEffect[MAXPLAYERS + 1] = {None, ...};
new Handle:g_iEffectTimer[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

public OnPluginStart()
{
	LoadTranslations("TG.MagicWeapons-Raska.phrases");
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

public TG_OnMenuGameDisplay(const String:sID[], iClient, String:name[])
{
	if (StrEqual(sID, GAME_ID))
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "GameName", iClient);
}

public TG_OnGameSelected(const String:sID[], iClient)
{
	if (!StrEqual(sID, GAME_ID))
		return;
	
	TG_StartGame(iClient, GAME_ID);
}

public TG_OnGamePrepare(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID))
		return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!TG_IsPlayerRedOrBlue(i))
			continue;
		
		GivePlayerItem(i, "weapon_knife");
		g_iPlayerClass[i] = MagicEffect:Math_GetRandomInt(1, _:MagicEffect);
		
		PrintToChatAll("magic: %N = '%d'", i, _:g_iPlayerClass[i]);
		
		SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public TG_OnTeamEmpty(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (!StrEqual(sID, GAME_ID, true))
		return;
	
	TG_StopGame(TG_GetOppositeTeam(iTeam));
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!Client_IsIngame(i))
			continue;
		
		SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public Action:Hook_OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{
	if (!TG_IsCurrentGameID(GAME_ID) || !TG_InOppositeTeams(iVictim, iAttacker) || !(GetClientButtons(iAttacker) & IN_ATTACK2)) {
		return Plugin_Continue;
	}
	
	if (g_iEffectTimer[iVictim] != INVALID_HANDLE) {
		KillTimer(g_iEffectTimer[iVictim]);
		g_iEffectTimer[iVictim] = INVALID_HANDLE;
		RemoveEffect(iVictim);
	}
	
	switch (g_iPlayerClass[iAttacker]) {
		case Freeze: {
			// AddFreeze(iVictim);
			PrintToChatAll("freeze");
		}
		case Burn: {
			PrintToChatAll("burn");
			AddBurn(iVictim);
		}
	}
	
	return Plugin_Handled;
}

RemoveEffect(iClient)
{
	switch (g_iEffect[iClient]) {
		case Freeze: {
			RemoveFreeze(iClient);
		}
		case Burn: {
			RemoveBurn(iClient);
		}
	}
	
	g_iEffect[iClient] = None;
}

AddFreeze(iClient)
{
	g_iEffect[iClient] = Freeze;
}

RemoveFreeze(iClient)
{
	
}

AddBurn(iClient)
{
	IgniteEntity(iClient, EFFECT_LENGTH);
	g_iEffect[iClient] = Burn;
}

RemoveBurn(iClient)
{
	ExtinguishEntity(iClient);
}