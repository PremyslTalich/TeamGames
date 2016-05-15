#include <sourcemod>
#include <smlib>
#include <dtc>
#include <sdkhooks>
#include <menu-stocks>
#include <teamgames>

#define GAME_ID				"HotPotato"
#define DOWNLOAD_POTATO		"HotPotato"
#define DOWNLOAD_BEAM		"HotPotato-beam"

public Plugin:myinfo =
{
	name = "[TG] HotPotato",
	author = "Raska",
	description = "",
	version = "0.6",
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

new bool:g_toLastMan;
new g_victim, Handle:g_victimSpeed, Handle:g_heathCheck;
new Handle:g_hDamage, Handle:g_damageTimer, Handle:g_damageInterval;
new g_potato, String:g_potatoModel[PLATFORM_MAX_PATH];
new g_beam, String:g_beamModel[PLATFORM_MAX_PATH], Float:g_beamWidth, g_beamColor[4];

public OnPluginStart()
{
	LoadTranslations("TG.HotPotato.phrases");

	g_heathCheck = 	    CreateConVar("tgm_hotpotato_healthcheck", 	 "2", 	"0 = Nothing\n1 = Color players in shades of red according to their health level.\n2 = Show healthbar above players.");
	g_hDamage = 		CreateConVar("tgm_hotpotato_damage", 		 "2", 	"Amount of damage to deal to victim");
	g_damageInterval =  CreateConVar("tgm_hotpotato_damageinterval", "0.2", "Interval between dealing damage to victim", _, true, 0.1, true, 10.0);
	g_victimSpeed = 	CreateConVar("tgm_hotpotato_victimspeed", 	 "1.1", "Set speed of victim (in percent)");

	HookEvent("bomb_pickup",  Event_BombPickUp, EventHookMode_Post);

	ResetGame();

	AutoExecConfig(_, _, "sourcemod/teamgames");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "TeamGames"))
		TG_RegGame(GAME_ID, TG_RedOnly);
}

public OnPluginEnd()
{
	TG_RemoveGame(GAME_ID);
}

public TG_AskModuleName(TG_ModuleType:type, const String:id[], client, String:name[], nameSize, &TG_MenuItemStatus:status)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	Format(name, nameSize, "%T", "GameName", client);
}

public TG_OnDownloadFile(String:file[], String:prefixName[], Handle:args, &bool:known)
{
	if (StrEqual(prefixName, DOWNLOAD_POTATO, false)) {
		PrecacheModel(file);
		strcopy(g_potatoModel, sizeof(g_potatoModel), file);

		known = true;
	} else if (StrEqual(prefixName, DOWNLOAD_BEAM, false)) {
		PrecacheModel(file);
		strcopy(g_beamModel, sizeof(g_beamModel), file);

		g_beamWidth = DTC_GetArgFloat(args, 1, 1.0);
		g_beamColor[0] = DTC_GetArgNum(args, 2, 255);
		g_beamColor[1] = DTC_GetArgNum(args, 3, 255);
		g_beamColor[2] = DTC_GetArgNum(args, 4, 255);
		g_beamColor[3] = DTC_GetArgNum(args, 5, 255);

		known = true;
	}
}

public TG_OnMenuSelected(TG_ModuleType:type, const String:id[], TG_GameType:gameType, client)
{
	if (type != TG_Game || !StrEqual(id, GAME_ID))
		return;

	ModuleSetTypeGameMenu(client, gameType);
}

public TG_OnGamePrepare(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	ResetPack(dataPack);
	new user = ReadPackCell(dataPack);

	if (Client_IsIngame(user)) {
		for (new i = 1; i <= MaxClients; i++) {
			if (!TG_IsPlayerRedOrBlue(i) || !Client_IsIngame(i))
				continue;

			SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);

			if (GetConVarInt(g_heathCheck) == 2) {
				TG_AttachPlayerHealthBar(i);
			}
		}
		MakeClientVictim(user, true);
	} else {
		TG_StopGame(TG_NoneTeam);
	}
}

public TG_OnGameStart(const String:id[], TG_GameType:gameType, client, const String:gameSettings[], Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	if (!Client_IsIngame(g_victim))
		TG_StopGame(TG_NoneTeam);

	g_damageTimer = CreateTimer(GetConVarFloat(g_damageInterval), Timer_SlapClient, _, TIMER_REPEAT);

	return;
}

