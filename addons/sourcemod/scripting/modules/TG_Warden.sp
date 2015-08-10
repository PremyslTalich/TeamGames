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

public OnPluginStart()
{
	LoadTranslations("TG.Warden.phrases");
}

public Action:TG_OnMenuDisplay(iClient)
{
	// admin access
	if (CheckCommandAccess(iClient, "sm_teamgames", ADMFLAG_GENERIC)) {
		return Plugin_Continue;
	}
	
	// player is not warden
	if (!warden_iswarden(iClient)) {
		CPrintToChat(iClient, "{error}%t", "MenuDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
