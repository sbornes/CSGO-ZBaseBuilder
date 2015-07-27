/*

 |__   __/ __ \  |  __ \ / __ \  | |    |_   _|/ ____|__   __|
    | | | |  | | | |  | | |  | | | |      | | | (___    | |   
    | | | |  | | | |  | | |  | | | |      | |  \___ \   | |   
    | | | |__| | | |__| | |__| | | |____ _| |_ ____) |  | |   
    |_|  \____/  |_____/ \____/  |______|_____|_____/   |_|   
                                                            


 */                                                    

#define VERSION "1.0.6"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <clientprefs>
#include <emitsoundany>

#pragma dynamic 131072 
#pragma newdecls required 

#define IsValidClient(%1)  ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )
#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

#define CLANTAG 				"SAUGN |"

#define SPECTATOR_TEAM 			0
#define TEAM_SPEC 				1
#define TEAM_ZOMBIES			2
#define TEAM_BUILDERS			3
#define MAINMENUITEMS			6
#define EXP_NODAMAGE            1
#define EXP_NODECAL             16

#define MAXCOLOURS 25
#define MAXENTS 1365

#define ACH_SOUND "zbb/achievement.mp3"

#define MAX_ACHIEVEMENTS 17
       
#define ACHIEVE_ZKILLS          0
#define ACHIEVE_HKILLS          1
#define ACHIEVE_OBJMOVED        2
#define ACHIEVE_HEADSHOTS       3
#define ACHIEVE_CONNECTS        4
#define ACHIEVE_CLUBDREAD       5
#define ACHIEVE_KNIFEZOMBIE     6
#define ACHIEVE_HITMAN          7
#define ACHIEVE_RAMBO           8
#define ACHIEVE_WAR             9
#define ACHIEVE_ARMS            10
#define ACHIEVE_BANK            11
#define ACHIEVE_HUNT            12
#define ACHIEVE_HP              13
#define ACHIEVE_AP              14
#define ACHIEVE_GR              15
#define ACHIEVE_SP              16

#define LEVEL_NONE              0
#define LEVEL_I                 1

public Plugin myinfo =
{
	name = "ZBB Mod",
	author = "sbornes",
	description = "ZBB",
	version = VERSION,
	url = "http://www.sbornes-portfolio.com/"
};

// COOKIES
Handle g_hPrimWepCookie = null;
Handle g_hSecWepCookie = null;
Handle g_hColourCookie = null;

bool gShowMSG[MAXPLAYERS+1];

int g_round;
bool gamestart;

Handle gConnectMSG[MAXPLAYERS+1] = null;
// Phase / Timer Stuff
Handle gPhase_1_BuildTime = null;
Handle gPhase_1 = null;
Handle gPhase_2 = null;
Handle gPhase_3 = null;
Handle gPhase_3_CountdownPre = null;
Handle gPhase_3_Countdown = null;
int zbb_phase;
int zbb_TimerTick;
int zbb_Countdown_Sound;
// Credit Gain Stuff
int PlayerCredit[MAXPLAYERS+1];
Handle zbb_ratio = null;
Handle g_kDMGXP = null;
Handle g_kBuilderWin = null;
Handle g_kZombieWin = null;
Handle g_kBuilderKill = null;
Handle g_kZombieKill = null;
Handle g_PDMGThreshold = null;
float BuilderDamage[MAXPLAYERS+1];
// Zombie Upgrades
Handle Zombie_StandardHP = null;
Handle Zombie_HPBonusPerLevel = null;
Handle Zombie_HPBonusPerLevelCost = null;
Handle Zombie_GravityBonusPerLevel = null;
Handle Zombie_GravityBonusPerLevelCost = null;
Handle Zombie_SpeedBonusPerLevel = null;
Handle Zombie_SpeedBonusPerLevelCost = null;
Handle Zombie_ArmourBonusPerLevel = null;
Handle Zombie_ArmourBonusPerLevelCost = null;
int Zombie_HPlevel[MAXPLAYERS+1];
int Zombie_Gravitylevel[MAXPLAYERS+1];
int Zombie_Speedlevel[MAXPLAYERS+1];
int Zombie_Armourlevel[MAXPLAYERS+1];
int g_pHPCost[MAXPLAYERS+1], 
g_pARCost[MAXPLAYERS+1], 
g_pGRCost[MAXPLAYERS+1],
g_pSPCost[MAXPLAYERS+1],
g_bHPCost[MAXPLAYERS+1];

// Builder Upgrades
Handle Builder_HPBonusPerLevel = null;
Handle Builder_HPBonusPerLevelCost = null
Handle zbb_FirstConnect_Credit = null;
Handle g_RespawnDelay = null;
Handle zbb_buildtime;
Handle zbb_pregametime;
Handle zbb_respawn_phase2;
Handle zbb_human_respawn;
Handle g_CreditMultiply;
Handle g_CreditMultiplyCLAN;
Handle hDatabase = null;
int Builder_HPlevel[MAXPLAYERS+1];
int Builder_Spawnlevel[MAXPLAYERS+1];
int g_remember_primary[MAXPLAYERS+1];
int g_remember_secondary[MAXPLAYERS+1];

// Other
int FirstConnect[MAXPLAYERS+1];
int g_remember_colour[MAXPLAYERS+1];
int LastTeam[MAXPLAYERS+1];
int LastTeamCT, LastTeamT;

bool has_used_pistol[MAXPLAYERS+1];
int totaldamage[MAXPLAYERS+1];

// Team name
Handle g_Terrorist = null;
Handle g_CTerrorist = null;
Handle g_hCvarTeamName1  = null;
Handle g_hCvarTeamName2 = null;

// +GRAB STUFF
bool g_Status[MAXPLAYERS+1]; // Is client using hook, grab, or rope
bool g_Grabbed[MAXPLAYERS+1];
bool EntLocSaved[MAXENTS]
bool g_Attracting[MAXPLAYERS+1];
bool g_Repelling[MAXPLAYERS+1];
int g_Targetindex[MAXPLAYERS+1];
int g_EntClaim[MAXENTS];
int Dummy[MAXENTS];
float g_MaxSpeed[MAXPLAYERS+1];
float targetlocstore[3];
float ANGLE[3];
float g_Distance[MAXPLAYERS+1];
float EntLocSave[MAXENTS][3];
// Offset variables
int OriginOffset;
// Beam
int RED[MAXPLAYERS+1];
int BLUE[MAXPLAYERS+1];
int GREEN[MAXPLAYERS+1];
bool colourselected[MAXPLAYERS+1];
int precache_laser;

// Achievements
int numofachieve[MAXPLAYERS+1];
int g_PlayerAchievements[MAXPLAYERS+1][MAX_ACHIEVEMENTS];
int zombiekills[MAXPLAYERS+ 1];
int humankills[MAXPLAYERS+1];
int objectsmoved[MAXPLAYERS+1];
int headshots[MAXPLAYERS+1];
int connects[MAXPLAYERS+1];
int clubdread[MAXPLAYERS+1];
int pistolonly[MAXPLAYERS+1];
int weaponsbought[MAXPLAYERS+1];

char ACHIEVEMENTS[MAX_ACHIEVEMENTS][2][]=
{
	{ "","Zombie Genocidist"}, // Kills as a human
	{ "","Hmm... Tasty"}, // Kills as a zombie
	{ "","Base Builder"}, // Total # objects moved
	{ "","Cr0wned"}, // Total # objects moved
	{ "","One inch at a time"}, // Total # of connections
	{ "","Dead Wreckening"}, // Kill a zombie with a knife
	{ "","Guns are for girls"}, // Deal out 1000 damage as a zombie
	{ "","Hitman"}, // Survive a round /w only pistols
	{ "","Rambo"}, // Unlock the M249-SAW
	{ "","War Machine"}, // Unlock all of the guns in the game
	{ "","Arms Dealer"}, // Unlock half of the guns in the game
	{ "","Break the Bank"}, // Accumulate 5000 credits without spending any
	{ "","Achievement Hunter"}, // Unlock all of the achievements in the game
	{ "","Juggernaut"}, // Upgrade to the max health level
	{ "","Solid Steel"}, // Upgrade to the max armor level
	{ "","Zero Gravity"}, // Upgrade to the max gravity level
	{ "","Speed Demon"} // Upgrade to the max speed level
}

char ACHIEVEMENTSDESC[][]=
{
	"Slaughter 100 zombies",
	"Kill 25 builders",
	"Move 10000 objects",
	"Get 50 headshots",
	"????????",
	"Deal 5000 damage as a zombie",
	"Knife a zombie",
	"Survive a round only using pistols",
	"Unlock the M249",
	"Unlock half of the guns in the game",
	"Unlock all of the guns in the game",
	"Reach 5000 credits",
	"Unlock all of the achievements in the game",
	"Upgrade to the max health level",
	"Upgrade to the max armor level",
	"Upgrade to the max gravity level",
	"Upgrade to the max speed level"
}


char PRIMCONST[][] = 
{ 
	"weapon_bizon",
	"weapon_galilar",
	"weapon_aug",
	"weapon_m4a1",
	"weapon_famas",
	"weapon_ak47",
	"weapon_mp7",
	"weapon_mac10",
	"weapon_ump",
	"weapon_p90",
	"weapon_nova",
	"weapon_xm1014",
	"weapon_scout",
	"weapon_awp",
	"weapon_m249"
}

char SECONDCONST[][] = 
{ 
	"weapon_hkp2000",
	"weapon_p250",
	"weapon_fiveseven",
	"weapon_elite",
	"weapon_glock",
	"weapon_deagle"
}


char g_MainMenu[][] = 
{
	"Load Out",
	"Unlock Guns",
	"Upgrade Zombie",
	"Upgrade Builder",
	"Achievements",
	"Help"
}

bool colourRainbow[MAXPLAYERS+1]
int g_ColorRED[]=
{
        200,
        255,
        255,
        255,
        255,
        252,
        254,
        059,
        197,
        000,
        120,
        135,
        128,
        000,
        146,
        255,
        246,
        205,
        250,
        234,
        180,
        149,
        0,
        255,
        255
};

int g_ColorGREEN[] =
{
		000,
		083,
		117,
		174,
		207,
		232,
		254,
		176,
		227,
		150,
		219,
		206,
        218,
		000,
		110,
		105,
		100,
		074,
		167,
		126,
		103,
		145,
		0,
		255,
		255
};

int g_ColorBLUE[] =
{
        000,
        073,
        056,
        066,
        171,
        131,
        034,
        143,
        132,
        000,
        226,
        235,
        235,
        255,
        174,
        180,
        175,
        076,
        108,
        093,
        077,
        140,
        0,
        255,
        255
};

char g_ColorName[][] =
{
	"Red",
	"Red Orange",
	"Orange",
	"Yellow Orange",
	"Peach",
	"Yellow",
	"Lemon Yellow",
	"Jungle Green",
	"Yellow Green",
	"Green",
	"Aquamarine",
	"Baby Blue",
	"Sky Blue",
	"Blue",
	"Violet",
	"Hot Pink",
	"Magenta",
	"Mahogany",
	"Tan",
	"Light Brown",
	"Brown",
	"Gray",
	"Black",
	"White",
	"Rainbow(VIP/ADMINS)"
};

int g_galil[MAXPLAYERS+1], g_aug[MAXPLAYERS+1], g_m4a4[MAXPLAYERS+1], g_famas[MAXPLAYERS+1], g_ak47[MAXPLAYERS+1],
	g_mp7[MAXPLAYERS+1], g_mac10[MAXPLAYERS+1], g_ump[MAXPLAYERS+1], g_p90[MAXPLAYERS+1],
	g_nova[MAXPLAYERS+1], g_xm1014[MAXPLAYERS+1], g_scout[MAXPLAYERS+1], g_awp[MAXPLAYERS+1], g_para[MAXPLAYERS+1],
	g_p228[MAXPLAYERS+1], g_five[MAXPLAYERS+1], g_elite[MAXPLAYERS+1], g_glock[MAXPLAYERS+1], g_deagle[MAXPLAYERS+1]

char g_sServerIp[16];
public void OnPluginStart()
{
    
	int iIp = GetConVarInt(FindConVar("hostip"));
	Format(g_sServerIp, sizeof(g_sServerIp), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF, (iIp >> 16) & 0x000000FF, (iIp >>  8) & 0x000000FF, iIp & 0x000000FF);
  	if( !StrEqual( g_sServerIp, "221.121.139.146") )
  		SetFailState( " ServersAU.com | ZBB. PRIVATE PLUGIN")

	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre); 
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);

	RegConsoleCmd("+grab", GrabCmd);
	RegConsoleCmd("-grab", DropCmd);

	RegConsoleCmd("sm_phase", Command_Phase, "Shows information on current phase");
	RegConsoleCmd("sm_ratio", Command_Ratio, "Shows Ratio Information");
	RegConsoleCmd("sm_zbb", Command_MainMenu, "Shows Main Menu");
	RegConsoleCmd("sm_help", Command_HelpMenu, "Shows Help Menu");
	RegConsoleCmd("sm_givecredit", Command_AdminPre, "Shows AdminMenu");
	RegConsoleCmd("sm_loadout", Command_Loadout, "Shows loudout Menu");
	RegConsoleCmd("sm_respawn", Command_Respawn, "Respawn Late Joiners");
	RegConsoleCmd("sm_spawn", Command_Respawn, "Respawn Late Joiners");
	RegConsoleCmd("sm_achievements", Command_Achievements, "List of Achievements");
	RegConsoleCmd("sm_colour", Command_colourMenu, "Shows Colour Menu");
	//AddCommandListener(Command_BuyAmmo, "buyammo1");
	//AddCommandListener(Command_BuyAmmo, "buyammo2");

	zbb_ratio = CreateConVar("sm_zbb_ratio", "3", "Every X zombies equals to +1 to base");
	zbb_human_respawn 				= CreateConVar("zbb_human_respawn", "1", "0 = disable / 1 = enable // Respawn dead humans as zombies");
	zbb_respawn_phase2 				= CreateConVar("zbb_respawn_phase2", "0", "0 = disable / 1 = enable // Respawn Players on Phase 2 to check base validity?");
	zbb_buildtime 					= CreateConVar("sm_zbb_buildtime", "150.0", "Build Time");
	zbb_pregametime 				= CreateConVar("sm_zbb_pregametime", "30.0", "Pre Game Time");
	Zombie_StandardHP 				= CreateConVar("sm_zbb_zombiehp", "2000", "Zombie HP");
	g_kDMGXP 						= CreateConVar("sm_zbb_dmg_zombie", "1", "How much Points for damaging an zombie");
	g_PDMGThreshold 				= CreateConVar("sm_zbb_dmg_threshold", "1000", "How much damage before gaining Credit");
	g_kBuilderWin 					= CreateConVar("sm_zbb_Hwin_credit", "25", "How much credit builders win");
	g_kZombieWin 					= CreateConVar("sm_zbb_Zwin_credit", "10", "How much credit Zombies win");
	g_kBuilderKill 					= CreateConVar("sm_zbb_bkill_credit", "5", "How much credit per builder kill");
	g_kZombieKill 					= CreateConVar("sm_zbb_zkill_credit", "15", "How much credit per zombie kill");
	g_CreditMultiply 				= CreateConVar("sm_zbb_credit_multiply", "1.0", "credit Multiply");
	g_CreditMultiplyCLAN 			= CreateConVar("sm_zbb_credit_multiplyCLAN", "2", "credit Multiply for clan tags");
	g_RespawnDelay 					= CreateConVar("sm_zbb_respawn_delay", "3.0", "How many seconds to delay the respawn");

	Builder_HPBonusPerLevel 		= CreateConVar("sm_zbb_upgrade_humanhp", "15", "Human HP Per Level");
	Builder_HPBonusPerLevelCost 	= CreateConVar("sm_zbb_upgrade_builderhpcost", "50", "Zombie HP Per Level Cost");
	Zombie_HPBonusPerLevel 			= CreateConVar("sm_zbb_upgrade_zombiehp", "100", "Zombie HP Per Level");
	Zombie_HPBonusPerLevelCost 		= CreateConVar("sm_zbb_upgrade_zombiehpcost", "30", "Zombie HP Per Level Cost");
	Zombie_GravityBonusPerLevel 	= CreateConVar("sm_zbb_upgrade_zombiegravity", "0.02", "Zombie Gravity Decrease Per Level");
	Zombie_GravityBonusPerLevelCost = CreateConVar("sm_zbb_upgrade_zombiegravitycost", "30", "Zombie Gravity Decrease Per Level Cost");
	Zombie_SpeedBonusPerLevel 		= CreateConVar("sm_zbb_upgrade_zombiespeed", "0.01", "Zombie Speed Per Level");
	Zombie_SpeedBonusPerLevelCost 	= CreateConVar("sm_zbb_upgrade_zombiespeedcost", "29", "Zombie Speed Per Level Cost");
	Zombie_ArmourBonusPerLevel 		= CreateConVar("sm_zbb_upgrade_zombiearmour", "10", "Zombie Armour Per Level");
	Zombie_ArmourBonusPerLevelCost 	= CreateConVar("sm_zbb_upgrade_zombiearmourcost", "25", "Zombie Armour Per Level Cost");

	zbb_FirstConnect_Credit 		= CreateConVar("sm_zbb_firstconnect_credit", "1000", "Amount of credit you get for first time connection")

	g_Terrorist 					= CreateConVar("sm_teamname_t", "Zombies", "Set your Terrorist team name.", FCVAR_PLUGIN);
	g_CTerrorist 					= CreateConVar("sm_teamname_ct", "Base Builders", "Set your Counter-Terrorist team name.", FCVAR_PLUGIN);
	
	HookConVarChange(g_Terrorist, OnConVarChange);
	HookConVarChange(g_CTerrorist, OnConVarChange);
	
	g_hCvarTeamName1 				= FindConVar("mp_teamname_1");
	g_hCvarTeamName2 				= FindConVar("mp_teamname_2");

	MySQL_Init();

	// Find offsets
	OriginOffset = FindSendPropOffs("CBaseEntity", "m_vecOrigin");
	if(OriginOffset == -1)
		SetFailState("Error: Failed to find the origin offset, aborting");

	g_hPrimWepCookie = RegClientCookie("zbb_primarywep", "ZBB Prim Wep Loadout", CookieAccess_Protected);
	g_hSecWepCookie  = RegClientCookie("zbb_secondarywep", "ZBB Sec Wep Loadout", CookieAccess_Protected);
	g_hColourCookie  = RegClientCookie("zbb_colour", "ZBB Beam Colour", CookieAccess_Protected);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("set_p_credit", Native_SetPlayerCredit);
	CreateNative("get_p_credit", Native_GetPlayerCredit);

	return APLRes_Success;
}


