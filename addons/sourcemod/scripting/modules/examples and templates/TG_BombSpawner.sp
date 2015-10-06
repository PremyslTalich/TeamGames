#include <sourcemod>
#include <teamgames>

#define ITEM_ID	"BombSpawner-Raska"

public Plugin:myinfo =
{
	name = "[TG] BombSpawner",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("TG.BombSpawner.phrases");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames")) {
		if (!TG_IsModuleReged(TG_MenuItem, ITEM_ID)) {
			TG_RegMenuItem(ITEM_ID);
		}
	}
}

public OnPluginEnd()
{
	TG_RemoveMenuItem(ITEM_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type == TG_MenuItem && StrEqual(id, ITEM_ID)) {
		Format(name, maxSize, "%T", "SpawnBomb", client);
		
		if (GetClientHealth(client) < 50) {
			status = TG_Inactive;
		}
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], client)
{
	if (type == TG_MenuItem && StrEqual(id, ITEM_ID)) {
		new Float:position[3];
		GetClientAbsOrigin(client, position);
		
		new bomb = CreateEntityByName("weapon_c4");		
		if (bomb != INVALID_ENT_REFERENCE) {
			DispatchSpawn(bomb);
			TeleportEntity(bomb, position, NULL_VECTOR, NULL_VECTOR);
		}
	}
}