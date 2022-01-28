///////////////////////////////////////////////////////
//  Credits...                                       //
//                                       	     //
//  tostly, joropito, L//, Starsailor, ConnorMcLeod  //
//                                                   //
///////////////////////////////////////////////////////

#include <translator>
#include <amxmod>
#include <amxmisc>

#define MAX_FRAGS 1000
#define SET_FRAGS 1337

enum _:ScoreInfo_Args {
	PlayerID = 1,
	Frags,
	Deaths,
	ClassID,
	TeamID
}

new g_msgScoreInfo
new p_MsgOn, p_MsgDelay

public plugin_init()
{
	new const VERSION[] = "1.4"
	load_translations("health_armor_scoreboard")
	register_plugin(_T("Health & Armor in Scoreboard"), VERSION, "Alucard")
	
	register_cvar("health_armor_scoreboard", VERSION,FCVAR_SERVER|FCVAR_SPONLY)
	
	p_MsgOn = register_cvar("has_msg_on", "1")
	p_MsgDelay = register_cvar("has_msg_delay", "180.0")
	
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	
	register_message(g_msgScoreInfo, "Message_ScoreInfo")
	
	register_event("Battery", "EventBattery", "b")
	register_event("Health", "EventHealth", "b")
	
	set_task(get_cvarptr_float(p_MsgDelay), "MsgToPlayers", .flags="b")
}

public Message_ScoreInfo(iMsgId, iMsgType, iMsgEnt)
{
	new id = get_msg_arg_int(PlayerID)
	
	set_msg_arg_int(Frags, get_user_health(id) )
	set_msg_arg_int(Deaths, get_user_armor(id) )
}

Send_ScoreInfo(id, iFrags, iDeaths, iTeamID)
{
	if(iFrags > MAX_FRAGS)
	{
		iFrags = SET_FRAGS
		iDeaths = SET_FRAGS
	}
	new iIsAlive = is_user_alive(id)
	
	message_begin(MSG_BROADCAST, g_msgScoreInfo)
	write_byte(id)  
	write_short(iIsAlive ? iFrags : 0) 
	write_short(iIsAlive ? iDeaths : 0) 
	write_short(0) 
	write_short(iTeamID) 
	message_end()
}

public EventBattery(id)
	Send_ScoreInfo(id, get_user_health(id), read_data(1), get_user_team(id) )

public EventHealth(id)
	Send_ScoreInfo(id, read_data(1), get_user_armor(id), get_user_team(id) )

public MsgToPlayers()
{
	if(get_cvarptr_num(p_MsgOn) )
		client_print_color(-1, 0, _T("[^4H & A^1] In this server ^3Frags & Deaths ^1are replaced with ^3Health & Armor ^1in the Scoreboard."))
}
