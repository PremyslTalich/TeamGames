#include <sourcemod>
#include <smlib>
#include <dtc>
#include <sdkhooks>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID				"HotPotato"
#define DOWNLOAD_POTATO		"HotPotato"
#define DOWNLOAD_BEAM		"HotPotato-beam"
#define DOWNLOAD_HEALTHBAR	"HotPotato-healthbar"

public Plugin:myinfo =
{
	name = "[TG] HotPotato",
	author = "Raska",
	description = "",
	version = "0.5",
	url = ""
}

enum HealhBar
{
	bool:Used,
	String:Sprite[PLATFORM_MAX_PATH],
	String:Color[12],
	Alpha,
	Float:Offset,
	Float:Scale
};

new bool:g_bToLastMan;
new g_iVictim, Handle:g_hVictimSpeed, Handle:g_hHeathCheck;
new Handle:g_hDamage, Handle:g_hDamageTimer, Handle:g_hDamageInterval;
new g_iPotato, String:g_sPotatoModel[PLATFORM_MAX_PATH];
new g_iBeam, String:g_sBeamModel[PLATFORM_MAX_PATH], Float:g_fBeamWidth, g_iBeamColor[4];

public OnPluginStart()
{
	LoadTranslations("TG.HotPotato.phrases");

	g_hHeathCheck = 	CreateConVar("tgm_hotpotato_healthcheck", 	 "2", 	"0 = Nothing\n1 = Color players in shades of red according to their health level.\n2 = Show healthbar above players.");
	g_hDamage = 		CreateConVar("tgm_hotpotato_damage", 		 "2", 	"Amount of damage to deal to victim");
	g_hDamageInterval = CreateConVar("tgm_hotpotato_damageinterval", "0.2", "Interval between dealing damage to victim", _, true, 0.1, true, 10.0);
	g_hVictimSpeed = 	CreateConVar("tgm_hotpotato_victimspeed", 	 "1.1", "Set speed of victim (in percent)");

	HookEvent("bomb_pickup",  Event_BombPickUp, EventHookMode_Post);

	ResetGame();

	AutoExecConfig(_, _, "sourcemod/teamgames");
}

public OnLibraryAdded(const String:sName[])
{
	if (StrEqual(sName, "TeamGames"))
		TG_RegGame(GAME_ID, TG_RedOnly);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], maxSize, &TG_MenuItemStatus:status)
{
	if (type == TG_Game && StrEqual(id, GAME_ID))
		Format(name, maxSize, "%T", "GameName", client);
}

public TG_OnDownloadFile(String:sFile[], String:sPrefixName[], Handle:hArgs, &bool:bKnown)
{
	if (StrEqual(sPrefixName, DOWNLOAD_POTATO, false)) {
		PrecacheModel(sFile);
		strcopy(g_sPotatoModel, sizeof(g_sPotatoModel), sFile);

		bKnown = true;
	} else if (StrEqual(sPrefixName, DOWNLOAD_BEAM, false)) {
		PrecacheModel(sFile);
		strcopy(g_sBeamModel, sizeof(g_sBeamModel), sFile);

		g_fBeamWidth = DTC_GetArgFloat(hArgs, 1, 1.0);
		g_iBeamColor[0] = DTC_GetArgNum(hArgs, 2, 255);
		g_iBeamColor[1] = DTC_GetArgNum(hArgs, 3, 255);
		g_iBeamColor[2] = DTC_GetArgNum(hArgs, 4, 255);
		g_iBeamColor[3] = DTC_GetArgNum(hArgs, 5, 255);

		bKnown = true;
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], iClient)
{
	if (StrEqual(id, GAME_ID) && type == TG_Game)
		ModuleSetTypeGameMenu(iClient);
}

public TG_OnGamePrepare(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	ResetPack(DataPack);
	new iUser = ReadPackCell(DataPack);

	if (Client_IsIngame(iUser)) {
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!TG_IsPlayerRedOrBlue(i) || !Client_IsIngame(i))
				continue;

			SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);

			if (GetConVarInt(g_hHeathCheck) == 2) {
				TG_AttachPlayerHealthBar(i);
			}
		}
		MakeClientVictim(iUser, true);
	} else {
		TG_StopGame(TG_NoneTeam);
	}
}

