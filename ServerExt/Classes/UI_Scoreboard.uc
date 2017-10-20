Class UI_Scoreboard extends KFGUI_Page;

var editinline export KFGUI_RightClickMenu PlayerContext;
var KFGUI_List PlayersList;
var() float ScoreboardSpacing;
var color SBTextColor;
var Texture2D HealthIcon;
var KFGameReplicationInfo KFGRI;
var array<ExtPlayerReplicationInfo> PRIList;
var ExtPlayerReplicationInfo RightClickPlayer;
var int PlayerIndex;
var Font SBFont;
var transient float SBFontSize,CashXPos,KillsXPos,AssistXPos,PingXPos,SBFontHeight;
var transient int InitAdminSize;

var KFGUI_Tooltip ToolTipItem;

var transient bool bHasSelectedPlayer,bMeAdmin,bShowSpectatorsOnly;

function InitMenu()
{
	Super.InitMenu();
	HealthIcon = Texture2D(DynamicLoadObject("UI_Objective_Tex.UI_Obj_Healing_Loc",class'Texture2D'));
	PlayersList = KFGUI_List(FindComponentID('PlayerList'));
}
function ShowMenu()
{
	local ExtPlayerController PC;
	local int i;
	local bool bAdmin;

	Owner.bAbsorbInput = false;
	PC = ExtPlayerController(GetPlayer());
	bAdmin = PC!=None && (PC.WorldInfo.NetMode!=NM_Client || (PC.PlayerReplicationInfo!=None && PC.PlayerReplicationInfo.bAdmin));
	if( PC!=None && (InitAdminSize!=PC.AdminCommands.Length || !bAdmin) )
	{
		InitAdminSize = (bAdmin ? PC.AdminCommands.Length : 0);
		PlayerContext.ItemRows.Length = 4+InitAdminSize;
		for( i=0; i<InitAdminSize; ++i )
			PlayerContext.ItemRows[4+i].Text = PC.AdminCommands[i].Info;
	}
}
function CloseMenu()
{
	Owner.bAbsorbInput = true;
	KFGRI = None;
	PRIList.Length = 0;
	RightClickPlayer = None;
	bHasSelectedPlayer = false;
	bShowSpectatorsOnly = false;
}

