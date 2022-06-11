#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "x07x08"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <tf2_stocks>

bool      g_bIgnoreHook;
ArrayList g_hWeaponsList;

public Plugin myinfo = 
{
	name = "[TF2] Explosion sound fix (based on Nanochip's fix)",
	author = PLUGIN_AUTHOR,
	description = "Fixes the looping sounds of explosions",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	AddTempEntHook("TFExplosion", OnTFExplosion);
	
	RegAdminCmd("sm_refreshexplosionfix", CmdRefreshConfig, ADMFLAG_CONFIG, "Reloads the weapons configuration file");
}

public void OnMapStart()
{
	ParseWeaponsConfig();
}

public Action CmdRefreshConfig(int iClient, int iArgs)
{
	ParseWeaponsConfig();
	
	ReplyToCommand(iClient, "[SM] Successfully refreshed the weapons configuration file");
	
	return Plugin_Handled;
}

void ParseWeaponsConfig()
{
	delete g_hWeaponsList;
	
	char strFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, strFilePath, sizeof(strFilePath), "configs/loopsoundlist.cfg");
	
	if (FileExists(strFilePath, true))
	{
		KeyValues kvConfig = new KeyValues("LoopSoundFix");
		
		if (kvConfig.ImportFromFile(strFilePath) && kvConfig.GotoFirstSubKey())
		{
			g_hWeaponsList = new ArrayList();
			
			do
			{
				AddWeapon(kvConfig);
			}
			while (kvConfig.GotoNextKey());
		}
		
		delete kvConfig;
	}
}

void AddWeapon(KeyValues kvConfig)
{
	char strWeaponIndex[8];
	int  iWeaponIndex;
	
	if (kvConfig.GetSectionName(strWeaponIndex, sizeof(strWeaponIndex)))
	{
		iWeaponIndex = StringToInt(strWeaponIndex);
		
		if (iWeaponIndex > 0 && (g_hWeaponsList.FindValue(iWeaponIndex) == -1))
		{
			g_hWeaponsList.Push(iWeaponIndex);
		}
	}
}

bool IsLooping(int iIndex)
{
	// If no config file is provided, replace all sounds
	return g_hWeaponsList == null ? true : g_hWeaponsList.FindValue(iIndex) == -1 ? false : true;
}

public Action OnTFExplosion(const char[] strTEName, const int[] iClients, int iNumClients, float fDelay)
{
	if (g_bIgnoreHook)
	{
		g_bIgnoreHook = false;
		
		return Plugin_Continue;
	}
	
	// The whole bug happens because m_nDefID isn't checked if it's a flamethrower (or a minigun).
	// The game plays the "SPECIAL1" sound, which in a flamethrower's case is the looping sound of the flames.
	// If m_nDefID is -1, it will not try to replace the sound at all.
	// To find which weapons have custom "SPECIAL1" sounds, go into "items_game.txt" and search for "sound_special1".
	
	TE_Start("TFExplosion");
	
	float vecNormal[3]; TE_ReadVector("m_vecNormal", vecNormal);
	int iDefID = TE_ReadNum("m_nDefID");
	
	TE_WriteFloat("m_vecOrigin[0]", TE_ReadFloat("m_vecOrigin[0]"));
	TE_WriteFloat("m_vecOrigin[1]", TE_ReadFloat("m_vecOrigin[1]"));
	TE_WriteFloat("m_vecOrigin[2]", TE_ReadFloat("m_vecOrigin[2]"));
	
	TE_WriteVector("m_vecNormal", vecNormal);
	
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("entindex",    TE_ReadNum("entindex"));
	// 21 is the stock flamethrower's defindex, which doesn't replace SPECIAL1
	TE_WriteNum("m_nDefID",    IsLooping(iDefID) ? 21 : iDefID);
	TE_WriteNum("m_nSound",    TE_ReadNum("m_nSound"));
	TE_WriteNum("m_iCustomParticleIndex", TE_ReadNum("m_iCustomParticleIndex"));
	
	g_bIgnoreHook = true;
	
	TE_Send(iClients, iNumClients, fDelay);
	
	return Plugin_Stop;
}