public Action:Hook_WeaponDrop(client, weapon)
{
	if (TG_IsCurrentGameID(GAME_ID) && client == g_victim && weapon == g_potato) {
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
	if (IsValidEntity(g_potato)) {

		if (ExistBeam()) {
			DispatchKeyValue(g_potato, "targetname", "TG_HotPotato-Bomb");
			ActivateEntity(g_beam);
			AcceptEntityInput(g_beam, "TurnOn");
		}
	}
}

public Action:Timer_SlapClient(Handle:timer)
{
	if (!Client_IsIngame(g_victim))
		return Plugin_Continue;

	new client = g_victim;

	if (g_damageTimer == INVALID_HANDLE)
		return Plugin_Stop;

	new newHealth = GetClientHealth(client) - GetConVarInt(g_hDamage);

	if (newHealth <= 0) {
		Client_RemoveAllWeapons(client);
		ForcePlayerSuicide(client);
	} else {
		SetEntityHealth(client, newHealth);

		if (GetConVarInt(g_heathCheck) == 1) {
			if (newHealth > 90) {
				SetEntityRenderColor(client, 255, 255, 255, 255);
			} else if (newHealth > 10) {
				new iColor = RoundToNearest((newHealth - 10) * 3.1875);
				SetEntityRenderColor(client, 255, iColor, iColor, 255);
			} else {
				SetEntityRenderColor(client, 255, 0, 0, 255);
			}
		} else if (GetConVarInt(g_heathCheck) == 2) {
			TG_UpdatePlayerHealthBar(client);
		}
	}

	return Plugin_Continue;
}

public Action:Event_BombPickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (TG_IsCurrentGameID(GAME_ID) && TG_GetPlayerTeam(client) == TG_RedTeam) {
		if (client == g_victim) {
			if (ExistBeam())
				AcceptEntityInput(g_beam, "TurnOff");
		} else {
			MakeClientVictim(client, false);
			SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", g_potato);
		}
	}

	return Plugin_Continue;
}

public Action:TG_OnLaserFenceCross(client, Float:FreezeTime)
{
	if (g_victim == client)
		return Plugin_Handled;

	return Plugin_Continue;
}

public TG_OnPlayerLeaveGame(const String:id[], TG_GameType:gameType, client, TG_Team:team, TG_PlayerTrigger:trigger)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	if (Client_IsIngame(client)) {
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}

	SDKUnhook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);

	if (client != g_victim)
		return;

	if (IsValidEntity(g_potato)) {
		RemoveEdict(g_potato);
		g_potato = -1;
	}

	RemoveClientVictim();

	if (g_toLastMan && TG_GetTeamCount(TG_RedTeam) > 1) {
		new user = TG_GetRandomClient(TG_RedTeam);

		if (Client_IsIngame(user)) {
			MakeClientVictim(user, true);
		} else {
			TG_StopGame(TG_NoneTeam);
		}
	} else {
		g_damageTimer = INVALID_HANDLE;

		new Handle:winners = CreateArray();
		for (new i = 1; i <= MaxClients; i++) {
			if (TG_GetPlayerTeam(i) == TG_RedTeam) {
				PushArrayCell(winners, i);
			}
		}

		TG_StopGame(TG_RedTeam, winners);
	}
}

public TG_OnGameEnd(const String:id[], TG_GameType:gameType, TG_Team:team, winners[], winnersCount, Handle:dataPack)
{
	if (!StrEqual(id, GAME_ID, true))
		return;

	ResetGame();

	return;
}

ModuleSetTypeGameMenu(client, TG_GameType:gameType)
{
	new Handle:menu = CreateMenu(ModuleSetTypeGameMenu_Handler);

	SetMenuTitle(menu, "%T - %T", "GameName", client, "Menu-Title", client);
	AddMenuItemFormat(menu, "Menu-OneDeath", _, "%T", "Menu-OneDeath", client);
	AddMenuItemFormat(menu, "Menu-LastManStanding", _, "%T", "Menu-LastManStanding", client);

	PushMenuCell(menu, "__GAME_TYPE__", _:gameType);

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 30);
}

