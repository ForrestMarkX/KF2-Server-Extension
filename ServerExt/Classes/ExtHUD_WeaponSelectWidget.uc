class ExtHUD_WeaponSelectWidget extends KFGFxHUD_WeaponSelectWidget;

var transient array< class<KFWeaponDefinition> > WeaponGroup;

simulated function UpdateWeaponGroupOnHUD( byte GroupIndex )
{
    local Inventory Inv;
    local KFWeapon KFW;
    local byte i;
    local int Index;
    local array<KFWeapon> WeaponsList;
    local KFGFxObject_TraderItems TraderItems;
    local Pawn P;
    local array< class<KFWeaponDefinition> > WPGroup;

    P = GetPC().Pawn;
    if ( P == none || P.InvManager == none )
        return;

    for ( Inv = P.InvManager.InventoryChain; Inv != none; Inv = Inv.Inventory )
    {
        KFW = KFWeapon( Inv );
        if ( KFW != none && KFW.InventoryGroup == GroupIndex )
            WeaponsList.AddItem(KFW);
    }

    WPGroup.Length = WeaponsList.Length;
    TraderItems = KFGameReplicationInfo( P.WorldInfo.GRI ).TraderItems;
    for ( i = 0; i < WeaponsList.Length; i++ )
    {
        Index = TraderItems.SaleItems.Find('ClassName', WeaponsList[i].Class.Name);
        if( Index != -1 )
            WPGroup[i] = TraderItems.SaleItems[Index].WeaponDef;
    }

    WeaponGroup = WPGroup;
    SetWeaponGroupList(WeaponsList, GroupIndex);
}

simulated function SetWeaponGroupList(out array<KFWeapon> WeaponList, byte GroupIndex)
{
    local byte i;
    local GFxObject DataProvider;
    local GFxObject TempObj;
    local bool bUsesAmmo;

    DataProvider = CreateArray();
    if ( DataProvider == None )
        return; // gfx has been shut down

    for (i = 0; i < WeaponList.length; i++)
    {
        TempObj = CreateObject( "Object" );

        if( WeaponGroup[i] != None )
        {
            TempObj.SetString( "weaponName", WeaponGroup[i].static.GetItemLocalization("ItemName") );
            TempObj.SetString( "texturePath", "img://"$WeaponGroup[i].static.GetImagePath() );
        }
        else 
        {
            TempObj.SetString( "weaponName", WeaponList[i].ItemName );
            TempObj.SetString( "texturePath",  "img://"$PathName(WeaponList[i].WeaponSelectTexture));
        }

        TempObj.SetInt( "ammoCount", WeaponList[i].AmmoCount[0]);
        TempObj.SetInt( "spareAmmoCount", WeaponList[i].SpareAmmoCount[0]);
        //secondary ammo shenanigans
        TempObj.SetBool("bUsesSecondaryAmmo", WeaponList[i].UsesSecondaryAmmo()&&WeaponList[i].bCanRefillSecondaryAmmo);
        TempObj.SetBool("bEnabled", WeaponList[i].HasAnyAmmo());
        if(WeaponList[i].UsesSecondaryAmmo() && WeaponList[i].bCanRefillSecondaryAmmo)
        {
            TempObj.SetBool("bCanRefillSecondaryAmmo", WeaponList[i].SpareAmmoCapacity[1] > 0);
            TempObj.SetInt( "secondaryAmmoCount", WeaponList[i].AmmoCount[1]);
            TempObj.SetInt( "secondarySpareAmmoCount", WeaponList[i].SpareAmmoCount[1]);
        }

        TempObj.SetBool( "throwable", WeaponList[i].CanThrow());

        bUsesAmmo = (WeaponList[i].static.UsesAmmo());
        TempObj.SetBool( "bUsesAmmo", bUsesAmmo);
        DataProvider.SetElementObject( i, TempObj );
    }

    SetWeaponList(DataProvider, GroupIndex);
}

DefaultProperties
{
}