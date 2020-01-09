// Written by Marco
//class KFExtendedHUD extends KFHUDBase;
class KFExtendedHUD extends KFGFxHudWrapper;

var array<Ext_T_MonsterPRI> MyCurrentPet;

struct FDeathMessageType
{
	var string Msg,SMsg;
	var float MsgTime;
};
var array<FDeathMessageType> DeathMessages;

struct FKillMessageType
{
	var bool bDamage,bLocal;
	var int Counter;
	var Class Type;
	var string Name;
	var PlayerReplicationInfo OwnerPRI;
	var float MsgTime;
	var color MsgColor;
};
var transient array<FKillMessageType> KillMessages;

var int HealthBarFullVisDist, HealthBarCutoffDist;
var transient float BestPetXL, BestPetYL;

struct PopupDamageInfo
{
    var int Damage;
    var float HitTime;
    var Vector HitLocation;
    var byte Type;
    var float RandX, RandY;
    var color FontColor;
};
const DAMAGEPOPUP_COUNT = 32;
var PopupDamageInfo DamagePopups[32];
var int NextDamagePopupIndex;
var float DamagePopupFadeOutTime;

struct FNewItemEntry
{
	var Texture2D Icon;
	var string Item;
	var float MsgTime;
};
var transient array<FNewItemEntry> NewItems;

var ExtPlayerReplicationInfo EPRI;
var transient KF2GUIController GUIController;
var transient GUIStyleBase GUIStyle;
var transient array<string> ProgressLines;
var transient float ProgressMsgTime,PLCameraDot;
var transient vector PLCameraLoc,PLCameraDir;
var transient rotator PLCameraRot;
//var Texture2D DownArrowTex,MiddleTex,WaveBossTex,WaveProgTex,TraderTimeTex,SyringeBarTex,ArmorIconTex,BatteryIconTex;
var Texture2D HealthIconTex;
var color BlackBGColor,RedBGColor,HUDTextColor;
var transient array<byte> WasNewlyAdded;

var transient OnlineSubsystem OnlineSub;
var string BadConnectionStr;

var transient bool bShowProgress,bProgressDC,bConfirmDisconnect,bMeAdmin,bLoadedInitItems;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	KFPlayerOwner = KFPlayerController(Owner);

	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSub!=None )
	{
		OnlineSub.AddOnInventoryReadCompleteDelegate(SearchInventoryForNewItem);
		SetTimer(60,false,'SearchInventoryForNewItem');
	}
	
	SetTimer(300 + FRand()*120.f,false,'CheckForItems');
}
simulated function Destroyed()
{
	Super.Destroyed();
	NotifyLevelChange();
}
simulated final function NotifyLevelChange( optional bool bMapswitch )
{
	if( OnlineSub!=None )
	{
		OnlineSub.ClearOnInventoryReadCompleteDelegate(SearchInventoryForNewItem);
		OnlineSub = None;
	}
	
	// Send to an empty stage to play the "waiting" game.
	if( bMapswitch )
		SetTimer(0.5,false,'PendingMapSwitch');
}
simulated function PendingMapSwitch()
{
	// Make sure we dont garbage collect the game:
	class'MS_Game'.Static.SetReference();
	class'MS_PC'.Default.TravelData.PendingURL = WorldInfo.GetAddressURL();
	class'MS_PC'.Default.TravelData.PendingSong = ExtPlayerController(Owner).BonusMusic;
	class'MS_PC'.Default.TravelData.PendingFX = ExtPlayerController(Owner).BonusFX;
	ConsoleCommand("Open KFMainMenu?Game="$PathName(class'MS_Game'));
}

final function AddKillMessage( class<Pawn> Victim, int Value, PlayerReplicationInfo PRI, byte Type )
{
	local int i;
	local bool bDmg,bLcl;
	
	bDmg = (Type==2);
	bLcl = (Type==0);
	for( i=0; i<KillMessages.Length; ++i )
		if( KillMessages[i].bDamage==bDmg && KillMessages[i].bLocal==bLcl && KillMessages[i].Type==Victim && (bDmg || bLcl || KillMessages[i].OwnerPRI==PRI) )
		{
			KillMessages[i].Counter+=Value;
			KillMessages[i].MsgTime = WorldInfo.TimeSeconds;
			KillMessages[i].MsgColor = GetMsgColor(bDmg,KillMessages[i].Counter);
			return;
		}
	
	KillMessages.Length = i+1;
	KillMessages[i].bDamage = bDmg;
	KillMessages[i].bLocal = bLcl;
	KillMessages[i].Counter = Value;
	KillMessages[i].Type = Victim;
	KillMessages[i].OwnerPRI = PRI;
	KillMessages[i].MsgTime = WorldInfo.TimeSeconds;
	KillMessages[i].Name = GetNameOf(Victim);
	KillMessages[i].MsgColor = GetMsgColor(bDmg,Value);
}
final function AddDeathMessage( string S, string StrippedMsg )
{
	DeathMessages.Insert(0,1);
	DeathMessages[0].Msg = S;
	DeathMessages[0].SMsg = StrippedMsg;
	DeathMessages[0].MsgTime = WorldInfo.TimeSeconds;
}
final function ShowProgressMsg( string S, optional bool bDis )
{
	if( S=="" )
	{
		bShowProgress = false;
		return;
	}
	bShowProgress = true;
	ParseStringIntoArray(S,ProgressLines,"|",false);
	if( !bProgressDC )
		ProgressMsgTime = WorldInfo.TimeSeconds+4.f;
	bProgressDC = bDis;
	if( bDis )
	{
		LocalPlayer(KFPlayerOwner.Player).ViewportClient.ViewportConsole.OutputText(Repl(S,"|","\n"));
	}
}
static final function string GetNameOf( class<Pawn> Other )
{
	local string S;
	local class<KFPawn_Monster> KFM;

	if( Class<VSZombie>(Other)!=None )
		return Class<VSZombie>(Other).Default.ZombieName;
		
	KFM = class<KFPawn_Monster>(Other);
	if( KFM!=None && KFM.default.LocalizationKey != '' )
		return Localize("Zeds", string(KFM.default.LocalizationKey), "KFGame");

	if( Other.Default.MenuName!="" )
		return Other.Default.MenuName;
	S = string(Other.Name);
	if( Left(S,10)~="KFPawn_Zed" )
		S = Mid(S,10);
	else if( Left(S,7)~="KFPawn_" )
		S = Mid(S,7);
	S = Repl(S,"_"," ");
	return S;
}
static final function string GetNameArticle( string S )
{
	switch( Caps(Left(S,1)) ) // Check if a vowel, then an.
	{
	case "A":
	case "E":
	case "I":
	case "O":
	case "U":
		return "an";
	}
	return "a";
}
static final function string StripMsgColors( string S )
{
	local int i;
	
	while( true )
	{
		i = InStr(S,Chr(6));
		if( i==-1 )
			break;
		S = Left(S,i)$Mid(S,i+2);
	}
	return S;
}
final function color GetMsgColor( bool bDamage, int Count )
{
	local float T;

	if( bDamage )
	{
		if( Count>1500 )
			return MakeColor(148,0,0,255);
		else if( Count>1000 )
		{
			T = (Count-1000) / 500.f;
			return MakeColor(148,0,0,255)*T + MakeColor(255,0,0,255)*(1.f-T);
		}
		else if( Count>500 )
		{
			T = (Count-500) / 500.f;
			return MakeColor(255,0,0,255)*T + MakeColor(255,255,0,255)*(1.f-T);
		}
		T = Count / 500.f;
		return MakeColor(255,255,0,255)*T + MakeColor(0,255,0,255)*(1.f-T);
	}
	if( Count>20 )
		return MakeColor(255,0,0,255);
	else if( Count>10 )
	{
		T = (Count-10) / 10.f;
		return MakeColor(148,0,0,255)*T + MakeColor(255,0,0,255)*(1.f-T);
	}
	else if( Count>5 )
	{
		T = (Count-5) / 5.f;
		return MakeColor(255,0,0,255)*T + MakeColor(255,255,0,255)*(1.f-T);
	}
	T = Count / 5.f;
	return MakeColor(255,255,0,255)*T + MakeColor(0,255,0,255)*(1.f-T);
}

