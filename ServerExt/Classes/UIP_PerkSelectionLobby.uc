Class UIP_PerkSelectionLobby extends UIP_PerkSelection;

function Timer()
{
	local int i;

	CurrentManager = ExtPlayerController(GetPlayer()).ActivePerkManager;
	if( CurrentManager!=None )
	{
		if( PrevPendingPerk!=None )
		{
			PendingPerk = CurrentManager.FindPerk(PrevPendingPerk);
			PrevPendingPerk = None;
		}
		PerkList.ChangeListSize(CurrentManager.UserPerks.Length);
		if( PendingPerk!=None && !PendingPerk.bPerkNetReady )
			return;
		
		// Huge code block to handle stat updating, but actually pretty well optimized.
		if( PendingPerk!=OldUsedPerk )
		{
			OldUsedPerk = PendingPerk;
			if( PendingPerk!=None )
			{
				OldPerkPoints = -1;
				if( StatsList.ItemComponents.Length!=PendingPerk.PerkStats.Length )
				{
					if( StatsList.ItemComponents.Length<PendingPerk.PerkStats.Length )
					{
						for( i=StatsList.ItemComponents.Length; i<PendingPerk.PerkStats.Length; ++i )
						{
							if( i>=StatBuyers.Length )
							{
								StatBuyers[StatBuyers.Length] = UIR_PerkStat(StatsList.AddListComponent(class'UIR_PerkStat'));
								StatBuyers[i].StatIndex = i;
								StatBuyers[i].InitMenu();
							}
							else
							{
								StatsList.ItemComponents.Length = i+1;
								StatsList.ItemComponents[i] = StatBuyers[i];
							}
						}
					}
					else if( StatsList.ItemComponents.Length>PendingPerk.PerkStats.Length )
					{
						for( i=PendingPerk.PerkStats.Length; i<StatsList.ItemComponents.Length; ++i )
							StatBuyers[i].CloseMenu();
						StatsList.ItemComponents.Length = PendingPerk.PerkStats.Length;
					}
				}
				OldPerkPoints = PendingPerk.CurrentSP;
				PerkLabel.SetText("Lv"$PendingPerk.GetLevelString()@PendingPerk.PerkName$" (Points: "$PendingPerk.CurrentSP$")");
				for( i=0; i<StatsList.ItemComponents.Length; ++i ) // Just make sure perk stays the same.
				{
					StatBuyers[i].SetActivePerk(PendingPerk);
					StatBuyers[i].CheckBuyLimit();
				}
				UpdateTraits();
			}
			else // Empty out if needed.
			{
				for( i=0; i<StatsList.ItemComponents.Length; ++i )
					StatBuyers[i].CloseMenu();
				StatsList.ItemComponents.Length = 0;
				PerkLabel.SetText("<No perk selected>");
			}
		}
		else if( PendingPerk!=None && OldPerkPoints!=PendingPerk.CurrentSP )
		{
			OldPerkPoints = PendingPerk.CurrentSP;
			PerkLabel.SetText("Lv"$PendingPerk.GetLevelString()@PendingPerk.PerkName$" (Points: "$PendingPerk.CurrentSP$")");
			for( i=0; i<StatsList.ItemComponents.Length; ++i ) // Just make sure perk stays the same.
				StatBuyers[i].CheckBuyLimit();
			
			// Update traits list.
			UpdateTraits();
		}
	}
}

defaultproperties
{
	Components.Remove(UnloadPerkButton)
	Components.Remove(PrestigePerkButton)
	Components.Remove(ResetPerkButton)
}