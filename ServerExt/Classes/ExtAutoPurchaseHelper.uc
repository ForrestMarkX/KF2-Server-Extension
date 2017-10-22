class ExtAutoPurchaseHelper extends KFAutoPurchaseHelper within ExtPlayerController;

final function class<KFPerk> GetBasePerk()
{
	return (ActivePerkManager!=None && ActivePerkManager.CurrentPerk!=None) ? ActivePerkManager.CurrentPerk.BasePerk : None;
}
final function Ext_PerkBase GetExtPerk()
{
	return ActivePerkManager!=None ? ActivePerkManager.CurrentPerk : None;
}

function DoAutoPurchase()
{
	local int PotentialDosh, i;
	local Array <STraderItem> OnPerkWeapons;
	local STraderItem TopTierWeapon;
	local int ItemIndex;
	local bool bSecondaryWeaponPurchased;
	local bool bUpgradeSuccess;
	local bool bAutoFillPurchasedItem;
	local string AutoFillMessageString;
	local Ext_PerkBase EP;

	GetTraderItems();
	EP = GetExtPerk();

	if( EP==None || EP.AutoBuyLoadOutPath.length == 0)
		return;

	for( i = 0; i<EP.AutoBuyLoadOutPath.length; i++ )
	{
		ItemIndex = TraderItems.SaleItems.Find('WeaponDef', EP.AutoBuyLoadOutPath[i]);
		if(ItemIndex != INDEX_NONE)
			OnPerkWeapons.AddItem(TraderItems.SaleItems[ItemIndex]);
	}

	SellOffPerkWeapons();

	TopTierWeapon = GetTopTierWeapon(OnPerkWeapons);
	//can I afford my top teir without selling my current weapon?
	if(!DoIOwnThisWeapon(TopTierWeapon) && GetCanAfford( GetAdjustedBuyPriceFor(TopTierWeapon) + DoshBuffer ) && CanCarry( TopTierWeapon ) )
	{
		bUpgradeSuccess = AttemptUpgrade(TotalDosh, OnPerkWeapons, true);
	}
	else
	{
		PotentialDosh = GetPotentialDosh();
		bUpgradeSuccess = AttemptUpgrade(PotentialDosh+TotalDosh, OnPerkWeapons);
	}
	
	bAutoFillPurchasedItem = StartAutoFill();
	if(DoIOwnThisWeapon(TopTierWeapon))
	{
		while(AttemptToPurchaseNextLowerTier(TotalDosh, OnPerkWeapons))
		{
			bSecondaryWeaponPurchased = true;
			AttemptToPurchaseNextLowerTier(TotalDosh, OnPerkWeapons);
		}	
	}

	MyKFIM.ServerCloseTraderMenu();

	if(bUpgradeSuccess)
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.WeaponUpgradeComepleteString;
	}
	else if(bSecondaryWeaponPurchased)
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.SecondaryWeaponPurchasedString;
	}
	else if(bAutoFillPurchasedItem)
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.AutoFillCompleteString;
	}
	else 
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.NoItemsPurchasedString;
	}
	

	if(MyGFxHUD != none)
	{
		MyGFxHUD.ShowNonCriticalMessage( class'KFCommon_LocalizedStrings'.default.AutoTradeCompleteString$AutoFillMessageString );
	}
}

function SellOnPerkWeapons()
{
	local int i;
	local class<KFPerk> Perk;
	
	Perk = GetBasePerk();
	if( Perk!=None )
	{
		for (i = 0; i < OwnedItemList.length; i++)
		{
			if( OwnedItemList[i].DefaultItem.AssociatedPerkClasses.Find(Perk)!=INDEX_NONE && OwnedItemList[i].DefaultItem.BlocksRequired != -1)
			{
				SellWeapon(OwnedItemList[i], i);
				i=-1;
			}
		}
	}
}

function SellOffPerkWeapons()
{
	local int i;
	local Ext_PerkBase EP;
	
	EP = GetExtPerk();

	for (i = 0; i < OwnedItemList.length; i++)
	{
		if( OwnedItemList[i].DefaultItem.AssociatedPerkClasses.Find(EP.BasePerk)==INDEX_NONE && OwnedItemList[i].DefaultItem.BlocksRequired != -1 && OwnedItemList[i].SellPrice != 0 )
		{
			if(EP.AutoBuyLoadOutPath.Find(OwnedItemList[i].DefaultItem.WeaponDef) == INDEX_NONE)
			{
				SellWeapon(OwnedItemList[i], i);
				i=-1;
			}
		}
	}
}

