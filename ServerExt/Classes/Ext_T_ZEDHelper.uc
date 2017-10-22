Class Ext_T_ZEDHelper extends Info
	transient
	DependsOn(Ext_TraitZED_Summon)
	config(ServerExt);

var config array<FZEDTypes> ZedTypes; // Dummy hack, not really config but merely just for being able to set class on defaults.

var() float FriendlyScalar;
var Pawn PawnOwner;
var byte CurLevel,RespawnHelperTime,NoLiveCounter;
var KFPawn_Monster LiveHelper;
var class<KFPawn_Monster> PrevMonster;
var float PrevMonsterHP;

var float HPScale,DamageScale;
var int OldKillsValue;
var bool bNeedsKillZed,bIsExtra;

function PostBeginPlay()
{
	PawnOwner = Pawn(Owner);
	bNeedsKillZed = true;
	if( PawnOwner==None )
		Destroy();
	else
	{
		OldKillsValue = PawnOwner.PlayerReplicationInfo.Kills;
		SetTimer(1+(FRand()*0.1),true);
	}
}
function Timer()
{
	if( PawnOwner==None || PawnOwner.Health<=0 || PawnOwner.PlayerReplicationInfo==None )
		Destroy();
	else if( bNeedsKillZed )
	{
		if( RespawnHelperTime>1 )
			--RespawnHelperTime;
		if( OldKillsValue==PawnOwner.PlayerReplicationInfo.Kills )
			return;
		bNeedsKillZed = false;
	}
	else if( RespawnHelperTime>0 )
	{
		if( --RespawnHelperTime==0 )
			SpawnHelper();
	}
	else if( LiveHelper==None || LiveHelper.Health<=0 )
	{
		OldKillsValue = PawnOwner.PlayerReplicationInfo.Kills;
		bNeedsKillZed = true;
		RespawnHelperTime = 60;
	}
	else if( !HasLiveZeds() )
	{
		if( NoLiveCounter==0 )
		{
			PrevMonster = LiveHelper.Class;
			PrevMonsterHP = (float(LiveHelper.Health) / LiveHelper.HealthMax);
			LiveHelper.Died(None,class'KFDT_Healing',vect(0,0,0));
			RespawnHelperTime = 5;
		}
		else --NoLiveCounter;
	}
	else NoLiveCounter = 5;
}
function Destroyed()
{
	if( LiveHelper!=None && LiveHelper.Health>0 )
		LiveHelper.Died(None,class'DmgType_Suicided',vect(0,0,0));
}
final function bool HasLiveZeds()
{
	local KFPawn_Monster M;
	
	if( KFGameReplicationInfo(WorldInfo.GRI).WaveNum>=KFGameReplicationInfo(WorldInfo.GRI).WaveMax ) // No pets on possible bonus waves.
		return false;

	foreach WorldInfo.AllPawns(Class'KFPawn_Monster',M)
		if( M.Health>0 && M.GetTeamNum()!=0 )
			return true;
	return false;
}
final function SpawnHelper()
{
	local class<KFPawn_Monster> MC;
	local byte i;
	local vector V;
	local rotator R;
	local Controller C;
	local Ext_T_MonsterPRI PRI;
	local AkBaseSoundObject TempSound;
	local bool bFinalWave;
	
	if( PawnOwner.PlayerReplicationInfo==None || !HasLiveZeds() )
	{
		RespawnHelperTime = 3;
		return;
	}
	NoLiveCounter = 5;
	bFinalWave = KFGameReplicationInfo(WorldInfo.GRI).IsFinalWave();
	if( bFinalWave && Class<KFPawn_MonsterBoss>(PrevMonster)!=None )
		PrevMonster = None;
	MC = (PrevMonster!=None ? PrevMonster : PickRandomMonster(CurLevel,bFinalWave));

	if( MC!=None )
	{
		R.Yaw = Rand(65536);
		if( MC.Default.SoundGroupArch!=None )
		{
			// Make no entrance roam (for FP's and Scrakes).
			TempSound = MC.Default.SoundGroupArch.EntranceSound;
			MC.Default.SoundGroupArch.EntranceSound = None;
		}
		for( i=0; i<40; ++i )
		{
			V = PawnOwner.Location;
			V.X += (FRand()*300.f-150.f);
			V.Y += (FRand()*300.f-150.f);
			if( !PawnOwner.FastTrace(V,PawnOwner.Location) )
				continue;
			LiveHelper = Spawn(MC,,,V,R);
			if( LiveHelper!=None )
				break;
		}
		if( MC.Default.SoundGroupArch!=None )
			MC.Default.SoundGroupArch.EntranceSound = TempSound;
	}
	if( LiveHelper==None )
		RespawnHelperTime = 2;
	else
	{
		// Downscale.
		LiveHelper.SetDrawScale(LiveHelper.DrawScale*FriendlyScalar);
		LiveHelper.SetCollisionSize(LiveHelper.GetCollisionRadius()*FriendlyScalar,LiveHelper.GetCollisionHeight()*FriendlyScalar);
		
		// Setup AI
		C = Spawn(LiveHelper.ControllerClass);
		if( KFAIController(C)!=None )
		{
			KFAIController(C).bCanTeleportCloser = false;
			KFAIController(C).DefaultCommandClass = class'Ext_AICommandBasePet';
			KFAIController(C).StuckCheckInterval = 100000.f; // ~27 hours
			KFAIController(C).LastStuckCheckTime = WorldInfo.TimeSeconds;
		}
		LiveHelper.SpecialMoveHandler.SpecialMoveClasses[SM_Taunt] = class'Ext_AINoTaunt';
		C.Possess(LiveHelper,false);

		// Set HP.
		LiveHelper.HealthMax = Clamp(LiveHelper.Default.Health,180,900)*HPScale;
		LiveHelper.Health = LiveHelper.HealthMax;
		LiveHelper.DamageScaling = DamageScale;
		LiveHelper.SetWeakGrabCoolDown(28800.f); // Never get grabbed (for 80 hours).
		LiveHelper.bWeakZedGrab = true;
		LiveHelper.bCanGrabAttack = false;
		
		// Scale by previous zed HP.
		if( PrevMonster!=None )
		{
			LiveHelper.Health *= PrevMonsterHP;
			PrevMonster = None;
		}

		// Setup PRI.
		if( C.PlayerReplicationInfo!=None )
			C.PlayerReplicationInfo.Destroy();
		PRI = Spawn(class'Ext_T_MonsterPRI',LiveHelper);
		LiveHelper.PlayerReplicationInfo = PRI;
		C.PlayerReplicationInfo = PRI;
		PRI.PawnOwner = LiveHelper;
		PRI.HealthMax = LiveHelper.HealthMax;
		PRI.MonsterName = Class'KFExtendedHUD'.Static.GetNameOf(MC);
		PRI.OwnerPRI = PawnOwner.PlayerReplicationInfo;
		PRI.MonsterType = MC;
		PRI.PlayerName = PawnOwner.PlayerReplicationInfo.PlayerName$"'s "$PRI.MonsterName;
		PRI.OwnerController = PawnOwner.Controller;
		if( PawnOwner.PlayerReplicationInfo.Team!=None )
			PawnOwner.PlayerReplicationInfo.Team.AddToTeam(C);
		PRI.Timer();
		if( WorldInfo.NetMode!=NM_DedicatedServer )
			PRI.NotifyOwner();
	}
}

