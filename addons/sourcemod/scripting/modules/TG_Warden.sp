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

new Handle:g_hAdmins, Handle:g_hMenu, Handle:g_hTeams, Handle:g_hGames, Handle:g_hMarks, Handle:g_hFences;

public OnPluginStart()
{
	LoadTranslations("TG.Warden.phrases");

	g_hAdmins = 		CreateConVar("sm_tg_warden_admins", 		"1", 	"Treat admins as warden.");
	g_hMenu = 			CreateConVar("sm_tg_warden_menu", 			"1", 	"Only warden can use TG menu.");
	g_hTeams = 			CreateConVar("sm_tg_warden_teams", 			"1", 	"Only warden can use TG teams.");
	g_hGames = 			CreateConVar("sm_tg_warden_games", 			"1", 	"Only warden can use TG games.");
	g_hMarks = 			CreateConVar("sm_tg_warden_marks", 			"1", 	"Only warden can use TG marks.");
	g_hFences = 		CreateConVar("sm_tg_warden_fences", 		"1", 	"Only warden can use TG fence.");
}

public Action:TG_OnMenuDisplay(client)
{
	if (GetConVarBool(g_hMenu) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnGameStartMenu(const String:id[], client, const String:gameSettings[], Handle:dataPack)
{
	if (GetConVarBool(g_hGames) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnMenuSelect(TG_ModuleType:type, const String:id[], client)
{
	if ((type == TG_Game || StrContains(id, "Core_GamesMenu", false) == 0) && GetConVarBool(g_hGames) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "%t", "AccessDenied");
		return Plugin_Handled;
	}

	if (StrEqual(id, "Core_FencesMenu") && GetConVarBool(g_hFences) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "%t", "AccessDenied");
		return Plugin_Handled;
	}

	if (StrEqual(id, "Core_TeamsMenu") && GetConVarBool(g_hTeams) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnMarkSpawn(client, TG_Team:team, Float:position[3], Float:life)
{
	if (GetConVarBool(g_hMarks) && !CheckWardenAccess(client)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCreate(client, Float:a[3], Float:c[3])
{
	if (GetConVarBool(g_hFences) && !CheckWardenAccess(client)) {
		CPrintToChat(client, "%t", "AccessDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool:CheckWardenAccess(iClient)
{
	return (warden_iswarden(iClient) || (GetConVarBool(g_hAdmins) && CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)));
}