function bool InOrder( PlayerReplicationInfo A, PlayerReplicationInfo B )
{
	if( A.bOnlySpectator!=B.bOnlySpectator )
		return B.bOnlySpectator;
	if( A.Kills!=B.Kills )
		return (A.Kills<B.Kills);
	if( A.Score!=B.Score )
		return (A.Score<B.Score);
	return (A.PlayerName<B.PlayerName);
}
function DrawMenu()
{
	local PlayerController PC;
	local float XPos,YPos,XScale,YHeight,Y,FontScalar,BoxHeight,XL,YL;
	local int i,j,NumSpec,NumPlayer,NumAlivePlayer;
	local PlayerReplicationInfo PRI;
	local ExtPlayerReplicationInfo KPRI;
	local byte DefFont;
	
	PC = GetPlayer();
	if( KFGRI==None )
	{
		KFGRI = KFGameReplicationInfo(PC.WorldInfo.GRI);
		if( KFGRI==None )
			return;
	}
	bMeAdmin = (PC.WorldInfo.NetMode!=NM_Client || (ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)!=None && ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).AdminType<=1));

	// Sort player list.
	for( i=(KFGRI.PRIArray.Length-1); i>0; --i )
	{
		for( j=i-1; j>=0; --j )
			if( !InOrder(KFGRI.PRIArray[i],KFGRI.PRIArray[j]) )
			{
				PRI = KFGRI.PRIArray[i];
				KFGRI.PRIArray[i] = KFGRI.PRIArray[j];
				KFGRI.PRIArray[j] = PRI;
			}
	}
	
	// Check players.
	PlayerIndex = -1;
	NumPlayer = 0;
	for( i=(KFGRI.PRIArray.Length-1); i>=0; --i )
	{
		KPRI = ExtPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if( KPRI==None || KPRI.bHiddenUser )
			continue;
		if( KPRI.bOnlySpectator )
		{
			++NumSpec;
			continue;
		}
		if( KPRI.PlayerHealth>0 && KPRI.PlayerHealthPercent>0 && KPRI.GetTeamNum()==0 )
			++NumAlivePlayer;
		++NumPlayer;
	}
	
	PRIList.Length = (bShowSpectatorsOnly ? NumSpec : NumPlayer);
	j = PRIList.Length;
	for( i=(KFGRI.PRIArray.Length-1); i>=0; --i )
	{
		KPRI = ExtPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if( KPRI!=None && bShowSpectatorsOnly==KPRI.bOnlySpectator )
		{
			PRIList[--j] = KPRI;
			if( KPRI==PC.PlayerReplicationInfo )
				PlayerIndex = j;
		}
	}

	// Header font info.
	DefFont = Owner.CurrentStyle.DefaultFontSize;
	Canvas.Font = Owner.CurrentStyle.PickFont(DefFont,FontScalar);
	YL = Owner.CurrentStyle.DefaultHeight;
	YHeight = YL*5.f;
	
	// Draw header.
	if( Canvas.ClipX<1000 )
	{
		XPos = Canvas.ClipX*0.2;
		XScale = Canvas.ClipX*0.6;
	}
	else
	{
		XPos = Canvas.ClipX*0.3;
		XScale = Canvas.ClipX*0.4;
	}
	YPos = Canvas.ClipY*0.05;
	Canvas.SetDrawColor(128,32,32,FrameOpacity);
	Owner.CurrentStyle.DrawRectBox(XPos,YPos,XScale*0.75,YHeight,26,1);

	Canvas.DrawColor = SBTextColor;

	Y = YPos+10;
	Canvas.SetPos(XPos+26,Y);
	Canvas.DrawText(PC.WorldInfo.Title,,FontScalar,FontScalar);

	Y+=YL;
	Canvas.SetPos(XPos+26,Y);
	Canvas.DrawText(KFGRI.ServerName,,FontScalar,FontScalar);

	if( KFGRI.GameClass!=None )
	{
		Y+=YL;
		Canvas.SetPos(XPos+26,Y);
		Canvas.DrawText(KFGRI.GameClass.Default.GameName$" - "$Class'KFCommon_LocalizedStrings'.Static.GetDifficultyString(KFGRI.GameDifficulty),,FontScalar,FontScalar);
	}

	Y+=YL;
	Canvas.SetPos(XPos+26,Y);
	Canvas.DrawText("Time: "$FormatTimeSM(KFGRI.ElapsedTime)$" | Players: "$NumPlayer$" | Alive: "$NumAlivePlayer$" | Spectators: "$NumSpec,,FontScalar,FontScalar);
	
	XPos += XScale*0.75-1;
	XScale *= 0.25;
	Canvas.SetDrawColor(18,8,8,FrameOpacity);
	Owner.CurrentStyle.DrawRectBox(XPos,YPos,XScale,YHeight,26);
	Canvas.DrawColor = SBTextColor;
	Canvas.Font = Owner.CurrentStyle.PickFont(DefFont+3,FontScalar);
	Canvas.TextSize("A",XL,YL,FontScalar,FontScalar);
	Y = YPos+4;
	DrawCenteredText("WAVE",XPos+XScale*0.5,Y,FontScalar);
	Y += YL;
	DrawCenteredText(KFGRI.WaveNum$"/"$(KFGRI.WaveMax-1),XPos+XScale*0.5,Y,FontScalar*1.1);
	
	// Scoreboard title line.
	Canvas.Font = Owner.CurrentStyle.PickFont(DefFont,FontScalar);
	YL = Owner.CurrentStyle.DefaultHeight;
	if( Canvas.ClipX<1000 )
	{
		XPos = Canvas.ClipX*0.175;
		XScale = Canvas.ClipX*0.65;
	}
	else
	{
		XPos = Canvas.ClipX*0.25;
		XScale = Canvas.ClipX*0.5;
	}
	YPos += YHeight*1.05;
	YHeight = YL;
	if( bShowSpectatorsOnly )
		Canvas.SetDrawColor(32,32,128,FrameOpacity);
	else Canvas.SetDrawColor(128,32,32,FrameOpacity);
	Owner.CurrentStyle.DrawRectBox(XPos,YPos,XScale,YHeight,16,2);
	
	// Calc X offsets
	CashXPos = XScale*0.5;
	KillsXPos = XScale*0.7;
	AssistXPos = XScale*0.8;
	PingXPos = XScale*0.9;
	
	// Header texts
	Canvas.DrawColor = SBTextColor;
	Y = YPos+4;
	Canvas.SetPos(XPos+18,Y);
	Canvas.DrawText("PLAYER",,FontScalar,FontScalar);
	if( !bShowSpectatorsOnly )
	{
		Canvas.SetPos(XPos+CashXPos,Y);
		Canvas.DrawText("DOSH",,FontScalar,FontScalar);
		DrawCenteredText("KILLS",XPos+KillsXPos,Y,FontScalar);
		DrawCenteredText("ASSISTS",XPos+AssistXPos,Y,FontScalar);
	}
	DrawCenteredText("PING",XPos+PingXPos,Y,FontScalar);

	// Check how many players to draw.
	YPos+=(YHeight-1);
	YHeight = (Canvas.ClipY*0.95) - YPos;
	i = DefFont+2;
	while( i>0 )
	{
		Canvas.Font = Owner.CurrentStyle.PickFont(i,SBFontSize);
		Canvas.TextSize("A",XL,SBFontHeight,SBFontSize,SBFontSize);
		BoxHeight = SBFontHeight*2.f+ScoreboardSpacing;
		if( (BoxHeight*PRIList.Length)<=YHeight )
			break;
		--i;
	}
	
	// Scoreboard background.
	Canvas.SetDrawColor(18,8,8,FrameOpacity);
	Owner.CurrentStyle.DrawRectBox(XPos,YPos,XScale,YHeight,16);
	
	// Setup listing.
	PlayersList.XPosition = (XPos+8.f) / InputPos[2];
	PlayersList.YPosition = (YPos+8.f) / InputPos[3];
	PlayersList.XSize = (XScale-16.f) / InputPos[2];
	PlayersList.YSize = (YHeight-16.f) / InputPos[3];
	PlayersList.ListItemsPerPage = YHeight/BoxHeight;
	PlayersList.ChangeListSize(PRIList.Length);
	SBFont = Canvas.Font;
}

