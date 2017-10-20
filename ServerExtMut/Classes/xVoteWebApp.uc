Class xVoteWebApp extends Object implements(IQueryHandler);

var WebAdmin webadmin;
var string MapVoterURL;
var int EditSettingLine;

function cleanup()
{
	webadmin = None;
}
function init(WebAdmin webapp)
{
	webadmin = webapp;
}
function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu(MapVoterURL, "X - Mapvote", self, "Modify settings of mapvote.", -88);
}
function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case MapVoterURL:
			handleMapVotes(q);
			return true;
	}
	return false;
}

final function IncludeFile( WebAdminQuery q, string file )
{
	local string S;
	
	if( webadmin.HTMLSubDirectory!="" )
	{
		S = webadmin.Path $ "/" $ webadmin.HTMLSubDirectory $ "/" $ file;
		if ( q.response.FileExists(S) )
		{
			q.response.IncludeUHTM(S);
			return;
		}
	}
	q.response.IncludeUHTM(webadmin.Path $ "/" $ file);
}
final function SendHeader( WebAdminQuery q, string Title )
{
	local IQueryHandler handler;
	
	q.response.Subst("page.title", Title);
	q.response.Subst("page.description", "");
	foreach webadmin.handlers(handler)
	{
		handler.decoratePage(q);
	}
	q.response.Subst("messages", webadmin.renderMessages(q));
	if (q.session.getString("privilege.log") != "")
	{
		q.response.Subst("privilege.log", webadmin.renderPrivilegeLog(q));
	}
	IncludeFile(q,"header.inc");
	q.response.SendText("<div id=\"content\"><h2>"$Title$"</h2></div><div class=\"section\">");
}
final function SendFooter( WebAdminQuery q )
{
	IncludeFile(q,"navigation.inc");
	IncludeFile(q,"footer.inc");
	q.response.ClearSubst();
}

