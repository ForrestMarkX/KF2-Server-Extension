Class Ext_PerkRhythmPerkBase extends Ext_PerkBase;

var byte HeadShotComboCount,MaxRhythmCombo,MissComboCount;
var float RhythmComboDmg;

simulated function ModifyDamageGiven( out int InDamage, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx )
{
	Super.ModifyDamageGiven(InDamage,DamageCauser,MyKFPM,DamageInstigator,DamageType,HitZoneIdx);
	if( RhythmComboDmg>0 && BasePerk==None || (DamageType!=None && DamageType.Default.ModifierPerkList.Find(BasePerk)>=0) || IsWeaponOnPerk(KFWeapon(DamageCauser)) )
		InDamage *= (1.f+RhythmComboDmg);
}

final function SetMaxRhythm( byte MaxCombo )
{
	MaxRhythmCombo = MaxCombo;
}
final function ResetRhythm()
{
	MaxRhythmCombo = 0;
	HeadShotComboCount = 0;
	RhythmComboDmg = 0;
	MissComboCount = 0;
	HeadShotMessage(0,true,1);
}

final function UpdateDmgScale( bool bUp )
{
	if( bUp )
	{
		MissComboCount = 0;
		HeadShotComboCount = Min(HeadShotComboCount+1,255);
		HeadShotMessage(HeadShotComboCount,false,MaxRhythmCombo);
	}
	else if( HeadShotComboCount>0 && ++MissComboCount==3 )
	{
		--HeadShotComboCount;
		HeadShotMessage(HeadShotComboCount,true,MaxRhythmCombo);
		MissComboCount = 0;
	}
	else return;
	RhythmComboDmg = FMin(HeadShotComboCount,MaxRhythmCombo)*0.075;
}
function UpdatePerkHeadShots( ImpactInfo Impact, class<DamageType> DamageType, int NumHit )
{
   	local int HitZoneIdx;
   	local KFPawn_Monster KFPM;
 	
	if( MaxRhythmCombo<=0 )
		return;
   	KFPM = KFPawn_Monster(Impact.HitActor);
   	if( KFPM==none || KFPM.GetTeamNum()==0 )
   	{
   		if( NumHit < 1 && HeadShotComboCount>0 )
			UpdateDmgScale(false);
   		return;
   	}

   	HitZoneIdx = KFPM.HitZones.Find('ZoneName', Impact.HitInfo.BoneName);
   	if( HitZoneIdx == HZI_Head && KFPM.IsAliveAndWell() )
	{
		if( class<KFDamageType>(DamageType)!=None && class<KFDamageType>(DamageType).Default.ModifierPerkList.Find(BasePerk)>=0 )
			UpdateDmgScale(true);
		else if( HeadShotComboCount>0 )
			UpdateDmgScale(false);
	}
	else if( NumHit < 1 && HeadShotComboCount>0 )
		UpdateDmgScale(false);
}
reliable client function HeadShotMessage( byte HeadShotNum, bool bMissed, byte MaxHits )
{
	local AkEvent TempAkEvent;
	local KFPlayerController PC;

	PC = KFPlayerController(PlayerOwner);
	if( PC==none || PC.MyGFxHUD==none )
	{
		return;
	}

	PC.MyGFxHUD.RhythmCounterWidget.SetInt("count", HeadShotNum);
	PC.MyGFxHUD.RhythmCounterWidget.SetBonusPercentage(float(HeadShotNum) / float(MaxHits));

	if( HeadshotNum==0 )
		TempAkEvent = AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Reset';
	else if( HeadShotNum<MaxHits )
	{
		if( !bMissed )
		{				
			//PC.ClientSpawnCameraLensEffect(class'KFCameraLensEmit_RackemHeadShot');
			TempAkEvent = AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Hit';
		}
	}
	else if( !bMissed )
	{
		//PC.ClientSpawnCameraLensEffect(class'KFCameraLensEmit_RackemHeadShotPing');
		TempAkEvent = AkEvent'WW_UI_PlayerCharacter.Play_R_Method_Top';
		HeadshotNum = 6;
	}

	if( TempAkEvent != none )
		PC.PlayRMEffect( TempAkEvent, 'R_Method', HeadshotNum );
}

defaultproperties
{
}