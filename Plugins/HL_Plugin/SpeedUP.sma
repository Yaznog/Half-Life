/**********************************************************************************
* Author: regalis (regalis1@gmx.de)
*
*	Version: 1.1
*
*	Description:
* 	-SpeedUP is a plugin that changes the movement speed for your players.
*	 	-There can be any Speedvalue between 0 and 2000!
*		-It emulates stop emitting the footstep sound while walking.(which is normaly done by the HL-engine)
*		 That means you can sneak around corners despite the amazing speed ;)
*		-There is a Digital speed-meter on top of the screen which shows the current speed in px/s (pixel/second)
*		-Now i have added an special effect: 
*				You can choose between "fire" or "smoke" which will follow you while running at highspeed
*
*
*	Requirements:
*		-Fun-Modul
*		-Fakemeta-Modul
*
*
*	Admin-Commands:
*		-amx_speedup_toggle - Toggles SpeedUP ON|OFF
*		-amx_speedup_value <speed> - Changes the Speed for the players. (Values are available from 0 to 2000)
*		-amx_speedup_bar	- Toggles the appearance of the SpeedUP-Bar on the top of the screen ON|OFF
*		-amx_speedup_trail - Toggles the SpeedUP-Trail ON|OFF
*		-amx_speedup_sprite - Toggles the SpeedUP-Trail-Sprite between FIRE|SMOKE
*
*
*
* CVARS:
*		-amx_speedup 0|1 (Default: 1) 
*		-amx_speedvalue 0 - 2000 (Default: 250)
*			 		"0" means no movement.
*					"250" is standard speed. ("500" is a good amount to be able to play at)
*		-amx_speedbar 0|1 (Default: 1)
*		-amx_speedtrail 0|1 (Default: 1)
*		-amx_speedsprite 0|1 (Default: 1)
*
*
*	Changelog:
*		V0.1
*			!Changed "for(new i=1;i<=get_maxplayers();i++)" to "get_players"
*			!Changed "set_cvar_num" to "set_pcvar_num"
*			+Added weapon based variation of speed (awp is slower than knife)
*			+Rewritten hole code because some strange behavior
*		
*		V0.2
*			!Fixed a Bug checking if switched weapon is active
*			!Fixed the Bug where sometimes at roundstart the speed wasn't set before weaponswitch
*
*		V0.3
*			!Fixed various problems encountered by VEN
*			!Fixed a bug that when a round_starts sometimes the players had default speed instead of the speedvalue
*
*		V0.4
*			+Added a routine which checks if the player is walking (+speed) or running and emits the footprintsound or not	
*			+Added Plugin-Version as CVAR
*
*		V0.5
*			+Added a Speed-Bar which displays the current speed to the player (cvar and admincommand for this feature is also implemented)
*
*		V0.6
*			!Fixed some minor bugs
*			!Changed indentiation
*			!Fixed serious bug which doesn't allow the freezetime at new_round
*			+Added SpeedUP-Trail: Choose between FIRE or SMOKE which follow you as a trail while running at highspeed
*
*		V0.6.1
*			!Fixed a little bug with postition of special efx when stop running and continue running...
*			!Fixed another bug with amx_speedup_sprite toggle...expected too much parameter for that toggle
*
*		V0.7
*			!Fixed a bug with playercount 
*			+Optimized the freezetime detection routine
*
*		V1.0
*			!Fixed a minor bug
*			@Got approved and therefore changed Version to 1.0
*
*		V1.1
*			!Fixed a bug within deathmatch..if you respawned without a weapon the speed didn't changed--fixed
*	
*
* Known Bugs:
*		-NONE- as always ;)
*
*
*	TODO:
*		I thought about a bunnyhop feature...
*		Adding possibility to switch modes between (instant on and on while key press)
*		Adding a feature where the Field of View is changed upon an given speed(this is harder than i have thought)
*		maybe someone make a suggestion for a feature!?
*
*
*	Credits:
*		p3tsin: For his codesniped in http://forums.alliedmods.net/showpost.php?p=380315&postcount=10 (helped alot making "walking" possible)
*		v3x & jtp10181: For their codesnipeds in http://forums.alliedmods.net/showthread.php?t=23942 (helped optimizing my plugin)
*		VEN & emp`: For their suggestions and advice in my thread (helped clean up my code and learn to optimize it)
*		and especially VEN for his TUTORIAL: http://forums.alliedmods.net/showthread.php?t=42159
*		Bahrmanou: For his "plugin_trail.amxx" which gave me lots of hints how to do a trail
		Prowler: For this nice thread: http://forums.alliedmods.net/showthread.php?t=31682
*		http://wiki.alliedmods.net/Main_Page
*		http://www.amxmodx.org/doc/
*
***********************************************************************************/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>


