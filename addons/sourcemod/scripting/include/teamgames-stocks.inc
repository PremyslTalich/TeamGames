#if defined _teamgames_stocks_included_
  #endinput
#endif
#define _teamgames_stocks_included_

#include <cstrike>

stock bool:TG_IsPlayerRedOrBlue(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != CS_TEAM_T)
		return false;

	return TG_IsTeamRedOrBlue(TG_GetPlayerTeam(client));
}

/**
 * Are players in different teams? (Red vs. Blue or Blue vs. Red)
 *
 * @param client1		Client 1 index.
 * @param client2		Client 2 index.
 * @return				True on (client 1 team != client 2 team), false otherwise.
 */
stock bool:TG_InOppositeTeams(client1, client2)
{
	new TG_Team:team1 = TG_GetPlayerTeam(client1);
	new TG_Team:team2 = TG_GetPlayerTeam(client2);

	if (team1 != TG_RedTeam && team1 != TG_BlueTeam)
		return false;

	if (team2 != TG_RedTeam && team2 != TG_BlueTeam)
		return false;

	return (team1 != team2);
}


stock TG_Team:TG_GetTeamFromString(String:team[])
{
	if (StrEqual(team, "RedTeam", false) || StrEqual(team, "red", false) || team[0] == '1')
		return TG_RedTeam;
	else if (StrEqual(team, "BlueTeam", false) || StrEqual(team, "blue", false) || team[0] == '2')
		return TG_BlueTeam;
	else if (StrEqual(team, "NoneTeam", false) || StrEqual(team, "none", false) || team[0] == '0')
		return TG_NoneTeam;
	else
		return TG_ErrorTeam;
}

stock TG_Team:TG_GetOppositeTeam(TG_Team:team)
{
	if (team == TG_RedTeam)
		return TG_BlueTeam;
	else if (team == TG_BlueTeam)
		return TG_RedTeam;
	else
		return TG_ErrorTeam;
}

stock bool:TG_IsTeamRedOrBlue(TG_Team:team)
{
	return (team == TG_RedTeam || team == TG_BlueTeam);
}

stock bool:TG_IsTeamValid(TG_Team:team)
{
	return (TG_IsTeamRedOrBlue(team) || team == TG_NoneTeam);
}

stock TG_GetRandomClient(TG_Team:team)
{
	decl clients[MAXPLAYERS + 1];
	new count = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (TG_GetPlayerTeam(i) == team) {
			clients[count] = i;
			count++;
		}
	}

	if (count == 0)
		return 0;

	return clients[GetRandomInt(0, count - 1)];
}

stock bool:TG_CheckModuleAccess(client, TG_ModuleType:type, const String:moduleID[])
{
	new String:typeID[128], iFlags;
	Format(typeID, sizeof(typeID), "%s-%s", (type == TG_MenuItem) ? "TG_MenuItem" : "TG_Game", moduleID);

	if (GetCommandOverride(typeID, Override_Command, iFlags)) {
		return CheckCommandAccess(client, typeID, iFlags);
	} else {
		if (GetCommandOverride(moduleID, Override_Command, iFlags)) {
			return CheckCommandAccess(client, moduleID, iFlags);
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

stock GivePlayerWeaponAndAmmo(client, String:weapon[], clip = -1, ammo = -1)
{
	new weaponEnt = GivePlayerItem(client, weapon);

	if (weaponEnt != -1) {
		if (clip != -1)
			SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clip);

		if (ammo != -1) {
			new iOffset = FindDataMapOffs(client, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(weaponEnt) * 4);
			SetEntData(client, iOffset, ammo, 4, true);

			if (GetEngineVersion() == Engine_CSGO) {
				SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
			}
		}
	}

	return weaponEnt;
}

stock SetPlayerWeaponAmmo(client, weaponEnt, clip = -1, ammo = -1)
{
	if (weaponEnt == INVALID_ENT_REFERENCE)
		return;

	if (clip != -1)
		SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clip);

	if (ammo != -1) {
		new iOffset = FindDataMapOffs(client, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(weaponEnt) * 4);
		SetEntData(client, iOffset, ammo, 4, true);

		if (GetEngineVersion() == Engine_CSGO) {
			SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
		}
	}
}
