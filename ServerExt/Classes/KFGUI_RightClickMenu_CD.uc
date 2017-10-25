Class KFGUI_RightClickMenu_CD extends KFGUI_RightClickMenu;

function DrawMenu()
{
	local float X,Y,YP,Edge,TextScale;
	local int i;
	local bool bCheckMouse;
	
	// Draw background.
	Edge = EdgeSize;
	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(45, 45, 45, 200);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	Canvas.SetPos(Edge,Edge);
	Canvas.SetDrawColor(10, 10, 10, 160);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2]-(Edge*2.f),CompPos[3]-(Edge*2.f));

	// While rendering, figure out mouse focus row.
	X = Owner.MousePosition.X - Canvas.OrgX;
	Y = Owner.MousePosition.Y - Canvas.OrgY;
	
	bCheckMouse = (X>0.f && X<CompPos[2] && Y>0.f && Y<CompPos[3]);
	
	Canvas.Font = Owner.CurrentStyle.PickFont(Owner.CurrentStyle.DefaultFontSize,TextScale);

	YP = Edge;
	CurrentRow = -1;

	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for( i=0; i<ItemRows.Length; ++i )
	{
		if( bCheckMouse && Y>=YP && Y<=(YP+Owner.CurrentStyle.DefaultHeight) )
		{
			bCheckMouse = false;
			CurrentRow = i;
			Canvas.SetPos(4.f,YP);
			Canvas.SetDrawColor(110,110,110,255);
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2]-(Edge*2.f),Owner.CurrentStyle.DefaultHeight);
		}

		Canvas.SetPos(Edge,YP);
		if( ItemRows[i].bSplitter )
		{
			Canvas.SetDrawColor(255,255,255,255);
			Canvas.DrawText("-------",,TextScale,TextScale);
		}
		else
		{
			if( ItemRows[i].bDisabled )
				Canvas.SetDrawColor(148,148,148,255);
			else Canvas.SetDrawColor(248,248,248,255);
			Canvas.DrawText(ItemRows[i].Text,,TextScale,TextScale);
		}
		
		YP+=Owner.CurrentStyle.DefaultHeight;
	}
	Canvas.PopMaskRegion();
	if( OldRow!=CurrentRow )
	{
		OldRow = CurrentRow;
		PlayMenuSound(MN_DropdownChange);
	}
}

defaultproperties
{
}