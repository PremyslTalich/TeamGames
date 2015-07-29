#include <sourcemod>
#include <sdkhooks>
#include <smlib>
#include <teamgames>

#define GAME_ID					"DrunkenRambo"
#define DTC_PREFIX_OVERLAY		"DrunkenRambo-Overlay"
#define DTC_PREFIX_SKIN			"DrunkenRambo-Skin"

public Plugin:myinfo =
{
	name = "[TG] DrunkenRambo",
	author = "Raska",
	description = "",
	version = "0.5",
	url = ""
}

new String:g_sOverlay[PLATFORM_MAX_PATH];
new String:g_sSkin[PLATFORM_MAX_PATH];
new String:g_sOriginalSkin[PLATFORM_MAX_PATH];
new g_iRambo;
new EngineVersion:g_iEngVersion;

public OnPluginStart()
{
	LoadTranslations("TG.DrunkenRambo-Raska.phrases");
	g_iEngVersion = GetEngineVersion();
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames") && !TG_IsModuleReged(TG_Game, GAME_ID))
		TG_RegGame(GAME_ID, TG_RedOnly, "%t", "GameName");
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_OnDownloadFile(String:sFile[], String:sPrefixName[], Handle:hArgs, &bool:bKnown)
{
	if (StrEqual(sPrefixName, DTC_PREFIX_OVERLAY, false)) {
		ReplaceStringEx(sFile, PLATFORM_MAX_PATH, "materials/", "");
		PrecacheDecal(sFile, true);
		strcopy(g_sOverlay, sizeof(g_sOverlay), sFile);
		bKnown = true;
	} else if (StrEqual(sPrefixName, DTC_PREFIX_SKIN, false)) {
		PrecacheModel(sFile);
		strcopy(g_sSkin, sizeof(g_sSkin), sFile);
		bKnown = true;
	}
}

public TG_OnMenuGameDisplay(const String:sID[], iClient, String:name[])
{
	if (StrEqual(sID, GAME_ID))
		Format(name, TG_MODULE_NAME_LENGTH, "%T", "GameName", iClient);
}

public TG_OnGameSelected(const String:sID[], iClient)
{
	if (!StrEqual(sID, GAME_ID, true)) 
		return;

	TG_ShowPlayerSelectMenu(iClient, TG_RedTeam, SelectPlayerHandeler, "%T", "ChooseRambo", iClient);
}

public SelectPlayerHandeler(iActivator, iClient, bool:bIsRandom)
{
	if (Client_IsIngame(iClient)) {
		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iClient);
		
		TG_StartGame(iActivator, GAME_ID, "", hDataPack, true);
	}
}

public TG_OnGamePrepare(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{
	if (!StrEqual(sID, GAME_ID, true))
		return;
	
	ResetPack(hDataPack);
	g_iRambo = ReadPackCell(hDataPack);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (TG_GetPlayerTeam(i) != TG_RedTeam)
			continue;
		
		if (i == g_iRambo) {
			SetEntityHealth(i, 10);
			SetFovAndOverlay(i, 120, g_sOverlay);
			
			if (g_sSkin[0] != '\0' && IsModelPrecached(g_sSkin)) {
				GetClientModel(g_iRambo, g_sOriginalSkin, sizeof(g_sOriginalSkin));
				SetEntityModel(g_iRambo, g_sSkin);
			}
			
			switch (g_iEngVersion) {
				case Engine_CSS: {
					GivePlayerWeaponAndAmmo(i, "weapon_m249");
				}
				case Engine_CSGO: {
					GivePlayerWeaponAndAmmo(i, "weapon_m249");
				}
			}
		} else {
			SetEntityHealth(i, 100);
			GivePlayerItem(i, "weapon_knife");
			GivePlayerItem(i, "weapon_taser");
		}
	}
}

public TG_OnPlayerLeaveGame(const String:sID[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (!StrEqual(sID, GAME_ID))
		return;
	
	if (iClient == g_iRambo) {
		new Handle:hWinners = CreateArray();
		
		for (new i = 0; i < MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(hWinners, i);
			}
		}
		
		TG_StopGame(TG_RedTeam, hWinners);
	} else if (iTeam == TG_RedTeam && TG_GetTeamCount(TG_RedTeam) == 1) {
		new Handle:hWinner = CreateArray();
		PushArrayCell(hWinner, g_iRambo);
		
		TG_StopGame(TG_RedTeam, hWinner);
	}
}

public TG_OnGameEnd(const String:sID[], TG_Team:iTeam, iWinners[], iWinnersCount, Handle:DataPack)
{
	if (StrEqual(sID, GAME_ID)) {
		if (g_sSkin[0] != '\0' && IsModelPrecached(g_sSkin) && Client_IsIngame(g_iRambo) && IsPlayerAlive(g_iRambo)) {
			SetEntityModel(g_iRambo, g_sOriginalSkin);
		}
		
		SetFovAndOverlay(g_iRambo, 90, "");
		g_iRambo = 0;
	}
}

SetFovAndOverlay(iClient, iFov, const String:sOverlay[])
{
	if (!Client_IsIngame(iClient))
		return;
	
	SetEntProp(iClient, Prop_Send, "m_iFOV", iFov);
	SetEntProp(iClient, Prop_Send, "m_iDefaultFOV", iFov);
	
	if (sOverlay[0] == '\0' || IsDecalPrecached(sOverlay)) {
		Client_SetScreenOverlay(iClient, sOverlay);
	}
}
