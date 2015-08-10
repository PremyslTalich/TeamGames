#include <sourcemod>
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

new Handle:g_hMenuFlag, String:g_sMenuFlag[16];

public OnPluginStart()
{
	LoadTranslations("TG.Warden.phrases");
}

public OnConfigsExecuted()
{
	g_hMenuFlag = FindConVar("tg_menu_adminflag_allow");

	if (g_hMenuFlag != INVALID_HANDLE) {
		GetConVarString(g_hMenuFlag, g_sMenuFlag, sizeof(g_sMenuFlag));
	} else {
		strcopy(g_sMenuFlag, sizeof(g_sMenuFlag), "");
	}

}

public Action:TG_OnMenuDisplay(client)
{
	// admin access
	if (g_sMenuFlag[0] != '\0' && TG_HasPlayerAdminAccess(client, g_sMenuFlag)) {
		return Plugin_Continue;
	}

	// player is not warden
	if (!warden_iswarden(client)) {
		TG_PrintToChat(client, "%t", "MenuDenied");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
