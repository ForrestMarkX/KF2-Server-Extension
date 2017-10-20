Class MS_Input extends PlayerInput;

event bool FilterButtonInput(int ControllerId, Name Key, EInputEvent Event, float AmountDepressed, bool bGamepad)
{
	if ( Event==IE_Pressed && (Key == 'Escape' || Key == 'XboxTypeS_Start') )
	{
		MS_PC(Outer).AbortConnection();
		return true;
	}
	return false;
}

defaultproperties
{
	OnReceivedNativeInputKey=FilterButtonInput
}