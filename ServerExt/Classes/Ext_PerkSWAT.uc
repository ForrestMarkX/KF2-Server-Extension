Class Ext_PerkSWAT extends Ext_PerkBase;

var byte RepTacticalMove;
var float MoveSpeedMods[3];
var bool bRapidAssault;

replication
{
	// Things the server should send to the client.
	if ( true )
		RepTacticalMove, bRapidAssault;
}

simulated function float GetIronSightSpeedModifier( KFWeapon KFW )
{
	return ((RepTacticalMove>0 && IsWeaponOnPerk(KFW)) ? MoveSpeedMods[RepTacticalMove-1] : 1.f);
}

simulated function bool GetIsUberAmmoActive( KFWeapon KFW )
{
	return bRapidAssault && IsWeaponOnPerk(KFW) && WorldInfo.TimeDilation < 1.f;
}

simulated function float GetZedTimeModifier( KFWeapon W )
{
	if( bRapidAssault && WorldInfo.TimeDilation<1.f && IsWeaponOnPerk(W) && BasePerk.Default.ZedTimeModifyingStates.Find(W.GetStateName()) != INDEX_NONE )
		return 0.51f;
	return 0.f;
}

defaultproperties
{
	PerkName="SWAT"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_SWAT'
	DefTraitList.Add(class'Ext_TraitWPSWAT')
	DefTraitList.Add(class'Ext_TraitHeavyArmor')
	DefTraitList.Add(class'Ext_TraitTacticalMove')
	DefTraitList.Add(class'Ext_TraitSWATEnforcer')
	DefTraitList.Add(class'Ext_TraitRapidAssault')
	BasePerk=class'KFPerk_SWAT'

	PrimaryMelee=class'KFWeap_Knife_SWAT'
	PrimaryWeapon=class'KFWeap_SMG_MP7'
	PerkGrenade=class'KFProj_FlashBangGrenade'

	PrimaryWeaponDef=class'KFWeapDef_MP7'
	KnifeWeaponDef=class'KFweapDef_Knife_SWAT'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_SWAT'

	AutoBuyLoadOutPath=(class'KFWeapDef_MP7', class'KFWeapDef_MP5RAS', class'KFWeapDef_P90', class'KFWeapDef_Kriss')

	MoveSpeedMods(0)=1.3
	MoveSpeedMods(1)=1.5
	MoveSpeedMods(2)=2
}