public TG_OnGameStart(const String:id[], iClient, const String:GameSettings[], Handle:DataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	if (!Client_IsIngame(g_iVictim))
		TG_StopGame(TG_NoneTeam);

	g_hDamageTimer = CreateTimer(GetConVarFloat(g_hDamageInterval), Timer_SlapClient, _, TIMER_REPEAT);

	return;
}

public Action:Hook_WeaponDrop(iClient, iWeapon)
{
	if (TG_IsCurrentGameID(GAME_ID) && iClient == g_iVictim && iWeapon == g_iPotato) {
		if (TG_GetGameStatus() == TG_InPreparation) {
			return Plugin_Handled;
		} else {
			RequestFrame(Frame_DropedPotato);
		}
	}

	return Plugin_Continue;
}

public Frame_DropedPotato(any:data)
{
	if (IsValidEntity(g_iPotato)) {

		if (ExistBeam()) {
			DispatchKeyValue(g_iPotato, "targetname", "TG_HotPotato-Bomb");
			ActivateEntity(g_iBeam);
			AcceptEntityInput(g_iBeam, "TurnOn");
		}
	}
}

public Action:Timer_SlapClient(Handle:hTimer)
{
	if (!Client_IsIngame(g_iVictim))
		return Plugin_Continue;

	new iClient = g_iVictim;

	if (g_hDamageTimer == INVALID_HANDLE)
		return Plugin_Stop;

	new iOldHealth = GetClientHealth(iClient);
	new iNewHealth = iOldHealth - GetConVarInt(g_hDamage);

	if (iNewHealth <= 0) {
		Client_RemoveAllWeapons(iClient);
		ForcePlayerSuicide(iClient);
	} else {
		SetEntityHealth(iClient, iNewHealth);

		if (GetConVarInt(g_hHeathCheck) == 1) {
			if (iNewHealth > 90) {
				SetEntityRenderColor(iClient, 255, 255, 255, 0);
			} else if (iNewHealth > 10) {
				new iColor = RoundToNearest((iNewHealth - 10) * 3.1875);
				SetEntityRenderColor(iClient, 255, iColor, iColor, 0);
			} else {
				SetEntityRenderColor(iClient, 255, 0, 0, 0);
			}
		} else if (GetConVarInt(g_hHeathCheck) == 2) {
			TG_UpdatePlayerHealthBar(iClient);
		}
	}

	return Plugin_Continue;
}

public Action:Event_BombPickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsCurrentGameID(GAME_ID) && TG_GetPlayerTeam(iClient) == TG_RedTeam) {
		if (iClient == g_iVictim) {
			if (ExistBeam())
				AcceptEntityInput(g_iBeam, "TurnOff");
		} else {
			MakeClientVictim(iClient, false);
			SetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon", g_iPotato);
		}
	}

	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCross(iClient, Float:FreezeTime)
{
	if (g_iVictim == iClient)
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

	SDKUnhook(iClient, SDKHook_WeaponDrop, 		 Hook_WeaponDrop);

	if (iClient != g_iVictim)
		return;

	if (IsValidEntity(g_iPotato)) {
		RemoveEdict(g_iPotato);
		g_iPotato = -1;
	}

	RemoveClientVictim();

	if (g_bToLastMan && TG_GetTeamCount(TG_RedTeam) > 1) {
		new user = TG_GetRandomClient(TG_RedTeam);

		if (Client_IsIngame(user)) {
			MakeClientVictim(user, true);
		} else {
			TG_StopGame(TG_NoneTeam);
		}
	} else {
		g_hDamageTimer = INVALID_HANDLE;

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

	SetMenuTitle(menu, "%T - %T", "GameName", iClient, "Menu-Title", iClient);
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
			g_bToLastMan = false;
		} else {
			g_bToLastMan = true;
		}

		TG_ShowPlayerSelectMenu(iClient, SelectPlayerHandeler, true, false, true, "%T", "Menu-ChooseFirstPotato", iClient);
	}
}

