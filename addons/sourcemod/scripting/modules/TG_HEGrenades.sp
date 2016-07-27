#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID	"HEGrenades"

public Plugin:myinfo =
{
	name = "[TG] HEGrenades",
	author = "Raska",
	description = "",
	version = "0.8",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.HEGrenades.phrases");
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

	HookEvent("hegrenade_detonate", Event_HEGrenadeDetonate);

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			GiveGrenade(i);
			TG_AttachPlayerHealthBar(i);
		}
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID))
		return;

	UnhookEvent("hegrenade_detonate", Event_HEGrenadeDetonate);
}

public Action:Event_HEGrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsPlayerRedOrBlue(client)) {
		GiveGrenade(client);
	}

	return Plugin_Continue;
}

GiveGrenade(client)
{
	new grenade = GivePlayerItem(client, "weapon_hegrenade");

	SetEntProp(grenade, Prop_Send, "m_iClip1", 1);

	new offset = FindDataMapInfo(client, "m_iAmmo") + (GetEntProp(grenade, Prop_Data, "m_iPrimaryAmmoType") * 4);
	SetEntData(client, offset, 1, 4, true);

	if (GetEngineVersion() == Engine_CSGO) {
		SetEntProp(grenade, Prop_Send, "m_iPrimaryReserveAmmoCount", 1);
	}
}