final function Texture2D FindAvatar( UniqueNetId ClientID )
{
	local string S;
	
	S = KFPlayerController(GetPlayer()).GetSteamAvatar(ClientID);
	if( S=="" )
		return None;
	return Texture2D(FindObject(S,class'Texture2D'));
}

final function DrawCenteredText( string S, float X, float Y, optional float Scale=1.f )
{
	local float XL,YL;

	Canvas.TextSize(S,XL,YL);
	Canvas.SetPos(X-(XL*Scale*0.5),Y);
	Canvas.DrawText(S,,Scale,Scale);
}
static final function string FormatTimeSM( float Sec )
{
	local int Seconds,Minutes;

	Sec = Abs(Sec);
	Seconds = int(Sec);
	Minutes = Seconds/60;
	Seconds-=Minutes*60;

	return Minutes$":"$(Seconds<10 ? "0"$Seconds : string(Seconds));
}

function DrawPlayerEntry( Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus )
{
	local ExtPlayerReplicationInfo PRI;
	local float XPos,YPos,XL,YL;
	local string S;
	
	if( Index==0 )
	{
		// Setup font info.
		C.Font = SBFont;
	}
	PRI = PRIList[Index];
	
	bFocus = bFocus || (bHasSelectedPlayer && RightClickPlayer==PRI);
	
	// Draw name entry background.
	if( PRI.bOnlySpectator ) // Spectator - blue.
	{
		if( bFocus )
			C.SetDrawColor(86,86,212,FrameOpacity);
		else C.SetDrawColor(48,48,164,FrameOpacity);
	}
	else if( PRI.Team==None ) // Unteamed - Grey.
	{
		if( bFocus )
			C.SetDrawColor(86,86,86,FrameOpacity);
		else C.SetDrawColor(48,48,48,FrameOpacity);
	}
	else
	{
		switch( PRI.Team.TeamIndex )
		{
		case 0: // Humans - Red.
			if( bFocus )
				C.SetDrawColor(160,48,48,FrameOpacity);
			else C.SetDrawColor(128,32,32,FrameOpacity);
			break;
		default: // Rest - Green.
			if( bFocus )
				C.SetDrawColor(48,160,48,FrameOpacity);
			else C.SetDrawColor(32,128,32,FrameOpacity);
		}
	}
	if( PRI.PlayerHealth<=0 || PRI.PlayerHealthPercent<=0 )
		C.DrawColor = C.DrawColor*0.6;
	Owner.CurrentStyle.DrawRectBox(0.f,YOffset,Width,Height-ScoreboardSpacing,10);
	Height-=ScoreboardSpacing;
	
	// Draw health bg.
	if( !bShowSpectatorsOnly )
	{
		if( PRI.PlayerHealth<30 || PRI.PlayerHealthPercent<=0 ) // Chose color based on health.
			C.SetDrawColor(220,32,32,255);
		else if( PRI.PlayerHealth<70 )
			C.SetDrawColor(220,220,32,255);
		else C.SetDrawColor(32,225,32,255);
		Owner.CurrentStyle.DrawRectBox(6.f,YOffset+6,Height-12,Height-12,5);
	}

	// Avatar
	if( PRI.Avatar!=None )
	{
		C.SetDrawColor(255,255,255,255);
		C.SetPos(Height+4,YOffset+4);
		C.DrawTile(PRI.Avatar,Height-8,Height-8,0,0,PRI.Avatar.SizeX,PRI.Avatar.SizeY);
		XPos = Height*2+8;
	}
	else
	{
		XPos = Height+4;

		// Try to obtain avatar.
		if( !PRI.bBot )
			PRI.Avatar = FindAvatar(PRI.UniqueId);
	}
	
	// Name
	C.SetPos(XPos,YOffset+2);
	if( PlayerIndex==Index )
		C.SetDrawColor(128,255,128,255);
	else C.DrawColor = SBTextColor;
	YPos = SBFontSize;
	S = PRI.TaggedPlayerName;
	if( PRI.ShowAdminName() )
	{
		S = S$" ("$PRI.GetAdminNameAbr()$")";
		C.DrawColor = PRI.GetAdminColorC();
	}
	else if( PRI.bIsDev )
	{
		S = S$" (D)";
		C.DrawColor = MakeColor(130,255,235,255);
	}
	if( bMeAdmin && PRI.FixedData>0 )
	{
		C.DrawColor = MakeColor(255,0,0,255);
		S = S$" -"$PRI.GetDesc();
	}
	while( true ) // Make sure too long name doesn't overleap.
	{
		C.TextSize(S,XL,YL,YPos,YPos);
		if( (C.CurX+XL)<CashXPos )
			break;
		YPos*=0.9;
	}
	C.DrawText(S,,YPos,YPos);
	
	// Other info background.
	C.SetDrawColor(4,4,4,255);
	Owner.CurrentStyle.DrawRectBox(CashXPos-4,YOffset+4,Width-CashXPos-8,Height-8,6);
	
	// Perk
	if( !bShowSpectatorsOnly )
	{
		if( PRI.ECurrentPerk!=None )
		{
			// Icon.
			C.DrawColor = PRI.HUDPerkColor;
			C.SetPos(XPos,YOffset+Height*0.5);
			C.DrawRect(Height*0.475,Height*0.475,PRI.ECurrentPerk.Default.PerkIcon);

			// Name.
			S = PRI.GetPerkLevelStr()@PRI.ECurrentPerk.Default.PerkName;
		}
		else if( PRI.bBot && PRI.CurrentPerkClass!=None )
		{
			// Icon.
			C.DrawColor = SBTextColor;
			C.SetPos(XPos,YOffset+Height*0.5);
			C.DrawRect(Height*0.475,Height*0.475,PRI.CurrentPerkClass.Default.PerkIcon);

			// Name.
			S = PRI.CurrentPerkClass.Default.PerkName;
		}
		else
		{
			C.DrawColor = SBTextColor;
			S = "No Perk";
		}
		YPos = SBFontSize*0.9;
		C.SetPos(XPos+Height*0.5,YOffset+Height*0.495);
		if( PRI.RespawnCounter>=0 )
		{
			C.DrawColor = SBTextColor;
			S = "Respawn: "$FormatTimeSM(PRI.RespawnCounter);
		}
		while( true ) // Make sure too long name doesn't overleap.
		{
			C.TextSize(S,XL,YL,YPos,YPos);
			if( (C.CurX+XL)<CashXPos )
				break;
			YPos*=0.8;
		}
		C.DrawText(S,,YPos,YPos);
	}
	
	// Cash
	C.DrawColor = SBTextColor;
	YPos = YOffset+(Height-SBFontHeight)*0.5;
	if( !bShowSpectatorsOnly )
	{
		C.SetPos(CashXPos,YPos);
		C.DrawText(string(int(PRI.Score)),,SBFontSize,SBFontSize);
		
		// Kills
		DrawCenteredText(string(PRI.Kills),KillsXPos,YPos,SBFontSize);
		
		// Assists
		DrawCenteredText(string(PRI.Assists),AssistXPos,YPos,SBFontSize);
	}
		
	// Ping
	DrawCenteredText(PRI.bBot ? "BOT" : string(PRI.Ping*4),PingXPos,YPos,SBFontSize);
	
	// Draw health.
	if( !bShowSpectatorsOnly )
	{
		if( HealthIcon!=None )
		{
			C.SetPos(6+(Height-12)*0.25,YOffset+8);
			C.DrawTile(HealthIcon,(Height-12)*0.5,(Height-12)*0.5,0,0,256,256);
		}
		if( PRI.PlayerHealth<=0 || PRI.PlayerHealthPercent<=0 )
			DrawCenteredText("DEAD",6+(Height-12)*0.5,YOffset+Height*0.45,SBFontSize*0.95);
		else DrawCenteredText(string(PRI.PlayerHealth),6+(Height-12)*0.5,YOffset+Height*0.45,SBFontSize*0.95);
	}
}
function ClickedPlayer( int Index, bool bRight, int MouseX, int MouseY )
{
	local PlayerController PC;
	local int i;

	if( !bRight || Index<0 )
		return;
	bHasSelectedPlayer = true;
	RightClickPlayer = PRIList[Index];
	
	// Check what items to disable.
	PC = GetPlayer();
	PlayerContext.ItemRows[0].bDisabled = (PlayerIndex==Index || !PC.IsSpectating());
	PlayerContext.ItemRows[1].bDisabled = RightClickPlayer.bBot;
	PlayerContext.ItemRows[2].bDisabled = (PlayerIndex==Index || RightClickPlayer.bBot);
	PlayerContext.ItemRows[2].Text = (PlayerContext.ItemRows[2].bDisabled || PC.IsPlayerMuted(RightClickPlayer.UniqueId)) ? "Unmute player" : "Mute player";

	if( PlayerIndex==Index ) // Selected self.
	{
		for( i=4; i<PlayerContext.ItemRows.Length; ++i )
			PlayerContext.ItemRows[i].bDisabled = true;
	}
	else
	{
		for( i=4; i<PlayerContext.ItemRows.Length; ++i )
			PlayerContext.ItemRows[i].bDisabled = false;
	}

	PlayerContext.OpenMenu(Self);
}
function HidRightClickMenu( KFGUI_RightClickMenu M )
{
	bHasSelectedPlayer = false;
}
function SelectedRCItem( int Index )
{
	local PlayerController PC;

	PC = GetPlayer();
	switch( Index )
	{
	case 0: // Spectate this player.
		PC.ConsoleCommand("ViewPlayerID "$RightClickPlayer.PlayerID);
		break;
	case 1: // Steam profile.
		OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem()).ShowProfileUI(0,,RightClickPlayer.UniqueId);
		break;
	case 2: // Mute voice.
		if( !PC.IsPlayerMuted(RightClickPlayer.UniqueId) )
		{
			PC.ClientMessage("You've muted "$RightClickPlayer.TaggedPlayerName);
			PC.ClientMutePlayer(RightClickPlayer.UniqueId);
			RightClickPlayer.bIsMuted = true;
		}
		else
		{
			PC.ClientMessage("You've unmuted "$RightClickPlayer.TaggedPlayerName);
			PC.ClientUnmutePlayer(RightClickPlayer.UniqueId);
			RightClickPlayer.bIsMuted = false;
		}
		break;
	default:
		if( Index>=4 )
			PC.ConsoleCommand("Admin "$ExtPlayerController(PC).AdminCommands[Index-4].Cmd@RightClickPlayer.PlayerID);
	}
}

