// Written by Marco.
class ExtProj_CrackerGrenade extends KFProj_FragGrenade
	hidedropdown;

var() byte NumCrackers;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(FuseTime+FRand()*0.25, true, 'ExplodeTimer');
}
simulated function ExplodeTimer()
{
    local Actor HitActor;
    local vector HitLocation, HitNormal;

	if( WorldInfo.NetMode!=NM_Client && InstigatorController==none )
	{
		Destroy();
		return;
	}
    GetExplodeEffectLocation(HitLocation, HitNormal, HitActor);
	if( --NumCrackers==0 )
		TriggerExplosion(HitLocation, HitNormal, HitActor);
	else SmallExplosion(HitLocation, HitNormal, HitActor);
}
simulated function SmallExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local vector NudgedHitLocation, ExplosionDirection;

	Velocity = VRand()*(900.f*FRand());
	SetPhysics(PHYS_Falling);
	if (ExplosionTemplate != None)
	{
		// using a hitlocation slightly away from the impact point is nice for certain things
		NudgedHitLocation = HitLocation + (HitNormal * 32.f);

		ExplosionActor = Spawn(ExplosionActorClass, self,, NudgedHitLocation, rotator(HitNormal));
		if (ExplosionActor != None)
		{
			ExplosionActor.RemoteRole = ROLE_None;
			ExplosionActor.Instigator = Instigator;
			ExplosionActor.InstigatorController = InstigatorController;

			PrepareExplosionTemplate();

			// If the locations are zero (probably because this exploded in the air) set defaults
			if( IsZero(HitLocation) )
				HitLocation = Location;

			if( IsZero(HitNormal) )
			{
				HitNormal = vect(0,0,1);
			}

			// these are needed for the decal tracing later in GameExplosionActor.Explode()
			ExplosionTemplate.HitActor = HitActor;
			ExplosionTemplate.HitLocation = HitLocation;// NudgedHitLocation
			ExplosionTemplate.HitNormal = HitNormal;

			// If desired, attach to mover if we hit one
			if(bAttachExplosionToHitMover && InterpActor(HitActor) != None)
			{
				ExplosionActor.Attachee = HitActor;
				ExplosionTemplate.bAttachExplosionEmitterToAttachee = TRUE;
				ExplosionActor.SetBase(HitActor);
			}

			// directional?
			if (ExplosionTemplate.bDirectionalExplosion)
			{
				ExplosionDirection = GetExplosionDirection(HitNormal);
				//DrawDebugLine(ExplosionActor.Location, ExplosionActor.Location+ExplosionDirection*64, 255, 255, 0, TRUE);
			}

			// @todo: make this function responsible for setting explosion instance parameters, and take instance parameters
			// out of GearExplosion (e.g. Attachee)
			PrepareExplosionActor(ExplosionActor);

			ExplosionActor.Explode(ExplosionTemplate, ExplosionDirection);		// go bewm
		}
	}
}
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
}
simulated function Explode(vector HitLocation, vector HitNormal);

defaultproperties
{
	bCanDisintegrate=false
	FuseTime=0.35
	NumCrackers=6
	bNetTemporary=true
}