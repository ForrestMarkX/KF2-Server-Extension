Class KFGUI_ScrollBarV_CD extends KFGUI_ScrollBarV;

function DrawMenu()
{
	local float A;
	local byte i;

	if( bDisabled )
		Canvas.SetDrawColor(5, 5, 5, 0);
	else if( bFocused || bGrabbedScroller )
		Canvas.SetDrawColor(30, 30, 30, 160);
	else Canvas.SetDrawColor(30, 30, 30, 160);

	Owner.CurrentStyle.DrawRectBox (0.f, 0.f, CompPos[2], CompPos[3], 4);
	
	if( bDisabled )
		return;

	if( bVertical )
		i = 3;
	else i = 2;
	
	SliderScale = FMax(PageStep * (CompPos[i] - 32.f) / (MaxRange + PageStep),CalcButtonScale);
	
	if( bGrabbedScroller )
	{
		// Track mouse.
		if( bVertical )
			A = Owner.MousePosition.Y - CompPos[1] - GrabbedOffset;
		else A = Owner.MousePosition.X - CompPos[0] - GrabbedOffset;
		
		A /= ((CompPos[i]-SliderScale) / float(MaxRange));
		SetValue(A);
	}

	A = float(CurrentScroll) / float(MaxRange);
	ButtonOffset = A*(CompPos[i]-SliderScale);

	if( bGrabbedScroller )
		Canvas.SetDrawColor(90,90,90,255);
	else if( bFocused )
		Canvas.SetDrawColor(65,65,65,255);
	else Canvas.SetDrawColor(40,40,40,255);

	if( bVertical )
		Owner.CurrentStyle.DrawRectBox (0.f, ButtonOffset, CompPos[2], SliderScale, 4);
	else Owner.CurrentStyle.DrawRectBox (ButtonOffset, 0.f, SliderScale, CompPos[3], 4);
}

defaultproperties
{
}