public Action Command_colourMenu(int client, int args)
{
	Colour(client);
}

public Action Colour(int client)
{
	Handle menu = CreateMenu(Colour_Handle);

	char szMsg[128];
	char szItems[128];

	Format(szMsg, sizeof( szMsg ), "ZBB Beam Colour\n----------------------");
	
	SetMenuTitle(menu, szMsg);

	for (int item_id = 0; item_id < MAXCOLOURS; item_id++)
	{

		Format(szItems, sizeof( szItems ), "%s", g_ColorName[item_id] );

		AddMenuItem(menu, "class_id", szItems);
	}


	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int Colour_Handle(Handle menu, MenuAction action, int client, int item)
{

	if( action == MenuAction_Select )
	{
		if( item == 24 )
		{
			if( Client_HasAdminFlags(client, ADMFLAG_ROOT) || Client_HasAdminFlags(client, ADMFLAG_CUSTOM1))
			{
				colourRainbow[client] = true;
			}
			else
			{
				PrintToChat(client, "You do not have permissions to use this colour");
				Colour(client);
				return;
			}
		}
		else
		{
			if( colourRainbow[client] )
				colourRainbow[client] = false;
		}
		g_remember_colour[client] = item;
		SetCookieInt(client, g_hColourCookie, item);
		PrintToChat( client, " You have selected the beam colour \x04%s", g_ColorName[item]);
		RED[client] = g_ColorRED[item]; //R
		BLUE[client] = g_ColorBLUE[item]; //G
		GREEN[client] = g_ColorGREEN[item]; //B
		colourselected[client] = true;
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}

}

public void OnClientPostAdminCheck(int client)
{
	LoadData(client);
	LoadData2(client);
	connects[client]++
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamageCallback);
}


/*public Action:OnReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(client, " running low on ammo? use '\x04.\x01' or '\x04,\x01' to purchase ammo !")
}*/

public Action msg_ConnectMessage(Handle timer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Handled;

	gShowMSG[client] = true;
	PrintToChat( client, " \x04Welcome to ServerAU.com's Zombie Base Builder server !")

	if( GameRules_GetProp("m_bWarmupPeriod") == 1 )
		PrintToChat( client, " \x04WARMUP: Waiting for players to connect !")

	if( FirstConnect[client] == 0 && !IsFakeClient(client))
	{
		if( GetConVarInt(zbb_FirstConnect_Credit) > 0 )
		{
			PrintToChat( client, " You were given \x04%d \x01credits to spend for \x04connecting\x01 for the\x04 first time!", GetConVarInt( zbb_FirstConnect_Credit ))
			Set_Player_Credit( client, PlayerCredit[client] + GetConVarInt( zbb_FirstConnect_Credit ) );
		}
		FirstConnect[client] = 1
		SaveData(client);
		PrintToChat( client, " You can type \x04!zbb \x01to access the main menu of \x04Zombie Base Builders")
		PrintToChat( client, " \x02bind 'key' +grab to move objects or hold your E(+use) key")
	}
	if(!IsPlayerAlive(client))
	{
		PrintToChat( client, " Late joiners can type \x04!respawn \x01to spawn as a zombie")
	}
	gConnectMSG[client] = null;
	return Plugin_Handled;
}
public void OnMapEnd()
{
	KillAllTimers();
}

public void OnMapStart()
{
	PrecacheModel("models/player/zombie.mdl", true);
	PrecacheModel("models/props/gg_tibet/rock_straight_small01.mdl", true);
	/*PrecacheModel("models/pokemod/fire_rock/fire_rock.mdl", true)
	AddFileToDownloadsTable("models/pokemod/fire_rock/fire_rock.mdl");
	AddFileToDownloadsTable("models/pokemod/fire_rock/fire_rock.dx90.vtx");
	AddFileToDownloadsTable("models/pokemod/fire_rock/fire_rock.phy");
	AddFileToDownloadsTable("models/pokemod/fire_rock/fire_rock.vvd");
	AddFileToDownloadsTable("materials/pokemod/fire_rock/fire_rock.pwl.vtf");
	AddFileToDownloadsTable("materials/pokemod/fire_rock/fire_rock.vtf");
	AddFileToDownloadsTable("materials/pokemod/fire_rock/fire_rock.vmt");
*/
	AddFileToDownloadsTable("sound/zbb/one.mp3");
	PrecacheSoundAny("zbb/one.mp3");
	AddFileToDownloadsTable("sound/zbb/two.mp3");
	PrecacheSoundAny("zbb/two.mp3");
	AddFileToDownloadsTable("sound/zbb/three.mp3");
	PrecacheSoundAny("zbb/three.mp3");
	AddFileToDownloadsTable("sound/zbb/four.mp3");
	PrecacheSoundAny("zbb/four.mp3");
	AddFileToDownloadsTable("sound/zbb/five.mp3");
	PrecacheSoundAny("zbb/five.mp3");
	AddFileToDownloadsTable("sound/zbb/six.mp3");
	PrecacheSoundAny("zbb/six.mp3");
	AddFileToDownloadsTable("sound/zbb/seven.mp3");
	PrecacheSoundAny("zbb/seven.mp3");
	AddFileToDownloadsTable("sound/zbb/eight.mp3");
	PrecacheSoundAny("zbb/eight.mp3");
	AddFileToDownloadsTable("sound/zbb/nine.mp3");
	PrecacheSoundAny("zbb/nine.mp3");
	AddFileToDownloadsTable("sound/zbb/ten.mp3");
	PrecacheSoundAny("zbb/ten.mp3");
	AddFileToDownloadsTable("sound/zbb/zombies_win.mp3");
	PrecacheSoundAny("zbb/zombies_win.mp3");
	AddFileToDownloadsTable("sound/zbb/humans_win.mp3");
	PrecacheSoundAny("zbb/humans_win.mp3");
	AddFileToDownloadsTable("sound/zbb/round_start2.mp3");
	PrecacheSoundAny("zbb/round_start2.mp3");
	AddFileToDownloadsTable("sound/zbb/round_start.mp3");
	PrecacheSoundAny("zbb/round_start.mp3");

	AddFileToDownloadsTable("sound/zbb/achievement.mp3");
	PrecacheSoundAny("zbb/achievement.mp3");

	PrecacheSoundAny("ui/beep07.wav");
	//PrecacheSoundAny("items/ammo_pickup.wav");
	precache_laser = PrecacheModel("materials/sprites/laserbeam.vmt");

	char sBuffer[32];
	GetConVarString(g_Terrorist, sBuffer, sizeof(sBuffer));
	SetConVarString(g_hCvarTeamName2, sBuffer);
	GetConVarString(g_CTerrorist, sBuffer, sizeof(sBuffer));
	SetConVarString(g_hCvarTeamName1, sBuffer);
}

public Action TakeDamageCallback(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{		

	if( !gamestart )
		return Plugin_Handled;

	if (damagetype & DMG_FALL )
	{
		if( zbb_phase == 1 )
		{
			return Plugin_Handled;	
		}		
	}

	if( attacker == 0 || victim == 0 )
		return Plugin_Changed;

	if( GetClientTeam(attacker) == TEAM_BUILDERS && GetClientTeam(victim) == TEAM_ZOMBIES)
	{
		float dmg = FloatAdd(BuilderDamage[attacker], damage);
		BuilderDamage[attacker] = dmg;
		if (BuilderDamage[attacker] >= GetConVarInt(g_PDMGThreshold))
		{
			BuilderDamage[attacker] = 0.0;
			char buffer[32];
			CS_GetClientClanTag(attacker, buffer, sizeof(buffer))
			if( StrEqual(buffer, CLANTAG) )
			{
				int xp = GetConVarInt(g_kDMGXP) * GetConVarInt(g_CreditMultiply) * GetConVarInt(g_CreditMultiplyCLAN) 
				PrintToChat(attacker, " You have\x04 gained\x03 %d Credit\x01 for defending your base. ", xp );
				Set_Player_Credit( attacker, PlayerCredit[attacker] + xp )				
			}
			else
			{
				PrintToChat(attacker, " You have\x04 gained\x03 %d Credit\x01 for defending your base. ", GetConVarInt(g_kDMGXP) * GetConVarInt(g_CreditMultiply) );
				Set_Player_Credit( attacker, PlayerCredit[attacker] + (GetConVarInt(g_kDMGXP) * GetConVarInt(g_CreditMultiply)) )
			}

		}
		char szWeapon[16];
		GetClientWeapon(attacker, szWeapon, sizeof(szWeapon));
		for (int i = 0; i < 15; i++)
		{
			if( StrEqual( szWeapon, PRIMCONST[ i ] ) )
			{
				has_used_pistol[attacker] = false
			}
		}
	}

	if (GetClientTeam(attacker) == TEAM_ZOMBIES && GetClientTeam(victim) == TEAM_BUILDERS && !g_PlayerAchievements[attacker][ACHIEVE_CLUBDREAD])
	{
		char buffer[32];
		int dmg = FloatToString(damage, buffer, 32)
		totaldamage[attacker] = totaldamage[attacker] + dmg
		if ( totaldamage[attacker] > 4999.0 )
		{
			switch ( g_PlayerAchievements[ attacker ][ ACHIEVE_CLUBDREAD ] )
			{
				case LEVEL_NONE:       
				{
					g_PlayerAchievements[ attacker ][ ACHIEVE_CLUBDREAD ] = LEVEL_I;
					PrintToChat( attacker, " \x04[ ACHIEVEMENT ] \x03%s: \nDeal out 5000 total damage as a zombie!\n \x03+50 Credits", ACHIEVEMENTS[ ACHIEVE_CLUBDREAD ][ LEVEL_I ] );
					Set_Player_Credit( attacker , PlayerCredit[ attacker ] + 50 );
					check_banker( attacker )
					EmitSoundToClientAny( attacker, ACH_SOUND );
				}
			}      
		}
	}

	if(GetClientTeam(victim) == TEAM_ZOMBIES && GetClientTeam(attacker) == TEAM_BUILDERS)
	{
		int dmghud = RoundToNearest(damage)
		int realhp = GetClientHealth(victim) - dmghud;
		char centerText[512];
		if( realhp > 0 )
			Format(centerText, sizeof(centerText), " %sHP Remaining: <font color='#ff0000'>%d</font>", centerText, realhp);
		else
			Format(centerText, sizeof(centerText), " %sHP Remaining: <font color='#ff0000'>DEAD</font>", centerText);

		PrintHintText(attacker, centerText );
	}
	return Plugin_Changed;
}
public Action Command_HelpMenu(int client, int args)
{
	HelpMenu(client);
}

public Action Command_MainMenu(int client, int args) 
{
	MainMenu(client);
}

public Action Command_AdminPre(int client, int args) 
{
	if( Client_IsAdmin(client) )
		AdminMenu(client);
	else
		PrintToChat(client, " \x02you are not an admin")
}


public Action Command_Loadout(int client, int args) 
{
	LoadOutMenu(client);
}

public Action Command_Respawn(int client, int args)
{
	if(IsPlayerAlive(client))
	{
		PrintToChat(client, " You can't respawn if you are alive.")
		//PrintToChat(client, " If you are stuck please use \x04!stuck.")
	}
	else
	{
		CS_SwitchTeam(client, TEAM_ZOMBIES)
		CS_RespawnPlayer(client)
		if( LastTeam[client] != 0)
		{
			if( LastTeamCT > LastTeamT)
			{
				LastTeam[client] = TEAM_ZOMBIES 
				LastTeamT++
				PrintToChat( client, " \x04You will be on team Builders next round.")
			}
			else if ( LastTeamT > LastTeamCT )
			{
				LastTeam[client] = TEAM_BUILDERS
				LastTeamCT++
				PrintToChat( client, " \x04You will be on team Zombies next round.")
			}
			else if ( LastTeamT == LastTeamCT )
			{
				LastTeam[client] = TEAM_ZOMBIES
				LastTeamT++
				PrintToChat( client, " \x04You will be on team Builders next round.")
			}
		}
	}
}

public Action Command_Ratio(int client, int args)
{
	PrintToChatAll(" \x04Ratio: %d CTs Per Base", GetRatio())
}

public Action Command_Phase(int client, int args) 
{
	if(zbb_phase == 1)
	{
		PrintToChat( client, " \x04PHASE ONE: \x06Base Building !")
	}
	else if(zbb_phase == 2)
	{
		PrintToChat( client, " \x04PHASE TWO: \x06Pre Game ! ")
	}
	else if(zbb_phase == 3)
	{
		PrintToChat( client, " \x04PHASE THREE: \x06Base Defence !")
	}
	else
	{
		PrintToChat( client, " \x02Game has not started yet !")
	}

}




/*
public Action:Command_BuyAmmo(client, const String:command[], argc)
{
	if(GetClientTeam(client) == TEAM_BUILDERS)
	{
		char szWeapon[16];
		GetClientWeapon(client, szWeapon, sizeof(szWeapon));
		if( StrEqual( szWeapon, "weapon_knife") )
		{
			PrintToChat(client, " \x02Cannot buy ammo for knives!")
		}
		else
		{
			if( PlayerCredit[client] >= 1)
			{
				SetSecondaryClip(client, GetSecondaryClip(client) + 30);
				Set_Player_Credit(client, PlayerCredit[client] - 1);
				PrintToChat( client, " \x04You have purchased an ammo clip!");
			}
			else
			{
				PrintToChat( client, " \x04You need 1 credit to purchase ammo");
			}
		}
	}
	else
		PrintToChat( client, " \x02Zombies can't buy ammo!")
}*/
/* MENUS */

public Action Command_Achievements(int client, int args) 
{
	AchievementMenu(client);
}

public Action AchievementMenu(int client)
{
	Handle menu = CreateMenu(AchievementMenu_Handle);

	char szMsg[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Achievement Menu \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[128];
	Format(szItems1, sizeof( szItems1 ), " Achievements List " );
	AddMenuItem(menu, "class_id", szItems1);

	char szItems2[128];
	Format(szItems2, sizeof( szItems2 ), " Achievements Progress " );
	AddMenuItem(menu, "class_id", szItems2);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int AchievementMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { AchievementMenuList(client);}
			case 1: 
			{ 
				AchieveCount(client);
				AchievementMenuProgress(client);
			}
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       MainMenu(client);
    } 
}


public Action AchievementMenuList(int client)
{
	Handle menu = CreateMenu(AchievementMenuList_Handle);

	char szMsg[128];
	char szItems[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Achievements Menu \n");
	
	SetMenuTitle(menu, szMsg);

	for (int item_id = 0; item_id < MAX_ACHIEVEMENTS; item_id++)
	{

		Format(szItems, sizeof( szItems ), "%s \n      %s ", ACHIEVEMENTS[item_id][1], ACHIEVEMENTSDESC[item_id] );

		AddMenuItem(menu, "class_id", szItems);
	}


	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}
public int AchievementMenuList_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		PrintToChat( client, " \x04Achievement Description: \x03%s \x01%s",  ACHIEVEMENTS[item][1], ACHIEVEMENTSDESC[item] );
		AchievementMenuList(client);
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       AchievementMenu(client);
    } 
}

