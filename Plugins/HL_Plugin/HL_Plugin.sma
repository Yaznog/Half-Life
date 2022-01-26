#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <engine>

#define PLUGIN "HL_Plugin"
#define VERSION "1.0"
#define AUTHOR "Yaznog"

#define MAX_SPEED 250
#define NEW_MAX_SPEED 375

#define LONGJUMP_SOUND 1

#define CROWBAR_SPEED_BONUS 50

#define BAR_SIZE 2

new gBar[ ] = "####################################################################################################";
new gMaxHealth[ 33 ];
new gMaxBattery[ 33 ];

new jumpnum[33] = 0
new bool:dojump[33] = false
new bool:mPlayerLongJump = false

new mCrowbarSpeedBonus, mMaxSpeed, g_speed_value;

//--------------------------------------------------------------------------------------------------
// Plugin init/precache

public plugin_init( ) 
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_event( "Health", "eHealth", "be" );
	register_event( "Battery", "eBattery", "be" );
	register_event( "ItemPickup", "eItemPickup", "be" );
	
	RegisterHam( Ham_Killed, "player", "client_death", 1 );
	RegisterHam( Ham_Spawn, "player", "client_spawn", 1 );
		
	g_speed_value = register_cvar("amx_speedvalue", "NEW_MAX_SPEED")
	register_event("CurWeapon","eCurWeapon","be","1=1");    
	
	register_cvar("amx_maxjumps","1")
	
	register_clcmd("say pluginMenu","cmd_menu");
}

public plugin_precache()
{
	precache_sound("misc/longJump.wav")
	
	return PLUGIN_CONTINUE
}

//--------------------------------------------------------------------------------------------------
// Client connect/disconnect

public client_putinserver(id)
{
	
	//set_task(0.1, "update_bar_tools", id, "", 0, "b");
	gMaxBattery[id] = 100
	mCrowbarSpeedBonus = 1.0 + float(CROWBAR_SPEED_BONUS)/100.0
	set_cvar_num("sv_maxspeed", NEW_MAX_SPEED)
	set_task(5.0, "show_connection_message", id, "", 0, "a", 1);
	jumpnum[id] = 0
	dojump[id] = false
	mPlayerLongJump = false
}

public client_disconnect(id)
{
	jumpnum[id] = 0
	dojump[id] = false
	mPlayerLongJump = false
}

//--------------------------------------------------------------------------------------------------
// Client death/spawn

public client_death(id)
{
	if(!is_user_alive(id)) 
	{
		mPlayerLongJump = false;
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
// Client preThink/postThink

public client_PreThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP) && mPlayerLongJump)
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
	
	if(get_user_weapon(id) == get_weaponid("weapon_crowbar")) set_user_maxspeed(id, float(MAX_SPEED) * mCrowbarSpeedBonus);
	else set_user_maxspeed(id, float(MAX_SPEED));
	
	return PLUGIN_CONTINUE;
}

public eItemPickup(id)
{
	if(read_data(1) == get_weaponid("item_longjump")) mPlayerLongJump = true;
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
			client_cmd(0, "spk misc/doubleJump.wav")
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

public show_connection_message(id)
{
	set_hudmessage( 255, 255, 255, 0.01, 0.85, 0, 6.0, 10.0, 0.0, 0.0, 3 )
	show_hudmessage(id, "Type ^"say pluginMenu^" in console to display the settings menu")
	
}

//--------------------------------------------------------------------------------------------------
// Menus

public cmd_menu(id)
{
	new menu = menu_create("HL_Plugin menu", "menuSettings")
	
	menu_additem(menu, "Display tools", "1", 0)
	menu_additem(menu, "Hide tools", "2", 0)
    
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
			remove_task(id);
		}
		case 3:
		{
			
		}
		case 4:
		{
			
		}
		case 5:
		{
			
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


/*
new mBarToolsCounterLength = 10
new mBarToolsCounter = 0

new mLastSpeed = 0.0, mLastPing = 0.0, mLastLoss = 0.0

new Float:mLatestSpeed[10] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0}
new Float:mLatestPing[10] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0}
new Float:mLatestLoss[10] = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0}*/



/*
public update_bar_tools(id)
{
	
	mLatestSpeed[mBarToolsCounter] = get_current_speed(id)
	mLatestPing[mBarToolsCounter] = get_current_ping(id)
	mLatestLoss[mBarToolsCounter] = get_current_loss(id)
	mBarToolsCounter++
	if(mBarToolsCounter >= mBarToolsCounterLength) mBarToolsCounter = 0
}*/

/*
public Float:get_average_speed(id)
{
	new speed = get_current_speed(id)
	mLastSpeed = mLastSpeed * 0.9 + speed * 0.1
	
	return float(mLastSpeed)
}

public Float:get_average_ping(id)
{
	new ping = get_current_ping(id)
	mLastPing = mLastPing * 0.9 + ping * 0.1
	
	return float(mLastPing)
}

public Float:get_average_loss(id)
{
	new loss = get_current_loss(id)
	mLastLoss = mLastLoss * 0.9 + loss * 0.1
	
	return float(mLastLoss)
}*/
/*
public Float:get_average_speed(id)
{
	new averageSpeed = 0.0
	new count
	for(count = 0; count < mBarToolsCounterLength; count++)
	{
		averageSpeed = averageSpeed + mLatestSpeed[count]
	}

	averageSpeed = averageSpeed / float(mBarToolsCounterLength)
	
	return float(averageSpeed)
}

public Float:get_average_ping(id)
{
	new averagePing = 0.0
	new count
	for(count = 0; count < mBarToolsCounterLength; count++)
	{
		averagePing = averagePing + mLatestPing[count]
	}

	averagePing = averagePing / float(mBarToolsCounterLength)
	
	return float(averagePing)
}

public Float:get_average_loss(id)
{
	new averageLoss = 0.0
	new count
	for(count = 0; count < mBarToolsCounterLength; count++)
	{
		averageLoss = averageLoss + mLatestLoss[count]
	}

	averageLoss = averageLoss / float(mBarToolsCounterLength)
	
	return float(averageLoss)
}*/
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
