// Server extension mutator, by Marco.
Class ServerExtMut extends KFMutator
	config(ServerExtMut);

// Webadmin
var array<FWebAdminConfigInfo> WebConfigs;

struct FInventory
{
	var class<Inventory> ItemClass;
	var int Values[4];
};
struct FSavedInvEntry
{
	var Controller OwnerPlayer;
	var byte Gren;
	var array<FInventory> Inv;
};
var array<FSavedInvEntry> PlayerInv;

var config array<string> PerkClasses,CustomChars,AdminCommands,CustomItems,BonusGameSongs,BonusGameFX;
var array< class<Ext_PerkBase> > LoadedPerks;
var array<FCustomCharEntry> CustomCharList;
var ExtPlayerStat ServerStatLoader;

var KFPawn LastHitZed;
var int LastHitHP;
var ExtPlayerController LastDamageDealer;
var vector LastDamagePosition;
var private const array<string> DevList;
var transient private array<UniqueNetId> DevNetID;
var ExtXMLOutput FileOutput;
var transient class<DamageType> LastKillDamageType;

var SoundCue BonusGameCue;
var Object BonusGameFXObj;

var array<FCustomTraderItem> CustomItemList;
var KFGFxObject_TraderItems CustomTrader;

const SettingsTagVer=12;
var KFGameReplicationInfo KF;
var config int SettingsInit;
var config int ForcedMaxPlayers,PlayerRespawnTime,LargeMonsterHP,StatAutoSaveWaves,MinUnloadPerkLevel,PostGameRespawnCost,MaxTopPlayers;
var config float UnloadPerkExpCost;
var globalconfig string ServerMOTD,StatFileDir;
var array<Controller> PendingSpawners;
var int LastWaveNum,NumWaveSwitches;
var ExtSpawnPointHelper SpawnPointer;
var bool bRespawnCheck,bSpecialSpawn,bGameHasEnded,bIsPostGame;
var config bool bKillMessages,bDamageMessages,bEnableMapVote,bNoAdminCommands,bNoWebAdmin,bNoBoomstickJumping,bDumpXMLStats,bRagdollFromFall,bRagdollFromMomentum,bRagdollFromBackhit,bAddCountryTags;

