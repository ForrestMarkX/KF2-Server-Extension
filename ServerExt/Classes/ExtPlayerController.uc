Class ExtPlayerController extends KFPlayerController;

struct FAdminCmdType
{
	var string Cmd,Info;
};
enum EDmgMsgType
{
	DMG_PawnDamage,
	DMG_EXP,
	DMG_Heal,
};
var string ServerMOTD,PendingMOTD;

var ExtPerkManager ActivePerkManager;
var class<KFGUI_Page> MidGameMenuClass;
var class<Ext_PerkBase> PendingPerkClass;
var private transient rotator OldViewRot;
var private transient float LastMisfireTime,LastFireTime,MisfireTimer;
var private transient byte MisfireCount,MisrateCounter;
var transient float NextSpectateChange,NextCommTime;
var array<FAdminCmdType> AdminCommands;
var transient byte DropCount;
var transient Object UserAPI;
var transient SoundCue BonusMusic;
var transient Object BonusFX;

// Stats
var transient byte TransitListNum;
var transient int TransitIndex;

// Dramatic end-game camera.
var transient vector EndGameCamFocusPos[2],CalcViewLocation;
var transient rotator EndGameCamRot,CalcViewRotation;
var transient float EndGameCamTimer,LastPlayerCalcView;
var transient bool bEndGameCamFocus;

var globalconfig bool bShowFPLegs,bHideNameBeacons,bHideKillMsg,bHideDamageMsg,bHideNumberMsg,bNoMonsterPlayer,bNoScreenShake,bRenderModes,bUseKF2DeathMessages,bUseKF2KillMessages;
var globalconfig int SelectedEmoteIndex;
var bool bMOTDReceived,bNamePlateShown,bNamePlateHidden,bClientHideKillMsg,bClientHideDamageMsg,bClientHideNumbers,bNoDamageTracking,bClientNoZed,bSetPerk;

struct SavedSkins
{
	var int ID;
	var class<KFWeaponDefinition> WepDef;
};
var globalconfig array<SavedSkins> SavedWeaponSkins;

replication
{
	// Things the server should send to the client.
	if ( bNetDirty )
		MidGameMenuClass,ActivePerkManager;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( WorldInfo.NetMode!=NM_Client && ActivePerkManager==None )
	{
		ActivePerkManager = Spawn(class'ExtPerkManager',Self);
		ActivePerkManager.PlayerOwner = Self;
		ActivePerkManager.PRIOwner = ExtPlayerReplicationInfo(PlayerReplicationInfo);
		if( ActivePerkManager.PRIOwner!=None )
			ActivePerkManager.PRIOwner.PerkManager = ActivePerkManager;
		SetTimer(0.1,true,'CheckPerk');
	}
}
simulated function Destroyed()
{
	if( ActivePerkManager!=None )
		ActivePerkManager.PreNotifyPlayerLeave();
	Super.Destroyed();
	if( ActivePerkManager!=None )
		ActivePerkManager.Destroy();
}
function CheckPerk()
{
	if( CurrentPerk!=ActivePerkManager )
	{
		CurrentPerk = ActivePerkManager;
		if( KFPlayerReplicationInfo(PlayerReplicationInfo)!=None )
		{
			KFPlayerReplicationInfo(PlayerReplicationInfo).NetPerkIndex = 0;
			KFPlayerReplicationInfo(PlayerReplicationInfo).CurrentPerkClass = ActivePerkManager.Class;
		}
	}
}

reliable client function AddAdminCmd( string S )
{
	local int i,j;
	
	j = InStr(S,":");
	i = AdminCommands.Length;
	AdminCommands.Length = i+1;
	if( j==-1 )
	{
		AdminCommands[i].Cmd = S;
		AdminCommands[i].Info = S;
	}
	else
	{
		AdminCommands[i].Cmd = Left(S,j);
		AdminCommands[i].Info = Mid(S,j+1);
	}
}
reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	Super.ClientSetHUD(newHUDType);
	SendServerSettings();
}
reliable client function ClientSetBonus( SoundCue C, Object FX )
{
	BonusMusic = C;
	BonusFX = FX;
}
simulated final function SendServerSettings()
{
	if( LocalPlayer(Player)!=None )
		ServerSetSettings(bHideKillMsg,bHideDamageMsg,bHideNumberMsg,bNoMonsterPlayer);
}
reliable server function ServerSetSettings( bool bHideKill, bool bHideDmg, bool bHideNum, bool bNoZ )
{
	bClientHideKillMsg = bHideKill;
	bClientHideDamageMsg = bHideDmg;
	bClientHideNumbers = bHideNum;
	bNoDamageTracking = (bHideDmg && bHideNum);
	bClientNoZed = bNoZ;
}
unreliable server function NotifyFixed( byte Mode )
{
	if( Mode==1 && (Pawn==None || (WorldInfo.TimeSeconds-Pawn.SpawnTime)<5.f) )
		return;
	OnClientFixed(Self,Mode);
	if( Default.bRenderModes && ExtPlayerReplicationInfo(PlayerReplicationInfo)!=None )
		ExtPlayerReplicationInfo(PlayerReplicationInfo).SetFixedData(Mode);
}
delegate OnClientFixed( ExtPlayerController PC, byte Mode );

