class KFPawn_ZedSirenX extends KFPawn_ZedSiren;

function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling)
{
    return false;
}

defaultproperties
{
	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_SonicAttack)=class'ExtSM_Siren_Scream'
	End Object
}