class VS_ZedClotBase extends VSZombie
	abstract;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	Super.PostInitAnimTree( SkelComp );

	if( bCanHeadTrack )
	{
		IK_Look_Head		= SkelControlLookAt(Mesh.FindSkelControl('HeadLook'));
		//IK_Look_Spine       = SkelControlLookAt(Mesh.FindSkelControl('SpineLook'));
	}
}

simulated function float StartAttackAnim( byte Num ) // Return animation duration.
{
	if( FPHandModel!=None )
		FPHandModel.PlayHandsAnim('Atk_Combo1_V1');
	return PlayBodyAnim('Atk_Combo1_V1',EAS_UpperBody);
}

defaultproperties
{
	MonsterArchPath="ZED_ARCH.ZED_Clot_UnDev_Archetype"
	CharacterMonsterArch=KFCharacterInfo_Monster'ZED_ARCH.ZED_Clot_UnDev_Archetype'
	DoshValue=12
	HitsPerAttack=2
	KnockedDownBySonicWaveOdds=0.230000
	Mass=50.000000
	GroundSpeed=190.000000
	RotationRate=(Pitch=50000,Yaw=30000,Roll=50000)
}