public Action AchievementMenuProgress(int client)
{
	Handle menu = CreateMenu(AchievementMenuProgress_Handle);

	char szMsg[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Achievements Progress \n----------------------");
	
	SetMenuTitle(menu, szMsg);

	char szItems1[128];
	if (g_PlayerAchievements[client][ACHIEVE_ZKILLS]==LEVEL_I)
		Format(szItems1, sizeof( szItems1 ), " Zombie Genocidist - 100/100 " );
	else
		Format(szItems1, sizeof( szItems1 ), " Zombie Genocidist - %d/100 ", zombiekills[client] );


	char szItems2[128];
	if (g_PlayerAchievements[client][ACHIEVE_HKILLS]==LEVEL_I)
		Format(szItems2, sizeof( szItems2 ), " Hmm... Tasty - 25/25 " );
	else
		Format(szItems2, sizeof( szItems2 ), " Hmm... Tasty - %d/25 ", humankills[client] );


	char szItems3[128];
	if (g_PlayerAchievements[client][ACHIEVE_HEADSHOTS]==LEVEL_I)
		Format(szItems3, sizeof( szItems3 ), " Base Builder - 10000/10000 " );
	else
		Format(szItems3, sizeof( szItems3 ), " Base Builder - %d/10000 ", objectsmoved[client] );


	char szItems4[128];
	if (g_PlayerAchievements[client][ACHIEVE_OBJMOVED]==LEVEL_I)
		Format(szItems4, sizeof( szItems4 ), " Cr0wned - 50/50 " );
	else
		Format(szItems4, sizeof( szItems4 ), " Cr0wned - %d/50 ", headshots[client] );


	char szItems5[128];
	if (g_PlayerAchievements[client][ACHIEVE_CONNECTS]==LEVEL_I)
		Format(szItems5, sizeof( szItems5 ), " One inch at a time - 10/10 " );
	else
		Format(szItems5, sizeof( szItems5 ), " One inch at a time - %d/10 ", connects[client] );

	char szItems6[128];
	if (g_PlayerAchievements[client][ACHIEVE_CLUBDREAD]==LEVEL_I)
		Format(szItems6, sizeof( szItems6 ), " Dead Wreckening - 5000/5000 " );
	else
		Format(szItems6, sizeof( szItems6 ), " Dead Wreckening - %d/5000 ", totaldamage[client] );

	char szItems7[128];
	if (g_PlayerAchievements[client][ACHIEVE_KNIFEZOMBIE]==LEVEL_I)
		Format(szItems7, sizeof( szItems7 ), " Guns are for girls - 1/1 " );
	else
		Format(szItems7, sizeof( szItems7 ), " Guns are for girls - %d/1 ", clubdread[client] );


	char szItems8[128];
	if (g_PlayerAchievements[client][ACHIEVE_HITMAN]==LEVEL_I)
		Format(szItems8, sizeof( szItems8 ), " Hitman - 1/1 " );
	else
		Format(szItems8, sizeof( szItems8 ), " Hitman - %d/1 ", pistolonly[client] );


	char szItems9[128];
	if (g_PlayerAchievements[client][ACHIEVE_RAMBO]==LEVEL_I)
		Format(szItems9, sizeof( szItems9 ), " Rambo - 1/1 " );
	else
		Format(szItems9, sizeof( szItems9 ), " Rambo - %d/1 ", g_para[client] );


	char szItems10[128];
	if (g_PlayerAchievements[client][ACHIEVE_WAR]==LEVEL_I)
		Format(szItems10, sizeof( szItems10 ), " War Machine - 19/19 " );
	else
		Format(szItems10, sizeof( szItems10 ), " War Machine - %d/19 ", weaponsbought[client] );


	char szItems11[128];
	if (g_PlayerAchievements[client][ACHIEVE_ARMS]==LEVEL_I)
		Format(szItems11, sizeof( szItems11 ), " Arms Dealer - 9/9 " );
	else
		Format(szItems11, sizeof( szItems11 ), " Arms Dealer - %d/9 ", weaponsbought[client] );


	char szItems12[128];
	if (g_PlayerAchievements[client][ACHIEVE_BANK]==LEVEL_I)
		Format(szItems12, sizeof( szItems12 ), " Break the Bank - 5000/5000 " );
	else
		Format(szItems12, sizeof( szItems12 ), " Break the Bank - %i/5000 ", PlayerCredit[client] );

	char szItems13[128];
	Format(szItems13, sizeof( szItems13 ), " Achievement Hunter - %d/%d", numofachieve[client], MAX_ACHIEVEMENTS );


	char szItems14[128];
	if (g_PlayerAchievements[client][ACHIEVE_HP]==LEVEL_I)
		Format(szItems14, sizeof( szItems14 ), " Juggernaut - 20/20 " );
	else
		Format(szItems14, sizeof( szItems14 ), " Juggernaut - %d/20 ", Zombie_HPlevel[client] );


	char szItems15[128];
	if (g_PlayerAchievements[client][ACHIEVE_AP]==LEVEL_I)
		Format(szItems15, sizeof( szItems15 ), " Solid Steel - 20/20 " );
	else
		Format(szItems15, sizeof( szItems15 ), " Solid Steel - %d/20 ", Zombie_Armourlevel[client] );

	char szItems16[128];
	if (g_PlayerAchievements[client][ACHIEVE_GR]==LEVEL_I)
		Format(szItems16, sizeof( szItems16 ), " Zero Gravity - 20/20 " );
	else
		Format(szItems16, sizeof( szItems16 ), " Zero Gravity - %d/20 ", Zombie_Gravitylevel[client] );

	char szItems17[128];
	if (g_PlayerAchievements[client][ACHIEVE_SP]==LEVEL_I)
		Format(szItems17, sizeof( szItems17 ), " Speed Demon - 20/20 " );
	else
		Format(szItems17, sizeof( szItems17 ), " Speed Demon - %d/20 ", Zombie_Speedlevel[client] );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", szItems3);
	AddMenuItem(menu, "class_id", szItems4);
	AddMenuItem(menu, "class_id", szItems5);
	AddMenuItem(menu, "class_id", szItems6);
	AddMenuItem(menu, "class_id", szItems7);
	AddMenuItem(menu, "class_id", szItems8);
	AddMenuItem(menu, "class_id", szItems9);
	AddMenuItem(menu, "class_id", szItems10);
	AddMenuItem(menu, "class_id", szItems11);
	AddMenuItem(menu, "class_id", szItems12);
	AddMenuItem(menu, "class_id", szItems13);
	AddMenuItem(menu, "class_id", szItems14);
	AddMenuItem(menu, "class_id", szItems15);
	AddMenuItem(menu, "class_id", szItems16);
	AddMenuItem(menu, "class_id", szItems17);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int AchievementMenuProgress_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		PrintToChat( client, " \x04Achievement Description: \x03%s \x01%s",  ACHIEVEMENTS[item][1], ACHIEVEMENTSDESC[item] );
		AchievementMenuProgress(client);
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       AchievementMenu(client);
    } 
}




public Action AdminMenu(int client)
{
	Handle menu = CreateMenu(AdminMenu_Handle);

	char szMsg[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Admin Menu \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[128];
	Format(szItems1, sizeof( szItems1 ), " Give Credit " );
	AddMenuItem(menu, "class_id", szItems1);

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}


public int AdminMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { GiveCredit_PlayerMenu(client);}
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}

public Action GiveCredit_PlayerMenu(int client)
{
	Handle menu = CreateMenu(GiveCredit_PlayerMenu_Handle);

	char szMsg[128];
	char szItems[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Player Menu \n----------------------");
	
	SetMenuTitle(menu, szMsg);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{

			Format(szItems, sizeof( szItems ), "%N Credit: %d", i, PlayerCredit[i] );

			AddMenuItem(menu, "class_id", szItems);
		}
	}


	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int GiveCredit_PlayerMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		Set_Player_Credit(item + 1, PlayerCredit[item + 1] + 1000)
		PrintToChat( item+1, " \x04You were given 1000 credits by admin %N", item + 1, client)
		PrintToChat( client, " \x04%N was given 1000 credits", item + 1)
		GiveCredit_PlayerMenu(client)
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}

public Action LoadOutMenu(int client)
{
	Handle menu = CreateMenu(LoadOutMenu_Handle);

	char szMsg[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Loadout \nCredits: %d \n----------------------", PlayerCredit[client]);
	SetMenuTitle(menu, szMsg);

	char WeppPrim[32];
	strcopy(WeppPrim, sizeof(WeppPrim), PRIMCONST[g_remember_primary[client]][7]);
	WeppPrim[0] = CharToUpper(WeppPrim[0]);

	char WeppSec[32];
	strcopy(WeppSec, sizeof(WeppSec), SECONDCONST[g_remember_secondary[client]][7]);
	WeppSec[0] = CharToUpper(WeppSec[0]);

	char szItems1[128];
	Format(szItems1, sizeof( szItems1 ), "Primary Gun: %s", WeppPrim );
	char szItems2[128];
	Format(szItems2, sizeof( szItems2 ), "Secondary Gun: %s \n\n", WeppSec );
	char szItems3[128];
	Format(szItems3, sizeof( szItems3 ), "Re-Equip\n");
	char szItems4[128];
	Format(szItems4, sizeof( szItems4 ), "Unlock Guns" );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", "", ITEMDRAW_SPACER);
	if(GetClientTeam(client) == TEAM_BUILDERS )
		AddMenuItem(menu, "class_id", szItems3);
	else
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	AddMenuItem(menu, "class_id", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "class_id", szItems4);


	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int LoadOutMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { GunMenuSelect(client); }
			case 1: { PISTOL_SELECT(client);}
			case 3: 
			{ 
				if( IsValidAlive(client))
				{
					if(GetClientTeam(client) == TEAM_BUILDERS)
					{
						if( zbb_phase == 2)
						{
							Client_RemoveAllWeapons(client, "weapon_knife", true); 
							GivePlayerItem( client, PRIMCONST[g_remember_primary[client]]), 
							GivePlayerItem( client, SECONDCONST[g_remember_secondary[client]]);
						}
						else
						{
							PrintToChat( client, " You can only\x04 re-equip \x01during the \x02Pre Game Phase\x01.")
						}
					}
					else
					{
						PrintToChat( client, " You \x02can't\x04 re-equip\x01 as an \x02zombie\x01.")
					}
				}
				else
				{
					PrintToChat( client, " \x02Dead\x01 players can not use \x04re-equip.")
				}
			}
			case 5: { GunMenuUnlock(client); }
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       MainMenu(client);
    } 
}


public Action MainMenu(int client)
{
	Handle menu = CreateMenu(MainMenu_Handle);

	char szMsg[128];
	char szItems[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Main Menu \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	for (int item_id = 0; item_id < MAINMENUITEMS; item_id++)
	{

		Format(szItems, sizeof( szItems ), "%s", g_MainMenu[item_id] );

		AddMenuItem(menu, "class_id", szItems);
	}


	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}



public int MainMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { LoadOutMenu(client); }
			case 1: { GunMenuUnlock(client);}
			case 2: { Upgrade_ZombieMenu(client);}
			case 3: { Upgrade_HumanMenu(client);}
			case 4: { AchievementMenu(client); }
			case 5: { HelpMenu(client); }
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}

}

public Action HelpMenu(int client)
{
	Handle menu = CreateMenu(HelpMenu_Handle);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "ZBB Help \n----------------------", PlayerCredit[client]);
	SetMenuTitle(menu, szMsg);

	char szItems1[128];
	Format(szItems1, sizeof( szItems1 ), "Commands" );

	char szItems2[128];
	Format(szItems2, sizeof( szItems2 ), "How to grab objects?" );

	char szItems3[128];
	Format(szItems3, sizeof( szItems3 ), "How to earn credits?" );

	char szItems4[128];
	Format(szItems4, sizeof( szItems4 ), "Types of Phases" );

	char szItems5[128];
	Format(szItems5, sizeof( szItems5 ), "V.I.P benefits" );

	char szItems6[128];
	Format(szItems6, sizeof( szItems6 ), "RULES" );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", szItems3);
	AddMenuItem(menu, "class_id", szItems4);
	AddMenuItem(menu, "class_id", szItems5);
	AddMenuItem(menu, "class_id", szItems6);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );	
}

public int HelpMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { CommandsMenu(client); }
			case 1: { GrabHelpMenu(client); }
			case 2: { CreditHelpMenu(client); }
			case 3: { TypesofPhaseMenu(client); }
			case 4: { VIPBenefitMenu(client); }
			case 5: { PrintToChat( client, " Please visit \x04http://www.saugn.com/forums/ \x01to view the \x04ZBB Rules"); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       MainMenu(client);
    } 
}

//
public Action CommandsMenu(int client)
{
	Handle menu = CreateMenu(CommandsMenu_Handle);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "ZBB Commands \n----------------------", PlayerCredit[client]);
	SetMenuTitle(menu, szMsg);

	char szItems1[2048];
	Format(szItems1, sizeof( szItems1 ), "Say commands: \n!zbb: brings up main menu.\n!loadout: brings up guns / loadout menu.\n!phase: checks what the current phase is.\n!respawn: respawns late joiners.\n!colour: brings up beam colour menu." );

	AddMenuItem(menu, "class_id", szItems1);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );	

}
public int CommandsMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       HelpMenu(client);
    } 
}

public Action GrabHelpMenu(int client)
{
	Handle menu = CreateMenu(GrabHelpMenu_Handle);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "ZBB how to grab objects? \n----------------------", PlayerCredit[client]);
	SetMenuTitle(menu, szMsg);

	char szItems1[2048];
	Format(szItems1, sizeof( szItems1 ), "Type bind 'key' +grab into console.\nreplace 'key' with a button. This will be your key to move/grab objects\n \n\nDont want to bind a key? You can use your (by default) 'E' (+use) key!" );


	AddMenuItem(menu, "class_id", szItems1);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );	
}
public int GrabHelpMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       HelpMenu(client);
    } 
}

public Action CreditHelpMenu(int client)
{
	Handle menu = CreateMenu(CreditHelpMenu_Handle);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "ZBB How to earn credits? \n----------------------", PlayerCredit[client]);
	SetMenuTitle(menu, szMsg);

	char szItems1[2048];
	Format(szItems1, sizeof( szItems1 ), "Zombies:\nKilling a builder: +%d\nSurving the round: +%d", GetConVarInt(g_kZombieKill), GetConVarInt(g_kZombieWin));

	char szItems2[2048];
	Format(szItems2, sizeof( szItems2 ), "Builders:\nKilling a zombie: +%d\nDealing %d DMG: +%d\nSurving the round: +%d",  GetConVarInt(g_kBuilderKill), GetConVarInt(g_PDMGThreshold), GetConVarInt(g_kDMGXP), GetConVarInt(g_kBuilderWin));

	char szItems3[2048];
	Format(szItems3, sizeof( szItems3 ), " Joining Our Steam Group and Setting Your Clan Tag to our group will earn you 2x Credits !\nYou can join our steam group by visiting our forums at www.saugn.com/forums/" );


	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "class_id", szItems3);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );	

}
public int CreditHelpMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       HelpMenu(client);
    } 
}

public Action TypesofPhaseMenu(int client)
{
	Handle menu = CreateMenu(TypesofPhaseMenu_Handle);

	char szMsg[4096];
	
	Format(szMsg, sizeof( szMsg ), "ZBB Types of Phases \n----------------------" );
	SetMenuTitle(menu, szMsg);

	char szItems1[4096];
	Format(szItems1, sizeof( szItems1 ), "Phase ONE: Build Phase\nBuilders have %d seconds to build a base. The zombies are stuck inside a barrier during this time.", GetConVarInt(zbb_buildtime) );

	char szItems2[4096];
	Format(szItems2, sizeof( szItems2 ), "Phase TWO: Pre Game Phase\nThe builders are respawned and have 30 seconds to get inside their base and equip their hard earnt guns. \nThis is to ensure the base is valid." );

	char szItems3[4096];
	Format(szItems3, sizeof( szItems3 ), "Phase Three: Base Defence Phase\nThe zombies are released and must fight their way into the builders base to win." );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "class_id", szItems3);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );		
}

public int TypesofPhaseMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       HelpMenu(client);
    } 
}

public Action VIPBenefitMenu(int client)
{
	Handle menu = CreateMenu(VIPBenefitMenu_Handle);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "ZBB V.I.P  \n----------------------" );
	SetMenuTitle(menu, szMsg);

	char szItems1[2048];
	Format(szItems1, sizeof( szItems1 ), "Benefits:\n-Unlock All Guns\n-Do not get respawned during Phase TWO\n-Acess to !store to unlock special effects!" );

	AddMenuItem(menu, "class_id", szItems1);


	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );		
}

public int VIPBenefitMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       HelpMenu(client);
    } 
}

