Class ExtPlayerReplicationInfo extends KFPlayerReplicationInfo;

struct FCustomCharEntry
{
	var bool bLock;
	var KFCharacterInfo_Human Char;
	var ObjectReferencer Ref;
};
struct FMyCustomChar // Now without constant.
{
	var int CharacterIndex,HeadMeshIndex,HeadSkinIndex,BodyMeshIndex,BodySkinIndex,AttachmentMeshIndices[`MAX_COSMETIC_ATTACHMENTS],AttachmentSkinIndices[`MAX_COSMETIC_ATTACHMENTS];
	
	structdefaultproperties
	{
		CharacterIndex=255
		AttachmentMeshIndices[0]=255
		AttachmentMeshIndices[1]=255
		AttachmentMeshIndices[2]=255
	}
};

// For custom trader inventory.
struct FCustomTraderItem
{
	var class<KFWeaponDefinition> WeaponDef;
	var class<KFWeapon> WeaponClass;
};

var bool bIsMuted,bInitialPT,bIsDev,bHiddenUser,bClientUseCustom,bClientFirstChar,bClientCharListDone,bClientInitChars;

var int RespawnCounter;
var byte AdminType;
var class<Ext_PerkBase> ECurrentPerk;
var Ext_PerkBase FCurrentPerk;
var int ECurrentPerkLevel,ECurrentPerkPrestige;
var ExtPerkManager PerkManager;
/* AdminTypes:
	0 - Super Admin (server owner)
	1 - Admin
	2 - Moderator
	3 - Trusted member
	4 - VIP
*/

var string TaggedPlayerName;
var repnotify string NameTag;
var repnotify byte RepLevelProgress;
var transient color HUDPerkColor;
var byte FixedData;
var int RepPlayTime,RepKills,RepEXP;

// Custom character stuff.
var array<FCustomCharEntry> CustomCharList;
var repnotify FMyCustomChar CustomCharacter;
var transient array<ExtCharDataInfo> SaveDataObjects;
var transient ExtPlayerReplicationInfo LocalOwnerPRI; // Local playercontroller owner PRI

// Custom trader inventory
var KFGFxObject_TraderItems CustomList;
var array<FCustomTraderItem> CustomItems;

// Supplier data:
var transient struct FSupplierData
{
	var transient Pawn SuppliedPawn;
	var transient float NextSupplyTimer;
} SupplierLimit;
var repnotify class<Ext_TraitSupply> HasSupplier;

replication
{
	// Things the server should send to the client.
	if ( true )
		RespawnCounter,AdminType,ECurrentPerk,ECurrentPerkLevel,ECurrentPerkPrestige,RepKills,RepEXP,RepLevelProgress,bIsDev,NameTag,FixedData,bHiddenUser,CustomCharacter,HasSupplier;
	if (bNetInitial || bInitialPT)
		RepPlayTime;
}

simulated function PostBeginPlay()
{
	local PlayerController PC;

	Super.PostBeginPlay();
	SetTimer(1,true,'TickPT');
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		HUDPerkColor = PickPerkColor();
		PC = GetALocalPlayerController();
		if( PC!=None )
			LocalOwnerPRI = ExtPlayerReplicationInfo(PC.PlayerReplicationInfo);
	}
	else LocalOwnerPRI = Self; // Dedicated server can use self PRI.
}

// Resupply traits:
simulated final function bool CanUseSupply( Pawn P )
{
	return (SupplierLimit.SuppliedPawn!=P || SupplierLimit.NextSupplyTimer<WorldInfo.TimeSeconds);
}
simulated final function UsedSupply( Pawn P, float NextTime )
{
	SupplierLimit.SuppliedPawn = P;
	SupplierLimit.NextSupplyTimer = WorldInfo.TimeSeconds+NextTime;
}

simulated function ClientInitialize(Controller C)
{
	local ExtPlayerReplicationInfo PRI;

	Super.ClientInitialize(C);
	
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		LocalOwnerPRI = Self;

		// Make all other PRI's load character list from local owner PRI.
		foreach DynamicActors(class'ExtPlayerReplicationInfo',PRI)
			PRI.LocalOwnerPRI = Self;
	}
}

simulated function TickPT()
{
	++RepPlayTime;
}

