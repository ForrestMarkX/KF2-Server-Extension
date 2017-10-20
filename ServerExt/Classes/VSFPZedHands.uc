Class VSFPZedHands extends Actor
	transient;

var SkeletalMeshComponent Mesh;
var AnimNodeSlot HandsAnimNode,BodyNode;
var name IdleAnimName;

simulated function InitHands( SkeletalMeshComponent C )
{
	Mesh.SetSkeletalMesh(C.SkeletalMesh);
	Mesh.AnimSets = C.AnimSets;
	HandsAnimNode = AnimNodeSlot(Mesh.FindAnimNode('ArmsSlot'));
	BodyNode = AnimNodeSlot(Mesh.FindAnimNode('BodySlot'));
}
simulated final function SetIdleAnim( name N )
{
	IdleAnimName = N;
	Timer();
}
simulated function Timer()
{
	HandsAnimNode.PlayCustomAnim(IdleAnimName,1.f,0.15,,true);
}
simulated final function PlayHandsAnim( name N, optional float Rate=1.f )
{
	SetTimer(HandsAnimNode.PlayCustomAnim(N,Rate,0.05,,,true),false);
}

defaultproperties
{
	Begin Object Class=AnimTree Name=FPZEDAnimTree
		Begin Object Class=SkelControlSingleBone Name=ArmStretcher
			bApplyTranslation=True
			bAddTranslation=True
			BoneTranslation=(X=50.000000,Y=0.000000,Z=0.000000)
			BoneTranslationSpace=BCS_ActorSpace
		End Object
		Begin Object Class=AnimNodeSlot Name=ArmSlotter
			TickArrayIndex=2
			NodeName="ArmsSlot"
		End Object
		Begin Object Class=AnimNodeBlendPerBone Name=AnimBoneBlender
			BranchStartBoneName(0)="RightArm"
			BranchStartBoneName(1)="LeftArm"
			Child2Weight=1.000000
			Child2WeightTarget=1.000000
			Children(1)=(Anim=AnimNodeSlot'ArmSlotter')
			TickArrayIndex=1
			NodeTotalWeight=1.000000
		End Object
		SkelControlLists(0)=(BoneName="RightArm",ControlHead=SkelControlSingleBone'ArmStretcher')
		SkelControlLists(1)=(BoneName="LeftArm",ControlHead=SkelControlSingleBone'ArmStretcher')
		AnimTickArray(0)=AnimTree'FPZEDAnimTree'
		AnimTickArray(1)=AnimNodeBlendPerBone'AnimBoneBlender'
		AnimTickArray(2)=AnimNodeSlot'ArmSlotter'
		Children(0)=(Anim=AnimNodeBlendPerBone'AnimBoneBlender')
	End Object

	Begin Object Class=SkeletalMeshComponent Name=FPHandSkeletalMesh
		MinDistFactorForKinematicUpdate=0.200000
		bSkipAllUpdateWhenPhysicsAsleep=True
		bIgnoreControllersWhenNotRendered=True
		bHasPhysicsAssetInstance=True
		bUpdateKinematicBonesFromAnimation=False
		bPerBoneMotionBlur=True
		bOverrideAttachmentOwnerVisibility=True
		bChartDistanceFactor=True
		RBChannel=RBCC_Pawn
		RBDominanceGroup=20
		bAcceptsDynamicDecals=True
		bUseOnePassLightingOnTranslucency=True
		CollideActors=false
		BlockZeroExtent=false
		BlockRigidBody=false
		Translation=(X=0.000000,Y=0.000000,Z=-86.000000)
		ScriptRigidBodyCollisionThreshold=200.000000
		PerObjectShadowCullDistance=4000.000000
		bAllowPerObjectShadows=True
		bAllowPerObjectShadowBatching=True
		AnimTreeTemplate=AnimTree'FPZEDAnimTree'
		CastShadow=false
		bCastDynamicShadow=false
		bCastStaticShadow=false
	End Object
	Mesh=FPHandSkeletalMesh
	Components.Add(FPHandSkeletalMesh)
}