reliable client event ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	if( Message!=class'KFLocalMessage_PlayerKills' && (Message!=class'KFLocalMessage_Game' || (Switch!=KMT_Suicide && Switch!=KMT_Killed)) )
		Super.ReceiveLocalizedMessage(Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

function AddZedKill( class<KFPawn_Monster> MonsterClass, byte Difficulty, class<DamageType> DT )
{
	// Stats.
	if( ActivePerkManager!=None )
	{
		ActivePerkManager.TotalKills++;
		ActivePerkManager.PRIOwner.RepKills++;
	}
}

unreliable client function ClientPlayCameraShake( CameraShake Shake, optional float Scale=1.f, optional bool bTryForceFeedback, optional ECameraAnimPlaySpace PlaySpace=CAPS_CameraLocal, optional rotator UserPlaySpaceRot )
{
	if( !bNoScreenShake )
		Super.ClientPlayCameraShake(Shake,Scale,bTryForceFeedback,PlaySpace,UserPlaySpaceRot);
}

exec final function AwardXP( int XP, optional byte Mode )
{
	if( WorldInfo.NetMode!=NM_Client && ActivePerkManager!=None )
		ActivePerkManager.EarnedEXP(XP,Mode);
}

/** Perk xp stat */
function OnPlayerXPAdded(INT XP, class<KFPerk> PerkClass)
{
	AwardXP(XP);
}

function AddSmallRadiusKill( byte Difficulty )
{
	AwardXP(class'KFPerk_Berserker'.static.GetSmallRadiusKillXP(Difficulty));
}
function AddWeldPoints( int PointsWelded )
{
	AwardXP(PointsWelded,1);
}
function AddHealPoints( int PointsHealed )
{
	AwardXP(PointsHealed,2);
}

function AddShotsHit( int AddedHits )
{
	local KFWeapon W;
	local float T;

	Super.AddShotsHit(AddedHits);
	W = KFWeapon(Pawn.Weapon);
	if( W==None )
	{
		if( LastMisfireTime>WorldInfo.TimeSeconds )
		{
			if( ++MisfireCount>15 && (WorldInfo.TimeSeconds-MisfireTimer)>10.f )
				NotifyFixed(8);
			LastMisfireTime = WorldInfo.TimeSeconds+2.f;
			return;
		}
		MisfireCount = 0;
		LastMisfireTime = WorldInfo.TimeSeconds+2.f;
		MisfireTimer = WorldInfo.TimeSeconds;
		return;
	}
	if( !W.HasAmmo(W.CurrentFireMode) )
	{
		if( LastMisfireTime>WorldInfo.TimeSeconds )
		{
			if( ++MisfireCount>15 && (WorldInfo.TimeSeconds-MisfireTimer)>10.f )
				NotifyFixed(16);
			LastMisfireTime = WorldInfo.TimeSeconds+2.f;
			return;
		}
		MisfireCount = 0;
		LastMisfireTime = WorldInfo.TimeSeconds+2.f;
		MisfireTimer = WorldInfo.TimeSeconds;
		return;
	}
	T = W.GetFireInterval(W.CurrentFireMode);
	ActivePerkManager.ModifyRateOfFire(T,W);
	if( (WorldInfo.TimeSeconds-LastFireTime)<(T*0.5) || !W.IsFiring() )
	{
		if( (WorldInfo.TimeSeconds-LastFireTime)>4.f )
			MisrateCounter = 0;
		LastFireTime = WorldInfo.TimeSeconds;
		if( MisrateCounter<5 )
		{
			++MisrateCounter;
			return;
		}
		if( LastMisfireTime>WorldInfo.TimeSeconds )
		{
			if( ++MisfireCount>15 && (WorldInfo.TimeSeconds-MisfireTimer)>10.f )
				NotifyFixed(2);
			LastMisfireTime = WorldInfo.TimeSeconds+1.f;
			return;
		}
		MisfireCount = 0;
		LastMisfireTime = WorldInfo.TimeSeconds+1.f;
		MisfireTimer = WorldInfo.TimeSeconds;
	}
	else MisrateCounter = 0;
}

// Message of the day.
Delegate OnSetMOTD( ExtPlayerController PC, string S );
reliable client function ReceiveServerMOTD( string S, bool bFinal )
{
	ServerMOTD $= S;
	bMOTDReceived = bFinal;
}
reliable server function ServerSetMOTD( string S, bool bFinal )
{
	PendingMOTD $= S;
	if( bFinal && PendingMOTD!="" )
	{
		OnSetMOTD(Self,PendingMOTD);
		PendingMOTD = "";
	}
}

// TESTING:
reliable server function ServerItemDropGet( string Item )
{
	if( DropCount>5 || Len(Item)>100 )
		return;
	++DropCount;
	WorldInfo.Game.Broadcast(Self,PlayerReplicationInfo.GetHumanReadableName()$" got item: "$Item);
}

reliable client function ReceiveLevelUp( Ext_PerkBase Perk, int NewLevel )
{
	if( Perk!=None )
		MyGFxHUD.LevelUpNotificationWidget.ShowAchievementNotification(class'KFGFxWidget_LevelUpNotification'.Default.LevelUpString, Perk.PerkName, class'KFGFxWidget_LevelUpNotification'.Default.TierUnlockedString, Perk.GetPerkIconPath(NewLevel), false, NewLevel);
}
reliable client function ReceiveKillMessage( class<Pawn> Victim, optional bool bGlobal, optional PlayerReplicationInfo KillerPRI )
{
	if( bHideKillMsg || (bGlobal && KillerPRI==None) )
		return;
	if( bUseKF2KillMessages )
	{
		if( MyGFxHUD != none )
		{
			ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX( (bGlobal ? KillerPRI : None), None, ,false, Victim );
		}
	}
	else if( KFExtendedHUD(myHUD)!=None && Victim!=None )
		KFExtendedHUD(myHUD).AddKillMessage(Victim,1,KillerPRI,byte(bGlobal));
}
unreliable client function ReceiveDamageMessage( class<Pawn> Victim, int Damage )
{
	if( !bHideDamageMsg && KFExtendedHUD(myHUD)!=None && Victim!=None )
		KFExtendedHUD(myHUD).AddKillMessage(Victim,Damage,None,2);
}
unreliable client function ClientNumberMsg( int Count, vector Pos, EDmgMsgType Type )
{
	if( !bHideNumberMsg && KFExtendedHUD(myHUD)!=None )
		KFExtendedHUD(myHUD).AddNumberMsg(Count,Pos,Type);
}

reliable client event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime  )
{
	//if( ( ( Type == 'Say' ) || (Type == 'TeamSay' ) ) && ( PRI != None ) )
	//	SpeakTTS( S, PRI ); <- KF built without TTS...

	// since this is on the client, we can assume that if Player exists, it is a LocalPlayer
	if( Player!=None )
	{
		if( ( ( Type == 'Say' ) || ( Type == 'TeamSay' ) ) && ( PRI != None ) )
			S = PRI.GetHumanReadableName()$": "$S;
		LocalPlayer( Player ).ViewportClient.ViewportConsole.OutputText( "("$Type$") "$S );
	}
	
	if (MyGFxManager != none && MyGFxManager.PartyWidget != none)
    {
    	if( !MyGFxManager.PartyWidget.ReceiveMessage(S) )  //Fails if message is for updating perks in a steam lobby
    		return;
    }

    if( MyGFxHUD != none )
    {
		switch( Type )
		{
		case 'Log':
			break; // Console only message.
		case 'Music':
			MyGFxHUD.MusicNotification.ShowSongInfo(S);
			break;
		case 'Event':
			MyGFxHUD.HudChatBox.AddChatMessage(S, class 'KFLocalMessage'.default.DefaultColor);
			break;
		case 'DeathMessage':
			//MyGFxHUD.HudChatBox.AddChatMessage(S, "FF0000"); // Console message only.
			break;
		case 'Say':
		case 'TeamSay':
			if( ExtPlayerReplicationInfo(PRI)!=None && ExtPlayerReplicationInfo(PRI).ShowAdminName() )
				MyGFxHUD.HudChatBox.AddChatMessage("("$ExtPlayerReplicationInfo(PRI).GetAdminNameAbr()$")"$S, ExtPlayerReplicationInfo(PRI).GetAdminColor());
    		else MyGFxHUD.HudChatBox.AddChatMessage(S, "64FE2E");
			break;
		case 'Priority':
			MyGFxHUD.HudChatBox.AddChatMessage(S, class 'KFLocalMessage'.default.PriorityColor);
			break;
		case 'CriticalEvent':
			PopScreenMsg(S); // HIGH|Low|Time
			break;
		case 'LowCriticalEvent':
			MyGFxHUD.ShowNonCriticalMessage(S);
			break;
		default:
			MyGFxHUD.HudChatBox.AddChatMessage(class'KFLocalMessage'.default.SystemString@S, class 'KFLocalMessage'.default.EventColor);
		}
	}
}
final function PopScreenMsg( string S )
{
	local int i;
	local string L;
	local float T;
	
	T = 4.f;
	
	// Get lower part.
	i = InStr(S,"|");
	if( i!=-1 )
	{
		L = Mid(S,i+1);
		S = Left(S,i);
		
		// Get time.
		i = InStr(L,"|");
		if( i!=-1 )
		{
			T = float(Mid(L,i+1));
			L = Left(L,i);
		}
	}
	MyGFxHUD.DisplayPriorityMessage(S,L,T);
}
reliable client function ClientKillMessage( class<DamageType> DamType, PlayerReplicationInfo Victim, PlayerReplicationInfo KillerPRI, optional class<Pawn> KillerPawn )
{
	local string Msg,S;
	local bool bFF;

	if( Player==None || Victim==None )
		return;
	
	if( bUseKF2DeathMessages && MyGFxHUD!=None )
	{
		if( Victim==KillerPRI || (KillerPRI==None && KillerPawn==None) ) // Suicide
			ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX( None, Victim, ,true );
		else ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX( KillerPRI, Victim, ,true, KillerPawn );
	}
	if( Victim==KillerPRI || (KillerPRI==None && KillerPawn==None) ) // Suicide
	{
		if( Victim.GetTeamNum()==0 )
		{
			Msg = ParseSuicideMsg(Chr(6)$"O"$Victim.GetHumanReadableName(),DamType);
			class'KFMusicStingerHelper'.static.PlayPlayerDiedStinger(Self);
		}
		else Msg = ParseSuicideMsg(Chr(6)$"K"$Victim.GetHumanReadableName(),DamType);
	}
	else
	{
		if( KillerPRI!=None && Victim.Team!=None && Victim.Team==KillerPRI.Team ) // Team-kill
		{
			bFF = true;
			S = KillerPRI.GetHumanReadableName();
			class'KFMusicStingerHelper'.static.PlayTeammateDeathStinger(Self);
		}
		else // Killed by monster.
		{
			bFF = false;
			if( KillerPRI!=None )
			{
				S = KillerPRI.GetHumanReadableName();
			}
			else
			{
				S = class'KFExtendedHUD'.Static.GetNameOf(KillerPawn);
				if( class<KFPawn_Monster>(KillerPawn)!=None && class<KFPawn_Monster>(KillerPawn).Default.MinSpawnSquadSizeType==EST_Boss ) // Boss type.
					S = "the "$S;
				else S = class'KFExtendedHUD'.Static.GetNameArticle(S)@S;
			}
			class'KFMusicStingerHelper'.static.PlayZedKillHumanStinger(Self);
		}
		Msg = ParseKillMsg(Victim.GetHumanReadableName(),S,bFF,DamType);
	}
	S = Class'KFExtendedHUD'.Static.StripMsgColors(Msg);
	if( !bUseKF2DeathMessages )
		KFExtendedHUD(myHUD).AddDeathMessage(Msg,S);
	ClientMessage(S,'DeathMessage');
}
reliable client function ClientZedKillMessage( class<DamageType> DamType, string Victim, optional PlayerReplicationInfo KillerPRI, optional class<Pawn> KillerPawn, optional bool bFFKill )
{
	local string Msg,S;

	if( Player==None )
		return;
	if( bUseKF2DeathMessages && MyGFxHUD!=None )
	{
		if( KillerPRI==None && KillerPawn==None ) // Suicide
			ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX( None, None, Victim, true );
		else ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX( KillerPRI, None, Victim, true, KillerPawn );
	}
	if( KillerPRI==None && KillerPawn==None ) // Suicide
	{
		Msg = ParseSuicideMsg(Chr(6)$"O"$Victim,DamType);
	}
	else
	{
		if( KillerPRI!=None ) // Team-kill
		{
			S = KillerPRI.GetHumanReadableName();
		}
		else // Killed by monster.
		{
			S = class'KFExtendedHUD'.Static.GetNameOf(KillerPawn);
			if( class<KFPawn_Monster>(KillerPawn)!=None && class<KFPawn_Monster>(KillerPawn).Default.MinSpawnSquadSizeType==EST_Boss ) // Boss type.
				S = "the "$S;
			else S = class'KFExtendedHUD'.Static.GetNameArticle(S)@S;
		}
		Msg = ParseKillMsg(Victim,S,bFFKill,DamType);
	}
	S = Class'KFExtendedHUD'.Static.StripMsgColors(Msg);
	if( !bUseKF2DeathMessages )
		KFExtendedHUD(myHUD).AddDeathMessage(Msg,S);
	ClientMessage(S,'DeathMessage');
}
simulated final function string ParseSuicideMsg( string Victim, class<DamageType> DamType )
{
	local string S;

	S = string(DamType.Name);
	if( Left(S,15)~="KFDT_Ballistic_" )
	{
		S = Mid(S,15); // Weapon name.
		return Victim$Chr(6)$"M killed himself with "$S;
	}
	else if( class<KFDT_Fire>(DamType)!=None )
		return Victim$Chr(6)$"M was burned to death";
	else if( class<KFDT_Explosive>(DamType)!=None )
		return Victim$Chr(6)$"M was blown into pieces";
	return Victim$Chr(6)$"M had a sudden heart attack";
}
simulated final function string ParseKillMsg( string Victim, string Killer, bool bFF, class<DamageType> DamType )
{
	local string T,S;

	T = (bFF ? "O" : "K");
	S = string(DamType.Name);
	if( Left(S,15)~="KFDT_Ballistic_" )
	{
		S = Mid(S,15); // Weapon name.
		return Chr(6)$"O"$Victim$Chr(6)$"M was killed by "$Chr(6)$T$Killer$Chr(6)$"M's "$S;
	}
	else if( class<KFDT_Fire>(DamType)!=None )
		return Chr(6)$"O"$Victim$Chr(6)$"M was incinerated by "$Chr(6)$T$Killer;
	else if( class<KFDT_Explosive>(DamType)!=None )
		return Chr(6)$"O"$Victim$Chr(6)$"M was blown up by "$Chr(6)$T$Killer;
	return Chr(6)$"O"$Victim$Chr(6)$"M was killed by "$Chr(6)$T$Killer;
}