function PostBeginPlay()
{
	local xVotingHandler MV;
	local int i,j;
	local class<Ext_PerkBase> PK;
	local UniqueNetId Id;
	local KFCharacterInfo_Human CH;
	local ObjectReferencer OR;
	local Object O;
	local string S;
	local FCustomTraderItem CI;
	local bool bLock;

	Super.PostBeginPlay();
	if( WorldInfo.Game.BaseMutator==None )
		WorldInfo.Game.BaseMutator = Self;
	else WorldInfo.Game.BaseMutator.AddMutator(Self);
	
	if( bDeleteMe ) // This was a duplicate instance of the mutator.
		return;

	SpawnPointer = class'ExtSpawnPointHelper'.Static.FindHelper(WorldInfo); // Start init world pathlist.
	
	//OnlineSubsystemSteamworks(class'GameEngine'.Static.GetOnlineSubsystem()).Int64ToUniqueNetId("",Id);
	//`Log("TEST"@class'OnlineSubsystem'.Static.UniqueNetIdToString(Id));

	DevNetID.Length = DevList.Length;
	for( i=0; i<DevList.Length; ++i )
	{
		class'OnlineSubsystem'.Static.StringToUniqueNetId(DevList[i],Id);
		DevNetID[i] = Id;
	}
	ServerStatLoader = new (None) class'ExtPlayerStat';
	WorldInfo.Game.HUDType = class'KFExtendedHUD';
	WorldInfo.Game.PlayerControllerClass = class'ExtPlayerController';
	WorldInfo.Game.PlayerReplicationInfoClass = class'ExtPlayerReplicationInfo';
	WorldInfo.Game.DefaultPawnClass = class'ExtHumanPawn';
	KFGameInfo(WorldInfo.Game).CustomizationPawnClass = class'ExtPawn_Customization';
	KFGameInfo(WorldInfo.Game).KFGFxManagerClass = class'ExtMoviePlayer_Manager';

	if( ServerMOTD=="" )
		ServerMOTD = "Message of the Day";
	if( StatFileDir=="" )
	{
		StatFileDir = "../../KFGame/Script/%s.usa";
		Default.StatFileDir = "../../KFGame/Script/%s.usa";
	}
	if( SettingsInit!=SettingsTagVer )
	{
		if( SettingsInit==0 )
			ForcedMaxPlayers = 6;
		if( SettingsInit<2 )
		{
			bKillMessages = true;
			bDamageMessages = true;
			LargeMonsterHP = 800;
		}
		if( SettingsInit<3 )
			bEnableMapVote = true;
		if( SettingsInit<5 )
		{
			StatAutoSaveWaves = 1;
			PerkClasses.Length = 10;
			PerkClasses[0] = PathName(class'Ext_PerkBerserker');
			PerkClasses[1] = PathName(class'Ext_PerkCommando');
			PerkClasses[2] = PathName(class'Ext_PerkFieldMedic');
			PerkClasses[3] = PathName(class'Ext_PerkSupport');
			PerkClasses[4] = PathName(class'Ext_PerkDemolition');
			PerkClasses[5] = PathName(class'Ext_PerkFirebug');
			PerkClasses[6] = PathName(class'Ext_PerkGunslinger');
			PerkClasses[7] = PathName(class'Ext_PerkSharpshooter');
			PerkClasses[8] = PathName(class'Ext_PerkSWAT');
			PerkClasses[9] = PathName(class'Ext_PerkSurvivalist');
		}
		else if( SettingsInit<11 )
		{
			PerkClasses.AddItem(PathName(class'Ext_PerkSharpshooter'));
			PerkClasses.AddItem(PathName(class'Ext_PerkSWAT'));
			PerkClasses.AddItem(PathName(class'Ext_PerkSurvivalist'));
		}
		else if( SettingsInit==11 )
			PerkClasses.AddItem(PathName(class'Ext_PerkSurvivalist'));
		if( SettingsInit<6 )
		{
			MinUnloadPerkLevel = 25;
			UnloadPerkExpCost = 0.1;
		}
		if( SettingsInit<8 )
		{
			AdminCommands.Length = 2;
			AdminCommands[0] = "Kick:Kick Player";
			AdminCommands[1] = "KickBan:Kick-Ban Player";
		}
		if( SettingsInit<9 )
			MaxTopPlayers = 50;
		SettingsInit = SettingsTagVer;
		SaveConfig();
	}
	for( i=0; i<PerkClasses.Length; ++i )
	{
		PK = class<Ext_PerkBase>(DynamicLoadObject(PerkClasses[i],class'Class'));
		if( PK!=None )
		{
			LoadedPerks.AddItem(PK);
			PK.Static.CheckConfig();
		}
	}
	j = 0;
	for( i=0; i<CustomChars.Length; ++i )
	{
		bLock = Left(CustomChars[i],1)=="*";
		S = (bLock ? Mid(CustomChars[i],1) : CustomChars[i]);
		CH = KFCharacterInfo_Human(DynamicLoadObject(S,class'KFCharacterInfo_Human',true));
		if( CH!=None )
		{
			CustomCharList.Length = j+1;
			CustomCharList[j].bLock = bLock;
			CustomCharList[j].Char = CH;
			++j;
			continue;
		}

		OR = ObjectReferencer(DynamicLoadObject(S,class'ObjectReferencer'));
		if( OR!=None )
		{
			foreach OR.ReferencedObjects(O)
			{
				if( KFCharacterInfo_Human(O)!=None )
				{
					CustomCharList.Length = j+1;
					CustomCharList[j].bLock = bLock;
					CustomCharList[j].Char = KFCharacterInfo_Human(O);
					CustomCharList[j].Ref = OR;
					++j;
				}
			}
		}
	}
	
	// Bonus (pong) game contents.
	if( BonusGameSongs.Length>0 )
	{
		BonusGameCue = SoundCue(DynamicLoadObject(BonusGameSongs[Rand(BonusGameSongs.Length)],class'SoundCue'));
	}
	if( BonusGameFX.Length>0 )
	{
		BonusGameFXObj = DynamicLoadObject(BonusGameFX[Rand(BonusGameFX.Length)],class'Object');
		if( SoundCue(BonusGameFXObj)==None && ObjectReferencer(BonusGameFXObj)==None ) // Check valid type.
			BonusGameFXObj = None;
	}

	for( i=0; i<CustomItems.Length; ++i )
	{
		CI.WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(CustomItems[i],class'Class'));
		if( CI.WeaponDef==None )
			continue;
		CI.WeaponClass = class<KFWeapon>(DynamicLoadObject(CI.WeaponDef.Default.WeaponClassPath,class'Class'));
		if( CI.WeaponClass==None )
			continue;
		
		CustomItemList.AddItem(CI);

		if( CustomTrader==None )
		{
			CustomTrader = class'ExtPlayerReplicationInfo'.Static.CreateNewList();
			SetTimer(0.1,false,'InitGRIList');
		}
		class'ExtPlayerReplicationInfo'.Static.SetWeaponInfo(WorldInfo.NetMode==NM_DedicatedServer,CustomTrader.SaleItems.Length,CI,CustomTrader);
	}
	if( ForcedMaxPlayers>0 )
	{
		SetMaxPlayers();
		SetTimer(0.001,false,'SetMaxPlayers');
	}
	bRespawnCheck = (PlayerRespawnTime>0);
	if( bRespawnCheck )
		SetTimer(1,true);
	if( bEnableMapVote )
	{
		foreach DynamicActors(class'xVotingHandler',MV)
			break;
		if( MV==None )
			MV = Spawn(class'xVotingHandler');
		MV.BaseMutator = Class;
	}
	SetTimer(1,true,'CheckWave');
	if( !bNoWebAdmin && WorldInfo.NetMode!=NM_StandAlone )
		SetTimer(0.1,false,'SetupWebAdmin');

	if( bDumpXMLStats )
		FileOutput = Spawn(class'ExtXMLOutput');
}
static final function string GetStatFile( const out UniqueNetId UID )
{
	return Repl(Default.StatFileDir,"%s","U_"$class'OnlineSubsystem'.Static.UniqueNetIdToString(UID));
}
final function bool IsDev( const out UniqueNetId UID )
{
	local int i;
	
	for( i=(DevNetID.Length-1); i>=0; --i )
		if( DevNetID[i]==UID )
			return true;
	return false;
}
function InitGRIList()
{
	local ExtPlayerController PC;

	KFGameReplicationInfo(WorldInfo.GRI).TraderItems = CustomTrader;

	// Must sync up local client.
	if( WorldInfo.NetMode==NM_StandAlone )
	{
		foreach LocalPlayerControllers(class'ExtPlayerController',PC)
			if( PC.PurchaseHelper!=None )
				PC.PurchaseHelper.TraderItems = CustomTrader;
	}
}
function CheckWave()
{
	if( KF==None )
	{
		KF = KFGameReplicationInfo(WorldInfo.GRI);
		if( KF==None )
			return;
	}
	if( LastWaveNum!=KF.WaveNum )
	{
		LastWaveNum = KF.WaveNum;
		NotifyWaveChange();
	}
	if( !bGameHasEnded && KF.bMatchIsOver ) // HACK, since KFGameInfo_Survival doesn't properly notify mutators of this!
	{
		SaveAllPerks(true);
		bGameHasEnded = true;
	}
}
function NotifyWaveChange()
{
	local ExtPlayerController ExtPC;
	
	if( bRespawnCheck )
	{
		bIsPostGame = (KF.WaveMax<KF.WaveNum);
		bRespawnCheck = (!bIsPostGame || PostGameRespawnCost>=0);
		if( bRespawnCheck )
			SavePlayerInventory();
	}
	if( StatAutoSaveWaves>0 && ++NumWaveSwitches>=StatAutoSaveWaves )
	{
		NumWaveSwitches = 0;
		SaveAllPerks();
	}
	
	if( !KF.bTraderIsOpen )
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',ExtPC)
			ExtPC.bSetPerk = false;
	}
}
function SetupWebAdmin()
{
	local WebServer W;
	local WebAdmin A;
	local ExtWebApp xW;
	local byte i;

	foreach AllActors(class'WebServer',W)
		break;
	if( W!=None )
	{
		for( i=0; (i<10 && A==None); ++i )
			A = WebAdmin(W.ApplicationObjects[i]);
		if( A!=None )
		{
			xW = new (None) class'ExtWebApp';
			xW.MyMutator = Self;
			A.addQueryHandler(xW);
		}
		else `Log("ExtWebAdmin ERROR: No valid WebAdmin application found!");
	}
	else `Log("ExtWebAdmin ERROR: No WebServer object found!");
}
function SetMaxPlayers()
{
	local OnlineGameSettings GameSettings;

	WorldInfo.Game.MaxPlayers = ForcedMaxPlayers;
	WorldInfo.Game.MaxPlayersAllowed = ForcedMaxPlayers;
	if( WorldInfo.Game.GameInterface!=None )
	{
		GameSettings = WorldInfo.Game.GameInterface.GetGameSettings(WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
		if( GameSettings!=None )
			GameSettings.NumPublicConnections = ForcedMaxPlayers;
	}
}
function AddMutator(Mutator M)
{
	if( M!=Self ) // Make sure we don't get added twice.
	{
		if( M.Class==Class )
			M.Destroy();
		else Super.AddMutator(M);
	}
}
function ScoreKill(Controller Killer, Controller Killed)
{
	local KFPlayerController KFPC;
	local ExtPerkManager KillersPerk;
	
	if( bRespawnCheck && Killed.bIsPlayer )
		CheckRespawn(Killed);
	if( KFPawn_Monster(Killed.Pawn)!=None && Killed.GetTeamNum()!=0 && Killer.bIsPlayer && Killer.GetTeamNum()==0 )
	{
		if( ExtPlayerController(Killer)!=None && ExtPlayerController(Killer).ActivePerkManager!=None )
			ExtPlayerController(Killer).ActivePerkManager.PlayerKilled(KFPawn_Monster(Killed.Pawn),LastKillDamageType);
		if( bKillMessages && Killer.PlayerReplicationInfo!=None )
			BroadcastKillMessage(Killed.Pawn,Killer);
		//else if( Killer!=None && Killer!=Killed && Killer.GetTeamNum()==0 && Ext_T_MonsterPRI(Killer.PlayerReplicationInfo)!=None )
		//	BroadcastKillMessage(Killed.Pawn,Ext_T_MonsterPRI(Killer.PlayerReplicationInfo).OwnerController);
	}
	if ( MyKFGI != None && MyKFGI.IsZedTimeActive() && KFPawn_Monster(Killed.Pawn) != None )
	{
		KFPC = KFPlayerController(Killer);
		if ( KFPC != none )
		{
			KillersPerk = ExtPerkManager(KFPC.GetPerk());
			if ( MyKFGI.ZedTimeRemaining > 0.f && KillersPerk != none && KillersPerk.GetZedTimeExtensions( KFPC.GetLevel() ) > MyKFGI.ZedTimeExtensionsUsed )
			{
				MyKFGI.DramaticEvent(1.0);
				MyKFGI.ZedTimeExtensionsUsed++;
			}
		}
	}
	if( ExtPlayerController(Killed)!=None )
		CheckPerkChange(ExtPlayerController(Killed));
	if (NextMutator != None)
		NextMutator.ScoreKill(Killer, Killed);
}
function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	if( (KFPawn_Human(Killed)!=None && CheckPreventDeath(KFPawn_Human(Killed),Killer,damageType)) || Super.PreventDeath(Killed,Killer,damageType,HitLocation) )
		return true;
	
	LastKillDamageType = damageType;
	if( Killed.Controller!=None && KFPawn_Monster(Killed)!=None )
	{
		// Hack for when pet kills a zed.
		if( Killed.GetTeamNum()!=0 )
		{
			if( Killer!=None && Killer!=Killed.Controller && Killer.GetTeamNum()==0 && Ext_T_MonsterPRI(Killer.PlayerReplicationInfo)!=None )
				GT_PlayerKilled(Ext_T_MonsterPRI(Killer.PlayerReplicationInfo).OwnerController,Killed.Controller,damageType);
		}
		// Broadcast pet's deathmessage.
		else if( Killed.PlayerReplicationInfo!=None && PlayerController(Killed.Controller)==None && damageType!=class'KFDT_Healing' )
			BroadcastFFDeath(Killer,Killed,damageType);
	}
	return false;
}

// Replica of KFGameInfo.Killed base.
final function GT_PlayerKilled( Controller Killer, Controller Killed, class<DamageType> damageType )
{
	local ExtPlayerController KFPC;
	local KFPawn_Monster MonsterPawn;
	local KFGameInfo KFG;

	KFG = KFGameInfo(WorldInfo.Game);
	ScoreKill(Killer,Killed); // Broadcast kill message.
	
	KFPC = ExtPlayerController(Killer);
	MonsterPawn = KFPawn_Monster(Killed.Pawn);
	if( KFG!=None && KFPC != none && MonsterPawn!=none )
	{
		//Chris: We have to do it earlier here because we need a damage type
		KFPC.AddZedKill( MonsterPawn.class, KFG.GameDifficulty, damageType );

		if( KFPC.ActivePerkManager!=none && KFPC.ActivePerkManager.CanEarnSmallRadiusKillXP(damageType) )
			KFG.CheckForBerserkerSmallRadiusKill( MonsterPawn, KFPC );
	}
}
final function bool CheckPreventDeath( KFPawn_Human Victim, Controller Killer, class<DamageType> damageType )
{
	local ExtPlayerController E;
	
	if( Victim.IsA('KFPawn_Customization') )
		return false;
	E = ExtPlayerController(Victim.Controller);
	return (E!=None && E.ActivePerkManager!=None && E.ActivePerkManager.CurrentPerk!=None && E.ActivePerkManager.CurrentPerk.PreventDeath(Victim,Killer,damageType));
}
final function BroadcastKillMessage( Pawn Killed, Controller Killer )
{
	local ExtPlayerController E;

	if( Killer==None || Killer.PlayerReplicationInfo==None )
		return;

	if( Killed.Default.Health>=LargeMonsterHP )
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			if( !E.bClientHideKillMsg )
				E.ReceiveKillMessage(Killed.Class,true,Killer.PlayerReplicationInfo);
	}
	else if( ExtPlayerController(Killer)!=None && !ExtPlayerController(Killer).bClientHideKillMsg )
		ExtPlayerController(Killer).ReceiveKillMessage(Killed.Class);
}
final function BroadcastFFDeath( Controller Killer, Pawn Killed, class<DamageType> damageType )
{
	local ExtPlayerController E;
	local PlayerReplicationInfo KillerPRI;
	local string P;
	local bool bFF;
	
	P = Killed.PlayerReplicationInfo.PlayerName;
	if( Killer==None || Killer==Killed.Controller )
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			E.ClientZedKillMessage(damageType,P);
		return;
	}
	bFF = (Killer.GetTeamNum()==0);
	KillerPRI = Killer.PlayerReplicationInfo;
	if( PlayerController(Killer)==None )
		KillerPRI = None;

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		E.ClientZedKillMessage(damageType,P,KillerPRI,Killer.Pawn.Class,bFF);
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	if (NextMutator != None)
		NextMutator.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	if( LastDamageDealer!=None ) // Make sure no other damagers interfear with the old thing going on.
	{
		ClearTimer('CheckDamageDone');
		CheckDamageDone();
	}
	if ( KFPawn_Monster(Injured) != None && InstigatedBy != none && InstigatedBy.GetTeamNum() == Injured.GetTeamNum() )
	{
		Momentum = vect(0,0,0);
		Damage = 0;
		return;
	}
	if( Damage>0 && InstigatedBy!=None )
	{
		if( KFPawn_Monster(Injured)!=None )
		{
			if( Injured.GetTeamNum()!=0 )
			{
				LastDamageDealer = ExtPlayerController(InstigatedBy);
				if( bDamageMessages && LastDamageDealer!=None && !LastDamageDealer.bNoDamageTracking )
				{
					// Must delay this until next to get accurate damage dealt result.
					LastHitZed = KFPawn(Injured);
					LastHitHP = LastHitZed.Health;
					LastDamagePosition = HitLocation;
					SetTimer(0.001,false,'CheckDamageDone');
				}
				else
				{
					LastDamageDealer = None;
					// Give credits to pet's owner.
					if( Ext_T_MonsterPRI(InstigatedBy.PlayerReplicationInfo)!=None )
						HackSetHistory(KFPawn(Injured),Injured,Ext_T_MonsterPRI(InstigatedBy.PlayerReplicationInfo).OwnerController,Damage,HitLocation);
				}
			}
			else if( KFPawn(InstigatedBy.Pawn).GetTeamNum() != KFPawn(Injured).GetTeamNum() )
			{
				Momentum = vect(0,0,0);
				Damage = 0;
			}
		}
		else if( bDamageMessages && KFPawn_Human(Injured)!=None && Injured.GetTeamNum()==0 && InstigatedBy.GetTeamNum()!=0 && ExtPlayerController(InstigatedBy)!=None )
		{
			LastDamageDealer = ExtPlayerController(InstigatedBy);
			if( bDamageMessages && !LastDamageDealer.bClientHideNumbers )
			{
				// Must delay this until next to get accurate damage dealt result.
				LastHitZed = KFPawn(Injured);
				LastHitHP = LastHitZed.Health;
				LastDamagePosition = HitLocation;
				SetTimer(0.001,false,'CheckDamageDone');
			}
		}
	}
}
final function CheckDamageDone()
{
	local int Damage;

	if( LastDamageDealer!=None && LastHitZed!=None && LastHitHP!=LastHitZed.Health )
	{
		Damage = LastHitHP-Max(LastHitZed.Health,0);
		if( Damage>0 )
		{
			if( !LastDamageDealer.bClientHideDamageMsg && KFPawn_Monster(LastHitZed)!=None )
				LastDamageDealer.ReceiveDamageMessage(LastHitZed.Class,Damage);
			if( !LastDamageDealer.bClientHideNumbers )
				LastDamageDealer.ClientNumberMsg(Damage,LastDamagePosition,DMG_PawnDamage);
		}
	}
	LastDamageDealer = None;
}
final function HackSetHistory( KFPawn C, Pawn Injured, Controller Player, int Damage, vector HitLocation )
{
	local int i;
	local ExtPlayerController PC;

	if( Player==None )
		return;
	PC = ExtPlayerController(Player);
	if( bDamageMessages && PC!=None )
	{
		if( !PC.bClientHideDamageMsg )
			PC.ReceiveDamageMessage(Injured.Class,Damage);
		if( !PC.bClientHideNumbers )
			PC.ClientNumberMsg(Damage,HitLocation,DMG_PawnDamage);
	}
	i = C.DamageHistory.Find('DamagerController',Player);
	if( i==-1 )
	{
		i = C.DamageHistory.Length;
		C.DamageHistory.Length = i+1;
		C.DamageHistory[i].DamagerController = Player;
		C.DamageHistory[i].DamagerPRI = Player.PlayerReplicationInfo;
		C.DamageHistory[i].DamagePerks.AddItem(class'ExtPerkManager');
		C.DamageHistory[i].Damage = Damage;
	}
	else if( (WorldInfo.TimeSeconds-C.DamageHistory[i].LastTimeDamaged)<10 )
		C.DamageHistory[i].Damage += Damage;
	else C.DamageHistory[i].Damage = Damage;

	C.DamageHistory[i].LastTimeDamaged = WorldInfo.TimeSeconds;
	C.DamageHistory[i].TotalDamage += Damage;
}

