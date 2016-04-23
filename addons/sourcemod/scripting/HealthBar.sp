enum HealthBarTemplate
{
	bool:Used,
	String:Sprite[PLATFORM_MAX_PATH],
	String:Color[12],
	Alpha,
	Float:Offset,
	Float:Scale
};

enum PlayerHealthBar
{
	CurrentTemplate,
	Entity,
	MaxHealth,
	bool:AutomaticDestroy
};

new g_iHPBarTemplate[11][HealthBarTemplate];
new g_iPlayerHPBar[MAXPLAYERS + 1][PlayerHealthBar];

UpdateHealthBar(iClient, bool:bCheckExistence = true)
{
	if (bCheckExistence && g_iPlayerHPBar[iClient][CurrentTemplate] == 0)
		return false;

	if (!Client_IsIngame(iClient) || !IsPlayerAlive(iClient) || g_iPlayerHPBar[iClient][MaxHealth] < 1)
		return false;

	new iHealth = GetClientHealth(iClient);
	new iDecPercent = RoundToNearest(g_iPlayerHPBar[iClient][MaxHealth] / 10.0);
	new iTemplate = 0;

	for (new i = 10; i >= 1; i--) {
		if (i * iDecPercent >= iHealth) {
			if (g_iHPBarTemplate[i][Used]) {
				iTemplate = i;
			}
		} else {
			break;
		}
	}

	if (iTemplate != 0 && g_iPlayerHPBar[iClient][CurrentTemplate] != iTemplate) {
		RemoveHealthBar(iClient);

		g_iPlayerHPBar[iClient][Entity] = AttachHealthBar(iClient, iTemplate);
		if (g_iPlayerHPBar[iClient][Entity] != INVALID_ENT_REFERENCE) {
			g_iPlayerHPBar[iClient][CurrentTemplate] = iTemplate;

			if (!g_Game[HealthBarVisibility]) {
				SDKHook(g_iPlayerHPBar[iClient][Entity], SDKHook_SetTransmit, Hook_HealthBarTransmit);
			}

			return true;
		} else {
			return false;
		}
	} else {
		return false;
	}
}

AttachHealthBar(iClient, iTemplate)
{
	new iSprite;
	if ((iSprite = CreateEntityByName("env_sprite_oriented")) != INVALID_ENT_REFERENCE) {
		new Float:fPos[3];
		GetClientAbsOrigin(iClient, fPos);
		fPos[2] += 73.0 + g_iHPBarTemplate[iTemplate][Offset];

		DispatchKeyValueFormat(iSprite, "targetname", "[TG HEALTHBAR] %d", GetClientUserId(iClient));

		DispatchKeyValue(iSprite, "model", g_iHPBarTemplate[iTemplate][Sprite]);
		DispatchKeyValueFloat(iSprite, "scale", g_iHPBarTemplate[iTemplate][Scale]);

		DispatchKeyValue(iSprite, "rendermode", "5");
		DispatchKeyValue(iSprite, "spawnflags", "1");

		DispatchKeyValue(iSprite, "rendercolor", g_iHPBarTemplate[iTemplate][Color]);
		DispatchKeyValueNum(iSprite, "RenderAmt", g_iHPBarTemplate[iTemplate][Alpha]);

		DispatchSpawn(iSprite);
		TeleportEntity(iSprite, fPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(iSprite, "SetParent", iClient);
	}

	return iSprite;
}

RemoveHealthBar(iClient)
{
	if (g_iPlayerHPBar[iClient][Entity] != INVALID_ENT_REFERENCE && g_iPlayerHPBar[iClient][Entity] != 0) {
		RemoveEdict(g_iPlayerHPBar[iClient][Entity]);
	}

	g_iPlayerHPBar[iClient][Entity] = INVALID_ENT_REFERENCE;
	g_iPlayerHPBar[iClient][CurrentTemplate] = 0;
}

public Action:Hook_HealthBarTransmit(iEntity, iClient)
{
	if (!g_Game[HealthBarVisibility] && TG_IsPlayerRedOrBlue(iClient)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}