#define STEPFREQUENCY 0.3
#define TRAILFREQUENCY 0.1
#define MAXPLAYERS 32

// Sprite variables
new g_fire_sprite
new g_smoke_sprite

new g_sprite_size[2] = {5, 1}
new g_sprite_calculatedoffset[MAXPLAYERS+1][2]
new g_sprite_standoffset[2] = {33, 30}
new g_sprite_duckoffset[2] = {14, 12}
new g_sprite_brightness[2] = {160, 255}


// Contains the plugin version
new Version[] = "1.1"

new bool:g_restart_attempt[MAXPLAYERS+1]
new bool:g_freezetime

// Global pointers to the CVARS
new g_speed_enabled
new g_speed_value
new g_speed_bar
new g_speed_trail
new g_speed_spritemodel

// Contains the next timeframe for checking if the player is running or walking
new Float:nextstep[MAXPLAYERS+1]
// Delay for trail calculation
new Float:nexttrail[MAXPLAYERS+1]

// Array that holds number of the players last weapon 
// (for changing the speed related to the current weapon)
new g_WeaponUsed[MAXPLAYERS+1]

// Saves the origin and the last origin of the players for showing the trail
new g_origin[MAXPLAYERS+1][3]
new g_last_origin[MAXPLAYERS+1][3]

// This array holds the speeddata for the players
// [0] = running speed; [1] = walking speed
// [2] = boolean(1/0 running/walking); [3] = SuperfastSpeed (trail)
new g_data[MAXPLAYERS+1][4]

public plugin_init()
{
	register_plugin("SpeedUP", Version, "regalis")
	
	// Registering the CVARS
	g_speed_enabled = register_cvar("amx_speedup", "1") 		// Enable/Disable Speed
	g_speed_value = register_cvar("amx_speedvalue", "250") 	// Set speedvalue
	g_speed_bar	= register_cvar("amx_speedbar", "1") 				// Enable/Disable Speed-Bar on top window
	g_speed_trail	= register_cvar("amx_speedtrail", "1") 		// Enable/Disable Speed-Trail
	g_speed_spritemodel = register_cvar("amx_speedsprite", "1") // Toggle between fire/smoke sprites for trail

	register_cvar("speedup_version", Version, FCVAR_SERVER|FCVAR_SPONLY)
	
	// Registering the Config-Admin console commands 
	// 1. To turn on/off(change speed to configured value or default speed) [To turn really off, disable the plugin in plugins.ini]
	// 2. To set speed value
	register_concmd("amx_speedup_toggle", "toggle_speed", ADMIN_CVAR, "amx_speedup_toggle - Toggle Speedup On/Off.")
	register_concmd("amx_speedup_value", "change_speed", ADMIN_CVAR, "amx_speedup_value - Change the Speed users will get.")
	register_concmd("amx_speedup_bar", "toggle_bar", ADMIN_CVAR, "amx_speedup_bar - Toggle Speedup-Bar On/Off.")
	register_concmd("amx_speedup_trail", "toggle_trail", ADMIN_CVAR, "amx_speedup_trail - Toggle Speedup-Trail On/Off.")
	register_concmd("amx_speedup_sprite", "toggle_sprite", ADMIN_CVAR, "amx_speedup_sprite - Toggle Speedup-Sprite between fire/smoke")

	// Set the Server Maxspeed to a very high amount to make sure the playerspeeds are possible
	set_cvar_num("sv_maxspeed", 10000)
	
	// Hook Events to set player speeds if Round starts
	// or player change his weapon
	register_event("CurWeapon", "Change_Wpn", "be") 			//Weapon changed....maybe adding "1=1"
	register_event("WeapPickup", "buy", "be") 						// Weapon buy/get
	register_event("ResetHUD", "hud_reset", "be") 				// Player spawned possibly
	register_event("TextMsg", "restart_attempt", "a", "2=#Game_will_restart_in") // restart is triggered/delayed
	register_event("HLTV", "new_round", "a", "1=0", "2=0")// new round started (freezetime begins)
	register_logevent("round_start", 2, "1=Round_Start") 	// Round has startet (freezetime is over)

	// Register Fullupdate command to catch demo recording and forced command
	register_clcmd("fullupdate", "clcmd_fullupdate")
	
	// ClientPreThink forward to process the footstepsounds(if walking or ducking nothing will be emited)
	register_forward(FM_PlayerPreThink, "fm_playerthink", 1)
}