public Action Upgrade_ZombieMenu(int client)
{
	Handle menu = CreateMenu(Upgrade_ZombieMenu_Handle);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "ZBB Upgrade Zombie \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	g_pHPCost[client] = GetConVarInt(Zombie_HPBonusPerLevelCost) + GetConVarInt(Zombie_HPBonusPerLevelCost) * Zombie_HPlevel[client]
	g_pGRCost[client] = GetConVarInt(Zombie_GravityBonusPerLevelCost) + GetConVarInt(Zombie_GravityBonusPerLevelCost) * Zombie_Gravitylevel[client]
	g_pSPCost[client] = GetConVarInt(Zombie_SpeedBonusPerLevelCost) + GetConVarInt(Zombie_SpeedBonusPerLevelCost) * Zombie_Speedlevel[client]
	g_pARCost[client] = GetConVarInt(Zombie_ArmourBonusPerLevelCost) + GetConVarInt(Zombie_ArmourBonusPerLevelCost) * Zombie_Armourlevel[client]

	char szItems1[128];
	Format(szItems1, sizeof( szItems1 ), "Upgrade HP ( %d / 20 )\nDescription: Gives %d extra health per level \nCost: %d", Zombie_HPlevel[client], GetConVarInt(Zombie_HPBonusPerLevel), g_pHPCost[client] );
	char szItems2[128];
	Format(szItems2, sizeof( szItems2 ), "Upgrade Gravity ( %d / 20 )\nDescription: Gives 0.02 lesser gravity per level \nCost: %d", Zombie_Gravitylevel[client], g_pGRCost[client] );
	char szItems3[128];
	Format(szItems3, sizeof( szItems3 ), "Upgrade Speed ( %d / 20 )\nDescription: Gives 0.02 times extra speed per level \nCost: %d", Zombie_Speedlevel[client], g_pSPCost[client] );
	char szItems4[128];
	Format(szItems4, sizeof( szItems4 ), "Upgrade Armour ( %d / 20 )\nDescription: Gives %d extra armour per level \nCost: %d", Zombie_Armourlevel[client], GetConVarInt(Zombie_ArmourBonusPerLevel), g_pARCost[client] );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", szItems3);
	AddMenuItem(menu, "class_id", szItems4);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int Upgrade_ZombieMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: 
			{ 
				if( Zombie_HPlevel[client] < 20 )
				{
					if( PlayerCredit[client] >= g_pHPCost[client] )
					{
						Set_Player_Credit(client, PlayerCredit[client] - g_pHPCost[client] )
						Zombie_HPlevel[client]++
						PrintToChat(client, " You have \x04successfully\x01 purchased \x04Zombie HP Upgrade\x01.");
						Upgrade_ZombieMenu(client);

						if( Zombie_HPlevel[client] == 20 )
						{
							switch (g_PlayerAchievements[client][ACHIEVE_HP])
							{
								case LEVEL_NONE:
								{
									g_PlayerAchievements[client][ACHIEVE_HP]=LEVEL_I;
									PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUpgrade to the most max health! \n\x03+100 Credits", ACHIEVEMENTS[ACHIEVE_HP][LEVEL_I]);
									Set_Player_Credit( client, PlayerCredit[client] + 100 )
									EmitSoundToClientAny( client, ACH_SOUND );
									SaveData2(client);
									check_banker(client)
								}
							}      
						}
					}
					else
					{
						PrintToChat(client, " \x02Not enough credit.");
						Upgrade_ZombieMenu(client)
					}
				}
				else
				{
					PrintToChat(client, " \x02Already at MAX level.");
					Upgrade_ZombieMenu(client)

				}
			}
			case 1: 
			{ 
				if( Zombie_Gravitylevel[client] < 20 )
				{
					if( PlayerCredit[client] >= g_pGRCost[client] )
					{
						Set_Player_Credit(client, PlayerCredit[client] - g_pGRCost[client]);
						Zombie_Gravitylevel[client]++
						PrintToChat(client, " You have \x04successfully\x01 purchased \x04Zombie Gravity Upgrade\x01.");
						Upgrade_ZombieMenu(client);

						if( Zombie_Gravitylevel[client] == 20 )
						{
							switch (g_PlayerAchievements[client][ACHIEVE_GR])
							{
								case LEVEL_NONE:
								{
									g_PlayerAchievements[client][ACHIEVE_GR]=LEVEL_I; 
									PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUpgrade to the lowest possible gravity! \n\x03+100 Credits", ACHIEVEMENTS[ACHIEVE_GR][LEVEL_I]);
									Set_Player_Credit( client, PlayerCredit[client] + 100 )
									EmitSoundToClientAny( client, ACH_SOUND );
									SaveData2(client);
									check_banker(client)
								}
							}      
						}

					}
					else
					{
						PrintToChat(client, " \x02Not enough credit.");
						Upgrade_ZombieMenu(client)
					}
				}
				else
				{
					PrintToChat(client, " \x02Already at MAX level.");
					Upgrade_ZombieMenu(client)
				}
			}
			case 2: 
			{ 
				if( Zombie_Speedlevel[client] < 20 )
				{
					if( PlayerCredit[client] >= g_pSPCost[client] )
					{
						Set_Player_Credit(client, PlayerCredit[client] - g_pSPCost[client]);
						Zombie_Speedlevel[client]++
						PrintToChat(client, " You have \x04successfully\x01 purchased \x04Zombie Speed Upgrade\x01.");
						Upgrade_ZombieMenu(client);

						if( Zombie_Speedlevel[client] == 20 )
						{
							switch (g_PlayerAchievements[client][ACHIEVE_SP])
							{
								case LEVEL_NONE:
								{
									g_PlayerAchievements[client][ACHIEVE_SP]=LEVEL_I;
									PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUpgrade to the fastest possible speed! \n\x03+100 Credits", ACHIEVEMENTS[ACHIEVE_SP][LEVEL_I]);
									Set_Player_Credit( client, PlayerCredit[client] + 100 )
									EmitSoundToClientAny( client, ACH_SOUND );
									SaveData2(client);
									check_banker(client)
								}
							}      
						}
					}
					else
					{
						PrintToChat(client, " \x02Not enough credit.");
						Upgrade_ZombieMenu(client)
					}
				}
				else
				{
					PrintToChat(client, " \x02Already at MAX level.");
					Upgrade_ZombieMenu(client)
				}
			}
			case 3: 
			{ 
				if( Zombie_Armourlevel[client] < 20 )
				{
					if( PlayerCredit[client] >= g_pARCost[client] )
					{
						Set_Player_Credit(client, PlayerCredit[client] - g_pARCost[client]);
						Zombie_Armourlevel[client]++
						PrintToChat(client, " You have \x04successfully\x01 purchased \x04Zombie Armour Upgrade\x01.");
						Upgrade_ZombieMenu(client);

						if( Zombie_Armourlevel[client] == 20 )
						{
							switch (g_PlayerAchievements[client][ACHIEVE_AP])
							{
								case LEVEL_NONE:
								{
									g_PlayerAchievements[client][ACHIEVE_AP]=LEVEL_I;
									PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUpgrade to the most armour!\n \x03+100 Credits", ACHIEVEMENTS[ACHIEVE_AP][LEVEL_I]);
									Set_Player_Credit( client, PlayerCredit[client] + 100 )
									EmitSoundToClientAny( client, ACH_SOUND );
									SaveData2(client);
									check_banker(client)
								}
							}      
						}
					}
					else
					{
						PrintToChat(client, " \x02Not enough credit.");
						Upgrade_ZombieMenu(client)
					}
				}
				else
				{
					PrintToChat(client, " \x02Already at MAX level.");
					Upgrade_ZombieMenu(client)
				}
			}
		}

	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);	
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       MainMenu(client);
    } 
}

public Action Upgrade_HumanMenu(int client)
{
	Handle menu = CreateMenu(Upgrade_HumanMenu_Handle);

	char szMsg[128];
	char szItems1[128];
	Format(szMsg, sizeof( szMsg ), "ZBB Upgrade Human \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	g_bHPCost[client] = GetConVarInt(Builder_HPBonusPerLevelCost) + GetConVarInt(Builder_HPBonusPerLevelCost) * Builder_HPlevel[client]

	Format(szItems1, sizeof( szItems1 ), "Upgrade HP ( %d / 10 )\nDescription: Gives %d extra health per level \nCost: %d", Builder_HPlevel[client], GetConVarInt(Builder_HPBonusPerLevel), g_bHPCost[client] );

	AddMenuItem(menu, "class_id", szItems1);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 120 );
}

public int Upgrade_HumanMenu_Handle(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: 
			{ 
				if( Builder_HPlevel[client] < 10 )
				{
					if( PlayerCredit[client] >= g_bHPCost[client] )
					{
						Set_Player_Credit(client, PlayerCredit[client] - g_bHPCost[client]);
						Builder_HPlevel[client]++
						PrintToChat(client, " You have \x04successfully\x01 purchased \x04Buidler's HP Upgrade\x01.");
						Upgrade_HumanMenu(client);
					}
					else
					{
						PrintToChat(client, " \x02Not enough credit.");
						Upgrade_HumanMenu(client)
					}
				}
				else
				{
					PrintToChat(client, " \x02Already at MAX level.");
					Upgrade_HumanMenu(client)
				}
			}
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       MainMenu(client);
    } 
}


public bool TraceRayTryToHit(int entity, int mask)
{
	// Check if the beam hit a player and tell it to keep tracing if it did
	if(entity > 0 && entity <= MaxClients)
		return false;
	return true;
}

/* EVENTS */

public void Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0) 
		return; 
	
	if( !gShowMSG[client] && gConnectMSG[client] == null)
		gConnectMSG[client] = CreateTimer(3.0, msg_ConnectMessage, client);

	Client_RemoveAllWeapons(client, "weapon_knife", true);

	if( GetClientTeam(client) == TEAM_ZOMBIES)
	{
		SetEntityModel(client, "models/player/zombie.mdl");

		int zombiehp =  GetConVarInt(Zombie_StandardHP) + Zombie_HPlevel[client] * GetConVarInt(Zombie_HPBonusPerLevel);
		SetEntityHealth(client, zombiehp);
		float gravity = ( 1.0 - ( GetConVarFloat(Zombie_GravityBonusPerLevel) * Zombie_Gravitylevel[client] ) );
		SetEntityGravity(client, gravity);
		float speed = ( 1.0 + (GetConVarInt(Zombie_SpeedBonusPerLevel) * Zombie_Speedlevel[client]) );
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed); 
		int armour = GetConVarInt(Zombie_ArmourBonusPerLevel) * Zombie_Armourlevel[client];
		//Client_SetArmor(client, armour);
		SetEntProp(client, Prop_Send, "m_ArmorValue", armour);
	/*	if( Client_GetArmor(client) > 0 )
		{
			new g_iPlayers_HelmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
			SetEntData(client, g_iPlayers_HelmetOffset, 1);
		}*/
		// Initialize vector variables.
		float clientloc[3];
		float direction[3] = {0.0, 0.0, 0.0};
		int flags;	
		// Get client's position.
		GetClientAbsOrigin(client, clientloc);
		clientloc[2] += 30;

		VEffectsCreateEnergySplash(clientloc, direction, true);
		VEffectsCreateExplosion(clientloc, flags);
	}
	if( GetClientTeam(client) == TEAM_BUILDERS)
	{
		int humanhp =  100 + Builder_HPlevel[client] * GetConVarInt(Builder_HPBonusPerLevel);
		SetEntityHealth(client, humanhp);
		SetEntityGravity(client, 1.00);
		Client_SetArmor(client, 0);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0); 

		//GetClientAbsOrigin(client, ClientSpawnPosition);
		g_Grabbed[client] = false;
		g_Targetindex[client] = -1;

		if( zbb_phase == 2 )
		{
			PrintToChat( client, " \x03!loadout\x01, to customize your weapon loadout !")
			//LoadOutMenu(client);
			Client_RemoveAllWeapons(client, "weapon_knife", true); 
			GivePlayerItem( client, PRIMCONST[g_remember_primary[client]]);
			GivePlayerItem( client, SECONDCONST[g_remember_secondary[client]]);
			//TeleportEntity( client, ClientSpawnPosition, NULL_VECTOR, NULL_VECTOR);
		}
		//GetEntityOrigin(client, ClientSpawnPosition);
	}
	/*if( GetClientTeam(client) == TEAM_BUILDERS && zbb_phase[2])
		OPEN GUN MENY */
	/*
	if( zbb_phase[3])
		OPENGUN MENU */		
}

public void GetEntityOrigin(int entity, float output[3])
{
	GetEntDataVector(entity, OriginOffset, output);
}

public void Event_OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	int team = GetClientTeam(victim);
	
	if ( victim == 0 || attacker == 0)
		return;

	char szWeapon[16];
	GetClientWeapon(attacker, szWeapon, sizeof(szWeapon));

	if(team == TEAM_ZOMBIES || team == TEAM_BUILDERS)
	{
		if( !IsValidAlive(victim) )
		{
			CreateTimer(GetConVarFloat(g_RespawnDelay), RespawnPlayer2, victim );
		}	
	}
	if( GetClientTeam(attacker) == TEAM_BUILDERS && team == TEAM_ZOMBIES)
	{
		char buffer[32];
		CS_GetClientClanTag(attacker, buffer, sizeof(buffer))
		if( StrEqual(buffer, CLANTAG ) )
		{
			int xp = GetConVarInt(g_kBuilderKill) * GetConVarInt(g_CreditMultiply) * GetConVarInt(g_CreditMultiplyCLAN);
			Set_Player_Credit( attacker, PlayerCredit[attacker] + xp)
			PrintToChat( attacker, " You have\x04 gained\x03 %d Credit\x01 for killing a zombie.", xp);
		}
		else
		{
			Set_Player_Credit( attacker, PlayerCredit[attacker] + GetConVarInt(g_kBuilderKill) * GetConVarInt(g_CreditMultiply))
			PrintToChat( attacker, " You have\x04 gained\x03 %d Credit\x01 for killing a zombie.", GetConVarInt(g_kBuilderKill) * GetConVarInt(g_CreditMultiply) );
		}

		zombiekills[ attacker ]++

		if( StrEqual( szWeapon, "weapon_knife") )
		{
			clubdread[attacker]++
		}
		if ( GetEventBool(event, "headshot") )
		{
			headshots[attacker]++
		}
	}
	else if( GetClientTeam(victim) == TEAM_BUILDERS && GetClientTeam(attacker) == TEAM_ZOMBIES)
	{
		char buffer[32];
		CS_GetClientClanTag(attacker, buffer, sizeof(buffer))
		if( StrEqual(buffer, CLANTAG ) )
		{
			int xp = GetConVarInt(g_kZombieKill) * GetConVarInt(g_CreditMultiply) * GetConVarInt(g_CreditMultiplyCLAN)
			Set_Player_Credit( attacker, PlayerCredit[attacker] + xp)
			PrintToChat( attacker, " You have\x04 gained\x03 %d Credit\x01 for killing a builder.", xp);
		}
		else
		{
			Set_Player_Credit( attacker, PlayerCredit[attacker] + GetConVarInt(g_kZombieKill) * GetConVarInt(g_CreditMultiply))
			PrintToChat( attacker, " You have\x04 gained\x03 %d Credit\x01 for killing a builder.", GetConVarInt(g_kZombieKill) * GetConVarInt(g_CreditMultiply) );
		}

	}


	check_achievements(attacker);
	check_achievements(victim);
	check_banker(attacker)
}

public Action Event_OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast) 
{
    dontBroadcast = true;
    return Plugin_Changed;
}

public void Event_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if( GameRules_GetProp("m_bWarmupPeriod") == 1 )
		return;

	gamestart = false;
	zbb_phase = 0;

	zbb_TimerTick = 0;

	PrintToChatAll( " \x07Teams being switched..");
	
	int winner = GetEventInt(event, "winner");
	if( winner == TEAM_BUILDERS )
	{
		EmitSoundToAllAny( "zbb/humans_win.mp3" )
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) && GetClientTeam(i) == TEAM_BUILDERS )
			{
				char buffer[32];
				CS_GetClientClanTag(i, buffer, sizeof(buffer))
				if( StrEqual(buffer, CLANTAG ) )
				{
					int xp = GetConVarInt(g_kBuilderWin) * GetConVarInt(g_CreditMultiply) * GetConVarInt(g_CreditMultiplyCLAN)
					Set_Player_Credit(i, PlayerCredit[i] + xp )
					PrintToChat(i, " You have\x04 gained\x03 %d Credit\x01 for surviving the round.", xp);
				}
				else
				{
					Set_Player_Credit(i, PlayerCredit[i] + GetConVarInt(g_kBuilderWin) * GetConVarInt(g_CreditMultiply) )
					PrintToChat(i, " You have\x04 gained\x03 %d Credit\x01 for surviving the round.", GetConVarInt(g_kBuilderWin) * GetConVarInt(g_CreditMultiply));
				}

			}

		}


		//Hitman
		switch (g_PlayerAchievements[client][ACHIEVE_HITMAN])
		{
			case LEVEL_NONE:
			{     
    	          
				if (has_used_pistol[client])
				{
					g_PlayerAchievements[client][ACHIEVE_HITMAN]=LEVEL_I;
					PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: %s \nSurvive a round only using pistols!\n \x03+100 Credits", ACHIEVEMENTS[ACHIEVE_HITMAN][LEVEL_I]);
					Set_Player_Credit( client, PlayerCredit[client] + 100 )
					EmitSoundToClientAny( client, ACH_SOUND );
					pistolonly[client]++
				}
			}
		}
	}
	else if( winner == TEAM_ZOMBIES)
	{
		EmitSoundToAllAny( "zbb/zombies_win.mp3" )
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) && GetClientTeam(i) == TEAM_ZOMBIES )
			{
				char buffer[32];
				CS_GetClientClanTag(i, buffer, sizeof(buffer))
				if( StrEqual(buffer, CLANTAG ) )
				{
					int xp = GetConVarInt(g_kZombieWin) * GetConVarInt(g_CreditMultiply) * GetConVarInt(g_CreditMultiplyCLAN)
					Set_Player_Credit(i, PlayerCredit[i] + xp )
					PrintToChat(i, " You have\x04 gained\x03 %d Credit\x01 for surviving the round.", xp);
				}
				else
				{
					Set_Player_Credit(i, PlayerCredit[i] + GetConVarInt(g_kZombieWin) * GetConVarInt(g_CreditMultiply) )
					PrintToChat(i, " You have\x04 gained\x03 %d Credit\x01 for surviving the round.", GetConVarInt(g_kZombieWin) * GetConVarInt(g_CreditMultiply));
				}

			}

		}
	}
	bool switchteams[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && LastTeam[i] == TEAM_BUILDERS && !switchteams[i])
		{
			CS_SwitchTeam(i, TEAM_ZOMBIES)
			switchteams[i] = true;
		}
		else if (IsValidClient(i) && LastTeam[i] == TEAM_ZOMBIES && !switchteams[i])
		{
			CS_SwitchTeam(i, TEAM_BUILDERS)
			switchteams[i] = true;
		}

	}
}

