class ExtMenu_Gear extends KFGFxObject_Menu;

var ExtPlayerReplicationInfo ExtPRI;

var KFGFxObject_TraderItems TraderItems;
var KFGFxGearContainer_PerksSelection PerkSelectionContainer;
var KFCharacterInfo_Human CurrentCharInfo;
var string CharInfoPath;
var int CurrentPerkIndex;
var array<class<KFWeaponDefinition> > CurrentWearponDefList;
var array<Emote> EmoteList;

var bool bWaitingCharList,bIsCustomChar;

function InitializeMenu( KFGFxMoviePlayer_Manager InManager )
{
    super(KFGFxObject_Menu).InitializeMenu(InManager);
    CheckForCustomizationPawn( GetPC() );
    LocalizeText();
    EmoteList = class'ExtEmoteList'.static.GetEmoteArray();
    InitCharacterMenu();
    TraderItems = KFGameReplicationInfo( GetPC().WorldInfo.GRI ).TraderItems;
}
function InitCharacterMenu()
{
    ExtPRI = ExtPlayerReplicationInfo(GetPC().PlayerReplicationInfo);
    
    if( ExtPRI!=None && ExtPRI.bClientInitChars )
        CharListRecieved();
    else if( ExtPRI==None )
    {
        if( GetPC().PlayerReplicationInfo!=None ) // Faulty mod setup.
        {
            bWaitingCharList = true;
            return;
        }
        GetPC().SetTimer(0.1,false,'InitCharacterMenu',Self);
    }
    else
    {
        ExtPRI.OnCharListDone = CharListRecieved;
        bWaitingCharList = true;
    }
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{    
    switch(WidgetName)
    {
    case 'perkSelectionContainer':
        if ( PerkSelectionContainer == none )
        {
            PerkSelectionContainer = KFGFxGearContainer_PerksSelection( Widget );
            PerkSelectionContainer.Initialize(self);
        }
        break;
    }

    return true;
}

function OnOpen()
{
    local PlayerController PC;

    PC = GetPC();
    if( PC == none )
        return;
        
    CheckForCustomizationPawn( PC );
    //GetGameViewportClient().HandleInputAxis = OnAxisModified;

    if ( PC.PlayerReplicationInfo.bReadyToPlay && PC.WorldInfo.GRI.bMatchHasBegun )
    {
        // Players cannot change characters if they are in a game
        SetBool("characterButtonEnabled", false);
    }
}

/** The customization pawn won't exist if this menu was opened mid-match */
function CheckForCustomizationPawn( PlayerController PC )
{
    local KFPlayerController KFPC;

    if( PC.Pawn == None || (!PC.Pawn.IsAliveAndWell() && KFPawn_Customization(PC.Pawn) == None) )
    {
        KFPC = KFPlayerController( PC );
        if( KFPC != None )
        {
            KFPC.SpawnMidGameCustomizationPawn();
        }
    }    
}

function LocalizeText()
{
    local GFxObject LocalizedObject;

    LocalizedObject = CreateObject("Object");

    LocalizedObject.SetString("header", class'KFGFxMenu_Gear'.Default.GearHeaderString);
    LocalizedObject.SetString("listButton", class'KFGFxMenu_Gear'.Default.BackString);
    LocalizedObject.SetString("bioStringText", class'KFGFxMenu_Gear'.Default.BioString);
    LocalizedObject.SetString("charactersString", class'KFGFxMenu_Gear'.Default.CharacterString);
    LocalizedObject.SetString("headsString", class'KFGFxMenu_Gear'.Default.HeadString);
    LocalizedObject.SetString("emoteString", Class'KFLocalMessage_VoiceComms'.default.VoiceCommsOptionStrings[8]);
    LocalizedObject.SetString("bodiesString", class'KFGFxMenu_Gear'.Default.BodyString);
    LocalizedObject.SetString("skinsString", class'KFGFxMenu_Gear'.Default.SkinsString);
    LocalizedObject.SetString("attachmentsString", class'KFGFxMenu_Gear'.Default.AttachmentsString);

    SetObject("localizeText", LocalizedObject);
}

simulated function CharListRecieved()
{
    UpdateCharacterList();    
    UpdateGear();
}

function UpdateEmoteList()
{
    local int ItemIndex, i;
    local GFxObject DataProvider, SlotObject;
    local string TexturePath;

    ItemIndex = 0;
    DataProvider = CreateArray();

    for (i = 0; i < EmoteList.length; i++)
    {
        if ( class'ExtEmoteList'.static.GetUnlockedEmote(EmoteList[i].Id, ExtPlayerController(GetPC())) != 'NONE')
        {
            SlotObject = CreateObject( "Object" );
            SlotObject.SetInt("ItemIndex", i);
            SlotObject.SetString("label", Localize(EmoteList[i].ItemName, "EmoteName", class'KFGFxMenu_Gear'.Default.KFCharacterInfoString));
            TexturePath = "img://"$EmoteList[i].IconPath;
            SlotObject.SetBool("enabled", true);
            SlotObject.SetString("source", TexturePath);
            DataProvider.SetElementObject(ItemIndex, SlotObject);
            ItemIndex++;
        }
        else
        {
            //`log(MyKFPRI.EmoteList[i] @ "is not purchased.");
        }
    }
    
    SetObject("emoteArray", DataProvider);
}

function UpdateCharacterList()
{
    local int i, ItemIndex;
    local GFxObject DataProvider, SlotObject;
    local string TexturePath;

    bWaitingCharList = false;
    ItemIndex = 0;
    DataProvider = CreateArray();
    for( i=0; i<ExtPRI.CharacterArchetypes.length; i++)
    {
        SlotObject = CreateObject( "Object" );
        SlotObject.SetInt("ItemIndex", i);
        SlotObject.SetString("label", Localize(String(ExtPRI.CharacterArchetypes[i].Name), "CharacterName", class'KFGFxMenu_Gear'.Default.KFCharacterInfoString));
        SlotObject.SetBool("enabled", true);
        TexturePath = "img://"$PathName(ExtPRI.CharacterArchetypes[i].DefaultHeadPortrait);
        SlotObject.SetString("source", TexturePath);
        DataProvider.SetElementObject(ItemIndex, SlotObject);
        ItemIndex++;
    }
    for( i=0; i<ExtPRI.CustomCharList.length; i++)
    {
        if( !ExtPRI.IsClientCharLocked(ExtPRI.CharacterArchetypes.length+i) )
        {
            SlotObject = CreateObject( "Object" );
            SlotObject.SetInt("ItemIndex", (ExtPRI.CharacterArchetypes.length+i));
            SlotObject.SetString("label", Repl(string(ExtPRI.CustomCharList[i].Char.Name),"_"," "));
            SlotObject.SetBool("enabled", true);
            TexturePath = "img://"$PathName(ExtPRI.CustomCharList[i].Char.DefaultHeadPortrait);
            SlotObject.SetString("source", TexturePath);
            DataProvider.SetElementObject(ItemIndex, SlotObject);
            ItemIndex++;
        }
    }
    
    SetObject("characterArray", DataProvider);
}

function UpdateGear()
{
    if( bWaitingCharList )
        return;

    CurrentCharInfo = ExtPRI.GetSelectedArch();
    bIsCustomChar = ExtPRI.ReallyUsingCustomChar();

    CharInfoPath = String(CurrentCharInfo.Name);
    // Set the list of usable bodies for this character
    UpdateMeshList(class'KFGFxMenu_Gear'.Default.BodyMeshKey, class'KFGFxMenu_Gear'.Default.BodySkinKey, CurrentCharInfo.BodyVariants, "bodyArray");
    // Set the list of usable heads for this character
    UpdateMeshList(class'KFGFxMenu_Gear'.Default.HeadMeshKey, class'KFGFxMenu_Gear'.Default.HeadSkinKey, CurrentCharInfo.HeadVariants, "headsArray");
    // Set the list of usable attachments for this character
    UpdateAttachmentsList(CurrentCharInfo.CosmeticVariants);
    
    UpdateEmoteList();

    SetCurrentCharacterButtons();
}

final function string GetMenuName( Object Obj )
{
    return Obj==None ? "Empty" : Repl(string(Obj.Name),"_"," ");
}
final function string GetMenuNameStr( string ObjName )
{
    local int i;
    
    i = InStr(ObjName,".",true);
    if( i!=-1 )
        ObjName = Mid(ObjName,i+1);
    return Repl(ObjName,"_"," ");
}

function UpdateMeshList(string OutfitKey, string SkinKey, array<OutfitVariants> Outfits, string DataArrayString)
{
    local int i, ItemIndex;
    local GFxObject DataProvider, SlotObject;
    local string TexturePath, OutfitName;
    local OutfitVariants Outfit;
    local SkinVariant FirstSkin;
    
    ItemIndex = 0;
    DataProvider = CreateArray();
    for (i = 0; i < Outfits.Length; i++)
    {
        Outfit = Outfits[i];
        
        OutfitName = Localize(CharInfoPath, OutfitKey$i, class'KFGFxMenu_Gear'.Default.KFCharacterInfoString);
        if( bIsCustomChar )
            OutfitName = GetMenuNameStr(Outfit.MeshName);
            
        if ( InStr(OutfitName, "?INT?") != -1 )
            continue;
        
        SlotObject = CreateObject( "Object" );
        SlotObject.SetInt("ItemIndex", i);
        SlotObject.SetString("label", OutfitName);
        SlotObject.SetBool("enabled", true);
        FirstSkin = UpdateOutfitVariants( OutfitKey, SkinKey, Outfit.SkinVariations, i, SlotObject );
        if( string(FirstSkin.UITexture) == "Bad" )
            continue;
            
        TexturePath = "img://"$PathName(FirstSkin.UITexture);
        SlotObject.SetString("source", TexturePath);

        DataProvider.SetElementObject(ItemIndex, SlotObject);
        ItemIndex++;
    }
    
    SetObject(DataArrayString, DataProvider);
}

function SkinVariant UpdateOutfitVariants(string OutfitKey, string KeyName, out array<SkinVariant> SkinVariations, int OutfitIndex, out GFxObject MeshObject)
{
    local int i, ItemIndex;
    local GFxObject DataProvider, SlotObject;
    local SkinVariant Skin;
    local SkinVariant FirstSkin;
    local string SectionPath;
    local string TexturePath;
    local bool bFoundFirst;

    ItemIndex = 0;
    DataProvider = CreateArray();
    SectionPath = CharInfoPath$"."$OutfitKey$OutfitIndex;    

    for (i = 0; i < SkinVariations.length; i++)
    {
        Skin = SkinVariations[i];
        if(!bFoundFirst)
        {
            FirstSkin = Skin;
            bFoundFirst = true;
        }
        SlotObject = CreateObject( "Object" );
        SlotObject.SetInt("ItemIndex", i);
        SlotObject.SetString("label", Localize(SectionPath, KeyName$i, class'KFGFxMenu_Gear'.Default.KFCharacterInfoString));
        TexturePath = "img://"$PathName(Skin.UITexture);
        SlotObject.SetBool("enabled", true);
        SlotObject.SetString("source", TexturePath);

        DataProvider.SetElementObject(ItemIndex, SlotObject);
        ItemIndex++;
    }
    MeshObject.SetObject("skinInfo", DataProvider);

    return FirstSkin;
}

function UpdateAttachmentsList(array<AttachmentVariants> Attachments)
{
    local int i, ItemIndex;
    local GFxObject DataProvider, SlotObject;
    local string TexturePath;
    local AttachmentVariants Variant;
    local Pawn MyPawn;
    local SkinVariant FirstSkin;
    local string AttachmentName;
    
    ItemIndex = 0;
    DataProvider = CreateArray();
    MyPawn = GetPC().Pawn;

    // Insert blank object
    SlotObject = CreateObject( "Object" );
    SlotObject.SetString("label", class'KFGFxMenu_Gear'.default.NoneString);
    SlotObject.SetString("source", "img://"$class'KFGFxMenu_Gear'.default.ClearImagePath);
    SlotObject.SetInt("ItemIndex", INDEX_NONE);
    SlotObject.SetBool("enabled", true);
    DataProvider.SetElementObject(ItemIndex, SlotObject);
    ItemIndex++;

    for (i = 0; i < Attachments.Length; i++)
    {
        Variant = Attachments[i];
        if ( class'ExtCharacterInfo'.static.IsAttachmentAvailable(CurrentCharInfo, Variant, MyPawn) )
        {
            SlotObject = CreateObject( "Object" );
            SlotObject.SetInt("ItemIndex", i);
            FirstSkin = UpdateCosmeticVariants( class'KFGFxMenu_Gear'.default.AttachmentKey, class'KFGFxMenu_Gear'.default.AttachmentSkinKey, Variant.AttachmentItem, i, SlotObject );
            AttachmentName = bIsCustomChar ? GetMenuNameStr(Variant.MeshName) : Localize(string(Variant.AttachmentItem.Name), class'KFGFxMenu_Gear'.default.AttachmentKey,  class'KFGFxMenu_Gear'.default.KFCharacterInfoString);
            SlotObject.SetString("label", AttachmentName);
            SlotObject.SetBool("enabled", true);
            TexturePath = "img://"$PathName(FirstSkin.UITexture);
            SlotObject.SetString("source", TexturePath);
            
            DataProvider.SetElementObject(ItemIndex, SlotObject);
            ItemIndex++;
        }
    }
    
    SetObject("attachmentsArray", DataProvider);
}

function SkinVariant UpdateCosmeticVariants(string OutfitKey, string KeyName, KFCharacterAttachment Attachment, int OutfitIndex, out GFxObject MeshObject)
{
    local int i, ItemIndex;
    local GFxObject DataProvider, SlotObject;
    local SkinVariant Skin;
    local SkinVariant FirstSkin;
    local string TexturePath;
    local bool bFoundFirst;
    local string SkinName;

    ItemIndex = 0;
    DataProvider = CreateArray();

    for (i = 0; i < Attachment.SkinVariations.length; i++)
    {
        Skin = Attachment.SkinVariations[i];
        if(!bFoundFirst)
        {
            FirstSkin = Skin;
            bFoundFirst = true;
        }
        SlotObject = CreateObject( "Object" );
        SlotObject.SetInt("ItemIndex", i);
        SkinName = Localize(string(Attachment.Name), KeyName$i, class'KFGFxMenu_Gear'.Default.KFCharacterInfoString);
        SlotObject.SetString("label", SkinName);
        TexturePath = "img://"$PathName(Skin.UITexture);
        SlotObject.SetBool("enabled", true);
        SlotObject.SetString("source", TexturePath);

        DataProvider.SetElementObject(ItemIndex, SlotObject);
        ItemIndex++;
    }
    MeshObject.SetObject("skinInfo", DataProvider);

    return FirstSkin;
}

function SetCurrentCharacterButtons()
{
    local bool bCustom;
    local GFxObject DataObject;
    local byte CharacterIndex, HeadMeshIndex, HeadSkinIndex, BodyMeshIndex, BodySkinIndex;

    bCustom = ExtPRI.UsesCustomChar();
    DataObject = CreateObject("Object");
    
    CharacterIndex = ExtPRI.RepCustomizationInfo.CharacterIndex;
    HeadMeshIndex = ExtPRI.RepCustomizationInfo.HeadMeshIndex;
    HeadSkinIndex = ExtPRI.RepCustomizationInfo.HeadSkinIndex;
    BodyMeshIndex = ExtPRI.RepCustomizationInfo.BodyMeshIndex;
    BodySkinIndex = ExtPRI.RepCustomizationInfo.BodySkinIndex;
    if( bCustom )
    {
        CharacterIndex = ExtPRI.CustomCharacter.CharacterIndex;
        HeadMeshIndex = ExtPRI.CustomCharacter.HeadMeshIndex;
        HeadSkinIndex = ExtPRI.CustomCharacter.HeadSkinIndex;
        BodyMeshIndex = ExtPRI.CustomCharacter.BodyMeshIndex;
        BodySkinIndex = ExtPRI.CustomCharacter.BodySkinIndex;
    }

    DataObject.SetString( "selectedCharacter", (bIsCustomChar ? Repl(string(CurrentCharInfo.Name),"_"," ") : Localize(CharInfoPath, "CharacterName", class'KFGFxMenu_Gear'.Default.KFCharacterInfoString)) );
    DataObject.SetString( "characterBio", (bIsCustomChar ? Repl(CurrentCharInfo.ArmMeshPackageName,"|","\n") : Localize(CharInfoPath, "Description", class'KFGFxMenu_Gear'.Default.KFCharacterInfoString)) );
    DataObject.SetInt( "selectedCharacterIndex", CharacterIndex );

    SetObject( "selectedCharacter", DataObject);

    //set head
    SetGearButtons(HeadMeshIndex, HeadSkinIndex, class'KFGFxMenu_Gear'.Default.HeadMeshKey, class'KFGFxMenu_Gear'.Default.HeadSkinKey, class'KFGFxMenu_Gear'.Default.HeadFunctionKey);
    //set body
    SetGearButtons(BodyMeshIndex, BodySkinIndex, class'KFGFxMenu_Gear'.Default.BodyMeshKey, class'KFGFxMenu_Gear'.Default.BodySkinKey, class'KFGFxMenu_Gear'.Default.BodyFunctionKey);
    //set attachments
    SetAttachmentButtons(class'KFGFxMenu_Gear'.Default.AttachmentKey, class'KFGFxMenu_Gear'.Default.AttachmentFunctionKey);
    
    SetEmoteButton();
}

function SetEmoteButton()
{
    local GFxObject DataObject;
    local int EmoteIndex;

    EmoteIndex = class'ExtEmoteList'.static.GetEmoteIndex( class'ExtEmoteList'.static.GetEquippedEmoteId(ExtPlayerController(GetPC())));

    DataObject = CreateObject("Object");
    if(EmoteIndex == 255)
    {
        DataObject.SetString( "selectedEmote", "");
        DataObject.SetInt( "selectedEmoteIndex", 0 );
    }
    else
    {
        DataObject.SetString( "selectedEmote", Localize(EmoteList[EmoteIndex].ItemName, "EmoteName", class'KFGFxMenu_Gear'.Default.KFCharacterInfoString));
        DataObject.SetInt( "selectedEmoteIndex", 0 );
    }
    

    SetObject("selectedEmote", DataObject);
}

/** Update the labels for our gear buttons */
function SetGearButtons(int MeshIndex, int SkinIndex, string MeshKey, string SkinKey, string sectionFunctionName)
{
    local string SectionPath;
    local string CurrentMesh;
    local string SkinName, MeshName;
    local GFxObject DataObject;

    if( bWaitingCharList )
        return;

    DataObject = CreateObject("Object");

    if(MeshIndex == `CLEARED_ATTACHMENT_INDEX)
    {
        DataObject.SetString( sectionFunctionName, class'KFGFxMenu_Gear'.Default.NoneString );
    }
    else if( bIsCustomChar )
    {
        if( MeshKey==class'KFGFxMenu_Gear'.Default.HeadMeshKey )
        {
            SkinName = GetMenuName(CurrentCharInfo.HeadVariants[MeshIndex].SkinVariations[SkinIndex].Skin);
            MeshName = GetMenuNameStr(CurrentCharInfo.HeadVariants[MeshIndex].MeshName);
        }
        else
        {
            SkinName = GetMenuName(CurrentCharInfo.BodyVariants[MeshIndex].SkinVariations[SkinIndex].Skin);
            MeshName = GetMenuNameStr(CurrentCharInfo.BodyVariants[MeshIndex].MeshName);
        }
        
        DataObject.SetString( sectionFunctionName,  MeshName @"\n" @SkinName );
    }
    else
    {
        CurrentMesh = MeshKey$MeshIndex;
        SectionPath = CharInfoPath$"."$CurrentMesh;

        SkinName = Localize(SectionPath, SkinKey$SkinIndex, class'KFGFxMenu_Gear'.Default.KFCharacterInfoString);
        MeshName = Localize(CharInfoPath, CurrentMesh, class'KFGFxMenu_Gear'.Default.KFCharacterInfoString);
        DataObject.SetString( sectionFunctionName,  MeshName @"\n" @SkinName );
    }

    DataObject.SetInt( (sectionFunctionName$"Index"), MeshIndex);
    DataObject.SetInt( (sectionFunctionName$"SkinIndex"), SkinIndex);

    SetObject( sectionFunctionName, DataObject);
}

/** Update the labels for our currently equipped attachments */
function SetAttachmentButtons(string AttachmentMeshKey, string sectionFunctionName)
{
    local GFxObject DataObject;
    local int i, AttachmentIndex;
    local bool bCustom;
    
    if( bWaitingCharList )
        return;
    
    bCustom = ExtPRI.UsesCustomChar();
    DataObject = CreateObject("Object");

    for(i = 0; i < `MAX_COSMETIC_ATTACHMENTS; i++)
    {
        AttachmentIndex = bCustom ? ExtPRI.CustomCharacter.AttachmentMeshIndices[i] : ExtPRI.RepCustomizationInfo.AttachmentMeshIndices[i];        
        if( AttachmentIndex == `CLEARED_ATTACHMENT_INDEX )
        {
            DataObject.SetString("selectedAttachment_"$i, "----");
        }
        else
        {
            DataObject.SetString("selectedAttachment_"$i, bIsCustomChar ? GetMenuNameStr(CurrentCharInfo.CosmeticVariants[AttachmentIndex].MeshName) : Localize(string(CurrentCharInfo.CosmeticVariants[AttachmentIndex].AttachmentItem.Name), AttachmentMeshKey, class'KFGFxMenu_Gear'.default.KFCharacterInfoString));
        }
    }    

    SetObject( sectionFunctionName, DataObject);
}

event OnClose()
{
    local PlayerController PC;

    super.OnClose();

    //GetGameViewportClient().HandleInputAxis = none;

    if ( class'WorldInfo'.static.IsMenuLevel() )
    {
        Manager.ManagerObject.SetBool("backgroundVisible", true);
    }

    // If we are alive, in game, with a playable pawn. switch back to first person view when leaving this menu
    PC = GetPC();
    if( PC != none && PC.WorldInfo.GRI.bMatchHasBegun && PC.Pawn != none && !PC.Pawn.IsA('KFPawn_Customization') )
    {
        PC.ServerCamera( 'FirstPerson' );
    }
}

event bool OnAxisModified( int ControllerId, name Key, float Delta, float DeltaTime, bool bGamepad )
{
    if ( GetPC().PlayerInput.bUsingGamepad )
    {
        if ( Key == 'XboxTypeS_RightX' && Abs(Delta) > class'KFGFxMenu_Gear'.Default.ControllerRotationThreshold)
        {
            Callback_RotateCamera(Delta * class'KFGFxMenu_Gear'.Default.ControllerRotationRate);
        }
    }
    return false;
}

//==============================================================
// ActionScript Callbacks
//==============================================================

function Callback_Emote(int Index)
{
    local KFPlayerController KFPC;

    KFPC = KFPlayerController(GetPC());
    if( KFPC != none )
    {
        class'ExtEmoteList'.static.SaveEquippedEmote(EmoteList[Index].ID, ExtPlayerController(KFPC));

        if ( ExtPawn_Customization(KFPC.Pawn) != none )
        {
            ExtPawn_Customization(KFPC.Pawn).PlayEmoteAnimation();
        }
    }

    SetEmoteButton();
}

function Callback_RotateCamera( int RotationDirection )
{
    local KFPlayerCamera PlayerCamera;
    
    PlayerCamera = KFPlayerCamera( GetPC().PlayerCamera );
    if ( PlayerCamera != none )
        PlayerCamera.CustomizationCam.RotatedCamera( RotationDirection );
}

function Callback_EndRotateCamera()
{
    local KFPlayerCamera PlayerCamera;

    PlayerCamera = KFPlayerCamera( GetPC().PlayerCamera );
    if ( PlayerCamera != none )
        PlayerCamera.CustomizationCam.StartFadeRotation();
}

function Callback_Weapon( int ItemIndex, int SkinIndex )
{
    local KFPawn_Customization KFP;

    KFP = KFPawn_Customization(GetPC().Pawn);
    if(KFP != none)
        KFP.AttachWeaponByItemDefinition(SkinIndex);
}

function Callback_BodyCamera()
{
    if ( KFPlayerCamera( GetPC().PlayerCamera ) != none )
        KFPlayerCamera( GetPC().PlayerCamera ).CustomizationCam.SetBodyView( 0 );
}

function Callback_HeadCamera()
{
    if ( KFPlayerCamera( GetPC().PlayerCamera ) != none )
        KFPlayerCamera( GetPC().PlayerCamera ).CustomizationCam.SetBodyView( 1 );
}

function Callback_Character(int Index)
{
    ExtPRI.ChangeCharacter(Index,!ExtPRI.UsesCustomChar());
    UpdateGear();
}

function Callback_Head( int MeshIndex, int SkinIndex )
{
    if( !ExtPRI.UsesCustomChar() ) // Force client to setup custom character now for this server.
        ExtPRI.ChangeCharacter(ExtPRI.RepCustomizationInfo.CharacterIndex,true);
    ExtPRI.UpdateCustomization(CO_Head, MeshIndex, SkinIndex);
    SetGearButtons(MeshIndex, SkinIndex, class'KFGFxMenu_Gear'.Default.HeadMeshKey, class'KFGFxMenu_Gear'.Default.HeadSkinKey, class'KFGFxMenu_Gear'.Default.HeadFunctionKey);
}

function Callback_Body( int MeshIndex, int SkinIndex )
{
    if( !ExtPRI.UsesCustomChar() ) // Force client to setup custom character now for this server.
        ExtPRI.ChangeCharacter(ExtPRI.RepCustomizationInfo.CharacterIndex,true);
    
    ExtPRI.UpdateCustomization(CO_Body, MeshIndex, SkinIndex);
    
    // When assigning a new body mesh we may need to remove certain attachments
    // refresh filters, and update the equipped accessories list
    UpdateAttachmentsList(CurrentCharInfo.CosmeticVariants);
    SetAttachmentButtons(class'KFGFxMenu_Gear'.Default.AttachmentKey, class'KFGFxMenu_Gear'.Default.AttachmentFunctionKey);

    SetGearButtons(MeshIndex, SkinIndex, class'KFGFxMenu_Gear'.Default.BodyMeshKey, class'KFGFxMenu_Gear'.Default.BodySkinKey, class'KFGFxMenu_Gear'.Default.BodyFunctionKey);
}

function Callback_Attachment( int MeshIndex, int SkinIndex )
{
    local int SlotIndex;
    local KFPawn KFP;

    if( !ExtPRI.UsesCustomChar() ) // Force client to setup custom character now for this server.
        ExtPRI.ChangeCharacter(ExtPRI.RepCustomizationInfo.CharacterIndex,true);

    KFP = KFPawn(GetPC().Pawn);
    if( KFP!=None && ExtPRI!=None )
    {
        if( MeshIndex==`CLEARED_ATTACHMENT_INDEX )
            ExtPRI.RemoveAttachments();
        else
        {
            class'ExtCharacterInfo'.Static.DetachConflictingAttachments(CurrentCharInfo, MeshIndex, KFP, ExtPRI);
            SlotIndex =  class'ExtCharacterInfo'.Static.GetAttachmentSlotIndex(CurrentCharInfo, MeshIndex, KFP, ExtPRI);
            if(SlotIndex == INDEX_NONE)
            {
                return;
            }
    
            ExtPRI.UpdateCustomization(CO_Attachment, MeshIndex, SkinIndex, SlotIndex);
        }

        SetAttachmentButtons(class'KFGFxMenu_Gear'.Default.AttachmentKey, class'KFGFxMenu_Gear'.Default.AttachmentFunctionKey);
    }
}

defaultproperties
{
	SubWidgetBindings.Add((WidgetName="customizationComponent",WidgetClass=class'KFGFxObject_Container'))
	SubWidgetBindings.Add((WidgetName="perkSelectionContainer",WidgetClass=class'KFGFxGearContainer_PerksSelection'))
}