event PostRender()
{
	if( GUIController!=None && PlayerOwner.PlayerInput==None )
		GUIController.NotifyLevelChange();
	if( KFGRI==None )
		KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if( GUIController==None || GUIController.bIsInvalid )
	{
		GUIController = Class'KF2GUIController'.Static.GetGUIController(PlayerOwner);
		if( GUIController!=None )
			GUIStyle = GUIController.CurrentStyle;
	}
	GUIStyle.Canvas = Canvas;
	GUIStyle.PickDefaultFontSize(Canvas.ClipY);
	
	DrawDamage();

	//RenderKFHUD(); // TODO later...
	super.PostRender();
	
	// Camera position.
	PlayerOwner.GetPlayerViewPoint(PLCameraLoc,PLCameraRot);
	PLCameraDir = vector(PLCameraRot);
	PLCameraDot = (PLCameraDir Dot PLCameraLoc);

	if( MyCurrentPet.Length>0 )
		DrawPetInfo();
	if( EPRI==None )
		EPRI = ExtPlayerReplicationInfo(KFPlayerOwner.PlayerReplicationInfo);
	else if( EPRI.RespawnCounter>0 )
		DrawRespawnCounter();
	bMeAdmin = (EPRI!=None && EPRI.AdminType<=1);
	if( KillMessages.Length>0 )
		RenderKillMsg();
	if( DeathMessages.Length>0 )
		RenderDMMessages();
	if( NewItems.Length>0 )
		DrawItemsList();

	if( bShowProgress || PlayerOwner.Player==None )
	{
		if( ProgressMsgTime<WorldInfo.TimeSeconds )
		{
			bShowProgress = false;
			if( PlayerOwner.Player==None )
			{
				ShowProgressMsg("Downloading contents for next map, please wait...|Press [Escape] key to cancel connection!");
				RenderProgress();
			}
			else if( bProgressDC )
				KFPlayerOwner.ConsoleCommand("Disconnect");
		}
		else RenderProgress();
	}
	if( PlayerOwner.Player==None && OnlineSub!=None )
		NotifyLevelChange();
}
simulated function CancelConnection()
{
	if( !bConfirmDisconnect )
	{
		ShowProgressMsg("Are you sure you want to cancel connection?|Press [Escape] again to confirm...");
		bConfirmDisconnect = true;
	}
	else class'Engine'.Static.GetEngine().GameViewport.ConsoleCommand("Disconnect");
}
final function DrawRespawnCounter()
{
	local float Sc,XL,YL;
	local string S;

	Canvas.Font = GUIStyle.PickFont(GUIStyle.DefaultFontSize+1,Sc);
	S = "You are about to respawn in "$class'UI_Scoreboard'.Static.FormatTimeSM(EPRI.RespawnCounter);
	Canvas.SetDrawColor(250,150,150,255);
	Canvas.TextSize(S,XL,YL,Sc,Sc);
	Canvas.SetPos((Canvas.ClipX-XL)*0.5,Canvas.ClipY*0.075);
	Canvas.DrawText(S,,Sc,Sc);
}
exec function SetShowScores(bool bNewValue)
{
	bShowScores = bNewValue;
	if( GUIController!=None )
	{
		if( bShowScores )
			GUIController.OpenMenu(class'UI_Scoreboard_CD');
		else GUIController.CloseMenu(class'UI_Scoreboard_CD');
	}
}
final function RenderKillMsg()
{
	local float Sc,YL,T,X,Y;
	local string S;
	local int i;
	
	Canvas.Font = GUIStyle.PickFont(GUIStyle.DefaultFontSize,Sc);
	Canvas.TextSize("A",X,YL,Sc,Sc);

	X = Canvas.ClipX*0.015;
	Y = Canvas.ClipY*0.24;
	
	for( i=0; i<KillMessages.Length; ++i )
	{
		T = WorldInfo.TimeSeconds-KillMessages[i].MsgTime;
		if( T>6.f )
		{
			KillMessages.Remove(i--,1);
			continue;
		}

		if( KillMessages[i].bDamage )
			S = "-"$KillMessages[i].Counter$" HP "$KillMessages[i].Name;
		else if( KillMessages[i].bLocal )
			S = "+"$KillMessages[i].Counter@KillMessages[i].Name$(KillMessages[i].Counter>1 ? " kills" : " kill");
		else S = (KillMessages[i].OwnerPRI!=None ? KillMessages[i].OwnerPRI.GetHumanReadableName() : "Someone")$" +"$KillMessages[i].Counter@KillMessages[i].Name$(KillMessages[i].Counter>1 ? " kills" : " kill");
		Canvas.SetPos(X,Y);
		Canvas.DrawColor = KillMessages[i].MsgColor;
		T = (1.f - (T/6.f)) * 255.f;
		Canvas.DrawColor.A = T;
		Canvas.DrawText(S,,Sc,Sc);
		Y+=YL;
	}
}
final function RenderDMMessages()
{
	local float Sc,YL,XL,T,Y,X;
	local string S;
	local int i,j;
	local byte a;

	Canvas.Font = GUIStyle.PickFont(GUIStyle.DefaultFontSize+1,Sc);
	Y = Canvas.ClipY*0.98;
	
	for( i=0; i<DeathMessages.Length; ++i )
	{
		T = WorldInfo.TimeSeconds-DeathMessages[i].MsgTime;
		if( T>6.f )
		{
			DeathMessages.Remove(i--,1);
			continue;
		}
		// Setup alpha color.
		T = (1.f - (T/6.f)) * 255.f;
		a = Max(T,1);
		Canvas.SetDrawColor(0,255,0,a);
		
		// Get text size and setup start position.
		Canvas.TextSize(DeathMessages[i].SMsg,XL,YL,Sc,Sc);
		Y-=YL;
		X = (Canvas.ClipX-XL)*0.5f;

		// Now strip text into color tag pieces.
		S = DeathMessages[i].Msg;
		while( true )
		{
			Canvas.SetPos(X,Y);
			j = InStr(S,Chr(6));
			if( j==-1 )
			{
				Canvas.DrawText(S,,Sc,Sc);
				break;
			}
			if( j>0 )
			{
				Canvas.DrawText(Left(S,j),,Sc,Sc);
				Canvas.TextSize(Left(S,j),XL,YL,Sc,Sc);
				X+=XL;
			}
			switch( Mid(S,j+1,1) )
			{
			case "O": // Blue victim color.
				Canvas.SetDrawColor(32,32,255,a);
				break;
			case "M": // Green killmessage color.
				Canvas.SetDrawColor(0,255,0,a);
				break;
			case "K": // Red enemy killer color.
				Canvas.SetDrawColor(255,32,32,a);
				break;
			}
			S = Mid(S,j+2);
		}
	}
}
final function RenderProgress()
{
	local float Y,XL,YL,Sc;
	local int i;
	
	Canvas.Font = GUIStyle.PickFont(GUIStyle.DefaultFontSize+1,Sc);
	if( bProgressDC )
		Canvas.SetDrawColor(255,80,80,255);
	else Canvas.SetDrawColor(255,255,255,255);
	Y = Canvas.ClipY*0.2;

	for( i=0; i<ProgressLines.Length; ++i )
	{
		Canvas.TextSize(ProgressLines[i],XL,YL,Sc,Sc);
		Canvas.SetPos((Canvas.ClipX-XL)*0.5,Y);
		Canvas.DrawText(ProgressLines[i],,Sc,Sc);
		Y+=YL;
	}
}

