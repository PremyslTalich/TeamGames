enum PlayerDataStruct
{
	TG_Team:Team, // player iTeam
	bool:MenuLock, // vote to unlock main menu
	bool:AbleToSwitch, // is able to switch to another iTeam
	String:DefaultModel[PLATFORM_MAX_PATH], // players default model (skin)
	bool:AbleToMark, // is able to make mark
	bool:AbleToFencePunishColor
}
new g_PlayerData[MAXPLAYERS + 1][PlayerDataStruct];

enum PlayerEquipment
{
	HP,
	Armor,
	bool:Bomb,
	bool:Knife,
	bool:Taser,
	TaserClip,
	TaserAmmo,
	HEGrenade,
	SmokeGrenade,
	FlashBang,
	MolotowCocktail,
	IncendiaryGrenade,
	DecoyGrenade,
	String:PrimaryWeapon[64],
	PrimaryClip,
	PrimaryAmmo,
	String:SecondaryWeapon[64],
	SecondaryClip,
	SecondaryAmmo
}
new g_PlayerEquipment[MAXPLAYERS + 1][PlayerEquipment];

ClearPlayerData(iClient)
{
	g_PlayerData[iClient][Team] = TG_NoneTeam;
	g_PlayerData[iClient][MenuLock] = true;
	g_PlayerData[iClient][AbleToSwitch] = true;
	g_PlayerData[iClient][AbleToMark] = true;
	g_PlayerData[iClient][AbleToFencePunishColor] = true;
}

GetCountPlayersInTeam(TG_Team:iTeam)
{
	if (iTeam == TG_ErrorTeam)
		return -1;

	new iCount = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (!Client_IsIngame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) == CS_TEAM_CT)
			continue;

		if (g_PlayerData[i][Team] == iTeam)
			iCount++;
	}

	return iCount;
}

SetPlayerEquipment(	iClient,
					iHP,
					iArmor,
					bool:bBomb,
					bool:bKnife,
					bool:bTaser,
					iTaserClip,
					iTaserAmmo,
					iHEGrenade,
					iSmokeGrenade,
					iFlashBang,
					iMolotowCocktail,
					iIncendiaryGrenade,
					iDecoyGrenade,
					String:sPrimaryWeapon[64],
					iPrimaryAmmo,
					iPrimaryClip,
					String:sSecondaryWeapon[64],
					iSecondaryAmmo,
					iSecondaryClip
				  )
{
	if (!Client_IsValid(iClient, false))
		return;

	g_PlayerEquipment[iClient][HP] = iHP;
	g_PlayerEquipment[iClient][Armor] = iArmor;
	g_PlayerEquipment[iClient][Bomb] = bBomb;
	g_PlayerEquipment[iClient][Knife] = bKnife;
	g_PlayerEquipment[iClient][Taser] = bTaser;
	g_PlayerEquipment[iClient][TaserClip] = iTaserClip;
	g_PlayerEquipment[iClient][TaserAmmo] = iTaserAmmo;
	g_PlayerEquipment[iClient][HEGrenade] = iHEGrenade;
	g_PlayerEquipment[iClient][SmokeGrenade] = iSmokeGrenade;
	g_PlayerEquipment[iClient][FlashBang] = iFlashBang;
	g_PlayerEquipment[iClient][MolotowCocktail] = iMolotowCocktail;
	g_PlayerEquipment[iClient][IncendiaryGrenade] = iIncendiaryGrenade;
	g_PlayerEquipment[iClient][DecoyGrenade] = iDecoyGrenade;
	strcopy(g_PlayerEquipment[iClient][PrimaryWeapon], 64, sPrimaryWeapon);
	g_PlayerEquipment[iClient][PrimaryAmmo] = iPrimaryAmmo;
	g_PlayerEquipment[iClient][PrimaryClip] = iPrimaryClip;
	strcopy(g_PlayerEquipment[iClient][SecondaryWeapon], 64, sSecondaryWeapon);
	g_PlayerEquipment[iClient][SecondaryAmmo] = iSecondaryAmmo;
	g_PlayerEquipment[iClient][SecondaryClip] = iSecondaryClip;
}

