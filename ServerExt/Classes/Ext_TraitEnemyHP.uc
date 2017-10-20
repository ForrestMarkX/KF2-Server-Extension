Class Ext_TraitEnemyHP extends Ext_TraitBase;

static function TraitActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.EnemyHealthRange = Level;
}
static function TraitDeActivate( Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Perk.EnemyHealthRange = 0;
}

defaultproperties
{
	TraitName="Enemy Health Bar"
	NumLevels=4
	DefLevelCosts(0)=25
	DefLevelCosts(1)=15
	DefLevelCosts(2)=20
	DefLevelCosts(3)=30
	Description="This trait lets you see enemy health bars. The distance is increased by every level in:|Lv1-4: 5m, 7m, 10m, 16m"
}