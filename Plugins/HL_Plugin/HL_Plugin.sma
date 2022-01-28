#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <engine>
//#include <fakemeta_util>


#define PLUGIN "HL_Plugin"
#define VERSION "1.0"
#define AUTHOR "Yaznog"

#define MAX_SPEED 250
#define NEW_MAX_SPEED 375

#define LONGJUMP_SOUND 1

#define CROWBAR_SPEED_BONUS 0.5

#define BAR_SIZE 2

#define HLW_SHOTGUN 7

#define CROWVAR_DAMAGE_MULTIPLIER 1.0
#define PISTOL_DAMAGE_MULTIPLIER 1.0
#define MAGNUM_DAMAGE_MULTIPLIER 1.0
#define SUBMACHINEGUN_DAMAGE_MULTIPLIER 1.0
#define SHOTGUN_DAMAGE_MULTIPLIER 1.0
#define CROSSBOW_DAMAGE_MULTIPLIER 1.0
#define ROCKETPROPELLED_DAMAGE_MULTIPLIER 1.0
#define TAUCANNON_DAMAGE_MULTIPLIER 1.0
#define GLUONGUN_DAMAGE_MULTIPLIER 0.8
#define HORNETGUN_DAMAGE_MULTIPLIER 1.0
#define GRENADE_DAMAGE_MULTIPLIER 1.0
#define TRIPMINE_DAMAGE_MULTIPLIER 1.0
#define SATCHELCHARGE_DAMAGE_MULTIPLIER 1.0
#define SNARK_DAMAGE_MULTIPLIER 1.0

#define MAX_SOUNDS	50
#define MAX_p_MODELS	50
#define MAX_v_MODELS	50
#define MAX_w_MODELS	50

#define MAP_CONFIGS	1

new new_sounds[MAX_SOUNDS][48]
new old_sounds[MAX_SOUNDS][48]
new sounds_team[MAX_SOUNDS]
new soundsnum

new new_p_models[MAX_p_MODELS][48]
new old_p_models[MAX_p_MODELS][48]
new p_models_team[MAX_p_MODELS]
new p_modelsnum

new new_v_models[MAX_v_MODELS][48]
new old_v_models[MAX_v_MODELS][48]
new v_models_team[MAX_p_MODELS]
new v_modelsnum

new new_w_models[MAX_w_MODELS][48]
new old_w_models[MAX_w_MODELS][48]
new w_models_team[MAX_p_MODELS]
new w_modelsnum

new gBar[ ] = "####################################################################################################"
new gMaxHealth[ 33 ]
new gMaxBattery[ 33 ]

new jumpnum[33] = 0
new bool:dojump[33] = false
new bool:mPlayerLongJump[33] = false

new Float:mCrowbarSpeedBonus

new mWeaponBaseDamage[14]={25, 12, 40, 12, 5, 20, 100, 20, 14, 10, 100, 150, 150, 10}
new Float:mTotalDamageDealt[33]={0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};

//--------------------------------------------------------------------------------------------------
// Plugin init/precache/load

public plugin_init( ) 
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_event("Health", "eHealth", "be");
	register_event("Battery", "eBattery", "be" );
	register_event("ItemPickup", "eItemPickup", "be");
	register_event("CurWeapon","eCurWeapon","be","1=1");   
	
	RegisterHam(Ham_Killed, "player", "client_death", 1);
	RegisterHam(Ham_Spawn, "player", "client_spawn", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	
	register_forward(FM_EmitSound,"Sound_Hook");
	register_forward(FM_SetModel,"W_Model_Hook",1);
		
	register_cvar("amx_maxjumps","1");
	
	register_clcmd("say pluginMenu","cmd_menu");
}

public plugin_precache()
{
	precache_sound("HL_Plugin_Sounds/longJump.wav")
	
	new configfile[200]
	new configsdir[200]
	new map[32]
	get_configsdir(configsdir,199)
	get_mapname(map,31)
	format(configfile,199,"%s/new_weapons_%s.ini",configsdir,map)
	if(file_exists(configfile))
	{
		load_models(configfile)
	}
	else
	{
		format(configfile,199,"%s/new_weapons.ini",configsdir)
		load_models(configfile)
	}
	
	return PLUGIN_CONTINUE
}