function DrawHUD()
{
	local KFPawn_Human KFPH;
	local KFPawn_Scripted KFPS;
	local vector ViewLocation, ViewVector, PlayerPartyInfoLocation, PawnLocation;
	local rotator ViewRotation;
    local array<PlayerReplicationInfo> VisibleHumanPlayers;
    local array<sHiddenHumanPawnInfo> HiddenHumanPlayers;
	local float ThisDot,DotScale;
	local vector TargetLocation;
	local Actor LocActor;
	local KFPawn_Monster M;
	local vector V;
	local bool bSpec;

    // Draw weapon HUD underneath everything else
    if( KFPlayerOwner != none && KFPlayerOwner.Pawn != none && KFPlayerOwner.Pawn.Weapon != none )
    {
    	KFPlayerOwner.Pawn.Weapon.DrawHUD( self, Canvas );
    }

	super.DrawHUD();

    // Cache GRI
    if( KFGRI == none )
    {
        KFGRI = KFGameReplicationInfo( WorldInfo.GRI );
    }

    // Don't draw canvas HUD in cinematic mode
	if( KFPlayerOwner != none && KFPlayerOwner.bCinematicMode )
	{
		return;
	}
	LocActor = KFPlayerOwner.ViewTarget != none ? KFPlayerOwner.ViewTarget : KFPlayerOwner;

	// Draw the crosshair for casual mode
	if( KFPlayerOwner != none && (bDrawCrosshair || bForceDrawCrosshair || KFPlayerOwner.GetTeamNum() == 255) )
	{
        DrawCrosshair();
    }

    // Friendly player status
	bSpec = (PlayerOwner.PlayerReplicationInfo!=None && PlayerOwner.PlayerReplicationInfo.bOnlySpectator);
	if( bSpec || PlayerOwner.GetTeamNum()==0 )
	{
		//Friendly player status
		if( !class'ExtPlayerController'.Default.bHideNameBeacons )
        {
            if( KFPlayerOwner != none )
            {
                KFPlayerOwner.GetPlayerViewPoint( ViewLocation, ViewRotation );
            }
            ViewVector = vector(ViewRotation);

            Canvas.EnableStencilTest(true);
            foreach WorldInfo.AllPawns( class'KFPawn_Human', KFPH )
            {
                if( KFPH.IsAliveAndWell() && KFPH != KFPlayerOwner.Pawn && KFPH.Mesh.SkeletalMesh != none && KFPH.Mesh.bAnimTreeInitialised )
                {
                    PlayerPartyInfoLocation = KFPH.Mesh.GetPosition() + ( KFPH.CylinderComponent.CollisionHeight * vect(0,0,1) );
                    if(`TimeSince(KFPH.Mesh.LastRenderTime) < 0.2f && Normal(PlayerPartyInfoLocation - ViewLocation) dot ViewVector > 0.f )
                    {
                        if( DrawFriendlyHumanPlayerInfo(KFPH) )
                        {
                            VisibleHumanPlayers.AddItem( KFPH.PlayerReplicationInfo );
                        }
                        else
                        {
                            HiddenHumanPlayers.Insert( 0, 1 );
                            HiddenHumanPlayers[0].HumanPawn = KFPH;
                            HiddenHumanPlayers[0].HumanPRI = KFPH.PlayerReplicationInfo;
                        }
                    }
                    else
                    {
                        HiddenHumanPlayers.Insert( 0, 1 );
                        HiddenHumanPlayers[0].HumanPawn = KFPH;
                        HiddenHumanPlayers[0].HumanPRI = KFPH.PlayerReplicationInfo;
                    }
                }
            }

            foreach WorldInfo.AllPawns(class'KFPawn_Scripted', KFPS)
            {
                if (KFPS.ShouldShowOnHUD())
                {
                    PlayerPartyInfoLocation = KFPS.Mesh.GetPosition() + (KFPS.CylinderComponent.CollisionHeight * vect(0,0,1));
                    DrawScriptedPawnInfo(KFPS, Normal(PlayerPartyInfoLocation - ViewLocation) dot ViewVector, `TimeSince(KFPS.Mesh.LastRenderTime) < 0.2f);
                }
            }

            if( !KFGRI.bHidePawnIcons )
            {
                // Draw hidden players
                CheckAndDrawHiddenPlayerIcons( VisibleHumanPlayers, HiddenHumanPlayers );

                // Draw last remaining zeds
                CheckAndDrawRemainingZedIcons();

                //Draw our current objective location
                if(KFGRI.CurrentObjective != none && KFGRI.ObjectiveInterface != none)
                {
                    KFGRI.ObjectiveInterface.DrawHUD(self, Canvas);

                    TargetLocation = KFGRI.ObjectiveInterface.GetIconLocation();
                    ThisDot = Normal((TargetLocation + (class'KFPawn_Human'.default.CylinderComponent.CollisionHeight * vect(0, 0, 1))) - ViewLocation) dot ViewVector;

                    if (ThisDot > 0 &&
                        KFGRI.ObjectiveInterface.ShouldShowObjectiveHUD() &&
                        (!KFGRI.ObjectiveInterFace.HasObjectiveDrawDistance() || VSizeSq(TargetLocation - LocActor.Location) < MaxDrawDistanceObjective))
                    {
                        DrawObjectiveHUD();
                    }
                }
            }

            Canvas.EnableStencilTest(false);
        }
	}
	else if( KFPawn_Monster(PlayerOwner.Pawn)!=None )
	{
		// Draw human health auras.
		DotScale = Canvas.ClipX*0.2f;
		foreach WorldInfo.AllPawns(class'KFPawn_Human', KFPH)
		{
			PawnLocation = KFPH.Location;
			
			if( IsZero( PawnLocation ) )
			{
				continue;
			}
			
			ThisDot = (PLCameraDir Dot PawnLocation) - PLCameraDot;
			if( KFPH.IsAliveAndWell() && ThisDot>0.f && ThisDot<10000.f )
			{
				V = Canvas.Project(PawnLocation);
				if( V.X<-100 || V.X>(Canvas.SizeX+100) || V.Y<-100 || V.Y>(Canvas.SizeY+100) )
					continue;
				Canvas.DrawColor = GetHPColorScale(KFPH);
				if( PlayerOwner.FastTrace(PawnLocation,PLCameraLoc) )
					ThisDot*=1.75f;
				ThisDot = (DotScale/ThisDot)*350.f;
				Canvas.SetPos(V.X-ThisDot*0.25f,V.Y-ThisDot*0.5f);
				Canvas.DrawTile(Texture2D'VFX_TEX.FX_Glare_01',ThisDot*0.5f,ThisDot,0,0,512,512,,,BLEND_Additive);
			}
		}

		if( !class'ExtPlayerController'.Default.bHideNameBeacons )
		{
            Canvas.EnableStencilTest(true);
			// Draw zed health bars.
			foreach WorldInfo.AllPawns(class'KFPawn_Monster', M)
			{
				ThisDot = (PLCameraDir Dot (M.Location + M.CylinderComponent.CollisionHeight * vect(0,0,1))) - PLCameraDot;
				if( ThisDot>0 && ThisDot<8000.f && M.IsAliveAndWell() && M.PlayerReplicationInfo!=None && M!=PlayerOwner.Pawn && (WorldInfo.TimeSeconds - M.Mesh.LastRenderTime) < 0.4f )
					DrawFriendlyHUDZ(M);
			}
            Canvas.EnableStencilTest(false);
		}
	}
}

