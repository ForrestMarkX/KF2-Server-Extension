// Written by Marco.
class ExtProj_SUPERMolotov extends KFProj_MolotovGrenade;

defaultproperties
{
	Speed=2500
	TerminalVelocity=3500
	TossZ=450

	bCanDisintegrate=false
	DrawScale=2.5
	
	NumResidualFlames=10
	ResidualFlameProjClass=class'ExtProj_SUPERMolotovS'
	
	// explosion
	Begin Object Name=ExploTemplate0
		Damage=750
		DamageRadius=500
	End Object
}