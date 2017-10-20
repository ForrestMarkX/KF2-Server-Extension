Class Ext_TraitSupplyData extends Ext_TraitDataStore;

var Ext_T_SupplierInteract SupplyInteraction;

final function SpawnSupplier( KFPawn_Human H, optional bool bGrenades )
{
	if( SupplyInteraction!=None )
		SupplyInteraction.Destroy();

	SupplyInteraction = Spawn( class'Ext_T_SupplierInteract', H,, H.Location, H.Rotation,, true );
	SupplyInteraction.SetBase( H );
	SupplyInteraction.PlayerOwner = H;
	SupplyInteraction.PerkOwner = Perk;
	SupplyInteraction.bGrenades = bGrenades;
	
	if( PlayerOwner!=None && ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo)!=None )
		ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).HasSupplier = class<Ext_TraitSupply>(TraitClass);
}
final function RemoveSupplier()
{
	if( SupplyInteraction!=None )
		SupplyInteraction.Destroy();
	
	if( PlayerOwner!=None && ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo)!=None )
		ExtPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).HasSupplier = None;
}
function Destroyed()
{
	RemoveSupplier();
}
