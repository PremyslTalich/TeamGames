#include <sourcemod>
#include <smlib>
#include <sdkhooks>
#include <teamgames>

#define GAME_ID	"OneInTheChamber"

public Plugin:myinfo =
{
	name = "[TG] OneInTheChamber",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.OneInTheChamber.phrases");
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
	Format(name, nameSize, "OneInTheChamber");
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	TG_StartGame(client, GAME_ID, gameType, _, _, true);
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			GivePlayerWeaponAndAmmo(i, "weapon_deagle", 1, 0);
			SetEntityHealth(i, 10);
		}
	}

	HookEvent("weapon_fire", Event_WeaponFire);
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (TG_IsPlayerRedOrBlue(client) && StrEqual(weapon, "weapon_deagle")) {
		RequestFrame(Frame_WeaponFire, client);
	}
}

public Frame_WeaponFire(any:client)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return;

	Client_RemoveAllWeapons(client);
	GivePlayerItem(client, "weapon_knife");
}

public TG_OnPlayerDeath(attacker, TG_Team:attackerTeam, victim, TG_Team:victimTeam, bool:headshot, const String:weapon[], TG_GameProgress:gameStatus, const String:gameID[], TG_GameType:gameType)
{
	if (!StrEqual(gameID, GAME_ID) || !TG_AreTeamsEnemies(attackerTeam, victimTeam, gameType))
		return;

	RequestFrame2(Frame_OnPlayerDeath, 2, attacker);
}

public Frame_OnPlayerDeath(any:client)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return;

	GivePlayerWeaponAndAmmo(client, "weapon_deagle", 1, 0);
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	UnhookEvent("weapon_fire", Event_WeaponFire);
}
