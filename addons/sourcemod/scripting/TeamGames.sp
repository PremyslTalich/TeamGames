#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <teamgames>
// #include <convar_append>
#include <menu-stocks>
#include <colorvariables>
#include <dtc>
#include <emitsoundany>
#undef REQUIRE_PLUGIN
#include <scp>
#include <updater>
#include <lastrequest>

// Modifying defines might cause problems... Do not modify them, unless you exactly know, what you are doing.
#define UPDATE_URL			""

#define PLUGIN_CONFIG		"sourcemod/teamgames"
#define LOGS_DIRECTORY		"logs/teamgames"
#define FENCES_CONFIGS 		"configs/teamgames/fences"
#define DOWNLOADS_CONFIG 	"configs/teamgames/downloads.cfg"
#define MODULES_CONFIG 		"configs/teamgames/modules.cfg" // lowercase only!
#define MODCONF_GAMES		"GamesMenu"
#define MODCONF_MENUITEMS	"MainMenu"

#define FF_DMG_MODIFIER	0.3125

// #define DEBUG

new Handle:Forward_OnTraceAttack;
new Handle:Forward_OnPlayerDamage;
new Handle:Forward_OnPlayerDeath;
new Handle:Forward_OnPlayerTeam;
new Handle:Forward_OnPlayerTeamPost;
new Handle:Forward_OnPlayerRebel;
new Handle:Forward_OnPlayerRebelPost;
new Handle:Forward_OnPlayerLeaveGame;
new Handle:Forward_OnPlayerStopGame;
new Handle:Forward_OnPlayerStopGamePost;
new Handle:Forward_OnLaserFenceCreate;
new Handle:Forward_OnLaserFenceCreated;
new Handle:Forward_OnLaserFenceCross;
new Handle:Forward_OnLaserFenceCrossed;
new Handle:Forward_OnLaserFenceDestroyed;
new Handle:Forward_OnMarkSpawn;
new Handle:Forward_OnMarkSpawned;
new Handle:Forward_OnMarkDestroyed;
new Handle:Forward_OnGameStartMenu;
new Handle:Forward_OnGamePreparePre;
new Handle:Forward_OnGamePrepare;
new Handle:Forward_OnGameStart;
new Handle:Forward_OnGameStartError;
new Handle:Forward_OnGameEnd;
new Handle:Forward_OnTeamEmpty;
new Handle:Forward_OnMenuDisplay;
new Handle:Forward_OnMenuDisplayed;
new Handle:Forward_OnMenuSelect;
new Handle:Forward_OnMenuSelected;
new Handle:Forward_AskModuleName;
new Handle:Forward_OnDownloadsStart;
new Handle:Forward_OnDownloadFile;
new Handle:Forward_OnDownloadsEnd;

new EngineVersion:g_iEngineVersion;

#include "ConVars.sp"
#include "ModuleData.sp"
#include "PlayerData.sp"
#include "Games.sp"
#include "Teams.sp"
#include "HealthBar.sp"
#include "LaserFences.sp"
#include "Chat.sp"
#include "Marks.sp"
#include "MapTriggers.sp"
#include "ConfigFiles.sp"
#include "Commands.sp"
#include "Api.sp"

// major.minor.patch.build
#define _PLUGIN_VERSION "0.17.0.7"

