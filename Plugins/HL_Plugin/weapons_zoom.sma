/*	Formatright © 2010, ConnorMcLeod

	Weapons Zoom is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Weapons Zoom; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "0.0.2"

// weapons offsets
#define XTRA_OFS_WEAPON			4
#define m_pPlayer				41
#define m_iId					43
#define m_fInReload				54
#define m_fInSpecialReload		55

#define XTRA_OFS_PLAYER			5
#define m_flNextAttack			83
#define m_iFOV					363

#define Ham_Player_ResetMaxSpeed Ham_Item_PreFrame

#define MAX_WEAPONS CSW_P90

const NO_RELOAD_WEAPONS_BITSUM = (1<<CSW_HEGRENADE)|(1<<CSW_C4)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)

#define SILENCE_WEAPONS_BITSUM (1<<CSW_USP)|(1<<CSW_M4A1)
#define FIRERATE_WEAPONS_BITSUM (1<<CSW_FAMAS)|(1<<CSW_GLOCK18)
//const LOWZOOM_WEAPONS_BITSUM = (1<<CSW_SG552)|(1<<CSW_AUG)
//const HIGHZOOM_WEAPONS_BITSUM = (1<<CSW_SCOUT)|(1<<CSW_AWP)|(1<<CSW_G3SG1)|(1<<CSW_SG550)

#define IsiIdShotGun(%1)		( ((1<<CSW_USP)|(1<<CSW_M4A1)) & (1<<%1) )

const ALREADY_SEC_ATTACK_WEAP_BITS = (1<<CSW_KNIFE)|SILENCE_WEAPONS_BITSUM|FIRERATE_WEAPONS_BITSUM

enum _:ZoomDatas {
	Float:ZoomDatas_flDelay,
	Float:ZoomDatas_flMaxSpeed,
	ZoomDatas_iFov1,
	ZoomDatas_iFov2
}

enum _:Forwards {
	HamHook:PostFrame,
	HamHook:Holster,
	HamHook:GetMaxSpeed,
	HamHook:Reload
}

new g_mZoomedWeaponsDatas[MAX_WEAPONS+1][ZoomDatas]
new HamHook:g_iHhForwards[MAX_WEAPONS+1][Forwards]

public plugin_init()
{
	register_plugin("Weapons Zoom", VERSION, "ConnorMcLeod")

	register_concmd("weapon_zoom", "ConsoleCommand_WeaponZoom", ADMIN_CFG, " <weapon name> <delay> <maxspeed> <zoom1> [zoom2]")
	register_concmd("weapon_unzoom", "ConsoleCommand_WeaponUnZoom", ADMIN_CFG, " <weapon name>")
}

public ConsoleCommand_WeaponZoom(id, lvl, cid)
{
	if( cmd_access(id, lvl, cid, 5) )
	{
		new szWeaponName[32] = "weapon_"
		read_argv(1, szWeaponName[7], charsmax(szWeaponName)-7)
		new iId = get_weaponid(szWeaponName)
		if( iId )
		{
			new iZoom1, iZoom2 = 90
			new szDelay[32], szMaxSpeed[32], szZoom1[3]

			read_argv(2, szDelay, charsmax(szDelay))
			read_argv(3, szMaxSpeed, charsmax(szMaxSpeed))
			read_argv(4, szZoom1, charsmax(szZoom1))

			g_mZoomedWeaponsDatas[iId][ZoomDatas_flDelay] = _:floatmax(str_to_float(szDelay), 0.1)
			g_mZoomedWeaponsDatas[iId][ZoomDatas_flMaxSpeed] = _:str_to_float(szMaxSpeed)
			iZoom1 = clamp(str_to_num(szZoom1), 0, 90)
			if( !iZoom1 )
			{
				iZoom1 = 90
			}

			if( read_argc() == 6 )
			{
				new szZoom2[3]
				read_argv(5, szZoom2, charsmax(szZoom2))
				iZoom2 = clamp(str_to_num(szZoom2), 0, 90)
				if( !iZoom2 )
				{
					iZoom2 = 90
				}
			}

			if( iZoom2 != 90 && iZoom2 > iZoom1 )
			{
				new iTemp = iZoom1
				iZoom1 = iZoom2
				iZoom2 = iTemp
			}

			g_mZoomedWeaponsDatas[iId][ZoomDatas_iFov1] = iZoom1
			g_mZoomedWeaponsDatas[iId][ZoomDatas_iFov2] = iZoom2


			if( g_iHhForwards[iId][PostFrame] )
			{
				EnableHamForward( g_iHhForwards[iId][PostFrame] )
				EnableHamForward( g_iHhForwards[iId][Holster] )
				EnableHamForward( g_iHhForwards[iId][GetMaxSpeed] )
				if( ~NO_RELOAD_WEAPONS_BITSUM & 1<<iId )
				{
					EnableHamForward( g_iHhForwards[iId][Reload] )
				}
			}
			else
			{
				g_iHhForwards[iId][PostFrame] = RegisterHam(Ham_Item_PostFrame, szWeaponName, "Item_PostFrame", 0)
				g_iHhForwards[iId][Holster] = RegisterHam(Ham_Item_Holster, szWeaponName, "Item_Holster", 0)
				g_iHhForwards[iId][GetMaxSpeed] = RegisterHam(Ham_CS_Item_GetMaxSpeed, szWeaponName, "Item_GetMaxSpeed", 0)
				if( ~NO_RELOAD_WEAPONS_BITSUM & 1<<iId )
				{
					g_iHhForwards[iId][Reload] = RegisterHam(Ham_Weapon_Reload, szWeaponName, IsiIdShotGun(iId) ? "ShotGun_Reload" : "Weapon_Reload", 1)
				}
			}
		}
	}
	return PLUGIN_HANDLED
}

public ConsoleCommand_WeaponUnZoom(id, lvl, cid)
{
	if( cmd_access(id, lvl, cid, 2) )
	{
		new szWeaponName[17] = "weapon_"
		read_argv(1, szWeaponName[7], charsmax(szWeaponName)-7)
		new iId = get_weaponid(szWeaponName)
		if( iId && g_iHhForwards[iId][PostFrame] )
		{
			DisableHamForward( g_iHhForwards[iId][PostFrame] )
			DisableHamForward( g_iHhForwards[iId][Holster] )
			DisableHamForward( g_iHhForwards[iId][GetMaxSpeed] )
			if( ~NO_RELOAD_WEAPONS_BITSUM & 1<<iId )
			{
				DisableHamForward( g_iHhForwards[iId][Reload] )
			}
		}	
	}
	return PLUGIN_HANDLED
}

public Item_GetMaxSpeed( iEnt )
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)
	if( get_pdata_int(id, m_iFOV, XTRA_OFS_PLAYER) == 90 )
	{
		return HAM_IGNORED
	}

	new Float:flMaxSpeed = g_mZoomedWeaponsDatas[ get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON) ][ ZoomDatas_flMaxSpeed ]
	if( flMaxSpeed > 0.0 )
	{
		SetHamReturnFloat( flMaxSpeed )
		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public Item_PostFrame( iEnt )
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON)

	new bitButton = IN_ATTACK2

	new iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON)

	if( ALREADY_SEC_ATTACK_WEAP_BITS & 1<<iId )
	{
		bitButton |= IN_USE
	}

	if( pev(id, pev_button) & bitButton == bitButton )
	{
		new iFov = get_pdata_int(id, m_iFOV, XTRA_OFS_PLAYER)

		if( iFov == 90 )
		{
			SetFov( id, g_mZoomedWeaponsDatas[ iId ][ ZoomDatas_iFov1 ] )
		}
		else if( iFov == g_mZoomedWeaponsDatas[ iId ][ ZoomDatas_iFov1 ] )
		{

			SetFov( id, g_mZoomedWeaponsDatas[ iId ][ ZoomDatas_iFov2 ] )
		}
		else
		{
			SetFov( id, 90 )
		}

		ExecuteHamB(Ham_Player_ResetMaxSpeed, id)

		emit_sound(id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100)
		set_pdata_float(id, m_flNextAttack, g_mZoomedWeaponsDatas[ iId ][ ZoomDatas_flDelay ], XTRA_OFS_PLAYER)

		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public Item_Holster( iEnt )
{
	if( ExecuteHamB(Ham_Item_CanHolster, iEnt) )
	{
		ResetFov( get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON) )
	}
}

public Weapon_Reload( iEnt )
{
	if( get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON) )
	{
		ResetFov( get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON) )
	}
}

public ShotGun_Reload( iEnt )
{
	if( get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON) == 1 )
	{
		ResetFov( get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON) )
	}
}

SetFov( id, iFov )
{
	set_pev(id, pev_fov, iFov)
	set_pdata_int(id, m_iFOV, iFov, XTRA_OFS_PLAYER)
}

ResetFov( id )
{
	if( 0 <= get_pdata_int(id, m_iFOV, XTRA_OFS_PLAYER) <= 90 )
	{
		set_pev(id, pev_fov, 90)
		set_pdata_int(id, m_iFOV, 90, XTRA_OFS_PLAYER)
	}
}