simulated static final function color GetHPColorScale( Pawn P )
{
	local color C;

	if( P.Health<25 ) // Red
		C.R = 255;
	else if( P.Health<75 ) // Yellow -> Red
	{
		C.G = (P.Health-25) * 5.1f;
		C.R = 255;
	}
	else if( P.Health<100 ) // Green -> Yellow
	{
		C.G = 255;
		C.R = (100-P.Health) * 10.2f;
	}
	else C.G = 255;
	C.B = 25;
	return C;
}
simulated function DrawFriendlyHUDZ( KFPawn_Monster KFPH )
{
	local float Percentage;
	local float BarHeight, BarLength;
	local vector ScreenPos, TargetLocation;
	local FontRenderInfo MyFontRenderInfo;
	local float FontScale;
    local byte FadeAlpha;

	MyFontRenderInfo = Canvas.CreateFontRenderInfo( true );
    FadeAlpha = DrawToDistance(KFPH);

	BarLength = FMin(PlayerStatusBarLengthMax * (float(Canvas.SizeX) / 1024.f), PlayerStatusBarLengthMax) * FriendlyHudScale;
	BarHeight = FMin(8.f * (float(Canvas.SizeX) / 1024.f), 8.f) * FriendlyHudScale;

	TargetLocation = KFPH.Location + vect(0,0,1) * KFPH.GetCollisionHeight() * 1.2;

	ScreenPos = Canvas.Project(TargetLocation);
	if( ScreenPos.X < 0 || ScreenPos.X > Canvas.SizeX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.SizeY )
		return;

	//Draw health bar
	Percentage = float(KFPH.Health) / float(KFPH.HealthMax);
	DrawPlayerInfoBar(KFPH, Percentage, BarLength, BarHeight, ScreenPos.X - (BarLength *0.5f), ScreenPos.Y, HealthColor, FadeAlpha);

	//Draw player name (Top)
	FontScale = class'KFGameEngine'.Static.GetKFFontScale() * FriendlyHudScale;
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
    
    Canvas.DrawColor = PlayerBarTextColor;
    Canvas.DrawColor.A = FadeAlpha;
    
	Canvas.SetPos(ScreenPos.X - (BarLength *0.5f), ScreenPos.Y - BarHeight * 2);
	Canvas.DrawText( KFPH.PlayerReplicationInfo.PlayerName,,FontScale,FontScale, MyFontRenderInfo );
}
simulated function bool DrawFriendlyHumanPlayerInfo( KFPawn_Human KFPH )
{
	local float Percentage;
	local float BarHeight, BarLength;
	local vector ScreenPos, TargetLocation;
	local ExtPlayerReplicationInfo KFPRI;
	local FontRenderInfo MyFontRenderInfo;
	local float FontScale;
	local float ResModifier;
	local float PerkIconPosX, PerkIconPosY, SupplyIconPosX, SupplyIconPosY, PerkIconSize;
	local color CurrentArmorColor, CurrentHealthColor, TextColor;
    local string S;
    local byte FadeAlpha;

	ResModifier = WorldInfo.static.GetResolutionBasedHUDScale() * FriendlyHudScale;
	KFPRI = ExtPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

	if( KFPRI == none )
	{
		return false;
	}

    FadeAlpha = DrawToDistance(KFPH);
	MyFontRenderInfo = Canvas.CreateFontRenderInfo( true );
	BarLength = FMin(PlayerStatusBarLengthMax * (Canvas.ClipX / 1024.f), PlayerStatusBarLengthMax) * ResModifier;
	BarHeight = FMin(8.f * (Canvas.ClipX / 1024.f), 8.f) * ResModifier;

	TargetLocation = KFPH.Mesh.GetPosition() + ( KFPH.CylinderComponent.CollisionHeight * vect(0,0,2.5f) );
	ScreenPos = Canvas.Project( TargetLocation );
	if( ScreenPos.X < 0 || ScreenPos.X > Canvas.ClipX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.ClipY )
	{
		return false;
	}

	//Draw player name (Top)
	FontScale = class'KFGameEngine'.Static.GetKFFontScale() * FriendlyHudScale;
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();

	// drop shadow for player name text
    S = KFPRI.PlayerName;
	if( KFPRI.bBot )
	{
		S = S$" (Bot)";
		TextColor = KFPRI.HUDPerkColor;
	}
	else if( KFPRI.ShowAdminName() ) // Admin info.
	{
		S = S$" ("$KFPRI.GetAdminNameAbr()$")";
		TextColor = KFPRI.GetAdminColorC();
	}
	else TextColor = PlayerBarTextColor;
    
	if( bMeAdmin && KFPRI.FixedData>0 )
	{
        TextColor = MakeColor(255,0,0,255);
		S @= "-"$KFPRI.GetDesc();
	}
    
    TextColor.A = FadeAlpha;
    
    Canvas.DrawColor = PlayerBarShadowColor;
    Canvas.DrawColor.A = FadeAlpha;
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.5f) + 1, ScreenPos.Y + 8);
	Canvas.DrawText(S, , FontScale, FontScale, MyFontRenderInfo);

    Canvas.DrawColor = TextColor;
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.5f), ScreenPos.Y + 7);
	Canvas.DrawText(S, , FontScale, FontScale, MyFontRenderInfo);

	//Draw armor bar
	Percentage = FMin(float(KFPH.Armor) / float(KFPH.MaxArmor), 100);
	CurrentArmorColor = ClassicPlayerInfo ? ClassicArmorColor : ArmorColor;
    CurrentArmorColor.A = FadeAlpha;
	DrawPlayerInfoBar(KFPH, Percentage, BarLength, BarHeight, ScreenPos.X - (BarLength * 0.5f), ScreenPos.Y + BarHeight + (36 * FontScale * ResModifier), CurrentArmorColor, FadeAlpha);

	//Draw health bar
	Percentage = FMin(float(KFPH.Health) / float(KFPH.HealthMax), 100);
	CurrentHealthColor = ClassicPlayerInfo ? ClassicHealthColor : HealthColor;
    CurrentHealthColor.A = FadeAlpha;
	DrawPlayerInfoBar(KFPH, Percentage, BarLength, BarHeight, ScreenPos.X - (BarLength * 0.5f), ScreenPos.Y + BarHeight * 2 + (36 * FontScale * ResModifier), CurrentHealthColor, FadeAlpha, true);

	if( KFPRI.ECurrentPerk == None )
	{
		return false;
	}

	// drop shadow for perk name text
    Canvas.DrawColor = PlayerBarShadowColor;
    Canvas.DrawColor.A = FadeAlpha;
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.5f) + 1, ScreenPos.Y + BarHeight * 3 + (36 * FontScale * ResModifier) + 1);
	Canvas.DrawText(KFPRI.GetPerkLevelStr()@KFPRI.ECurrentPerk.default.PerkName, , FontScale, FontScale, MyFontRenderInfo);

	//Draw perk level and name text
	Canvas.DrawColor = PlayerBarTextColor;
    Canvas.DrawColor.A = FadeAlpha;
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.5f), ScreenPos.Y + BarHeight * 3 + (36 * FontScale * ResModifier));
	Canvas.DrawText(KFPRI.GetPerkLevelStr()@KFPRI.ECurrentPerk.default.PerkName, , FontScale, FontScale, MyFontRenderInfo);

	// drop shadow for perk icon
    Canvas.DrawColor = PlayerBarShadowColor;
	Canvas.DrawColor.A = FadeAlpha;
	PerkIconSize = PlayerStatusIconSize * ResModifier;
	PerkIconPosX = ScreenPos.X - (BarLength * 0.5f) - PerkIconSize + 1;
	PerkIconPosY = ScreenPos.Y + (36 * FontScale * ResModifier) + 1;
	SupplyIconPosX = ScreenPos.X + (BarLength * 0.5f) + 1;
	SupplyIconPosY = PerkIconPosY + 4 * ResModifier;
	DrawPerkIcons(KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY, SupplyIconPosX, SupplyIconPosY, true);

	//draw perk icon
    Canvas.DrawColor = PlayerBarIconColor;
	Canvas.DrawColor.A = FadeAlpha;
	PerkIconPosX = ScreenPos.X - (BarLength * 0.5f) - PerkIconSize;
	PerkIconPosY = ScreenPos.Y + (36 * FontScale * ResModifier);
	SupplyIconPosX = ScreenPos.X + (BarLength * 0.5f);
	SupplyIconPosY = PerkIconPosY + 4 * ResModifier;
	DrawPerkIcons(KFPH, PerkIconSize, PerkIconPosX, PerkIconPosY, SupplyIconPosX, SupplyIconPosY, false);

	return true;
}
simulated final function DrawPlayerInfoBar( KFPawn P, float BarPercentage, float BarLength, float BarHeight, float XPos, float YPos, Color BarColor, byte FadeAlpha, optional bool bDrawingHealth )
{
	//background for status bar
	Canvas.DrawColor = PlayerBarBGColor;
    Canvas.DrawColor.A = FadeAlpha;
	Canvas.SetPos(XPos, YPos);
	Canvas.DrawTileStretched(PlayerStatusBarBGTexture, BarLength, BarHeight, 0, 0, 32, 32);

	XPos+=1;
	YPos+=1;
	BarLength-=2;
	BarHeight-=2;

	//Forground for status bar.
	Canvas.DrawColor = BarColor;
    Canvas.DrawColor.A = FadeAlpha;
	Canvas.SetPos(XPos, YPos);
	Canvas.DrawTileStretched(PlayerStatusBarBGTexture, BarLength * BarPercentage, BarHeight, 0, 0, 32, 32);
	
	if( bDrawingHealth && ExtHumanPawn(P) != None && P.Health<P.HealthMax && ExtHumanPawn(P).RepRegenHP>0 )
	{
		// Draw to-regen bar.
		XPos+=(BarLength * BarPercentage);
		BarPercentage = FMin(float(ExtHumanPawn(P).RepRegenHP) / float(P.HealthMax),1.f-BarPercentage);
		
        Canvas.DrawColor = MakeColor(255,128,128,FadeAlpha);
		Canvas.SetPos(XPos, YPos);
		Canvas.DrawTileStretched(PlayerStatusBarBGTexture, BarLength * BarPercentage, BarHeight, 0, 0, 32, 32);
	}
}
simulated function DrawPerkIcons(KFPawn_Human KFPH, float PerkIconSize, float PerkIconPosX, float PerkIconPosY, float SupplyIconPosX, float SupplyIconPosY, bool bDropShadow)
{
	local byte PrestigeLevel;
	local ExtPlayerReplicationInfo KFPRI;
	local color TempColor;
	local float ResModifier;

	KFPRI = ExtPlayerReplicationInfo(KFPH.PlayerReplicationInfo);

	if (KFPRI == none)
	{
		return;
	}

	PrestigeLevel = KFPRI.GetActivePerkPrestigeLevel();
	ResModifier = WorldInfo.static.GetResolutionBasedHUDScale() * FriendlyHudScale;

	if (KFPRI.CurrentVoiceCommsRequest == VCT_NONE && KFPRI.ECurrentPerk != none && PrestigeLevel > 0)
	{
		Canvas.SetPos(PerkIconPosX, PerkIconPosY);
		Canvas.DrawTile(KFPRI.ECurrentPerk.default.BasePerk.default.PrestigeIcons[PrestigeLevel - 1], PerkIconSize, PerkIconSize, 0, 0, 256, 256);
	}

	if (PrestigeLevel > 0)
	{																//icon slot in image is not centered
		Canvas.SetPos(PerkIconPosX + (PerkIconSize * (1 - PrestigeIconScale)) / 2, PerkIconPosY + PerkIconSize * 0.05f);
		Canvas.DrawTile(KFPRI.GetCurrentIconToDisplay(), PerkIconSize * PrestigeIconScale, PerkIconSize * PrestigeIconScale, 0, 0, 256, 256);
	}
	else
	{
		Canvas.SetPos(PerkIconPosX, PerkIconPosY);
		Canvas.DrawTile(KFPRI.GetCurrentIconToDisplay(), PerkIconSize, PerkIconSize, 0, 0, 256, 256);
	}

	if (KFPRI.PerkSupplyLevel > 0 && KFPRI.ECurrentPerk.default.BasePerk.static.GetInteractIcon() != none)
	{
		if (!bDropShadow)
		{
			if (KFPRI.PerkSupplyLevel == 2)
			{
				if (KFPRI.bPerkPrimarySupplyUsed && KFPRI.bPerkSecondarySupplyUsed)
				{
					TempColor = SupplierActiveColor;
				}
				else if (KFPRI.bPerkPrimarySupplyUsed || KFPRI.bPerkSecondarySupplyUsed)
				{
					TempColor = SupplierHalfUsableColor;
				}
				else
				{
					TempColor = SupplierUsableColor;
				}
			}
			else if (KFPRI.PerkSupplyLevel == 1)
			{
				TempColor = KFPRI.bPerkPrimarySupplyUsed ? SupplierActiveColor : SupplierUsableColor;
			}

			Canvas.SetDrawColorStruct(TempColor);
		}

		Canvas.SetPos(SupplyIconPosX, SupplyIconPosY); //offset so that supplier icon shows up on the correct side of the player's health bar
		Canvas.DrawTile(KFPRI.ECurrentPerk.default.BasePerk.static.GetInteractIcon(), (PlayerStatusIconSize * 0.75) * ResModifier, (PlayerStatusIconSize * 0.75) * ResModifier, 0, 0, 256, 256);
	}
}
simulated function DrawMonsterHUD( KFPawn KFPH )
{
	local float Percentage;
	local float BarHeight, BarLength;
	local vector ScreenPos, TargetLocation;
	local Ext_T_MonsterPRI PRI;
	local FontRenderInfo MyFontRenderInfo;
	local float FontScale;
    local byte FadeAlpha;

	PRI = Ext_T_MonsterPRI(KFPH.PlayerReplicationInfo);
	if( PRI==None )
		return;

    FadeAlpha = DrawToDistance(KFPH);
	MyFontRenderInfo = Canvas.CreateFontRenderInfo( true );

	BarLength = FMin(PlayerStatusBarLengthMax * (float(Canvas.SizeX) / 1024.f), PlayerStatusBarLengthMax) * FriendlyHudScale;
	BarHeight = FMin(8.f * (float(Canvas.SizeX) / 1024.f), 8.f) * FriendlyHudScale;

	TargetLocation = KFPH.Location + vect(0,0,1) * KFPH.GetCollisionHeight() * 0.8;

	ScreenPos = Canvas.Project(TargetLocation);
	if( ScreenPos.X < 0 || ScreenPos.X > Canvas.SizeX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.SizeY )
		return;

	//Draw health bar
	Percentage = FMin(float(KFPH.Health) / float(KFPH.HealthMax),1.f);
	DrawPlayerInfoBar(KFPH, Percentage, BarLength, BarHeight, ScreenPos.X - (BarLength *0.5f), ScreenPos.Y, HealthColor, FadeAlpha);

	//Draw player name (Top)
	FontScale = class'KFGameEngine'.Static.GetKFFontScale() * FriendlyHudScale;
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
	Canvas.DrawColor = PRI.OwnerPRI==PlayerOwner.PlayerReplicationInfo ? MakeColor(32,250,32,FadeAlpha) : MakeColor(250,32,32,FadeAlpha);
	Canvas.SetPos(ScreenPos.X - (BarLength *0.5f), ScreenPos.Y - BarHeight * 3);
	Canvas.DrawText( PRI.PlayerName,,FontScale,FontScale, MyFontRenderInfo );

	//draw HP icon
	Canvas.SetPos(ScreenPos.X - (BarLength * 0.75), ScreenPos.Y - BarHeight * 2);
	Canvas.DrawRect(PlayerStatusIconSize * FriendlyHudScale,PlayerStatusIconSize * FriendlyHudScale,HealthIconTex);
}
simulated function DrawPetInfo()
{
	local float X,Y,Sc,XL,YL,YS;
	local string S;
	local int i;
	
	X = Canvas.ClipX*0.165;
	Y = Canvas.ClipY*0.925;
	Canvas.Font = GUIStyle.PickFont(GUIStyle.DefaultFontSize,Sc);
	Canvas.TextSize("ABC",XL,YS,Sc,Sc);
	S = "Current Pet(s)";
	Canvas.TextSize(S,XL,YL,Sc,Sc);
	Y-=(YS*MyCurrentPet.Length);
	
	Canvas.SetDrawColor(120,0,0,145);
	GUIStyle.DrawRectBox( X, Y, BestPetXL * 1.04, YL, 4 );	
	
	Canvas.DrawColor = MakeColor(255,255,255,255);
	Canvas.SetPos(X,Y);
	Canvas.DrawText(S,,Sc,Sc);
	
	Canvas.SetDrawColor(8,8,8,145);
	GUIStyle.DrawRectBox( X, Y + YS, BestPetXL * 1.04, YL * MyCurrentPet.Length, 4 );
	
	Canvas.DrawColor = MakeColor(32,250,32,255);
	for( i=0; i<MyCurrentPet.Length; ++i )
	{
		if( MyCurrentPet[i]==None )
		{
			MyCurrentPet.Remove(i--,1);
			continue;
		}
		Y+=YS;
		S = MyCurrentPet[i].MonsterName$" ("$MyCurrentPet[i].HealthStatus$"/"$MyCurrentPet[i].HealthMax$"HP)";
		Canvas.TextSize(S,XL,YL,Sc,Sc);
		Canvas.SetPos(X,Y);
		Canvas.DrawText(S,,Sc,Sc);
		
		if( XL > BestPetXL )
			BestPetXL = XL;
		if( YL > BestPetYL )
			BestPetYL = YL;
	}
}

