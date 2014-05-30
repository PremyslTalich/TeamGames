new Handle:gh_SaveWeapons = INVALID_HANDLE;

enum PlayerDataStruct
{
	TG_Team:Team, // player team
	bool:MenuLock, // vote to unlock main menu
	bool:AbleToSwitch, // is able to switch to another team
	String:DefaultModel[ PLATFORM_MAX_PATH ], // player default model (skin)
	bool:AbleToMark // is able to make mark
}
new g_PlayerData[ MAXPLAYERS + 1 ][ PlayerDataStruct ];

enum PlayerEquipment
{
    HP,
	Armor,
	bool:Bomb,
	bool:Knife,
	HEGrenade,
	SmokeGrenade,
	FlashBang,
	String:PrimaryWeapon[ 64 ],
	PrimaryAmmo,
	PrimaryClip,
    String:SecondaryWeapon[ 64 ],
	SecondaryAmmo,
	SecondaryClip
}
new g_PlayerEquipment[ MAXPLAYERS + 1 ][ PlayerEquipment ];

ClearPlayerData( client )
{
	g_PlayerData[ client ][ Team ] = NoneTeam;
	g_PlayerData[ client ][ MenuLock ] = true;
	g_PlayerData[ client ][ AbleToSwitch ] = true;
	g_PlayerData[ client ][ AbleToMark ] = true;
}

GetCountPlayersInTeam( TG_Team:team )
{
	if( team == ErrorTeam )
		return -1;
	
	new count = 0;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( !Client_IsIngame( i ) || !IsPlayerAlive( i ) )
			continue;
		
		if( GetClientTeam( i ) == CS_TEAM_CT )
			continue;
		
		if( g_PlayerData[ i ][ Team ] == team )
			count++;
	}
	
	return count;
}

SetPlayerEquipment( client, hp, armor, bool:bomb, bool:knife, hegrenade, smokegrenade, flashbang, String:primaryweapon[ 64 ], primaryammo, primaryclip, String:secondaryweapon[ 64 ], secondaryammo, secondaryclip )
{
	if( !Client_IsValid( client, false ) )
		return;
	
	g_PlayerEquipment[ client ][ HP ] = hp;
	g_PlayerEquipment[ client ][ Armor ] = armor;
	g_PlayerEquipment[ client ][ Bomb ] = bomb;
	g_PlayerEquipment[ client ][ Knife ] = knife;
	g_PlayerEquipment[ client ][ HEGrenade ] = hegrenade;
	g_PlayerEquipment[ client ][ SmokeGrenade ] = smokegrenade;
	g_PlayerEquipment[ client ][ FlashBang ] = flashbang;
	strcopy( g_PlayerEquipment[ client ][ PrimaryWeapon ], 64, primaryweapon );
	g_PlayerEquipment[ client ][ PrimaryAmmo ] = primaryammo;
	g_PlayerEquipment[ client ][ PrimaryClip ] = primaryclip;
	strcopy( g_PlayerEquipment[ client ][ SecondaryWeapon ], 64, secondaryweapon );
	g_PlayerEquipment[ client ][ SecondaryAmmo ] = secondaryammo;
	g_PlayerEquipment[ client ][ SecondaryClip ] = secondaryclip;
}

ClearPlayerEquipment( client )
{
	if( !Client_IsValid( client, false ) )
		return;
	
	SetPlayerEquipment( client, -1, -1, false, false, 0, 0, 0, "", 0, 0, "", 0, 0 );
}

