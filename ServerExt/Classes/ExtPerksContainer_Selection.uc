class ExtPerksContainer_Selection extends KFGFxPerksContainer_Selection;

function UpdatePerkSelection(byte SelectedPerkIndex)
{
 	local int i;
	local GFxObject DataProvider;
	local GFxObject TempObj;
	local ExtPlayerController KFPC;
	local Ext_PerkBase PerkClass;	

	KFPC = ExtPlayerController( GetPC() );

	if ( KFPC!=none && KFPC.ActivePerkManager!=None )
	{
	   	DataProvider = CreateArray();

		for (i = 0; i < KFPC.ActivePerkManager.UserPerks.Length; i++)
		{
			PerkClass = KFPC.ActivePerkManager.UserPerks[i];
		    TempObj = CreateObject( "Object" );
		    TempObj.SetInt( "PerkLevel", PerkClass.CurrentLevel );
		    TempObj.SetString( "Title",  PerkClass.PerkName );	
			TempObj.SetString( "iconSource",  PerkClass.GetPerkIconPath(PerkClass.CurrentLevel) );
			TempObj.SetBool("bTierUnlocked", true);
			
		    DataProvider.SetElementObject( i, TempObj );
		}	
		SetObject( "perkData", DataProvider );
		SetInt("SelectedIndex", SelectedPerkIndex);

		UpdatePendingPerkInfo(SelectedPerkIndex);
    }
}

function UpdatePendingPerkInfo(byte SelectedPerkIndex)
{
	local ExtPlayerController KFPC;
	local Ext_PerkBase PerkClass;

	KFPC = ExtPlayerController( GetPC() );
	if( KFPC != none )
	{
		PerkClass = KFPC.ActivePerkManager.UserPerks[SelectedPerkIndex];
		SetPendingPerkChanges(PerkClass.PerkName, PerkClass.GetPerkIconPath(PerkClass.CurrentLevel), "Perk changes will be applied when you die.");
	}
}

function SavePerk(int PerkID);
