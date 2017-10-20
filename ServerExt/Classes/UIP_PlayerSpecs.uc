Class UIP_PlayerSpecs extends KFGUI_MultiComponent;

struct FPageExtraInfo
{
	var array<UniqueNetId> UserID;
};
var FPageExtraInfo ExtraInfo[3];
var KFGUI_ColumnList PlayersList,TopPlayers[3];
var KFGUI_SwitchComponent MultiPager;
var int CurrentPageIndex;
var byte CurrentPageStatus[3];
var KFGUI_Button PreviousButton;
var bool bDownloadingPage;

function InitMenu()
{
	PreviousButton = KFGUI_Button(FindComponentID('Init'));
	PreviousButton.bIsHighlighted = true;
	PlayersList = KFGUI_ColumnList(FindComponentID('Players'));
	TopPlayers[0] = KFGUI_ColumnList(FindComponentID('PlayTimes'));
	TopPlayers[1] = KFGUI_ColumnList(FindComponentID('Kills'));
	TopPlayers[2] = KFGUI_ColumnList(FindComponentID('EXP'));
	MultiPager = KFGUI_SwitchComponent(FindComponentID('Pager'));
	Super.InitMenu();
}
function ShowMenu()
{
	Super.ShowMenu();
	SetTimer(2,true);
	Timer();
}
function CloseMenu()
{
	Super.CloseMenu();
	SetTimer(0,false);
}

function ReceivedStat( byte ListNum, bool bFinal, string N, UniqueNetId UserID, int V )
{
	local int i;

	if( bFinal )
	{
		CurrentPageStatus[ListNum] = 1;
		bDownloadingPage = false;
	}
	else
	{
		i = ExtraInfo[ListNum].UserID.Length;
		TopPlayers[ListNum].AddLine((i+1)$"\n"$N$"\n"$(ListNum==0 ? FormatTimeSMH(V) : FormatInteger(V)),i,MakeSortStr(i)$"\n"$N$"\n"$MakeSortStr(V));
		ExtraInfo[ListNum].UserID.AddItem(UserID);
	}
}

function Timer()
{
	if( CurrentPageIndex==0 )
		UpdatePlayerList(PlayersList,GetPlayer().WorldInfo.GRI);
	else if( CurrentPageStatus[CurrentPageIndex-1]==0 && !bDownloadingPage )
	{
		bDownloadingPage = true;
		ExtPlayerController(GetPlayer()).OnClientReceiveStat = ReceivedStat;
		ExtPlayerController(GetPlayer()).ServerRequestStats(CurrentPageIndex-1);
	}
}

static final function UpdatePlayerList( KFGUI_ColumnList PL, GameReplicationInfo GRI )
{
	local int i;
	local ExtPlayerReplicationInfo PRI;
	local string S;

	PL.EmptyList();
	if( GRI==None )
		return;
	for( i=0; i<GRI.PRIArray.Length; ++i )
	{
		PRI = ExtPlayerReplicationInfo(GRI.PRIArray[i]);
		if( PRI==None || PRI.bHiddenUser )
			continue;
		S = PRI.PlayerName;
		if( PRI.ShowAdminName() )
			S $= " ("$PRI.GetAdminName()$")";
		PL.AddLine(S$"\n"$FormatInteger(PRI.RepKills)$"\n"$FormatInteger(PRI.RepEXP)$"\n"$FormatTimeSMH(PRI.RepPlayTime),PRI.PlayerID,S$"\n"$MakeSortStr(PRI.RepKills)$"\n"$MakeSortStr(PRI.RepEXP)$"\n"$MakeSortStr(PRI.RepPlayTime));
	}
}

static final function string FormatTimeSMH( float Sec )
{
	local int Seconds,Minutes,Hours,Days;
	local string S;

	Sec = Abs(Sec);
	Seconds = int(Sec);

	Minutes = Seconds/60;
	Seconds-=(Minutes*60);

	Hours = Minutes/60;
	Minutes-=(Hours*60);
	
	Days = Hours/24;
	Hours-=(Days*24);

	S = Hours$":"$(Minutes<10 ? "0"$Minutes : string(Minutes))$":"$(Seconds<10 ? "0"$Seconds : string(Seconds));
	if( Days>0 )
		S = Days$"d "$S;
	return S;
}
static final function string FormatInteger( int Val )
{
	local string S,O;

	S = string(Val);
	Val = Len(S);
	if( Val<=3 )
		return S;
	while( Val>3 )
	{
		if( O=="" )
			O = Right(S,3);
		else O = Right(S,3)$","$O;
		S = Left(S,Val-3);
		Val-=3;
	}
	if( Val>0 )
		O = S$","$O;
	return O;
}

