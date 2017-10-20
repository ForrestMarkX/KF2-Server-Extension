class ExtMenu_Inventory extends KFGFxMenu_Inventory;

function bool IsItemActive(int ItemDefinition)
{
	local class<KFWeaponDefinition> WeaponDef;
	local int ItemIndex;

	ItemIndex = class'ExtWeaponSkinList'.default.Skins.Find('Id', ItemDefinition);

	if(ItemIndex == INDEX_NONE)
	{
		return false;
	}

	WeaponDef = class'ExtWeaponSkinList'.default.Skins[ItemIndex].WeaponDef;

	if(WeaponDef != none)
	{
		return class'ExtWeaponSkinList'.Static.IsSkinEquip(WeaponDef, ItemDefinition, ExtPlayerController(KFPC));
	}

	return false;
}

function Callback_Equip( int ItemDefinition )
{
	local class<KFWeaponDefinition> WeaponDef;
	local int ItemIndex;

	ItemIndex = class'ExtWeaponSkinList'.default.Skins.Find('Id', ItemDefinition);

	if(ItemIndex == INDEX_NONE)
	{
		return;
	}

	WeaponDef = class'ExtWeaponSkinList'.default.Skins[ItemIndex].WeaponDef;

	if(WeaponDef != none)
	{
		if(IsItemActive(ItemDefinition))
		{
			class'ExtWeaponSkinList'.Static.SaveWeaponSkin(WeaponDef, 0, ExtPlayerController(KFPC));

			if(class'WorldInfo'.static.IsConsoleBuild( ))
			{
				Manager.CachedProfile.ClearWeaponSkin(WeaponDef.default.WeaponClassPath);
			}
		}
		else
		{
			class'ExtWeaponSkinList'.Static.SaveWeaponSkin(WeaponDef, ItemDefinition, ExtPlayerController(KFPC));
			if(class'WorldInfo'.static.IsConsoleBuild( ))
			{
				Manager.CachedProfile.SaveWeaponSkin(WeaponDef.default.WeaponClassPath, ItemDefinition);
			}
		}
	}

	InitInventory();
}

defaultproperties
{
}