function bool HandleRestartGame()
{
	if( !bGameHasEnded )
	{
		SaveAllPerks(true);
		bGameHasEnded = true;
	}
	return Super.HandleRestartGame();
}

function NotifyLogout(Controller Exiting)
{
	if( KFPlayerController(Exiting)!=None )
		RemoveRespawn(Exiting);
	if( !bGameHasEnded && ExtPlayerController(Exiting)!=None )
	{
		CheckPerkChange(ExtPlayerController(Exiting));
		SavePlayerPerk(ExtPlayerController(Exiting));
	}
	if ( NextMutator != None )
		NextMutator.NotifyLogout(Exiting);
}
function NotifyLogin(Controller NewPlayer)
{
	if( ExtPlayerController(NewPlayer)!=None )
	{
		if( ExtPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo)!=None )
			InitCustomChars(ExtPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo));
		if( bAddCountryTags && NetConnection(PlayerController(NewPlayer).Player)!=None )
			ExtPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).SetPlayerNameTag(class'CtryDatabase'.Static.GetClientCountryStr(PlayerController(NewPlayer).GetPlayerNetworkAddress()));
		ExtPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).bIsDev = IsDev(NewPlayer.PlayerReplicationInfo.UniqueId);
		if( WorldInfo.NetMode!=NM_StandAlone )
			ExtPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).OnRepNextItem = GetNextItem;
		if( BonusGameCue!=None || BonusGameFXObj!=None )
			ExtPlayerController(NewPlayer).ClientSetBonus(BonusGameCue,BonusGameFXObj);
		if( bRespawnCheck )
			CheckRespawn(NewPlayer);
		if( !bGameHasEnded )
			InitializePerks(ExtPlayerController(NewPlayer));
		SendMOTD(ExtPlayerController(NewPlayer));
	}
	if ( NextMutator != None )
		NextMutator.NotifyLogin(NewPlayer);
}
final function InitializePerks( ExtPlayerController Other )
{
	local ExtPerkManager PM;
	local Ext_PerkBase P;
	local int i;
	
	Other.OnChangePerk = PlayerChangePerk;
	Other.OnBoughtStats = PlayerBuyStats;
	Other.OnBoughtTrait = PlayerBoughtTrait;
	Other.OnPerkReset = ResetPlayerPerk;
	Other.OnAdminHandle = AdminCommand;
	Other.OnSetMOTD = AdminSetMOTD;
	Other.OnRequestUnload = PlayerUnloadInfo;
	Other.OnSpectateChange = PlayerChangeSpec;
	Other.OnClientGetStat = class'ExtStatList'.Static.GetStat;
	PM = Other.ActivePerkManager;
	PM.InitPerks();
	for( i=0; i<LoadedPerks.Length; ++i )
	{
		P = Spawn(LoadedPerks[i],Other);
		PM.RegisterPerk(P);
	}
	ServerStatLoader.FlushData();
	if( ServerStatLoader.LoadStatFile(Other) )
	{
		ServerStatLoader.ToStart();
		PM.LoadData(ServerStatLoader);
		if( Default.MaxTopPlayers>0 )
			class'ExtStatList'.Static.SetTopPlayers(Other);
	}
	PM.ServerInitPerks();
	PM.InitiateClientRep();
}
final function SendMOTD( ExtPlayerController PC )
{
	local string S;
	local int i;
	
	S = ServerMOTD;
	while( Len(S)>510 )
	{
		PC.ReceiveServerMOTD(Left(S,500),false);
		S = Mid(S,500);
	}
	PC.ReceiveServerMOTD(S,true);
	
	for( i=0; i<AdminCommands.Length; ++i )
		PC.AddAdminCmd(AdminCommands[i]);
}
final function SavePlayerPerk( ExtPlayerController PC )
{
	if( PC.ActivePerkManager!=None && PC.ActivePerkManager.bStatsDirty )
	{
		// Verify broken stats.
		if( PC.ActivePerkManager.bUserStatsBroken )
		{
			PC.ClientMessage("Warning: Your stats are broken, not saving.",'Priority');
			return;
		}
		ServerStatLoader.FlushData();
		if( ServerStatLoader.LoadStatFile(PC) && ServerStatLoader.GetSaveVersion()!=PC.ActivePerkManager.UserDataVersion )
		{
			PC.ActivePerkManager.bUserStatsBroken = true;
			PC.ClientMessage("Warning: Your stats save data version differs from what is loaded, stat saving disabled to prevent stats loss.",'Priority');
			return;
		}
		
		// Actually save.
		ServerStatLoader.FlushData();
		PC.ActivePerkManager.SaveData(ServerStatLoader);
		ServerStatLoader.SaveStatFile(PC);
		PC.ActivePerkManager.bStatsDirty = false;
		
		// Write XML output.
		if( FileOutput!=None )
			FileOutput.DumpXML(PC.ActivePerkManager);
	}
}
function SaveAllPerks( optional bool bOnEndGame )
{
	local ExtPlayerController PC;
	
	if( bGameHasEnded )
		return;
	foreach WorldInfo.AllControllers(class'ExtPlayerController',PC)
		if( PC.ActivePerkManager!=None && PC.ActivePerkManager.bStatsDirty )
		{
			if( bOnEndGame )
				CheckPerkChange(PC);
			SavePlayerPerk(PC);
		}
}