public plugin_precache()
{
	g_fire_sprite = precache_model("sprites/flame.spr")
	g_smoke_sprite = precache_model("sprites/xsmoke4.spr")
}


// Called on player joins the server
public client_putinserver(id) 
{
	if (!get_pcvar_num(g_speed_enabled)) return PLUGIN_HANDLED
	
	g_data[id][0] = get_pcvar_num(g_speed_value)	// Current speedvalue get stored
	
	if(!g_freezetime) give_speed(id) // call function to set the speed for the player
	
	if (get_pcvar_num(g_speed_bar)) 
	set_task(1.0, "speed_bar", id+110477, "", 0, "b")

	return PLUGIN_HANDLED
}


// Before player thinks...
public fm_playerthink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED

	new Float:gametime = get_gametime()
	if(nextstep[id] < gametime)		// is it time for the next check?
	{  // check if player is on ground and faster than walking speed and isn't already running
		if((pev(id,pev_flags)&FL_ONGROUND) && (get_currentspeed(id) > g_data[id][1]))
		{
			if(!g_data[id][2])
			{
				g_data[id][2] = 1  // Set boolean that player is running
				nextstep[id] = gametime + STEPFREQUENCY //Add a little delay for checking walking/runnning state
				set_user_footsteps(id, 0)	// Emit the footprint sound
			}
		}
		else
		{
			if(g_data[id][2])
			{
				g_data[id][2] = 0		// Set boolean that while player is walking no more actions are set
				nextstep[id] = gametime + STEPFREQUENCY  //Add a little delay for checking walking/runnning state
				set_user_footsteps(id, 1)	// Don't emit the footprint sound
			}
		}
	}
	if (get_pcvar_num(g_speed_enabled))
	{
		if((nexttrail[id] < gametime) && get_pcvar_num(g_speed_trail))
		{
			if((pev(id,pev_flags)&FL_ONGROUND) && (get_currentspeed(id) > g_data[id][3]))
			{
				nexttrail[id] = gametime + TRAILFREQUENCY //Add a little delay for checking
				get_user_origin(id, g_origin[id])
				if(pev(id,pev_flags)&FL_DUCKING)
				{
					g_sprite_calculatedoffset[id][0] = g_sprite_duckoffset[0] - 19
					g_sprite_calculatedoffset[id][1] = g_sprite_duckoffset[1] - 18
				}
				else
				{
					g_sprite_calculatedoffset[id][0] = g_sprite_standoffset[0]
					g_sprite_calculatedoffset[id][1] = g_sprite_standoffset[1]
				}
				trailmessage(id)
				g_last_origin[id][0] = g_origin[id][0]
				g_last_origin[id][1] = g_origin[id][1]
				g_last_origin[id][2] = g_origin[id][2]
			}
			else
			{
				get_user_origin(id, g_origin[id])
				g_last_origin[id][0] = g_origin[id][0]
				g_last_origin[id][1] = g_origin[id][1]
				g_last_origin[id][2] = g_origin[id][2]
			}
		}
		if(get_pcvar_num(g_speed_bar) && (!task_exists(id+110477)))
		{
			set_task(1.0, "speed_bar", id+110477, "", 0, "b")
		}
	}
	else
	{
		set_pcvar_num(g_speed_value, 250)
		checkWeapon(id)
	}
	return FMRES_IGNORED
}