SavePlayerEquipment( client, bool:save_hp = true, bool:save_armor = true )
{
	if( !Client_IsIngame( client ) || !IsPlayerAlive( client ) )
		return;
	
	ClearPlayerEquipment( client );
	
	new WeaponEntity = -1;
	decl String:primaryweapon[ 64 ], String:secondaryweapon[ 64 ], String:WeaponName[ 64 ];
	new hp = -1, armor = -1, hegrenade, smokegrenade, flashbang, primaryammo, primaryclip, secondaryammo, secondaryclip;
	new bool:bomb = false, bool:knife = false;
	
	if( save_hp )
		hp =  GetClientHealth( client );
	
	if( save_armor )
		armor = GetClientArmor( client );
	
	new offset = Client_GetWeaponsOffset( client ) - 4;	
	for( new i = 0; i < MAX_WEAPONS; i++ )
	{
		offset += 4;

		WeaponEntity = GetEntDataEnt2( client, offset );
		
		if( !Weapon_IsValid( WeaponEntity ) )
			continue;
		
		Entity_GetClassName( WeaponEntity, WeaponName, sizeof( WeaponName ) );
		
		if( StrEqual( WeaponName, "weapon_knife" ) )
			knife = true;
		else if( StrEqual( WeaponName, "weapon_flashbang" ) )
			flashbang++;
		else if( StrEqual( WeaponName, "weapon_smokegrenade" ) )
			smokegrenade++;
		else if( StrEqual( WeaponName, "weapon_hegrenade" ) )
			hegrenade++;
		else if( StrEqual( WeaponName, "weapon_c4" ) )
			bomb = true;
	}
		
	WeaponEntity = GetPlayerWeaponSlot( client, 0 );	
	if( WeaponEntity == -1 )
	{
		strcopy( primaryweapon, 64, "" );
	}
	else
	{
		Entity_GetClassName( WeaponEntity, primaryweapon, sizeof( primaryweapon ) );
		
		primaryammo = GetEntData( client, FindDataMapOffs( client, "m_iAmmo" ) + ( Weapon_GetPrimaryAmmoType( WeaponEntity ) * 4 ) );
		primaryclip = Weapon_GetPrimaryClip( WeaponEntity );
	}
	
	WeaponEntity = GetPlayerWeaponSlot( client, 1 );
	if( WeaponEntity == -1 )
	{
		strcopy( secondaryweapon, 64, "" );
	}
	else
	{
		Entity_GetClassName( WeaponEntity, secondaryweapon, sizeof( secondaryweapon ) );
		
		secondaryammo = GetEntData( client, FindDataMapOffs( client, "m_iAmmo" ) + ( Weapon_GetPrimaryAmmoType( WeaponEntity ) * 4 ) );
		secondaryclip = Weapon_GetPrimaryClip( WeaponEntity );
	}
	
	SetPlayerEquipment( client, hp, armor, bomb, knife, hegrenade, smokegrenade, flashbang, primaryweapon, primaryammo, primaryclip, secondaryweapon, secondaryammo, secondaryclip );
}

PlayerEquipmentLoad( client )
{
	if( !Client_IsIngame( client ) || !IsPlayerAlive( client ) )
		return;
	
	Client_RemoveAllWeapons( client, "", true );
	
	if( g_PlayerEquipment[ client ][ HP ] > 0 )
		SetEntityHealth( client, g_PlayerEquipment[ client ][ HP ] );
	
	if( g_PlayerEquipment[ client ][ Armor ] > -1 )
		Client_SetArmor( client, g_PlayerEquipment[ client ][ Armor ] );
	
	if( g_PlayerEquipment[ client ][ Knife ] )
		Client_GiveWeapon( client, "weapon_knife", true );
	
	if( g_PlayerEquipment[ client ][ Bomb ] )
		Client_GiveWeapon( client, "weapon_c4", false );
	
	for( new i = 0; i < g_PlayerEquipment[ client ][ HEGrenade ]; i++ )
		Client_GiveWeapon( client, "weapon_hegrenade", false );
	
	for( new i = 0; i < g_PlayerEquipment[ client ][ SmokeGrenade ]; i++ )
		Client_GiveWeapon( client, "weapon_smokegrenade", false );
	
	for( new i = 0; i < g_PlayerEquipment[ client ][ FlashBang ]; i++ )
		Client_GiveWeapon( client, "weapon_flashbang", false );
	
	if( strlen( g_PlayerEquipment[ client ][ PrimaryWeapon ] ) > 0 )
		Client_GiveWeaponAndAmmo( client, g_PlayerEquipment[ client ][ PrimaryWeapon ], false, g_PlayerEquipment[ client ][ PrimaryAmmo ], _, g_PlayerEquipment[ client ][ PrimaryClip ], _ );
	
	if( strlen( g_PlayerEquipment[ client ][ SecondaryWeapon ] ) > 0 )
		Client_GiveWeaponAndAmmo( client, g_PlayerEquipment[ client ][ SecondaryWeapon ], false, g_PlayerEquipment[ client ][ SecondaryAmmo ], _, g_PlayerEquipment[ client ][ SecondaryClip ], _ );
	
	ClearPlayerEquipment( client );
}
