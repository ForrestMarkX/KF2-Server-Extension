// Columned list box (only for text lines).
Class UIR_PerkTraitList extends KFGUI_ColumnList;

var array<string> ToolTip;
var KFGUI_Tooltip ToolTipItem;

function DrawMenu()
{
	local int i,n,j;
	local float Y,TextY,YClip,XOffset;
	local KFGUI_ListItem C;
	local bool bCheckMouse,bHideRow;

	Canvas.DrawColor = BackgroundColor;
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	
	// Mouse focused item check.
	bCheckMouse = bClickable && bFocused;
	FocusMouseItem = -1;
	if( bCheckMouse )
		MouseYHit = Owner.MousePosition.Y - CompPos[1];

	n = ScrollBar.CurrentScroll;
	i = 0;
	for( C=FirstItem; C!=None; C=C.Next )
		if( (i++)==n )
			break;
	Y = 0.f;
	TextY = (ItemHeight-TextHeight)*0.5f;
	XOffset = TextY*0.75;
	YClip = CompPos[1]+CompPos[3];
	Canvas.SetDrawColor(250,250,250,255);

	for( i=0; (i<ListItemsPerPage && C!=None); ++i )
	{
		// Check for mouse hit.
		if( bCheckMouse && FocusMouseItem==-1 )
		{
			if( MouseYHit<ItemHeight )
				FocusMouseItem = n;
			else MouseYHit-=ItemHeight;
		}
		
		// Draw selection background.
		bHideRow = false;
		if( Left(C.GetDisplayStr(0),2)=="--" ) // Group name.
		{
			Canvas.SetPos(0,Y);
			Canvas.SetDrawColor(32,128,32);
			bHideRow = true;
			
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
			
			Canvas.SetClip(CompPos[0]+CompPos[2],YClip);
			Canvas.SetPos(2,TextY);
			DrawStrClipped(Mid(C.GetDisplayStr(0),2));
		}
		else if( SelectedRowIndex==n ) // Selected
		{
			Canvas.SetPos(0,Y);
			Canvas.DrawColor = SelectedLineColor;
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
		}
		else if( FocusMouseItem==n ) // Focused
		{
			Canvas.SetPos(0,Y);
			Canvas.DrawColor = FocusedLineColor;
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
		}
		
		if( !bHideRow )
		{
			// Draw columns of text
			for( j=0; j<Columns.Length; ++j )
				if( !Columns[j].bHidden )
				{
					Canvas.SetClip(Columns[j].X+Columns[j].XSize,YClip);
					Canvas.SetPos(Columns[j].X+XOffset,TextY);
					DrawStrClipped(C.GetDisplayStr(j));
				}
		}
		Y+=ItemHeight;
		TextY+=ItemHeight;
		++n;
		C = C.Next;
	}
}
function NotifyMousePaused()
{
	if( Owner.InputFocus==None && FocusMouseItem!=-1 && ToolTip[FocusMouseItem]!="" )
	{
		if( ToolTipItem==None )
		{
			ToolTipItem = New(None)Class'KFGUI_Tooltip';
			ToolTipItem.Owner = Owner;
			ToolTipItem.ParentComponent = Self;
			ToolTipItem.InitMenu();
		}
		ToolTipItem.SetText(ToolTip[FocusMouseItem]);
		ToolTipItem.ShowMenu();
		ToolTipItem.CompPos[0] = Owner.MousePosition.X;
		ToolTipItem.CompPos[1] = Owner.MousePosition.Y;
		ToolTipItem.GetInputFocus();
	}
}

defaultproperties
{
	Columns.Add((Text="Trait name",Width=0.6))
	Columns.Add((Text="Level",Width=0.2))
	Columns.Add((Text="Cost",Width=0.2))
	bCanSortColumn=false
}