public load_models(configfile[])
{
	if(file_exists(configfile))
	{
		new read[96], left[48], right[48], trash, team
		for(new i=0;i<file_size(configfile,1);i++)
		{
			read_file(configfile,i,read,95,trash)
			if(containi(read,";")!=0 && containi(read," ")!=-1)
			{
				strbreak(read,left,47,right,47)
				replace_all(right,47,"^"","")
				if(file_exists(right))
				{
					if(containi(right,".mdl")==strlen(right)-4)
					{
						if(!precache_model(right))
						{
							log_amx("Error attempting to precache model: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
						}
						else if(containi(left,"models/p_")==0)
						{
							format(new_p_models[p_modelsnum],47,right)
							format(old_p_models[p_modelsnum],47,left)
							p_models_team[p_modelsnum]=team
							p_modelsnum++
						}
						else if(containi(left,"models/v_")==0)
						{
							format(new_v_models[v_modelsnum],47,right)
							format(old_v_models[v_modelsnum],47,left)
							v_models_team[v_modelsnum]=team
							v_modelsnum++
						}
						else if(containi(left,"models/w_")==0)
						{
							format(new_w_models[w_modelsnum],47,right)
							format(old_w_models[w_modelsnum],47,left)
							w_models_team[w_modelsnum]=team
							w_modelsnum++
						}
						else
						{
							log_amx("Model type(p_ / v_ / w_) unknown for model: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
						}
					}
					else if(containi(right,".wav")==strlen(right)-4 || containi(right,".mp3")==strlen(right)-4)
					{
						replace(right,47,"sound/","")
						replace(left,47,"sound/","")
						if(!precache_sound(right))
						{
							log_amx("Error attempting to precache sound: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
						}
						else
						{
							format(new_sounds[soundsnum],47,right)
							format(old_sounds[soundsnum],47,left)
							sounds_team[soundsnum]=team
							soundsnum++
						}
					}
					else
					{
						log_amx("Invalid File: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
					}
				}
				else
				{
					log_amx("File Inexistent: ^"%s^" (Line %d of new_weapons.ini)",right,i+1)
				}
				/*if(!file_exists(left))
				{
					log_amx("Warning: File Inexistent: ^"%s^" (Line %d of new_weapons.ini). ONLY A WARNING. PLUGIN WILL STILL WORK!!!!",left,i+1)
				}*/
			}
		}
	}
}

//--------------------------------------------------------------------------------------------------
// Client connect/disconnect

public client_putinserver(id)
{
	gMaxBattery[id] = 100
	mCrowbarSpeedBonus = 1.0 + CROWBAR_SPEED_BONUS
	set_cvar_num("sv_maxspeed", NEW_MAX_SPEED)
	set_task(1.0, "show_connection_message", id, "", 0, "a", 1);
	jumpnum[id] = 0
	dojump[id] = false
	mPlayerLongJump[id] = false
	mTotalDamageDealt[id] = 0.0
}

public client_disconnect(id)
{
	jumpnum[id] = 0
	dojump[id] = false
	mPlayerLongJump[id] = false
	mTotalDamageDealt[id] = 0.0
}

//--------------------------------------------------------------------------------------------------
// Client death/spawn

public client_death(id)
{
	if(!is_user_alive(id)) 
	{
		mPlayerLongJump[id] = false;
		mTotalDamageDealt[id] = 0.0
	}
	return HAM_IGNORED;
}

public client_spawn(id)
{
	if(is_user_alive(id))
	{
		gMaxHealth[ id ] = get_user_health(id);
		show_bar_health(id, 100);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

//--------------------------------------------------------------------------------------------------
// Change sounds/models

public Sound_Hook(id,channel,sample[])
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	if(channel!=CHAN_WEAPON && channel!=CHAN_ITEM) return FMRES_IGNORED

	static i

	for(i=0;i<soundsnum;i++)
	{
		if(equali(sample,old_sounds[i]))
		{
			engfunc(EngFunc_EmitSound,id,CHAN_WEAPON,new_sounds[i],1.0,ATTN_NORM,0,PITCH_NORM)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public W_Model_Hook(ent,model[])
{
	if(!pev_valid(ent)) return FMRES_IGNORED
	
	static i
	for(i=0;i<w_modelsnum;i++)
	{
		if(equali(model,old_w_models[i]))
		{
			engfunc(EngFunc_SetModel,ent,new_w_models[i])
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

//--------------------------------------------------------------------------------------------------
// Client preThink/postThink

public client_PreThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP) && mPlayerLongJump[id])
	{
		if(jumpnum[id] < get_cvar_num("amx_maxjumps"))
		{
			dojump[id] = true
			jumpnum[id]++
			return PLUGIN_CONTINUE
		}
	}
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if(dojump[id] == true)
	{
		playSound(id, LONGJUMP_SOUND)
		new Float:velocity[3]	
		entity_get_vector(id,EV_VEC_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,velocity)
		dojump[id] = false
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}	

//--------------------------------------------------------------------------------------------------
// Events reactions
	
public eHealth( id )
{
	static health, max_health; 
	health = read_data( 1 );
	max_health = gMaxHealth[ id ];
	if( health > max_health ) gMaxHealth[ id ] = max_health = health;
	show_bar_health( id, health * 100 / max_health );
}

public eBattery( id )
{
	static battery, max_battery; 
	battery = read_data( 1 );
	max_battery = gMaxBattery[ id ];
	if( battery > max_battery ) gMaxBattery[ id ] = max_battery = battery;
	show_bar_battery( id, battery * 100 / max_battery );
}

public eCurWeapon(id)
{	
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if(get_user_weapon(id) == get_weaponid("weapon_crowbar")) set_user_maxspeed(id, float(MAX_SPEED) * mCrowbarSpeedBonus);
	else set_user_maxspeed(id, float(MAX_SPEED));
	
	static model[32], i

	pev(id,pev_viewmodel2,model,31)
	for(i=0;i<v_modelsnum;i++)
	{
		if(equali(model,old_v_models[i]))
		{
			set_pev(id,pev_viewmodel2,new_v_models[i])
			break;
		}
	}

	pev(id,pev_weaponmodel2,model,31)
	for(i=0;i<p_modelsnum;i++)
	{
		if(equali(model,old_p_models[i]))
		{
			set_pev(id,pev_weaponmodel2,new_p_models[i])
			break;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public eItemPickup(id)
{
	if(read_data(1) == get_weaponid("item_longjump")) mPlayerLongJump[id] = true;
}

public TakeDamage(Victim, Inflictor, Attacker, Float:Damage)
{
	mTotalDamageDealt[Attacker] += Damage
	if(!Attacker) return HAM_IGNORED
	
	new weaponID = get_user_weapon(Attacker)
	
	if(weaponID == 		get_weaponid("weapon_crowbar")) 	SetHamParamFloat(4, Damage * CROWVAR_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_9mmhandgun")) 	SetHamParamFloat(4, Damage * PISTOL_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_357")) 		SetHamParamFloat(4, Damage * MAGNUM_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_9mmAR")) 		SetHamParamFloat(4, Damage * SUBMACHINEGUN_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_shotgun")) 	SetHamParamFloat(4, Damage * SHOTGUN_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_crossbow")) 	SetHamParamFloat(4, Damage * CROSSBOW_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_rpg")) 		SetHamParamFloat(4, Damage * ROCKETPROPELLED_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_gauss")) 		SetHamParamFloat(4, Damage * TAUCANNON_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_egon")) 		SetHamParamFloat(4, Damage * GLUONGUN_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_hornetgun")) 	SetHamParamFloat(4, Damage * HORNETGUN_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_handgrenade")) 	SetHamParamFloat(4, Damage * GRENADE_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_tripmine")) 	SetHamParamFloat(4, Damage * TRIPMINE_DAMAGE_MULTIPLIER)
	else if(weaponID == 	get_weaponid("weapon_satchel")) 	SetHamParamFloat(4, Damage * SATCHELCHARGE_DAMAGE_MULTIPLIER)
	else return HAM_IGNORED
		
	return HAM_HANDLED;
	
}

//--------------------------------------------------------------------------------------------------
// Basics functions

stock Float:get_current_speed(id) 
{
	static Float:vel[3]
	pev(id,pev_velocity, vel)
	return vector_length(vel)
}

stock Float:get_current_ping(id)
{ 
	new ping, loss
	get_user_ping(id, ping, loss)
	return float(ping)
}

stock Float:get_current_loss(id)
{
	new ping, loss
	get_user_ping(id, ping, loss)
	return float(loss)
}

public playSound(id, soundName)
{
	switch(soundName)
	{
		case LONGJUMP_SOUND:
		{
			client_cmd(0, "spk HL_Plugin_Sounds/doubleJump.wav")
		}
	}
}


//--------------------------------------------------------------------------------------------------
// HUD messages

public show_bar_health( id, health_percent )
{
	set_hudmessage( 255 - health_percent * 2, health_percent * 2, 0, 0.01, 0.935, 0, 6.0, 999.9, 0.0, 0.0, 4 )
	show_hudmessage(id, "%s", gBar[ min( 99, 100 - health_percent / BAR_SIZE ) ] )
}

public show_bar_battery( id, battery_percent )
{
	set_hudmessage( 255 - battery_percent * 2, battery_percent * 2, 0, 0.01, 0.92, 0, 6.0, 999.9, 0.0, 0.0, 3 )
	show_hudmessage(id, "%s", gBar[ min( 99, 100 - battery_percent / BAR_SIZE ) ] )
}

public show_bar_tools(id)
{
	set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 0.0, 2.0, 0.0, 0.0, 1)
	show_hudmessage(id, "Speed: %.2f px/s   ^nPing: %.2f ^nLoss: %.2f", get_current_speed(id), get_current_ping(id), get_current_loss(id))
}

public show_bar_ping(id)
{
	set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 0.0, 2.0, 0.0, 0.0, 1)
	show_hudmessage(id, "Ping: %.2f", get_current_ping(id))
}

public show_connection_message(id)
{
	set_hudmessage( 255, 255, 255, 0.01, 0.85, 0, 6.0, 20.0, 0.0, 0.0, 3 )
	show_hudmessage(id, "Type ^"say pluginMenu^" in console to display the settings menu")
	
}

public show_weapons_damages_message(id)
{
	set_hudmessage( 255, 255, 255, 0.01, 0.1, 0, 15.0, 20.0, 0.0, 0.0, 3 )
	show_hudmessage(id, "Crowbar: %.2f ^n9mm Pistol: %.2f ^n357 Magnum: %.2f ^nSubmachine Gun: %.2f or 100.00^nShotgun: %.2f * 4 or * 8^nCrossbow: %.2f + 40.00 or 120.0^nRocket-Propelled: %.2f ^nTau Cannon: or 25.00 up to 200.0%.2f ^nGluon Gun: %.2f ^nHornet Gun: %.2f ^nFragmentation Grenade: %.2f ^nLaser Trip Mine: %.2f ^nSatchel Charge: %.2f ^nSnark: %.2f or 5.00",
	float(mWeaponBaseDamage[0]), 	float(mWeaponBaseDamage[1]), 	float(mWeaponBaseDamage[2]), 
	float(mWeaponBaseDamage[3]), 	float(mWeaponBaseDamage[4]), 	float(mWeaponBaseDamage[5]), 
	float(mWeaponBaseDamage[6]), 	float(mWeaponBaseDamage[7]), 	float(mWeaponBaseDamage[8]), 
	float(mWeaponBaseDamage[9]), 	float(mWeaponBaseDamage[10]), 	float(mWeaponBaseDamage[11]), 
	float(mWeaponBaseDamage[12]), 	float(mWeaponBaseDamage[13]))
	/*
	float(mWeaponBaseDamage[0]*CROWVAR_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[1]*PISTOL_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[2]*MAGNUM_DAMAGE_MULTIPLIER), 
	float(mWeaponBaseDamage[3]*SUBMACHINEGUN_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[4]*SHOTGUN_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[5]*CROSSBOW_DAMAGE_MULTIPLIER), 
	float(mWeaponBaseDamage[6]*ROCKETPROPELLED_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[7]*TAUCANNON_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[8]*GLUONGUN_DAMAGE_MULTIPLIER), 
	float(mWeaponBaseDamage[9]*HORNETGUN_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[10]*GRENADE_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[11]*TRIPMINE_DAMAGE_MULTIPLIER), 
	float(mWeaponBaseDamage[12]*SATCHELCHARGE_DAMAGE_MULTIPLIER), float(mWeaponBaseDamage[13]*SNARK_DAMAGE_MULTIPLIER))
	*/
}

public show_bar_damage(id)
{
	new bool:player[33]

	for(new i=0;i<33;i++)
	{
		if(is_user_connected(i)) player[i] = true 
		else player[i] = false
	}
	set_hudmessage( 255, 255, 255, 0.93, 0.18, 0, 2.0, 20.0, 0.0, 0.0, 4 )
	show_hudmessage(id, "Player 1: %.2f ^nPlayer 2: %.2f ^nPlayer 3: %.2f", mTotalDamageDealt[1], mTotalDamageDealt[2], mTotalDamageDealt[3])
}

//--------------------------------------------------------------------------------------------------
// Menus

public cmd_menu(id)
{
	new menu = menu_create("HL_Plugin menu", "menuSettings")
	
	menu_additem(menu, "Display tools", "1", 0)
	menu_additem(menu, "Display ping", "2", 0)
	menu_additem(menu, "Hide tools", "3", 0)
	menu_additem(menu, "Show weapons damages", "4", 0)
	menu_additem(menu, "Display players damages", "5", 0)
    
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public menuSettings(id, menu, item)
{
	new data[6], iName[64], access, callback
    
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback) 
    
	new key = str_to_num(data)
	
	switch(key)
	{
		case 1:
		{
			set_task(0.25, "show_bar_tools"	, id, "", 0, "b");
		}
		case 2:
		{
			set_task(0.25, "show_bar_ping"	, id, "", 0, "b");
		}
		case 3:
		{
			remove_task(id);
		}
		case 4:
		{
			show_weapons_damages_message(id)
		}
		case 5:
		{
			set_task(1.0, "show_bar_damage"	, id, "", 0, "b");
		}
		case 6:
		{
			
		}
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED_MAIN
}

//--------------------------------------------------------------------------------------------------
// Archives
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
