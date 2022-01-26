/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 01-05-08
*
*  ============
*   Changelog:
*  ============
*
*  v2.0
*    -Optimized Code
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.0"

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new pcvar
new Float:speed[33]

public plugin_init()
{
	register_plugin("Variable Speed Adjuster",VERSION,"GHW_Chronic")
	register_event("CurWeapon","cur_weap","be","1=1")
	pcvar = register_cvar("variable_speed","1.0")
	register_logevent("new_round",2,"1=Round_Start")
	set_cvar_num("sv_maxspeed",999999)
}

public new_round()
{
	set_cvar_num("sv_maxspeed",999999)
	new players[32], num
	get_players(players,num,"ah")
	for(new i=0;i<num;i++) set_task(0.2,"cur_weap",players[i])
}

public cur_weap(id)
{
	new Float:maxspeed
	pev(id,pev_maxspeed,maxspeed)

	if(maxspeed!=1.0 && speed[id]!=maxspeed)
	{
		speed[id] = maxspeed * get_pcvar_num(pcvar)
		set_pev(id,pev_maxspeed,speed[id])
		if(speed[id]>400) client_cmd(id,"cl_forwardspeed %f;cl_backspeed %f;cl_sidespeed %f",speed[id],speed[id],speed[id])
		else client_cmd(id,"cl_forwardspeed 400;cl_backspeed 400;cl_sidespeed 400")
	}
}