function CheckRespawn( Controller PC )
{
	if( !PC.bIsPlayer || ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)==None || PC.PlayerReplicationInfo.bOnlySpectator || WorldInfo.Game.bWaitingToStartMatch || WorldInfo.Game.bGameEnded )
		return;

	// VS redead.
	if( ExtHumanPawn(PC.Pawn)!=None && ExtHumanPawn(PC.Pawn).bPendingRedead )
		return;

	if( bIsPostGame && PC.PlayerReplicationInfo.Score<PostGameRespawnCost )
	{
		if( PlayerController(PC)!=None )
			PlayerController(PC).ClientMessage("You can't afford to respawn anymore (need "$PostGameRespawnCost@Chr(163)$")!",'LowCriticalEvent');
		return;
	}
	ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = PlayerRespawnTime;
	PC.PlayerReplicationInfo.bForceNetUpdate = true;
	if( PendingSpawners.Find(PC)<0 )
		PendingSpawners.AddItem(PC);
}
function RemoveRespawn( Controller PC )
{
	ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
	PendingSpawners.RemoveItem(PC);
}

final function InitPlayer( ExtHumanPawn Other )
{
	local ExtPlayerReplicationInfo PRI;
	
	PRI = ExtPlayerReplicationInfo(Other.PlayerReplicationInfo);
	if( PRI!=None && PRI.PerkManager!=None && PRI.PerkManager.CurrentPerk!=None )
		PRI.PerkManager.CurrentPerk.ApplyEffectsTo(Other);
	Other.bRagdollFromFalling = bRagdollFromFall;
	Other.bRagdollFromMomentum = bRagdollFromMomentum;
	Other.bRagdollFromBackhit = bRagdollFromBackhit;
}
function ModifyPlayer(Pawn Other)
{
	if( ExtHumanPawn(Other)!=None )
		InitPlayer(ExtHumanPawn(Other));
	if ( NextMutator != None )
		NextMutator.ModifyPlayer(Other);
}