simulated event ReplicatedEvent(name VarName)
{
	switch( VarName )
	{
	case 'RepLevelProgress':
		HUDPerkColor = PickPerkColor();
		break;
	case 'CustomCharacter':
		CharacterCustomizationChanged();
		break;
	case 'HasSupplier':
		SupplierLimit.SuppliedPawn = None; // Reset if stat was changed.
		break;
	case 'PlayerName':
	case 'NameTag':
		UpdateNameTag();
	default:
		Super.ReplicatedEvent(VarName);
	}
}
function SetPlayerName(string S)
{
	Super.SetPlayerName(S);
	UpdateNameTag();
}
function SetPlayerNameTag( string S )
{
	NameTag = S;
	UpdateNameTag();
}
function OverrideWith(PlayerReplicationInfo PRI)
{
	Super.OverrideWith(PRI);
	NameTag = ExtPlayerReplicationInfo(PRI).NameTag;
	bAdmin = PRI.bAdmin;
	AdminType = ExtPlayerReplicationInfo(PRI).AdminType;
	UpdateNameTag();
}
simulated final function UpdateNameTag()
{
	if( NameTag!="" )
		TaggedPlayerName = "["$NameTag$"] "$PlayerName;
	else TaggedPlayerName = PlayerName;
}
final function SetLevelProgress( int CurLevel, int CurPrest, int MinLevel, int MaxLevel )
{
	local float V;

	ECurrentPerkLevel = CurLevel;
	ECurrentPerkPrestige = CurPrest;
	V = FClamp((float(CurLevel-MinLevel) / float(MaxLevel-MinLevel))*255.f,0,255);
	RepLevelProgress = V;
	bForceNetUpdate = true;

	if( WorldInfo.NetMode!=NM_DedicatedServer )
		HUDPerkColor = PickPerkColor();
}
simulated final function string GetPerkLevelStr()
{
	return (ECurrentPerkPrestige>0 ? (string(ECurrentPerkPrestige)$"-"$string(ECurrentPerkLevel)) : string(ECurrentPerkLevel));
}
simulated final function color PickPerkColor()
{
	local float P;
	local byte i;
	
	if( RepLevelProgress==0 )
		return MakeColor(255,255,255,255);
	P = float(RepLevelProgress) / 255.f;
	if( P<0.25f ) // White - Blue
	{
		i = 255 - (P*1020.f);
		return MakeColor(i,i,255,255);
	}
	if( P<0.5f ) // Blue - Green
	{
		i = ((P-0.25f)*1020.f);
		return MakeColor(0,i,255-i,255);
	}
	if( P<0.75f ) // Green - Red
	{
		i = ((P-0.5f)*1020.f);
		return MakeColor(i,255-i,0,255);
	}
	// Red - Yellow
	i = ((P-0.75f)*1020.f);
	return MakeColor(255,i,0,255);
}

function SetInitPlayTime( int T )
{
	bInitialPT = true;
	bForceNetUpdate = true;
	RepPlayTime = T;
	SetTimer(5,false,'UnsetPT');
}
function UnsetPT()
{
	bInitialPT = false;
}

