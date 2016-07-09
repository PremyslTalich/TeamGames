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
	version = "0.5",
	url = ""
}

new Handle:g_hMenu, Handle:g_hTeams, Handle:g_hGames, Handle:g_hMarks, Handle:g_hFences;

public OnPluginStart()
{
	LoadTranslations("TG.Warden.phrases");

	g_hMenu = 	CreateConVar("tgm_warden_menu", 	"1", "0 = Everyone can use TG menu.\n1 = Only warden can use TG menu.\n2 = Only warden and admins with access to sm_teamgames can use TG menu.");
	g_hTeams = 	CreateConVar("tgm_warden_teams", 	"1", "0 = Everyone can use TG teams.\n1 = Only warden can use TG teams.\n2 = Only warden and admins with access to sm_teamgames can use TG teams.");
	g_hGames = 	CreateConVar("tgm_warden_games", 	"1", "0 = Everyone can use TG games.\n1 = Only warden can use TG games.\n2 = Only warden and admins with access to sm_teamgames can use TG games.");
	g_hMarks = 	CreateConVar("tgm_warden_marks", 	"1", "0 = Everyone can use TG marks.\n1 = Only warden can use TG marks.\n2 = Only warden and admins with access to sm_teamgames can use TG marks.");
	g_hFences = CreateConVar("tgm_warden_fences", 	"1", "0 = Everyone can use TG fences.\n1 = Only warden can use TG fences.\n2 = Only warden and admins with access to sm_teamgames can use TG fences.");

	AutoExecConfig(_, _, "sourcemod/teamgames");
}

public Action:TG_OnMenuDisplay(client)
{
	if (GetConVarBool(g_hMenu) && !CheckWardenAccess(client, g_hMenu)) {
		PrintClientAccessDenied(client)
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnGameStartMenu(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!CheckWardenAccess(client, g_hGames)) {
		PrintClientAccessDenied(client)
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnMenuSelect(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if ((type == TG_Game || StrContains(id, "Core_GamesMenu", false) == 0) && !CheckWardenAccess(client, g_hGames)) {
		PrintClientAccessDenied(client)
		return Plugin_Handled;
	}

	if (StrEqual(id, "Core_FencesMenu") && !CheckWardenAccess(client, g_hFences)) {
		PrintClientAccessDenied(client)
		return Plugin_Handled;
	}

	if (StrEqual(id, "Core_TeamsMenu") && !CheckWardenAccess(client, g_hTeams)) {
		PrintClientAccessDenied(client)
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnPlayerTeam(client, activator, TG_Team:teamBefore, TG_Team:teamAfter)
{
	if (activator < 1 || activator > MaxClients || !IsClientInGame(activator)) {
		return Plugin_Continue;
	}

	if (!CheckWardenAccess(activator, g_hTeams)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnMarkSpawn(client, TG_Team:team, Float:position[3], Float:life)
{
	if (!CheckWardenAccess(client, g_hMarks)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCreate(client, Float:a[3], Float:c[3])
{
	if (!CheckWardenAccess(client, g_hFences)) {
		PrintClientAccessDenied(client)
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool:CheckWardenAccess(iClient, Handle:hConVar)
{
	new iAccess = GetConVarInt(hConVar);

	if (iAccess == 0)
		return true;

	if ((iAccess == 1 || iAccess == 2) && warden_iswarden(iClient))
		return true;

	if (iAccess == 2 && CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC))
		return true;

	return false;
}

PrintClientAccessDenied(iClient)
{
	CPrintToChat(iClient, "%t", "AccessDenied");
}