// Catch fullupdate command and demo recording
public clcmd_fullupdate()
 {
	return PLUGIN_HANDLED_MAIN
}


// Restart is triggered/delayed
public restart_attempt() 
{
	new playercount, Players[MAXPLAYERS]
	get_players(Players, playercount,"a")
	for (new i=0; i < playercount; ++i)
	{
		g_restart_attempt[Players[i]] = true
	}
}


// new round started (freezetime begins)
public new_round()
{
	g_freezetime = true
}


// ResetHUD is triggered
public hud_reset(id)
{
	if (g_restart_attempt[id])
	{
		g_restart_attempt[id] = false
		return
	}
	set_task(0.2, "checkWeapon", id)
}


// Round has startet (freezetime is over)
public round_start()
{
	g_freezetime = false
	new playercount, Players[MAXPLAYERS]
	get_players(Players, playercount,"a")
	for (new i=0; i < playercount; ++i)
	{
		roundstart(Players[i])
	}
}



// Called on roundstart
public roundstart(id)
{
	if (!get_pcvar_num(g_speed_enabled)) return PLUGIN_HANDLED
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	get_user_origin(id, g_last_origin[id]) // Save player position for the trail
	set_task(0.2, "checkWeapon", id)
	return PLUGIN_CONTINUE
}


// Called on player Buy
public buy(id)
{
	if (!get_pcvar_num(g_speed_enabled)) return PLUGIN_HANDLED
	checkWeapon(id)  // call function to set the speed for the player
	return PLUGIN_CONTINUE
}


// Change the speed to default or adjusted value
public toggle_speed(id,lvl,cid)
{
	if (!cmd_access(id, lvl, cid, 1)) return PLUGIN_HANDLED
	if(!get_pcvar_num(g_speed_enabled))
	{
		set_pcvar_num(g_speed_enabled, 1)  // if not enabled then set to enabled
		
		console_print(id, "SpeedUP is now -Enabled-")
		log_message("[AMXX] SpeedUP is now -Enabled-")	
		
		new playercount, Players[MAXPLAYERS]
		get_players(Players, playercount, "a")
		for(new i=0; i < playercount; i++)
		{	
			checkWeapon(Players[i])
		}
	} 
	else 
	{
		set_pcvar_num(g_speed_enabled, 0)
		set_pcvar_num(g_speed_value, 250)  // set default CS speed
		
		console_print(id, "SpeedUP îs now -Disabled-")
		log_message("[AMXX] SpeedUP is now -Disabled-")
		
		new playercount, Players[MAXPLAYERS]
		get_players(Players, playercount, "a")
		for(new i=0; i < playercount; i++)
		{		
			checkWeapon(Players[i])
		}
	}
	return PLUGIN_HANDLED
}


// Toggle the appearance of the Speed-bar
public toggle_bar(id,lvl,cid)
{
	if (!cmd_access(id, lvl, cid, 1)) return PLUGIN_HANDLED
	if(get_pcvar_num(g_speed_enabled))
	{
		if(!get_pcvar_num(g_speed_bar))   // if not enabled then set to enabled
		{
			set_pcvar_num(g_speed_bar, 1)
			
			console_print(id, "SpeedUP-Bar is now -Enabled-")
			log_message("[AMXX] SpeedUP-Bar is now -Enabled-")	
			
			new playercount, Players[MAXPLAYERS]
			get_players(Players, playercount, "a")
			for(new i=0; i < playercount; i++)
			{
				set_task(1.0, "speed_bar", Players[i]+110477, "", 0, "b")	
			}
		} 
		else
		{				// if enabled set to disabled
			set_pcvar_num(g_speed_bar, 0)
			
			console_print(id, "SpeedUP-Bar îs now -Disabled-")
			log_message("[AMXX] SpeedUP-Bar is now -Disabled-")
			
			new playercount, Players[MAXPLAYERS]
			get_players(Players, playercount, "a")
			for(new i=0; i < playercount; i++) // remove task from all players
			{
				if(task_exists(Players[i]+110477))
				{
					remove_task(Players[i]+110477)	// remove the speedbar task
				}
			}
		}
	}
	else
	{
		console_print(id, "To show the SpeedUP-bar please enable SpeedUP")
		log_message("[AMXX] To show the SpeedUP-bar please enable SpeedUP")	
	}
	return PLUGIN_HANDLED
}