Delegate bool OnRepNextItem( ExtPlayerReplicationInfo PRI, int RepIndex )
{
	return false;
}
simulated reliable client function ClientAddTraderItem( int Index, FCustomTraderItem Item )
{
	// Make sure to not execute on server.
	if( WorldInfo.NetMode!=NM_Client && (PlayerController(Owner)==None || LocalPlayer(PlayerController(Owner).Player)==None) )
		return;

	if( CustomList==None )
	{
		CustomList = CreateNewList();
		RecheckGRI();
	}
	CustomItems.AddItem(Item);
	SetWeaponInfo(false,Index,Item,CustomList);
}
simulated static final function KFGFxObject_TraderItems CreateNewList()
{
	local KFGFxObject_TraderItems L,B;
	
	B = class'KFGameReplicationInfo'.Default.TraderItems;
	L = new(B) class'KFGFxObject_TraderItems'; // Make clone of list.
	L.SaleItems = B.SaleItems;
	L.ArmorPrice = B.ArmorPrice;
	L.GrenadePrice = B.GrenadePrice;

	return L;
}
simulated static final function SetWeaponInfo( bool bDedicated, int Index, FCustomTraderItem Item, KFGFxObject_TraderItems List )
{
	local array<STraderItemWeaponStats> S;

	if( List.SaleItems.Length<=Index )
		List.SaleItems.Length = Index+1;

	List.SaleItems[Index].WeaponDef = Item.WeaponDef;
	List.SaleItems[Index].ClassName = Item.WeaponClass.Name;
	if( class<KFWeap_DualBase>(Item.WeaponClass)!=None && class<KFWeap_DualBase>(Item.WeaponClass).Default.SingleClass!=None )
		List.SaleItems[Index].SingleClassName = class<KFWeap_DualBase>(Item.WeaponClass).Default.SingleClass.Name;
	else List.SaleItems[Index].SingleClassName = '';
	List.SaleItems[Index].DualClassName = Item.WeaponClass.Default.DualClass!=None ? Item.WeaponClass.Default.DualClass.Name : '';
	List.SaleItems[Index].AssociatedPerkClasses = Item.WeaponClass.Static.GetAssociatedPerkClasses();
	List.SaleItems[Index].MagazineCapacity = Item.WeaponClass.Default.MagazineCapacity[0];
	List.SaleItems[Index].InitialSpareMags = Item.WeaponClass.Default.InitialSpareMags[0];
	List.SaleItems[Index].MaxSpareAmmo = Item.WeaponClass.Default.SpareAmmoCapacity[0];
	List.SaleItems[Index].MaxSecondaryAmmo = Item.WeaponClass.Default.MagazineCapacity[1] * Item.WeaponClass.Default.SpareAmmoCapacity[1];
	List.SaleItems[Index].BlocksRequired = Item.WeaponClass.Default.InventorySize;
	List.SaleItems[Index].ItemID = Index;
	
	if( !bDedicated )
	{
		List.SaleItems[Index].SecondaryAmmoImagePath = Item.WeaponClass.Default.SecondaryAmmoTexture!=None ? "img://"$PathName(Item.WeaponClass.Default.SecondaryAmmoTexture) : "";
		List.SaleItems[Index].TraderFilter = Item.WeaponClass.Static.GetTraderFilter();
		List.SaleItems[Index].InventoryGroup = Item.WeaponClass.Default.InventoryGroup;
		List.SaleItems[Index].GroupPriority = Item.WeaponClass.Default.GroupPriority;
		Item.WeaponClass.Static.SetTraderWeaponStats(S);
		List.SaleItems[Index].WeaponStats = S;
	}
}

simulated function RecheckGRI()
{
	local ExtPlayerController PC;

	if( KFGameReplicationInfo(WorldInfo.GRI)==None )
		SetTimer(0.1,false,'RecheckGRI');
	else
	{
		KFGameReplicationInfo(WorldInfo.GRI).TraderItems = CustomList;
		foreach LocalPlayerControllers(class'ExtPlayerController',PC)
			if( PC.PurchaseHelper!=None )
				PC.PurchaseHelper.TraderItems = CustomList;
	}
}

simulated final function bool ShowAdminName()
{
	return (bAdmin || AdminType<255);
}
simulated function string GetAdminName()
{
	switch( AdminType )
	{
	case 0:
		return "Super Admin";
	case 1:
	case 255:
		return "Admin";
	case 2:
		return "Mod";
	case 3:
		return "Trusted Member";
	case 4:
		return "VIP";
	}
}
simulated function string GetAdminNameAbr()
{
	switch( AdminType )
	{
	case 0:
		return "S";
	case 1:
	case 255:
		return "A";
	case 2:
		return "M";
	case 3:
		return "T";
	case 4:
		return "V";
	}
}
simulated function string GetAdminColor()
{
	switch( AdminType )
	{
	case 0:
		return "FF6600";
	case 1:
	case 255:
		return "40FFFF";
	case 2:
		return "FF33FF";
	case 3:
		return "FF0000";
	case 4:
		return "FFD700";
	}
}
simulated function color GetAdminColorC()
{
	switch( AdminType )
	{
	case 0:
		return MakeColor(255,102,0,255);
	case 1:
	case 255:
		return MakeColor(64,255,255,255);
	case 2:
		return MakeColor(255,51,255,255);
	case 3:
		return MakeColor(255,0,0,255);
	case 4:
		return MakeColor(255,215,0,255);
	}
}

simulated function string GetHumanReadableName()
{
	return TaggedPlayerName;
}

function SetFixedData( byte M )
{
	OnModeSet(Self,M);
	FixedData = FixedData | M;
	SetTimer(5,false,'ClearFixed');
}
function ClearFixed()
{
	FixedData = 0;
}
simulated final function string GetDesc()
{
	local string S;
	
	if( (FixedData & 1)!=0 )
		S = "A.";
	if( (FixedData & 2)!=0 )
		S $= "WF.";
	if( (FixedData & 4)!=0 )
		S $= "G.";
	if( (FixedData & 8)!=0 )
		S $= "NW.";
	if( (FixedData & 16)!=0 )
		S $= "WA.";
	return S;
}
delegate OnModeSet( ExtPlayerReplicationInfo PRI, byte Num );

