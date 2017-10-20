Class Ext_PerkFieldMedic extends Ext_PerkBase;

var float RepairArmorRate,AirborneAgentHealRate;
var byte AirborneAgentLevel;

function bool RepairArmor( Pawn HealTarget )
{
	local KFPawn_Human KFPH;

	if( RepairArmorRate>0 )
	{
		KFPH = KFPawn_Human(Healtarget);
		if( KFPH != none && KFPH.Armor < KFPH.MaxArmor )
		{
			KFPH.AddArmor( Round( float(KFPH.MaxArmor) * RepairArmorRate ) );
			return true;
		}
	}
	return false;
}
function bool ModifyHealAmount( out float HealAmount )
{
	HealAmount*=Modifiers[9];
	return (RepairArmorRate>0);
}
simulated function ModifyHealerRechargeTime( out float RechargeRate )
{
	RechargeRate/=Modifiers[9];
}

function CheckForAirborneAgent( KFPawn HealTarget, class<DamageType> DamType, int HealAmount )
{
	if( (AirborneAgentLevel==1 && WorldInfo.TimeDilation<1.f) || AirborneAgentLevel>1 )
		GiveMedicAirborneAgentHealth( HealTarget, DamType, HealAmount );
}

function GiveMedicAirborneAgentHealth( KFPawn HealTarget, class<DamageType> DamType, int HealAmount )
{
	local KFPawn KFP;
	local int RoundedExtraHealAmount;

	RoundedExtraHealAmount = FCeil( float(HealAmount) * AirborneAgentHealRate );

	foreach WorldInfo.Allpawns(class'KFPawn', KFP, HealTarget.Location, 500.f)
	{
		if( KFP.IsAliveAndWell() && WorldInfo.GRI.OnSameTeam( HealTarget, KFP ) )
		{					
			if ( HealTarget == KFP )
				KFP.HealDamage( RoundedExtraHealAmount, PlayerOwner, DamType );	
			else KFP.HealDamage( RoundedExtraHealAmount + HealAmount, PlayerOwner, DamType );
		}
	}
}

defaultproperties
{
	PerkName="Field Medic"
	PerkIcon=Texture2D'UI_PerkIcons_TEX.UI_PerkIcon_Medic'
	DefTraitList.Remove(class'Ext_TraitMedicPistol')
	DefTraitList.Add(class'Ext_TraitAirborne')
	DefTraitList.Add(class'Ext_TraitWPMedic')
	DefTraitList.Add(class'Ext_TraitArmorRep')
	DefTraitList.Add(class'Ext_TraitToxicDart')
	BasePerk=class'KFPerk_FieldMedic'
	HealExpUpNum=3
	
	DefPerkStats(0)=(MaxValue=70)
	DefPerkStats(9)=(bHiddenConfig=false) // Heal efficiency
	DefPerkStats(15)=(bHiddenConfig=false) // Toxic resistance
	DefPerkStats(16)=(bHiddenConfig=false) // Sonic resistance
	DefPerkStats(17)=(bHiddenConfig=false) // Fire resistance
	
	PrimaryMelee=class'KFWeap_Knife_FieldMedic'
	PrimaryWeapon=class'KFWeap_Pistol_Medic'
	PerkGrenade=class'KFProj_MedicGrenade'
	SuperGrenade=class'ExtProj_SUPERMedGrenade'
	
	PrimaryWeaponDef=class'KFWeapDef_MedicPistol'
	KnifeWeaponDef=class'KFWeapDef_Knife_Medic'
	GrenadeWeaponDef=class'KFWeapDef_Grenade_Medic'
	
	AutoBuyLoadOutPath=(class'KFWeapDef_MedicPistol', class'KFWeapDef_MedicSMG', class'KFWeapDef_MedicShotgun', class'KFWeapDef_MedicRifle')
}