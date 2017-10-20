Class KFGUI_ComboSelector extends KFGUI_Clickable;

var KFGUI_ComboBox Combo;
var int CurrentRow,OldRow;

function DrawMenu()
{
	Owner.CurrentStyle.RenderComboList(Self);
}

function HandleMouseClick( bool bRight )
{
	PlayMenuSound(MN_ClickButton);
	DropInputFocus();
	if( CurrentRow>=0 )
	{
		Combo.SelectedIndex = CurrentRow;
		Combo.OnComboChanged(Combo);
	}
}

defaultproperties
{
	CurrentRow=-1
	OldRow=-1
	bFocusedPostDrawItem=true
}