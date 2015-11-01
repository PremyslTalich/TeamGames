#define MAX_MENU_ITEMS 64
#define MAX_GAMES 64

new Handle:g_hTimer_CountDownGamePrepare = INVALID_HANDLE;
new g_iTimer_CountDownGamePrepare_counter = 4;

enum gamestatusinfo
{
	TG_GameProgress:GameProgress,
	String:GameID[TG_MODULE_ID_LENGTH],
	String:DefaultName[TG_MODULE_NAME_LENGTH],
	TG_GameType:GameType,
	String:GameSettings[TG_GAME_SETTINGS_LENGTH],
	Handle:GameDataPack,
	bool:RemoveDrops,
	bool:EndOnTeamEmpty,
	GameStarter,
	RedTeam[MAXPLAYERS + 1],
	BlueTeam[MAXPLAYERS + 1]
}
new g_Game[gamestatusinfo];

new String:g_sDisabledModulesList[MAX_MENU_ITEMS + MAX_GAMES][TG_MODULE_ID_LENGTH + 12];
new g_iDisabledModulesListEnd = 0;

AddModuleToDisabledList(TG_ModuleType:iType, const String:sID[])
{
	if (g_iDisabledModulesListEnd + 1 < MAX_MENU_ITEMS + MAX_GAMES) {
		new String:m_sID[TG_MODULE_ID_LENGTH + 12];
		Format(m_sID, sizeof(m_sID), "%s-%s", (iType == TG_MenuItem) ? "TG_MenuItem" : "TG_Game", sID);
		strcopy(g_sDisabledModulesList[g_iDisabledModulesListEnd], TG_MODULE_ID_LENGTH + 12, m_sID);

		g_iDisabledModulesListEnd++;
	}
}

bool:IsModuleDisabled(TG_ModuleType:iType, const String:sID[])
{
	if (g_iDisabledModulesListEnd == 0) {
		return false;
	}

	new String:m_sID[TG_MODULE_ID_LENGTH + 12];
	Format(m_sID, sizeof(m_sID), "%s-%s", (iType == TG_MenuItem) ? "TG_MenuItem" : "TG_Game", sID);

	for (new i = 0; i < g_iDisabledModulesListEnd; i++) {
		if (StrEqual(g_sDisabledModulesList[i], m_sID)) {
			return true;
		}
	}

	return false;
}

ClearGameStatusInfo()
{
	g_Game[GameProgress] = TG_NoGame;
	g_Game[GameType] = TG_FiftyFifty;
	strcopy(g_Game[GameID], TG_MODULE_ID_LENGTH, "Core_NoGame");
	strcopy(g_Game[DefaultName], TG_MODULE_ID_LENGTH, "Core_NoGame");
	strcopy(g_Game[GameSettings], TG_MODULE_NAME_LENGTH, "");

	if (g_Game[GameDataPack] != INVALID_HANDLE) {
		CloseHandle(g_Game[GameDataPack]);
		g_Game[GameDataPack] = INVALID_HANDLE;
	}

	g_Game[RemoveDrops] = false;
	g_Game[EndOnTeamEmpty] = true;
	g_Game[GameStarter] = 0;
	g_Game[RedTeam][0] = 0;
	g_Game[BlueTeam][0] = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (Client_IsIngame(i))
			SDKUnhook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
	}
}

enum MenuItemStruct
{
	bool:Used,
	bool:Visible,
	String:Id[TG_MODULE_ID_LENGTH],
    String:DefaultName[TG_MODULE_NAME_LENGTH],
    Separator
}
new g_MenuItemList[MAX_MENU_ITEMS][MenuItemStruct];
new g_iMenuItemListEnd = 0;

enum GameStruct
{
	bool:Used,
	bool:Visible,
	String:Id[TG_MODULE_ID_LENGTH],
    String:DefaultName[TG_MODULE_NAME_LENGTH],
    TG_GameType:GameType,
	Separator
}
new g_GameList[MAX_GAMES][GameStruct];
new g_iGameListEnd = 0;

