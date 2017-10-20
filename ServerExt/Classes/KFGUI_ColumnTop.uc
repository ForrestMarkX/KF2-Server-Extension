// Do not use this on your own, it is used by ColumnList
Class KFGUI_ColumnTop extends KFGUI_Base;

var() float ColumnMinSize; // Minimum pixels width allowed.
var KFGUI_ColumnList ListOwner;

var transient int PrevSortedColumn,MouseColumn,ScalingColumn;
var transient byte PressedDown[2];
var transient bool bPressedDown,bScaleColumn,bMouseScaler;

function InitMenu()
{
	Super.InitMenu();
	ListOwner = KFGUI_ColumnList(ParentComponent);
}

function DrawMenu()
{
	local int i,j;
	local float X,MouseX,GrabWidth,MinSize,Wd;
	local bool bCheckMouse;

	bClickable = ListOwner.bClickable;
	MinSize = ColumnMinSize / CompPos[2];
	
	// Scale column
	if( bScaleColumn )
	{
		MouseX = Owner.MousePosition.X - CompPos[0];
		for( i=0; i<ScalingColumn; ++i )
			MouseX-=(ListOwner.Columns[i].Width * CompPos[2]);

		ListOwner.Columns[ScalingColumn].Width = MouseX / CompPos[2];
		
		// Make sure no column is scrolled off screen.
		X = 0;
		for( i=0; i<(ListOwner.Columns.Length-1); ++i )
		{
			if( ListOwner.Columns[i].Width<MinSize )
				ListOwner.Columns[i].Width = MinSize;
			X+=ListOwner.Columns[i].Width;
			if( X>=(1.f-MinSize) )
			{
				MouseX = X-(1.f-MinSize); // Grab overshoot.

				// Then push back!
				for( j=i; j>=0; --j )
				{
					if( (ListOwner.Columns[j].Width-MouseX)>MinSize ) // This column has enough space to retract.
					{
						ListOwner.Columns[j].Width-=MouseX;
						MouseX = 0;
						break;
					}
					else if( ListOwner.Columns[j].Width>MinSize ) // This column has limited space to retract.
					{
						MouseX-=(ListOwner.Columns[j].Width-MinSize);
						ListOwner.Columns[j].Width = MinSize;
					}
				}
				X = (1.f-MinSize); // Continue at maximum size.
			}
		}
	}
	
	// Init mouse check.
	MouseColumn = -1;
	bCheckMouse = (bClickable && bFocused);
	if( bCheckMouse )
	{
		GrabWidth = CompPos[3]*0.175;
		MouseX = Owner.MousePosition.X - CompPos[0] - GrabWidth;
		GrabWidth *= -2.f;
	}

	// Draw the columns and compute the scalings.
	X = 0;
	j = (ListOwner.bShouldSortList ? ListOwner.LastSortedColumn : -1);
	for( i=0; i<ListOwner.Columns.Length; ++i )
	{
		if( ListOwner.Columns[i].Width<MinSize )
			ListOwner.Columns[i].Width = MinSize;

		Wd = ListOwner.Columns[i].Width * CompPos[2];
		if( i==(ListOwner.Columns.Length-1) ) // Final column, give infinitive width.
		{
			Wd = (CompPos[2]-X);
		}
		if( Wd<=0 ) // Impossible.
		{
			ListOwner.Columns[i].bHidden = true;
			continue;
		}

		ListOwner.Columns[i].X = X;
		ListOwner.Columns[i].XSize = Wd;
		
		if( bCheckMouse && (MouseX-=Wd)<=0.f )
		{
			MouseColumn = i;
			bCheckMouse = false;
			bMouseScaler = (MouseX>=GrabWidth) && ((i+1)<ListOwner.Columns.Length);
		}

		if( X>=CompPos[2] )
			ListOwner.Columns[i].bHidden = true;
		else
		{
			ListOwner.Columns[i].bHidden = false;
			Canvas.SetClip(X+Wd,CompPos[1]+CompPos[3]);
			
			// Draw column.
			Owner.CurrentStyle.RenderColumnHeader(Self,X,Min(Wd,CompPos[2]-X),i,MouseColumn==i && !bMouseScaler,i==j);
		}
		X+=Wd;
	}
}

function MouseClick( bool bRight )
{
	if( !ListOwner.bDisabled && bClickable )
	{
		PressedDown[byte(bRight)] = 1;
		bPressedDown = true;
		
		if( !bRight && bMouseScaler )
		{
			PlayMenuSound(MN_ClickButton);
			bScaleColumn = true;
			ScalingColumn = MouseColumn;
			GetInputFocus();
		}
	}
}
function MouseRelease( bool bRight )
{
	if( bScaleColumn && !bRight )
	{
		bScaleColumn = false;
		DropInputFocus();
		return;
	}
	if( !bDisabled && bClickable && PressedDown[byte(bRight)]==1 )
	{
		PlayMenuSound(MN_ClickButton);
		PressedDown[byte(bRight)] = 0;
		bPressedDown = (PressedDown[0]!=0 || PressedDown[1]!=0);
		
		if( MouseColumn>=0 )
		{
			ListOwner.SortColumn(MouseColumn,(PrevSortedColumn==MouseColumn));
			if( PrevSortedColumn==MouseColumn )
				PrevSortedColumn = -1;
			else PrevSortedColumn = MouseColumn;
		}
	}
}
function byte GetCursorStyle()
{
	if( bClickable )
		return (bMouseScaler ? 2 : 1);
	return 0;
}
function MouseLeave()
{
	Super.MouseLeave();
	if( !bScaleColumn )
	{
		PressedDown[0] = 0;
		PressedDown[1] = 0;
		bPressedDown = false;
	}
}
function MouseEnter()
{
	Super.MouseEnter();
}

function LostInputFocus()
{
	bScaleColumn = false;
	PressedDown[0] = 0;
	PressedDown[1] = 0;
	bPressedDown = false;
}

defaultproperties
{
	bClickable=true
	ColumnMinSize=8
}