ClearPlayerEquipment(iClient)
{
	if (!Client_IsValid(iClient, false))
		return;

	SetPlayerEquipment(iClient, -1, -1, false, false, false, 0, 0, 0, 0, 0, 0, 0, 0, "", 0, 0, "", 0, 0);
}

SavePlayerEquipment(iClient, bool:bSaveHP = true, bool:bSaveArmor = true)
{
	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient))
		return;

	ClearPlayerEquipment(iClient);

	new iWeaponEntity = -1;
	decl String:sPrimaryWeapon[64], String:sSecondaryWeapon[64], String:sWeaponName[64];
	new iHP = -1, iArmor = -1;
	new iHEGrenade, iSmokeGrenade, iFlashBang, iMolotowCocktail, iIncendiaryGrenade, iDecoyGrenade;
	new iPrimaryAmmo, iPrimaryClip, iSecondaryAmmo, iSecondaryClip, iTaserClip, iTaserAmmo;
	new bool:bBomb = false, bool:bKnife = false, bool:bTaser = false, iTaser = INVALID_ENT_REFERENCE;

	if (bSaveHP)
		iHP =  GetClientHealth(iClient);

	if (bSaveArmor)
		iArmor = GetClientArmor(iClient);

	new iOffset = Client_GetWeaponsOffset(iClient) - 4;
	for (new i = 0; i < MAX_WEAPONS; i++) {
		iOffset += 4;

		iWeaponEntity = GetEntDataEnt2(iClient, iOffset);

		if (!Weapon_IsValid(iWeaponEntity))
			continue;

		GetWeaponClassName(iWeaponEntity, sWeaponName, sizeof(sWeaponName));

		if (StrEqual(sWeaponName, "weapon_knife"))
			bKnife = true;
		else if (StrEqual(sWeaponName, "weapon_taser"))
			iTaser = iWeaponEntity;
		else if (StrEqual(sWeaponName, "weapon_flashbang"))
			iFlashBang++;
		else if (StrEqual(sWeaponName, "weapon_smokegrenade"))
			iSmokeGrenade++;
		else if (StrEqual(sWeaponName, "weapon_hegrenade"))
			iHEGrenade++;
		else if (StrEqual(sWeaponName, "weapon_molotow"))
			iMolotowCocktail++;
		else if (StrEqual(sWeaponName, "weapon_incgrenade"))
			iIncendiaryGrenade++;
		else if (StrEqual(sWeaponName, "weapon_decoy"))
			iDecoyGrenade++;
		else if (StrEqual(sWeaponName, "weapon_c4"))
			bBomb = true;
	}

	if (iTaser != INVALID_ENT_REFERENCE) {
		bTaser = true;
		iTaserClip = GetEntProp(iTaser, Prop_Data, "m_iClip1");
		if (g_iEngineVersion == Engine_CSGO) {
			iPrimaryAmmo = GetEntProp(iTaser, Prop_Send, "m_iPrimaryReserveAmmoCount");
		} else {
			iPrimaryAmmo = GetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(iTaser) * 4));
		}
	}

	iWeaponEntity = GetPlayerWeaponSlot(iClient, 0);
	if (iWeaponEntity == -1) {
		strcopy(sPrimaryWeapon, 64, "");
	} else {
		GetWeaponClassName(iWeaponEntity, sPrimaryWeapon, sizeof(sPrimaryWeapon));

		iPrimaryClip = Weapon_GetPrimaryClip(iWeaponEntity);
		if (g_iEngineVersion == Engine_CSGO) {
			iPrimaryAmmo = GetEntProp(iWeaponEntity, Prop_Send, "m_iPrimaryReserveAmmoCount");
		} else {
			iPrimaryAmmo = GetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(iWeaponEntity) * 4));
		}
	}

	iWeaponEntity = GetPlayerWeaponSlot(iClient, 1);
	if (iWeaponEntity == -1) {
		strcopy(sSecondaryWeapon, 64, "");
	} else {
		GetWeaponClassName(iWeaponEntity, sSecondaryWeapon, sizeof(sSecondaryWeapon));

		iSecondaryClip = Weapon_GetPrimaryClip(iWeaponEntity);
		if (g_iEngineVersion == Engine_CSGO) {
			iSecondaryAmmo = GetEntProp(iWeaponEntity, Prop_Send, "m_iPrimaryReserveAmmoCount");
		} else {
			iSecondaryAmmo = GetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (Weapon_GetPrimaryAmmoType(iWeaponEntity) * 4));
		}
	}

	SetPlayerEquipment(iClient, iHP, iArmor, bBomb, bKnife, bTaser, iTaserClip, iTaserAmmo, iHEGrenade, iSmokeGrenade, iFlashBang, iMolotowCocktail, iIncendiaryGrenade, iDecoyGrenade, sPrimaryWeapon, iPrimaryAmmo, iPrimaryClip, sSecondaryWeapon, iSecondaryAmmo, iSecondaryClip);
}

