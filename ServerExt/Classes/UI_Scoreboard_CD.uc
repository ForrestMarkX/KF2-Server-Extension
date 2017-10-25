class UI_Scoreboard_CD extends UI_Scoreboard;

var transient float AdminXPos, PerkXPos, PlayerXPos, StateXPos, TimeXPos;
var int MaxPlayerCount;

static final function string FormatTimeSMH (float Sec)
{
    local int Hours, Seconds, Minutes;

    Sec = Abs (Sec);
    Seconds = int (Sec);
    Minutes = Seconds / 60;
    Seconds -= Minutes * 60;
    Hours = Minutes / 60;

    return ((Hours < 1) ? "0" $Hours : string (Hours)) @":" @((Minutes < 10) ? "0" $Minutes : string (Minutes)) @":" @((Seconds < 10) ? "0" $Seconds : string (Seconds));
}

function DrawMenu()
{
    local string S;
    local PlayerController PC;
    local PlayerReplicationInfo PRI;
    local ExtPlayerReplicationInfo KFPRI;
    local float XPos, YPos, XL, YL, FontScalar, XPosCenter, CurrentBoxY;
    local int i, j, NumSpec, NumPlayer, NumAlivePlayer, Width, NotShownCount;
	local byte DefFont;

    PC = GetPlayer ();
    if (KFGRI == None) {
        KFGRI = KFGameReplicationInfo (PC.WorldInfo.GRI);
        if (KFGRI == None)
            return;
    }

    // Sort player list.
    for (i = (KFGRI.PRIArray.Length - 1); i > 0; --i) {
        for (j = i - 1; j >= 0; --j) {
            if (!InOrder (KFGRI.PRIArray [i], KFGRI.PRIArray [j])) {
                PRI = KFGRI.PRIArray [i];
                KFGRI.PRIArray [i] = KFGRI.PRIArray [j];
                KFGRI.PRIArray [j] = PRI;
            }
        }
    }

    // Check players.
    NumPlayer = 0;
    for (i = (KFGRI.PRIArray.Length - 1); i >= 0; --i) {
        KFPRI = ExtPlayerReplicationInfo (KFGRI.PRIArray [i]);
        if (KFPRI == None)
            continue;

        if (KFPRI.bOnlySpectator) {
            ++NumSpec;
            continue;
        }

        if (KFPRI.PlayerHealth > 0 && KFPRI.PlayerHealthPercent > 0 && KFPRI.GetTeamNum () == 0)
            ++NumAlivePlayer;
        ++NumPlayer;
    }

    //`Log ("DrawMenu (): PlayList.Length = " @PRIList.Length);

    // Header font info.
	DefFont = Owner.CurrentStyle.DefaultFontSize;
    Canvas.Font = Owner.CurrentStyle.PickFont(DefFont, FontScalar);

    YL = Owner.CurrentStyle.DefaultHeight;
    XPosCenter = (Canvas.ClipX * 0.5);

	// ServerName

	XPos = XPosCenter;
	YPos = Canvas.ClipY * 0.05;

	S = " " $KFGRI.ServerName $" ";
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos -= (XL * 0.5);

	Canvas.SetDrawColor (10, 10, 10, 200);
	Owner.CurrentStyle.DrawRectBox (XPos, YPos, XL, YL, 4);

	Canvas.DrawColor = MakeColor (250, 0, 0, 255);
	XPos += 5;

	S = KFGRI.ServerName;
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);

	// Deficulty | Wave | MapName | ElapsedTime

	XPos = XPosCenter;
	YPos += YL;

	S = " " $Class'KFCommon_LocalizedStrings'.Static.GetDifficultyString (KFGRI.GameDifficulty) $"  |  WAVE " $KFGRI.WaveNum $"  |  " $PC.WorldInfo.Title $"  |  00 : 00 : 00 ";
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos -= (XL * 0.5);

	Canvas.SetDrawColor (10, 10, 10, 200);
	Owner.CurrentStyle.DrawRectBox (XPos, YPos, XL, YL, 4);

	Canvas.DrawColor = MakeColor (0, 250, 0, 255);
	XPos += 5;

	S = Class'KFCommon_LocalizedStrings'.Static.GetDifficultyString (KFGRI.GameDifficulty);
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  | WAVE " $KFGRI.WaveNum;
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $class'KFCommon_LocalizedStrings'.static.GetFriendlyMapName(PC.WorldInfo.GetMapName(true));
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  " $FormatTimeSMH (KFGRI.ElapsedTime);
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	
	// Players | Alive | Spectators

	XPos = XPosCenter;
	YPos += YL;

	S = " Players : " $NumPlayer $"  |  Alive : " $NumAlivePlayer $"  |  Spectators : " $NumSpec $" ";
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos -= (XL * 0.5);

	Canvas.SetDrawColor (10, 10, 10, 200);
	Owner.CurrentStyle.DrawRectBox (XPos, YPos, XL, YL, 4);

	Canvas.DrawColor = MakeColor (250, 250, 0, 255);
	XPos += 5;

	S = "Players : " $NumPlayer;
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  Alive : " $NumAlivePlayer;
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	Canvas.TextSize (S, XL, YL, FontScalar, FontScalar);

	XPos += XL;
	S = "  |  Spectators : " $NumSpec;
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText (S, , FontScalar, FontScalar);
	
	Width = Canvas.ClipX * 0.7;

	XPos = (Canvas.ClipX - Width) * 0.5;
	YPos += YL * 2.0;

	Canvas.SetDrawColor (10, 10, 10, 200);
	Owner.CurrentStyle.DrawRectBox (XPos, YPos, Width, YL, 4);

	Canvas.DrawColor = MakeColor (250, 250, 250, 255);

	// Calc X offsets
	
	AdminXPos = Width * 0.0;
	PerkXPos = Width * 0.1;
	PlayerXPos = Width * 0.3;
	KillsXPos = Width * 0.5;
	AssistXPos = Width * 0.6;
	CashXPos = Width * 0.7;
	StateXPos = Width * 0.8;
	PingXPos = Width * 0.95;

	// Header texts
	if( !bShowSpectatorsOnly )
	{
		Canvas.SetPos (XPos + PerkXPos, YPos);
		Canvas.DrawText ("PERK", , FontScalar, FontScalar);

		Canvas.SetPos (XPos + KillsXPos, YPos);
		Canvas.DrawText ("KILLS", , FontScalar, FontScalar);

		Canvas.SetPos (XPos + AssistXPos, YPos);
		Canvas.DrawText ("ASSISTS", , FontScalar, FontScalar);
		
		Canvas.SetPos (XPos + CashXPos, YPos);
		Canvas.DrawText ("DOSH", , FontScalar, FontScalar);

		Canvas.SetPos (XPos + StateXPos, YPos);
		Canvas.DrawText ("STATE", , FontScalar, FontScalar);
	}
	
	Canvas.SetPos (XPos, YPos);
	Canvas.DrawText ("RANK", , FontScalar, FontScalar);
	
	Canvas.SetPos (XPos + PlayerXPos, YPos);
	Canvas.DrawText ("PLAYER", , FontScalar, FontScalar);

	Canvas.SetPos (XPos + PingXPos, YPos);
	Canvas.DrawText ("PING", , FontScalar, FontScalar);
	
	PRIList.Length = (bShowSpectatorsOnly ? NumSpec : NumPlayer);
	j = PRIList.Length;
	for( i=(KFGRI.PRIArray.Length-1); i>=0; --i )
	{
		KFPRI = ExtPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if( KFPRI!=None && bShowSpectatorsOnly==KFPRI.bOnlySpectator )
		{
			PRIList[--j] = KFPRI;
			if( KFPRI==PC.PlayerReplicationInfo )
				PlayerIndex = j;
		}
	}
	
	CurrentBoxY = (YL + 4) * MaxPlayerCount;
	while( CurrentBoxY > (Canvas.ClipY-YPos) )
	{
		if( ++i>=5 )
		{
			NotShownCount = MaxPlayerCount-int((Canvas.ClipY-YPos)/CurrentBoxY)+1;
			MaxPlayerCount-=NotShownCount;
			break;
		}
	}
	
	PlayersList.XPosition = ((Canvas.ClipX - Width) * 0.5) / InputPos[2];
	PlayersList.YPosition = (YPos + (YL + 4)) / InputPos[3];
	PlayersList.XSize = (Width * 1.022) / InputPos[2];
	PlayersList.YSize = CurrentBoxY / InputPos[3];
	PlayersList.ListItemsPerPage = MaxPlayerCount;
	PlayersList.ChangeListSize(PRIList.Length);
}