reliable server function ServerCamera( name NewMode )
{
	// <- REMOVED CAMERA LOGGING (PlayerController)
	if ( NewMode == '1st' )
    	NewMode = 'FirstPerson';
    else if ( NewMode == '3rd' )
    	NewMode = 'ThirdPerson';
	SetCameraMode( NewMode );
}
exec function Camera( name NewMode )
{
	ServerCamera( PlayerCamera.CameraStyle=='FirstPerson' ? 'ThirdPerson' : 'FirstPerson' );
}
simulated final function ToggleFPBody( bool bEnable )
{
	bShowFPLegs = bEnable;
	Class'ExtPlayerController'.Default.bShowFPLegs = bEnable;
	
	if( ExtHumanPawn(Pawn)!=None )
		ExtHumanPawn(Pawn).UpdateFPLegs();
}

/*exec function KickBan( string S )
{
	if( WorldInfo.Game!=None )
		WorldInfo.Game.KickBan(S);
}*/
exec function Kick( string S )
{
	if( WorldInfo.Game!=None )
		WorldInfo.Game.Kick(S);
}
reliable server function SkipLobby();

Delegate OnChangePerk( ExtPlayerController PC, class<Ext_PerkBase> NewPerk );

reliable server function SwitchToPerk( class<Ext_PerkBase> PerkClass )
{
	if( PerkClass!=None )
		OnChangePerk(Self,PerkClass);
}

