class Ext_T_SupplierInteract extends KFUsablePerkTrigger;

struct FActiveUsers
{
	var Pawn Player;
	var transient float NextUseTime;
};
var array<FActiveUsers> ActiveUsers;

var repnotify KFPawn_Human PlayerOwner;
var Ext_PerkBase PerkOwner;

var() float ReuseTime;
var bool bGrenades;

replication
{
	if( true )
		PlayerOwner,bGrenades;
}

simulated event ReplicatedEvent(name VarName)
{
	if( VarName=='PlayerOwner' && PlayerOwner!=None )
	{
		SetLocation(PlayerOwner.Location);
		SetBase(PlayerOwner);
	}
}

simulated function int GetInteractionIndex( Pawn User )
{
	return (bGrenades ? IMT_ReceiveGrenades : InteractionIndex);
}

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local KFPawn_Human KFP;

	Super.Touch(Other, OtherComp, HitLocation, HitNormal);

	KFP = KFPawn_Human(Other);
	if( KFP != none && KFP.Controller != none && KFP != PlayerOwner )
	{
		KFPlayerController(KFP.Controller).SetPendingInteractionMessage();
	}
}

simulated event UnTouch(Actor Other)
{
	local KFPawn_Human KFP;

	super.UnTouch( Other );

	KFP = KFPawn_Human(Other);
	if( KFP != none && KFP.Controller != none && KFP != PlayerOwner )
	{
		KFPlayerController(KFP.Controller).SetPendingInteractionMessage();
	}
}

simulated function RecheckUser()
{
	local KFPawn_Human Toucher;

	// Notify local player owner that this is available again.
	foreach TouchingActors(class'KFPawn_Human', Toucher)
	{
		if( Toucher.IsLocallyControlled() )
			Touch(Toucher,None,Location,vect(1,0,0));
	}
}

simulated function bool GetCanInteract( Pawn User, optional bool bInteractIfTrue = false)
{
	local int i;
	local ExtPlayerReplicationInfo PRI;

	if( PlayerOwner==None || User==PlayerOwner || KFPawn_Human(User)==None || User.Health<=0 )
		return false;

	if( WorldInfo.NetMode==NM_Client )
	{
		PRI = ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
		if( !User.IsLocallyControlled() || PRI==None || !PRI.CanUseSupply(User) )
			return false;
		
		if( bInteractIfTrue )
		{
			PRI.UsedSupply(User,ReuseTime);
			SetTimer(ReuseTime+0.1,false,'RecheckUser');
			
			if( KFPlayerController(User.Controller)!=None )
				KFPlayerController(User.Controller).SetPendingInteractionMessage();
		}
	}
	else
	{
		i = ActiveUsers.Find('Player',User);
		if( i>=0 && ActiveUsers[i].NextUseTime>WorldInfo.TimeSeconds )
			return false;
		
		if( bInteractIfTrue )
		{
			if( i==-1 )
			{
				i = ActiveUsers.Length;
				ActiveUsers.Length = i+1;
				ActiveUsers[i].Player = User;
				SetTimer(10.f,true,'CleanupUsers');
			}
			ActiveUsers[i].NextUseTime = WorldInfo.TimeSeconds+ReuseTime;
		}
	}
	
	if( bInteractIfTrue && WorldInfo.NetMode!=NM_Client )
	{
		GiveAmmunition(KFPawn_Human(User));
	}
	return true;
}
function CleanupUsers()
{
	local int i;
	
	for( i=(ActiveUsers.Length-1); i>=0; --i )
		if( ActiveUsers[i].Player==None || ActiveUsers[i].Player.Health<=0 || ActiveUsers[i].NextUseTime<WorldInfo.TimeSeconds )
			ActiveUsers.Remove(i,1);
	if( ActiveUsers.Length==0 )
		ClearTimer('CleanupUsers');
}
final function GiveAmmunition( KFPawn_Human Other )
{
	local KFWeapon KFW;

	if( PlayerController(PlayerOwner.Controller)!=None )
		PlayerController(PlayerOwner.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Game', (bGrenades ? GMT_GaveGrenadesTo : GMT_GaveAmmoTo), Other.PlayerReplicationInfo );
	if( PlayerController(Other.Controller)!=None )
	{
		PlayerController(Other.Controller).ReceiveLocalizedMessage( class'KFLocalMessage_Game', (bGrenades ? GMT_ReceivedGrenadesFrom : GMT_ReceivedAmmoFrom), PlayerOwner.PlayerReplicationInfo );
		if( ExtPlayerController(Other.Controller)!=None )
			ExtPlayerController(Other.Controller).ClientUsedAmmo(Self);
	}
	if( PerkOwner!=None )
		PerkOwner.EarnedEXP(25);

	if( bGrenades )
	{
		if( KFInventoryManager(Other.InvManager)!=None )
			KFInventoryManager(Other.InvManager).AddGrenades(1);
	}
	else
	{
		foreach Other.InvManager.InventoryActors( class'KFWeapon', KFW )
		{
			if( KFW.DenyPerkResupply() )
				continue;

			// resupply 1 mag for every 5 initial mags
			KFW.AddAmmo( Max( KFW.InitialSpareMags[0] / 3, 1 ) * KFW.MagazineCapacity[0] );

			if( KFW.CanRefillSecondaryAmmo() )
			{
				// resupply 1 mag for every 5 initial mags
				KFW.AddSecondaryAmmo( Max( KFW.InitialSpareMags[1] / 3, 1 ) );
			}
		}
	}
}
simulated final function UsedOnClient( Pawn User )
{
	local ExtPlayerReplicationInfo PRI;

	PRI = ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
	if( PRI!=None )
		PRI.UsedSupply(User,ReuseTime);
	SetTimer(ReuseTime+0.1,false,'RecheckUser');
	
	if( WorldInfo.NetMode==NM_Client && KFPlayerController(User.Controller)!=None )
		KFPlayerController(User.Controller).SetPendingInteractionMessage();
}

simulated function Destroyed()
{
	local KFPawn_Human Toucher;

	//notify all touching actors that they are not touching this non existing trigger anymore
	foreach TouchingActors(class'KFPawn_Human', Toucher)
	{
		UnTouch(Toucher);
	}
}

DefaultProperties
{
	InteractionIndex=IMT_ReceiveAmmo
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=true
	bHidden=false
	ReuseTime=90
	bProjTarget=false
	
	Components.Empty()
	Components.Add(CollisionCylinder)
}