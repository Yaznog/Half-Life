#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

new P_Cvars[31]
new Weapons[33][2]

public plugin_init()
{
	register_plugin("Fire Rate Control", "1.08", "Fxfighter")
	register_event("CurWeapon","Event_CurWeapon", "b")
	
	P_Cvars[0] = register_cvar("amx_speed_mode","1")
	P_Cvars[1] = register_cvar("amx_speed_p228","1.0")
	P_Cvars[3] = register_cvar("amx_speed_scout","1.0")
	P_Cvars[4] = register_cvar("amx_speed_hegrenade","1.0")
	P_Cvars[5] = register_cvar("amx_speed_xm1014","1.0")
	P_Cvars[6] = register_cvar("amx_speed_all","1.0")
	P_Cvars[7] = register_cvar("amx_speed_mac10","1.0")
	P_Cvars[8] = register_cvar("amx_speed_aug","1.0")
	P_Cvars[9] = register_cvar("amx_speed_smokegrenade","1.0")
	P_Cvars[10] = register_cvar("amx_speed_elite","1.0")
	P_Cvars[11] = register_cvar("amx_speed_fiveseven","1.0")
	P_Cvars[12] = register_cvar("amx_speed_ump45","1.0")
	P_Cvars[13] = register_cvar("amx_speed_sg550","1.0")
	P_Cvars[14] = register_cvar("amx_speed_galil","1.0")
	P_Cvars[15] = register_cvar("amx_speed_famas","1.0")
	P_Cvars[16] = register_cvar("amx_speed_usp","1.0")
	P_Cvars[17] = register_cvar("amx_speed_glock18","1.0")
	P_Cvars[18] = register_cvar("amx_speed_awp","1.0")
	P_Cvars[19] = register_cvar("amx_speed_mp5navy","1.0")
	P_Cvars[20] = register_cvar("amx_speed_m249","1.0")
	P_Cvars[21] = register_cvar("amx_speed_m3","1.0")
	P_Cvars[22] = register_cvar("amx_speed_m4a1","1.0")
	P_Cvars[23] = register_cvar("amx_speed_tmp","1.0")
	P_Cvars[24] = register_cvar("amx_speed_g3sg1","1.0")
	P_Cvars[25] = register_cvar("amx_speed_flashbang","1.0")
	P_Cvars[26] = register_cvar("amx_speed_deagle","1.0")
	P_Cvars[27] = register_cvar("amx_speed_sg552","1.0")
	P_Cvars[28] = register_cvar("amx_speed_ak47","1.0")
	P_Cvars[30] = register_cvar("amx_speed_p90","1.0")
}

public Event_CurWeapon(id) 
{ 
	new Gun = read_data(2) 
	new On = get_pcvar_num(P_Cvars[0])
	
	if( !On || !Gun || Gun==6 || Gun==29 || Gun>30)return		
	
	new Ammo = read_data(3) 	
	if(Weapons[id][0] != Gun || Weapons[id][1] == Ammo)
	{
		Weapons[id][0] = Gun
		Weapons[id][1] = Ammo 
		return
	}
	Weapons[id][0] = Gun
	Weapons[id][1] = Ammo 
	
	static Float:N_Speed
	if(On == 1)N_Speed = get_pcvar_float(P_Cvars[6])
	else N_Speed = get_pcvar_float(P_Cvars[Gun])
		
	if(N_Speed != 1.0)
	{
		static weapon[32],Ent
		get_weaponname(Gun,weapon,31)
		Ent = fm_find_ent_by_owner(-1,weapon,id)
		if(Ent)
		{
			static Float:Delay,Float:M_Delay
			Delay = get_pdata_float( Ent, 46, 4) * N_Speed
			M_Delay = get_pdata_float( Ent, 47, 4) * N_Speed
			if (Delay > 0.0)
			{
				set_pdata_float( Ent, 46, Delay, 4)
				set_pdata_float( Ent, 47, M_Delay, 4)
			}
		}
	}
}
//Frome Fakemeta utility
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
{
	new strtype[11] = "classname", ent = index
	switch (jghgtype) 
	{
		case 1: strtype = "target"
		case 2: strtype = "targetname"
	}
	
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}
	
	return ent
}