PlayerEquipmentLoad(iClient)
{
	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient))
		return;

	Client_RemoveAllWeapons(iClient, "", true);

	if (g_PlayerEquipment[iClient][HP] > 0)
		SetEntityHealth(iClient, g_PlayerEquipment[iClient][HP]);

	if (g_PlayerEquipment[iClient][Armor] > -1)
		Client_SetArmor(iClient, g_PlayerEquipment[iClient][Armor]);

	if (g_PlayerEquipment[iClient][Knife])
		GivePlayerItem(iClient, "weapon_knife");

	if (g_PlayerEquipment[iClient][Bomb])
		GivePlayerItem(iClient, "weapon_c4");

	for (new i = 0; i < g_PlayerEquipment[iClient][HEGrenade]; i++)
		GivePlayerItem(iClient, "weapon_hegrenade");

	for (new i = 0; i < g_PlayerEquipment[iClient][SmokeGrenade]; i++)
		GivePlayerItem(iClient, "weapon_smokegrenade");

	for (new i = 0; i < g_PlayerEquipment[iClient][FlashBang]; i++)
		GivePlayerItem(iClient, "weapon_flashbang");

	for (new i = 0; i < g_PlayerEquipment[iClient][MolotowCocktail]; i++)
		GivePlayerItem(iClient, "weapon_molotow");

	for (new i = 0; i < g_PlayerEquipment[iClient][IncendiaryGrenade]; i++)
		GivePlayerItem(iClient, "weapon_incgrenade");

	for (new i = 0; i < g_PlayerEquipment[iClient][DecoyGrenade]; i++)
		GivePlayerItem(iClient, "weapon_decoy");

	if (g_PlayerEquipment[iClient][Taser])
		GivePlayerWeaponAndAmmo(iClient, "weapon_taser", g_PlayerEquipment[iClient][TaserClip], g_PlayerEquipment[iClient][TaserAmmo]);

	if (strlen(g_PlayerEquipment[iClient][PrimaryWeapon]) > 0)
		GivePlayerWeaponAndAmmo(iClient, g_PlayerEquipment[iClient][PrimaryWeapon], g_PlayerEquipment[iClient][PrimaryClip], g_PlayerEquipment[iClient][PrimaryAmmo]);

	if (strlen(g_PlayerEquipment[iClient][SecondaryWeapon]) > 0)
		GivePlayerWeaponAndAmmo(iClient, g_PlayerEquipment[iClient][SecondaryWeapon], g_PlayerEquipment[iClient][SecondaryClip], g_PlayerEquipment[iClient][SecondaryAmmo]);

	ClearPlayerEquipment(iClient);
}

GetWeaponClassName(iWeaponEntity, String:sWeaponName[], iSize)
{
	GetEntityClassname(iWeaponEntity, sWeaponName, iSize);

	if (StrEqual(sWeaponName, "weapon_m4a1") && GetEntProp(iWeaponEntity, Prop_Send, "m_iItemDefinitionIndex") == 60) {
		strcopy(sWeaponName, iSize, "weapon_m4a1_silencer");
	} else if (StrEqual(sWeaponName, "weapon_hkp2000") && GetEntProp(iWeaponEntity, Prop_Send, "m_iItemDefinitionIndex") == 61) {
		strcopy(sWeaponName, iSize, "weapon_usp_silencer");
	} else if (StrEqual(sWeaponName, "weapon_p250") && GetEntProp(iWeaponEntity, Prop_Send, "m_iItemDefinitionIndex") == 63) {
		strcopy(sWeaponName, iSize, "weapon_cz75a");
	}
}