final function SetDamageScale( float Sc )
{
	DamageScale = Default.DamageScale*Sc;
	if( LiveHelper!=None )
		LiveHelper.DamageScaling = DamageScale;
}
final function SetHealthScale( float Sc )
{
	HPScale = Default.HPScale*Sc;
}

static final function LoadMonsterList()
{
	local int i,j;
	local array<string> SA;
	local class<KFPawn_Monster> C;
	
	Default.ZedTypes.Length = class'Ext_TraitZED_Summon'.Default.ZedTypes.Length;
	
	for( i=0; i<Default.ZedTypes.Length; ++i )
	{
		SA.Length = 0;
		ParseStringIntoArray(class'Ext_TraitZED_Summon'.Default.ZedTypes[i],SA,",",true);
		
		for( j=0; j<SA.Length; ++j )
		{
			C = class<KFPawn_Monster>(DynamicLoadObject(SA[j],Class'Class'));
			if( C==None )
				continue;
			Default.ZedTypes[i].Zeds[Default.ZedTypes[i].Zeds.Length] = C;
		}
		if( Default.ZedTypes[i].Zeds.Length==0 )
			Default.ZedTypes[i].Zeds[Default.ZedTypes[i].Zeds.Length] = Class'KFPawn_ZedClot_Alpha';
	}
}
static final function class<KFPawn_Monster> PickRandomMonster( byte Level, bool bNotBoss )
{
	local byte i;
	local class<KFPawn_Monster> Res;
	
	Level = Min(Default.ZedTypes.Length-1,Level);
	for( i=0; i<5; ++i )
	{
		Res = Default.ZedTypes[Level].Zeds[Rand(Default.ZedTypes[Level].Zeds.Length)];
		if( !bNotBoss || class<KFPawn_MonsterBoss>(Res)==None )
			break;
	}
	if( bNotBoss && class<KFPawn_MonsterBoss>(Res)!=None )
		Res = Class'KFPawn_ZedFleshpound';
	return Res;
}

defaultproperties
{
	RespawnHelperTime=1
	HPScale=0.5
	DamageScale=2
	FriendlyScalar=0.65
}
