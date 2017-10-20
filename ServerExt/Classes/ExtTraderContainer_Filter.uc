class ExtTraderContainer_Filter extends KFGFxTraderContainer_Filter;

function SetPerkFilterData(byte FilterIndex)
{
 	local int i;
	local GFxObject DataProvider;
	local GFxObject FilterObject;
	local ExtPlayerController KFPC;
	local KFPlayerReplicationInfo KFPRI;
	local ExtPerkManager PrM;

	SetBool("filterVisibliity", true);

    KFPC = ExtPlayerController( GetPC() );
	if ( KFPC != none )
	{
		PrM = KFPC.ActivePerkManager;
		KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
		if ( KFPRI != none && PrM!=None )
		{
			i = Max(PrM.UserPerks.Find(PrM.CurrentPerk),0);
			SetInt("selectedIndex", i);

			// Set the title of this filter based on either the perk or the off perk string
			if( FilterIndex < PrM.UserPerks.Length )
			{
				SetString("filterText", PrM.UserPerks[FilterIndex].PerkName);
			}
			else
			{
				SetString("filterText", OffPerkString);
			}

		   	DataProvider = CreateArray();
			for (i = 0; i < PrM.UserPerks.Length; i++)
			{
				FilterObject = CreateObject( "Object" );
				FilterObject.SetString("source",  PrM.UserPerks[i].GetPerkIconPath(PrM.UserPerks[i].CurrentLevel));
			    DataProvider.SetElementObject( i, FilterObject );
			}

			FilterObject = CreateObject( "Object" );
			FilterObject.SetString("source",  "img://"$class'KFGFxObject_TraderItems'.default.OffPerkIconPath);
			DataProvider.SetElementObject( i, FilterObject );

			SetObject( "filterSource", DataProvider );
    	}
    }
}

defaultproperties
{
}