Class ExtWebApp extends Object implements(IQueryHandler);

var WebAdmin webadmin;
var string ExtWebURL;
var int EditPageIndex;
var ExtWebAdmin_UI ExtAdminUI;
var ServerExtMut MyMutator;

function cleanup()
{
	webadmin = None;
	MyMutator = None;
	if( ExtAdminUI!=None )
	{
		ExtAdminUI.Cleanup();
		ExtAdminUI = None;
	}
}
function init(WebAdmin webapp)
{
	webadmin = webapp;
}
function registerMenuItems(WebAdminMenu menu)
{
	menu.addMenu(ExtWebURL, "ExtServer Mod", self, "Modify settings of Extended Server Mod.", -44);
}
function bool handleQuery(WebAdminQuery q)
{
	switch (q.request.URI)
	{
		case ExtWebURL:
			handleExtMod(q);
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

final function AddConfigEditbox( WebAdminQuery q, string InfoStr, string CurVal, int MaxLen, string ResponseVar, string Tooltip, optional bool bSkipTrail )
{
	local string S;
	
	S = "<TR><TD><abbr title=\""$Tooltip$"\">"$InfoStr$":</abbr></TD><TD><input class=\"textbox\" class=\"text\" name=\""$ResponseVar$"\" value=\""$CurVal$"\"></TD>";
	if( !bSkipTrail )
		S $= "</TR>";
	q.response.SendText(S);
}
final function AddConfigCheckbox( WebAdminQuery q, string InfoStr, bool bCur, string ResponseVar, string Tooltip )
{
	local string S;
	
	S = bCur ? " checked" : "";
	S = "<TR><TD><abbr title=\""$Tooltip$"\">"$InfoStr$":</abbr></TD><TD><input type=\"checkbox\" name=\""$ResponseVar$"\" value=\"1\" "$S$"></TD></TR>";
	q.response.SendText(S);
}
final function AddConfigTextbox( WebAdminQuery q, string InfoStr, string CurVal, int Rows, string ResponseVar, string Tooltip )
{
	local string S;
	
	S = "<TR><TD><abbr title=\""$Tooltip$"\">"$InfoStr$":</abbr></TD><TD>";
	S $= "<textarea name=\""$ResponseVar$"\" rows=\""$Rows$"\" cols=\"80\">"$CurVal$"</textarea></TD></TR>";
	q.response.SendText(S);
}

function handleExtMod(WebAdminQuery q)
{
	local int i,j,z;
	local string S;
	local delegate<ExtWebAdmin_UI.OnGetValue> GetV;
	local delegate<ExtWebAdmin_UI.OnSetValue> SetV;
	local bool bEditArray;

	if( ExtAdminUI==None )
	{
		ExtAdminUI = new (None) class'ExtWebAdmin_UI';
		MyMutator.InitWebAdmin(ExtAdminUI);
	}

	// First check if user is trying to get to another page.
	S = q.request.getVariable("GoToPage");
	if( S!="" )
	{
		if( S=="Main Menu" )
			EditPageIndex = -1;
		else EditPageIndex = ExtAdminUI.ConfigList.Find('PageName',S);
	}

	if( EditPageIndex<0 || EditPageIndex>=ExtAdminUI.ConfigList.Length )
	{
		// Show main links page.
		SendHeader(q,"Ext Server Links page");
		q.response.SendText("<table id=\"settings\" class=\"grid\"><thead><tr><th>Links</th></tr></thead><tbody>");
		for( i=0; i<ExtAdminUI.ConfigList.Length; ++i )
			q.response.SendText("<tr><td><form action=\""$webadmin.Path$ExtWebURL$"\"><input class=\"button\" name=\"GoToPage\" type=\"submit\" value=\""$ExtAdminUI.ConfigList[i].PageName$"\"></form></td></tr>");
		q.response.SendText("</tbody></table></div></div></body></html>");
	}
	else
	{
		S = q.request.getVariable("edit"$EditPageIndex);
		bEditArray = false;
		if( S=="Submit" )
		{
			// Read setting values.
			for( i=0; i<ExtAdminUI.ConfigList[EditPageIndex].Configs.Length; ++i )
			{
				S = q.request.getVariable("PR"$i,"#NULL");
				if( S!="#NULL" )
				{
					SetV = ExtAdminUI.ConfigList[EditPageIndex].SetValue;
					SetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,0,S);
				}
				else if( ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropType==1 ) // Checkboxes return nothing if unchecked.
				{
					SetV = ExtAdminUI.ConfigList[EditPageIndex].SetValue;
					SetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,0,"0");
				}
			}
		}
		else if( Left(S,5)=="Edit " )
		{
			i = ExtAdminUI.ConfigList[EditPageIndex].Configs.Find('UIName',Mid(S,5));
			if( i!=-1 && ExtAdminUI.ConfigList[EditPageIndex].Configs[i].NumElements==-1 ) // Check if valid.
			{
				// Edit dynamic array.
				bEditArray = true;
			}
		}
		else if( Left(S,7)=="Submit " )
		{
			i = ExtAdminUI.ConfigList[EditPageIndex].Configs.Find('UIName',Mid(S,7));
			if( i!=-1 && ExtAdminUI.ConfigList[EditPageIndex].Configs[i].NumElements==-1 ) // Check if valid.
			{
				// Submitted dynamic array values.
				GetV = ExtAdminUI.ConfigList[EditPageIndex].GetValue;
				SetV = ExtAdminUI.ConfigList[EditPageIndex].SetValue;
				z = int(GetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,-1));
				
				for( j=z; j>=0; --j )
				{
					if( q.request.getVariable("DEL"$j)=="1" )
						SetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,j,"#DELETE");
					else
					{
						S = q.request.getVariable("PR"$j,"New Line");
						if( S!="New Line" )
							SetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,j,S);
					}
				}
			}
		}

		// Show settings page
		SendHeader(q,ExtAdminUI.ConfigList[EditPageIndex].PageName$" ("$PathName(ExtAdminUI.ConfigList[EditPageIndex].ObjClass)$")");
		q.response.SendText("<form method=\"post\" action=\""$webadmin.Path$ExtWebURL$"\"><table id=\"settings\" class=\"grid\">");

		if( bEditArray )
		{
			q.response.SendText("<table id=\"settings\" class=\"grid\"><thead><tr><th><abbr title=\""$ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIDesc$"\">Edit Array "$ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName$"</abbr></th><th></th><th>Delete Line</th></tr></thead><tbody>");
			
			GetV = ExtAdminUI.ConfigList[EditPageIndex].GetValue;
			z = int(GetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,-1));

			for( j=0; j<=z; ++j )
			{
				if( j<z )
					S = GetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,j);
				else S = "New Line";
				switch( ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropType )
				{
				case 0: // int
					AddConfigEditbox(q,"["$j$"]",S,8,"PR"$j,"",true);
					if( j<z )
						q.response.SendText("<TD><input type=\"checkbox\" name=\"DEL"$j$"\" value=\"1\" "$S$"></TD></TR>");
					else q.response.SendText("<TD></TD></TR>");
					break;
				case 2: // string
					AddConfigEditbox(q,"["$j$"]",S,80,"PR"$j,"",true);
					if( j<z )
						q.response.SendText("<TD><input type=\"checkbox\" name=\"DEL"$j$"\" value=\"1\" "$S$"></TD></TR>");
					else q.response.SendText("<TD></TD></TR>");
					break;
				}
			}
			
			q.response.SendText("<tr><td></td><td><input class=\"button\" type=\"submit\" name=\"edit"$EditPageIndex$"\" value=\"Submit "$ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName$"\"></td></tr></form>");
		}
		else
		{
			q.response.SendText("<table id=\"settings\" class=\"grid\"><thead><tr><th>Settings</th></tr></thead><tbody>");
			for( i=0; i<ExtAdminUI.ConfigList[EditPageIndex].Configs.Length; ++i )
			{
				if( ExtAdminUI.ConfigList[EditPageIndex].Configs[i].NumElements==-1 ) // Dynamic array.
				{
					GetV = ExtAdminUI.ConfigList[EditPageIndex].GetValue;
					j = int(GetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,-1));
					q.response.SendText("<TR><TD><abbr title=\""$ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIDesc$"\">"$ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName$"["$j$"]:</abbr></TD><TD><input class=\"button\" type=\"submit\" name=\"edit"$EditPageIndex$"\" value=\"Edit "$ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName$"\"></TD></TR>");
				}
				else
				{
					GetV = ExtAdminUI.ConfigList[EditPageIndex].GetValue;
					S = GetV(ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropName,0);
					switch( ExtAdminUI.ConfigList[EditPageIndex].Configs[i].PropType )
					{
					case 0: // Int
						AddConfigEditbox(q,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName,S,8,"PR"$i,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIDesc);
						break;
					case 1: // Bool
						AddConfigCheckbox(q,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName,bool(S),"PR"$i,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIDesc);
						break;
					case 2: // String
						AddConfigEditbox(q,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName,S,80,"PR"$i,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIDesc);
						break;
					case 3: // Text field
						AddConfigTextbox(q,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIName,S,25,"PR"$i,ExtAdminUI.ConfigList[EditPageIndex].Configs[i].UIDesc);
						break;
					}
				}
			}
			
			// Submit button
			q.response.SendText("<tr><td></td><td><input class=\"button\" type=\"submit\" name=\"edit"$EditPageIndex$"\" value=\"Submit\"></td></tr></form>");
		}

		// Return to main menu button.
		q.response.SendText("<tr><td><form action=\""$webadmin.Path$ExtWebURL$"\"><input class=\"button\" name=\"GoToPage\" type=\"submit\" value=\"Main Menu\"></form></td></tr>");
		q.response.SendText("</tbody></table></div></div></body></html>");
	}
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
	ExtWebURL="/settings/ExtServerMod"
	EditPageIndex=-1
}