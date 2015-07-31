#if defined _teamgames_stocks_included_
  #endinput
#endif
#define _teamgames_stocks_included_

#include <cstrike>

stock bool:TG_IsPlayerRedOrBlue(iClient)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != CS_TEAM_T)
		return false;

	return TG_IsTeamRedOrBlue(TG_GetPlayerTeam(iClient));
}

/**
 * Are players in different teams? (Red vs. Blue or Blue vs. Red)
 *
 * @param client1		Client 1 index.
 * @param client2		Client 2 index.
 * @return				True on (client 1 team != client 2 team), false otherwise.
 */
stock bool:TG_InOppositeTeams(iClient1, iClient2)
{
	new TG_Team:iTeam1 = TG_GetPlayerTeam(iClient1);
	new TG_Team:iTeam2 = TG_GetPlayerTeam(iClient2);

	if (iTeam1 != TG_RedTeam && iTeam1 != TG_BlueTeam)
		return false;

	if (iTeam2 != TG_RedTeam && iTeam2 != TG_BlueTeam)
		return false;

	return (iTeam1 != iTeam2);
}


stock TG_Team:TG_GetTeamFromString(String:sTeam[])
{
	if (StrEqual(sTeam, "RedTeam", false) || StrEqual(sTeam, "red", false) || sTeam[0] == '1')
		return TG_RedTeam;
	else if (StrEqual(sTeam, "BlueTeam", false) || StrEqual(sTeam, "blue", false) || sTeam[0] == '2')
		return TG_BlueTeam;
	else if (StrEqual(sTeam, "NoneTeam", false) || StrEqual(sTeam, "none", false) || sTeam[0] == '0')
		return TG_NoneTeam;
	else
		return TG_ErrorTeam;
}

stock TG_Team:TG_GetOppositeTeam(TG_Team:iTeam)
{
	if (iTeam == TG_RedTeam)
		return TG_BlueTeam;
	else if (iTeam == TG_BlueTeam)
		return TG_RedTeam;
	else
		return TG_ErrorTeam;
}

stock bool:TG_IsTeamRedOrBlue(TG_Team:iTeam)
{
	return (iTeam == TG_RedTeam || iTeam == TG_BlueTeam);
}

stock bool:TG_IsTeamValid(TG_Team:iTeam)
{
	return (TG_IsTeamRedOrBlue(iTeam) || iTeam == TG_NoneTeam);
}

stock TG_GetRandomClient(TG_Team:iTeam)
{
	decl clients[MAXPLAYERS + 1];
	new count = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_GetPlayerTeam(i) == iTeam) {
			clients[count] = i;
			count++;
		}
	}

	if (count == 0)
		return 0;

	return clients[GetRandomInt(0, count - 1)];
}

stock bool:TG_CheckModuleAccess(iClient, TG_ModuleType:iType, const String:sModuleID[])
{
	new String:sTypeID[128], iFlags;
	Format(sTypeID, sizeof(sTypeID), "%s-%s", (iType == TG_MenuItem) ? "TG_MenuItem" : "TG_Game", sModuleID);

	if (GetCommandOverride(sTypeID, Override_Command, iFlags)) {
		return CheckCommandAccess(iClient, sTypeID, iFlags);
	} else {
		if (GetCommandOverride(sModuleID, Override_Command, iFlags)) {
			return CheckCommandAccess(iClient, sModuleID, iFlags);
		}
	}

	return true;
}

//------------------------------------------------------------------------------------------------
// Some little helpers

stock bool:DispatchKeyValueFormat(entity, const String:keyName[], const String:format[], any:...)
{
	decl String:value[256];
	VFormat(value, sizeof(value), format, 4);
	return DispatchKeyValue(entity, keyName, value);
}

stock GetCmdArgInt(argnum)
{
	decl String:value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToInt(value);
}

stock GetCmdArgFloat(argnum)
{
	decl String:value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToFloat(value);
}

//------------------------------------------------------------------------------------------------
// Weapons (safe to use in both CS:S and CS:GO)

stock GivePlayerWeaponAndAmmo(iClient, String:sWeapon[], iClip = -1, iAmmo = -1)
{
	new iWeapon = GivePlayerItem(iClient, sWeapon);

	if (iWeapon != -1) {
		if (iClip != -1)
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip);

		if (iAmmo != -1) {
			new iOffset = FindDataMapOffs(iClient, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(iWeapon) * 4);
			SetEntData(iClient, iOffset, iAmmo, 4, true);

			if (GetEngineVersion() == Engine_CSGO) {
				SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo);
			}
		}
	}

	return iWeapon;
}

stock SetPlayerWeaponAmmo(iClient, iWeapon, iClip = -1, iAmmo = -1)
{
	if (iWeapon == INVALID_ENT_REFERENCE)
		return;

	if (iClip != -1)
		SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip);

	if (iAmmo != -1) {
		new iOffset = FindDataMapOffs(iClient, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(iWeapon) * 4);
		SetEntData(iClient, iOffset, iAmmo, 4, true);

		if (GetEngineVersion() == Engine_CSGO) {
			SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo);
		}
	}
}
