Class ExtXMLOutput extends FileWriter implements(ExtStatWriter);

var transient string Intendent;
var transient array<string> StackedSect;

event PreBeginPlay();

final function DumpXML( ExtPerkManager M )
{
	OpenFile(class'OnlineSubsystem'.Static.UniqueNetIdToString(M.PRIOwner.UniqueId),FWFT_Stats,".xml",false);
	M.OutputXML(Self);
	CloseFile();
	ResetFile();
}

function WriteValue( string Key, string Value )
{
	Logf(Intendent$"<"$Key$">"$Value$"</"$Key$">");
}
function StartIntendent( string Section, optional string Key, optional string Value )
{
	if( Key!="" )
		Logf(Intendent$"-<"$Section$" "$Key$"=\""$Value$"\">");
	else Logf(Intendent$"-<"$Section$">");
	Intendent $= Chr(9);
	StackedSect.AddItem(Section);
}
function EndIntendent()
{
	Intendent = Left(Intendent,Len(Intendent)-1);
	Logf(Intendent$"</"$StackedSect[StackedSect.Length-1]$">");
	StackedSect.Remove(StackedSect.Length-1,1);
}
function ResetFile()
{
	Intendent = "";
	StackedSect.Length = 0;
}

defaultproperties
{
	bFlushEachWrite=false
}