Delegate OnBoughtStats( ExtPlayerController PC, class<Ext_PerkBase> PerkClass, int iStat, int Amount );

reliable server function BuyPerkStat( class<Ext_PerkBase> PerkClass, int iStat, int Amount )
{
	if( PerkClass!=None && Amount>0 && iStat>=0 )
		OnBoughtStats(Self,PerkClass,iStat,Amount);
}

Delegate OnBoughtTrait( ExtPlayerController PC, class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait );

reliable server function BoughtTrait( class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait )
{
	if( PerkClass!=None && Trait!=None )
		OnBoughtTrait(Self,PerkClass,Trait);
}

Delegate OnPerkReset( ExtPlayerController PC, class<Ext_PerkBase> PerkClass, bool bPrestige );

reliable server function ServerResetPerk( class<Ext_PerkBase> PerkClass, bool bPrestige )
{
	if( PerkClass!=None )
		OnPerkReset(Self,PerkClass,bPrestige);
}

Delegate OnAdminHandle( ExtPlayerController PC, int PlayerID, int Action );

reliable server function AdminRPGHandle( int PlayerID, int Action )
{
	OnAdminHandle(Self,PlayerID,Action);
}

simulated reliable client event bool ShowConnectionProgressPopup( EProgressMessageType ProgressType, string ProgressTitle, string ProgressDescription, bool SuppressPasswordRetry = false)
{
	switch(ProgressType)
	{
	case    PMT_ConnectionFailure :
	case    PMT_PeerConnectionFailure :
		KFExtendedHUD(myHUD).NotifyLevelChange();
		KFExtendedHUD(myHUD).ShowProgressMsg("Connection Error: "$ProgressTitle$"|"$ProgressDescription$"|Disconnecting...",true);
		return true;
	case    PMT_DownloadProgress :
		KFExtendedHUD(myHUD).NotifyLevelChange();
	case	PMT_AdminMessage :
		KFExtendedHUD(myHUD).ShowProgressMsg(ProgressTitle$"|"$ProgressDescription);
		return true;
	}
	return false;
}

