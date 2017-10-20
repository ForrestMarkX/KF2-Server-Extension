Class Ext_PerkSharpshooter extends Ext_PerkRhythmPerkBase;

var bool bHasDireReload;
var float ZEDTimeStunPower,DireReloadSpeed;

replication
{
	// Things the server should send to the client.
	if ( true )
		bHasDireReload;
}

simulated function float GetReloadRateScale(KFWeapon KFW)
{
	if( bHasDireReload && PlayerOwner.Pawn!=None && PlayerOwner.Pawn.Health<40 )
		return Super.GetReloadRateScale(KFW)*DireReloadSpeed;
	return Super.GetReloadRateScale(KFW);
}
function float GetStunPowerModifier( optional class<DamageType> DamageType, optional byte HitZoneIdx )
{
	if( ZEDTimeStunPower>0 && HitZoneIdx==HZI_Head && WorldInfo.TimeDilation<1.f && (class<KFDamageType>(DamageType)!=None && class<KFDamageType>(DamageType).Default.ModifierPerkList.Find(BasePerk)>=0) )
		return Super.GetStunPowerModifier(DamageType,HitZoneIdx) + ZEDTimeStunPower;
	return Super.GetStunPowerModifier(DamageType,HitZoneIdx);
}

defaultproperties
{
	PerkName="Sharpshooter"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Sharpshooter'
	DefTraitList.Add(class'Ext_TraitWPSharp')
	DefTraitList.Add(class'Ext_TraitRackEmUp')
	DefTraitList.Add(class'Ext_TraitRanger')
	DefTraitList.Add(class'Ext_TraitDireReload')
	DefTraitList.Add(class'Ext_TraitEliteReload')
	BasePerk=class'KFPerk_Sharpshooter'

	PrimaryMelee=class'KFWeap_Knife_Sharpshooter'
	PrimaryWeapon=class'KFWeap_Rifle_Winchester1894'
	PerkGrenade=class'KFProj_FreezeGrenade'
	
	PrimaryWeaponDef=class'KFWeapDef_Winchester1894'
	KnifeWeaponDef=class'KFWeapDef_Knife_Sharpshooter'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Sharpshooter'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_Winchester1894', class'KFWeapDef_Crossbow', class'KFWeapDef_M14EBR', class'KFWeapDef_RailGun')
	
	DireReloadSpeed=0.25f
}