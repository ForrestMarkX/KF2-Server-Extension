Class UI_PrestigeNote extends UI_ResetWarning;

function SetupTo( Ext_PerkBase P )
{
	PerkToReset = P.Class;
	WindowTitle = "NOTICE: Prestige "$P.PerkName;
	InfoLabel.SetText("NOTICE: If you prestige your perk, you can not undo this operation!|All your gained XP and level will be reset to #{FF0000}0#{DEF}.|But this will also increase the amount of points by #{F7FE2E}+"$P.PrestigeSPIncrease$"#{DEF} you earn for every level up in the future.||Are you sure you want to do this?");
}

defaultproperties
{
	bIsPrestige=true

	Begin Object Name=YesButten
		Tooltip="Prestige the perk (you can not undo this action!)"
	End Object
}