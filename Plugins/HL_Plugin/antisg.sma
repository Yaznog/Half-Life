#include <amxmodx>
#include <hamsandwich>
#include <engine>

#define PLUGIN     "Anti_Self-Gauss"
#define VERSION "1.0"
#define AUTHOR "Flipper_SPb"

new allow, messg
new  e_class[64]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("antisg_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	allow = register_cvar("antisg_on", "0")  // plugin on/off
	messg = register_cvar("antisg_msg", "0") // self-gauss message
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(attacker != victim || !(1 <= attacker <= 32) || !get_pcvar_num(allow))
		return HAM_IGNORED

	entity_get_string(inflictor, EV_SZ_classname, e_class, 63)
    
	if (attacker == inflictor || equal(e_class, "weapon_gauss"))
	{
		if(damage > 1 && get_pcvar_num(messg))
			client_print(attacker, print_chat, "* You got the self-gauss with power: %d", floatround(damage))
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
