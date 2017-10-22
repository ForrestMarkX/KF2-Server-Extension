Class Ext_PerkSupport extends Ext_PerkBase;

var bool bUseAPShot,bUsePerforate,bCanRepairDoors;
var float APShotMul;

replication
{
	// Things the server should send to the client.
	if ( true )
		bCanRepairDoors, bUseAPShot, bUsePerforate, APShotMul;
}

simulated function bool GetUsingTactialReload( KFWeapon KFW )
{
	return (IsWeaponOnPerk(KFW) ? Modifiers[5]<0.75 : false);
}

simulated function bool CanRepairDoors()
{
	return bCanRepairDoors;
}

simulated function float GetPenetrationModifier( byte Level, class<KFDamageType> DamageType, optional bool bForce  )
{
    local float PenetrationPower;
    if( !bForce && (DamageType == none || ( DamageType!=None && DamageType.Default.ModifierPerkList.Find(BasePerk) == INDEX_NONE )))
        return 0;

    PenetrationPower = bUseAPShot ? APShotMul : 0.f;
    PenetrationPower = IsPerforateActive() ? 40.f : PenetrationPower;

    return PenetrationPower;
}

simulated function bool IsPerforateActive()
{
	return bUsePerforate && WorldInfo.TimeDilation < 1.f;
}

defaultproperties
{
	PerkName="Support"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Support'
	DefTraitList.Add(class'Ext_TraitGrenadeSUpg')
	DefTraitList.Add(class'Ext_TraitWPSupp')
	DefTraitList.Add(class'Ext_TraitSupply')
	DefTraitList.Add(class'Ext_TraitAPShots')
	DefTraitList.Add(class'Ext_TraitDoorRepair')
	DefTraitList.Add(class'Ext_TraitPenetrator')
	BasePerk=class'KFPerk_Support'
	WeldExpUpNum=80

	DefPerkStats(0)=(MaxValue=20,CostPerValue=2)
	DefPerkStats(8)=(bHiddenConfig=false)

	PrimaryMelee=class'KFWeap_Knife_Support'
	PrimaryWeapon=class'KFWeap_Shotgun_MB500'
	
	PrimaryWeaponDef=class'KFWeapDef_MB500'
	KnifeWeaponDef=class'KFWeapDef_Knife_Support'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Support'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_MB500', class'KFWeapDef_DoubleBarrel', class'KFWeapDef_M4', class'KFWeapDef_AA12')
}