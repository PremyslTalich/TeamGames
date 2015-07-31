#include <sourcemod>
#include <cstrike>
#include <smlib>
#include <teamgames>

public Plugin:myinfo =
{
	name = "[TG] Stats",
	author = "Raska",
	description = "",
	version = "0.1",
	url = ""
}

public TG_OnGamePrepare(const String:sID[], iClient, const String:sGameSettings[], Handle:hDataPack)
{

}

public TG_OnPlayerLeaveGame(const String:id[], iClient, TG_Team:iTeam, TG_PlayerTrigger:iTrigger)
{

}

public TG_OnGameEnd(const String:sID[], TG_Team:iTeam, iWinners[], iWinnersCount, Handle:hDataPack)
{

}

// hráč
	// - počet spuštění (za CT)
	// - počet startů
	// - počet zabití
	// - počet úmrtí
	// - počet rebélií
	// - počet vítězství
	// - počet porážek

// hra
	// - počet spuštění
	// - 50/50 -> vítězství červení
	// - 50/50 -> vítězství modří
	// - nastavení
