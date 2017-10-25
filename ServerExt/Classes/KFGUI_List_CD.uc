Class KFGUI_List_CD extends KFGUI_List;

function InitMenu()
{
	Super(KFGUI_MultiComponent).InitMenu();
	ScrollBar = KFGUI_ScrollBarV_CD(FindComponentID('Scrollbar'));
	UpdateListVis();
}

defaultproperties
{
	Components.Empty
	
	Begin Object Class=KFGUI_ScrollBarV_CD Name=ListScroller
		XPosition=0.96
		YPosition=0
		XSize=0.04
		YSize=1
		ID="Scrollbar"
	End Object
	Components.Add(ListScroller)
}