public void Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	int saveent = -1
	while(( saveent = FindEntityByClassname(saveent, "func_brush")) != -1)
	{
		if( !EntLocSaved[saveent])
		{
			GetEntityOrigin(saveent, EntLocSave[saveent]); 
			EntLocSaved[saveent] = true;
		}
		else
		{
			TeleportEntity(saveent, EntLocSave[saveent], NULL_VECTOR, NULL_VECTOR);
		}
	}

	if( GameRules_GetProp("m_bWarmupPeriod") == 1 )
		return;

	KillAllTimers();

	g_round++

	PrintToChatAll( " \x04ROUND \x03[ %d ]", g_round );

	gamestart = false;
	zbb_TimerTick = 0;
	LastTeamCT = 0;
	LastTeamT = 0;

	gPhase_1 = CreateTimer(1.0, Start_Phase_1)
}

public Action Start_Phase_1(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			PrintToChat( i, " \x04PHASE ONE: \x06Base Building !")
			PrintToChat( i, " \x06Build Time: %d !", RoundToNearest(GetConVarFloat(zbb_buildtime)) )
		}
	}
	PrintToChatAll(" \x04Ratio: %d CTs Per Base", GetRatio());
	zbb_phase = 1;
	gPhase_1_BuildTime = CreateTimer(1.0, Phase_1_BuildtimeHUD, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
	gPhase_2 = CreateTimer(GetConVarFloat(zbb_buildtime), Start_Phase_2)
	gPhase_1 = null;
}

public Action Phase_1_BuildtimeHUD(Handle timer)
{
	int timeLeft = GetConVarInt(zbb_buildtime) - zbb_TimerTick
	zbb_TimerTick++
	for (int i = 1; i <= MaxClients; i++)
	{
		if( IsValidClient(i))
		{
			PrintHintText(i, "<font size='25'> Build Time Left: %d </font>", timeLeft)
			switch( timeLeft )
			{
				case 1,2,3,4,5,6,7,8,9,10:{ EmitSoundToClientAny( i, "ui/beep07.wav"); }
			}
		}
	}	

	if(zbb_TimerTick == GetConVarInt(zbb_buildtime))
	{
		gPhase_1_BuildTime = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Start_Phase_2(Handle timer)
{
	zbb_phase = 2;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if( g_Status[i] )
				Action_Drop(i);

			PrintToChat( i, " \x04PHASE TWO: \x06Pre Game !")
			PrintToChat( i, " \x04Get inside your base !")
			PrintToChat( i, " \x0430 seconds before game begins !")
			if(GetClientTeam(i) == TEAM_BUILDERS )
			{
				LastTeam[i] = TEAM_BUILDERS;
				LastTeamCT++
				
				PrintToChat( i, " \x03!loadout\x01, to customize your weapon loadout !")
				Client_RemoveAllWeapons(i, "weapon_knife", true); 
				GivePlayerItem( i, PRIMCONST[g_remember_primary[i]]);
				GivePlayerItem( i, SECONDCONST[g_remember_secondary[i]]);
				if( GetConVarInt(zbb_respawn_phase2) )
					CS_RespawnPlayer(i);					
			}
			else
			{
				LastTeam[i] = TEAM_ZOMBIES;
				LastTeamT++
			}
		}
	}
	gPhase_2 = null
	if( gPhase_3 == null )
		gPhase_3 = CreateTimer(GetConVarFloat(zbb_pregametime), Start_Phase_3)
	if( gPhase_3_CountdownPre == null )
		gPhase_3_CountdownPre = CreateTimer( 19.0, Start_Phase_3_PreCountdown)
}

public Action Start_Phase_3_PreCountdown(Handle timer)
{
	if( gPhase_3_Countdown == null )
	{
		zbb_TimerTick = 0;
		gPhase_3_Countdown = CreateTimer(1.0, Start_Phase_3_Countdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	gPhase_3_CountdownPre = null;
}

public Action Start_Phase_3_Countdown(Handle timer)
{
	zbb_TimerTick++;
	zbb_Countdown_Sound = 11 - zbb_TimerTick

	switch(zbb_Countdown_Sound)
	{
		case 10: { EmitSoundToAllAny( "zbb/ten.mp3");  }
		case 9:  { EmitSoundToAllAny( "zbb/nine.mp3"); }
		case 8:  { EmitSoundToAllAny( "zbb/eight.mp3");}
		case 7:  { EmitSoundToAllAny( "zbb/seven.mp3");}
		case 6:  { EmitSoundToAllAny( "zbb/six.mp3");  }
		case 5:  { EmitSoundToAllAny( "zbb/five.mp3"); }
		case 4:  { EmitSoundToAllAny( "zbb/four.mp3"); }
		case 3:  { EmitSoundToAllAny( "zbb/three.mp3");}
		case 2:  { EmitSoundToAllAny( "zbb/two.mp3");  }
		case 1:  { EmitSoundToAllAny( "zbb/one.mp3");  }
		case 0:
		{
			EmitSoundToAllAny( "zbb/round_start.mp3");
			gPhase_3_Countdown = null
			return Plugin_Stop;			
		}
	}
	return Plugin_Handled;
}

public Action Start_Phase_3(Handle timer)
{
	int iEnt;
	while((iEnt = FindEntityByClassname(iEnt, "func_door")) != -1)
		AcceptEntityInput(iEnt, "KillHierarchy");

	gamestart = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			PrintToChat( i, " \x04PHASE THREE: \x06Base Defence !")
			PrintToChat( i, " \x02ZOMBIES HAVE BEEN RELEASED !")
			has_used_pistol[ i ] = true;
		}
	}

	zbb_phase = 3
	gPhase_3 = null;
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) 
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if ( IsValidClient(client) && !IsFakeClient(client) )
	{
		if( LastTeam[client] == TEAM_BUILDERS)
		{
			LastTeamCT--;
		}
		else if( LastTeam[client] == TEAM_ZOMBIES)
		{
			LastTeamT--;
		}
		SaveData2(client);
	}
}

public Action RespawnPlayer2(Handle Timer, any client)
{
	if( !IsPlayerAlive(client) && IsClientInGame(client))
	{
		if(GetClientTeam(client) == TEAM_BUILDERS)
		{
			if( GetConVarInt(zbb_human_respawn) )
			{
				CS_SwitchTeam(client, TEAM_ZOMBIES);
				CS_RespawnPlayer(client);
			}	
		}
		else
		{
			CS_RespawnPlayer(client);
		}
	}
}

// EFFECTS TAKEN FROM ZOMBIES //
void VEffectsCreateEnergySplash(const float origin[3], const float direction[3], bool explosive)
{
    TE_SetupEnergySplash(origin, direction, explosive);
    TE_SendToAll();
}

void VEffectsCreateExplosion(const float origin[3], int flags)
{
    // Create an explosion entity.
    int explosion = CreateEntityByName("env_explosion");
    
    // If explosion entity isn't valid, then stop.
    if (explosion == -1)
    {
        return;
    }
    
    // Get and modify flags on explosion.
    int spawnflags = GetEntProp(explosion, Prop_Data, "m_spawnflags");
    spawnflags = spawnflags | EXP_NODAMAGE | EXP_NODECAL | flags;
    
    // Set modified flags on entity.
    SetEntProp(explosion, Prop_Data, "m_spawnflags", spawnflags);
    
    // Spawn the entity into the world.
    DispatchSpawn(explosion);
    
    // Set the origin of the explosion.
    DispatchKeyValueVector(explosion, "origin", origin);
    
    // Set fireball material.
    PrecacheModel("materials/sprites/xfireball3.vmt");
    DispatchKeyValue(explosion, "fireballsprite", "materials/sprites/xfireball3.vmt");
    
    // Tell the entity to explode.
    AcceptEntityInput(explosion, "Explode");
    
    // Remove entity from world.
    AcceptEntityInput(explosion, "Kill");
}


/* DATABASE SQLITE */

public void MySQL_Init()
{
	if( SQL_CheckConfig("ZombieBB")) 
	{
		SQL_TConnect(SQLCALLBACK, "ZombieBB"); // Credits / Upgrades 
		//SQL_TConnect(SQLCALLBACK2, "ZombieBBAch"); // Achievements
	}
}

public void SQLCALLBACK(Handle owner, Handle hndl, const char[] error, any data)
{
	char Error[255];

	char TQuery[2048];

	if ( hndl == null )
	{
		PrintToServer("Failed to connect: %s", Error)
		LogError( "debug1: %s", Error ); 
	}
	hDatabase = CloneHandle(hndl);

	Format( TQuery, sizeof( TQuery ), "CREATE TABLE IF NOT EXISTS `player_stats` (\ 
																			`player_id` VARCHAR(32) NOT NULL,\
																			`player_name` VARCHAR(32) NOT NULL,\
																			`player_credits` INT(16) default NULL,\
																			`player_zhplevel` INT(16) default NULL,\
																			`player_zgravitylevel` INT(16) default NULL,\
																			`player_zspeedlevel` INT(16) default NULL,\
																			`player_zarmourlevel` INT(16) default NULL,\
																			`player_hhplevel` INT(16) default NULL,\
																			`player_hlimitlevel` INT(16) default NULL,\
																			`player_galil` INT(16) default NULL,\
																			`player_aug` INT(16) default NULL,\
																			`player_m4a4` INT(16) default NULL,\
																			`player_famas` INT(16) default NULL,\
																			`player_ak47` INT(16) default NULL,\
																			`player_mp7` INT(16) default NULL,\
																			`player_mac10` INT(16) default NULL,\
																			`player_ump` INT(16) default NULL,\
																			`player_p90` INT(16) default NULL,\
																			`player_para` INT(16) default NULL,\
																			`player_nova` INT(16) default NULL,\
																			`player_xm1014` INT(16) default NULL,\
																			`player_scout` INT(16) default NULL,\
																			`player_awp` INT(16) default NULL,\
																			`player_deagle` INT(16) default NULL,\
																			`player_p228` INT(16) default NULL,\
																			`player_five` INT(16) default NULL,\
																			`player_elite` INT(16) default NULL,\
																			`player_glock` INT(16) default NULL,\
																			`player_firstconnect` INT(16) default NULL,\
																			PRIMARY KEY (`player_id`))\
																			COLLATE='utf8_unicode_ci'" );

	SQL_TQuery( hDatabase, QueryCreateTable, TQuery);

	Format( TQuery, sizeof( TQuery ), "CREATE TABLE IF NOT EXISTS `player_achievements` (\
																`player_id` VARCHAR(32) NOT NULL, \
																`player_name` VARCHAR(32) NOT NULL, \
																`player_ach_0` INT(16) default NULL, \
																`player_zombiekill` INT(16) default NULL, \
																`player_ach_1` INT(16) default NULL, \
																`player_humankills` INT(16) default NULL, \
																`player_ach_2` INT(16) default NULL, \
																`player_objectsmoved` INT(16) default NULL, \
																`player_ach_3` INT(16) default NULL, \
																`player_headshots` INT(16) default NULL,\
																`player_ach_4` INT(16) default NULL, \
																`player_connects` INT(16) default NULL, \
																`player_ach_5` INT(16) default NULL, \
																`player_clubdread` INT(16) default NULL, \
																`player_ach_6` INT(16) default NULL, \
																`player_totaldamage` INT(16) default NULL, \
																`player_ach_7` INT(16) default NULL, \
																`player_pistolonly` INT(16) default NULL, \
																`player_ach_8` INT(16) default NULL, \
																`player_ach_9` INT(16) default NULL, \
																`player_weaponsbought` INT(16) default NULL, \
																`player_ach_10` INT(16) default NULL, \
																`player_ach_11` INT(16) default NULL, \
																`player_ach_12` INT(16) default NULL, \
																`player_ach_13` INT(16) default NULL, \
																`player_ach_14` INT(16) default NULL, \
																`player_ach_15` INT(16) default NULL, \
																`player_ach_16` INT(16) default NULL, \
																PRIMARY KEY (`player_id`) ) \
																COLLATE='utf8_unicode_ci';" );

	SQL_TQuery( hDatabase, QueryCreateTable, TQuery);
	
}


public void SaveData(int client)
{
	if(IsFakeClient(client))
		return

	char szQuery[ 5000 ]; 
	
	char szKey[128];
	//GetClientAuthString( client, szKey, sizeof( szKey ) );
	GetClientAuthId(client, AuthId_Steam3, szKey, sizeof( szKey ) );
	// player name
	char sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, MAX_NAME_LENGTH);

	int iLength = ((strlen(sName) * 2) + 1);
	char[] sEscapedName = new char[iLength]; 
	SQL_EscapeString(hDatabase, sName, sEscapedName, iLength);

	Format( szQuery, sizeof( szQuery ), "REPLACE INTO `player_stats` (`player_id`, `player_name`, `player_credits`, `player_zhplevel`, `player_zgravitylevel`, `player_zspeedlevel`, `player_zarmourlevel`, `player_hhplevel`, `player_hlimitlevel`, `player_galil`, `player_aug`, `player_m4a4`, `player_famas`, `player_ak47`, `player_mp7`, `player_mac10`, `player_ump`, `player_p90`, `player_para`, `player_nova`, `player_xm1014`, `player_scout`, `player_awp`, `player_deagle`, `player_p228`, `player_five`, `player_elite`, `player_glock`, `player_firstconnect` ) VALUES ('%s', '%s', '%d', '%d', '%d','%d','%d','%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", szKey , sEscapedName, PlayerCredit[client], Zombie_HPlevel[client], Zombie_Gravitylevel[client], Zombie_Speedlevel[client], Zombie_Armourlevel[client], Builder_HPlevel[client], Builder_Spawnlevel[client], g_galil[client], g_aug[client], g_m4a4[client], g_famas[client], g_ak47[client], g_mp7[client], g_mac10[client], g_ump[client], g_p90[client], g_para[client], g_nova[client], g_xm1014[client], g_scout[client], g_awp[client], g_deagle[client], g_p228[client], g_five[client], g_elite[client], g_glock[client], FirstConnect[client] );


	SQL_TQuery( hDatabase, QuerySetData, szQuery, client);
}



public void LoadData(int client)
{
	if(IsFakeClient(client))
		return

	char szQuery[ 5000 ]; 
	
	char szKey[128];
	//GetClientAuthString( client, szKey, sizeof( szKey ) );
	GetClientAuthId(client, AuthId_Steam3, szKey, sizeof( szKey ) );

	Format( szQuery, sizeof( szQuery ), "SELECT `player_credits`, `player_zhplevel`, `player_zgravitylevel`, `player_zspeedlevel`, `player_zarmourlevel`, `player_hhplevel`, `player_hlimitlevel`, `player_galil`, `player_aug`, `player_m4a4`, `player_famas`, `player_ak47`, `player_mp7`, `player_mac10`, `player_ump`, `player_p90`, `player_para`, `player_nova`, `player_xm1014`, `player_scout`, `player_awp`, `player_deagle`, `player_p228`, `player_five`, `player_elite`, `player_glock`, `player_firstconnect` FROM `player_stats` WHERE ( `player_id` = '%s' );", szKey );
	
	SQL_TQuery( hDatabase, QuerySelectData, szQuery, client);	
}


public void QueryCreateTable( Handle owner, Handle hndl, const char[] error, any data)
{ 
	if ( hndl == null )
	{
		LogError( "debug2: %s", error ); 
		
		return;
	} 
}
public void QuerySetData( Handle owner, Handle hndl, const char[] error, any data)
{ 
	if ( hndl == null )
	{
		LogError( "debug3: %s", error ); 
		
		return;
	} 
} 
	
public void QuerySelectData( Handle owner, Handle hndl, const char[] error, any data)
{ 
	if ( hndl != null )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			PlayerCredit[data] 			= SQL_FetchInt(hndl, 0);
			Zombie_HPlevel[data] 		= SQL_FetchInt(hndl, 1);
			Zombie_Gravitylevel[data] 	= SQL_FetchInt(hndl, 2);
			Zombie_Speedlevel[data] 	= SQL_FetchInt(hndl, 3);
			Zombie_Armourlevel[data] 	= SQL_FetchInt(hndl, 4);
			Builder_HPlevel[data] 		= SQL_FetchInt(hndl, 5);
			Builder_Spawnlevel[data]	= SQL_FetchInt(hndl, 6);
			g_galil[data] 				= SQL_FetchInt(hndl, 7);
			g_aug[data] 				= SQL_FetchInt(hndl, 8);
			g_m4a4[data] 				= SQL_FetchInt(hndl, 9);
			g_famas[data] 				= SQL_FetchInt(hndl, 10);
			g_ak47[data] 				= SQL_FetchInt(hndl, 11);
			g_mp7[data] 				= SQL_FetchInt(hndl, 12);
			g_mac10[data] 				= SQL_FetchInt(hndl, 13);
			g_ump[data] 				= SQL_FetchInt(hndl, 14);
			g_p90[data] 				= SQL_FetchInt(hndl, 15);
			g_para[data] 				= SQL_FetchInt(hndl, 16);
			g_nova[data] 				= SQL_FetchInt(hndl, 17);
			g_xm1014[data]				= SQL_FetchInt(hndl, 18);
			g_scout[data] 				= SQL_FetchInt(hndl, 19);
			g_awp[data] 				= SQL_FetchInt(hndl, 20);
			g_deagle[data] 				= SQL_FetchInt(hndl, 21);
			g_p228[data] 				= SQL_FetchInt(hndl, 22);
			g_five[data] 				= SQL_FetchInt(hndl, 23);
			g_elite[data] 				= SQL_FetchInt(hndl, 24);
			g_glock[data] 				= SQL_FetchInt(hndl, 25);
			FirstConnect[data]			= SQL_FetchInt(hndl, 26);
		}
	} 
	else
	{
		LogError( "debug4: %s", error ); 
		
		return;
	}
}