function DrawPlayerEntry( Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus )
{
	local float FontScalar;
	local ExtPlayerReplicationInfo KFPRI;
	local string S, StrValue;
	local byte DefFont;
	local int Ping;
	
	KFPRI = PRIList[Index];
	
	bFocus = bFocus || (bHasSelectedPlayer && RightClickPlayer==KFPRI);
	
	DefFont = Owner.CurrentStyle.DefaultFontSize;
    C.Font = Owner.CurrentStyle.PickFont(DefFont, FontScalar);
	
	if (KFPRI == GetPlayer().PlayerReplicationInfo)
	{
		if( bFocus )
			C.SetDrawColor(0, 83, 255, 150);
		else C.SetDrawColor (51, 30, 101, 150);
	}
	else 
	{
		if( bFocus )
			C.SetDrawColor(0, 83, 255, 150);
		else C.SetDrawColor (30, 30, 30, 150);
	}
	
	Owner.CurrentStyle.DrawRectBox (0.f, YOffset, Width, Height, 4);

	C.DrawColor = MakeColor (250, 250, 250, 255);

	// Perk
	if( !bShowSpectatorsOnly )
	{
		C.DrawColor = KFPRI.HUDPerkColor;
		if( KFPRI.ECurrentPerk!=None )
		{
			C.SetPos (0.f + PerkXPos, YOffset + 2.5);
			C.DrawRect (Height-5, Height-5, KFPRI.ECurrentPerk.Default.PerkIcon);
			
			S = KFPRI.GetPerkLevelStr()@KFPRI.ECurrentPerk.Default.PerkName;
			C.SetPos (0.f + PerkXPos + Height, YOffset);
			C.DrawText (S, , FontScalar, FontScalar);
		}
		else if( KFPRI.bBot && KFPRI.CurrentPerkClass!=None )
		{
			C.SetPos (0.f + PerkXPos, YOffset + 2.5);
			C.DrawRect (Height-5, Height-5, KFPRI.CurrentPerkClass.Default.PerkIcon);
			
			S = KFPRI.CurrentPerkClass.Default.PerkName;
			C.SetPos (0.f + PerkXPos + Height, YOffset);
			C.DrawText (S, , FontScalar, FontScalar);
		}
		else
		{
			C.DrawColor = MakeColor (250, 250, 250, 255);
			S = "No Perk";
			C.SetPos (0.f + PerkXPos + Height, YOffset);
			C.DrawText (S, , FontScalar, FontScalar);
		}
	}
	
	// Avatar
	if( KFPRI.Avatar!=None )
	{
		C.SetDrawColor(255,255,255,255);
		C.SetPos(0.f + PlayerXPos - (Height * 1.2), YOffset);
		C.DrawTile(KFPRI.Avatar,Height,Height,0,0,KFPRI.Avatar.SizeX,KFPRI.Avatar.SizeY);
	}
	else
	{
		// Try to obtain avatar.
		if( !KFPRI.bBot )
			KFPRI.Avatar = FindAvatar(KFPRI.UniqueId);
	}
	
	// Rank
	if( KFPRI.ShowAdminName() )
	{
		S = KFPRI.GetAdminName();
		C.DrawColor = KFPRI.GetAdminColorC();
	}
	else if( KFPRI.bIsDev )
	{
		S = "Developer";
		C.DrawColor = MakeColor(130,255,235,255);
	}
	else
	{
		S = "Player";
		C.DrawColor = MakeColor(255,255,255,255);
	}
	
	// Rank
	C.SetPos (0.f + AdminXPos, YOffset);
	C.DrawText (S, , FontScalar, FontScalar);

	// Player
	C.SetPos (0.f + PlayerXPos, YOffset);
	C.DrawText (KFPRI.PlayerName, , FontScalar, FontScalar);
	
	C.DrawColor = MakeColor(255,255,255,255);

	if( !bShowSpectatorsOnly )
	{
		// Kill
		C.SetDrawColor(255,51,51,255);
		C.SetPos (0.f + KillsXPos, YOffset);
		C.DrawText (string (KFPRI.Kills), , FontScalar, FontScalar);

		// Assist
		C.SetDrawColor(255,255,51,255);
		C.SetPos (0.f + AssistXPos, YOffset);
		C.DrawText (string (KFPRI.Assists), , FontScalar, FontScalar);
		
		// Dosh
		C.SetDrawColor(51,255,51,255);
		C.SetPos (0.f + CashXPos, YOffset);
		StrValue = ConvertValueLarge(KFPRI.Score);
		C.DrawText (StrValue, , FontScalar, FontScalar);

		// State
		if (KFPRI.PlayerHealth <= 0 || KFPRI.PlayerHealthPercent <= 0)
		{
			C.DrawColor = MakeColor (250, 0, 0, 255);
			S = "DEAD";
		}
		else
		{
			if (KFPRI.PlayerHealth >= 80)
				C.DrawColor = MakeColor (0, 250, 0, 255);
			else if (KFPRI.PlayerHealth >= 30)
				C.DrawColor = MakeColor (250, 250, 0, 255);
			else C.DrawColor = MakeColor (250, 100, 100, 255);
			
			S =  string (KFPRI.PlayerHealth) @"HP";
		}

		C.SetPos (0.f + StateXPos, YOffset);
		C.DrawText (S, , FontScalar, FontScalar);
		
		C.DrawColor = MakeColor (250, 250, 250, 255);
	}

	// Ping
	if (KFPRI.bBot)
		S = "-";
	else
	{
		Ping = int(KFPRI.Ping * `PING_SCALE);
		
		if (Ping <= 100)
			C.DrawColor = MakeColor (0, 250, 0, 255);
		else if (Ping <= 200)
			C.DrawColor = MakeColor (250, 250, 0, 255);
		else C.DrawColor = MakeColor (250, 100, 100, 255);
		
		S = string(Ping);
	}

	C.SetPos (0.f + PingXPos, YOffset);
	C.DrawText (S, , FontScalar, FontScalar);
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
			ToolTipItem = New(None)Class'KFGUI_Tooltip_CD';
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

function string ConvertValueLarge(int FValue)
{
	local string StrValue, StrType;
	local float FltValue;
	local int i;
	
	FltValue = float(FValue);
	StrValue = string(FltValue);
	if(FltValue < 10000.f)
	{
		StrValue = string(int(FltValue));
		StrType = "";
	}
	else if(FltValue < 1000000.f)
	{
		StrValue = string(FltValue / 1000);//.0
		StrType = "k";
	}
	else
	{
		StrValue = string(FltValue / 1000000);//.0
		StrType = "m";
	}
	i = InStr(StrValue,".");
	if(i != -1 && StrType != "")
		return Left(StrValue,i+2) $ StrType;
	return StrValue;
}

function SelectedRCItem( int Index )
{
	local PlayerController PC;
	local KFPlayerReplicationInfo KFPRI;

	PC = GetPlayer();
	KFPRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);
	
	switch( Index )
	{
	case 3: // Vote kick.
		KFPRI.ServerStartKickVote(RightClickPlayer, KFPRI);
		break;
	default:
		Super.SelectedRCItem(Index);
		break;
	}
}

defaultproperties
{
	MaxPlayerCount=25
	
	Components.Empty
	
	Begin Object Class=KFGUI_List_CD Name=PlayerList
		bDrawBackground=false
		OnDrawItem=DrawPlayerEntry
		OnClickedItem=ClickedPlayer
		ID="PlayerList"
		bClickable=true
		OnMouseRest=ShowPlayerTooltip
	End Object
	Begin Object Class=KFGUI_Button_CD Name=B_ShowSpecs
		ID="Spec"
		ButtonText="Show Spectators"
		Tooltip="Toggle show server spectators"
		XPosition=0.67
		YPosition=0.965
		XSize=0.09
		YSize=0.03
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(PlayerList)
	Components.Add(B_ShowSpecs)
	
	Begin Object Class=KFGUI_RightClickMenu_CD Name=PlayerContextMenu
		ItemRows.Add((Text="Spectate this player"))
		ItemRows.Add((Text="View player Steam profile"))
		ItemRows.Add((Text="Mute Player"))
		ItemRows.Add((Text="Vote kick player"))
		ItemRows.Add((bSplitter=true))
		OnSelectedItem=SelectedRCItem
		OnBecameHidden=HidRightClickMenu
	End Object
	PlayerContext=PlayerContextMenu
}