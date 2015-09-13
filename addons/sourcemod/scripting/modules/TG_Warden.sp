// Warden plugin: https://forums.alliedmods.net/showthread.php?p=1476638

#include <sourcemod>
#include <colorvariables>
#include <teamgames>
#include <warden>

public Plugin:myinfo =
{
	name = "[TG] Warden",
	author = "Raska",
	description = "",
	version = "0.2",
	url = ""
}

new Handle:g_hMark, Handle:g_hFence;

public OnPluginStart()
{
	LoadTranslations("TG.Warden.phrases");

	g_hMark = CreateConVar("sm_tg_warden_mark", "1", "Only warden can use TG marks.");
	g_hFence = CreateConVar("sm_tg_warden_fence", "1", "Only warden can use TG fence.");
}

public Action:TG_OnMenuDisplay(client)
{
	if (!CheckWardenAccess(client)) {
		CPrintToChat(client, "{error}%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnGameStartMenu(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (!CheckWardenAccess(client)) {
		CPrintToChat(client, "{error}%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnMenuSelect(TG_ModuleType:type, const String:id[], client)
{
	if (!CheckWardenAccess(client)) {
		CPrintToChat(client, "{error}%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnMarkSpawn(client, TG_Team:team, Float:position[3], Float:life)
{
	if (GetConVarBool(g_hMark) && !CheckWardenAccess(client)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCreate(client, Float:a[3], Float:c[3])
{
	if (GetConVarBool(g_hFence) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "{error}%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool:CheckWardenAccess(iClient)
{
	return (CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC) || warden_iswarden(iClient));
}
