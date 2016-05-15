#include <sourcemod>
#include <teamgames>

#define ITEM_ID "MENU_ITEM_ID"

public Plugin:myinfo =
{
	name = "[TG] ",
	author = "",
	description = "",
	version = "",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.MENU_ITEM.phrases");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames"))
		TG_RegMenuItem(ITEM_ID);
}

public OnPluginEnd()
{
	TG_RemoveMenuItem(ITEM_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type != TG_MenuItem || !StrEqual(id, ITEM_ID))
		return;

	Format(name, maxSize, "%T", "ItemName", client);

	// if (something) {
		// status = TG_Inactive;
	// }
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if (type != TG_MenuItem || !StrEqual(id, ITEM_ID))
		return;

	// code here
}