simulated final function bool LoadPlayerCharacter( byte CharIndex, out FMyCustomChar CharInfo )
{
	local KFCharacterInfo_Human C;

	if( CharIndex>=(CharacterArchetypes.Length+CustomCharList.Length) )
		return false;

	if( SaveDataObjects.Length<=CharIndex )
		SaveDataObjects.Length = CharIndex+1;
	if( SaveDataObjects[CharIndex]==None )
	{
		C = (CharIndex<CharacterArchetypes.Length) ? CharacterArchetypes[CharIndex] : CustomCharList[CharIndex-CharacterArchetypes.Length].Char;
		SaveDataObjects[CharIndex] = new(None,PathName(C)) class'ExtCharDataInfo';
	}
	CharInfo = SaveDataObjects[CharIndex].LoadData();
	return true;
}
simulated final function bool SavePlayerCharacter()
{
	local KFCharacterInfo_Human C;

	if( CustomCharacter.CharacterIndex>=(CharacterArchetypes.Length+CustomCharList.Length) )
		return false;

	if( SaveDataObjects.Length<=CustomCharacter.CharacterIndex )
		SaveDataObjects.Length = CustomCharacter.CharacterIndex+1;
	if( SaveDataObjects[CustomCharacter.CharacterIndex]==None )
	{
		C = (CustomCharacter.CharacterIndex<CharacterArchetypes.Length) ? CharacterArchetypes[CustomCharacter.CharacterIndex] : CustomCharList[CustomCharacter.CharacterIndex-CharacterArchetypes.Length].Char;
		SaveDataObjects[CustomCharacter.CharacterIndex] = new(None,PathName(C)) class'ExtCharDataInfo';
	}
	SaveDataObjects[CustomCharacter.CharacterIndex].SaveData(CustomCharacter);
	return true;
}
simulated function ChangeCharacter( byte CharIndex, optional bool bFirstSet )
{
	local FMyCustomChar NewChar;
	local byte i;

	if( CharIndex>=(CharacterArchetypes.Length+CustomCharList.Length) || IsClientCharLocked(CharIndex) )
		CharIndex = 0;

	if( bFirstSet && RepCustomizationInfo.CharacterIndex==CharIndex )
	{
		// Copy properties from default character info.
		NewChar.HeadMeshIndex = RepCustomizationInfo.HeadMeshIndex;
		NewChar.HeadSkinIndex = RepCustomizationInfo.HeadSkinIndex;
		NewChar.BodyMeshIndex = RepCustomizationInfo.BodyMeshIndex;
		NewChar.BodySkinIndex = RepCustomizationInfo.BodySkinIndex;
		for( i=0; i<`MAX_COSMETIC_ATTACHMENTS; ++i )
		{
			NewChar.AttachmentMeshIndices[i] = RepCustomizationInfo.AttachmentMeshIndices[i];
			NewChar.AttachmentSkinIndices[i] = RepCustomizationInfo.AttachmentSkinIndices[i];
		}
	}
	if( LoadPlayerCharacter(CharIndex,NewChar) )
	{
		NewChar.CharacterIndex = CharIndex;
		CustomCharacter = NewChar;
		ServerSetCharacterX(NewChar);
		if( WorldInfo.NetMode==NM_Client )
			CharacterCustomizationChanged();
	}
}
simulated function UpdateCustomization( byte Type, byte MeshIndex, byte SkinIndex, optional byte SlotIndex )
{
	switch( Type )
	{
	case CO_Head:
		CustomCharacter.HeadMeshIndex = MeshIndex;
		CustomCharacter.HeadSkinIndex = SkinIndex;
		break;
	case CO_Body:
		CustomCharacter.BodyMeshIndex = MeshIndex;
		CustomCharacter.BodySkinIndex = SkinIndex;
		break;
	case CO_Attachment:
		CustomCharacter.AttachmentMeshIndices[SlotIndex] = MeshIndex;
		CustomCharacter.AttachmentSkinIndices[SlotIndex] = SkinIndex;
		break;
	}
	SavePlayerCharacter();
	ServerSetCharacterX(CustomCharacter);
	if( WorldInfo.NetMode==NM_Client )
		CharacterCustomizationChanged();
}
simulated final function RemoveAttachments()
{
	local byte i;

	for( i=0; i<`MAX_COSMETIC_ATTACHMENTS; ++i )
	{
		CustomCharacter.AttachmentMeshIndices[i] = `CLEARED_ATTACHMENT_INDEX;
		CustomCharacter.AttachmentSkinIndices[i] = 0;
	}
	SavePlayerCharacter();
	ServerSetCharacterX(CustomCharacter);
	if( WorldInfo.NetMode==NM_Client )
		CharacterCustomizationChanged();
}
simulated function ClearCharacterAttachment(int AttachmentIndex)
{
	if( UsesCustomChar() )
	{
		CustomCharacter.AttachmentMeshIndices[AttachmentIndex] = `CLEARED_ATTACHMENT_INDEX;
		CustomCharacter.AttachmentSkinIndices[AttachmentIndex] = 0;
	}
	else Super.ClearCharacterAttachment(AttachmentIndex);
}

reliable server final function ServerSetCharacterX( FMyCustomChar NewMeshInfo )
{
	if( NewMeshInfo.CharacterIndex>=(CharacterArchetypes.Length+CustomCharList.Length) || IsClientCharLocked(NewMeshInfo.CharacterIndex) )
		return;

	CustomCharacter = NewMeshInfo;

    if ( Role == Role_Authority )
    {
		CharacterCustomizationChanged();
    }
}
simulated final function bool IsClientCharLocked( byte Index )
{
	if( Index<CharacterArchetypes.Length )
		return false;
	Index-=CharacterArchetypes.Length;
	return (Index<CustomCharList.Length && CustomCharList[Index].bLock && !ShowAdminName());
}

simulated reliable client function ReceivedCharacter( byte Index, FCustomCharEntry C )
{
	if( WorldInfo.NetMode==NM_DedicatedServer )
		return;

	if( CustomCharList.Length<=Index )
		CustomCharList.Length = Index+1;
	CustomCharList[Index] = C;
}

simulated reliable client function AllCharReceived()
{
	if( WorldInfo.NetMode==NM_DedicatedServer )
		return;

	if( !bClientInitChars )
	{
		OnCharListDone();
		NotifyCharListDone();
		bClientInitChars = true;
	}
}
simulated final function NotifyCharListDone()
{
	local KFPawn_Human KFP;
	local KFCharacterInfo_Human NewCharArch;
	local ExtPlayerReplicationInfo EPRI;

	foreach WorldInfo.AllPawns(class'KFPawn_Human', KFP)
	{
		EPRI = ExtPlayerReplicationInfo(KFP.PlayerReplicationInfo);
		if( EPRI!=None )
		{
			NewCharArch = EPRI.GetSelectedArch();

			if( NewCharArch != KFP.CharacterArch )
			{
				// selected a new character
				KFP.SetCharacterArch( NewCharArch );
			}
			else if( WorldInfo.NetMode != NM_DedicatedServer )
			{
				// refresh cosmetics only
				class'ExtCharacterInfo'.Static.SetCharacterMeshFromArch( NewCharArch, KFP, EPRI );
			}
		}
	}
}

simulated delegate OnCharListDone();

// Player has a server specific setting for a character selected.
simulated final function bool UsesCustomChar()
{
	if( LocalOwnerPRI==None )
		return false; // Not yet init on client.
	return CustomCharacter.CharacterIndex<(LocalOwnerPRI.CustomCharList.Length+CharacterArchetypes.Length);
}

// Client uses a server specific custom character.
simulated final function bool ReallyUsingCustomChar()
{
	if( !UsesCustomChar() )
		return false;
	return (CustomCharacter.CharacterIndex>=CharacterArchetypes.Length);
}
simulated final function KFCharacterInfo_Human GetSelectedArch()
{
	if( UsesCustomChar() )
		return (CustomCharacter.CharacterIndex<CharacterArchetypes.Length) ? CharacterArchetypes[CustomCharacter.CharacterIndex] : LocalOwnerPRI.CustomCharList[CustomCharacter.CharacterIndex-CharacterArchetypes.Length].Char;
	return CharacterArchetypes[RepCustomizationInfo.CharacterIndex];
}

simulated event CharacterCustomizationChanged()
{
	local KFPawn_Human KFP;
	local KFCharacterInfo_Human NewCharArch;

	foreach WorldInfo.AllPawns(class'KFPawn_Human', KFP)
	{
		if( KFP.PlayerReplicationInfo == self || (KFP.DrivenVehicle != None && KFP.DrivenVehicle.PlayerReplicationInfo == self) )
		{
			NewCharArch = GetSelectedArch();

			if( NewCharArch != KFP.CharacterArch )
			{
				// selected a new character
				KFP.SetCharacterArch( NewCharArch );
			}
			else if( WorldInfo.NetMode != NM_DedicatedServer )
			{
				// refresh cosmetics only
				class'ExtCharacterInfo'.Static.SetCharacterMeshFromArch( NewCharArch, KFP, self );
			}
		}
	}
}

// Save/Load custom character information.
final function SaveCustomCharacter( ExtSaveDataBase Data )
{
	local byte i,c;
	local string S;

	// Write the name of custom character.
	if( UsesCustomChar() )
		S = string(GetSelectedArch().Name);
	Data.SaveStr(S);
	if( S=="" )
		return;
	
	// Write selected accessories.
	Data.SaveInt(CustomCharacter.HeadMeshIndex);
	Data.SaveInt(CustomCharacter.HeadSkinIndex);
	Data.SaveInt(CustomCharacter.BodyMeshIndex);
	Data.SaveInt(CustomCharacter.BodySkinIndex);
	
	c = 0;
	for( i=0; i<`MAX_COSMETIC_ATTACHMENTS; ++i )
	{
		if( CustomCharacter.AttachmentMeshIndices[i]!=255 )
			++c;
	}

	// Write attachments count.
	Data.SaveInt(c);
	
	// Write attachments.
	for( i=0; i<`MAX_COSMETIC_ATTACHMENTS; ++i )
	{
		if( CustomCharacter.AttachmentMeshIndices[i]!=255 )
		{
			Data.SaveInt(i);
			Data.SaveInt(CustomCharacter.AttachmentMeshIndices[i]);
			Data.SaveInt(CustomCharacter.AttachmentSkinIndices[i]);
		}
	}
}
final function LoadCustomCharacter( ExtSaveDataBase Data )
{
	local string S;
	local byte i,n,j;

	if( Data.GetArVer()>=2 )
		S = Data.ReadStr();
	if( S=="" ) // Stock skin.
		return;

	for( i=0; i<CharacterArchetypes.Length; ++i )
	{
		if( string(CharacterArchetypes[i].Name)~=S )
			break;
	}
	
	if( i==CharacterArchetypes.Length )
	{
		for( i=0; i<CustomCharList.Length; ++i )
		{
			if( string(CustomCharList[i].Char.Name)~=S )
				break;
		}
		if( i==CharacterArchetypes.Length )
		{
			// Character not found = Skip data.
			Data.SkipBytes(4);
			n = Data.ReadInt();
			for( i=0; i<n; ++i )
				Data.SkipBytes(3);
			return;
		}
		i+=CharacterArchetypes.Length;
	}

	CustomCharacter.CharacterIndex = i;
	CustomCharacter.HeadMeshIndex = Data.ReadInt();
	CustomCharacter.HeadSkinIndex = Data.ReadInt();
	CustomCharacter.BodyMeshIndex = Data.ReadInt();
	CustomCharacter.BodySkinIndex = Data.ReadInt();

	n = Data.ReadInt();
	for( i=0; i<n; ++i )
	{
		j = Min(Data.ReadInt(),`MAX_COSMETIC_ATTACHMENTS-1);
		CustomCharacter.AttachmentMeshIndices[j] = Data.ReadInt();
		CustomCharacter.AttachmentSkinIndices[j] = Data.ReadInt();
	}
	bNetDirty = true;
}

// Only used to skip offset (in case of an error).
static final function DummyLoadChar( ExtSaveDataBase Data )
{
	local string S;
	local byte i,n;

	if( Data.GetArVer()>=2 )
		S = Data.ReadStr();
	if( S=="" ) // Stock skin.
		return;

	Data.SkipBytes(4);
	n = Data.ReadInt();
	for( i=0; i<n; ++i )
		Data.SkipBytes(3);
}
static final function DummySaveChar( ExtSaveDataBase Data )
{
	Data.SaveStr("");
}

// Set admin levels without having to hard-reference to this mod.
event BeginState(Name N)
{
	switch( N )
	{
	case 'Global':
		AdminType = 0;
		break;
	case 'Admin':
		AdminType = 1;
		break;
	case 'Mod':
		AdminType = 2;
		break;
	case 'TMem':
		AdminType = 3;
		break;
	case 'VIP':
		AdminType = 4;
		break;
	case 'User':
		AdminType = 255;
		break;
	}
}

defaultproperties
{
	RespawnCounter=-1
	AdminType=255
	TaggedPlayerName="Player"
}