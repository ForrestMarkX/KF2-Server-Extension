// Written by Marco.
class ExtProj_SUPERMedGrenade extends KFProj_MedicGrenade
	hidedropdown;

var() byte NumClusters;

simulated function Disintegrate( rotator inDisintegrateEffectRotation ); // Nope!

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local byte i;
	local KFProj_MedicGrenade P;

	if( bHasExploded )
		return;
	if( InstigatorController==None && WorldInfo.NetMode!=NM_Client ) // Prevent Team-Kill.
	{
		Destroy();
		return;
	}
	Super.TriggerExplosion(HitLocation,HitNormal,HitActor);
	if( WorldInfo.NetMode!=NM_Client )
	{
		for( i=0; i<NumClusters; ++i )
		{
			P = Spawn(class'KFProj_MedicGrenade',,,Location);
			if( P!=None )
			{
				P.InstigatorController = InstigatorController;
				P.Init(VRand());
			}
		}
	}
	bHasExploded = true;
}

simulated function Destroyed()
{
    local Actor HitActor;
    local vector HitLocation, HitNormal;

	// Final Failsafe check for explosion effect
	if( !bHasExploded && WorldInfo.NetMode==NM_Client )
	{
		GetExplodeEffectLocation(HitLocation, HitNormal, HitActor);
        TriggerExplosion(HitLocation, HitNormal, HitActor);
	}
}

defaultproperties
{
	bCanDisintegrate=false
	DrawScale=2
	NumClusters=5
	ProjFlightTemplate=ParticleSystem'ZED_Hans_EMIT.FX_Grenade_Explosive_01'

	Begin Object Name=ExploTemplate0
		Damage=170
		DamageRadius=800
	End Object
}