function Timer()
{
	local int i;
	local Controller PC;
	local bool bSpawned,bAllDead;

	bAllDead = (KFGameInfo(WorldInfo.Game).GetLivingPlayerCount()<=0 || WorldInfo.Game.bGameEnded || !bRespawnCheck);
	for( i=0; i<PendingSpawners.Length; ++i )
	{
		PC = PendingSpawners[i];
		if( bAllDead || PC==None || PC.PlayerReplicationInfo.bOnlySpectator || (PC.Pawn!=None && PC.Pawn.IsAliveAndWell()) )
		{
			if( PC!=None )
			{
				ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
				PC.PlayerReplicationInfo.bForceNetUpdate = true;
			}
			PendingSpawners.Remove(i--,1);
		}
		else if( bIsPostGame && PC.PlayerReplicationInfo.Score<PostGameRespawnCost )
		{
			ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
			PC.PlayerReplicationInfo.bForceNetUpdate = true;

			if( PlayerController(PC)!=None )
				PlayerController(PC).ClientMessage("You can't afford to respawn anymore (need "$PostGameRespawnCost@Chr(163)$")!",'LowCriticalEvent');
			PendingSpawners.Remove(i--,1);
		}
		else if( --ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter<=0 )
		{
			PC.PlayerReplicationInfo.bForceNetUpdate = true;
			ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = 0;
			if( !bSpawned ) // Spawn only one player at time (so game doesn't crash if many players spawn in same time).
			{
				bSpawned = true;
				if( RespawnPlayer(PC) )
				{
					if( bIsPostGame )
					{
						if( PlayerController(PC)!=None )
							PlayerController(PC).ClientMessage("This respawn cost you "$PostGameRespawnCost@Chr(163)$"!",'LowCriticalEvent');
						PC.PlayerReplicationInfo.Score-=PostGameRespawnCost;
					}
					ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
					PC.PlayerReplicationInfo.bForceNetUpdate = true;
				}
			}
		}
		else PC.PlayerReplicationInfo.bForceNetUpdate = true;
	}
}
final function SavePlayerInventory()
{
	local KFPawn_Human P;
	local int i,j;
	local Inventory Inv;
	local KFWeapon K;
	
	PlayerInv.Length = 0;
	i = 0;
	foreach WorldInfo.AllPawns(class'KFPawn_Human',P)
		if( P.IsAliveAndWell() && P.InvManager!=None && P.Controller!=None && P.Controller.PlayerReplicationInfo!=None )
		{
			PlayerInv.Length = i+1;
			PlayerInv[i].OwnerPlayer = P.Controller;
			PlayerInv[i].Gren = KFInventoryManager(P.InvManager).GrenadeCount;
			j = 0;
			
			foreach P.InvManager.InventoryActors(class'Inventory',Inv)
			{
				if( KFInventory_Money(Inv)!=None )
					continue;
				K = KFWeapon(Inv);
				if( K!=None && !K.bCanThrow ) // Skip non-throwable items.
					continue;
				PlayerInv[i].Inv.Length = j+1;
				PlayerInv[i].Inv[j].ItemClass = Inv.Class;
				if( K!=None )
				{
					PlayerInv[i].Inv[j].Values[0] = K.SpareAmmoCount[0];
					PlayerInv[i].Inv[j].Values[1] = K.SpareAmmoCount[1];
					PlayerInv[i].Inv[j].Values[2] = K.AmmoCount[0];
					PlayerInv[i].Inv[j].Values[3] = K.AmmoCount[1];
				}
				++j;
			}
			++i;
		}
}
final function bool AddPlayerSpecificInv( Pawn Other )
{
	local int i,j;
	local Inventory Inv;
	local KFWeapon K;

	for( i=(PlayerInv.Length-1); i>=0; --i )
		if( PlayerInv[i].OwnerPlayer==Other.Controller )
		{
			KFInventoryManager(Other.InvManager).bInfiniteWeight = true;
			KFInventoryManager(Other.InvManager).GrenadeCount = PlayerInv[i].Gren;
			for( j=(PlayerInv[i].Inv.Length-1); j>=0; --j )
			{
				Inv = Other.InvManager.FindInventoryType(PlayerInv[i].Inv[j].ItemClass,false);
				if( Inv==None )
				{
					Inv = Other.InvManager.CreateInventory(PlayerInv[i].Inv[j].ItemClass);
				}
				K = KFWeapon(Inv);
				if( K!=None )
				{
					K.SpareAmmoCount[0] = PlayerInv[i].Inv[j].Values[0];
					K.SpareAmmoCount[1] = PlayerInv[i].Inv[j].Values[1];
					K.AmmoCount[0] = PlayerInv[i].Inv[j].Values[2];
					K.AmmoCount[1] = PlayerInv[i].Inv[j].Values[3];
					K.ClientForceAmmoUpdate(K.AmmoCount[0],K.SpareAmmoCount[0]);
					K.ClientForceSecondaryAmmoUpdate(K.AmmoCount[1]);
				}
			}
			if( Other.InvManager.FindInventoryType(class'KFInventory_Money',true)==None )
				Other.InvManager.CreateInventory(class'KFInventory_Money');
			KFInventoryManager(Other.InvManager).bInfiniteWeight = false;
			return true;
		}
	return false;
}
final function Pawn SpawnDefaultPawnFor(Controller NewPlayer, Actor StartSpot) // Clone of GameInfo one, but with Actor StartSpot.
{
	local class<Pawn> PlayerClass;
	local Rotator R;
	local Pawn ResultPawn;

	PlayerClass = WorldInfo.Game.GetDefaultPlayerClass(NewPlayer);
	R.Yaw = StartSpot.Rotation.Yaw;
	ResultPawn = Spawn(PlayerClass,,,StartSpot.Location,R,,true);
	return ResultPawn;
}
final function bool RespawnPlayer( Controller NewPlayer )
{
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local Actor startSpot;
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local LocalPlayer LP; 

	if( NewPlayer.Pawn!=None )
		NewPlayer.Pawn.Destroy();

	// figure out the team number and find the start spot
	StartSpot = SpawnPointer.PickBestSpawn();

	// if a start spot wasn't found,
	if (startSpot == None)
	{
		// check for a previously assigned spot
		if (NewPlayer.StartSpot != None)
		{
			StartSpot = NewPlayer.StartSpot;
			`warn("Player start not found, using last start spot");
		}
		else
		{
			// otherwise abort
			`warn("Player start not found, failed to restart player");
			return false;
		}
	}

	// try to create a pawn to use of the default class for this player
	NewPlayer.Pawn = SpawnDefaultPawnFor(NewPlayer, StartSpot);

	if (NewPlayer.Pawn == None)
	{
		NewPlayer.GotoState('Dead');
		if ( PlayerController(NewPlayer) != None )
			PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
		return false;
	}
	else
	{
		// initialize and start it up
		if( NavigationPoint(startSpot)!=None )
			NewPlayer.Pawn.SetAnchor(NavigationPoint(startSpot));
		if ( PlayerController(NewPlayer) != None )
		{
			PlayerController(NewPlayer).TimeMargin = -0.1;
			if( NavigationPoint(startSpot)!=None )
				NavigationPoint(startSpot).AnchoredPawn = None; // SetAnchor() will set this since IsHumanControlled() won't return true for the Pawn yet
		}
		NewPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
		NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
		NewPlayer.Possess(NewPlayer.Pawn, false);
		NewPlayer.Pawn.PlayTeleportEffect(true, true);
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);

		if ( !WorldInfo.bNoDefaultInventoryForPlayer )
		{
			AddPlayerSpecificInv(NewPlayer.Pawn);
			WorldInfo.Game.AddDefaultInventory(NewPlayer.Pawn);
		}
		WorldInfo.Game.SetPlayerDefaults(NewPlayer.Pawn);

		// activate spawned events
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned',TRUE,Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None &&
					SpawnedEvent.CheckActivate(NewPlayer,NewPlayer))
				{
					SpawnedEvent.SpawnPoint = startSpot;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
	}

	KFPC = KFPlayerController(NewPlayer);
	KFPRI = KFPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);

	// To fix custom post processing chain when not running in editor or PIE.
	if (KFPC != none)
	{
		LP = LocalPlayer(KFPC.Player); 
		if(LP != None) 
		{ 
			LP.RemoveAllPostProcessingChains(); 
			LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
			if(KFPC.myHUD != None)
			{
				KFPC.myHUD.NotifyBindPostProcessEffects();
			}
		} 
	}

	KFGameInfo(WorldInfo.Game).SetTeam( NewPlayer, KFGameInfo(WorldInfo.Game).Teams[0] );

	if( KFPC != none )
	{
		// Initialize game play post process effects such as damage, low health, etc.
		KFPC.InitGameplayPostProcessFX();
	}
	if( KFPRI!=None )
	{
		if( KFPRI.Deaths == 0 )
			KFPRI.Score = KFGameInfo(WorldInfo.Game).DifficultyInfo.GetAdjustedStartingCash();
		KFPRI.PlayerHealth = NewPlayer.Pawn.Health;
		KFPRI.PlayerHealthPercent = FloatToByte( float(NewPlayer.Pawn.Health) / float(NewPlayer.Pawn.HealthMax) );
	}
	return true;
}