public SelectPlayerHandeler(activator, iClient, bool:IsRandom)
{
	if (Client_IsIngame(iClient)) {
		new String:sSettings[48];
		new Handle:hDataPack = CreateDataPack();

		Format(sSettings, sizeof(sSettings), "%t", (g_bToLastMan) ? "Menu-LastManStanding" : "Menu-OneDeath");
		WritePackCell(hDataPack, iClient);

		TG_StartGame(activator, GAME_ID, sSettings, hDataPack, _, _, false);
	}
}

MakeClientVictim(iClient, bool:bGiveBomb)
{
	if (g_iVictim == iClient)
		return;

	RemoveClientVictim();

	g_iVictim = iClient;
	SetEntPropFloat(g_iVictim, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_hVictimSpeed));

	if (bGiveBomb) {
		if (Client_IsIngame(g_iVictim)) {
			Client_RemoveAllWeapons(g_iVictim);
		}

		g_iPotato = CreateEntityByName("weapon_c4");
		DispatchKeyValue(g_iPotato, "targetname", "TG_HotPotato-Bomb");
		DispatchSpawn(g_iPotato);
		CreateTimer(0.1, Timer_Bomb);

		if (IsModelPrecached(g_sPotatoModel))
			SDKHook(g_iPotato, SDKHook_Think, Hook_BombThink);
	}

	CreateBeam();

	TG_LogGameMessage(GAME_ID, _, "Player %N has the hot potato.", iClient);
}


public Action:Timer_Bomb(Handle:hTimer)
{
	SetEntPropEnt(g_iPotato, Prop_Data, "m_hOwner", g_iVictim);
	EquipPlayerWeapon(g_iVictim, g_iPotato);
}

CreateBeam()
{
	if (IsModelPrecached(g_sBeamModel)) {
		if (IsValidEntity(g_iBeam) && g_iBeam != 0) {
			RemoveEdict(g_iBeam);
		}

		g_iBeam = CreateEntityByName("env_beam");

		if (IsValidEntity(g_iBeam)) {
			DispatchKeyValue(g_iBeam, "targetname", "TG_HotPotato-Beam");

			DispatchKeyValue(g_iBeam, "texture", g_sBeamModel);
			DispatchKeyValueFormat(g_iBeam, "BoltWidth", "%f", g_fBeamWidth);
			DispatchKeyValue(g_iBeam, "life", "0");
			DispatchKeyValueFormat(g_iBeam, "rendercolor", "%d %d %d", g_iBeamColor[0], g_iBeamColor[1], g_iBeamColor[2]);
			DispatchKeyValueFormat(g_iBeam, "renderamt", "%d", g_iBeamColor[3]);
			DispatchKeyValue(g_iBeam, "TextureScroll", "0");
			DispatchKeyValue(g_iBeam, "LightningStart", "TG_HotPotato-Beam");
			DispatchKeyValue(g_iBeam, "LightningEnd", "TG_HotPotato-Bomb");

			DispatchSpawn(g_iBeam);
			ActivateEntity(g_iBeam);
			AcceptEntityInput(g_iBeam, "TurnOff");

			new Float:fVictimPos[3];
			GetClientAbsOrigin(g_iVictim, fVictimPos);
			fVictimPos[2] += 48.0;

			TeleportEntity(g_iBeam, fVictimPos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(g_iBeam, "SetParent", g_iVictim);
		}
	}
}

bool:ExistBeam()
{
	return (IsModelPrecached(g_sBeamModel) && IsValidEntity(g_iBeam) && g_iBeam != 0);
}

public Hook_BombThink(iEntity)
{
	SetEntityModel(g_iPotato, g_sPotatoModel);
}

RemoveClientVictim()
{
	if (Client_IsIngame(g_iVictim))
		SetEntPropFloat(g_iVictim, Prop_Data, "m_flLaggedMovementValue", 1.0);

	g_iVictim = 0;
}

ResetGame()
{
	if (IsValidEntity(g_iPotato))
		RemoveEdict(g_iPotato);

	if (ExistBeam()) {
		RemoveEdict(g_iBeam);
		g_iBeam = 0;
	}

	g_iPotato = -1;
	g_iVictim = -1;
	g_bToLastMan = false;
	g_hDamageTimer = INVALID_HANDLE;
}
