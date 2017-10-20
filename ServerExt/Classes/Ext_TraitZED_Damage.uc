Class Ext_TraitZED_Damage extends Ext_TraitZEDBase
	abstract;

var array<float> DamList;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_ZEDHelper H;

	foreach Player.ChildActors(class'Ext_T_ZEDHelper',H)
		H.SetDamageScale(Default.DamList[Level-1]);
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_ZEDHelper H;

	foreach Player.ChildActors(class'Ext_T_ZEDHelper',H)
		H.SetDamageScale(1);
}

defaultproperties
{
	NumLevels=5
	TraitName="Monster Damage"
	Description="This trait will scale how much damage your helper ZED will deal:|Lv1-5: +10%, +25%, +50%, +100%, +200%||-Requires Monster Tongue trait."
	DefLevelCosts(0)=10
	DefLevelCosts(1)=20
	DefLevelCosts(2)=30
	DefLevelCosts(3)=40
	DefLevelCosts(4)=60
	bPostApplyEffect=true
	
	DamList.Add(1.1)
	DamList.Add(1.25)
	DamList.Add(1.5)
	DamList.Add(2)
	DamList.Add(3)
	DamList.Add(3)
}