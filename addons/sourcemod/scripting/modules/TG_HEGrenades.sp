#include <sourcemod>
#include <smlib>
#include <teamgames>

#define GAME_ID	"HEGrenades"

public Plugin:myinfo =
{
	name = "[TG] HEGrenades",
	author = "Raska",
	description = "",
	version = "0.7",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.HEGrenades.phrases");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames"))
		TG_RegGame(GAME_ID, TG_TeamGame);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type == TG_Game && StrEqual(id, GAME_ID))
		Format(name, maxSize, "%T", "GameName", client);
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:sID[], iClient)
{
	if (StrEqual(sID, GAME_ID) && type == TG_Game)
		TG_StartGame(iClient, GAME_ID);
}


public TG_OnGameStart(const String:sID[], iClient, const String:GameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID, true))
		return;

	HookEvent("hegrenade_detonate", Event_HEGrenadeDetonate);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (TG_IsPlayerRedOrBlue(i)) {
			GiveGrenade(i);
			TG_AttachPlayerHealthBar(i);
		}
	}
}

public TG_OnGameEnd(const String:sID[], TG_Team:iTeam, iWinners[], iWinnersCount, Handle:DataPack)
{
	if (StrEqual(sID, GAME_ID)) {
		UnhookEvent("hegrenade_detonate", Event_HEGrenadeDetonate);
	}
}

public Action:Event_HEGrenadeDetonate(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if (!TG_IsCurrentGameID(GAME_ID))
		return Plugin_Continue;

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (TG_IsPlayerRedOrBlue(iClient)) {
		GiveGrenade(iClient);
	}

	return Plugin_Continue;
}

GiveGrenade(iClient)
{
	new iGrenade = GivePlayerItem(iClient, "weapon_hegrenade");

	SetEntProp(iGrenade, Prop_Send, "m_iClip1", 1);

	new iOffset = FindDataMapOffs(iClient, "m_iAmmo") + (GetEntProp(iGrenade, Prop_Data, "m_iPrimaryAmmoType") * 4);
	SetEntData(iClient, iOffset, 1, 4, true);

	if (GetEngineVersion() == Engine_CSGO) {
		SetEntProp(iGrenade, Prop_Send, "m_iPrimaryReserveAmmoCount", 1);
	}
}