// Toggle trail on/off
public toggle_trail(id,lvl,cid)
{
	if (!cmd_access(id, lvl, cid, 1)) return PLUGIN_HANDLED
	if(get_pcvar_num(g_speed_enabled))
	{
		if(get_pcvar_num(g_speed_trail)==0)
		{
			set_pcvar_num(g_speed_trail,1)
			console_print(id, "SpeedUP-Trail îs now -Disabled-")
			log_message("[AMXX] SpeedUP-Trail is now -Disabled-")
			return PLUGIN_HANDLED
		}
		if(get_pcvar_num(g_speed_trail)==1)
		{
			set_pcvar_num(g_speed_trail,0)
			console_print(id, "SpeedUP-Trail îs now -Enabled-")
			log_message("[AMXX] SpeedUP-Trail is now -Enabled-")
			return PLUGIN_HANDLED
		}
	}
	else
	{
		console_print(id, "To show the SpeedUP-Trail please enable SpeedUP")
		log_message("[AMXX] To show the SpeedUP-Trail please enable SpeedUP")	
	}
	return PLUGIN_HANDLED
}


// Toggle between the fire/smoke sprite for trail
public toggle_sprite(id,lvl,cid)
{
	if (!cmd_access(id, lvl, cid, 1) || (!get_pcvar_num(g_speed_enabled))) return PLUGIN_HANDLED

	if(get_pcvar_num(g_speed_spritemodel)==0)
	{
		set_pcvar_num(g_speed_spritemodel,1)
		console_print(id, "SpeedUP-Trail Sprite îs now -FIRE-")
		log_message("[AMXX] SpeedUP-Trail Sprite is now -FIRE-")
		return PLUGIN_HANDLED
	}
	if(get_pcvar_num(g_speed_spritemodel)==1)
	{
		set_pcvar_num(g_speed_spritemodel,0)
		console_print(id, "SpeedUP-Trail Sprite îs now -SMOKE-")
		log_message("[AMXX] SpeedUP-Trail Sprite is now -SMOKE-")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}


// Change the speed value
public change_speed(id,lvl,cid)
	{
	if (!cmd_access(id, lvl, cid, 2) || (!get_pcvar_num(g_speed_enabled))) return PLUGIN_HANDLED
	
	new speed_value, speed_arg[10]
	read_argv(1, speed_arg, 9)
	speed_value = str_to_num(speed_arg)
	
	if(speed_value > 2000)
	{
		console_print(id, "SpeedUP-Value is too high, available values are between 0 and 2000")
		log_message("[AMXX] SpeedUP-Value is too high, available values are between 0 and 2000")
		return PLUGIN_HANDLED
	}
	set_pcvar_num(g_speed_value, speed_value)
	
	console_print(id, "SpeedUP-Value changed to %d", speed_value)
	log_message("[AMXX] SpeedUP-Value changed to %d", speed_value)
	
	new playercount, Players[MAXPLAYERS]
	get_players(Players, playercount, "a")
	for(new i=0; i < playercount; i++)
	{
		checkWeapon(Players[i])
	}
	return PLUGIN_HANDLED
}


// Called on player switches his weapon
public Change_Wpn(id)
{
	if (!get_pcvar_num(g_speed_enabled)) return PLUGIN_HANDLED
	
	new WeaponNum = read_data(2)  // read and store the weaponID
	new WeaponActive = read_data(1)  // read the flag if weapon is active (user holds in his hand)
	
	if ((WeaponNum != g_WeaponUsed[id]) && WeaponActive)  // if weapon has changed and its the active weapon continue
	{
		g_WeaponUsed[id] = WeaponNum
		calculate_speed(id, WeaponNum)
		if(!g_freezetime) give_speed(id)
	}
	return PLUGIN_HANDLED
}


// Checks the players current weapon and give him the corresponding speed
public checkWeapon(id)
{	
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	new ammo, clip
	new WeaponNum = get_user_weapon(id, ammo, clip)
	
	calculate_speed(id, WeaponNum)
	if(!g_freezetime) give_speed(id)
	
	return PLUGIN_HANDLED
}


// Calculate the percentual running- and walking-speed for current Weapon (e.g. awp gives a slower speed than knife)
stock calculate_speed(id, WeaponNum)
{
	new speed_value = get_pcvar_num(g_speed_value)
	
	switch (WeaponNum)
	{
		case CSW_SCOUT:{
			g_data[id][0] = (speed_value * 104)/100; 	// Calculate the speed for current Weapon
			g_data[id][1] = (g_data[id][0]*55)/100;		// Calculate the walking speed for current Weapon(plus a little buffer)
			g_data[id][3] = (g_data[id][0]*95)/100;		// Calculate the speed at which the trail will follow the player
		}
		case CSW_P90:{
			g_data[id][0] = (speed_value * 98)/100;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		case CSW_XM1014, CSW_AUG, CSW_GALI, CSW_FAMAS:{
			g_data[id][0] = (speed_value * 96)/100;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		case CSW_SG552:{
			g_data[id][0] = (speed_value * 94)/100;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		case CSW_M3, CSW_M4A1:{
			g_data[id][0] = (speed_value * 92)/100;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		case CSW_AK47:{
			g_data[id][0] = (speed_value * 884)/1000;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		case CSW_M249:{
			g_data[id][0] = (speed_value * 88)/100;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		case CSW_SG550, CSW_AWP, CSW_G3SG1:{
			g_data[id][0] = (speed_value * 84)/100;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
		default:{ // All other weapons and nades
			g_data[id][0] = speed_value;
			g_data[id][1] = (g_data[id][0]*55)/100;
			g_data[id][3] = (g_data[id][0]*95)/100;
		}
	}
	return PLUGIN_CONTINUE
}


// Applys the speed value to the players
give_speed(id)
{
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	client_cmd(id, "cl_forwardspeed %d ; cl_sidespeed %d ; cl_backspeed %d", g_data[id][0]+100, g_data[id][0]+100, g_data[id][0]+100)
	set_user_maxspeed(id, float(g_data[id][0]))	
	return PLUGIN_CONTINUE
}


// Task for displaying the actual speed at the top player window
public speed_bar(id)
{
	if(get_pcvar_num(g_speed_bar) && get_pcvar_num(g_speed_enabled))
	{
		set_hudmessage(192, 192, 192, -1.0, 0.0, 0, 0.0, 1.0, 0.0, 0.0, 1)
		show_hudmessage(id-110477, "Speed: %.2f px/s", get_currentspeed(id-110477))
	}
	else
	{
		remove_task(id) // remove the speed-bar task
	}
}


// stock for getting the current player speed
stock Float:get_currentspeed(id) 
{
	static Float:vel[3]
	pev(id,pev_velocity, vel)
	return vector_length(vel)
}


trailmessage(id)
{
	//#define TE_SPRITE     17    // additive sprite, plays 1 cycle
	new sprite = get_pcvar_num(g_speed_spritemodel)
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY) //message begin
	write_byte(TE_SPRITE)
	write_coord(g_last_origin[id][0]) // start position
	write_coord(g_last_origin[id][1])
	write_coord(g_last_origin[id][2] - (sprite ? g_sprite_calculatedoffset[id][1] : g_sprite_calculatedoffset[id][0]))
	write_short(sprite ? g_fire_sprite : g_smoke_sprite) // sprite index
	write_byte(sprite ? g_sprite_size[1] : g_sprite_size[0]) // scale in 0.1's
	write_byte(sprite ? g_sprite_brightness[1] : g_sprite_brightness[0]) // brightness
	message_end()
	return PLUGIN_HANDLED
}


// Garbage collection - remove speed-bar task if exist
public client_disconnect(id)
{
	if(task_exists(id+110477))
	{
		remove_task(id+110477) // remove the speed-bar task
	}
}