public void SaveData2(int client)
{
	if(IsFakeClient(client))
		return

	char szQuery2[ 5000 ]; 
	
	char szKey[128];
	//GetClientAuthString( client, szKey, sizeof( szKey ) );
	GetClientAuthId(client, AuthId_Steam3, szKey, sizeof( szKey ) );

	char sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, MAX_NAME_LENGTH);

	int iLength = ((strlen(sName) * 2) + 1);
	char[] sEscapedName = new char[iLength]; 
	SQL_EscapeString(hDatabase, sName, sEscapedName, iLength);

	Format( szQuery2, sizeof( szQuery2 ), "REPLACE INTO `player_achievements` (`player_id`, `player_name`, `player_ach_0`, `player_zombiekill`, `player_ach_1`, `player_humankills`, `player_ach_2`, `player_objectsmoved`, `player_ach_3`, `player_headshots`, `player_ach_4`, `player_connects`, `player_ach_5`, `player_clubdread`, `player_ach_6`, `player_totaldamage`, `player_ach_7`, `player_pistolonly`, `player_ach_8`, `player_ach_9`, `player_weaponsbought`, `player_ach_10`, `player_ach_11`, `player_ach_12`, `player_ach_13`, `player_ach_14`, `player_ach_15`, `player_ach_16` ) VALUES ('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d');", szKey , sEscapedName, g_PlayerAchievements[client][0], zombiekills[client], g_PlayerAchievements[client][1], humankills[client], g_PlayerAchievements[client][2], objectsmoved[client], g_PlayerAchievements[client][3], headshots[client], g_PlayerAchievements[client][4], connects[client],   g_PlayerAchievements[client][5], clubdread[client], g_PlayerAchievements[client][6], totaldamage[client],g_PlayerAchievements[client][7], pistolonly[client],g_PlayerAchievements[client][8], g_PlayerAchievements[client][9],g_PlayerAchievements[client][10], weaponsbought[client],g_PlayerAchievements[client][11],  g_PlayerAchievements[client][12],g_PlayerAchievements[client][13],g_PlayerAchievements[client][14],g_PlayerAchievements[client][15],g_PlayerAchievements[client][16]);  
        
	SQL_TQuery( hDatabase, QuerySetData2, szQuery2, client);
}



public void LoadData2(int client)
{
	if(IsFakeClient(client))
		return

	char szQuery[ 5000 ]; 
	
	char szKey[128];
	//GetClientAuthString( client, szKey, sizeof( szKey ) );
	GetClientAuthId(client, AuthId_Steam3, szKey, sizeof( szKey ) );

	Format( szQuery, sizeof( szQuery ), "SELECT `player_ach_0`, `player_zombiekill`, `player_ach_1`, `player_humankills`, `player_ach_2`, `player_objectsmoved`, `player_ach_3`, `player_headshots`, `player_ach_4`, `player_connects`, `player_ach_5`, `player_clubdread`, `player_ach_6`, `player_totaldamage`, `player_ach_7`, `player_pistolonly`, `player_ach_8`, `player_ach_9`, `player_weaponsbought`, `player_ach_10`, `player_ach_11`, `player_ach_12`, `player_ach_13`, `player_ach_14`, `player_ach_15`, `player_ach_16` FROM `player_achievements` WHERE ( `player_id` = '%s' );", szKey );
	
	SQL_TQuery( hDatabase, QuerySelectData2, szQuery, client);
}

public void QuerySetData2( Handle owner, Handle hndl, const char[] error, any data)
{ 
	if ( hndl == null )
	{
		LogError( "debug6: %s", error ); 
		
		return;
	} 
} 
	
public void QuerySelectData2( Handle owner, Handle hndl, const char[] error, any data)
{ 
	if ( hndl != null )
	{
		while ( SQL_FetchRow(hndl) ) 
		{
			g_PlayerAchievements[data][0]		= SQL_FetchInt(hndl, 0);
			zombiekills[data]					= SQL_FetchInt(hndl, 1);
			g_PlayerAchievements[data][1]		= SQL_FetchInt(hndl, 2);
			humankills[data]					= SQL_FetchInt(hndl, 3);
			g_PlayerAchievements[data][2]		= SQL_FetchInt(hndl, 4);
			objectsmoved[data]					= SQL_FetchInt(hndl, 5);
			g_PlayerAchievements[data][3]		= SQL_FetchInt(hndl, 6);
			headshots[data]						= SQL_FetchInt(hndl, 7);
			g_PlayerAchievements[data][4]		= SQL_FetchInt(hndl, 8);
			connects[data]						= SQL_FetchInt(hndl, 9);
			g_PlayerAchievements[data][5]		= SQL_FetchInt(hndl, 10);
			clubdread[data]						= SQL_FetchInt(hndl, 11);
			g_PlayerAchievements[data][6]		= SQL_FetchInt(hndl, 12);
			totaldamage[data]					= SQL_FetchInt(hndl, 13);
			g_PlayerAchievements[data][7]		= SQL_FetchInt(hndl, 14);
			pistolonly[data]					= SQL_FetchInt(hndl, 15);
			g_PlayerAchievements[data][8]		= SQL_FetchInt(hndl, 16);
			g_PlayerAchievements[data][9]		= SQL_FetchInt(hndl, 17);
			weaponsbought[data]					= SQL_FetchInt(hndl, 18);
			g_PlayerAchievements[data][10]		= SQL_FetchInt(hndl, 19);
			g_PlayerAchievements[data][11]		= SQL_FetchInt(hndl, 20);
			g_PlayerAchievements[data][12]		= SQL_FetchInt(hndl, 21);
			g_PlayerAchievements[data][13]		= SQL_FetchInt(hndl, 22);
			g_PlayerAchievements[data][14]		= SQL_FetchInt(hndl, 23);
			g_PlayerAchievements[data][15]		= SQL_FetchInt(hndl, 24);
			g_PlayerAchievements[data][16]		= SQL_FetchInt(hndl, 25);
		}
	} //26
	else
	{
		LogError( "debug7: %s", error ); 
		
		return;
	}
}