function byte DrawToDistance(Actor A, optional float StartAlpha=255.f, optional float MinAlpha=90.f)
{
    local float Dist, fZoom;

    Dist = VSize(A.Location - PLCameraLoc);
    if ( Dist <= HealthBarFullVisDist || PlayerOwner.PlayerReplicationInfo.bOnlySpectator )
        fZoom = 1.0;
    else fZoom = FMax(1.0 - (Dist - HealthBarFullVisDist) / (HealthBarCutoffDist - HealthBarFullVisDist), 0.0);
    
    return Clamp(StartAlpha * fZoom, MinAlpha, StartAlpha);
}

final function AddNumberMsg( int Amount, vector Pos, byte Type )
{
    local Color C;

    DamagePopups[NextDamagePopupIndex].Damage = Amount;
    DamagePopups[NextDamagePopupIndex].HitTime = WorldInfo.TimeSeconds;
    DamagePopups[NextDamagePopupIndex].Type = Type;
    DamagePopups[NextDamagePopupIndex].HitLocation = Pos;
    //ser random speed of fading out, so multiple damages in the same hit location don't overlap each other
    DamagePopups[NextDamagePopupIndex].RandX = 2.0 * FRand();
    DamagePopups[NextDamagePopupIndex].RandY = 1.0 + FRand();

    C.A = 255;
    if ( Type == 0 && Amount < 100 ) {
        C.R = 220;
        C.G = 0;
        C.B = 0;
    }   
	else if ( Type == 1 ) {
        C.R = 255;
        C.G = 255;
        C.B = 25;
    }
    else if ( Type == 2 ) {
        C.R = 32;
        C.G = 240;
        C.B = 32;
    }
    else if ( Amount >= 300 ) {
        C.R = 0;
        C.G = 206;
        C.B = 0;
    }
    else if ( Amount >= 100 ) {
        C.R = 206;
        C.G = 206;
        C.B = 0;
    }
    else {
        C.R = 127;
        C.G = 127;
        C.B = 127;
    }
    DamagePopups[NextDamagePopupIndex].FontColor = C;

    if( ++NextDamagePopupIndex >= DAMAGEPOPUP_COUNT)
        NextDamagePopupIndex=0;
}

