class ExtWeapDef_Grenade_Demo extends KFWeapDef_Grenade_Demo;

static function string GetItemLocalization(string KeyName)
{
	return class'KFWeapDef_Grenade_Demo'.Static.GetItemLocalization(KeyName);
}

DefaultProperties
{
	WeaponClassPath="ServerExt.ExtProj_DynamiteGrenade"
}
