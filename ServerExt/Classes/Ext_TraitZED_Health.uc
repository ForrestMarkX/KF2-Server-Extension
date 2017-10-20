Class Ext_TraitZED_Health extends Ext_TraitZEDBase
	abstract;

var array<float> HPList;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_ZEDHelper H;

	foreach Player.ChildActors(class'Ext_T_ZEDHelper',H)
		H.SetHealthScale(Default.HPList[Level-1]);
}
static function CancelEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Ext_T_ZEDHelper H;

	foreach Player.ChildActors(class'Ext_T_ZEDHelper',H)
		H.SetHealthScale(1);
}

defaultproperties
{
	NumLevels=5
	bPostApplyEffect=true
	TraitName="Monster Health"
	Description="This trait will scale how much health your helper ZED will have:|Lv1-5: +25%, +50%, +75%, +100%, +200%||-Requires Monster Tongue trait."
	DefLevelCosts(0)=5
	DefLevelCosts(1)=15
	DefLevelCosts(2)=25
	DefLevelCosts(3)=40
	DefLevelCosts(4)=60
	
	HPList.Add(1.25)
	HPList.Add(1.5)
	HPList.Add(1.75)
	HPList.Add(2)
	HPList.Add(3)
}