public Plugin:myinfo =
{
	name        = "TeamGames",
	author      = "Raska",
	description = "Platform (core plugin) for team based games for prisoners and non-game modules + provides a few useful things for wardens. Supports only CS:S and CS:GO.",
	version     = _PLUGIN_VERSION,
	url         = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("TeamGames.phrases");

	CreateConVar("tg_version", _PLUGIN_VERSION, "TeamGames core version (not changeable)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	g_hAutoUpdate = 				CreateConVar("tg_autoupdate", 				"1", 						"Should TeamGames use plugin Updater? (https://forums.alliedmods.net/showthread.php?t=169095) (1 = true, 0 = false)");
	g_hLogTime = 					CreateConVar("tg_logtime", 					"72.0", 					"How long should logs be hold (in hours)\n\t0.0 = logging turned off\n\t-1.0 = loggin on + logs are hold forever\n\t>0.0 = loggin on + older logs are deleted", _, true, -1.0, true, 600.0);

	g_hModuleDefVisibility = 		CreateConVar("tg_module_defvisibility",		"1", 						"Default visibility of new modules (might not work properly). (1 = visible, 0 = invisible)");

	g_hMenuPercent = 				CreateConVar("tg_menu_percent", 			"0.0", 						"How many percent of alive CTs must use !tg to unlock !tg menu (0.0 = no limit)", _, true, 0.0, true, 1.0);
	g_hAllowMultiSwitch = 			CreateConVar("tg_menu_team_multiswitch",	"0",						"Allow multi switch functions in teams menu? (0 = no, 1 = yes, 2 = yes + jump to games menu)");
	g_hMenuTimeLock = 				CreateConVar("tg_menu_timelock",			"0",						"Time lock for TeamGames menu. (in seconds)");

	g_hBindActionBuyAmmo1 = 		CreateConVar("tg_bindaction_buyammo1",		"Core_SwitchToRedTeam",		"Bind action on buyammo1 (key ,) command. For actions look at https://github.com/KissLick/TeamGames/wiki/Bind-actions");
	g_hBindActionBuyAmmo2 = 		CreateConVar("tg_bindaction_buyammo2",		"Core_SwitchToBlueTeam",	"Bind action on buyammo2 (key .) command. For actions look at https://github.com/KissLick/TeamGames/wiki/Bind-actions");
	g_hBindActionLookAtWeapon = 	CreateConVar("tg_bindaction_lookatweapon",	"Core_MainMenu",			"Bind action on +lookatweapon (key v) command. For actions look at https://github.com/KissLick/TeamGames/wiki/Bind-actions");

	g_hSelfDamage = 				CreateConVar("tg_player_selfdmg", 			"0", 						"Allow self damage (only for Ts)?\n\t0 = No self damage\n\t1 = Allow self damage, but not in game\n\t2 = Allow self damage, even in game");

	g_hRoundLimit = 				CreateConVar("tg_game_roundlimit", 			"-1", 						"How many games can be played in one round? (-1 = no limit)");
	g_hCheckTeams = 				CreateConVar("tg_game_checkteams", 			"0", 						"Check if the teams are equal before starting TeamGame game.");
	g_hMoveSurvivors = 				CreateConVar("tg_game_movesurvivors",		"0",						"Should be survivors (after game end) moved to \"NoneTeam\"?\n\t0 = don't move them\n\t1 = move them\n\t2 = let the game decide)");
	g_hSaveWeapons = 				CreateConVar("tg_game_saveweapons",			"2",						"Should survivors recieve striped weapons, health and armor in Game preparation?\n\t0 = no\n\t1 = yes\n\t2 = let the game decide)");
	g_hRebelAttack = 				CreateConVar("tg_game_rebelattack",			"1",						"Action taken when red/blue T attack CT during game\n\t0 = no dmg & no rebel\n\t1 = no dmg & make rebel");
	g_hKillFrags = 					CreateConVar("tg_game_killfrags",			"1",						"Frags added when prisoner killed in TG game.");
	g_hKillScore = 					CreateConVar("tg_game_killscore",			"1",						"Score added when prisoner killed in TG game. (Only for CS:GO)");
	g_hGamesTimeLock = 				CreateConVar("tg_game_timelock",			"0",						"Time lock for TG games. (in seconds)");

	g_hChangeTeamDelay =			CreateConVar("tg_team_changedelay",			"2.0", 						"How many seconds after team change should be player immune from changing team.", _, true, 0.0, true, 600.0);
	g_hTeamDiff = 					CreateConVar("tg_team_diff",				"1",						"How should be teams differentiated? (0 = color, 1 = skin)");
	g_hTeamAttack = 				CreateConVar("tg_team_attack",				"0",						"Can Ts in different teams (excluding none team) attack each other even if there is no game? (requires \"mp_friendlyfire 1\") (1 = true, 0 = false)");
	g_hNoneTeamAttack = 			CreateConVar("tg_team_none_attack",			"0",						"Can Ts in none team attack each other? (requires \"mp_friendlyfire 1\") (1 = true, 0 = false)");
	g_hNotifyPlayerTeam = 			CreateConVar("tg_team_notification",		"1",						"Location for notifications about player's team.\n\t0 = turned off\n\t1 = KeyHint text (bottom-right)\n\t2 = hsay\n\t3 = tg hud\n\t4 = screen overlay (this might break other overlays!)");

	g_hAllowMark = 					CreateConVar("tg_mark_allow",				"1",						"Should be marks enabled? (1 = true, 0 = false)");
	g_hMarkLimit = 					CreateConVar("tg_mark_limit",				"20",						"How many marks can be spawned at the moment");
	g_hMarkLife = 					CreateConVar("tg_mark_life",				"20.0",						"How many seconds should be one mark spawned", _, true, 0.5, true, 600.0);
	g_hMarkLaser = 					CreateConVar("tg_mark_laser",				"0.4",						"Mark spawn laser life (in seconds) (0.0 = no laser).", _, true, 0.0, true, 600.0);
	g_hMarkBlockDMG = 				CreateConVar("tg_mark_nobullet",			"1",						"Mark spawning will not consume ammo and deal damage. (0 = false, 1 = true, 2 = true only for red mark)");
	g_hMarkSpawnDelay = 			CreateConVar("tg_mark_spawndelay",			"0.0",						"Mark spawn delay (for each player). (0.0 = no delay)");
	g_hMarkInfinite = 				CreateConVar("tg_mark_infinitemarks",		"1",						"If you attempt to spawn mark over limit (tg_mark_limit + 1), oldest mark is removed to allow spawn new mark. (1 = true, 0 = false)");

	g_hImportantMsg = 				CreateConVar("tg_chat_doubleimportant",		"1",						"Print important messages twice (translations: GamePreparation, GameStart, TeamWins-RedTeam, TeamWins-BlueTeam and TeamWins-Tie)? (1 = true, 0 = false)"); //
	g_hAllowTeamPrefix = 			CreateConVar("tg_chat_teamprefix",			"1",						"Use chat name prefix (for player in team red or team blue)? (1 = true, 0 = false) (requires plugin \"simple-chatprocessor.smx\")");

	g_hFenceType = 					CreateConVar("tg_fence_type",				"1",						"Fence type:\n\t0 = fence is turned off\n\t1 = beam fence\n\t2 = rope fence");
	g_hFenceHeight = 				CreateConVar("tg_fence_height",				"72.0",						"Height of fence. (Player can jump over fence)", _, true, 12.0, true, 1024.0);
	g_hFenceNotify = 				CreateConVar("tg_fence_notify",				"2",						"Notify in chat that player crossed laser fence.\n\t0 = no\n\t1 = yes\n\t2 = only when game is in progress)");
	g_hFencePunishLength = 			CreateConVar("tg_fence_punishlength",		"0.75",						"Time in seconds to punish (color and freeze) player who crossed laser fence.", _, true, 0.0, true, 600.0);
	g_hFenceFreeze = 				CreateConVar("tg_fence_freeze",				"2",						"Freeze player who crossed laser fence.\n\t0 = no\n\t1 = yes\n\t2 = only when game is in progress)");
	g_hFencePunishColorSettings = 	CreateConVar("tg_fence_color",				"1",						"Color player who crossed laser fence.\n\t0 = no\n\t1 = yes\n\t2 = only when game is in progress)");
	g_hFencePunishColor = 			CreateConVar("tg_fence_punishcolor",		"000000",					"RRGGBB (hex rgb) - color used on punished player");

	g_hForceAutoKick = 				CreateConVar("tg_cvar_autokick",			"1",						"Force set convar \"mp_autokick 0\" every map start? (1 = true, 0 = false)");
	g_hForceTKPunish = 				CreateConVar("tg_cvar_tkpunish",			"1",						"Force set convar \"mp_tkpunish 0\" every map start? (1 = true, 0 = false)");
	g_hFriendlyFire = 				CreateConVar("tg_cvar_friendlyfire",		"1",						"0 = do nothing \"mp_friendlyfire\"\n1 = set \"mp_friendlyfire 1\" every map start (after configs are loaded)\n2 = set \"mp_friendlyfire 1\" when game is in progress and set \"mp_friendlyfire 0\" otherwise.");
	g_hFFReduction = 				CreateConVar("tg_cvar_ff_reduction",		"1",						"Force set convar \"ff_damage_reduction_bullets\", \"ff_damage_reduction_grenade\", \"ff_damage_reduction_grenade_self\" and \"ff_damage_reduction_other\" to \"1\" every map start? Only for CS:GO. (1 = true, 0 = false)");

	RegConsoleCmd("sm_tg", 			Command_MainMenu, 	"TeamGames main menu");
	RegConsoleCmd("sm_games", 		Command_GamesList,	"List of all loaded games.");
	RegConsoleCmd("sm_rebel", 		Command_Rebel,		"Become a rebel.");
	RegConsoleCmd("sm_r", 			Command_Rebel,		"Become a rebel.");
	RegConsoleCmd("sm_stoptg", 		Command_StopTG,		"Stop current TG game.");

	RegAdminCmd("sm_teamgames", 	Command_MainMenu, 			ADMFLAG_GENERIC,	"TeamGames main menu");
	RegAdminCmd("sm_tgteam", 		Command_SetTeam,	 	 	ADMFLAG_GENERIC, 	"Set player team (0 = NoneTeam, 1 = RedTeam, 2 = BlueTeam).");
	RegAdminCmd("sm_tglist",  		Command_ModulesList, 		ADMFLAG_GENERIC,	"List of all games and custom (modules) menu items.");
	RegAdminCmd("sm_tgvisible", 	Command_Visible, 		 	ADMFLAG_GENERIC, 	"Set modules visibility (allow/disallow them to appear in tg menu).");
	RegAdminCmd("sm_tgupdate", 		Command_Update, 		 	ADMFLAG_ROOT, 		"Check and try to update TeamGames via updater.smx");

	AddCommandListener(Command_BindAction, "buyammo1");
	AddCommandListener(Command_BindAction, "buyammo2");
	AddCommandListener(Command_BindAction, "+lookatweapon");

	HookEvent("round_start", 	Event_RoundStart, 	EventHookMode_Post);
	HookEvent("round_end", 		Event_RoundEnd, 	EventHookMode_Pre);
	HookEvent("player_death", 	Event_PlayerDeath, 	EventHookMode_Post);
	HookEvent("bullet_impact", 	Event_BulletImpact, EventHookMode_Post);

	HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);

	AddMultiTargetFilter("@r", 	TGMultiTargetTeam, "TG Red team", false);
	AddMultiTargetFilter("@b", 	TGMultiTargetTeam, "TG Blue team", false);
	AddMultiTargetFilter("@n", 	TGMultiTargetTeam, "TG None team", false);
	AddMultiTargetFilter("@rb", TGMultiTargetBoth, "TG Red & Blue team", false);

	ClearGameStatusInfo();

	g_bLockMenu = true;

	g_iMarkLimitCounter = 0;

	// AutoExecConfigAppend(_, PLUGIN_CONFIG);

	new String:sPluginConfig[PLATFORM_MAX_PATH];
	FormatEx(sPluginConfig, sizeof(sPluginConfig), "cfg/%s", PLUGIN_CONFIG);
	CreateDirectoryPath(sPluginConfig, 511);
	AutoExecConfig(_, _, PLUGIN_CONFIG);

	CSavePrefix("TG");

	CAddVariable("tg-noneteam", "{default}");
	CAddVariable("tg-redteam", 	"{lightred}");
	CAddVariable("tg-blueteam", "{blue}");
	CAddVariable("tg-settings", "{green}");
	CAddVariable("tg-module", 	"{green}");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater") && GetConVarBool(g_hAutoUpdate)) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++) {
		ClearPlayerData(i);
		ClearPlayerEquipment(i);
	}

	new String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof (sPath), DOWNLOADS_CONFIG);

	CreateDirectoryPath(sPath, 511, true);
	DTC_CreateConfig(sPath, DTC_OnCreateConfig);

	Call_StartForward(Forward_OnDownloadsStart);
	Call_Finish();

	DTC_LoadConfig(sPath, DTC_OnFile);

	Call_StartForward(Forward_OnDownloadsEnd);
	Call_Finish();

	PrecacheSoundAny("buttons/blip2.wav", true);
	PrecacheModel("models/props/cs_office/trash_can.mdl", true);
	g_iFencePreMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnConfigsExecuted()
{
	LoadLogging();
	LoadConVars();
	HookConVarsChange();

	if (g_iFriendlyFire == 1) {
		SetConVarIntSilent("mp_friendlyfire", 1);
	}

	if (g_hNotifyTimer != INVALID_HANDLE) {
		KillTimer(g_hNotifyTimer);
		g_hNotifyTimer = INVALID_HANDLE;
	}
	g_hNotifyTimer = CreateTimer(3.0, Timer_HintTeam, _, TIMER_REPEAT);
}

