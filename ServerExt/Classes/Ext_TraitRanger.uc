Class Ext_TraitRanger extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSharpshooter(Perk).ZEDTimeStunPower = 4.f;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_PerkSharpshooter(Perk).ZEDTimeStunPower = 0.f;
}

defaultproperties
{
	SupportedPerk=class'Ext_PerkSharpshooter'
	TraitGroup=class'Ext_TGroupZEDTime'
	TraitName="ZED TIME - Ranger"
	DefLevelCosts(0)=40
	Description="This will make you effectively stun enemies with headshots during ZED-time."
}