function PlayerBuyStats( ExtPlayerController PC, class<Ext_PerkBase> Perk, int iStat, int Amount )
{
	local Ext_PerkBase P;
	local int i;

	if( bGameHasEnded )
		return;
	
	P = PC.ActivePerkManager.FindPerk(Perk);
	if( P==None || !P.bPerkNetReady || iStat>=P.PerkStats.Length )
		return;
	Amount = Min(Amount,P.PerkStats[iStat].MaxValue-P.PerkStats[iStat].CurrentValue);
	if( Amount<=0 )
		return;
	i = Amount*P.PerkStats[iStat].CostPerValue;
	if( i>P.CurrentSP )
	{
		Amount = P.CurrentSP/P.PerkStats[iStat].CostPerValue;
		if( Amount<=0 )
			return;
		i = Amount*P.PerkStats[iStat].CostPerValue;
	}
	P.CurrentSP-=i;
	if( !P.IncrementStat(iStat,Amount) )
		PC.ClientMessage("Failed to buy stat.");
}
function PlayerChangePerk( ExtPlayerController PC, class<Ext_PerkBase> NewPerk )
{
	if( bGameHasEnded )
		return;
	if( NewPerk==PC.ActivePerkManager.CurrentPerk.Class )
	{
		if( PC.PendingPerkClass!=None )
		{
			PC.ClientMessage("You will remain the same perk now.");
			PC.PendingPerkClass = None;
		}
	}
	else if( PC.ActivePerkManager.CurrentPerk==None || KFPawn_Customization(PC.Pawn)!=None || (!PC.bSetPerk && KFGameReplicationInfo(WorldInfo.GRI).bTraderIsOpen) )
	{
		if( PC.ActivePerkManager.ApplyPerkClass(NewPerk) )
		{
			PC.ClientMessage("You have changed your perk to "$NewPerk.Default.PerkName);
			PC.bSetPerk = true;
		}
		else PC.ClientMessage("Invalid perk "$NewPerk.Default.PerkName);
	}
	else if( PC.bSetPerk )
		PC.ClientMessage("Can only change perks once per wave");
	else
	{
		PC.ClientMessage("You will change to perk '"$NewPerk.Default.PerkName$"' during trader time.");
		PC.PendingPerkClass = NewPerk;
	}
}
function CheckPerkChange( ExtPlayerController PC )
{
	if( PC.PendingPerkClass!=None )
	{
		if( PC.ActivePerkManager.ApplyPerkClass(PC.PendingPerkClass) )
		{
			PC.ClientMessage("You have changed your perk to "$PC.PendingPerkClass.Default.PerkName);
			PC.bSetPerk = true;
		}
		else PC.ClientMessage("Invalid perk "$PC.PendingPerkClass.Default.PerkName);
		PC.PendingPerkClass = None;
	}
}
function Tick(float DeltaTime)
{
	local bool bCheckedWave;
	local ExtPlayerController ExtPC;
	
	if( KFGameReplicationInfo(WorldInfo.GRI).bTraderIsOpen && !bCheckedWave )
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',ExtPC)
			CheckPerkChange(ExtPC);
			
		bCheckedWave = true;
	}
	else if( bCheckedWave )
		bCheckedWave = false;
}
function PlayerBoughtTrait( ExtPlayerController PC, class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait )
{
	local Ext_PerkBase P;
	local int i,cost;

	if( bGameHasEnded )
		return;
	
	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if( P==None || !P.bPerkNetReady )
		return;

	for( i=0; i<P.PerkTraits.Length; ++i )
	{
		if( P.PerkTraits[i].TraitType==Trait )
		{
			if( P.PerkTraits[i].CurrentLevel>=Trait.Default.NumLevels )
				return;
			cost = Trait.Static.GetTraitCost(P.PerkTraits[i].CurrentLevel);
			if( cost>P.CurrentSP || !Trait.Static.MeetsRequirements(P.PerkTraits[i].CurrentLevel,P) )
				return;
			
			PC.ActivePerkManager.bStatsDirty = true;
			P.CurrentSP-=cost;
			P.bForceNetUpdate = true;
			++P.PerkTraits[i].CurrentLevel;
			P.ClientReceiveTraitLvl(i,P.PerkTraits[i].CurrentLevel);
			if( P.PerkTraits[i].CurrentLevel==1 )
				P.PerkTraits[i].Data = Trait.Static.InitializeFor(P,PC);

			if( PC.ActivePerkManager.CurrentPerk==P )
			{
				Trait.Static.TraitDeActivate(P,P.PerkTraits[i].CurrentLevel-1,P.PerkTraits[i].Data);
				Trait.Static.TraitActivate(P,P.PerkTraits[i].CurrentLevel,P.PerkTraits[i].Data);
				if( KFPawn_Human(PC.Pawn)!=None )
				{
					Trait.Static.CancelEffectOn(KFPawn_Human(PC.Pawn),P,P.PerkTraits[i].CurrentLevel-1,P.PerkTraits[i].Data);
					Trait.Static.ApplyEffectOn(KFPawn_Human(PC.Pawn),P,P.PerkTraits[i].CurrentLevel,P.PerkTraits[i].Data);
				}
			}
			break;
		}
	}
}
function PlayerUnloadInfo( ExtPlayerController PC, byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload )
{
	local Ext_PerkBase P;
	local int LostExp,NewLvl;

	// Verify if client tries to cause errors.
	if( PC==None || PerkClass==None || PC.ActivePerkManager==None )
		return;
	
	// Perk unloading disabled on this server.
	if( MinUnloadPerkLevel==-1 )
	{
		if( !bUnload )
			PC.ClientGotUnloadInfo(CallID,0);
		return;
	}
	
	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if( P==None ) // More client hack attempts.
		return;
	
	if( P.CurrentLevel<MinUnloadPerkLevel ) // Verify minimum level.
	{
		if( !bUnload )
			PC.ClientGotUnloadInfo(CallID,1,MinUnloadPerkLevel);
		return;
	}
	
	// Calc how much EXP is lost on this progress.
	LostExp = Round(float(P.CurrentEXP) * UnloadPerkExpCost);

	if( !bUnload )
	{
		if( LostExp==0 ) // Generous server admin!
			PC.ClientGotUnloadInfo(CallID,2,0,0);
		else
		{
			// Calc how many levels are dropped.
			NewLvl = P.CalcLevelForExp(P.CurrentEXP-LostExp);
			PC.ClientGotUnloadInfo(CallID,2,LostExp,P.CurrentLevel-NewLvl);
		}
		return;
	}
	P.UnloadStats();
	P.CurrentEXP -= LostExp;
	P.SetInitialLevel();
	PC.ActivePerkManager.PRIOwner.SetLevelProgress(P.CurrentLevel,P.CurrentPrestige,P.MinimumLevel,P.MaximumLevel);
	if( PC.Pawn!=None )
		PC.Pawn.Suicide();
}


function ResetPlayerPerk( ExtPlayerController PC, class<Ext_PerkBase> PerkClass, bool bPrestige )
{
	local Ext_PerkBase P;

	if( bGameHasEnded )
		return;
	
	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if( P==None || !P.bPerkNetReady )
		return;
	if( bPrestige )
	{
		if( !P.CanPrestige() )
		{
			PC.ClientMessage("Prestige for this perk is not allowed.");
			return;
		}
		++P.CurrentPrestige;
	}
	P.FullReset(bPrestige);
}

function bool CheckReplacement(Actor Other)
{
	if( bNoBoomstickJumping && KFWeap_Shotgun_DoubleBarrel(Other)!=None )
		KFWeap_Shotgun_DoubleBarrel(Other).DoubleBarrelKickMomentum = 5.f;
	return true;
}

final function InitCustomChars( ExtPlayerReplicationInfo PRI )
{
	PRI.CustomCharList = CustomCharList;
}