function InitializeOwnedItemList()
{
   	local Inventory Inv;
   	local KFWeapon KFW;
	local KFPawn_Human KFP;
	local Ext_PerkBase EP;

	EP = GetExtPerk();
    OwnedItemList.length = 0;

	TraderItems = KFGameReplicationInfo( WorldInfo.GRI ).TraderItems;

	KFP = KFPawn_Human( Pawn );
    if( KFP != none )
    {
		// init armor purchase values
		ArmorItem.SpareAmmoCount = KFP.Armor;
		ArmorItem.MaxSpareAmmo = KFP.GetMaxArmor();
	   	ArmorItem.AmmoPricePerMagazine = TraderItems.ArmorPrice * ActivePerkManager.GetArmorDiscountMod();
	   	ArmorItem.DefaultItem.WeaponDef = TraderItems.ArmorDef;

		// init grenade purchase values
		GrenadeItem.SpareAmmoCount = MyKFIM.GrenadeCount;
		GrenadeItem.MaxSpareAmmo = ActivePerkManager.MaxGrenadeCount;
	   	GrenadeItem.AmmoPricePerMagazine = TraderItems.GrenadePrice;
	   	GrenadeItem.DefaultItem.WeaponDef = EP.GrenadeWeaponDef;

		// @temp: fill in stuff that is normally serialized in the archetype
		GrenadeItem.DefaultItem.AssociatedPerkClasses[0] = CurrentPerk.Class;

		for ( Inv = MyKFIM.InventoryChain; Inv != none; Inv = Inv.Inventory )
		{
			KFW = KFWeapon( Inv );
			if( KFW != none )
			{
				// Set the weapon information and add it to the OwnedItemList
				SetWeaponInformation( KFW );
	     	}
		}

		if(MyGfxManager != none && MyGfxManager.TraderMenu != none)
		{
			MyGfxManager.TraderMenu.OwnedItemList = OwnedItemList;	
		}
	}
}

function int AddItemByPriority( out SItemInformation WeaponInfo )
{
	local byte i;
	local byte WeaponGroup, WeaponPriority;
	local byte BestIndex;
	local class<KFPerk> Perk;
	
	Perk = GetBasePerk();

	BestIndex = 0;
	WeaponGroup = WeaponInfo.DefaultItem.InventoryGroup;
	WeaponPriority = WeaponInfo.DefaultItem.GroupPriority;

	for( i = 0; i < OwnedItemList.length; i++ )
	{
		// If the weapon belongs in the group prior to the current weapon, we've found the spot
		if( WeaponGroup < OwnedItemList[i].DefaultItem.InventoryGroup )
		{
			BestIndex = i;
			break;
		}
		else if( WeaponGroup == OwnedItemList[i].DefaultItem.InventoryGroup )
		{
			if( WeaponPriority > OwnedItemList[i].DefaultItem.GroupPriority )
			{
				// if the weapon is in the same group but has a higher priority, we've found the spot
				BestIndex = i;
				break;
			}
			else if( WeaponPriority == OwnedItemList[i].DefaultItem.GroupPriority && WeaponInfo.DefaultItem.AssociatedPerkClasses.Find(Perk)>=0 )
			{
				// if the weapons have the same priority give the slot to the on perk weapon
				BestIndex = i;
				break;
			}
		}
		else
		{
			// Covers the case if this weapon is the only item in the last group
			BestIndex = i + 1;
		}
	}
	OwnedItemList.InsertItem( BestIndex, WeaponInfo );

	// Add secondary ammo immediately after the main weapon
	if( WeaponInfo.DefaultItem.WeaponDef.static.UsesSecondaryAmmo() )
   	{
   		WeaponInfo.bIsSecondaryAmmo = true;
		WeaponInfo.SellPrice = 0;
		OwnedItemList.InsertItem( BestIndex + 1, WeaponInfo );
   	}

	if( MyGfxManager != none && MyGfxManager.TraderMenu != none )
	{
		MyGfxManager.TraderMenu.OwnedItemList = OwnedItemList;	
	}

   	return BestIndex;
}

function bool CanCarry( const out STraderItem Item )
{
	local int Result;
	
	Result = TotalBlocks + MyKFIM.GetDisplayedBlocksRequiredFor(Item);
	if (Result > MaxBlocks)
	{
    	return false;
	}
	return true;
}