final function DrawDamage()
{
    local int i;
    local float TimeSinceHit;
    local vector CameraLocation, CamDir;
    local rotator CameraRotation;
    local vector HBScreenPos;
    local float TextWidth, TextHeight, x, Sc;
	local string S;

	Canvas.Font = class'Engine'.Static.GetMediumFont();
	Sc = 1;
	
	KFPlayerController(Owner).GetPlayerViewPoint(CameraLocation, CameraRotation);
	CamDir = vector(CameraRotation);
	
    for( i=0; i < DAMAGEPOPUP_COUNT ; i++ ) 
	{
        TimeSinceHit = WorldInfo.TimeSeconds - DamagePopups[i].HitTime;
        if( TimeSinceHit > DamagePopupFadeOutTime
                || ( Normal(DamagePopups[i].HitLocation - CameraLocation) dot Normal(CamDir) < 0.1 ) ) //don't draw if player faced back to the hit location
            continue;
			
		switch( DamagePopups[i].Type )
		{
		case 0: // Pawn damage.
			S = "-"$string(DamagePopups[i].Damage);
			break;
		case 1: // EXP.
			S = "+"$string(DamagePopups[i].Damage)$" XP";
			break;
		case 2: // Health.
			S = "+"$string(DamagePopups[i].Damage)$" HP";
			break;
		}

        HBScreenPos = Canvas.Project(DamagePopups[i].HitLocation);
		Canvas.TextSize(S,TextWidth,TextHeight,Sc,Sc);
        //draw just on the hit location
        HBScreenPos.Y -= TextHeight/2;
        HBScreenPos.X -= TextWidth/2;

        //let numbers to fly up
        HBScreenPos.Y -= TimeSinceHit * TextHeight * DamagePopups[i].RandY;
        x = Sin(2*Pi * TimeSinceHit/DamagePopupFadeOutTime) * TextWidth * DamagePopups[i].RandX;
        // odd numbers start to flying to the right side, even - left
        // So in situations of decapitaion player could see both damages
        if ( i % 2 == 0)
            x *= -1.0;
        HBScreenPos.X += x;

        Canvas.DrawColor = DamagePopups[i].FontColor;
        Canvas.DrawColor.A = 255 * Cos(0.5*Pi * TimeSinceHit/DamagePopupFadeOutTime);

        Canvas.SetPos( HBScreenPos.X, HBScreenPos.Y);
        Canvas.DrawText( S );
    }
}

