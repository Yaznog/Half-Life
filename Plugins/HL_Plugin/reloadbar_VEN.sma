/* AMX Mod X
*   Reload Status Bar
*
* (c) Copyright 2008 by VEN
*
* This file is provided as is (no warranties)
*
*	DESCRIPTION
*		Plugin draws dynamic status bar when player reloads his weapon.
*
*	CREDITS
*		Idea has been taken from "Reloadbar" plugin by "NL)Ramon(NL".
*
*	VERSIONS
*		0.1.1
*			- added: linux support
*			- some code improvements
*		0.1
*			- initial version
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

// plugin's main information
#define PLUGIN_NAME "Reload Status Bar"
#define PLUGIN_VERSION "0.1.1"
#define PLUGIN_AUTHOR "VEN"

#define OFFSET_PLAYER_LINUX_DIFFERENCE 5

#define OFFSET_PLAYER_NEXT_ATTACK_WIN32 83
#define /* Float: */ GetPlayerAttackDelay(%1) /* (iPlayer) */ get_pdata_float(%1, OFFSET_PLAYER_NEXT_ATTACK_WIN32, OFFSET_PLAYER_LINUX_DIFFERENCE)

#define OFFSET_WEAPON_LINUX_DIFFERENCE 4

#define OFFSET_WEAPON_CBASE_PLAYER_WIN32 41
#define GetWeaponPlayer(%1) /* (iEnt) */ get_pdata_cbase(%1, OFFSET_WEAPON_CBASE_PLAYER_WIN32, OFFSET_WEAPON_LINUX_DIFFERENCE)

#define OFFSET_WEAPON_IN_RELOAD_WIN32 54
#define /* bool: */ IsWeaponInReload(%1) /* (iEnt) */ !!get_pdata_int(%1, OFFSET_WEAPON_IN_RELOAD_WIN32, OFFSET_WEAPON_LINUX_DIFFERENCE)

#define WEAPONS_SHOTGUNS_NONGUNS ((1<<CSW_HEGRENADE) | (1<<CSW_XM1014) | (1<<CSW_C4) | (1<<CSW_SMOKEGRENADE) | (1<<CSW_M3) | (1<<CSW_FLASHBANG) | (1<<CSW_KNIFE))

enum weapon_list {
	WeaponList_Name = 1,
	WeaponList_AmmoId1,
	WeaponList_MaxAmmo1,
	WeaponList_AmmoId2,
	WeaponList_MaxAmmo2,
	WeaponList_Slot,
	WeaponList_Position,
	WeaponList_Id,
	WeaponList_Flags
}

new g_iFwIdRegUserMsgPost

new const g_szMsgNameWeaponList[] = "WeaponList"
stock const g_szMsgNameBarTime[] = "BarTime"

new g_iMsgIdWeaponList
new g_iMsgIdBarTime

#define MAX_CLIENTS 32

new Float:g_fPlayerReloadEndGameTime[MAX_CLIENTS + 1]

public plugin_precache() {
	g_iMsgIdWeaponList = get_user_msgid(g_szMsgNameWeaponList)
	if (!g_iMsgIdWeaponList)
		g_iFwIdRegUserMsgPost = register_forward(FM_RegUserMsg, "fwRegUserMsgPost", 1)
	else
		HookMsgWeaponList()
}

public fwRegUserMsgPost(const szMsgName[]) {
	if (!equal(szMsgName, g_szMsgNameWeaponList))
		return FMRES_IGNORED

	unregister_forward(FM_RegUserMsg, g_iFwIdRegUserMsgPost, 1)
	g_iMsgIdWeaponList = get_orig_retval()
	HookMsgWeaponList()

	return FMRES_HANDLED
}

HookMsgWeaponList() {
	register_message(g_iMsgIdWeaponList, "fwMsgWeaponList")
}

public fwMsgWeaponList() {
	static iHookedWeapons, iWeaponId, szWeaponName[32]
	iWeaponId = get_msg_arg_int(WeaponList_Id)
	if (iHookedWeapons & (1<<iWeaponId))
		return PLUGIN_CONTINUE

	get_msg_arg_string(WeaponList_Name, szWeaponName, sizeof szWeaponName - 1)

	static const szfwHamWeaponReloadPost[] = "fwHamWeaponReloadPost"
	if (!(WEAPONS_SHOTGUNS_NONGUNS & (1<<iWeaponId)))
		RegisterHam(Ham_Weapon_Reload, szWeaponName, szfwHamWeaponReloadPost, 1)

	static const szFwHamItemDeployPost[] = "fwHamItemDeployPost"
	RegisterHam(Ham_Item_Deploy, szWeaponName, szFwHamItemDeployPost, 1)

	iHookedWeapons |= (1<<iWeaponId)

	return PLUGIN_CONTINUE
}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	g_iMsgIdBarTime = get_user_msgid(g_szMsgNameBarTime)
}

public fwHamWeaponReloadPost(iEnt) {
	if (!IsWeaponInReload(iEnt))
		return HAM_IGNORED

	static iWeaponPlayer, Float:fAttackDelay
	iWeaponPlayer = GetWeaponPlayer(iEnt)
	fAttackDelay = GetPlayerAttackDelay(iWeaponPlayer)

	MsgBarTime(iWeaponPlayer, floatround(fAttackDelay))
	g_fPlayerReloadEndGameTime[iWeaponPlayer] = get_gametime() + fAttackDelay

	return HAM_HANDLED
}

public fwHamItemDeployPost(iEnt) {
	static iWeaponPlayer
	iWeaponPlayer = GetWeaponPlayer(iEnt)

	if (g_fPlayerReloadEndGameTime[iWeaponPlayer] < get_gametime())
		return HAM_IGNORED

	MsgBarTime(iWeaponPlayer, 0)
	g_fPlayerReloadEndGameTime[iWeaponPlayer] = 0.0

	return HAM_HANDLED
}

stock MsgBarTime(iPlayer, iBarScale) {
	message_begin(MSG_ONE, g_iMsgIdBarTime, _, iPlayer)
	write_short(iBarScale)
	message_end()
}
