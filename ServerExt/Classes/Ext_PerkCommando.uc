Class Ext_PerkCommando extends Ext_PerkBase;

var bool bUseProfessional,bUseMachineGunner;
var float ZTExtCount;

replication
{
	// Things the server should send to the client.
	if ( true )
		bUseProfessional,bUseMachineGunner;
}

simulated function bool GetUsingTactialReload( KFWeapon KFW )
{
	return (IsWeaponOnPerk(KFW) ? Modifiers[5]<0.65 : false);
}

simulated function ModifyDamageGiven( out int InDamage, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx )
{
	if( (DamageType!=None && DamageType.Default.ModifierPerkList.Find(BasePerk)>=0) || (KFWeapon(DamageCauser)!=None && IsWeaponOnPerk(KFWeapon(DamageCauser))) )
	{
		if( bUseMachineGunner && WorldInfo.TimeDilation < 1.f )
			InDamage += InDamage * 0.03;
	}
		
	Super.ModifyDamageGiven(InDamage, DamageCauser, MyKFPM, DamageInstigator, DamageType, HitZoneIdx);
}

simulated function float GetZedTimeModifier( KFWeapon W )
{
	local name StateName;
	StateName = W.GetStateName();

	if( bUseProfessional && IsWeaponOnPerk( W ) )
	{
		if( StateName == 'Reloading' || StateName == 'AltReloading' )
			return 1.f;
		else if( StateName == 'WeaponPuttingDown' || StateName == 'WeaponEquipping' )
			return 0.3f;
	}

	if( bUseMachineGunner && IsWeaponOnPerk( W ) && BasePerk.Default.ZedTimeModifyingStates.Find( StateName ) != INDEX_NONE )
		return 0.5f;

	return 0.f;
}

simulated function float GetZedTimeExtensions( byte Level )
{
	return ZTExtCount;
}

defaultproperties
{
	PerkName="Commando"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Commando'
	DefTraitList.Add(class'Ext_TraitWPComm')
	DefTraitList.Add(class'Ext_TraitUnCloak')
	DefTraitList.Add(class'Ext_TraitZedTExt')
	DefTraitList.Add(class'Ext_TraitEnemyHP')
	DefTraitList.Add(class'Ext_TraitEliteReload')
	DefTraitList.Add(class'Ext_TraitTactician')
	DefTraitList.Add(class'Ext_TraitMachineGunner')
	BasePerk=class'KFPerk_Commando'
	
	ZTExtCount=1.f;

	PrimaryMelee=class'KFWeap_Knife_Commando'
	PrimaryWeapon=class'KFWeap_AssaultRifle_AR15'
	PerkGrenade=class'KFProj_HEGrenade'

	PrimaryWeaponDef=class'KFWeapDef_AR15'
	KnifeWeaponDef=class'KFweapDef_Knife_Commando'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Commando'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_AR15', class'KFWeapDef_Bullpup', class'KFWeapDef_AK12', class'KFWeapDef_SCAR')
}