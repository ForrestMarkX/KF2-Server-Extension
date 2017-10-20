class KFPawn_ZedSirenX extends KFPawn_ZedSiren;

function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
{
    return false;
}

defaultproperties
{
	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_SonicAttack)=class'ExtSM_Siren_Scream'
	End Object
}