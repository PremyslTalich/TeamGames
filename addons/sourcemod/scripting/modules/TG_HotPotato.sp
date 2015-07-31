#include <sourcemod>
#include <smlib>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID	"HotPotato"

public Plugin:myinfo =
{
	name = "[TG] HotPotato",
	author = "Raska",
	description = "",
	version = "0.3",
	url = ""
}

enum GameInfo
{
	BombEntity,
	VictimEntity,
	Float:VictimSpeed,
	bool:ToLastMan,
	Handle:SlapTimer
}
new g_game[GameInfo];

new Handle:g_hHeathColor, g_bHealthColor;

public OnPluginStart()
{
	LoadTranslations("TG.HotPotato-Raska.phrases");

	g_hHeathColor = CreateConVar("tghp_enablecolor", "1", "Color players in shades of red according to their health level.");

	HookEvent("bomb_pickup",  Event_BombPickUp, EventHookMode_Post);

	ResetGame();

	AutoExecConfig(true, "plugin.TeamGames.TG_HotPotato");
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

public OnConfigsExecuted()
{
	g_bHealthColor = GetConVarBool(g_hHeathColor);
}

public TG_OnGameSelected(const String:id[], iClient)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	ModuleSetTypeGameMenu(iClient);
}

public TG_OnGamePrepare(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	new user = TG_GetRandomClient(TG_RedTeam);

	if (Client_IsIngame(user)) {
		Client_RemoveAllWeapons(user);
		g_game[BombEntity] = Client_GiveWeapon(user, "weapon_c4", true);

		MakeClientVictim(user);
	} else {
		TG_StopGame(TG_NoneTeam);
	}
}

public TG_OnGameStart(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	if (!Client_IsIngame(g_game[VictimEntity]))
		TG_StopGame(TG_NoneTeam);

	g_game[SlapTimer] = CreateTimer(0.2, Timer_SlapClient, _, TIMER_REPEAT);

	return;
}

public Action:Timer_SlapClient(Handle:hTimer)
{
	if (!Client_IsIngame(g_game[VictimEntity]))
		return Plugin_Continue;

	new iClient = g_game[VictimEntity];

	if (g_game[SlapTimer] == INVALID_HANDLE)
		return Plugin_Stop;

	new iOldHealth = GetClientHealth(iClient);
	new iNewHealth = iOldHealth - 2;

	if (iNewHealth <= 0) {
		Client_RemoveAllWeapons(iClient);
		ForcePlayerSuicide(iClient);
	} else {
		SetEntityHealth(iClient, iNewHealth);

		if (g_bHealthColor) {
			if (iNewHealth > 90) {
				SetEntityRenderColor(iClient, 255, 255, 255, 0);
			} else if (iNewHealth > 10) {
				new iColor = RoundToNearest((iNewHealth - 10) * 3.1875);
				SetEntityRenderColor(iClient, 255, iColor, iColor, 0);
			} else {
				SetEntityRenderColor(iClient, 255, 0, 0, 0);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_BombPickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsCurrentGameID(GAME_ID) && TG_GetPlayerTeam(iClient) == TG_RedTeam) {
		RemoveClientVictim(g_game[VictimEntity]);
		MakeClientVictim(iClient);

		new weapon = Client_GetWeapon(iClient, "weapon_c4");
		SetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon", weapon);
	}

	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCrossed(iClient, Float:FreezeTime)
{
	if (g_game[VictimEntity] == iClient)
		return Plugin_Handled;

	return Plugin_Continue;
}

public TG_OnPlayerLeaveGame(const String:id[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	if (Client_IsIngame(iClient)) {
		SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityRenderColor(iClient, 255, 255, 255, 0);
	}


	if (iClient != g_game[VictimEntity])
		return;

	RemoveClientVictim(iClient);

	if (g_game[ToLastMan] && TG_GetTeamCount(TG_RedTeam) > 1 && IsValidEntity(g_game[BombEntity])) {
		new user = TG_GetRandomClient(TG_RedTeam);

		if (Client_IsIngame(user)) {
			Client_RemoveAllWeapons(user);
			g_game[BombEntity] = Client_GiveWeapon(user, "weapon_c4", true);

			MakeClientVictim(user);
		} else {
			TG_StopGame(TG_NoneTeam);
		}
	} else {
		g_game[SlapTimer] = INVALID_HANDLE;

		new Handle:hWinners = CreateArray();
		for (new i = 1; i <= MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(hWinners, i);
			}
		}

		TG_StopGame(TG_RedTeam, hWinners);
	}
}

public TG_OnGameEnd(const String:id[], TG_Team:iTeam, winners[], winnersCount)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	ResetGame();

	return;
}

ModuleSetTypeGameMenu(iClient)
{
	new Handle:menu = CreateMenu(ModuleSetTypeGameMenu_Handler);

	SetMenuTitle(menu, "%T", "Menu-Title", iClient, "GameName");
	AddMenuItemFormat(menu, "Menu-OneDeath", _, "%T", "Menu-OneDeath", iClient);
	AddMenuItemFormat(menu, "Menu-LastManStanding", _, "%T", "Menu-LastManStanding", iClient);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, iClient, 30);
}

public ModuleSetTypeGameMenu_Handler(Handle:menu, MenuAction:iAction, iClient, iKey)
{
	if (iAction == MenuAction_Select) {
		decl String:info[TG_MODULE_ID_LENGTH], String:GameSettings[TG_GAME_SETTINGS_LENGTH];

		GetMenuItem(menu, iKey, info, sizeof(info));
		Format(GameSettings, sizeof(GameSettings), "%t", info);

		if (StrEqual(info, "Menu-OneDeath")) {
			g_game[ToLastMan] = false;
		} else {
			g_game[ToLastMan] = true;
		}

		TG_ShowPlayerSelectMenu(iClient, TG_RedTeam, SelectPlayerHandeler, "%T", "Menu-ChooseFirstPotato", iClient);
	}
}

public SelectPlayerHandeler(activator, iClient, bool:IsRandom)
{
	if (Client_IsIngame(iClient)) {
		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iClient);

		TG_StartGame(activator, GAME_ID, "", hDataPack, _, _, false);
	}
}

MakeClientVictim(iClient)
{
	if (g_game[VictimEntity] == iClient)
		return;

	g_game[VictimEntity] = iClient;
	SetEntPropFloat(g_game[VictimEntity], Prop_Data, "m_flLaggedMovementValue", g_game[VictimSpeed]);

	if (GetPlayerWeaponSlot(iClient, 4) != g_game[BombEntity]) {
		new Float:pos[3];
		GetClientAbsOrigin(iClient, pos);
	}

	TG_LogGameMessage(GAME_ID, _, "Player %N has hot potato.", iClient);
}

RemoveClientVictim(iClient)
{
	g_game[VictimEntity] = 0;

	if (Client_IsIngame(iClient))
		SetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue", 1.0);
}

ResetGame()
{
	if (IsValidEntity(g_game[BombEntity]))
		RemoveEdict(g_game[BombEntity]);

	g_game[BombEntity] = -1;
	g_game[VictimEntity] = -1;
	g_game[VictimSpeed] = 1.1;
	g_game[ToLastMan] = false;
	g_game[SlapTimer] = INVALID_HANDLE;
}