simulated function CancelConnection()
{
	if( KFExtendedHUD(myHUD)!=None )
		KFExtendedHUD(myHUD).CancelConnection();
	else class'Engine'.Static.GetEngine().GameViewport.ConsoleCommand("Disconnect");
}

function NotifyLevelUp(class<KFPerk> PerkClass, byte PerkLevel);

function ShowBossNameplate( KFInterface_MonsterBoss KFBoss, optional string PlayerName)
{
	if( !bNamePlateShown ) // Dont make multiple bosses pop this up multiple times.
	{
		bNamePlateShown = true;
		Super.ShowBossNameplate(KFBoss,PlayerName);
		SetTimer(8,false,'HideBossNameplate'); // MAKE sure it goes hidden.
	}
}
function HideBossNameplate()
{	
	if( !bNamePlateHidden )
	{
		bNamePlateHidden = false;
		Super.HideBossNameplate();
		ClearTimer('HideBossNameplate');
		if( MyGFxHUD!=None )
			MyGFxHUD.MusicNotification.SetVisible(true);
	}
}

function UpdateRotation( float DeltaTime )
{
	if( OldViewRot!=Rotation && Pawn!=None && Pawn.IsAliveAndWell() )
		NotifyFixed(1);
	Super.UpdateRotation(DeltaTime);
	OldViewRot = Rotation;
}

reliable server function ServerGetUnloadInfo( byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload )
{
	OnRequestUnload(Self,CallID,PerkClass,bUnload);
}
delegate OnRequestUnload( ExtPlayerController PC, byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload );

reliable client function ClientGotUnloadInfo( byte CallID, byte Code, optional int DataA, optional int DataB )
{
	OnClientGetResponse(CallID,Code,DataA,DataB);
}
delegate OnClientGetResponse( byte CallID, byte Code, int DataA, int DataB );
function DefClientResponse( byte CallID, byte Code, int DataA, int DataB );

reliable client function ClientUsedAmmo( Ext_T_SupplierInteract S )
{
	if( Pawn!=None && S!=None )
		S.UsedOnClient(Pawn);
}

