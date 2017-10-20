class ExtTraderContainer_Store extends KFGFxTraderContainer_Store;

function RefreshWeaponListByPerk(byte FilterIndex, const out array<STraderItem> ItemList)
{
	local int i, SlotIndex;
	local GFxObject ItemDataArray; // This array of information is sent to ActionScript to update the Item data
	local array<STraderItem> OnPerkWeapons, SecondaryWeapons, OffPerkWeapons;
	local class<KFPerk> TargetPerkClass;
	local ExtPlayerController EKFPC;

	EKFPC = ExtPlayerController(KFPC);
	if ( EKFPC!=none && EKFPC.ActivePerkManager!=None)
	{
		if( FilterIndex<EKFPC.ActivePerkManager.UserPerks.Length )
			TargetPerkClass = EKFPC.ActivePerkManager.UserPerks[FilterIndex].BasePerk;

		SlotIndex = 0;
	    ItemDataArray = CreateArray();

		for (i = 0; i < ItemList.Length; i++)
		{
			if ( IsItemFiltered(ItemList[i]) )
			{
				continue; // Skip this item if it's in our inventory
			}
			else if ( ItemList[i].AssociatedPerkClasses.length > 0 && ItemList[i].AssociatedPerkClasses[0] != none && TargetPerkClass != class'KFPerk_Survivalist'
				&& (TargetPerkClass==None || ItemList[i].AssociatedPerkClasses.Find(TargetPerkClass) == INDEX_NONE ) )
			{
				continue; // filtered by perk
			}
			else
			{
				if(ItemList[i].AssociatedPerkClasses.length > 0)
				{
					switch (ItemList[i].AssociatedPerkClasses.Find(TargetPerkClass))
					{
						case 0: //primary perk
							OnPerkWeapons.AddItem(ItemList[i]);
							break;
					
						case 1: //secondary perk
							SecondaryWeapons.AddItem(ItemList[i]);
							break;
					
						default: //off perk
							OffPerkWeapons.AddItem(ItemList[i]);
							break;
					}
				}
			}
		}

		for (i = 0; i < OnPerkWeapons.length; i++)
		{
			SetItemInfo(ItemDataArray, OnPerkWeapons[i], SlotIndex);
			SlotIndex++;	
		}

		for (i = 0; i < SecondaryWeapons.length; i++)
		{
			SetItemInfo(ItemDataArray, SecondaryWeapons[i], SlotIndex);
			SlotIndex++;
		}

		for (i = 0; i < OffPerkWeapons.length; i++)
		{
			SetItemInfo(ItemDataArray, OffPerkWeapons[i], SlotIndex);
			SlotIndex++;
		}		

		SetObject("shopData", ItemDataArray);
	}
}
