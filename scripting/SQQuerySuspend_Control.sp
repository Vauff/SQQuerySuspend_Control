#include <sourcemod>
#include <dhooks>
#include <stocksoup/memory>

#pragma semicolon 1
#pragma newdecls required

#define SQ_QUERY_CONTINUE 0
#define SQ_QUERY_BREAK 1
#define SQ_QUERY_SUSPEND 2

public Plugin myinfo =
{
	name = "SQQuerySuspend Threshold Control",
	author = "Vauff",
	description = "Modifies the extremely short VScript execution timeout",
	version = "1.0",
	url = "https://github.com/Vauff/SQQuerySuspend_Control"
};

Handle g_hQueryContinue;
ConVar g_cvTimeoutThreshold;
Address g_aQueryContinueDb;

public void OnPluginStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "gamedata/SQQuerySuspend_Control.games.txt");

	if (!FileExists(path))
		SetFailState("Can't find SQQuerySuspend_Control.games.txt gamedata");

	GameData gameData = LoadGameConfigFile("SQQuerySuspend_Control.games");
	
	if (gameData == INVALID_HANDLE)
		SetFailState("Can't find SQQuerySuspend_Control.games.txt gamedata");

	g_hQueryContinue = DHookCreateFromConf(gameData, "QueryContinue");
	g_aQueryContinueDb = gameData.GetMemSig("QueryContinueDb");
	CloseHandle(gameData);

	if (!g_hQueryContinue)
		SetFailState("Failed to setup detour for QueryContinue");

	if (!DHookEnableDetour(g_hQueryContinue, false, Detour_QueryContinue_Pre))
		SetFailState("Failed to pre-detour QueryContinue");

	if (!DHookEnableDetour(g_hQueryContinue, true, Detour_QueryContinue_Post))
		SetFailState("Failed to post-detour QueryContinue");

	g_cvTimeoutThreshold = CreateConVar("sm_vscript_timeout_threshold", "2.0", "How long to allow VScript code to execute before force terminating it. 0.0 = no limit", _, true, 0.0);
	HookConVarChange(g_cvTimeoutThreshold, ThresholdChanged);
	AutoExecConfig(true, "SQQuerySuspend_Control");

	// Force a patch incase SQQuerySuspend_Control.cfg has default value and didn't trigger ConVar change
	PatchTimeoutThreshold(g_cvTimeoutThreshold.FloatValue);
}

public MRESReturn Detour_QueryContinue_Pre(DHookReturn hReturn, DHookParam hParams)
{
	if (g_cvTimeoutThreshold.FloatValue == 0.0)
	{
		DHookSetReturn(hReturn, SQ_QUERY_CONTINUE);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn Detour_QueryContinue_Post(DHookReturn hReturn, DHookParam hParams)
{
	if (DHookGetReturn(hReturn) == SQ_QUERY_BREAK)
		LogError("WARNING: VScript execution timed out with a threshold of %fs", g_cvTimeoutThreshold.FloatValue);

	return MRES_Ignored;
}

public void ThresholdChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PatchTimeoutThreshold(convar.FloatValue);
}

void PatchTimeoutThreshold(float timeout)
{
	// 0.0 is treated as no timeout threshold
	if (timeout != 0.0)
		StoreDoubleToAddressFromFloat(g_aQueryContinueDb, timeout);
}