final function AddConfigEditbox( WebAdminQuery q, string InfoStr, string CurVal, int MaxLen, string ResponseVar, string Tooltip, optional bool bNoTR )
{
	local string S;
	
	S = "<abbr title=\""$Tooltip$"\"><TD>"$InfoStr$":</TD><TD><input class=\"textbox\" class=\"text\" name=\""$ResponseVar$"\" size=\""$Min(100,MaxLen)$"\" value=\""$CurVal$"\" maxlength=\""$MaxLen$"\"></TD></abbr>";
	if( !bNoTR )
		S = "<TR>"$S$"</TR>";
	q.response.SendText(S);
}
final function AddInLineEditbox( WebAdminQuery q, string CurVal, int MaxLen, string ResponseVar, string Tooltip )
{
	q.response.SendText("<abbr title=\""$Tooltip$"\"><TD><input class=\"textbox\" class=\"text\" name=\""$ResponseVar$"\" size=\""$Min(100,MaxLen)$"\" value=\""$CurVal$"\" maxlength=\""$MaxLen$"\"></TD></abbr>");
}
function handleMapVotes(WebAdminQuery q)
{
	local int i;
	local string S;

	S = q.request.getVariable("edit");
	if( S=="Submit" )
	{
		class'xVotingHandler'.Default.VoteTime = int(q.request.getVariable("VT",string(class'xVotingHandler'.Default.VoteTime)));
		class'xVotingHandler'.Default.MidGameVotePct = float(q.request.getVariable("MV",string(class'xVotingHandler'.Default.MidGameVotePct)));
		class'xVotingHandler'.Default.MapWinPct = float(q.request.getVariable("VP",string(class'xVotingHandler'.Default.MapWinPct)));
		class'xVotingHandler'.Default.MapChangeDelay = float(q.request.getVariable("SD",string(class'xVotingHandler'.Default.MapChangeDelay)));
		class'xVotingHandler'.Default.MaxMapsOnList = int(q.request.getVariable("MXP",string(class'xVotingHandler'.Default.MaxMapsOnList)));
		class'xVotingHandler'.Static.StaticSaveConfig();
		EditSettingLine = -1;
	}
	else if( S=="New" )
	{
		i = class'xVotingHandler'.Default.GameModes.Length;
		class'xVotingHandler'.Default.GameModes.Length = i+1;
		class'xVotingHandler'.Default.GameModes[i].GameName = "Killing Floor";
		class'xVotingHandler'.Default.GameModes[i].GameShortName = "KF";
		class'xVotingHandler'.Default.GameModes[i].GameClass = "KFGameContent.KFGameInfo_Survival";
		EditSettingLine = i;
		class'xVotingHandler'.Static.StaticSaveConfig();
	}
	else if( S=="Save" )
	{
		if( EditSettingLine>=0 && EditSettingLine<class'xVotingHandler'.Default.GameModes.Length )
		{
			i = EditSettingLine;
			class'xVotingHandler'.Default.GameModes[i].GameName = q.request.getVariable("GN",class'xVotingHandler'.Default.GameModes[i].GameName);
			class'xVotingHandler'.Default.GameModes[i].GameShortName = q.request.getVariable("GS",class'xVotingHandler'.Default.GameModes[i].GameName);
			class'xVotingHandler'.Default.GameModes[i].GameClass = q.request.getVariable("GC",class'xVotingHandler'.Default.GameModes[i].GameName);
			class'xVotingHandler'.Default.GameModes[i].Mutators = q.request.getVariable("MM",class'xVotingHandler'.Default.GameModes[i].GameName);
			class'xVotingHandler'.Default.GameModes[i].Options = q.request.getVariable("OP",class'xVotingHandler'.Default.GameModes[i].GameName);
			class'xVotingHandler'.Default.GameModes[i].Prefix = q.request.getVariable("PF",class'xVotingHandler'.Default.GameModes[i].GameName);
			class'xVotingHandler'.Static.StaticSaveConfig();
		}
		EditSettingLine = -1;
	}
	else
	{
		for( i=0; i<class'xVotingHandler'.Default.GameModes.Length; ++i )
		{
			S = q.request.getVariable("edit"$i);
			if( S=="Delete" )
			{
				class'xVotingHandler'.Default.GameModes.Remove(i,1);
				class'xVotingHandler'.Static.StaticSaveConfig();
				EditSettingLine = -1;
				break;
			}
			else if( S=="Edit" )
			{
				EditSettingLine = i;
				break;
			}
		}
	}

	SendHeader(q,"X - Mapvote");
	q.response.SendText("<form method=\"post\" action=\""$webadmin.Path$MapVoterURL$"\"><table id=\"settings\" class=\"grid\">");
	q.response.SendText("<thead><tr><th colspan=2>Mapvote settings</th></tr></thead><tbody>");
	AddConfigEditbox(q,"Mapvote time",string(class'xVotingHandler'.Default.VoteTime),8,"VT","Time in seconds people have to cast mapvote");
	AddConfigEditbox(q,"Mid-Game vote pct",string(class'xVotingHandler'.Default.MidGameVotePct),12,"MV","Number of people in percent needs to vote to make game initiate mid-game mapvote");
	AddConfigEditbox(q,"Map win vote pct",string(class'xVotingHandler'.Default.MapWinPct),12,"VP","Number of people in percent needs to vote for same map for mapvote instantly switch to it");
	AddConfigEditbox(q,"Map switch delay",string(class'xVotingHandler'.Default.MapChangeDelay),12,"SD","Time in seconds delay after a mapvote has passed, when server actually switches map");
	AddConfigEditbox(q,"Max Maps On List",string(class'xVotingHandler'.Default.MaxMapsOnList),8,"MXP","Maximum maps that should show on mapvote GUI before starting to remove random ones (0 = no limit)");
	q.response.SendText("<tr><td></td><td><input class=\"button\" type=\"submit\" name=\"edit\" value=\"Submit\"></td></tr>");
	q.response.SendText("</tbody></table></form>");
	q.response.SendText("<form method=\"post\" action=\""$webadmin.Path$MapVoterURL$"\"><table id=\"settings\" class=\"grid\">");
	q.response.SendText("<thead><tr><th colspan=7>Mapvote game modes</th></tr></thead><tbody>");
	q.response.SendText("<tr><th>Game Name</th><th>Game Short Name</th><th>Game Class</th><th>Mutators</th><th>Options</th><th>Map Prefix</th><th></th></tr>");
	for( i=0; i<class'xVotingHandler'.Default.GameModes.Length; ++i )
	{
		if( EditSettingLine==i )
		{
			q.response.SendText("<tr>",false);
			AddInLineEditbox(q,class'xVotingHandler'.Default.GameModes[i].GameName,48,"GN","Game type long display name");
			AddInLineEditbox(q,class'xVotingHandler'.Default.GameModes[i].GameShortName,12,"GS","Game type short display name");
			AddInLineEditbox(q,class'xVotingHandler'.Default.GameModes[i].GameClass,38,"GC","Game type class name to run");
			AddInLineEditbox(q,class'xVotingHandler'.Default.GameModes[i].Mutators,120,"MM","List of mutators to run along with this game option (separated with commas)");
			AddInLineEditbox(q,class'xVotingHandler'.Default.GameModes[i].Options,100,"OP","List of options to run along with this game option (separated with question mark)");
			AddInLineEditbox(q,class'xVotingHandler'.Default.GameModes[i].Prefix,16,"PF","Maps prefix to filter out maps not wanted for this game mode");
			q.response.SendText("</td><td><input class=\"button\" type=\"submit\" name=\"edit\" value=\"Save\"><input class=\"button\" type=\"submit\" name=\"edit"$i$"\" value=\"Delete\"></td></tr>");
		}
		else
		{
			q.response.SendText("<tr><td>"$class'xVotingHandler'.Default.GameModes[i].GameName$
								"</td><td>"$class'xVotingHandler'.Default.GameModes[i].GameShortName$
								"</td><td>"$class'xVotingHandler'.Default.GameModes[i].GameClass$
								"</td><td>"$class'xVotingHandler'.Default.GameModes[i].Mutators$
								"</td><td>"$class'xVotingHandler'.Default.GameModes[i].Options$
								"</td><td>"$class'xVotingHandler'.Default.GameModes[i].Prefix$
								"</td><td><input class=\"button\" type=\"submit\" name=\"edit"$i$"\" value=\"Edit\"><input class=\"button\" type=\"submit\" name=\"edit"$i$"\" value=\"Delete\"></td></tr>");
		}
	}
	q.response.SendText("<tr><td><input class=\"button\" type=\"submit\" name=\"edit\" value=\"New\"></td></tr>");
	q.response.SendText("</tbody></table></form>");
	q.response.SendText("</div></body></html>");
	SendFooter(q);
}

function bool producesXhtml()
{
	return true;
}
function bool unhandledQuery(WebAdminQuery q);
function decoratePage(WebAdminQuery q);

defaultproperties
{
	MapVoterURL="/settings/xMapVoter"
	EditSettingLine=-1
}