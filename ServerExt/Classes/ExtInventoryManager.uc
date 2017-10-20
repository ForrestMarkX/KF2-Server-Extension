class ExtInventoryManager extends KFInventoryManager;

// Dosh spamming barrier.
var transient float MoneyTossTime;
var transient byte MoneyTossCount;

reliable server function ServerThrowMoney()
{
	if( MoneyTossTime>WorldInfo.TimeSeconds )
	{
		if( MoneyTossCount>=10 )
			return;
		++MoneyTossCount;
		MoneyTossTime = FMax(MoneyTossTime,WorldInfo.TimeSeconds+0.5);
	}
	else
	{
		MoneyTossCount = 0;
		MoneyTossTime = WorldInfo.TimeSeconds+1;
	}
	Super.ServerThrowMoney();
}

simulated function Inventory CreateInventory(class<Inventory> NewInventoryItemClass, optional bool bDoNotActivate)
{
	local KFWeapon Wep;
	local Inventory SupClass;
	
	SupClass = Super.CreateInventory(NewInventoryItemClass, bDoNotActivate);
	Wep = KFWeapon(SupClass);
	
	if( Wep != none )
	{
		if( KFWeap_Pistol_Dual9mm(Wep) != None && ExtWeap_Pistol_Dual9mm(Wep) == None )
		{
			Wep.Destroy();
			return Super.CreateInventory(class'ExtWeap_Pistol_Dual9mm', bDoNotActivate);
		}
		
		Switch(Wep.Class.Name)
		{
			Case 'KFWeap_GrenadeLauncher_M79':
				Wep.WeaponProjectiles[0] = class'ExtProj_HighExplosive_M79';
				break;
			Case 'KFWeap_RocketLauncher_RPG7':
				Wep.WeaponProjectiles[0] = class'ExtProj_Rocket_RPG7';
				break;
			Case 'KFWeap_AssaultRifle_M16M203':
				Wep.WeaponProjectiles[1] = class'ExtProj_HighExplosive_M16M203';
				break;	
			Case 'KFWeap_Thrown_C4':
				Wep.WeaponProjectiles[0] = class'ExtProj_Thrown_C4';
				break;	
			Case 'KFWeap_RocketLauncher_Seeker6':
				Wep.WeaponProjectiles[0] = class'ExtProj_Rocket_Seeker6';
				break;	
			default:
				break;
		}
		
		return Wep;
	}
	
	return SupClass;
}

simulated function CheckForExcessRemoval(KFWeapon NewWeap)
{
	local Inventory RemoveInv, Inv;
	
	if( KFWeap_Pistol_Dual9mm(NewWeap) != None )
	{
		for (Inv = InventoryChain; Inv != None; Inv = Inv.Inventory)
		{
			if (Inv.Class == class'ExtWeap_Pistol_9mm')
			{
				RemoveInv = Inv;
				Inv = Inv.Inventory;
				RemoveFromInventory(RemoveInv);
			}
		}
	}
		
	Super.CheckForExcessRemoval(NewWeap);
}