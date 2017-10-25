Class KFGUI_Button_CD extends KFGUI_Button;

function DrawMenu()
{
	local float XL,YL,TS;
	local byte i, FrameOpacity;
	
	FrameOpacity = 200;
	if( bDisabled )
		Canvas.SetDrawColor(10, 10, 10, FrameOpacity);
	else if( bPressedDown )
		Canvas.SetDrawColor(20, 20, 20, FrameOpacity);
	else if( bFocused )
		Canvas.SetDrawColor(75, 75, 75, FrameOpacity);
	else Canvas.SetDrawColor(45, 45, 45, FrameOpacity);
	
	if( bIsHighlighted )
	{
		Canvas.DrawColor.R = Min(Canvas.DrawColor.R + 25, FrameOpacity);
        Canvas.DrawColor.G = Min(Canvas.DrawColor.G + 25, FrameOpacity);
        Canvas.DrawColor.B = Min(Canvas.DrawColor.B + 25, FrameOpacity);
	}

	Canvas.SetPos(0.f,0.f);
	if( ExtravDir==255 )
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	else Owner.CurrentStyle.DrawRectBox(0,0,CompPos[2],CompPos[3],Min(CompPos[2],CompPos[3])*0.2,ExtravDir);

	if( OverlayTexture.Texture!=None )
	{
		Canvas.SetPos(0.f,0.f);
		Canvas.DrawTile(OverlayTexture.Texture,CompPos[2],CompPos[3],OverlayTexture.U,OverlayTexture.V,OverlayTexture.UL,OverlayTexture.VL);
	}
	if( ButtonText!="" )
	{
		// Chose the best font to fit this button.
		i = Min(FontScale+Owner.CurrentStyle.DefaultFontSize,Owner.CurrentStyle.MaxFontScale);
		while( true )
		{
			Canvas.Font = Owner.CurrentStyle.PickFont(i,TS);
			Canvas.TextSize(ButtonText,XL,YL,TS,TS);
			if( i==0 || (XL<(CompPos[2]*0.95) && YL<(CompPos[3]*0.95)) )
				break;
			--i;
		}
		Canvas.SetPos((CompPos[2]-XL)*0.5,(CompPos[3]-YL)*0.5);
		if( bDisabled )
			Canvas.DrawColor = TextColor*0.5f;
		else Canvas.DrawColor = TextColor;
		Canvas.DrawText(ButtonText,,TS,TS,TextFontInfo);
	}
}

defaultproperties
{
}