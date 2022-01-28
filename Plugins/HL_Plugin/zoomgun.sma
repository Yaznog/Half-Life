/*
 *  Comments: 
 *  	This plugin enables zooming of weapons.  They are grouped by catagory, so one variable changes all
 *		zoom distance of weapon catagory.  The plugin also allows setting a zoom delay, for zooming and
 * 		unzooming.  The default values are (prefered) values.  You may change as you please, or set your
 *		custom values in the server.cfg so they are defaulted every map.
 *
 *	Note:	I only included weapons without any zoom, and grouped them by catagory, for better balance.
 *			Also, do not set the zoom amount less than 0 or to 90, those are normal view, unless you do not
 			want that weapon catagory to have a zoom.One last thing, the lower the amount, the further the 
 			distance you can see, but be warned, too low gives you the sniper scope thing. 
 *				
 *	Commands:	
 * 		+zoom 		- zoom/unzoom the zoomable weapon. (confusing?)
 *
 *	CVARs:
 *		zoom_on 			(Default: 1) 	-activates/deactivates the plugin completely.
 *		zoom_delay			(Default: 0.4) 	-sets the delay for zooming/unzooming (must be decimal)
 *		zoom_pistol			(Default: 65) 	-sets zoom distance for pistols
 *		zoom_shotgun		(Default: 60) 	-sets zoom distance for shotguns
 *		zoom_submachinegun	(Default: 50) 	-sets zoom distance for submachine guns
 *		zoom_rifleone		(Default: 45) 	-sets zoom distance for Galil & Famas only
 *		zoom_rifletwo		(Default: 50) 	-sets zoom distance for AK47 & M4A1 only
 *		zoom_machinegun		(Default: 55) 	-sets zoom distance for PARA woot woot
 *		
 *
 *	Requires:	AMXX 1.01
 *
 *	Author:		OneEyed
 *	Date:		07-20-2005
 *	Email:		oneeyed@stx.rr.com
 *	irc:		#zT (gamesurge.net) 
 *
 * 	Tested :
 *	Win32 machine.  Linux UNTESTED (should work tho).
 * 
 */

#include <amxmodx>
#include <amxmisc>

new gmsgSetFov, foved[33], oldweap[33], lastinv[33]
//----------------------------------------------------------------------------------------
public plugin_init() {
	register_plugin("ZoomGuns", "1.0", "OneEyed")
	if(!cvar_exists("zoom_on"))
		register_cvar("zoom_on","1")
	if(!cvar_exists("zoom_delay"))
		register_cvar("zoom_delay","0.4")
	if(!cvar_exists("zoom_pistol"))
		register_cvar("zoom_pistol","65")
	if(!cvar_exists("zoom_shotgun"))
		register_cvar("zoom_shotgun","60")
	if(!cvar_exists("zoom_submachinegun"))
		register_cvar("zoom_submachinegun","50")
	if(!cvar_exists("zoom_rifleone"))
		register_cvar("zoom_rifleone","45")
	if(!cvar_exists("zoom_rifletwo"))
		register_cvar("zoom_rifletwo","50")
	if(!cvar_exists("zoom_machinegun"))
		register_cvar("zoom_machinegun","55")
		
	register_clcmd("+zoom","zoomIn")
	register_clcmd("-zoom","null")	//added this so console doesn't whine
	
	register_clcmd("say","handle_say") // Newbie help (credits to KRoTaL on this method)
	register_event("CurWeapon", "Switched", "be") 
	gmsgSetFov = get_user_msgid("SetFOV")
}
//----------------------------------------------------------------------------------------
public zoom_help(id) {
	client_print(id, print_chat, "If you want to use the zoom feature, ^n")
	client_print(id, print_chat, "Open your console and write: bind ^"key^" ^"+zoom^"")
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------
public handle_say(id) {
	new said[192]
	read_args(said,192)
	remove_quotes(said)
	if( (containi(said, "zoom") != -1) ) 
		zoom_help(id)
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------
public client_putinserver(id) foved[id] = 0
//----------------------------------------------------------------------------------------
public null(id) return PLUGIN_HANDLED/*..HAX..*/
//----------------------------------------------------------------------------------------
//Hack so they cant use the fov for getting crosshair on (sniper guns) when no scoped-----
public Switched(id) {
	if(!get_cvar_num("zoom_on"))
		return PLUGIN_HANDLED
		
	new weapon, clip, ammo
	weapon = get_user_weapon(id,clip,ammo)
	
	lastinv[id] = checkWeap(weapon)
	if(foved[id] && oldweap[id] != weapon) {
		new fovargs[2]
		fovargs[0] = id
		fovargs[1] = 0
		setFov(fovargs)
		if(lastinv[id]) {
			lastinv[id] = 0
			client_cmd(id,"lastinv")
			set_task(0.01,"lastInv",id)
		}
	}
	return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------
public lastInv(id) 
	client_cmd(id,"lastinv")
//End hack--------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------
public checkWeap(weap) {
	if(weap == CSW_AWP || weap == CSW_SCOUT || weap == CSW_SG550 || weap == CSW_G3SG1 )
		return 1
	return 0
}
//----------------------------------------------------------------------------------------
public zoomIn(id) {
	if(!get_cvar_num("zoom_on"))
		return PLUGIN_HANDLED

	new weapon, clip, ammo
	weapon = get_user_weapon(id,clip,ammo)

	if(foved[id] == 1 ) {
		makeFov(id,0)
		return PLUGIN_HANDLED
	}
	
	if(weapon == CSW_GLOCK18 || weapon == CSW_USP || weapon == CSW_P228 || weapon == CSW_DEAGLE || weapon == CSW_FIVESEVEN || weapon == CSW_ELITE)
		makeFov(id,get_cvar_num("zoom_pistol"))
	else if(weapon == CSW_M3 || weapon == CSW_XM1014)
		makeFov(id,get_cvar_num("zoom_shotgun"))
	else if(weapon == CSW_MP5NAVY || weapon == CSW_UMP45 || weapon == CSW_P90 || weapon == CSW_TMP || weapon == CSW_MAC10)
		makeFov(id,get_cvar_num("zoom_submachinegun"))
	else if(weapon == CSW_FAMAS || weapon == CSW_GALIL)
		makeFov(id,get_cvar_num("zoom_rifleone"))
	else if(weapon == CSW_AK47 || weapon == CSW_M4A1)
		makeFov(id,get_cvar_num("zoom_rifletwo"))
	else if(weapon == CSW_M249)
		makeFov(id,get_cvar_num("zoom_machinegun"))
	
	oldweap[id] = weapon
	return PLUGIN_HANDLED	
}
//----------------------------------------------------------------------------------------
public makeFov(id,amt) {
	new args[2]
	args[0] = id
	args[1] = amt
	if(get_cvar_float("zoom_delay") > 0.0)
		set_task(get_cvar_float("zoom_delay"),"setFov",4321,args,2)
	else
		setFov(args)
}
//----------------------------------------------------------------------------------------
public setFov(args[]) {
	new id = args[0], amt = args[1]
	message_begin(MSG_ONE,gmsgSetFov,{0,0,0},id)
	write_byte(amt)
	message_end()
	if(amt > 0 && amt != 90)
		foved[id] = 1
	else
		foved[id] = 0
}
//----------------------------------------------------------------------------------------