/* GUN MENU SECLECT */
public Action GunMenuSelect(int client)
{
	Handle menu = CreateMenu(GunMenuSelect_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Gun Menu Select \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	Format(szItems1, sizeof( szItems1 ), "Select Rifles" );
	char szItems2[60];
	Format(szItems2, sizeof( szItems2 ), "Select SMGs" );
	char szItems3[60];
	Format(szItems3, sizeof( szItems3 ), "Select Others" );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", szItems3);


	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}

public int GunMenuSelect_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { RIFLE_SELECT(client); }
			case 1: { SUB_SELECT(client); }
			case 2: { OTHERS_SELECT(client); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       LoadOutMenu(client);
    } 
}
public Action RIFLE_SELECT(int client)
{
	Handle menu = CreateMenu(RIFLE_SELECT_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Gun Menu Select Rifle \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	Format(szItems1, sizeof( szItems1 ), "Galil" );
	char szItems2[60];
	Format(szItems2, sizeof( szItems2 ), "AUG" )
	char szItems3[60];
	Format(szItems3, sizeof( szItems3 ), "M4A4" )
	char szItems4[60];
	Format(szItems4, sizeof( szItems4 ), "Famas" )
	char szItems5[60];
	Format(szItems5, sizeof( szItems5 ), "AK47" )

	if(g_galil[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems1);
	else
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	if(g_aug[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems2);
	else
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	if(g_m4a4[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems3);
	else
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	if(g_famas[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems4);
	else
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	if(g_ak47[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems5);
	else
		AddMenuItem(menu, "class_id", szItems5, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}
public int RIFLE_SELECT_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{

		switch(item)
		{
			case 0: { g_remember_primary[client] = 1; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 1: { g_remember_primary[client] = 2; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 2: { g_remember_primary[client] = 3; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 3: { g_remember_primary[client] = 4; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 4: { g_remember_primary[client] = 5; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuSelect(client);
    } 
}

public Action SUB_SELECT(int client)
{
	Handle menu = CreateMenu(SUB_SELECT_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Gun Menu Select SMG \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems0[60];
	Format(szItems0, sizeof( szItems0 ), "Bizon(FREE)" );

	char szItems1[60];
	Format(szItems1, sizeof( szItems1 ), "MP7" );
	char szItems2[60];
	Format(szItems2, sizeof( szItems2 ), "MAC-10" )
	char szItems3[60];
	Format(szItems3, sizeof( szItems3 ), "UMP 45" )
	char szItems4[60];
	Format(szItems4, sizeof( szItems4 ), "P90" )

	AddMenuItem(menu, "class_id", szItems0);
	if(g_mp7[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems1);
	else
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	if(g_mac10[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems2);
	else
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	if(g_ump[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems3);
	else
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	if(g_p90[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems4);
	else
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}
public int SUB_SELECT_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { g_remember_primary[client] = 0; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 1: { g_remember_primary[client] = 6; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 2: { g_remember_primary[client] = 7; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 3: { g_remember_primary[client] = 8; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 4: { g_remember_primary[client] = 9; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuSelect(client);
    } 
}
public Action OTHERS_SELECT(int client)
{
	Handle menu = CreateMenu(OTHERS_SELECT_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Gun Menu Select Others \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	Format(szItems1, sizeof( szItems1 ), "Nova" );
	char szItems2[60];
	Format(szItems2, sizeof( szItems2 ), "XM1014" )
	char szItems3[60];
	Format(szItems3, sizeof( szItems3 ), "Scout" )
	char szItems4[60];
	Format(szItems4, sizeof( szItems4 ), "AWP" )
	char szItems5[60];
	Format(szItems5, sizeof( szItems5 ), "M249" )

	if(g_nova[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems1);
	else
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	if(g_xm1014[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems2);
	else
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	if(g_scout[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems3);
	else
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	if(g_awp[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems4);
	else
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	if(g_para[client] )
		AddMenuItem(menu, "class_id", szItems5);
	else
		AddMenuItem(menu, "class_id", szItems5, ITEMDRAW_DISABLED);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}
public int OTHERS_SELECT_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { g_remember_primary[client] = 10; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 1: { g_remember_primary[client] = 11; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 2: { g_remember_primary[client] = 12; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 3: { g_remember_primary[client] = 13; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
			case 4: { g_remember_primary[client] = 14; LoadOutMenu(client); SetCookieInt(client, g_hPrimWepCookie, g_remember_primary[client]); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuSelect(client);
    } 
}

public Action PISTOL_SELECT(int client)
{
	Handle menu = CreateMenu(PISTOL_SELECT_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Gun Menu Select Pistols \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	Format(szItems1, sizeof( szItems1 ), "P250" );
	char szItems2[60];
	Format(szItems2, sizeof( szItems2 ), "FiveSeven" )
	char szItems3[60];
	Format(szItems3, sizeof( szItems3 ), "Dual Barettas" )
	char szItems4[60];
	Format(szItems4, sizeof( szItems4 ), "Glock 18c" )
	char szItems5[60];
	Format(szItems5, sizeof( szItems5 ), "Desert Eagle" )

	if(g_p228[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems1);
	else
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	if(g_five[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems2);
	else
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	if(g_elite[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems3);
	else
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	if(g_glock[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems4);
	else
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	if(g_deagle[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		AddMenuItem(menu, "class_id", szItems5);
	else
		AddMenuItem(menu, "class_id", szItems5, ITEMDRAW_DISABLED);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}
public int PISTOL_SELECT_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { g_remember_secondary[client] = 1; LoadOutMenu(client); SetCookieInt(client, g_hSecWepCookie, g_remember_secondary[client]); }
			case 1: { g_remember_secondary[client] = 2; LoadOutMenu(client); SetCookieInt(client, g_hSecWepCookie, g_remember_secondary[client]); }
			case 2: { g_remember_secondary[client] = 3; LoadOutMenu(client); SetCookieInt(client, g_hSecWepCookie, g_remember_secondary[client]); }
			case 3: { g_remember_secondary[client] = 4; LoadOutMenu(client); SetCookieInt(client, g_hSecWepCookie, g_remember_secondary[client]); }
			case 4: { g_remember_secondary[client] = 5; LoadOutMenu(client); SetCookieInt(client, g_hSecWepCookie, g_remember_secondary[client]); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       LoadOutMenu(client);
    } 
}
/* GUN MENU UNLOCK */


/* GUN MENU UNLOCK */


public Action GunMenuUnlock(int client)
{
	Handle menu = CreateMenu(GunMenuUnlock_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Gun Menu Unlock \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	Format(szItems1, sizeof( szItems1 ), "Unlock Rifles" );
	char szItems2[60];
	Format(szItems2, sizeof( szItems2 ), "Unlock SMGs" );
	char szItems3[60];
	Format(szItems3, sizeof( szItems3 ), "Unlock Others" );
	char szItems4[60];
	Format(szItems4, sizeof( szItems4 ), "Unlock Pistols" );

	AddMenuItem(menu, "class_id", szItems1);
	AddMenuItem(menu, "class_id", szItems2);
	AddMenuItem(menu, "class_id", szItems3);
	AddMenuItem(menu, "class_id", szItems4);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}

public int GunMenuUnlock_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: { RIFLE_UNLOCK(client); }
			case 1: { SUB_UNLOCK(client); }
			case 2: { OTHER_UNLOCK(client); }
			case 3: { PISTOL_UNLOCK(client); }
		}
	}
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       MainMenu(client);
    }
}

public Action RIFLE_UNLOCK(int client)
{
	Handle menu = CreateMenu(RIFLE_UNLOCK_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Rifle Unlock \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	if(g_galil[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems1, sizeof( szItems1 ), "Galil \nCost: -Unlocked-" );
	else
		Format(szItems1, sizeof( szItems1 ), "Galil \nCost: 1000" );

	char szItems2[60];
	if(g_aug[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems2, sizeof( szItems2 ), "AUG \nCost: -Unlocked-" );
	else
		Format(szItems2, sizeof( szItems2 ), "AUG \nCost: 1500" );		

	char szItems3[60];
	if(g_m4a4[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems3, sizeof( szItems3 ), "M4A4 \nCost: -Unlocked-" );
	else
		Format(szItems3, sizeof( szItems3 ), "M4A4 \nCost: 2500" );	

	char szItems4[60];
	if(g_famas[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems4, sizeof( szItems4 ), "Famas \nCost: -Unlocked-" );
	else
		Format(szItems4, sizeof( szItems4 ), "Famas \nCost: 1250" );	

	char szItems5[60];
	if(g_ak47[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems5, sizeof( szItems5 ), "AK47 \nCost: -Unlocked-" );
	else
		Format(szItems5, sizeof( szItems5 ), "AK47 \nCost: 3500" );	

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems1);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems2);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems3);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems4);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems5, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems5);


	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}
public int RIFLE_UNLOCK_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: 
			{
				if(!g_galil[client] )
				{
					if( PlayerCredit[client] >= 1000 )
					{
						g_galil[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 1000)
						PrintToChat( client, " You have unlocked the \x04Galil!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04Galil!")
				}

				RIFLE_UNLOCK(client);
			}
			case 1:
			{
				if(!g_aug[client] )
				{
					if( PlayerCredit[client] >= 1500 )
					{
						g_aug[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 1500 )
						PrintToChat( client, " You have unlocked the \x04AUG!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04AUG!")
				}
				
				RIFLE_UNLOCK(client);
			}
			case 2:
			{
				if(!g_m4a4[client] )
				{
					if( PlayerCredit[client] >= 2500 )
					{
						g_m4a4[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 2500 )
						PrintToChat( client, " You have unlocked the \x04M4A4!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04M4A4!")
				}
				
				RIFLE_UNLOCK(client);
			}
			case 3:
			{
				if(!g_famas[client] )
				{
					if( PlayerCredit[client] >= 1250 )
					{
						g_famas[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 1250 )
						PrintToChat( client, " You have unlocked the \x04Famas!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04Famas!")
				}
				
				RIFLE_UNLOCK(client);
			}
			case 4:
			{
				if(!g_ak47[client] )
				{
					if( PlayerCredit[client] >= 3500 )
					{
						g_ak47[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 3500 )
						PrintToChat( client, " You have unlocked the \x04AK47!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04AK47!")
				}
				
				RIFLE_UNLOCK(client);
			}
		}			
	
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuUnlock(client);
    } 
}


public Action SUB_UNLOCK(int client)
{
	Handle menu = CreateMenu(SUB_UNLOCK_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Sub Machine Gun Unlock \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	if(g_mp7[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems1, sizeof( szItems1 ), "MP7 \nCost: -Unlocked-" );
	else
		Format(szItems1, sizeof( szItems1 ), "MP7 \nCost: 200" );

	char szItems2[60];
	if(g_mac10[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems2, sizeof( szItems2 ), "MAC-10 \nCost: -Unlocked-" );
	else
		Format(szItems2, sizeof( szItems2 ), "MAC-10 \nCost: 400" );		

	char szItems3[60];
	if(g_ump[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems3, sizeof( szItems3 ), "UMP \nCost: -Unlocked-" );
	else
		Format(szItems3, sizeof( szItems3 ), "UMP \nCost: 600" );	

	char szItems4[60];
	if(g_p90[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems4, sizeof( szItems4 ), "P90 \nCost: -Unlocked-" );
	else
		Format(szItems4, sizeof( szItems4 ), "P90 \nCost: 850" );	


	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems1);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems2);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems3);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems4);


	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}

public int SUB_UNLOCK_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: 
			{
				if(!g_mp7[client] )
				{
					if( PlayerCredit[client] >= 200 )
					{
						g_mp7[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 200)
						PrintToChat( client, " You have unlocked the \x04MP7!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04MP7!")
				}

				SUB_UNLOCK(client);
			}
			case 1:
			{
				if(!g_mac10[client] )
				{
					if( PlayerCredit[client] >= 400 )
					{
						g_mac10[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 400 )
						PrintToChat( client, " You have unlocked the \x04MAC-10!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04MAC-10!")
				}
				
				SUB_UNLOCK(client);
			}
			case 2:
			{
				if(!g_ump[client] )
				{
					if( PlayerCredit[client] >= 600 )
					{
						g_ump[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 600 )
						PrintToChat( client, " You have unlocked the \x04UMP!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04UMP!")
				}
				
				SUB_UNLOCK(client);
			}
			case 3:
			{
				if(!g_p90[client] )
				{
					if( PlayerCredit[client] >= 850 )
					{
						g_p90[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 850 )
						PrintToChat( client, " You have unlocked the \x04P90!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04P90!")
				}
				
				SUB_UNLOCK(client);
			}
		}			
	
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuUnlock(client);
    } 
}

public Action OTHER_UNLOCK(int client)
{
	Handle menu = CreateMenu(OTHER_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Other Unlock \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	if(g_nova[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems1, sizeof( szItems1 ), "Nova \nCost: -Unlocked-" );
	else
		Format(szItems1, sizeof( szItems1 ), "Nova \nCost: 400" );

	char szItems2[60];
	if(g_xm1014[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems2, sizeof( szItems2 ), "XM1014 \nCost: -Unlocked-" );
	else
		Format(szItems2, sizeof( szItems2 ), "XM1014 \nCost: 600" );		

	char szItems3[60];
	if(g_scout[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems3, sizeof( szItems3 ), "Scout \nCost: -Unlocked-" );
	else
		Format(szItems3, sizeof( szItems3 ), "Scout \nCost: 1000" );	

	char szItems4[60];
	if(g_awp[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems4, sizeof( szItems4 ), "AWP \nCost: -Unlocked-" );
	else
		Format(szItems4, sizeof( szItems4 ), "AWP \nCost: 2000" );	

	char szItems5[60];
	if(g_para[client] )
		Format(szItems5, sizeof( szItems5 ), "M249 \nCost: -Unlocked-" );
	else
		Format(szItems5, sizeof( szItems5 ), "M249 \nCost: 10000" );	


	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems1);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems2);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems3);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems4);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems5, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems5);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}

public int OTHER_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: 
			{
				if(!g_nova[client] )
				{
					if( PlayerCredit[client] >= 400 )
					{
						g_nova[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 400)
						PrintToChat( client, " You have unlocked the \x04Nova!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the\x04 Nova!")
				}

				OTHER_UNLOCK(client);
			}
			case 1:
			{
				if(!g_xm1014[client] )
				{
					if( PlayerCredit[client] >= 600 )
					{
						g_xm1014[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 600)
						PrintToChat( client, " You have unlocked the \x04XM1014!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04XM1014!")
				}
				
				OTHER_UNLOCK(client);
			}
			case 2:
			{
				if(!g_scout[client] )
				{
					if( PlayerCredit[client] >= 1000 )
					{
						g_scout[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 1000)
						PrintToChat( client, " You have unlocked the \x04Scout!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04Scout!")
				}
				
				OTHER_UNLOCK(client);
			}
			case 3:
			{
				if(!g_awp[client])
				{
					if( PlayerCredit[client] >= 2000 )
					{
						g_awp[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 2000)
						PrintToChat( client, " You have unlocked the \x04AWP!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the\x04 AWP!")
				}
				
				OTHER_UNLOCK(client);
			}
			case 4:
			{
				if(!g_para[client])
				{
					if( PlayerCredit[client] >= 10000 )
					{
						g_para[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 10000 )
						PrintToChat( client, " You have unlocked the\x04 M249!")
						weaponsbought[client]++
						check_warmachine(client)

						switch (g_PlayerAchievements[client][ACHIEVE_RAMBO])
						{
							case LEVEL_NONE:       
							{
								g_PlayerAchievements[client][ACHIEVE_RAMBO]=LEVEL_I;
								PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUnlock the M249-SAW! \n\x03+25 Credits", ACHIEVEMENTS[ACHIEVE_RAMBO][LEVEL_I]);
								Set_Player_Credit( client, PlayerCredit[client] + 25 );
								EmitSoundToClientAny(client, ACH_SOUND);
								SaveData2(client);
							}
						}
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the\x04 M249!")
				}
				
				OTHER_UNLOCK(client);
			}
		}			
	
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuUnlock(client);
    } 
}

public Action PISTOL_UNLOCK(int client)
{
	Handle menu = CreateMenu(Pistol_Handler);

	char szMsg[128];
	
	Format(szMsg, sizeof( szMsg ), "Pistol Unlock \nCredits: %d \n----------------------", PlayerCredit[client]);
	
	SetMenuTitle(menu, szMsg);

	char szItems1[60];
	if(g_p228[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems1, sizeof( szItems1 ), "P250 \nCost: -Unlocked-" );
	else
		Format(szItems1, sizeof( szItems1 ), "P250 \nCost: 300" );

	char szItems2[60];
	if(g_five[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems2, sizeof( szItems2 ), "FiveSeven \nCost: -Unlocked-" );
	else
		Format(szItems2, sizeof( szItems2 ), "FiveSeven \nCost: 400" );		

	char szItems3[60];
	if(g_elite[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems3, sizeof( szItems3 ), "Dual Berettas \nCost: -Unlocked-" );
	else
		Format(szItems3, sizeof( szItems3 ), "Dual Berettas \nCost: 200" );	

	char szItems4[60];
	if(g_glock[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems4, sizeof( szItems4 ), "Glock \nCost: -Unlocked-" );
	else
		Format(szItems4, sizeof( szItems4 ), "Glock \nCost: 100" );	

	char szItems5[60];
	if(g_deagle[client] || GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		Format(szItems5, sizeof( szItems5 ), "Deagle \nCost: -Unlocked-" );
	else
		Format(szItems5, sizeof( szItems5 ), "Deagle \nCost: 500" );	


	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems1, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems1);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems2, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems2);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems3, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems3);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems4, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems4);

	if( GetUserFlagBits(client) & ADMFLAG_CUSTOM6 )
		AddMenuItem(menu, "class_id", szItems5, ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "class_id", szItems5);

	SetMenuExitBackButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}

public int Pistol_Handler(Handle menu, MenuAction action, int client, int item)
{
	if( action == MenuAction_Select )
	{
		switch(item)
		{
			case 0: 
			{
				if(!g_p228[client] )
				{
					if( PlayerCredit[client] >= 300 )
					{
						g_p228[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 300 )
						PrintToChat( client, " You have unlocked the \x04P250!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04P250!")
				}

				PISTOL_UNLOCK(client);
			}
			case 1:
			{
				if(!g_five[client] )
				{
					if( PlayerCredit[client] >= 400 )
					{
						g_five[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 400 )
						PrintToChat( client, " You have unlocked the\x04 Fiveseven!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the\x04 Fiveseven!")
				}
				
				PISTOL_UNLOCK(client);
			}
			case 2:
			{
				if(!g_elite[client] )
				{
					if( PlayerCredit[client] >= 200 )
					{
						g_elite[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 200 )
						PrintToChat( client, " You have unlocked the\x04 Dual Berettas!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the \x04Dual Berettas!")
				}
				
				PISTOL_UNLOCK(client);
			}
			case 3:
			{
				if(!g_glock[client] )
				{
					if( PlayerCredit[client] >= 100 )
					{
						g_glock[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 100)
						PrintToChat( client, " You have unlocked the\x04 Glock!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the\x04 Glock!")
				}
				
				PISTOL_UNLOCK(client);
			}
			case 4:
			{
				if(!g_deagle[client] )
				{
					if( PlayerCredit[client] >= 500 )
					{
						g_deagle[client] = 1
						Set_Player_Credit(client, PlayerCredit[client] - 500)
						PrintToChat( client, " You have unlocked the\x04 Deagle!")
						weaponsbought[client]++
						check_warmachine(client)
					}
					else
					{
						PrintToChat( client, " \x02You do not have enough credits!")
					}
				}
				else
				{
					PrintToChat( client, " You have already unlocked the\x04 Deagle!")
				}
				
				PISTOL_UNLOCK(client);
			}
		}			
	
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) 
    { 
       GunMenuUnlock(client);
    } 
}

public Action Set_Player_Credit(int client, int value)
{
	if ( !IsValidClient(client) )
		return Plugin_Continue;

	
	PlayerCredit[client] = value

	SaveData(client);


	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_Status[client] && !g_Attracting[client])
	{
		if( buttons & IN_ATTACK )
		{
			g_Attracting[client] = true;
		}
	}

	if( g_Status[client] && !g_Repelling[client] )
	{
		if( buttons & IN_ATTACK2 )
		{
			g_Repelling[client] = true;
		}
	}

	if( buttons & IN_USE )
    {
    	if( zbb_phase == 1 )
    	{
    		if( GetClientTeam(client) == TEAM_BUILDERS )
    		{
    			Action_Grab(client);
    		}    		
    	}

    	int target = GetClientAimTarget(client, true);	

    	if(target != -1 && GetClientTeam(target) == TEAM_BUILDERS)
    	{
    		char szItems[60];
    		Format(szItems, sizeof( szItems ), "%N's Stats \nCredit(s): %d", target, PlayerCredit[target] );

    		char szItems3[60];
    		Format(szItems3, sizeof( szItems3 ), "Builder HP Level: %d / 10", Builder_HPlevel[target] );

    		char szItems4[60];
    		Format(szItems4, sizeof( szItems4 ), "Builder Spawn Limit Level: %d / 5", Builder_Spawnlevel[target] );

    		char WeppPrim[32];
    		strcopy(WeppPrim, sizeof(WeppPrim), PRIMCONST[g_remember_primary[target]][7]);
    		WeppPrim[0] = CharToUpper(WeppPrim[0]);

    		char WeppSec[32];
    		strcopy(WeppSec, sizeof(WeppSec), SECONDCONST[g_remember_secondary[target]][7]);
    		WeppSec[0] = CharToUpper(WeppSec[0]);

    		char szItems5[60];
    		Format(szItems5, sizeof( szItems5 ), "Primary Gun: %s", WeppPrim );

    		char szItems6[60];
    		Format(szItems6, sizeof( szItems6 ), "Secondary Gun: %s", WeppSec );

    		Handle panel = CreatePanel();
    		SetPanelTitle(panel, szItems );
    		DrawPanelItem(panel, "", ITEMDRAW_SPACER );
    		DrawPanelItem(panel, szItems3, ITEMDRAW_RAWLINE);
    		DrawPanelItem(panel, szItems4, ITEMDRAW_RAWLINE);
    		DrawPanelItem(panel, "", ITEMDRAW_SPACER );
    		DrawPanelItem(panel, szItems5, ITEMDRAW_RAWLINE);
    		DrawPanelItem(panel, szItems6, ITEMDRAW_RAWLINE);

    		SendPanelToClient(panel, client, PanelHandler1, 3);

    		CloseHandle(panel);
		}
		else if (target != -1 && GetClientTeam(target) == TEAM_ZOMBIES)
		{
			char szItems[60];
			Format(szItems, sizeof( szItems ), "%N's Stats \nCredit(s): %d", target, PlayerCredit[target] );

			char szItems3[60];
			Format(szItems3, sizeof( szItems3 ), "Zombie HP Level: %d / 20", Zombie_HPlevel[target] );

			char szItems4[60];
			Format(szItems4, sizeof( szItems4 ), "Zombie Speed Level: %d / 20", Zombie_Speedlevel[target] );

			char szItems5[60];
			Format(szItems5, sizeof( szItems5 ), "Zombie Gravity Level: %d / 20", Zombie_Gravitylevel[target] );

			char szItems6[60];
			Format(szItems6, sizeof( szItems6 ), "Zombie Armour Level: %d / 20", Zombie_Armourlevel[target] );
			Handle panel = CreatePanel();
			SetPanelTitle(panel, szItems );
			DrawPanelItem(panel, "", ITEMDRAW_SPACER );
			DrawPanelItem(panel, szItems3, ITEMDRAW_RAWLINE);
 			DrawPanelItem(panel, szItems4, ITEMDRAW_RAWLINE);
			DrawPanelItem(panel, szItems5, ITEMDRAW_RAWLINE);
 			DrawPanelItem(panel, szItems6, ITEMDRAW_RAWLINE);

			SendPanelToClient(panel, client, PanelHandler1, 3);
 			
 			CloseHandle(panel);

		}
	}
	else if ( g_Status[client] )
	{
		Action_Drop(client);
	}
	return Plugin_Continue;
}

public int PanelHandler1(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{

	}
}


stock void SetSecondaryClip(int client, int ammo)
{
	SetEntProp(g_remember_primary[client], Prop_Send, "m_iClip1",ammo);
	SetEntProp(g_remember_secondary[client], Prop_Send, "m_iClip1",ammo);
}

stock int GetSecondaryClip(int client)
{
	return GetEntProp(g_remember_primary[client], Prop_Send, "m_iClip1");
}

/* NATIVES */

public int Native_SetPlayerCredit(Handle plugin, int numParams)
{
	int client = GetNativeCell( 1 );
	int value = GetNativeCell( 2 );

	if( !IsValidClient(client) )
		return;

	PlayerCredit[client] = value

	SaveData(client);	
}

public int Native_GetPlayerCredit(Handle plugin, int numParams)
{
	int client = GetNativeCell( 1 );

	return PlayerCredit[client];
}

public void check_banker(int client)
{
		//Break the Bank
	switch (g_PlayerAchievements[ client ][ ACHIEVE_BANK ] )
	{
		case LEVEL_NONE:       
		{
			if (PlayerCredit[client]>=5000)
			{
				g_PlayerAchievements[ client ][ ACHIEVE_BANK ] = LEVEL_I;
				PrintToChat( client, " [ ACHIEVEMENT ]\x03%s \nReach 5000 credits!\n \x03+250 Credits", ACHIEVEMENTS[ ACHIEVE_BANK ][ LEVEL_I ] );
				Set_Player_Credit( client , PlayerCredit[ client ] + 250 );
				EmitSoundToClientAny( client, ACH_SOUND );
				SaveData2(client);

			}
		}      
	}
}

public void check_achievements(int client)
{
	if (IsFakeClient(client))
		return;
               
	bool achievementgained=false;
	int currentachievement=0;
	int kills;
	
	//Kills as a Zombie
	currentachievement=g_PlayerAchievements[client][ACHIEVE_ZKILLS];
	
	kills=zombiekills[client];
	
	switch (currentachievement)
	{
		case LEVEL_NONE:       
		{       
			if (kills>99)
			{
				g_PlayerAchievements[client][ACHIEVE_ZKILLS]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nKill 100 zombies!\n \x03+25 Credits", ACHIEVEMENTS[ACHIEVE_ZKILLS][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 25 )
				achievementgained=true;

			}
			
		}
	}
			
	//Kills as a Builder
	currentachievement=g_PlayerAchievements[client][ACHIEVE_HKILLS];
			
	kills=humankills[client];
		
	switch (currentachievement)
	{
		case LEVEL_NONE:       
		{
			if (kills>24)
			{
				g_PlayerAchievements[client][ACHIEVE_HKILLS]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nKill 25 builders!\n \x03+25 Credits", ACHIEVEMENTS[ACHIEVE_HKILLS][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 25 )
				achievementgained=true;
			}
		}
	}
	                      
		//Total Headshots
	currentachievement=g_PlayerAchievements[client][ACHIEVE_HEADSHOTS];
	kills=headshots[client];
              
	switch (currentachievement)
	{
		case LEVEL_NONE:       
		{
			if (kills>49)
			{
				g_PlayerAchievements[client][ACHIEVE_HEADSHOTS]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nGet 50 headshots!\n \x03+50 Credits", ACHIEVEMENTS[ACHIEVE_HEADSHOTS][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 50 )
				achievementgained=true;
			}
		}
	}
                       
	//Total Connects
	currentachievement=g_PlayerAchievements[client][ACHIEVE_CONNECTS];
      
	kills=connects[client];
               
	switch (currentachievement)
	{
		case LEVEL_NONE:       
		{
			if (kills>9)
			{
				g_PlayerAchievements[client][ACHIEVE_CONNECTS]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \n??????????\n \x03+5 Credits", ACHIEVEMENTS[ACHIEVE_CONNECTS][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 5 )
				achievementgained=true;
			}
		}
	}
                       
                      
	//Guns are for girls
	currentachievement=g_PlayerAchievements[client][ACHIEVE_KNIFEZOMBIE];
       
	kills=clubdread[client];
              
	switch (currentachievement)
	{
		case LEVEL_NONE:       
		{
			if (kills>0)
			{
				g_PlayerAchievements[client][ACHIEVE_KNIFEZOMBIE]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nKnife a zombie!\n \x03+75 Credits", ACHIEVEMENTS[ACHIEVE_KNIFEZOMBIE][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 75 )
				achievementgained=true;
			}
		}
	}
	
              
	if (achievementgained)
	{
		EmitSoundToClientAny(client, ACH_SOUND );
		SaveData2(client);
		check_banker(client)
	}

}

public void AchieveCount(int client)
{
	numofachieve[client]=0;
	
	for (int counter=0; counter<MAX_ACHIEVEMENTS; counter++)
		numofachieve[client]=numofachieve[client]+g_PlayerAchievements[client][counter]
                       
	if (numofachieve[client]==(MAX_ACHIEVEMENTS-1))
	{
		//Achievement Hunter
		switch (g_PlayerAchievements[client][ACHIEVE_HUNT])
		{
			case LEVEL_NONE:
			{
				g_PlayerAchievements[client][ACHIEVE_HUNT]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUnlock all of the achievements in the game!\n \x03+250 Credits", ACHIEVEMENTS[ACHIEVE_HUNT][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 250 );
				EmitSoundToClient(client, ACH_SOUND);
				SaveData2(client);
				check_banker(client)
			}
		}      
	}
}

public void check_warmachine(int client)
{
	//Arms Dealer
	switch (g_PlayerAchievements[client][ACHIEVE_ARMS])
	{
		case LEVEL_NONE:       
		{
			if (weaponsbought[client]==9)
			{
				g_PlayerAchievements[client][ACHIEVE_ARMS]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUnlock half of the guns in the game!\n \x03+100 Credits", ACHIEVEMENTS[ACHIEVE_ARMS][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 100 );
				EmitSoundToClientAny(client, ACH_SOUND);
				SaveData2(client);
				check_banker(client)
			}
		}
	}
               
	//War Machine
	switch (g_PlayerAchievements[client][ACHIEVE_WAR])
	{
		case LEVEL_NONE:
		{                  
			if (weaponsbought[client]==19)
			{
				g_PlayerAchievements[client][ACHIEVE_WAR]=LEVEL_I;
				PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s: \nUnlock all of the guns in the game!\n \x03+200 Credits", ACHIEVEMENTS[ACHIEVE_WAR][LEVEL_I]);
				Set_Player_Credit( client, PlayerCredit[client] + 200 );
				EmitSoundToClientAny(client, ACH_SOUND);
				SaveData2(client);
				check_banker(client)
			}
		}
	}
}

/* BLOCK HUD MESSAGES */

public Action Event_TextMsg(UserMsg msg_id, Handle pb, int[] players, int playersNum, bool reliable, bool init)
{
	if(reliable)
	{
		char text[32];
		PbReadString(pb, "params", text, sizeof(text),0);
		if (StrContains(text, "#Chat_SavePlayer_", false) != -1)
			return Plugin_Handled;
		
		if (StrContains(text, "#Cstrike_TitlesTXT_Game_teammate_attack", false) != -1)
			return Plugin_Handled;
			
		if (StrContains(text, "#SFUI_Notice_Warmup_Has_Ended", false) != -1)
			return Plugin_Handled;
			
		if (StrContains(text, "#Cstrike_game_join_", false) != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnConVarChange(Handle hCvar, char[] oldValue, char[] newValue)
{
	char sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	
	if(hCvar == g_Terrorist)
		SetConVarString(g_hCvarTeamName2, sBuffer);
	else if(hCvar == g_CTerrorist)
		SetConVarString(g_hCvarTeamName1, sBuffer);
}




stock bool IsStuckInEnt(int client, int ent)
{
	float vecMin[3], vecMax[3], vecOrigin[3];

	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);

	GetClientAbsOrigin(client, vecOrigin);

	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_ALL, TraceRayHitOnlyEnt, ent);
	return TR_DidHit();
}

public bool TraceRayHitOnlyEnt(int entityhit, int mask, any data) 
{
	return entityhit==data;
}


/* ACTION COMMANDS */

public Action GrabCmd(int client, int args)
{
	if( GetClientTeam(client) == TEAM_BUILDERS )
	{
		Action_Grab(client);
	}
	return Plugin_Handled;
}

public Action DropCmd(int client, int args)
{
	if(IsPlayerAlive(client))
		Action_Drop(client);
	return Plugin_Handled;
}

public void Action_Grab(int client)
{
	if( client > 0 && client <= MaxClients && IsPlayerAlive(client) && !g_Status[client] && !g_Grabbed[client])
	{
		g_Status[client] = true;
		CreateTimer(0.1, GrabSearch, client, TIMER_REPEAT); 
	}
}
char tname[20]; // Parenting
public Action GrabSearch(Handle timer, any client)
{
	if( client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && g_Status[client] && !g_Grabbed[client])
	{
		float clientloc[3], clientang[3], pos[3];
		GetClientEyePosition(client, clientloc);
		GetClientEyeAngles(client, clientang);
		
		TR_TraceRayFilter(clientloc, clientang, MASK_ALL, RayType_Infinite, TraceRayGrabEnt);
		g_Targetindex[client] = TR_GetEntityIndex();
		TR_GetEndPosition(pos)

		char Classname[32];

		GetEdictClassname(g_Targetindex[client], Classname, sizeof(Classname))
		
		if(g_Targetindex[client] > 0 && IsValidEntity(g_Targetindex[client]) || StrEqual(Classname, "func_brush", false))
		{
			if (g_Targetindex[client] == -1 || client == -1 || StrEqual(Classname, "func_door", false)) {
				return Plugin_Handled;
			}


			if( StrEqual(Classname, "func_brush", false) )
			{
				int ent = SpawnParent(pos);
				Dummy[ent] = g_Targetindex[client];
				SetVariantString(tname);
				DispatchKeyValue(g_Targetindex[client], "Parentname", tname)
				AcceptEntityInput(g_Targetindex[client], "SetParent", ent);
				g_Targetindex[client] = ent;
			}

			if(zbb_phase != 1 || GetClientTeam(client) == 2  && g_Targetindex[client] != 0)
			{
				PrintToChat( client, " \x04Claimed by: \x03%N", g_EntClaim[g_Targetindex[client]]);
				return Plugin_Handled;
			}

			if(g_EntClaim[g_Targetindex[client]] == 0 || g_EntClaim[g_Targetindex[client]] == client && zbb_phase == 1)
			{
				g_EntClaim[g_Targetindex[client]] = client; //Claim Entity

				objectsmoved[client]++
				if (objectsmoved[client] == 10000)
		        {
		                switch (g_PlayerAchievements[client][ACHIEVE_OBJMOVED])
		                {
		                        case LEVEL_NONE:       
		                        {
		                                g_PlayerAchievements[client][ACHIEVE_OBJMOVED]=LEVEL_I;
		                                PrintToChat(client, " \x04[ ACHIEVEMENT ] \x03%s:\n Move 10000 objects!\n \x03+15 Credits", ACHIEVEMENTS[ACHIEVE_OBJMOVED][LEVEL_I]);
		                                Set_Player_Credit( client, PlayerCredit[client] + 15 );
		                                check_banker(client);
		                                EmitSoundToClientAny(client, ACH_SOUND );
		                                SaveData2(client);
		                        }
		                }      
		        }
				GetEntPropVector(g_Targetindex[client], Prop_Data, "m_angRotation", ANGLE);

				float targetloc[3], EyePos[3];
				GetClientEyePosition(client, EyePos);
				GetEntityOrigin(g_Targetindex[client], targetloc); 
				g_Distance[client] = GetVectorDistance(EyePos, targetloc);
				AcceptEntityInput(g_Targetindex[client], "EnableMotion");
				DispatchKeyValue(g_Targetindex[client], "solid", "0");
				GetEntityOrigin(g_Targetindex[client], targetlocstore);

				if( g_Targetindex[client] > 0 && g_Targetindex[client] <= MaxClients && IsClientInGame(g_Targetindex[client]))
				{
					PrintToChat(client, "Grabbed 2");
					g_MaxSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
					g_Grabbed[g_Targetindex[client]] = true; 
					SetEntPropFloat(g_Targetindex[client], Prop_Send, "m_flMaxspeed", 0.01); 
				}
				// Finish grabbing
				CreateTimer(0.05, Grabbing, client, TIMER_REPEAT); 
				return Plugin_Stop; 
			}
			else if(zbb_phase != 1 || g_EntClaim[g_Targetindex[client]] != client)
			{
				PrintToChat( client, " \x01You do not own this entity, \x04Claimed by: \x03%N", g_EntClaim[g_Targetindex[client]])
				return Plugin_Handled;	
			}
			
		}
	}
	else
	{
		Action_Drop(client);
		return Plugin_Stop; 
	}
	return Plugin_Continue;
}

public Action Grabbing(Handle timer, any client)
{
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_Status[client] && !g_Grabbed[client] /*&& IsValidEntity(g_Targetindex[client])*/)
	{
		if(g_Targetindex[client] > MaxClients || g_Targetindex[client] > 0  && g_Targetindex[client] <= MaxClients && IsClientInGame(g_Targetindex[client]) && IsPlayerAlive(g_Targetindex[client]))
		{
			// Init variables
			float clientloc[3], clientang[3], targetloc[3], velocity[3];
			GetClientEyePosition(client, clientloc);
			GetClientEyeAngles(client, clientang);
			GetEntityOrigin(g_Targetindex[client], targetloc);

			// Grab traceray
			TR_TraceRayFilter(clientloc, clientang, MASK_ALL, RayType_Infinite, TraceRayTryToHit); // Find where the player is aiming
			TR_GetEndPosition(velocity); // Get the end position of the trace ray

			// Calculate velocity vector
			SubtractVectors(velocity, clientloc, velocity);
			NormalizeVector(velocity, velocity);

			ScaleVector(velocity, g_Distance[client]);
			AddVectors(velocity, clientloc, velocity);
			SubtractVectors(velocity, targetloc, velocity);
			//ScaleVector(velocity, 5.0 * 3 / 5);
			ScaleVector(velocity, 15.0 );

			int roundedvelo[3]
			roundedvelo[0] = RoundToNearest(velocity[0])
			roundedvelo[1] = RoundToNearest(velocity[1])
			roundedvelo[2] = RoundToNearest(velocity[2])

			Math_MakeVector(float(roundedvelo[0]), float(roundedvelo[1]), float(roundedvelo[2]), velocity)
			//PrintToChat(client, "%.2f %.2f %.2f", velocity[0], velocity[1], velocity[2])
			//`doSnapping(client, g_Targetindex[client], velocity);

			// Move grab target
			TeleportEntity(g_Targetindex[client], NULL_VECTOR, ANGLE, velocity );

			if(g_Attracting[client])
			{
				g_Distance[client] += 5.0 * 10.0;
				g_Attracting[client] = false;
			}
			else if(g_Repelling[client])
			{
				g_Distance[client] -= 5.0 * 10.0;
				if(g_Distance[client] <= 100.0)
					g_Distance[client] = 100.0;

				g_Repelling[client] = false;
			}

			int color[4];
			if(g_Targetindex[client] <= MaxClients)
				targetloc[2] += 45;
			clientloc[2] -= 5;
			if( !colourRainbow[client] )
			{
				GetBeamColor(client, color);
			}
			else
			{
				color[0] = GetRandomInt(0, 255);
				color[1] = GetRandomInt(0, 255);
				color[2] = GetRandomInt(0, 255);
				color[3] = 255;
			}

			BeamEffect(clientloc, targetloc, 0.2, 1.0, 1.0, color, 0.0, 0);	
			//Entity_SetRenderColor(g_Targetindex[client], color[0], color[1], color[2], color[3])
		}
		else
		{
			Action_Drop(client);
			return Plugin_Stop; // Stop the timer
		}
	}
	else
	{
		Action_Drop(client);
		return Plugin_Stop; // Stop the timer
	}
	return Plugin_Continue;
}

public void Action_Drop(int client)
{
	if( IsClientInGame(client) && IsPlayerAlive(client) && g_Status[client] )
	{
		g_Status[client] = false; // Tell plugin the grabber has dropped his target
		if(g_Targetindex[client] > 0)
		{
			char Classname[32];
			Entity_GetClassName(g_Targetindex[client], Classname, sizeof(Classname))
			if( StrEqual(Classname, "brush_dummy", false) )
			{
				AcceptEntityInput(Dummy[g_Targetindex[client]], "ClearParent");
				RemoveEdict(g_Targetindex[client])
			}

			DispatchKeyValue(g_Targetindex[client], "solid", "6");
			SetEntProp(g_Targetindex[client], Prop_Send, "m_usSolidFlags",  152);
			SetEntProp(g_Targetindex[client], Prop_Send, "m_CollisionGroup", 8);
			AcceptEntityInput(g_Targetindex[client], "DisableMotion");
			for (int i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if (IsStuckInEnt(i, g_Targetindex[client]))
					{
						TeleportEntity( g_Targetindex[client], targetlocstore, NULL_VECTOR, NULL_VECTOR);
						PrintToChat( client, " \x02Please don't stick objects in other players");
						break;
					}
				}
			}
			if( g_Targetindex[client] > 0 && g_Targetindex[client] <= MaxClients && IsClientInGame(g_Targetindex[client]))
			{
				g_Grabbed[g_Targetindex[client]] = false; // Tell plugin the target is no longer being grabbed
				SetEntPropFloat(g_Targetindex[client], Prop_Send, "m_flMaxspeed", g_MaxSpeed[client]); // Set speed back to normal
			}
			g_Targetindex[client] = -1;
		}
	}
}

int SpawnParent(float fOrigin[3])
{
	int iEntity = CreateEntityByName("prop_physics_override"); 
	DispatchKeyValue(iEntity, "targetname", "prop");
	DispatchKeyValue(iEntity, "model", "models/props/gg_tibet/rock_straight_small01.mdl");
	DispatchKeyValue(iEntity, "solid", "0");
	//SetEntPropFloat(iEntity, Prop_Send,"m_flModelScale", 0.000001);
	SetEntityRenderMode(iEntity, RENDER_NONE);
	Entity_SetClassName(iEntity, "brush_dummy")

	Format(tname, 20, "target%d", iEntity);
	DispatchKeyValue(iEntity, "targetname", tname);

	if( DispatchSpawn(iEntity) ) 
	{
		TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR); 
		SetEntProp(iEntity, Prop_Send, "m_usSolidFlags",  0);
		SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 0);
		AcceptEntityInput(iEntity, "DisableMotion");
		return iEntity;
	}
	return -1;
}

public bool TraceRayGrabEnt(int entity, int mask)
{
	// Check if the beam hit an entity other than the grabber, and stop if it does
	if(entity > 0)
	{
		if(entity > MaxClients) 
			return true;
		/*if(entity <= MaxClients && !g_Status[entity][Grab] && !g_Grabbed[entity] && !g_TRIgnore[entity])
			return true;*/
	}
	return false;
}

public void GetBeamColor(int client, int color[4])
{

   	if(colourselected[client])
   	{
		color[0] = RED[client];
		color[1] = GREEN[client];
		color[2] = BLUE[client];
		color[3] = 255;
	}
	else
	{
		color[0] = 0;
		color[1] = 0;
		color[2] = 255;
		color[3] = 255;
    }
}

public void BeamEffect(float startvec[3], float endvec[3], float life, float width, float endwidth, int color[4], float amplitude, int speed)
{
	TE_SetupBeamPoints(startvec, endvec, precache_laser, 0, 0, 66, life, width, endwidth, 0, amplitude, color, speed);
	TE_SendToAll();
}

void KillAllTimers()
{
	if( gPhase_1_BuildTime != null )
	{
		KillTimer( gPhase_1_BuildTime )
		gPhase_1_BuildTime = null;
	}
	if( gPhase_1 != null )
	{
		KillTimer( gPhase_1 );
		gPhase_1 = null;
	}
	if( gPhase_2 != null )
	{
		KillTimer( gPhase_2 );
		gPhase_2 = null;
	}
	if( gPhase_3 != null )
	{
		KillTimer( gPhase_3 );
		gPhase_3 = null;
	}
	if( gPhase_3_CountdownPre != null )
	{
		KillTimer( gPhase_3_CountdownPre );
		gPhase_3_CountdownPre = null;
	}
	if( gPhase_3_Countdown != null )
	{
		KillTimer( gPhase_3_Countdown );
		gPhase_3_Countdown = null;
	}
}

public void OnClientCookiesCached(int client) 
{
    if (IsFakeClient(client))
        return;

    UpdatePreferencesOnCookies(client);
    PrintToServer(const String:format[], any:...)
}

public void UpdatePreferencesOnCookies(int client)
{
	g_remember_primary[client] = GetCookieInt(client, g_hPrimWepCookie);
	g_remember_secondary[client] = GetCookieInt(client, g_hSecWepCookie);
	g_remember_colour[client] = GetCookieInt(client, g_hColourCookie);

	RED[client] = g_ColorRED[g_remember_colour[client]]; //R
	BLUE[client] = g_ColorBLUE[g_remember_colour[client]]; //G
	GREEN[client] = g_ColorGREEN[g_remember_colour[client]]; //B
}

public int GetCookieInt(int client, Handle cookie) 
{
    char buffer[20];
    GetClientCookie(client, cookie, buffer, sizeof(buffer));
    return StringToInt(buffer);
}

public void SetCookieInt(any client, Handle cookie, any value) 
{
    char buffer[20];
    IntToString(value, buffer, sizeof(buffer));
    SetClientCookie(client, cookie, buffer);
}

stock int GetRatio()
{
	int counter;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i) )
		{
			if(	GetClientTeam(i) == TEAM_ZOMBIES )
				counter++
		}	
	}
	return RoundToFloor(float((GetConVarInt(zbb_ratio)+counter)/GetConVarInt(zbb_ratio)));
}