public OnMapEnd()
{
	g_hNotifyTimer = INVALID_HANDLE;

	if (g_hMarks != INVALID_HANDLE) {
		for (new i = GetArraySize(g_hMarks) - 1; i >= 0; i--) {
			TriggerTimer(Handle:GetArrayCell(g_hMarks, i));
		}

		// kinda paranoid...
		CloseHandle(g_hMarks);
		g_hMarks = INVALID_HANDLE;
	}
}

public OnClientPutInServer(iClient)
{
	// there is no splashing blood with SDKHook_TraceAttack (unlike with SDKHook_OnTakeDamage)
	SDKHook(iClient, SDKHook_TraceAttack, Hook_TraceAttack);

	// SDKHook_OnTakeDamage - mainly because of molotovs
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);

	// Updating HealthBar
	SDKHook(iClient, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

public OnClientDisconnect(iClient)
{
	if (g_Game[GameProgress] != TG_NoGame && TG_IsPlayerRedOrBlue(iClient)) {
		TG_LogGameMessage(g_Game[GameID], "PlayerLeaveGame", "\"%L\" (%s) (reason = \"Disconnect\")", iClient, (g_PlayerData[iClient][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iClient][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");

		Call_OnPlayerLeaveGame(g_Game[GameID], g_Game[GameType], iClient, g_PlayerData[iClient][Team], TG_Disconnect);
	}

	if (TG_IsTeamRedOrBlue(g_PlayerData[iClient][Team]) && GetCountPlayersInTeam(g_PlayerData[iClient][Team]) == 0) {
		if (g_Game[GameProgress] != TG_NoGame) {
			TG_LogGameMessage(g_Game[GameID], "OnTeamEmpty", "\"%L\" (%s) (reason = \"Disconnect\")", iClient, (g_PlayerData[iClient][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iClient][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
		} else {
			TG_LogRoundMessage("OnTeamEmpty", "\"%L\" (%s) (reason = \"Disconnect\")", iClient, (g_PlayerData[iClient][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iClient][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
		}

		Call_OnTeamEmpty(g_Game[GameID], g_Game[GameType], iClient, g_PlayerData[iClient][Team], TG_Death);
	}

	ClearPlayerData(iClient);
	ClearPlayerEquipment(iClient);
}

public Action:Event_RoundStart(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	ClearGameStatusInfo();

	g_bLockMenu = (GetConVarFloat(g_hMenuPercent) <= 0.0) ? false : true;
	g_bTeamsLock = false;
	g_iMenuTimeLock = GetTime() + GetConVarInt(g_hMenuTimeLock);
	g_iGamesTimeLock = GetTime() + GetConVarInt(g_hGamesTimeLock);
	g_iMarkLimitCounter = 0;

	DestroyFence();

	for (new i = 1; i <= MaxClients; i++) {
		ClearPlayerData(i);
		ClearPlayerEquipment(i);
	}

	if (g_hMarks != INVALID_HANDLE) {
		for (new i = GetArraySize(g_hMarks) - 1; i >= 0; i--) {
			TriggerTimer(Handle:GetArrayCell(g_hMarks, i));
		}

		// kinda paranoid...
		ClearArray(g_hMarks);
	} else {
		g_hMarks = CreateArray();
	}

	TG_LogMessage("RoundStart", "");
}

public Action:Event_RoundEnd(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if (GetConVarInt(g_hNotifyPlayerTeam) == 4) {
		for (new i = 1; i <= MaxClients; i++) {
			if (Client_IsIngame(i))
				ClientCommand(i, "r_screenoverlay \"\"");
		}
	}
}

public Action:Hook_TraceAttack(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iAmmoType, iHitBox, iHitGroup)
{
	new Action:iReturnValue = (Client_IsIngame(iAttacker) && g_PlayerData[iAttacker][MarkBlockDMG]) ? Plugin_Handled : Hook_PlayerAttack(true, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup);

	// if ((Client_IsIngame(iAttacker) || iAttacker == 0) && Client_IsIngame(iVictim))
		// PrintToChatAll("Attack: %N -> %N = %d", iAttacker, iVictim, iReturnValue);

	return iReturnValue;
}

public Action:Hook_OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{
	new Action:iReturnValue = (Client_IsIngame(iAttacker) && g_PlayerData[iAttacker][MarkBlockDMG]) ? Plugin_Handled : Hook_PlayerAttack(false, iVictim, iAttacker, iInflictor, fDamage, iDamageType);

	// if ((Client_IsIngame(iAttacker) || iAttacker == 0) && Client_IsIngame(iVictim))
		// PrintToChatAll("Damage: %N -> %N = %d", iAttacker, iVictim, iReturnValue);

	return iReturnValue;
}

public Hook_OnTakeDamagePost(iVictim, iAttacker, iInflictor, Float:fDamage, iDamageType)
{
	UpdateHealthBar(iVictim);
}

Action:Hook_PlayerAttack(bool:bTraceAttack, iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iAmmoType = -1, iHitBox = -1, iHitGroup = -1)
{
	if (!Client_IsIngame(iAttacker) || !Client_IsIngame(iVictim))
		return Plugin_Continue;

	new iVictimTeam = GetClientTeam(iVictim);
	new iAttackerTeam = GetClientTeam(iAttacker);

	// CT can't hurt CT
	if (iAttackerTeam == CS_TEAM_CT && iVictimTeam == CS_TEAM_CT)
		return Plugin_Handled;

	// CT can always hurt T
	if (iAttackerTeam == CS_TEAM_CT && iVictimTeam == CS_TEAM_T)
		return Plugin_Continue;

	new TG_Team:iAttackerTGTeam = g_PlayerData[iAttacker][Team];
	new TG_Team:iVictimTGTeam = g_PlayerData[iVictim][Team];

	if (iAttackerTeam == CS_TEAM_T && iVictimTeam == CS_TEAM_CT) {
		if (g_Game[GameProgress] == TG_NoGame) {
			if (iAttackerTGTeam != TG_NoneTeam) {
				MakeRebel(iAttacker);
			}

			return Plugin_Continue;
		} else if (g_Game[GameProgress] == TG_InPreparation) {
			if (iAttackerTGTeam == TG_NoneTeam) {
				return Plugin_Continue;
			} else {
				return Plugin_Handled;
			}
		} else if (g_Game[GameProgress] == TG_InProgress) {
			if (iAttackerTGTeam == TG_NoneTeam) {
				return Plugin_Continue;
			} else {
				if (GetConVarInt(g_hRebelAttack) == 1) {
					MakeRebel(iAttacker);
				}

				return Plugin_Handled;
			}
		}
	} else if (iAttackerTeam == CS_TEAM_T && iVictimTeam == CS_TEAM_T) {
		if (g_iEngineVersion == Engine_CSS) {
			fDamage = fDamage / FF_DMG_MODIFIER;
		}

		if (GetConVarBool(g_hNoneTeamAttack) && iAttacker != iVictim && TG_GetPlayerTeam(iAttacker) == TG_NoneTeam && TG_GetPlayerTeam(iVictim) == TG_NoneTeam) {
			return Plugin_Changed;
		}

		if (g_Game[GameProgress] == TG_NoGame) {
			if (iAttacker == iVictim) {
				if (GetConVarInt(g_hSelfDamage) > 0) {
					return Plugin_Changed;
				} else {
					return Plugin_Handled;
				}
			}

			// FN
			new Action:iDefaultResult = (GetConVarBool(g_hTeamAttack) && TG_InOppositeTeams(iAttacker, iVictim)) ? Plugin_Changed : Plugin_Handled;
			return CallForward_PlayerAttack(bTraceAttack, false, iDefaultResult, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup);
		} else if (g_Game[GameProgress] == TG_InPreparation) {
			if (iAttacker == iVictim) {
				if (iAttackerTGTeam == TG_NoneTeam && GetConVarInt(g_hSelfDamage) > 0) {
					return Plugin_Changed;
				} else {
					return Plugin_Handled;
				}
			}

			if (iAttackerTGTeam == TG_NoneTeam && iVictimTGTeam == TG_NoneTeam) {
				// FN
				return CallForward_PlayerAttack(bTraceAttack, false, Plugin_Handled, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup);
			} else {
				return Plugin_Handled;
			}
		} else if (g_Game[GameProgress] == TG_InProgress) {
			if (iAttacker == iVictim) {
				if ((iAttackerTGTeam == TG_NoneTeam && GetConVarInt(g_hSelfDamage) > 0) || (iAttackerTGTeam != TG_NoneTeam && GetConVarInt(g_hSelfDamage) > 1)) {
					return Plugin_Changed;
				} else {
					return Plugin_Handled;
				}
			}

			if (iAttackerTGTeam == TG_NoneTeam && iVictimTGTeam == TG_NoneTeam) {
				// FN
				return CallForward_PlayerAttack(bTraceAttack, false, Plugin_Handled, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup);
			} else if (TG_InOppositeTeams(iAttacker, iVictim) || (g_Game[GameType] == TG_RedOnly && iAttackerTGTeam == iVictimTGTeam)) {
				// FG
				return CallForward_PlayerAttack(bTraceAttack, true, Plugin_Changed, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup);
			} else if (iAttackerTGTeam == iVictimTGTeam) {
				// FG
				return CallForward_PlayerAttack(bTraceAttack, true, Plugin_Handled, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup);
			} else {
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

static Action:CallForward_PlayerAttack(bool:bTraceAttack, bool:bInGame, Action:iDefaultResult, iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iAmmoType, iHitBox, iHitGroup)
{
	if (bTraceAttack) {
		return ResolveResult(CallForward_TraceAttack(bInGame, iDefaultResult, iVictim, iAttacker, iInflictor, fDamage, iDamageType, iAmmoType, iHitBox, iHitGroup), iDefaultResult);
	} else {
		return ResolveResult(CallForward_OnTakeDamage(bInGame, iDefaultResult, iVictim, iAttacker, iInflictor, fDamage, iDamageType), iDefaultResult);
	}
}

static Action:CallForward_TraceAttack(bool:bInGame, Action:iDefaultResult, iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iAmmoType, iHitBox, iHitGroup)
{
	new Action:iResult = iDefaultResult;
	Call_StartForward(Forward_OnTraceAttack);
	Call_PushCell(bInGame);
	Call_PushCell(iVictim);
	Call_PushCellRef(iAttacker);
	Call_PushCellRef(iInflictor);
	Call_PushFloatRef(fDamage);
	Call_PushCellRef(iDamageType);
	Call_PushCellRef(iAmmoType);
	Call_PushCell(iHitBox);
	Call_PushCell(iHitGroup);
	Call_Finish(iResult);

	return iResult;
}

static Action:CallForward_OnTakeDamage(bool:bInGame, Action:iDefaultResult, iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{
	new Action:iResult = iDefaultResult;
	Call_StartForward(Forward_OnPlayerDamage);
	Call_PushCell(bInGame);
	Call_PushCell(iVictim);
	Call_PushCellRef(iAttacker);
	Call_PushCellRef(iInflictor);
	Call_PushFloatRef(fDamage);
	Call_PushCellRef(iDamageType);
	Call_Finish(iResult);

	return iResult;
}

static Action:ResolveResult(Action:iResult, Action:iDefaultResult)
{
	if (iResult == Plugin_Handled || iResult == Plugin_Stop) {
		return Plugin_Handled;
	} else if (iResult == Plugin_Continue) {
		return iDefaultResult;
	} else {
		return Plugin_Changed;
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (!Client_IsIngame(iVictim) || g_PlayerData[iVictim][Team] == TG_NoneTeam)
		return Plugin_Continue;

	new iHeadShot = GetEventInt(hEvent, "headshot");
	new String:sWeapon[64];
	GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));

	if (Client_IsIngame(iAttacker) && GetClientTeam2(iVictim) == CS_TEAM_T && GetClientTeam2(iAttacker) == CS_TEAM_T && iAttacker != iVictim) {
		RequestFrame(Frame_AddFragsAndScore, iAttacker);
	}

	Call_StartForward(Forward_OnPlayerDeath);
	Call_PushCell(iAttacker);
	Call_PushCell(g_PlayerData[iAttacker][Team]);
	Call_PushCell(iVictim);
	Call_PushCell(g_PlayerData[iVictim][Team]);
	Call_PushCell(iHeadShot);
	Call_PushString(sWeapon);
	Call_PushCell(g_Game[GameProgress]);
	Call_PushString(g_Game[GameID]);
	Call_PushCell(g_Game[GameType]);
	Call_Finish();

	decl String:sVictimName[64];
	GetClientName(iVictim, sVictimName, sizeof(sVictimName));

	if (g_Game[GameProgress] != TG_NoGame) {
		Call_OnPlayerLeaveGame(g_Game[GameID], g_Game[GameType], iVictim, g_PlayerData[iVictim][Team], TG_Death);

		TG_LogGameMessage(g_Game[GameID], "PlayerDeath", "\"%L\" (%s) killed \"%L\" (%s)", iAttacker, (GetClientTeam2(iAttacker) == CS_TEAM_CT) ? "CT" : (g_PlayerData[iAttacker][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iAttacker][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam", iVictim, (g_PlayerData[iVictim][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iVictim][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
	} else {
		TG_LogRoundMessage("PlayerDeath", "\"%L\" (%s) killed \"%L\" (%s)", iAttacker, (Client_IsIngame(iAttacker) && GetClientTeam2(iAttacker) == CS_TEAM_CT) ? "CT" : (g_PlayerData[iAttacker][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iAttacker][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam", iVictim, (g_PlayerData[iVictim][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iVictim][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
	}

	if (g_PlayerData[iVictim][Team] == TG_RedTeam) {
		CPrintToChatAll("%t", "PlayerDeath-RedTeam", sVictimName);
	} else if (g_PlayerData[iVictim][Team] == TG_BlueTeam) {
		CPrintToChatAll("%t", "PlayerDeath-BlueTeam", sVictimName);
	}

	if (GetCountPlayersInTeam(g_PlayerData[iVictim][Team]) == 0) {
		if (g_Game[GameProgress] != TG_NoGame) {
			TG_LogGameMessage(g_Game[GameID], "OnTeamEmpty", "\"%L\" (%s) (reason = \"Death\")", iVictim, (g_PlayerData[iVictim][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iVictim][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
		} else {
			TG_LogRoundMessage("OnTeamEmpty", "\"%L\" (%s) (reason = \"Death\")", iVictim, (g_PlayerData[iVictim][Team] == TG_RedTeam) ? "RedTeam" : (g_PlayerData[iVictim][Team] == TG_BlueTeam) ? "BlueTeam" : "NoneTeam");
		}

		Call_OnTeamEmpty(g_Game[GameID], g_Game[GameType], iVictim, g_PlayerData[iVictim][Team], TG_Death);
	}

	g_PlayerData[iVictim][MenuLock] = true;
	ClearPlayerEquipment(iVictim);
	ClearPlayerData(iVictim);

	if (GetConVarInt(g_hNotifyPlayerTeam) == 4)
		ClientCommand(iVictim, "r_screenoverlay \"\"");

	return Plugin_Continue;
}

GetClientTeam2(iClient)
{
	return (iClient != 0) ? GetClientTeam(iClient) : CS_TEAM_NONE;
}

public Frame_AddFragsAndScore(any:iClient)
{
	new iFrags = GetEntProp(iClient, Prop_Data, "m_iFrags");
	SetEntProp(iClient, Prop_Data, "m_iFrags", iFrags + 1 + GetConVarInt(g_hKillFrags));

	if (g_iEngineVersion == Engine_CSGO && GetConVarInt(g_hKillScore)) {
		new iScore = CS_GetClientContributionScore(iClient);
		CS_SetClientContributionScore(iClient, iScore + GetConVarInt(g_hKillScore));
	}
}

LoadLogging()
{
	decl String:sFilePath[PLATFORM_MAX_PATH];
	new Float:fLogTime = GetConVarFloat(g_hLogTime);
	if (fLogTime != 0.0) {
		new FileType:iType;
		decl String:sDirPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sDirPath, sizeof(sDirPath), LOGS_DIRECTORY);

		if (!DirExists(sDirPath))
			CreateDirectoryPath(sDirPath, 511);

		if (fLogTime > 0.0) {
			new Handle:hDirectory = OpenDirectory(sDirPath);

			while (ReadDirEntry(hDirectory, sFilePath, sizeof(sFilePath), iType)) {
				if (iType == FileType_File) {
					Format(sFilePath, sizeof(sFilePath), "%s/%s", sDirPath, sFilePath);

					if (GetFileTime(sFilePath, FileTime_LastChange) < GetTime() - GetConVarFloat(g_hLogTime) * 3600.0)
						DeleteFile(sFilePath);
				}
			}

			CloseHandle(hDirectory);
		}

		g_bLogCvar = true;
	} else {
		g_bLogCvar = false;
	}

	if (g_bLogCvar) {
		new String:sMapName[128];
		GetCurrentMap(sMapName, sizeof(sMapName));
		BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "%s/%d-%s.log", LOGS_DIRECTORY, GetTime(), sMapName);

		TG_LogMessage(_, "TeamGames log file session started (file \"%s/%d-%s.log\")", LOGS_DIRECTORY, GetTime(), sMapName);
	}
}