unreliable server function ServerNextSpectateMode()
{
	local Pawn HumanViewTarget;

	if( !IsSpectating() )
		return;

	// switch to roaming if human viewtarget is dead
	if( CurrentSpectateMode != SMODE_Roaming )
	{
		HumanViewTarget = Pawn(ViewTarget);
		if( HumanViewTarget == none || !HumanViewTarget.IsAliveAndWell() )
		{
			SpectateRoaming();
			return;
		}
	}

	switch ( CurrentSpectateMode )
	{
	case SMODE_PawnFreeCam:
		SpectatePlayer( SMODE_PawnThirdPerson );
		break;
	case SMODE_PawnThirdPerson:
		SpectatePlayer( SMODE_PawnFirstPerson );
		break;
	case SMODE_PawnFirstPerson:
	case SMODE_Roaming:
		SpectatePlayer( SMODE_PawnFreeCam );
		break;
	}
}

function ViewAPlayer(int dir)
{
	local PlayerReplicationInfo PRI;

	PRI = GetNextViewablePlayer(dir);
	if ( PRI!=None )
	{
		SetViewTarget(PRI);
		ClientMessage("Now viewing from "$PRI.GetHumanReadableName());
	}
}

exec function ViewPlayerID( int ID )
{
	ServerViewPlayerID(ID);
}
reliable server function ServerViewPlayerID( int ID )
{
	local PlayerReplicationInfo PRI;

	if( !IsSpectating() )
		return;

	// Find matching player by ID
	foreach WorldInfo.GRI.PRIArray(PRI)
	{
		if ( PRI.PlayerID==ID )
			break;
	}
	if( PRI==None || PRI.PlayerID!=ID || Controller(PRI.Owner)==None || Controller(PRI.Owner).Pawn==None || !WorldInfo.Game.CanSpectate(self, PRI) )
		return;
	
	SetViewTarget(PRI);
	ClientMessage("Now viewing from "$PRI.GetHumanReadableName());
	if( CurrentSpectateMode==SMODE_Roaming )
		SpectatePlayer( SMODE_PawnFreeCam );
}

reliable server function SpectateRoaming()
{
	local Pawn P;
	
	P = Pawn(ViewTarget);
	ClientMessage("Viewing from own camera.");
	Super.SpectateRoaming();
	if( P!=None )
	{
		SetLocation(P.Location);
		SetRotation(P.GetViewRotation());
		ClientSetLocation(Location,Rotation);
	}
}
reliable client function ClientSetLocation( vector NewLocation, rotator NewRotation )
{
	SetLocation(NewLocation);
	Super.ClientSetLocation(NewLocation,NewRotation);
}

unreliable server function ServerPlayLevelUpDialog()
{
	if( NextCommTime<WorldInfo.TimeSeconds )
	{
		NextCommTime = WorldInfo.TimeSeconds+2.f;
		Super.ServerPlayLevelUpDialog();
	}
}
unreliable server function ServerPlayVoiceCommsDialog( int CommsIndex )
{
	if( NextCommTime<WorldInfo.TimeSeconds )
	{
		NextCommTime = WorldInfo.TimeSeconds+2.f;
		Super.ServerPlayVoiceCommsDialog(CommsIndex);
	}
}

// The player wants to fire.
// Setup bFire/bAltFire so that Auto-Fire trait will work.
exec function StartFire( optional byte FireModeNum )
{
	if( FireModeNum==0 )
		bFire = 1;
	else if( FireModeNum==1 )
		bAltFire = 1;
	Super.StartFire(FireModeNum);
}
exec function StopFire( optional byte FireModeNum )
{
	if( FireModeNum==0 )
		bFire = 0;
	else if( FireModeNum==1 )
		bAltFire = 0;
	Super.StopFire(FireModeNum);
}

state Spectating
{
	function BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);
		bCollideWorld = false;
	}
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		Acceleration = Normal(NewAccel) * SpectatorCameraSpeed;
		Velocity = Acceleration;
		MoveSmooth( Acceleration * DeltaTime );
	}
	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local rotator OldRotation;

		OldRotation = Rotation;
		GetAxes(Rotation,X,Y,Z);
		Acceleration = (Normal(PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1)) - bDuck*vect(0,0,1))*100.f;
		UpdateRotation(DeltaTime);

		if (Role < ROLE_Authority) // then save this move and replicate it
		{
			ReplicateMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
			
			// only done for clients, as LastActiveTime only affects idle kicking
			if( (!IsZero(Acceleration) || OldRotation != Rotation) && LastUpdateSpectatorActiveTime<WorldInfo.TimeSeconds )
			{
				LastUpdateSpectatorActiveTime = WorldInfo.TimeSeconds+UpdateSpectatorActiveInterval;
				ServerSetSpectatorActive();
			}
		}
		else
		{
			ProcessMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
		}
	}
	exec function SpectateNextPlayer()
	{
		SpectateRoaming();
	}
	exec function SpectatePreviousPlayer()
	{
		ServerViewNextPlayer();
		if( Role == ROLE_Authority )
		{
			NotifyChangeSpectateViewTarget();
		}
	}
	unreliable server function ServerViewNextPlayer()
	{
		if( CurrentSpectateMode==SMODE_Roaming )
		{
			CurrentSpectateMode = SMODE_PawnFreeCam;
			SetCameraMode('FreeCam');
		}
		Global.ServerViewNextPlayer();
	}
	reliable client function ClientSetCameraMode( name NewCamMode )
	{
		Global.ClientSetCameraMode(NewCamMode);
		if( NewCamMode=='FirstPerson' && ViewTarget==Self && MyGFxHUD!=None )
			MyGFxHUD.SpectatorInfoWidget.SetSpectatedKFPRI(None); // Possibly went to first person, hide player info.
	}
}

