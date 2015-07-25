public Action:Hook_TextMsg(UserMsg:iMsgId, Handle:hMsg, const iPlayers[], iPlayersNum, bool:bReliable, bool:bInit)
{
	new String:sBuffer[512];
	
	if (GetUserMessageType() == UM_Protobuf) {
		PbReadString(hMsg, "params", sBuffer, sizeof(sBuffer), 0);
	} else {
		BfReadString(hMsg, sBuffer, sizeof(sBuffer), false);
	}
	
	if (StrContains(sBuffer, "#SFUI_Notice_Killed_Teammate") != -1)
		return Plugin_Handled;
	
	if (StrContains(sBuffer, "#Cstrike_TitlesTXT_Game_teammate_attack") != -1)
		return Plugin_Handled;
	
	if (StrContains(sBuffer, "#Hint_try_not_to_injure_teammates") != -1)
		return Plugin_Handled;
	
	if (StrContains(sBuffer, "#Player_Cash_Award_Kill_Teammate") != -1)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:OnChatMessage(&iAuthor, Handle:hRecipients, String:sName[], String:sMessage[])
{
	if (!g_bAllowTeamPrefix)
		return Plugin_Continue;
	
	if (g_PlayerData[iAuthor][Team] == TG_RedTeam) {
		Format(sName, MAXLENGTH_NAME, "{tg-redteam}%t \x03%s", "TeamPrefix-RedTeam", sName);
		CProcessVariables(sName, MAXLENGTH_NAME);
		CAddWhiteSpace(sName, MAXLENGTH_NAME);
		return Plugin_Changed;
	} else if (g_PlayerData[iAuthor][Team] == TG_BlueTeam) {
		Format(sName, MAXLENGTH_NAME, "{tg-blueteam}%t \x03%s", "TeamPrefix-BlueTeam", sName);
		CProcessVariables(sName, MAXLENGTH_NAME);
		CAddWhiteSpace(sName, MAXLENGTH_NAME);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public bool:TGMultiTargetTeam(const String:sPattern[], Handle:hClients) {
    
	new TG_Team:iTeam;
	
	if (StrEqual(sPattern, "@r", false))
		iTeam = TG_RedTeam;
	else if (StrEqual(sPattern, "@b", false))
		iTeam = TG_BlueTeam;
	else if (StrEqual(sPattern, "@n", false))
		iTeam = TG_NoneTeam;
	else
		return false;
	
	for (new i = 1; i <= MaxClients; i++) {
		if (TG_GetPlayerTeam(i) == iTeam) {
			PushArrayCell(hClients, i);			
		}
   }
	
	return true;
}

public bool:TGMultiTargetBoth(const String:sPattern[], Handle:hClients) {
    
	for (new i = 1; i <= MaxClients; i++) {
		if (TG_IsPlayerRedOrBlue(i)) {
			PushArrayCell(hClients, i);
		}
	}
	
	return true;
}

public COnForwardedVariable(String:sCode[], String:sData[], iDataSize, String:sColor[], iColorSize)
{
	if (StrEqual(sCode, "tg-player", false)) {
		switch (TG_GetPlayerTeam(StringToInt(sData))) {
			case TG_NoneTeam: {CGetColor("tg-noneteam", sColor, iColorSize);}
			case TG_RedTeam: {CGetColor("tg-redteam", sColor, iColorSize);}
			case TG_BlueTeam: {CGetColor("tg-blueteam", sColor, iColorSize);}
			default: {CGetColor("default", sColor, iColorSize);}
		}
	} else if (StrEqual(sCode, "tg-team", false)) {
		switch (TG_GetTeamFromString(sData)) {
			case TG_NoneTeam: {CGetColor("tg-noneteam", sColor, iColorSize);}
			case TG_RedTeam: {CGetColor("tg-redteam", sColor, iColorSize);}
			case TG_BlueTeam: {CGetColor("tg-blueteam", sColor, iColorSize);}
			default: {CGetColor("default", sColor, iColorSize);}
		}
	}	
}
