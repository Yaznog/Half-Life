#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#define PLUGIN "Extra Items Menu"
#define VERSION "1.0"
#define AUTHOR "DragonTail"

new cvar_health, cvar_armor, cvar_speed, cvar_gravity, cvar_invisible, user_foot[33], user_invi[33]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "fwdPlayerSpawn", 1)
	register_event("DeathMsg", "event_deathmsg", "a")
}

public plugin_cfg()
{
	cvar_health =			register_cvar("eim_health", "50")			// Колко допълнителна кръв да дава.
	cvar_armor =			register_cvar("eim_armor", "100")			// Колко допълнителна броня да дава.
	cvar_speed = 			register_cvar("eim_speed", "350.0")			// Колко да бъде скоростта.
	cvar_gravity =			register_cvar("eim_gravity", "0.5")			// Колко да бъде гравитацията.
	cvar_invisible =		register_cvar("eim_invisible", "80")			// Невидимост на играча. (0 max invis)
}

public fwdPlayerSpawn(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	
	user_invi[id] = false
	user_foot[id] = false
	if(is_user_alive(id) && !user_invi[id])
	{
		set_user_rendering(id)
	}
	if(is_user_alive(id) && !user_foot[id])
	{
		set_user_footsteps(id, 0)
	}
	
	if(is_user_alive(id))
	{
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
		
		cmd_menu(id);
		set_hudmessage(255, 0, 0, -1.0, 0.10, 0, 5.0, 5.0, 0.1, 0.2, -1)
		show_hudmessage(id, "Select your item!")
		
	}
	return PLUGIN_HANDLED
}

public cmd_menu(id)
{
	new menu = menu_create("\rExtra Items menu \dv1.0^n\ySelect your item:", "settings")
	
	menu_additem(menu, "\wExtra HP + AP", "1", 0)
	menu_additem(menu, "\wAll Grenades", "2", 0)
	menu_additem(menu, "\wFaster Speed", "3", 0)
	menu_additem(menu, "\wLow Gravity", "4", 0)
	menu_additem(menu, "\wNo Footsteps", "5", 0)
	menu_additem(menu, "\wInvisibility", "6", 0)
    
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public settings(id, menu, item)
{
	new data[6], iName[64], access, callback
    
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback) 
    
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			set_user_health(id, get_user_health(id) +get_pcvar_num(cvar_health))
			set_user_armor(id, get_user_armor(id) +get_pcvar_num(cvar_armor))
			
			set_hudmessage(200, 200, 200, -1.0, 0.25, 0, 5.0, 5.0, 0.1, 0.2, -1)
			show_hudmessage(id, "Your HP and AP is increased!")
			
		}
		case 2:
		{
			give_item(id, "weapon_hegrenade")
			
			give_item(id, "weapon_flashbang")
			
			give_item(id, "weapon_smokegrenade")
			
			set_hudmessage(0, 191, 255, -1.0, 0.25, 0, 5.0, 5.0, 0.1, 0.2, -1)
			show_hudmessage(id, "You received Full Grenade pack!")
		}
		case 3:
		{
			set_user_maxspeed(id, get_pcvar_float(cvar_speed))
			
			set_hudmessage(0, 0, 255, -1.0, 0.25, 0, 5.0, 5.0, 0.1, 0.2, -1)
			show_hudmessage(id, "Your speed is increased!")
		}
		case 4:
		{
			set_user_gravity(id, get_pcvar_float(cvar_gravity))
			
			set_hudmessage(165, 42, 42, -1.0, 0.25, 0, 5.0, 5.0, 0.1, 0.2, -1)
			show_hudmessage(id, "Your gravity is lower!")
		}
		case 5:
		{
			user_foot[id] = true
			set_user_footsteps(id, 1)
			
			set_hudmessage(160, 32, 240, -1.0, 0.25, 0, 5.0, 5.0, 0.1, 0.2, -1)
			show_hudmessage(id, "Your footsteps are silent!")
		}
		case 6:
		{
			user_invi[id] = true
			set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, get_pcvar_num(cvar_invisible))
			
			set_hudmessage(0, 0, 205, -1.0, 0.25, 0, 5.0, 5.0, 0.1, 0.2, -1)
			show_hudmessage(id, "You are invisible now!")
		}
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED_MAIN
}
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1026\\ f0\\ fs16 \n\\ par }
*/