// Feign death:
function EnterRagdollMode( bool bEnable )
{
	if( bEnable )
		GoToState('RagdollMove');
	else if( Pawn==None )
		GotoState('Dead');
	else if ( Pawn.PhysicsVolume.bWaterVolume )
		GotoState(Pawn.WaterMovementState);
	else GotoState(Pawn.LandMovementState);
}

// Optional dramatic end-game camera!
simulated function EndGameCamFocus( vector Pos )
{
	local vector CamPos;
	local rotator CamRot;

	GetPlayerViewPoint(CamPos,CamRot);
	bEndGameCamFocus = true;
	EndGameCamFocusPos[0] = Pos;
	EndGameCamFocusPos[1] = CamPos;
	EndGameCamRot = CamRot;
	EndGameCamTimer = WorldInfo.RealTimeSeconds;
	
	if( LocalPlayer(Player)==None )
		ClientFocusView(Pos);
	else if( KFPawn(ViewTarget)!=None )
		KFPawn(ViewTarget).SetMeshVisibility(true);
}
reliable client function ClientFocusView( vector Pos )
{
	if( WorldInfo.NetMode==NM_Client )
		EndGameCamFocus(Pos);
}
final function bool CalcEndGameCam()
{
	local float T,RT;
	local vector HL,HN;

	if( LastPlayerCalcView==WorldInfo.TimeSeconds )
		return true;

	T = WorldInfo.RealTimeSeconds-EndGameCamTimer;
	
	if( T>=20.f ) // Finished view.
	{
		bEndGameCamFocus = false;
		if( LocalPlayer(Player)!=None && KFPawn(ViewTarget)!=None )
			KFPawn(ViewTarget).SetMeshVisibility(!Global.UsingFirstPersonCamera());
		return false;
	}
	// Setup other cache params.
	LastPlayerCalcView	= WorldInfo.TimeSeconds;

	CalcViewLocation.Z = 1.f;
	RT = WorldInfo.RealTimeSeconds;
	if( T<4.f )
		RT += (4.f-T);
	CalcViewLocation.X = Sin(RT*0.08f);
	CalcViewLocation.Y = Cos(RT*0.08f);
	CalcViewLocation = EndGameCamFocusPos[0] + Normal(CalcViewLocation)*350.f;
	if( Trace(HL,HN,CalcViewLocation,EndGameCamFocusPos[0],false,vect(16,16,16))!=None )
		CalcViewLocation = HL;

	CalcViewRotation = rotator(EndGameCamFocusPos[0]-CalcViewLocation);

	if( T<4.f && LocalPlayer(Player)!=None ) // Zoom in to epic death.
	{
		T*=0.25;
		CalcViewLocation = CalcViewLocation*T + EndGameCamFocusPos[1]*(1.f-T);
		CalcViewRotation = RLerp(EndGameCamRot,CalcViewRotation,T,true);
	}
	return true;
}
simulated event GetPlayerViewPoint( out vector out_Location, out Rotator out_Rotation )
{
	if( bEndGameCamFocus && CalcEndGameCam() )
	{
		out_Location = CalcViewLocation;
		out_Rotation = CalcViewRotation;
		return;
	}
	Super.GetPlayerViewPoint(out_Location,out_Rotation);
}
exec function DebugRenderMode()
{
	if( WorldInfo.NetMode!=NM_Client )
	{
		bRenderModes = !bRenderModes;
		SaveConfig();
		ClientMessage(bRenderModes);
	}
}

// Stats traffic.
reliable server function ServerRequestStats( byte ListNum )
{
	if( ListNum<3 )
	{
		TransitListNum = ListNum;
		TransitIndex = 0;
		SetTimer(0.001,true,'SendNextList');
	}
}
function SendNextList()
{
	if( !OnClientGetStat(Self,TransitListNum,TransitIndex++) )
	{
		ClientGetStat(TransitListNum,true);
		ClearTimer('SendNextList');
	}
}
simulated reliable client function ClientGetStat( byte ListNum, bool bFinal, optional string N, optional UniqueNetId ID, optional int V )
{
	OnClientReceiveStat(ListNum,bFinal,N,ID,V);
}

Delegate OnClientReceiveStat( byte ListNum, bool bFinal, string N, UniqueNetId ID, int V );
Delegate bool OnClientGetStat( ExtPlayerController PC, byte ListNum, int StatIndex );

reliable server function ChangeSpectateMode( bool bSpectator )
{
	OnSpectateChange(Self,bSpectator);
}
simulated reliable client function ClientSpectateMode( bool bSpectator )
{
	UpdateURL("SpectatorOnly",(bSpectator ? "1" : "0"),false);
}
Delegate OnSpectateChange( ExtPlayerController PC, bool bSpectator );