bool:ExistMenuItem(const String:sID[])
{
	if (GetMenuItemIndex(sID) != -1)
		return true;

	return false;
}

bool:ExistGame(const String:sID[])
{
	if (GetGameIndex(sID) != -1)
		return true;

	return false;
}

GetMenuItemIndex(const String:sID[], bool:bOnlyRunning = true)
{
	for (new i = 0; i < MAX_MENU_ITEMS; i++) {
		if (!g_MenuItemList[i][Used] && bOnlyRunning)
			continue;

		if (StrEqual(g_MenuItemList[i][Id], sID))
			return i;
	}

	return -1;
}

GetGameIndex(const String:sID[], bool:bOnlyRunning = true)
{
	for (new i = 0; i < MAX_GAMES; i++) {
		if (!g_GameList[i][Used] && bOnlyRunning)
			continue;

		if (StrEqual(g_GameList[i][Id], sID))
			return i;
	}

	return -1;
}

GetCountAllGames()
{
	new iCount = 0;

	for (new i = 0; i < MAX_GAMES; i++) {
		if (!g_GameList[i][Used])
			continue;

		iCount++;
	}

	return iCount;
}

RemoveAllTGMenuItems()
{
	for (new i = 0; i < MAX_MENU_ITEMS; i++)
		g_MenuItemList[i][Used] = false;
}

RemoveAllGames()
{
	for (new i = 0; i < MAX_GAMES; i++)
		g_GameList[i][Used] = false;
}

bool:IsGameTypeAvailable(TG_GameType:iType)
{
	if (iType == TG_FiftyFifty) {
		new iRed = GetCountPlayersInTeam(TG_RedTeam);
		new iBlue = GetCountPlayersInTeam(TG_BlueTeam);

		if (GetConVarBool(g_hCheckTeams)) {
			return (iRed == iBlue && iRed > 0);
		} else {
			return (iRed > 0 && iBlue > 0);
		}
	} else if (iType == TG_RedOnly) {
		return (GetCountPlayersInTeam(TG_RedTeam) >= 2 && GetCountPlayersInTeam(TG_BlueTeam) == 0);
	}

	return false;
}

ListGames(iClient)
{
	PrintToConsoleOrServer(iClient, "\n[TeamGames] Games list");
	PrintToConsoleOrServer(iClient, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+");
	PrintToConsoleOrServer(iClient, "|     | Game ID                                                          | Default game name                                                |");
	PrintToConsoleOrServer(iClient, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+");

	new iIndex = 1;

	for (new i = 0; i < MAX_GAMES; i++) {
		if (!g_GameList[i][Used])
			continue;

		PrintToConsoleOrServer(iClient, "| #%2d | %64s | %64s", iIndex, g_GameList[i][Id], g_GameList[i][DefaultName]);
		iIndex++;
	}

	PrintToConsoleOrServer(iClient, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+\n");
}

ListMenuItems(iClient)
{
	PrintToConsoleOrServer(iClient, "\n[TeamGames] Menu items list");
	PrintToConsoleOrServer(iClient, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+");
	PrintToConsoleOrServer(iClient, "|     | Menu item ID                                                     | Default menu item name                                           |");
	PrintToConsoleOrServer(iClient, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+");

	new iIndex = 1;

	for (new i = 0; i < MAX_MENU_ITEMS; i++) {
		if (!g_MenuItemList[i][Used])
			continue;

		PrintToConsoleOrServer(iClient, "| #%2d | %64s | %64s", iIndex, g_MenuItemList[i][Id], g_MenuItemList[i][DefaultName]);
		iIndex++;
	}

	PrintToConsoleOrServer(iClient, "+-----+------------------------------------------------------------------+------------------------------------------------------------------+\n");
}

PrintToConsoleOrServer(iClient, const String:format[], any:...)
{
	decl String:sMsg[256];
	VFormat(sMsg, sizeof(sMsg), format, 3);

	if (Client_IsValid(iClient))
		PrintToConsole(iClient, sMsg);
	else
		PrintToServer(sMsg);
}
