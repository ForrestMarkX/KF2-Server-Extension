Class KFGUI_NumericBox extends KFGUI_EditBox;

var() float MaxValue,MinValue;
var() bool bFloatValue;

function InitMenu()
{
	Super.InitMenu();
	ValidateValue();
}
final function int GetValueInt()
{
	return int(Value);
}
final function float GetValueFloat()
{
	return float(Value);
}

function ChangeValue( string V )
{
	Super.ChangeValue(V);
	ValidateValue();
}
final function ValidateValue()
{
	if( bFloatValue )
		Value = string(FClamp(float(Value),MinValue,MaxValue));
	else Value = string(Clamp(int(Value),MinValue,MaxValue));
}

function bool NotifyInputChar( int ControllerId, string Unicode )
{
	ControllerId = Asc(Unicode);
	if( (ControllerId>=48 && ControllerId<=57) || ControllerId==46 )
		Super.NotifyInputChar(ControllerId,Unicode);
	return true;
}

function LostKeyFocus()
{
	ValidateValue();
	Super.LostKeyFocus();
}

defaultproperties
{
	MaxValue=9999999
	MaxTextLength=7
}