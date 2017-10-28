class ExtProj_HighExplosive_M79 extends KFProj_HighExplosive_M79;

simulated protected function PrepareExplosionTemplate()
{
    local ExtPlayerReplicationInfo MyPRI;

    Super.PrepareExplosionTemplate();

    if(Instigator == None)
    	return;

    MyPRI = ExtPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if( MyPRI != none )
    {
		if( bWasTimeDilated && MyPRI.bNukeIsOn && class'KFPerk_Demolitionist'.static.ProjectileShouldNuke( self ) )
		{
			ExplosionTemplate = class'KFPerk_Demolitionist'.static.GetNukeExplosionTemplate();
			ExplosionTemplate.Damage = default.ExplosionTemplate.Damage * class'KFPerk_Demolitionist'.static.GetNukeDamageModifier();
			ExplosionTemplate.DamageRadius = default.ExplosionTemplate.DamageRadius * class'KFPerk_Demolitionist'.static.GetNukeRadiusModifier();
			ExplosionTemplate.DamageFalloffExponent = default.ExplosionTemplate.DamageFalloffExponent; 
		} 
		else if( MyPRI.bConcussiveIsOn )
		{
			ExplosionTemplate.ExplosionEffects = AltExploEffects;
			ExplosionTemplate.ExplosionSound = class'KFPerk_Demolitionist'.static.GetConcussiveExplosionSound();
		}
    }
}

simulated protected function SetExplosionActorClass()
{
	local ExtPlayerReplicationInfo MyPRI;

    Super(KFProjectile).SetExplosionActorClass();
	
    if(Instigator == None)
    	return;
		
    MyPRI = ExtPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if( MyPRI != none )
    {
		if( bWasTimeDilated && MyPRI.bNukeIsOn && class'KFPerk_Demolitionist'.static.ProjectileShouldNuke( self ) )
			ExplosionActorClass = class'KFPerk_Demolitionist'.static.GetNukeExplosionActorClass();
    }
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local vector NudgedHitLocation, ExplosionDirection;
    local Pawn P;
	local ExtPlayerReplicationInfo MyPRI;

	if( bHasDisintegrated )
	{
		return;
	}
	if (!bHasExploded)
	{
        // On local player or server, we cache off our time dilation setting here
        if( WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || InstigatorController != None )
        {
            bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
        }

        // Stop ambient sounds when this projectile explodes
    	if( bStopAmbientSoundOnExplode )
    	{
            StopAmbientSound();
    	}

		if (ExplosionTemplate != None)
		{
			StopSimulating();

			// using a hit location slightly away from the impact point is nice for certain things
			NudgedHitLocation = HitLocation + (HitNormal * 32.f);

            SetExplosionActorClass();      
            if( ExplosionActorClass == class'KFPerk_Demolitionist'.static.GetNukeExplosionActorClass() )
            {
                P = Pawn(HitActor);
                if( P != none )
                {
                    NudgedHitLocation = P.Location - vect(0,0,1) * P.GetCollisionHeight();
                }
            }

            ExplosionActor = Spawn(ExplosionActorClass, self,, NudgedHitLocation, rotator(HitNormal));
			if (ExplosionActor != None)
			{
				ExplosionActor.Instigator = Instigator;
				ExplosionActor.InstigatorController = InstigatorController;

				PrepareExplosionTemplate();

            	// If the locations are zero (probably because this exploded in the air) set defaults
                if( IsZero(HitLocation) )
                {
                    HitLocation = Location;
                }

            	if( IsZero(HitNormal) )
                {
                    HitNormal = vect(0,0,1);
                }

				// these are needed for the decal tracing later in GameExplosionActor.Explode()
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
				
				MyPRI = ExtPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
				if( MyPRI != none && KFExplosionActorLingering(ExplosionActor) != None )
				{
					KFExplosionActorLingering(ExplosionActor).MaxTime *= MyPRI.NukeTimeMult;
					KFExplosionActorLingering(ExplosionActor).LifeSpan *= MyPRI.NukeTimeMult;
				}

				ExplosionActor.Explode(ExplosionTemplate, ExplosionDirection);		// go bewm
			}

			// done with it
			if (!bPendingDelete && !bDeleteMe)
			{
				// defer destruction so any replication of explosion stuff can happen if necessary
				DeferredDestroy(PostExplosionLifetime);
			}
		}

		bHasExploded = true;
	}
}

defaultproperties
{
}