function ShowPlayerTooltip( int Index )
{
	local ExtPlayerReplicationInfo PRI;
	local string S;
	
	PRI = PRIList[Index];
	if( PRI!=None )
	{
		if( ToolTipItem==None )
		{
			ToolTipItem = New(None)Class'KFGUI_Tooltip';
			ToolTipItem.Owner = Owner;
			ToolTipItem.ParentComponent = Self;
			ToolTipItem.InitMenu();
		}
		S = "Player: "$PRI.TaggedPlayerName$"|Health: "$(PRI.PlayerHealthPercent<=0 ? "0" : string(PRI.PlayerHealth));
		if( PRI.ShowAdminName() )
			S = S$"|"$PRI.GetAdminName();
		S = S$"|(Right click for options)";
		ToolTipItem.SetText(S);
		ToolTipItem.ShowMenu();
		ToolTipItem.CompPos[0] = Owner.MousePosition.X;
		ToolTipItem.CompPos[1] = Owner.MousePosition.Y;
		ToolTipItem.GetInputFocus();
	}
}

function ButtonClicked( KFGUI_Button Sender )
{
	switch( Sender.ID )
	{
	case 'Spec':
		bShowSpectatorsOnly = !bShowSpectatorsOnly;
		break;
	}
}

defaultproperties
{
	bAlwaysTop=true
	SBTextColor=(R=250,G=250,B=250,A=255)
	ScoreboardSpacing=4
	
	Begin Object Class=KFGUI_List Name=PlayerList
		bDrawBackground=false
		OnDrawItem=DrawPlayerEntry
		OnClickedItem=ClickedPlayer
		ID="PlayerList"
		bClickable=true
		OnMouseRest=ShowPlayerTooltip
	End Object
	Begin Object Class=KFGUI_Button Name=B_ShowSpecs
		ID="Spec"
		ButtonText="Show Spectators"
		Tooltip="Toggle show server spectators"
		XPosition=0.67
		YPosition=0.95
		XSize=0.09
		YSize=0.03
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	
	Components.Add(PlayerList)
	Components.Add(B_ShowSpecs)
	
	Begin Object Class=KFGUI_RightClickMenu Name=PlayerContextMenu
		ItemRows.Add((Text="Spectate this player"))
		ItemRows.Add((Text="View player Steam profile"))
		ItemRows.Add((Text="Mute"))
		ItemRows.Add((bSplitter=true))
		OnSelectedItem=SelectedRCItem
		OnBecameHidden=HidRightClickMenu
	End Object
	PlayerContext=PlayerContextMenu
}