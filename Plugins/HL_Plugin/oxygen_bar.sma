/*

Current Version - 0.7.0

Oxygen Bar

- Description -

Another pointless plugin from me. While you're underwater, it shows an oxygen bar,
showing how much oxygen you still have. When the last line from the bar disappears you will start to receive damage.
There are no cvars, just a red bar displaying the amount of oxygen you still have left.
If you really hate the red color, change it yourself. Bar is only displayed while you're in water.

- Screenshot -

http://img3.imageshack.us/img3/4464/oxyscreen.jpg

- Changelog -

0.7.0
*Initial Release

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define VERSION	"0.7.0"

//Maxplayers. I like it this way, not the "new g_Maxplayers = get_maxplayers() / for(i = 1; i < g_Maxplayers; i++)" way.
#define MAXPLAYERS 32 + 1

//Handler think time
#define HANDLER_THINK_TIME 0.01

//Time player can stay underwater, until he starts receiving damage
#define UNDERWATER_MAX_TIME 12.012

//Lines in the oxygen bar
#define BAR_LINES 12

//Time per line in oxygen bar
#define TIME_PER_LINE UNDERWATER_MAX_TIME / BAR_LINES

//Bar array size // 6 - name 'oxygen' // 2 - '^n' // 2 - '[' and ']'
#define BAR_STRING_LENGTH BAR_LINES + 6 + 2 + 2 

//Oxygen bar chars.
#define FULL_CHAR 	"|"
#define EMPTY_CHAR	"="

//pev_waterlevel 3 - head is underwater
#define UNDERWATER 3

//Handler entity id
new g_HandlerEnt

//Is player alive?
new bool:g_PlayerAlive[MAXPLAYERS]

//Hold the time when player dived into the water
new Float:g_PlayerWaterGametime[MAXPLAYERS]

//Holds the gametime of players last bar update.
new Float:g_PlayerUpdateGametime[MAXPLAYERS]

public plugin_init() {
	
	register_plugin("Oxygen Bar",VERSION,"shine")
	
	register_cvar("oxygenbar",VERSION,FCVAR_SERVER|FCVAR_SPONLY)
	
	//Events
	register_event("DeathMsg","PlayerDeath","a")
	
	//Ham Forwards
	RegisterHam(Ham_Spawn,"player","PlayerSpawn",1)
	RegisterHam(Ham_Think,"info_target","HandlerThink",1)
	
	//Make handler
	MakeHandler()
}

public MakeHandler() {
	
	g_HandlerEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	
	set_pev(g_HandlerEnt,pev_classname,"OxyHandler")
	
	set_pev(g_HandlerEnt,pev_nextthink,get_gametime() + HANDLER_THINK_TIME)
}

public client_disconnect(id) {
	
	g_PlayerAlive[id] = false
	
	g_PlayerWaterGametime[id] = 0.0
	
	g_PlayerUpdateGametime[id] = 0.0
}

public PlayerDeath() g_PlayerAlive[read_data(2)] = false

public PlayerSpawn(id) if(is_user_alive(id)) g_PlayerAlive[id] = true

public HandlerThink(Ent) {
	
	if(Ent == g_HandlerEnt) {
		
		static Float:Gametime, i, x
		Gametime = get_gametime()
		
		set_hudmessage(255,0,0,-1.0,0.9,0,6.0,TIME_PER_LINE + 0.01)
		
		for(i = 1; i < MAXPLAYERS; i++) {
			
			if(g_PlayerAlive[i]) {
				
				if(pev(i,pev_waterlevel) == UNDERWATER && !g_PlayerWaterGametime[i]) {
					
					g_PlayerWaterGametime[i] = Gametime
				}
				else if(pev(i,pev_waterlevel) != UNDERWATER) {
					
					g_PlayerWaterGametime[i] = 0.0
				}
				else if(Gametime - g_PlayerUpdateGametime[i] >= TIME_PER_LINE) {
					
					static sBar[BAR_STRING_LENGTH], Float:UnderWaterGametime
					
					//Static looks cooler
					sBar[0] = 0
					
					UnderWaterGametime = UNDERWATER_MAX_TIME - (Gametime - g_PlayerWaterGametime[i])
					
					add(sBar,BAR_STRING_LENGTH - 1,"Oxygen^n[")
					
					for(x = 0; x < BAR_LINES; x++) {
						
						if(UnderWaterGametime >= x * TIME_PER_LINE) 	add(sBar,BAR_STRING_LENGTH - 1,FULL_CHAR)
						else 											add(sBar,BAR_STRING_LENGTH - 1,EMPTY_CHAR)
					}
					
					add(sBar,BAR_STRING_LENGTH - 1,"]")
					
					show_hudmessage(i,sBar)
					
					g_PlayerUpdateGametime[i] = Gametime
				}
			}
		}
		
		set_pev(Ent,pev_nextthink,get_gametime() + HANDLER_THINK_TIME)
	}
}