Class KFGUI_CheckBox extends KFGUI_EditControl;

var() Texture CheckMark,CheckDisabled,CheckIdle,CheckFocus,CheckClicked;
var() bool bForceUniform,bChecked;

function UpdateSizes()
{
	Super.UpdateSizes();
	if( bForceUniform )
		XSize = (YSize*InputPos[3]) / InputPos[2];
}

function DrawMenu()
{
	Owner.CurrentStyle.RenderCheckbox(Self);
}

function HandleMouseClick( bool bRight )
{
	bChecked = !bChecked;
	if( bChecked )
		PlayMenuSound(MN_ClickCheckboxOn);
	else PlayMenuSound(MN_ClickCheckboxOff);
	OnCheckChange(Self);
}

Delegate OnCheckChange( KFGUI_CheckBox Sender );

defaultproperties
{
	bForceUniform=true
	LableWidth=0.85
}