final function bool HasPrivs( ExtPlayerReplicationInfo P )
{
	return WorldInfo.NetMode==NM_StandAlone || (P!=None && P.ShowAdminName() && (P.AdminType<=1 || P.AdminType==255));
}
function AdminCommand( ExtPlayerController PC, int PlayerID, int Action )
{
	local ExtPlayerController E;
	local int i;
	
	if( bNoAdminCommands )
	{
		PC.ClientMessage("Admin level commands are disabled.",'Priority');
		return;
	}
	if( !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)) )
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}
	
	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		if( E.PlayerReplicationInfo.PlayerID==PlayerID )
			break;
	
	if( E==None )
	{
		PC.ClientMessage("Action failed, missing playerID: "$PlayerID,'Priority');
		return;
	}
	
	if( Action>=100 ) // Set perk level.
	{
		if( E.ActivePerkManager.CurrentPerk==None )
		{
			PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
			return;
		}
		if( Action>=100000 ) // Set prestige level.
		{
			if( E.ActivePerkManager.CurrentPerk.MinLevelForPrestige<0 )
			{
				PC.ClientMessage("Perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" has prestige disabled!",'Priority');
				return;
			}
			Action = Min(Action-100000,E.ActivePerkManager.CurrentPerk.MaxPrestige);
			E.ActivePerkManager.CurrentPerk.CurrentPrestige = Action;
			PC.ClientMessage("Set "$E.PlayerReplicationInfo.PlayerName$"' perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" prestige level to "$Action,'Priority');
			
			E.ActivePerkManager.CurrentPerk.FullReset(true);
		}
		else
		{
			Action = Clamp(Action-100,E.ActivePerkManager.CurrentPerk.MinimumLevel,E.ActivePerkManager.CurrentPerk.MaximumLevel);
			E.ActivePerkManager.CurrentPerk.CurrentEXP = E.ActivePerkManager.CurrentPerk.GetNeededExp(Action-1);
			PC.ClientMessage("Set "$E.PlayerReplicationInfo.PlayerName$"' perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" level to "$Action,'Priority');
			
			E.ActivePerkManager.CurrentPerk.SetInitialLevel();
			E.ActivePerkManager.CurrentPerk.UpdatePRILevel();
		}
		return;
	}

	switch( Action )
	{
	case 0: // Reset ALL Stats
		for( i=0; i<E.ActivePerkManager.UserPerks.Length; ++i )
			E.ActivePerkManager.UserPerks[i].FullReset();
		PC.ClientMessage("Reset EVERY perk for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		break;
	case 1: // Reset Current Perk Stats
		if( E.ActivePerkManager.CurrentPerk!=None )
		{
			E.ActivePerkManager.CurrentPerk.FullReset();
			PC.ClientMessage("Reset perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 2: // Add 1,000 XP
	case 3: // Add 10,000 XP
	case 4: // Advance Perk Level
		if( E.ActivePerkManager.CurrentPerk!=None )
		{
			if( Action==2 )
				i = 1000;
			else if( Action==3 )
				i = 10000;
			else i = Max(E.ActivePerkManager.CurrentPerk.NextLevelEXP - E.ActivePerkManager.CurrentPerk.CurrentEXP,0);
			E.ActivePerkManager.EarnedEXP(i);
			PC.ClientMessage("Gave "$i$" XP for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 5: // Unload all stats
		if( E.ActivePerkManager.CurrentPerk!=None )
		{
			E.ActivePerkManager.CurrentPerk.UnloadStats(1);
			PC.ClientMessage("Unloaded all stats for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 6: // Unload all traits
		if( E.ActivePerkManager.CurrentPerk!=None )
		{
			E.ActivePerkManager.CurrentPerk.UnloadStats(2);
			PC.ClientMessage("Unloaded all traits for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 7: // Remove 1,000 XP
	case 8: // Remove 10,000 XP
		if( E.ActivePerkManager.CurrentPerk!=None )
		{
			if( Action==6 )
				i = 1000;
			else i = 10000;
			E.ActivePerkManager.CurrentPerk.CurrentEXP = Max(E.ActivePerkManager.CurrentPerk.CurrentEXP-i,0);
			PC.ClientMessage("Removed "$i$" XP from "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 9: // Show Debug Info
		PC.ClientMessage("DEBUG info for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		PC.ClientMessage("PerkManager "$E.ActivePerkManager$" Current Perk: "$E.ActivePerkManager.CurrentPerk,'Priority');
		PC.ClientMessage("Perks Count: "$E.ActivePerkManager.UserPerks.Length,'Priority');
		for( i=0; i<E.ActivePerkManager.UserPerks.Length; ++i )
			PC.ClientMessage("Perk "$i$": "$E.ActivePerkManager.UserPerks[i]$" XP:"$E.ActivePerkManager.UserPerks[i].CurrentEXP$" Lv:"$E.ActivePerkManager.UserPerks[i].CurrentLevel$" Rep:"$E.ActivePerkManager.UserPerks[i].bPerkNetReady,'Priority');
		break;
	default:
		PC.ClientMessage("Unknown admin action.",'Priority');
	}
}
function AdminSetMOTD( ExtPlayerController PC, string S )
{
	if( !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)) )
		return;
	ServerMOTD = S;
	SaveConfig();
	PC.ClientMessage("Message of the Day updated.",'Priority');
}

function PlayerChangeSpec( ExtPlayerController PC, bool bSpectator )
{
	if( bSpectator==PC.PlayerReplicationInfo.bOnlySpectator || PC.NextSpectateChange>WorldInfo.TimeSeconds )
		return;
	PC.NextSpectateChange = WorldInfo.TimeSeconds+0.5;

	if( WorldInfo.Game.bGameEnded )
		PC.ClientMessage("Can't change spectate mode after end-game.");
	else if( WorldInfo.Game.bWaitingToStartMatch )
		PC.ClientMessage("Can't change spectate mode before game has started.");
	else if( WorldInfo.Game.AtCapacity(bSpectator,PC.PlayerReplicationInfo.UniqueId) )
		PC.ClientMessage("Can't change spectate mode because game is at its maximum capacity.");
	else if( bSpectator )
	{
		PC.NextSpectateChange = WorldInfo.TimeSeconds+2.5;
		if( PC.PlayerReplicationInfo.Team!=None )
			PC.PlayerReplicationInfo.Team.RemoveFromTeam(PC);
		PC.PlayerReplicationInfo.bOnlySpectator = true;
		if( PC.Pawn!=None )
			PC.Pawn.KilledBy(None);
		PC.Reset();
		--WorldInfo.Game.NumPlayers;
		++WorldInfo.Game.NumSpectators;
		WorldInfo.Game.Broadcast(PC,PC.PlayerReplicationInfo.GetHumanReadableName()@"became a spectator");
		RemoveRespawn(PC);
	}
	else
	{
		PC.PlayerReplicationInfo.bOnlySpectator = false;
		if( !WorldInfo.Game.ChangeTeam(PC,WorldInfo.Game.PickTeam(0,PC,PC.PlayerReplicationInfo.UniqueId),false) )
		{
			PC.PlayerReplicationInfo.bOnlySpectator = true;
			PC.ClientMessage("Can't become an active player, failed to set a team.");
			return;
		}
		PC.NextSpectateChange = WorldInfo.TimeSeconds+2.5;
		++WorldInfo.Game.NumPlayers;
		--WorldInfo.Game.NumSpectators;
		PC.Reset();
		WorldInfo.Game.Broadcast(PC,PC.PlayerReplicationInfo.GetHumanReadableName()@"became an active player");
		if( bRespawnCheck )
			CheckRespawn(PC);
	}
}

function bool GetNextItem( ExtPlayerReplicationInfo PRI, int RepIndex )
{
	if( RepIndex>=CustomItemList.Length )
		return false;
	PRI.ClientAddTraderItem(class'KFGameReplicationInfo'.Default.TraderItems.SaleItems.Length+RepIndex,CustomItemList[RepIndex]);
	return true;
}

function InitWebAdmin( ExtWebAdmin_UI UI )
{
	local int i;

	UI.AddSettingsPage("Main Server Ext",Class,WebConfigs,WebAdminGetValue,WebAdminSetValue);
	for( i=0; i<LoadedPerks.Length; ++i )
		LoadedPerks[i].Static.InitWebAdmin(UI);
}
function string WebAdminGetValue( name PropName, int ElementIndex )
{
	switch( PropName )
	{
	case 'StatFileDir':
		return StatFileDir;
	case 'ForcedMaxPlayers':
		return string(ForcedMaxPlayers);
	case 'PlayerRespawnTime':
		return string(PlayerRespawnTime);
	case 'StatAutoSaveWaves':
		return string(StatAutoSaveWaves);
	case 'PostGameRespawnCost':
		return string(PostGameRespawnCost);
	case 'bKillMessages':
		return string(bKillMessages);
	case 'LargeMonsterHP':
		return string(LargeMonsterHP);
	case 'bDamageMessages':
		return string(bDamageMessages);
	case 'bEnableMapVote':
		return string(bEnableMapVote);
	case 'bNoBoomstickJumping':
		return string(bNoBoomstickJumping);
	case 'bNoAdminCommands':
		return string(bNoAdminCommands);
	case 'bDumpXMLStats':
		return string(bDumpXMLStats);
	case 'bRagdollFromFall':
		return string(bRagdollFromFall);
	case 'bRagdollFromMomentum':
		return string(bRagdollFromMomentum);
	case 'bRagdollFromBackhit':
		return string(bRagdollFromBackhit);
	case 'bAddCountryTags':
		return string(bAddCountryTags);
	case 'MaxTopPlayers':
		return string(MaxTopPlayers);
	case 'MinUnloadPerkLevel':
		return string(MinUnloadPerkLevel);
	case 'UnloadPerkExpCost':
		return string(UnloadPerkExpCost);
	case 'PerkClasses':
		return (ElementIndex==-1 ? string(PerkClasses.Length) : PerkClasses[ElementIndex]);
	case 'CustomChars':
		return (ElementIndex==-1 ? string(CustomChars.Length) : CustomChars[ElementIndex]);
	case 'AdminCommands':
		return (ElementIndex==-1 ? string(AdminCommands.Length) : AdminCommands[ElementIndex]);
	case 'CustomItems':
		return (ElementIndex==-1 ? string(CustomItems.Length) : CustomItems[ElementIndex]);
	case 'ServerMOTD':
		return Repl(ServerMOTD,"|",Chr(10));
	case 'BonusGameSongs':
		return (ElementIndex==-1 ? string(BonusGameSongs.Length) : BonusGameSongs[ElementIndex]);
	case 'BonusGameFX':
		return (ElementIndex==-1 ? string(BonusGameFX.Length) : BonusGameFX[ElementIndex]);
	}
}
final function UpdateArray( out array<string> Ar, int Index, const out string Value )
{
	if( Value=="#DELETE" )
		Ar.Remove(Index,1);
	else
	{
		if( Index>=Ar.Length )
			Ar.Length = Index+1;
		Ar[Index] = Value;
	}
}
function WebAdminSetValue( name PropName, int ElementIndex, string Value )
{
	switch( PropName )
	{
	case 'StatFileDir':
		StatFileDir = Value;				break;
	case 'ForcedMaxPlayers':
		ForcedMaxPlayers = int(Value);		break;
	case 'PlayerRespawnTime':
		PlayerRespawnTime = int(Value);		break;
	case 'StatAutoSaveWaves':
		StatAutoSaveWaves = int(Value);		break;
	case 'PostGameRespawnCost':
		PostGameRespawnCost = int(Value);	break;
	case 'bKillMessages':
		bKillMessages = bool(Value);		break;
	case 'LargeMonsterHP':
		LargeMonsterHP = int(Value);		break;
	case 'MinUnloadPerkLevel':
		MinUnloadPerkLevel = int(Value);	break;
	case 'UnloadPerkExpCost':
		UnloadPerkExpCost = float(Value);	break;
	case 'bDamageMessages':
		bDamageMessages = bool(Value);		break;
	case 'bEnableMapVote':
		bEnableMapVote = bool(Value);		break;
	case 'bNoAdminCommands':
		bNoAdminCommands = bool(Value);		break;
	case 'bDumpXMLStats':
		bDumpXMLStats = bool(Value);		break;
	case 'bNoBoomstickJumping':
		bNoBoomstickJumping = bool(Value);	break;
	case 'bRagdollFromFall':
		bRagdollFromFall = bool(Value);		break;
	case 'bRagdollFromMomentum':
		bRagdollFromMomentum = bool(Value);	break;
	case 'bRagdollFromBackhit':
		bRagdollFromBackhit = bool(Value);	break;
	case 'bAddCountryTags':
		bAddCountryTags = bool(Value);		break;
	case 'MaxTopPlayers':
		MaxTopPlayers = int(Value);			break;
	case 'ServerMOTD':
		ServerMOTD = Repl(Value,Chr(13)$Chr(10),"|"); break;
	case 'PerkClasses':
		UpdateArray(PerkClasses,ElementIndex,Value);	break;
	case 'CustomChars':
		UpdateArray(CustomChars,ElementIndex,Value);	break;
	case 'AdminCommands':
		UpdateArray(AdminCommands,ElementIndex,Value);	break;
	case 'CustomItems':
		UpdateArray(CustomItems,ElementIndex,Value);	break;
	case 'BonusGameSongs':
		UpdateArray(BonusGameSongs,ElementIndex,Value);	break;
	case 'BonusGameFX':
		UpdateArray(BonusGameFX,ElementIndex,Value);	break;
	default:
		return;
	}
	SaveConfig();
}

defaultproperties
{
	DevList.Add("0x0110000100E8984E")
	DevList.Add("0x01100001023DF8A8")
	WebConfigs.Add((PropType=0,PropName="StatFileDir",UIName="Stat File Dir",UIDesc="Location of the stat files on the HDD (%s = unique player ID)"))
	WebConfigs.Add((PropType=0,PropName="ForcedMaxPlayers",UIName="Server Max Players",UIDesc="A forced max players value of the server (0 = use standard KF2 setting)"))
	WebConfigs.Add((PropType=0,PropName="PlayerRespawnTime",UIName="Respawn Time",UIDesc="Players respawn time in seconds after they die (0 = no respawning)"))
	WebConfigs.Add((PropType=0,PropName="PostGameRespawnCost",UIName="Post-Game Respawn Cost",UIDesc="Amount of dosh it'll cost to be respawned after end-game (only for custom gametypes that support this)."))
	WebConfigs.Add((PropType=0,PropName="StatAutoSaveWaves",UIName="Stat Auto-Save Waves",UIDesc="How often should stats be auto-saved (1 = every wave, 2 = every second wave etc)"))
	WebConfigs.Add((PropType=0,PropName="MinUnloadPerkLevel",UIName="Min Unload Perk Level",UIDesc="Minimum level a player should be on before they can use the perk stat unload (-1 = never)."))
	WebConfigs.Add((PropType=0,PropName="UnloadPerkExpCost",UIName="Perk Unload XP Cost",UIDesc="The percent of XP it costs for a player to use a perk unload (1 = all XP, 0 = none)."))
	WebConfigs.Add((PropType=1,PropName="bKillMessages",UIName="Show Kill Messages",UIDesc="Display on players HUD a kill counter every time they kill something"))
	WebConfigs.Add((PropType=0,PropName="LargeMonsterHP",UIName="Large Monster HP",UIDesc="If the enemy kill a monster with more HP then this, broadcast kill message to everyone"))
	WebConfigs.Add((PropType=1,PropName="bDamageMessages",UIName="Show Damage Messages",UIDesc="Display on players HUD a damage counter every time they damage an enemy"))
	WebConfigs.Add((PropType=1,PropName="bEnableMapVote",UIName="Enable MapVote",UIDesc="Enable MapVote X on this server"))
	WebConfigs.Add((PropType=1,PropName="bNoBoomstickJumping",UIName="No Boomstick Jumps",UIDesc="Disable boomstick knockback, so people can't glitch with it on maps"))
	WebConfigs.Add((PropType=1,PropName="bNoAdminCommands",UIName="Disable Admin menu",UIDesc="Disable admin menu commands so admins can't modify XP or levels of players"))
	WebConfigs.Add((PropType=1,PropName="bDumpXMLStats",UIName="Dump XML stats",UIDesc="Dump XML stat files for some external stat loggers"))
	WebConfigs.Add((PropType=1,PropName="bRagdollFromFall",UIName="Ragdoll From Fall",UIDesc="Make players ragdoll if they fall from a high place"))
	WebConfigs.Add((PropType=1,PropName="bRagdollFromMomentum",UIName="Ragdoll From Momentum",UIDesc="Make players ragdoll if they take a damage with high momentum transfer"))
	WebConfigs.Add((PropType=1,PropName="bRagdollFromBackhit",UIName="Ragdoll From Backhit",UIDesc="Make players ragdoll if they take a big hit to their back"))
	WebConfigs.Add((PropType=1,PropName="bAddCountryTags",UIName="Add Country Tags",UIDesc="Add player country tags to their names"))
	WebConfigs.Add((PropType=0,PropName="MaxTopPlayers",UIName="Max top players",UIDesc="Maximum top players to broadcast of and to keep track of."))
	WebConfigs.Add((PropType=2,PropName="PerkClasses",UIName="Perk Classes",UIDesc="List of RPG perks players can play as (careful with removing them, because any perks removed will permanently delete the gained XP for every player for that perk)!",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="CustomChars",UIName="Custom Chars",UIDesc="List of custom characters for this server (prefix with * to mark as admin character).",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="AdminCommands",UIName="Admin Commands",UIDesc="List of Admin commands to show on scoreboard UI for admins (use : to split actual command with display name for the command)",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="CustomItems",UIName="Custom Inventory",UIDesc="List of custom inventory to add to trader (must be KFWeaponDefinition class).",NumElements=-1))
	WebConfigs.Add((PropType=3,PropName="ServerMOTD",UIName="MOTD",UIDesc="Message of the Day"))
	WebConfigs.Add((PropType=2,PropName="BonusGameSongs",UIName="Bonus Game Songs",UIDesc="List of custom musics to play during level change pong game.",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="BonusGameFX",UIName="Bonus Game FX",UIDesc="List of custom FX to play on pong game.",NumElements=-1))
}