// Search for new inventory!
simulated function SearchInventoryForNewItem()
{
	local int i,j;

	if( WasNewlyAdded.Length!=OnlineSub.CurrentInventory.Length )
		WasNewlyAdded.Length = OnlineSub.CurrentInventory.Length;
	for( i=0; i<OnlineSub.CurrentInventory.Length; ++i )
	{
		if( OnlineSub.CurrentInventory[i].NewlyAdded==1 && WasNewlyAdded[i]==0 )
		{
			WasNewlyAdded[i] = 1;
			if( WorldInfo.TimeSeconds<80.f || !bLoadedInitItems ) // Skip initial inventory.
				continue;
			j = OnlineSub.ItemPropertiesList.Find('Definition', OnlineSub.CurrentInventory[i].Definition);

			if(j != INDEX_NONE)
			{
				NewItems.Insert(0,1);
				NewItems[0].Icon = Texture2D(DynamicLoadObject(OnlineSub.ItemPropertiesList[j].IconURL,Class'Texture2D'));
				NewItems[0].Item = OnlineSub.ItemPropertiesList[j].Name$" ["$RarityStr(OnlineSub.ItemPropertiesList[j].Rarity)$"]";
				NewItems[0].MsgTime = WorldInfo.TimeSeconds;
				ExtPlayerController(Owner).ServerItemDropGet(NewItems[0].Item);
			}
		}
	}
	bLoadedInitItems = true;
}
simulated final function string RarityStr( byte R )
{
	switch( R )
	{
	case ITR_Common:			return "Common";
	case ITR_Uncommon:			return "Uncommon +";
	case ITR_Rare:				return "Rare ++";
	case ITR_Legendary:			return "Legendary +++";
	case ITR_ExceedinglyRare:	return "Exceedingly Rare ++++";
	case ITR_Mythical:			return "Mythical !!!!";
	default:					return "Unknown -";
	}
}