function ButtonClicked( KFGUI_Button Sender )
{
	if( CurrentPageIndex==Sender.IDValue )
		return;

	if( PreviousButton!=None )
		PreviousButton.bIsHighlighted = false;
	Sender.bIsHighlighted = true;
	PreviousButton = Sender;
	CurrentPageIndex = Sender.IDValue;
	MultiPager.SelectPageIndex(CurrentPageIndex);
	Timer();
}

function SelectedRow( KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick )
{
	local UniqueNetId Res;
	local PlayerReplicationInfo PRI;

	if( bRight || bDblClick )
	{
		if( CurrentPageIndex==0 )
		{
			foreach GetPlayer().WorldInfo.GRI.PRIArray(PRI)
				if( PRI.PlayerID==Item.Value )
					break;
			if( PRI==None || PRI.PlayerID!=Item.Value || PRI.bBot )
				return;
			Res = PRI.UniqueId;
		}
		else Res = ExtraInfo[CurrentPageIndex-1].UserID[Item.Value];

		OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ShowProfileUI(0,,Res);
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_Button Name=B_ShowStats
		ButtonText="Show Stats"
		Tooltip="Show the stats of the current players in server"
		XPosition=0.05
		YPosition=0.05
		XSize=0.1
		YSize=0.045
		IDValue=0
		ID="Init"
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=B_ShowTopTime
		ButtonText="Top playtime"
		Tooltip="Show the top playtime by players in all-time from this server"
		XPosition=0.35
		YPosition=0.05
		XSize=0.1
		YSize=0.045
		IDValue=1
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=B_ShowTopKills
		ButtonText="Top kills"
		Tooltip="Show the top kills by players in all-time from this server"
		XPosition=0.6
		YPosition=0.05
		XSize=0.1
		YSize=0.045
		IDValue=2
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=B_ShowTopEXP
		ButtonText="Top EXP"
		Tooltip="Show the top EXP by players in all-time from this server"
		XPosition=0.85
		YPosition=0.05
		XSize=0.1
		YSize=0.045
		IDValue=3
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(B_ShowStats)
	Components.Add(B_ShowTopTime)
	Components.Add(B_ShowTopKills)
	Components.Add(B_ShowTopEXP)

	Begin Object Class=KFGUI_SwitchComponent Name=MultiPager
		XPosition=0.05
		YPosition=0.12
		XSize=0.9
		YSize=0.85
		ID="Pager"

		Begin Object Class=KFGUI_ColumnList Name=PlayerList
			ID="Players"
			Columns.Add((Text="Player",Width=0.55))
			Columns.Add((Text="Total Kills",Width=0.15))
			Columns.Add((Text="Total EXP",Width=0.15))
			Columns.Add((Text="Total PlayTime",Width=0.15))
			OnSelectedRow=SelectedRow
		End Object
		Begin Object Class=KFGUI_ColumnList Name=TopPlaytimes
			ID="PlayTimes"
			Columns.Add((Text="#",Width=0.05))
			Columns.Add((Text="Player",Width=0.7))
			Columns.Add((Text="Total PlayTime",Width=0.25))
			OnSelectedRow=SelectedRow
		End Object
		Begin Object Class=KFGUI_ColumnList Name=TopKills
			ID="Kills"
			Columns.Add((Text="#",Width=0.05))
			Columns.Add((Text="Player",Width=0.7))
			Columns.Add((Text="Total Kills",Width=0.25))
			OnSelectedRow=SelectedRow
		End Object
		Begin Object Class=KFGUI_ColumnList Name=TopExp
			ID="EXP"
			Columns.Add((Text="#",Width=0.05))
			Columns.Add((Text="Player",Width=0.7))
			Columns.Add((Text="Total EXP",Width=0.25))
			OnSelectedRow=SelectedRow
		End Object
		Components.Add(PlayerList)
		Components.Add(TopPlaytimes)
		Components.Add(TopKills)
		Components.Add(TopExp)
	End Object
	Components.Add(MultiPager)
}