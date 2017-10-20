Class Ext_TraitSupplyGren extends Ext_TraitSupply;

static function ApplyEffectOn( KFPawn_Human Player, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	Ext_TraitSupplyData(Data).SpawnSupplier(Player,true);
}

defaultproperties
{
	TraitName="Grenade Supply"
	Description="With this trait you can supply grenades for your team mates. For each use you will receive a little bit of XP points."
	
	SupplyIcon=Texture2D'UI_World_TEX.Demolitionist_Supplier_HUD'
}