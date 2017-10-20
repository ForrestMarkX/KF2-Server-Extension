Class KF2Style extends GUIStyleBase;

var Texture2D LoadedTex[2];
var Font DrawFonts[3];

const TOOLTIP_BORDER=4;

function InitStyle()
{
	local byte i;

	Super.InitStyle();
	
	LoadedTex[0] = Texture2D(DynamicLoadObject("EditorMaterials.CASC_ModuleEnable",class'Texture2D'));
	LoadedTex[1] = Texture2D(DynamicLoadObject("EditorMaterials.Tick",class'Texture2D'));
	for( i=0; i<ArrayCount(LoadedTex); ++i )
		if( LoadedTex[i]==None )
			LoadedTex[i] = Texture2D'EngineMaterials.DefaultWhiteGrid';
	DrawFonts[0] = Font(DynamicLoadObject("UI_Canvas_Fonts.Font_General",class'Font'));
	DrawFonts[1] = Font(DynamicLoadObject("EngineFonts.SmallFont",class'Font'));
	DrawFonts[2] = Font(DynamicLoadObject("EngineFonts.TinyFont",class'Font'));
	for( i=0; i<ArrayCount(DrawFonts); ++i )
	{
		if( DrawFonts[i]==None )
			DrawFonts[i] = class'Engine'.Static.GetMediumFont();
	}
}
function RenderFramedWindow( KFGUI_FloatingWindow P )
{
	local int XS,YS,CornerSlope,TitleHeight;
	
	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;
	CornerSlope = DefaultHeight*0.4;
	TitleHeight = DefaultHeight;

	// Frame Header
	if( P.bWindowFocused )
		Canvas.SetDrawColor(220,2,2,255);
	else Canvas.SetDrawColor(100,1,1,P.FrameOpacity);
	Canvas.SetPos(0,0);
	DrawCornerTex(CornerSlope,0);
	Canvas.SetPos(0,TitleHeight);
	DrawCornerTex(CornerSlope,3);
	Canvas.SetPos(XS-CornerSlope,0);
	DrawCornerTex(CornerSlope,1);
	Canvas.SetPos(XS-CornerSlope,TitleHeight);
	DrawCornerTex(CornerSlope,2);
	
	// Header filling
	Canvas.SetPos(0,CornerSlope);
	DrawWhiteBox(XS,TitleHeight-CornerSlope);
	Canvas.SetPos(CornerSlope,0);
	DrawWhiteBox(XS-(CornerSlope*2),CornerSlope);
	
	// Frame itself.
	if( P.bWindowFocused )
		Canvas.SetDrawColor(32,6,6,255);
	else Canvas.SetDrawColor(16,2,2,P.FrameOpacity);
	Canvas.SetPos(0,TitleHeight);
	DrawCornerTex(CornerSlope,0);
	Canvas.SetPos(XS-CornerSlope,TitleHeight);
	DrawCornerTex(CornerSlope,1);
	Canvas.SetPos(0,YS-CornerSlope);
	DrawCornerTex(CornerSlope,2);
	Canvas.SetPos(XS-CornerSlope,YS-CornerSlope);
	DrawCornerTex(CornerSlope,3);
	
	// Filling
	Canvas.SetPos(CornerSlope,TitleHeight);
	DrawWhiteBox(XS-(CornerSlope*2),YS-TitleHeight);
	Canvas.SetPos(0,TitleHeight+CornerSlope);
	DrawWhiteBox(CornerSlope,YS-(CornerSlope*2)-TitleHeight);
	Canvas.SetPos(XS-CornerSlope,TitleHeight+CornerSlope);
	DrawWhiteBox(CornerSlope,YS-(CornerSlope*2)-TitleHeight);
	
	// Title.
	if( P.WindowTitle!="" )
	{
		Canvas.SetDrawColor(250,250,250,P.FrameOpacity);
		Canvas.SetPos(CornerSlope,0);
		DrawText(DefaultFontSize,P.WindowTitle);
	}
}
function RenderWindow( KFGUI_Page P )
{
	local int XS,YS,CornerSlope;
	
	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;
	CornerSlope = DefaultHeight*0.4;

	// Frame itself.
	if( P.bWindowFocused )
		Canvas.SetDrawColor(64,64,64,255);
	else Canvas.SetDrawColor(32,32,32,P.FrameOpacity);
	Canvas.SetPos(0,0);
	DrawCornerTex(CornerSlope,0);
	Canvas.SetPos(XS-CornerSlope,0);
	DrawCornerTex(CornerSlope,1);
	Canvas.SetPos(0,YS-CornerSlope);
	DrawCornerTex(CornerSlope,2);
	Canvas.SetPos(XS-CornerSlope,YS-CornerSlope);
	DrawCornerTex(CornerSlope,3);
	
	// Filling
	Canvas.SetPos(CornerSlope,0);
	DrawWhiteBox(XS-(CornerSlope*2),YS);
	Canvas.SetPos(0,CornerSlope);
	DrawWhiteBox(CornerSlope,YS-(CornerSlope*2));
	Canvas.SetPos(XS-CornerSlope,CornerSlope);
	DrawWhiteBox(CornerSlope,YS-(CornerSlope*2));
}
function RenderToolTip( KFGUI_Tooltip TT )
{
	local int i;
	local float X,Y,XS,YS,TX,TY,TS;

	Canvas.Font = PickFont(DefaultFontSize,TS);

	// First compute textbox size.
	TY = DefaultHeight*TT.Lines.Length;
	for( i=0; i<TT.Lines.Length; ++i )
	{
		if( TT.Lines[i]!="" )
			Canvas.TextSize(TT.Lines[i],XS,YS);
		TX = FMax(XS,TX);
	}
	TX*=TS;
	
	// Give some borders.
	TX += TOOLTIP_BORDER*2;
	TY += TOOLTIP_BORDER*2;

	X = TT.CompPos[0];
	Y = TT.CompPos[1]+24.f;

	// Then check if too close to window edge, then move it to another pivot.
	if( (X+TX)>TT.Owner.ScreenSize.X )
		X = TT.Owner.ScreenSize.X-TX;
	if( (Y+TY)>TT.Owner.ScreenSize.Y )
		Y = TT.CompPos[1]-TY;
	
	if( TT.CurrentAlpha<255 )
		TT.CurrentAlpha = Min(TT.CurrentAlpha+25,255);

	// Reset clipping.
	Canvas.SetOrigin(0,0);
	Canvas.SetClip(TT.Owner.ScreenSize.X,TT.Owner.ScreenSize.Y);

	// Draw frame.
	Canvas.SetDrawColor(200,200,80,TT.CurrentAlpha);
	Canvas.SetPos(X-2,Y-2);
	DrawWhiteBox(TX+4,TY+4);
	Canvas.SetDrawColor(80,10,80,TT.CurrentAlpha);
	Canvas.SetPos(X,Y);
	DrawWhiteBox(TX,TY);

	// Draw text.
	Canvas.SetDrawColor(255,255,255,TT.CurrentAlpha);
	X+=TOOLTIP_BORDER;
	Y+=TOOLTIP_BORDER;
	for( i=0; i<TT.Lines.Length; ++i )
	{
		Canvas.SetPos(X,Y);
		Canvas.DrawText(TT.Lines[i],,TS,TS,TT.TextFontInfo);
		Y+=DefaultHeight;
	}
}
function RenderButton( KFGUI_Button B )
{
	local float XL,YL,TS;
	local byte i;

	if( B.bDisabled )
		Canvas.SetDrawColor(32,0,0,255);
	else if( B.bPressedDown )
		Canvas.SetDrawColor(255,64,64,255);
	else if( B.bFocused )
		Canvas.SetDrawColor(180,45,45,255);
	else Canvas.SetDrawColor(164,8,8,255);
	
	if( B.bIsHighlighted )
	{
		Canvas.DrawColor.R = Min(Canvas.DrawColor.R+25,255);
		Canvas.DrawColor.G = Min(Canvas.DrawColor.G+25,255);
		Canvas.DrawColor.B = Min(Canvas.DrawColor.B+25,255);
	}

	Canvas.SetPos(0.f,0.f);
	if( B.ExtravDir==255 )
		DrawWhiteBox(B.CompPos[2],B.CompPos[3]);
	else DrawRectBox(0,0,B.CompPos[2],B.CompPos[3],Min(B.CompPos[2],B.CompPos[3])*0.2,B.ExtravDir);

	if( B.OverlayTexture.Texture!=None )
	{
		Canvas.SetPos(0.f,0.f);
		Canvas.DrawTile(B.OverlayTexture.Texture,B.CompPos[2],B.CompPos[3],B.OverlayTexture.U,B.OverlayTexture.V,B.OverlayTexture.UL,B.OverlayTexture.VL);
	}
	if( B.ButtonText!="" )
	{
		// Chose the best font to fit this button.
		i = Min(B.FontScale+DefaultFontSize,MaxFontScale);
		while( true )
		{
			Canvas.Font = PickFont(i,TS);
			Canvas.TextSize(B.ButtonText,XL,YL,TS,TS);
			if( i==0 || (XL<(B.CompPos[2]*0.95) && YL<(B.CompPos[3]*0.95)) )
				break;
			--i;
		}
		Canvas.SetPos((B.CompPos[2]-XL)*0.5,(B.CompPos[3]-YL)*0.5);
		if( B.bDisabled )
			Canvas.DrawColor = B.TextColor*0.5f;
		else Canvas.DrawColor = B.TextColor;
		Canvas.DrawText(B.ButtonText,,TS,TS,B.TextFontInfo);
	}
}
function RenderEditBox( KFGUI_EditBox E )
{
	local color C;

	if( E.bDisabled )
	{
		Canvas.SetDrawColor(4,4,32,255);
		C = MakeColor(52,52,52,255);
	}
	else if( E.bPressedDown )
	{
		Canvas.SetDrawColor(110,110,255,255);
		C = MakeColor(16,16,186,255);
	}
	else if( E.bFocused || E.bIsTyping )
	{
		Canvas.SetDrawColor(120,120,230,255);
		C = MakeColor(8,8,96,255);
	}
	else
	{
		Canvas.SetDrawColor(50,50,186,255);
		C = MakeColor(8,8,50,255);
	}
	
	Canvas.SetPos(0.f,0.f);
	DrawRectBox(0,0,E.CompPos[2],E.CompPos[3],E.TextHeight*0.15,1);
	
	Canvas.SetPos(3.f,3.f);
	Canvas.DrawColor = C;
	DrawWhiteBox(E.CompPos[2]-6,E.CompPos[3]-6);
}
function RenderScrollBar( KFGUI_ScrollBarBase S )
{
	local float A;
	local byte i;

	if( S.bDisabled )
		Canvas.SetDrawColor(48,2,2,255);
	else if( S.bFocused || S.bGrabbedScroller )
		Canvas.SetDrawColor(86,8,8,255);
	else Canvas.SetDrawColor(74,4,4,255);

	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(S.CompPos[2],S.CompPos[3]);
	
	if( S.bDisabled )
		return;

	if( S.bVertical )
		i = 3;
	else i = 2;
	
	S.SliderScale = FMax(S.PageStep * (S.CompPos[i] - 32.f) / (S.MaxRange + S.PageStep),S.CalcButtonScale);
	
	if( S.bGrabbedScroller )
	{
		// Track mouse.
		if( S.bVertical )
			A = S.Owner.MousePosition.Y - S.CompPos[1] - S.GrabbedOffset;
		else A = S.Owner.MousePosition.X - S.CompPos[0] - S.GrabbedOffset;
		
		A /= ((S.CompPos[i]-S.SliderScale) / float(S.MaxRange));
		S.SetValue(A);
	}

	A = float(S.CurrentScroll) / float(S.MaxRange);
	S.ButtonOffset = A*(S.CompPos[i]-S.SliderScale);

	if( S.bGrabbedScroller )
		Canvas.SetDrawColor(140,86,8,255);
	else if( S.bFocused )
		Canvas.SetDrawColor(175,48,8,255);
	else Canvas.SetDrawColor(150,36,4,255);

	if( S.bVertical )
	{
		Canvas.SetPos(0.f,S.ButtonOffset);
		DrawWhiteBox(S.CompPos[2],S.SliderScale);
	}
	else
	{
		Canvas.SetPos(S.ButtonOffset,0.f);
		DrawWhiteBox(S.SliderScale,S.CompPos[3]);
	}
}
function RenderColumnHeader( KFGUI_ColumnTop C, float XPos, float Width, int Index, bool bFocus, bool bSort )
{
	local int XS;

	if( bSort )
	{
		if( bFocus )
			Canvas.SetDrawColor(175,240,8,255);
		else Canvas.SetDrawColor(128,200,56,255);
	}
	else if( bFocus )
		Canvas.SetDrawColor(220,220,8,255);
	else Canvas.SetDrawColor(220,86,56,255);

	XS = DefaultHeight*0.125;
	Canvas.SetPos(XPos,0.f);
	DrawCornerTexNU(XS,C.CompPos[3],0);
	Canvas.SetPos(XPos+XS,0.f);
	DrawWhiteBox(Width-(XS*2),C.CompPos[3]);
	Canvas.SetPos(XPos+Width-(XS*2),0.f);
	DrawCornerTexNU(XS,C.CompPos[3],1);
	
	Canvas.SetDrawColor(250,250,250,255);
	Canvas.SetPos(XPos+XS,(C.CompPos[3]-C.ListOwner.TextHeight)*0.5f);
	C.ListOwner.DrawStrClipped(C.ListOwner.Columns[Index].Text);
}
function RenderCheckbox( KFGUI_CheckBox C )
{
	if( C.bDisabled )
		Canvas.SetDrawColor(86,86,86,255);
	else if( C.bPressedDown )
		Canvas.SetDrawColor(128,255,128,255);
	else if( C.bFocused )
		Canvas.SetDrawColor(150,200,128,255);
	else Canvas.SetDrawColor(128,186,128,255);
	
	Canvas.SetPos(0.f,0.f);
	Canvas.DrawTileStretched(LoadedTex[0],C.CompPos[2],C.CompPos[3],0,0,LoadedTex[0].GetSurfaceWidth(),LoadedTex[0].GetSurfaceHeight());

	if( C.bChecked )
	{
		if( C.bDisabled )
			Canvas.SetDrawColor(128,128,128,255);
		else Canvas.SetDrawColor(255,255,255,255);
		Canvas.SetPos(0.f,0.f);
		Canvas.DrawTile(LoadedTex[1],C.CompPos[2],C.CompPos[3],0,0,LoadedTex[1].GetSurfaceWidth(),LoadedTex[1].GetSurfaceHeight());
	}
}
function RenderComboBox( KFGUI_ComboBox C )
{
	if( C.bDisabled )
		Canvas.SetDrawColor(64,4,4,255);
	else if( C.bPressedDown )
		Canvas.SetDrawColor(220,56,56,255);
	else if( C.bFocused )
		Canvas.SetDrawColor(190,48,48,255);
	else Canvas.SetDrawColor(186,4,4,255);
	
	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);

	if( C.SelectedIndex<C.Values.Length && C.Values[C.SelectedIndex]!="" )
	{
		Canvas.SetPos(C.BorderSize,(C.CompPos[3]-C.TextHeight)*0.5);
		if( C.bDisabled )
			Canvas.DrawColor = C.TextColor*0.5f;
		else Canvas.DrawColor = C.TextColor;
		Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX-C.BorderSize,Canvas.ClipY);
		Canvas.DrawText(C.Values[C.SelectedIndex],,C.TextScale,C.TextScale,C.TextFontInfo);
		Canvas.PopMaskRegion();
	}
}
function RenderComboList( KFGUI_ComboSelector C )
{
	local float X,Y,YL,YP,Edge;
	local int i;
	local bool bCheckMouse;
	
	// Draw background.
	Edge = C.Combo.BorderSize;
	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(128,4,4,255);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);
	Canvas.SetPos(Edge,Edge);
	Canvas.SetDrawColor(64,4,4,255);
	DrawWhiteBox(C.CompPos[2]-(Edge*2.f),C.CompPos[3]-(Edge*2.f));

	// While rendering, figure out mouse focus row.
	X = C.Owner.MousePosition.X - Canvas.OrgX;
	Y = C.Owner.MousePosition.Y - Canvas.OrgY;
	
	bCheckMouse = (X>0.f && X<C.CompPos[2] && Y>0.f && Y<C.CompPos[3]);
	
	Canvas.Font = C.Combo.TextFont;
	YL = C.Combo.TextHeight;

	YP = Edge;
	C.CurrentRow = -1;

	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for( i=0; i<C.Combo.Values.Length; ++i )
	{
		if( bCheckMouse && Y>=YP && Y<=(YP+YL) )
		{
			bCheckMouse = false;
			C.CurrentRow = i;
			Canvas.SetPos(4.f,YP);
			Canvas.SetDrawColor(128,48,48,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),YL);
		}
		Canvas.SetPos(Edge,YP);
		
		if( i==C.Combo.SelectedIndex )
			Canvas.DrawColor = C.Combo.SelectedTextColor;
		else Canvas.DrawColor = C.Combo.TextColor;

		Canvas.DrawText(C.Combo.Values[i],,C.Combo.TextScale,C.Combo.TextScale,C.Combo.TextFontInfo);
		
		YP+=YL;
	}
	Canvas.PopMaskRegion();
	if( C.OldRow!=C.CurrentRow )
	{
		C.OldRow = C.CurrentRow;
		C.PlayMenuSound(MN_DropdownChange);
	}
}
function RenderRightClickMenu( KFGUI_RightClickMenu C )
{
	local float X,Y,YP,Edge,TextScale;
	local int i;
	local bool bCheckMouse;
	
	// Draw background.
	Edge = C.EdgeSize;
	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(148,4,4,255);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);
	Canvas.SetPos(Edge,Edge);
	Canvas.SetDrawColor(64,4,4,255);
	DrawWhiteBox(C.CompPos[2]-(Edge*2.f),C.CompPos[3]-(Edge*2.f));

	// While rendering, figure out mouse focus row.
	X = C.Owner.MousePosition.X - Canvas.OrgX;
	Y = C.Owner.MousePosition.Y - Canvas.OrgY;
	
	bCheckMouse = (X>0.f && X<C.CompPos[2] && Y>0.f && Y<C.CompPos[3]);
	
	Canvas.Font = PickFont(DefaultFontSize,TextScale);

	YP = Edge;
	C.CurrentRow = -1;

	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for( i=0; i<C.ItemRows.Length; ++i )
	{
		if( bCheckMouse && Y>=YP && Y<=(YP+DefaultHeight) )
		{
			bCheckMouse = false;
			C.CurrentRow = i;
			Canvas.SetPos(4.f,YP);
			Canvas.SetDrawColor(128,48,48,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),DefaultHeight);
		}

		Canvas.SetPos(Edge,YP);
		if( C.ItemRows[i].bSplitter )
		{
			Canvas.SetDrawColor(0,0,0,255);
			Canvas.DrawText("-------",,TextScale,TextScale);
		}
		else
		{
			if( C.ItemRows[i].bDisabled )
				Canvas.SetDrawColor(148,148,148,255);
			else Canvas.SetDrawColor(248,248,248,255);
			Canvas.DrawText(C.ItemRows[i].Text,,TextScale,TextScale);
		}
		
		YP+=DefaultHeight;
	}
	Canvas.PopMaskRegion();
	if( C.OldRow!=C.CurrentRow )
	{
		C.OldRow = C.CurrentRow;
		C.PlayMenuSound(MN_DropdownChange);
	}
}

function Font PickFont( byte i, out float Scaler )
{
	switch( i )
	{
	case 0:
		Scaler = 1;
		return DrawFonts[2];
	case 1:
		Scaler = 1;
		return DrawFonts[1];
	case 2:
		Scaler = 0.4;
		return DrawFonts[0];
	case 3:
		Scaler = 0.55;
		return DrawFonts[0];
	case 4:
		Scaler = 0.6;
		return DrawFonts[0];
	case 5:
		Scaler = 0.75;
		return DrawFonts[0];
	default:
		Scaler = 1.0;
		return DrawFonts[0];
	}
}

defaultproperties
{
	MaxFontScale=6
}