state RagdollMove extends PlayerWalking
{
Ignores NotifyPhysicsVolumeChange,ServerCamera,ResetCameraMode;

	event BeginState(Name PreviousStateName)
	{
		FOVAngle = DesiredFOV;

		if( WorldInfo.NetMode!=NM_Client )
			SetCameraMode('ThirdPerson');
	}
	event EndState(Name NewState)
	{
		FOVAngle = DesiredFOV;

		if( Pawn!=none && NewState!='Dead' )
			Global.SetCameraMode('FirstPerson');
	}
	function PlayerMove( float DeltaTime )
	{
		local rotator			OldRotation;

		if( Pawn == None )
			GotoState('Dead');
		else
		{
			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );
			bDoubleJump = false;
			bPressedJump = false;

			if( Role < ROLE_Authority ) // then save this move and replicate it
				ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, OldRotation - Rotation);
			else ProcessMove(DeltaTime, vect(0,0,0), DCLICK_None, OldRotation - Rotation);
		}
	}
	simulated event GetPlayerViewPoint( out vector out_Location, out Rotator out_Rotation )
	{
		local Actor TheViewTarget;
		local vector HL,HN,EndOffset;

		if( bEndGameCamFocus && CalcEndGameCam() )
		{
			out_Location = CalcViewLocation;
			out_Rotation = CalcViewRotation;
			return;
		}
		if( Global.UsingFirstPersonCamera() )
			Global.GetPlayerViewPoint(out_Location,out_Rotation);
		else
		{
			out_Rotation = Rotation;
			TheViewTarget = GetViewTarget();
			if( TheViewTarget==None )
				TheViewTarget = Self;
			out_Location = TheViewTarget.Location;
			EndOffset = out_Location-vector(Rotation)*250.f;
			
			if( TheViewTarget.Trace(HL,HN,EndOffset,out_Location,false,vect(16,16,16))!=None )
				out_Location = HL;
			else out_Location = EndOffset;
		}
	}
}

state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

	function PlayerMove( float DeltaTime )
	{
		local vector			X,Y,Z, NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator			OldRotation;
		local bool				bSaveJump;

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{
			GetAxes(Pawn.Rotation,X,Y,Z);
			if( VSZombie(Pawn)!=None )
				VSZombie(Pawn).ModifyPlayerInput(Self,DeltaTime);

			// Update acceleration.
			NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
			NewAccel.Z	= 0;
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );
			bDoubleJump = false;

			if( bPressedJump && Pawn.CannotJumpNow() )
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			bPressedJump = bSaveJump;
		}
	}
}

state Dead
{
	event BeginState(Name PreviousStateName)
	{
		local KFPlayerInput KFPI;

		SetTimer( 5.f, false, nameof(StartSpectate) );
		if ( (Pawn != None) && (Pawn.Controller == self) )
			Pawn.Controller = None;
		Pawn = None;
		FOVAngle = DesiredFOV;
		Enemy = None;
		bPressedJump = false;
		FindGoodView();
		CleanOutSavedMoves();
		
		if( KFPawn(ViewTarget)!=none )
		{
			KFPawn(ViewTarget).SetMeshVisibility(true);
		}

        // Deactivate any post process effects when we die
		ResetGameplayPostProcessFX();

		if(CurrentPerk != none)
			CurrentPerk.PlayerDied();

		KFPI = KFPlayerInput(PlayerInput);
		if(KFPI != none)
			KFPI.HideVoiceComms();

		if( MyGFxManager != none )
			MyGFxManager.CloseMenus();

		if(MyGFxHUD != none )
			MyGFxHUD.ClearBuffIcons();
	}
	simulated event GetPlayerViewPoint( out vector out_Location, out Rotator out_Rotation )
	{
		local Actor TheViewTarget;
		local vector HL,HN,EndOffset;

		if( bEndGameCamFocus && CalcEndGameCam() )
		{
			out_Location = CalcViewLocation;
			out_Rotation = CalcViewRotation;
			return;
		}
		out_Rotation = Rotation;
		TheViewTarget = GetViewTarget();
		if( TheViewTarget==None )
			TheViewTarget = Self;
		out_Location = TheViewTarget.Location;
		EndOffset = out_Location-vector(Rotation)*400.f;
		
		if( TheViewTarget.Trace(HL,HN,EndOffset,out_Location,false,vect(16,16,16))!=None )
			out_Location = HL;
		else out_Location = EndOffset;
	}
}

defaultproperties
{
	InputClass=Class'ExtPlayerInput'
	PurchaseHelperClass=class'ExtAutoPurchaseHelper'
	bIgnoreEncroachers=true
	SpectatorCameraSpeed=900
	MidGameMenuClass=class'UI_MidGameMenu'
	PerkList.Empty()
	PerkList.Add((PerkClass=Class'ExtPerkManager'))
	
	NVG_DOF_FocalDistance=3800.0
	NVG_DOF_SharpRadius=2500.0
	NVG_DOF_FocalRadius=3500.0
	NVG_DOF_MaxNearBlurSize=0.25
}