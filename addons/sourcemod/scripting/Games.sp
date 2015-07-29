new String:g_sGamePrepare[6][PLATFORM_MAX_PATH];
new String:g_sGameEnd[3][PLATFORM_MAX_PATH];
new String:g_sGameStart[PLATFORM_MAX_PATH];

GamesMenu(iClient, TG_GameType:iType = TG_All_)
{
	if (GetCountAllGames() > 0) {
		new Handle:hMenu = CreateMenu(GamesMenu_Handler);
		new String:sName[TG_MODULE_NAME_LENGTH];
		
		SetMenuTitle(hMenu, "%T", "MenuGames-Title", iClient);
		
		for (new i = 0; i < g_iGameListEnd; i++) {
			if (!g_GameList[i][Used] || !g_GameList[i][Visible])
				continue;
			
			if (g_GameList[i][GameType] != iType && iType != TG_All_)
				continue;
			
			if (!TG_CheckModuleAccess(iClient, TG_Game, g_GameList[i][Id]))
				continue;
			
			strcopy(sName, sizeof(sName), g_GameList[i][DefaultName]);
			
			Call_StartForward(Forward_OnMenuGameDisplay);
			Call_PushString(g_GameList[i][Id]);
			Call_PushCell(iClient);
			Call_PushStringEx(sName, sizeof(sName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_Finish();
			
			AddSeperatorToMenu(hMenu, g_GameList[i][Separator], -1);
			
			if (g_GameList[i][GameType] == TG_RedOnly && iType != TG_RedOnly)
				Format(sName, sizeof(sName), "%s (%T)", sName, "MenuGames-RedOnlyHint", iClient);
			
			if (IsGameTypeAvailable(g_GameList[i][GameType]))
				AddMenuItem(hMenu, g_GameList[i][Id], sName);
			else
				AddMenuItem(hMenu, g_GameList[i][Id], sName, ITEMDRAW_DISABLED);
			
			AddSeperatorToMenu(hMenu, g_GameList[i][Separator], -1);
		}
		
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, iClient, 30);
	}
}

public GamesMenu_Handler(Handle:hMenu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		decl String:sKey[TG_MODULE_ID_LENGTH];
		GetMenuItem(hMenu, iKey, sKey, sizeof(sKey));
		
		#if defined DEBUG
		LogMessage("[TG DEBUG] Player %L selected game (id = '%s').", iClient, sKey);
		#endif
		
		new Action:result = Plugin_Continue;
		Call_StartForward(Forward_OnGameSelect);
		Call_PushString(sKey);
		Call_PushCell(iClient);
		Call_Finish(result);
		if (result != Plugin_Continue)
			return;
		
		Call_StartForward(Forward_OnGameSelected);
		Call_PushString(sKey);
		Call_PushCell(iClient);
		Call_Finish();		
	} else if (iAction == MenuAction_Cancel && iKey == MenuCancel_ExitBack) {
		MainMenu(iClient);
	}
}

TG_GameType:GetGameTypeByName(String:sTypeStr[])
{
	if (StrEqual(sTypeStr, "FiftyFifty", false))
		return TG_FiftyFifty;
	else if (StrEqual(sTypeStr, "RedOnly", false))
		return TG_RedOnly;
	else
		return TG_All_;
}

public TG_OnTeamEmpty(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (g_Game[GameProgress] != TG_NoGame && g_Game[EndOnTeamEmpty]) {
		if (g_Game[GameType] == TG_FiftyFifty) {
			TG_StopGame(TG_GetOppositeTeam(iTeam));
		} else if (g_Game[GameType] == TG_RedOnly && iTeam == TG_RedTeam) {
			TG_StopGame(TG_RedTeam);
		}
	}
}

public TG_OnPlayerLeaveGame(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (g_Game[RemoveDrops]) {
		SDKUnhook(iClient, SDKHook_WeaponDrop, Hook_WeaponDrop);
	}
	
	if (g_Game[GameType] == TG_RedOnly && g_Game[EndOnTeamEmpty] && iTeam == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:hWinner = CreateArray();
		for (new i = 0; i < MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(hWinner, i);
				break;
			}
		}
		
		TG_StopGame(TG_RedTeam, hWinner);
	}
}
