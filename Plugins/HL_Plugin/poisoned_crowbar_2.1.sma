#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <fun>

#define PLUGIN "Poisoned CrowBar"
#define VERSION "2.1"
#define AUTHOR "anakin_cstrike"

#define V_MODEL "models/v_crowbar.mdl"
#define W_MODEL "models/w_crowbar.mdl"
#define P_MODEL "models/p_crowbar.mdl"
#define KNIFE_W_MODEL "models/w_knife.mdl"
#define KNIFE_V_MODEL "models/v_knife.mdl"
#define KNIFE_P_MODEL "models/p_knife.mdl"

new 
toggle_plugin,toggle_hp,
toggle_interval,toggle_cost,
toggle_vamp,toggle_vampa,
toggle_maxhp,toggle_hs,toggle_speed,
toggle_dur,toggle_suicide,toggle_grav,
p_cost,p_dur,p_hp,p_int,p_maxhp,p_maxspeed;
new bool: g_CrowBar[33],bool: g_Counting,g_Count[33] = 0;
new gmsgsaytext,gmsgscreenfade,gmsgstatusicon;
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_SetModel,"fw_setmodel"/*,1*/);
	register_event("CurWeapon","evn_curwpn","be","1=1");
	register_event("Damage", "evn_damage", "b", "2!0", "3=0", "4!0");
	register_event("DeathMsg","hook_death","a");
	register_event("HLTV","hook_round","a","1=0","2=0");
	register_event("ResetHUD","hook_reset","b");
	register_clcmd("say /crowbar","crowbar_buy");
	register_clcmd("say /cb","crowbar_buy");
	toggle_plugin = register_cvar("crowbar","1");
	toggle_hp = register_cvar("crowbar_hp","1");
	toggle_interval = register_cvar("crowbar_interval","2");
	toggle_cost = register_cvar("crowbar_cost","7500");
	toggle_dur = register_cvar("crowbar_duration","3");
	toggle_vamp = register_cvar("crowbar_vampiric","1");
	toggle_vampa = register_cvar("crowbar_vampammount","0.3");
	toggle_maxhp = register_cvar("crowbar_maxhealth","125");
	toggle_hs = register_cvar("crowbar_hsexplode","1");
	toggle_speed = register_cvar("crowbar_speed","200");
	toggle_grav = register_cvar("crowbar_highgravity","1");
	toggle_suicide = register_cvar("crowbar_suicidereset","0");
	p_hp = get_pcvar_num(toggle_hp);
	p_int = get_pcvar_num(toggle_interval);
	p_dur = get_pcvar_num(toggle_dur);
	p_maxhp = get_pcvar_num(toggle_maxhp);
	p_cost = get_pcvar_num(toggle_cost);
	p_maxspeed = get_pcvar_num(toggle_speed);
	
	gmsgsaytext = get_user_msgid("SayText");
	gmsgscreenfade = get_user_msgid("ScreenFade");
	gmsgstatusicon = get_user_msgid("StatusIcon");
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel,V_MODEL);
	engfunc(EngFunc_PrecacheModel,P_MODEL);
	engfunc(EngFunc_PrecacheModel,W_MODEL);
	precache_sound("weapons/headshot2.wav");
}
public client_connect(id) g_CrowBar[id] = false;	
public client_disconnect(id) g_CrowBar[id] = false;
public crowbar_buy(id)
{
	if(get_pcvar_num(toggle_plugin) != 1)
		return PLUGIN_CONTINUE;
	if(!is_user_alive(id))
	{
		print(id,"You must be alive to buy a Crowbar!");
		return PLUGIN_CONTINUE;
	}
	new gmoney = cs_get_user_money(id);
	if(gmoney < p_cost)
	{
		print(id,"Not enough money!");
		return PLUGIN_CONTINUE;
	}
	if(g_CrowBar[id])
	{
		print(id,"You have allready bought a CrowBar!");
		return PLUGIN_CONTINUE;
	}
	cs_set_user_money(id,gmoney - p_cost,1);
	print(id,"You have bough a Poisoned CrowBar!");
	g_CrowBar[id] = true;
	g_Count[id] = 0;
	g_Counting = true;
	return PLUGIN_CONTINUE;
}
public hook_reset(id)
{
	if(task_exists(id+1234))
		remove_task(id+1234);
}
public hook_death()
{
	new victim = read_data(2);
	if((!read_data(1) || !victim) && get_pcvar_num(toggle_suicide) == 0)
		return PLUGIN_CONTINUE;
	if(task_exists(victim+1234))
		remove_task(victim+1234);
	g_CrowBar[victim] = false;
	g_Count[victim] = 0;
	if(read_data(3) && get_pcvar_num(toggle_hs) == 1 && g_CrowBar[read_data(1)] && !g_CrowBar[victim])
	{
		new vorigin[3];
		get_user_origin(victim,vorigin);
		Blood(vorigin);
		emit_sound(0,CHAN_ITEM, "weapons/headshot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	return PLUGIN_CONTINUE;
}
public evn_curwpn(id)
{
	if(get_pcvar_num(toggle_plugin) != 1)
		return PLUGIN_CONTINUE;
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	new wpn = read_data(2);
	if(!g_CrowBar[id])
		return PLUGIN_CONTINUE;
	if(wpn == CSW_KNIFE)
	{
		set_pev(id,pev_viewmodel2,V_MODEL);
		set_pev(id,pev_weaponmodel2,P_MODEL);
		Speed(id,float(p_maxspeed));
		if(get_pcvar_num(toggle_grav) == 1)
			Gravity(id,1.75);
	} else {
		Speed(id,280.0);
		Gravity(id,1.0);
	}
	return PLUGIN_CONTINUE;
}
public fw_setmodel(ent,const model[])
{
	if(get_pcvar_num(toggle_plugin) != 1)
		return FMRES_IGNORED;
	if(!pev_valid(ent))
		return FMRES_IGNORED;
	if(strcmp(KNIFE_W_MODEL,model))
		return FMRES_IGNORED;
	static classname[32]
	pev(ent,pev_classname,classname,31);
	if(!strcmp(classname, "weaponbox") || !strcmp(classname, "armoury_entity") || !strcmp(classname, "grenade"))
	{
		engfunc(EngFunc_SetModel, ent, W_MODEL);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}
public evn_damage(victim)
{
	if(get_pcvar_num(toggle_plugin) != 1)
		return PLUGIN_CONTINUE;
	new weapon,attacker = get_user_attacker(victim, weapon);
	new damage = read_data(2);
	if(!attacker || !is_user_alive(victim))
		return PLUGIN_CONTINUE;
	if(weapon != CSW_KNIFE)
		return PLUGIN_CONTINUE;
	if(!g_CrowBar[attacker])
		return PLUGIN_CONTINUE;
	FadeEffect(victim,255,0,0,75);	
	set_task(float(p_int),"effects",victim+1234,"",0, "b");
	if(get_pcvar_num(toggle_vamp) == 1)
	{
		new sHealth = get_user_health(attacker);
		new sBonus = floatround(float(damage) * get_pcvar_float(toggle_vampa));
	
		if(sHealth + sBonus > p_maxhp)
			set_user_health(attacker,p_maxhp);
		else 
			set_user_health(attacker,sHealth + sBonus);
		FadeEffect(attacker,0,255,0,30);
	}
	return PLUGIN_CONTINUE;
}
public effects(task)
{
	new index = task - 1234
	new hp = get_user_health(index);
	is_user_alive(index) ? set_user_health(index,hp - p_hp) : remove_task(index);
	
	new Origin[3]; get_user_origin(index,Origin);
	BleedEffect(Origin);
	FadeEffect(index,255,0,0,30);
	IconEffect(index);
}
public hook_round()
{
	if(get_pcvar_num(toggle_plugin) != 1)
		return PLUGIN_CONTINUE;
	if(!g_Counting)
		return PLUGIN_CONTINUE;	
	new players[32],num,index,i;
	get_players(players,num);
	for(i = 0;i < num;i++)
	{
		index = players[i];
		g_Count[index]++;
		if(!g_CrowBar[index]) continue;
		if(g_Count[index] >= p_dur)
		{
			g_CrowBar[index] = false;
			g_Count[index] = 0;
			g_Counting = false;
			set_pev(index,pev_viewmodel2,KNIFE_V_MODEL);
			set_pev(index,pev_weaponmodel2,KNIFE_P_MODEL);
			engfunc(EngFunc_SetModel,index,KNIFE_W_MODEL);
		}
	}
	return PLUGIN_CONTINUE;
}
public BleedEffect(Origin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BLOODSTREAM);
	write_coord(Origin[0]);
	write_coord(Origin[1]);
	write_coord(Origin[2]+10);
	write_coord(random_num(-360,360));
	write_coord(random_num(-360,360));
	write_coord(-10);
	write_byte(70);
	write_byte(random_num(50,100));
	message_end();
}
public IconEffect(index)
{
	message_begin(MSG_ONE,gmsgstatusicon,{0,0,0},index);
	write_byte(2);
	write_string("dmg_bio");
	write_byte(255);
	write_byte(50);
	write_byte(0);
	message_end()
}
public FadeEffect(index,red,green,blue,alpha)
{
	message_begin(MSG_ONE_UNRELIABLE,gmsgscreenfade,{0,0,0},index);
	write_short(1<<10);
	write_short(1<<10);
	write_short(1<<12);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
}
Blood(pos[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_LAVASPLASH); 
	write_coord(pos[0]); 
	write_coord(pos[1]); 
	write_coord(pos[2]); 
	message_end(); 
}
Speed(index,Float:maxspeed) set_pev(index,pev_maxspeed,maxspeed);
Gravity(index,Float:grav) set_pev(index,pev_gravity,grav);
print(index,const message[])
{
	new Buffer[128];
	formatex(Buffer,sizeof Buffer - 1,"%s",message);
	if(!is_user_connected(index)) return 0;
	message_begin(MSG_ONE,gmsgsaytext,_,index);
	write_byte(index);
	write_string(Buffer);
	message_end();
	return 1;
}