simulated final function DrawItemsList()
{
	local int i;
	local float T,FontScale,XS,YS,YSize,XPos,YPos;
	
	FontScale = Canvas.ClipY / 660.f;
	Canvas.Font = GetFontSizeIndex(0);
	Canvas.TextSize("ABC",XS,YSize,FontScale,FontScale);
	YSize*=2.f;
	YPos = Canvas.ClipY*0.82 - YSize;
	XPos = Canvas.ClipX - YSize*0.15;

	for( i=0; i<NewItems.Length; ++i )
	{
		T = WorldInfo.TimeSeconds-NewItems[i].MsgTime;
		if( T>=10.f )
		{
			NewItems.Remove(i--,1);
			continue;
		}
		if( T>9.f )
		{
			T = 255.f * (10.f-T);
			Canvas.SetDrawColor(255,255,255,T);
		}
		else Canvas.SetDrawColor(255,255,255,255);
		
		Canvas.TextSize(NewItems[i].Item,XS,YS,FontScale,FontScale);

		/*if( NewItems[i].Icon!=None )
		{
			Canvas.SetPos(XPos-YSize,YPos);
			Canvas.DrawRect(YSize,YSize,NewItems[i].Icon);
			XS = XPos-(YSize*1.1)-XS;
		}
		else */XS = XPos-XS;
		
		Canvas.SetPos(XS,YPos);
		Canvas.DrawText("New Item:",,FontScale,FontScale);
		Canvas.SetPos(XS,YPos+(YSize*0.5));
		Canvas.DrawText(NewItems[i].Item,,FontScale,FontScale);

		YPos-=YSize;
	}
}

simulated function CheckForItems()
{
	if( KFGameReplicationInfo(WorldInfo.GRI)!=none )
		KFGameReplicationInfo(WorldInfo.GRI).ProcessChanceDrop();
	SetTimer(260+FRand()*220.f,false,'CheckForItems');
}

defaultproperties
{
	//DownArrowTex=Texture2D'UI_Widgets.MenuBarWidget_SWF_I10'
	//MiddleTex=Texture2D'UI_Widgets.MenuBarWidget_SWF_I14'
	//WaveBossTex=Texture2D'UI_HUD.InGameHUD_SWF_I35'
	//WaveProgTex=Texture2D'UI_HUD.InGameHUD_SWF_IF5'
	//TraderTimeTex=Texture2D'UI_HUD.InGameHUD_SWF_IF7'
	//SyringeBarTex=Texture2D'UI_HUD.InGameHUD_SWF_I155'
	//ArmorIconTex=Texture2D'UI_HUD.InGameHUD_SWF_I16A'
	HealthIconTex=Texture2D'UI_Objective_Tex.UI_Obj_Healing_Loc'
	//BatteryIconTex=Texture2D'UI_HUD.InGameHUD_SWF_I109'
	BlackBGColor=(R=4,G=4,B=4,A=186)
	RedBGColor=(R=164,G=32,B=32,A=186)
	HUDTextColor=(R=250,G=250,B=250,A=186)
	HUDClass=class'ExtMoviePlayer_HUD'
	
	HealthBarFullVisDist=350
	HealthBarCutoffDist=3500
	DamagePopupFadeOutTime=3.000000
	
	BadConnectionStr="Warning: Connection problem!"
}