public ModuleSetTypeGameMenu_Handler(Handle:menu, MenuAction:action, client, key)
{
	if (action == MenuAction_Select) {
		new String:info[TG_MODULE_ID_LENGTH];
		GetMenuItem(menu, key, info, sizeof(info));

		new TG_GameType:gameType = TG_GameType:GetMenuCell(menu, "__GAME_TYPE__");

		if (StrEqual(info, "Menu-OneDeath")) {
			g_toLastMan = false;
		} else {
			g_toLastMan = true;
		}

		TG_ShowPlayerSelectMenu(client, SelectPlayerHandeler, true, false, true, gameType, "%T", "Menu-ChooseFirstPotato", client);
	}
}

public SelectPlayerHandeler(activator, client, bool:IsRandom, any:data)
{
	if (Client_IsIngame(client)) {
		new String:settings[48];
		new Handle:dataPack = CreateDataPack();

		Format(settings, sizeof(settings), "%t", (g_toLastMan) ? "Menu-LastManStanding" : "Menu-OneDeath");
		WritePackCell(dataPack, client);

		TG_StartGame(activator, GAME_ID, TG_GameType:data, settings, dataPack);
	}
}

MakeClientVictim(client, bool:giveBomb)
{
	if (g_victim == client)
		return;

	RemoveClientVictim();

	g_victim = client;
	SetEntPropFloat(g_victim, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_victimSpeed));

	if (giveBomb) {
		if (Client_IsIngame(g_victim)) {
			Client_RemoveAllWeapons(g_victim);
		}

		g_potato = CreateEntityByName("weapon_c4");
		DispatchKeyValue(g_potato, "targetname", "TG_HotPotato-Bomb");
		DispatchSpawn(g_potato);
		CreateTimer(0.1, Timer_Bomb);

		if (IsModelPrecached(g_potatoModel))
			SDKHook(g_potato, SDKHook_Think, Hook_BombThink);
	}

	CreateBeam();

	TG_LogGameMessage(GAME_ID, _, "Player %N has the hot potato.", client);
}


public Action:Timer_Bomb(Handle:timer)
{
	SetEntPropEnt(g_potato, Prop_Data, "m_hOwner", g_victim);
	EquipPlayerWeapon(g_victim, g_potato);
}

CreateBeam()
{
	if (IsModelPrecached(g_beamModel)) {
		if (IsValidEntity(g_beam) && g_beam != 0) {
			RemoveEdict(g_beam);
		}

		g_beam = CreateEntityByName("env_beam");

		if (IsValidEntity(g_beam)) {
			DispatchKeyValue(g_beam, "targetname", "TG_HotPotato-Beam");

			DispatchKeyValue(g_beam, "texture", g_beamModel);
			DispatchKeyValueFormat(g_beam, "BoltWidth", "%f", g_beamWidth);
			DispatchKeyValue(g_beam, "life", "0");
			DispatchKeyValueFormat(g_beam, "rendercolor", "%d %d %d", g_beamColor[0], g_beamColor[1], g_beamColor[2]);
			DispatchKeyValueFormat(g_beam, "renderamt", "%d", g_beamColor[3]);
			DispatchKeyValue(g_beam, "TextureScroll", "0");
			DispatchKeyValue(g_beam, "LightningStart", "TG_HotPotato-Beam");
			DispatchKeyValue(g_beam, "LightningEnd", "TG_HotPotato-Bomb");

			DispatchSpawn(g_beam);
			ActivateEntity(g_beam);
			AcceptEntityInput(g_beam, "TurnOff");

			new Float:victimPos[3];
			GetClientAbsOrigin(g_victim, victimPos);
			victimPos[2] += 48.0;

			TeleportEntity(g_beam, victimPos, NULL_VECTOR, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(g_beam, "SetParent", g_victim);
		}
	}
}

bool:ExistBeam()
{
	return (IsModelPrecached(g_beamModel) && IsValidEntity(g_beam) && g_beam != 0);
}

public Hook_BombThink(iEntity)
{
	SetEntityModel(g_potato, g_potatoModel);
}

RemoveClientVictim()
{
	if (Client_IsIngame(g_victim))
		SetEntPropFloat(g_victim, Prop_Data, "m_flLaggedMovementValue", 1.0);

	g_victim = 0;
}

ResetGame()
{
	if (IsValidEntity(g_potato))
		RemoveEdict(g_potato);

	if (ExistBeam()) {
		RemoveEdict(g_beam);
		g_beam = 0;
	}

	g_potato = -1;
	g_victim = -1;
	g_toLastMan = false;
	g_damageTimer = INVALID_HANDLE;
}
