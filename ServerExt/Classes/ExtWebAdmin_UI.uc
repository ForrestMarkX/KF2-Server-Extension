// Webadmin playinfo config variables.
// Just an information holder.
Class ExtWebAdmin_UI extends Object
	transient;

/* List of PropTypes:
0 = Integer
1 = Boolean
2 = string
3 = multiline text field
*/
struct FWebAdminConfigInfo
{
	var byte PropType;
	var name PropName;
	var string UIName,UIDesc;
	var int NumElements;
	
	structdefaultproperties
	{
		NumElements=1
	}
};
struct FPropGroup
{
	var string PageName;
	var class<Object> ObjClass;
	var array<FWebAdminConfigInfo> Configs;
	var delegate<OnGetValue> GetValue;
	var delegate<OnSetValue> SetValue;
	var int Dupes;
};
var array<FPropGroup> ConfigList;

// Value accessors.
Delegate string OnGetValue( name PropName, int ElementIndex );
Delegate OnSetValue( name PropName, int ElementIndex, string Value );

final function Cleanup()
{
	ConfigList.Length = 0;
}
final function AddSettingsPage( string PageName, class<Object> Obj, const out array<FWebAdminConfigInfo> Configs, delegate<OnGetValue> GetFunc, delegate<OnSetValue> SetFunc )
{
	local int i;
	
	i = ConfigList.Find('PageName',PageName);
	if( i>=0 ) // Make sure no dupe pages.
		PageName $= "_"$(ConfigList[i].Dupes++);

	i = ConfigList.Length;
	ConfigList.Length = i+1;
	ConfigList[i].PageName = PageName;
	ConfigList[i].ObjClass = Obj;
	ConfigList[i].Configs = Configs;
	ConfigList[i].GetValue = GetFunc;
	ConfigList[i].SetValue = SetFunc;
}
final function bool HasConfigFor( class<Object> Obj )
{
	return (ConfigList.Find('ObjClass',Obj)>=0);
}
