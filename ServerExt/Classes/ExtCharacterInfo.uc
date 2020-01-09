// Only a helper class to hold code.
class ExtCharacterInfo extends Object
    abstract;

// Hack fix for not being able to compile materials in run-time.
static final function CloneMIC( MaterialInstanceConstant B )
{
    local int i;
    local MaterialInstanceConstant M;
    local LinearColor C;
    
    M = MaterialInstanceConstant(B.Parent);
    if( M==None )
        return;
    B.SetParent(M.Parent);
    
    for( i=0; i<M.TextureParameterValues.Length; ++i )
        if( M.TextureParameterValues[i].ParameterValue!=None )
            B.SetTextureParameterValue(M.TextureParameterValues[i].ParameterName,M.TextureParameterValues[i].ParameterValue);

    for( i=0; i<M.ScalarParameterValues.Length; ++i )
        B.SetScalarParameterValue(M.ScalarParameterValues[i].ParameterName,M.ScalarParameterValues[i].ParameterValue);
    
    for( i=0; i<M.VectorParameterValues.Length; ++i )
    {
        C = M.VectorParameterValues[i].ParameterValue;
        B.SetVectorParameterValue(M.VectorParameterValues[i].ParameterName,C);
    }
}

static final function Object SafeLoadObject( string S, Class ObjClass )
{
    local Object O;
    
    O = FindObject(S,ObjClass);
    return O!=None ? O : DynamicLoadObject(S,ObjClass);
}

static function InitCharacterMICs(KFCharacterInfo_Human C, KFPawn P, optional bool bMaskHead)
{
    local int i;

    if( P.WorldInfo.NetMode == NM_DedicatedServer )
    {
        return;
    }

    P.CharacterMICs.Remove(0, P.CharacterMICs.Length);

    // body MIC
    if ( P.Mesh != None )
    {
        P.CharacterMICs[0] = P.Mesh.CreateAndSetMaterialInstanceConstant(C.BodyMaterialID);
        CloneMIC(P.CharacterMICs[0]);
    }

    // head MIC
    if( P.ThirdPersonHeadMeshComponent != None )
    {
        P.CharacterMICs[1] = P.ThirdPersonHeadMeshComponent.CreateAndSetMaterialInstanceConstant(C.HeadMaterialID);

        if ( bMaskHead )
        {
            // initial mask for new head MIC (also see ResetHeadMaskParam())
            P.CharacterMICs[1].SetScalarParameterValue('Scalar_Mask', 1.f);
        }
    }

    // attachment MIC
    for( i=0; i < `MAX_COSMETIC_ATTACHMENTS; i++ )
    {
        if( P.ThirdPersonAttachments[i] != none )
        {
            P.CharacterMICs.AddItem(P.ThirdPersonAttachments[i].CreateAndSetMaterialInstanceConstant(0));
        }
        
        if (P.FirstPersonAttachments[i] != none)
        {
            P.CharacterMICs.AddItem(P.FirstPersonAttachments[i].CreateAndSetMaterialInstanceConstant(0));
        }
    }
}

/** Sets the pawns character mesh from it's CharacterInfo, and updates instance of player in map if there is one. */
static final function SetCharacterMeshFromArch( KFCharacterInfo_Human C, KFPawn KFP, optional KFPlayerReplicationInfo KFPRI )
{
    local ExtPlayerReplicationInfo EPRI;
    local int AttachmentIdx, CosmeticMeshIdx;
    local bool bMaskHeadMesh, bCustom;

    if ( KFPRI == none )
    {
        `Warn("Does not have a KFPRI" @ C);
         return;
    }
    EPRI = ExtPlayerReplicationInfo(KFPRI);
    bCustom = (EPRI!=None ? EPRI.UsesCustomChar() : false);

    // Body mesh & skin. Index of 255 implies use index 0 (default).
    SetBodyMeshAndSkin(C,
        bCustom ? EPRI.CustomCharacter.BodyMeshIndex : KFPRI.RepCustomizationInfo.BodyMeshIndex,
        bCustom ? EPRI.CustomCharacter.BodySkinIndex : KFPRI.RepCustomizationInfo.BodySkinIndex,
        KFP,
        KFPRI);

    // Head mesh & skin. Index of 255 implies use index 0 (default).
    SetHeadMeshAndSkin(C,
        bCustom ? EPRI.CustomCharacter.HeadMeshIndex : KFPRI.RepCustomizationInfo.HeadMeshIndex,
        bCustom ? EPRI.CustomCharacter.HeadSkinIndex : KFPRI.RepCustomizationInfo.HeadSkinIndex,
        KFP,
        KFPRI);

    // skip dedicated for purely cosmetic stuff
    if ( KFP.WorldInfo.NetMode != NM_DedicatedServer )
    {
        // Must clear all attachments before trying to attach new ones, 
        // otherwise we might accidentally remove things we're not supposed to
        for( AttachmentIdx=0; AttachmentIdx < `MAX_COSMETIC_ATTACHMENTS; AttachmentIdx++ )
        {
            // Clear any previous attachments from other characters
            C.DetachAttachment(AttachmentIdx, KFP);
        }

        // Cosmetic attachment mesh & skin. Index of 255 implies don't use any attachments (default)
        for( AttachmentIdx=0; AttachmentIdx < `MAX_COSMETIC_ATTACHMENTS; AttachmentIdx++ )
        {
            CosmeticMeshIdx = bCustom ? EPRI.CustomCharacter.AttachmentMeshIndices[AttachmentIdx] : KFPRI.RepCustomizationInfo.AttachmentMeshIndices[AttachmentIdx];
            if ( CosmeticMeshIdx != `CLEARED_ATTACHMENT_INDEX && CosmeticMeshIdx != INDEX_NONE )
            {
                bMaskHeadMesh = bMaskHeadMesh || C.CosmeticVariants[CosmeticMeshIdx].bMaskHeadMesh;

                // Attach all saved attachments to the character
                SetAttachmentMeshAndSkin(C,
                    CosmeticMeshIdx,
                    bCustom ? EPRI.CustomCharacter.AttachmentSkinIndices[AttachmentIdx] : KFPRI.RepCustomizationInfo.AttachmentSkinIndices[AttachmentIdx],
                    KFP, KFPRI);
            }
        }

        // initial mask for new MIC (also see ResetHeadMaskParam())
        InitCharacterMICs(C, KFP, bMaskHeadMesh);
    }
}

static final function SetBodyMeshAndSkin( KFCharacterInfo_Human C,
    byte CurrentBodyMeshIndex,
    byte CurrentBodySkinIndex,
    KFPawn KFP,
    KFPlayerReplicationInfo KFPRI )
{
    local string CharBodyMeshName;
    local SkeletalMesh CharBodyMesh;

    //Always use default body on servers
    if (KFP.WorldInfo.NetMode == NM_DedicatedServer)
    {
        CurrentBodyMeshIndex = 0;
        CurrentBodySkinIndex = 0;
    }

    // Character Mesh
    if( C.BodyVariants.length > 0 )
    {
        // Assign a skin to the body mesh as a material override
        CurrentBodyMeshIndex = (CurrentBodyMeshIndex < C.BodyVariants.length) ? CurrentBodyMeshIndex : 0;
        
        if (KFPRI.StartLoadCosmeticContent(C, ECOSMETICTYPE_Body, CurrentBodyMeshIndex))
        {
            return;
        }

        // Retrieve the name of the meshes to be used from the archetype
        CharBodyMeshName = C.BodyVariants[CurrentBodyMeshIndex].MeshName;

        // Load the meshes
        CharBodyMesh = SkeletalMesh(SafeLoadObject(CharBodyMeshName, class'SkeletalMesh'));

        // Assign the body mesh to the pawn
        if ( CharBodyMesh != KFP.Mesh.SkeletalMesh )
        {
            KFP.Mesh.SetSkeletalMesh(CharBodyMesh);
            KFP.OnCharacterMeshChanged();
        }

        if (KFP.WorldInfo.NetMode != NM_DedicatedServer)
        {
            SetBodySkinMaterial(C, C.BodyVariants[CurrentBodyMeshIndex], CurrentBodySkinIndex, KFP);
        }
    }
    else
    {
        `warn("Character does not have a valid mesh");
    }
}

static final function SetBodySkinMaterial( KFCharacterInfo_Human C, OutfitVariants CurrentVariant, byte NewSkinIndex, KFPawn KFP)
{
    local int i;

    if (KFP.WorldInfo.NetMode != NM_DedicatedServer)
    {
        if( CurrentVariant.SkinVariations.length > 0 )
        {
            // Assign a skin to the body mesh as a material override
            NewSkinIndex = (NewSkinIndex < CurrentVariant.SkinVariations.length) ? NewSkinIndex : 0;
            KFP.Mesh.SetMaterial(C.BodyMaterialID, CurrentVariant.SkinVariations[NewSkinIndex].Skin);
        }
        else
        {
            // Use material specified in the mesh asset
            for( i=0; i<KFP.Mesh.GetNumElements(); i++ )
            {
                KFP.Mesh.SetMaterial(i, none);
            }
        }
    }
}

static final function SetHeadSkinMaterial( KFCharacterInfo_Human C, OutfitVariants CurrentVariant, byte NewSkinIndex, KFPawn KFP )
{
    local int i;

    if (KFP.WorldInfo.NetMode != NM_DedicatedServer)
    {
        if( CurrentVariant.SkinVariations.length > 0 )
        {
            // Assign a skin to the body mesh as a material override
            NewSkinIndex = (NewSkinIndex < CurrentVariant.SkinVariations.length) ? NewSkinIndex : 0;
            KFP.ThirdPersonHeadMeshComponent.SetMaterial(C.HeadMaterialID, CurrentVariant.SkinVariations[NewSkinIndex].Skin);
        }
        else
        {
            // Use material specified in the mesh asset
            for( i=0; i<KFP.ThirdPersonHeadMeshComponent.GetNumElements(); i++ )
            {
                KFP.ThirdPersonHeadMeshComponent.SetMaterial(i, none);
            }
        }
    }
}

static final function SetHeadMeshAndSkin( KFCharacterInfo_Human C,
    byte CurrentHeadMeshIndex,
    byte CurrentHeadSkinIndex,
    KFPawn KFP,
    KFPlayerReplicationInfo KFPRI )
{
    local string CharHeadMeshName;
    local SkeletalMesh CharHeadMesh;

    if ( C.HeadVariants.length > 0 )
    {
        CurrentHeadMeshIndex = (CurrentHeadMeshIndex < C.HeadVariants.length) ? CurrentHeadMeshIndex : 0;
        
        if (KFPRI.StartLoadCosmeticContent(C, ECOSMETICTYPE_Head, CurrentHeadMeshIndex))
        {
            return;
        }

        CharHeadMeshName = C.HeadVariants[CurrentHeadMeshIndex].MeshName;
        CharHeadMesh = SkeletalMesh(DynamicLoadObject(CharHeadMeshName, class'SkeletalMesh'));

        // Parent the third person head mesh to the body mesh
        KFP.ThirdPersonHeadMeshComponent.SetSkeletalMesh(CharHeadMesh);
        KFP.ThirdPersonHeadMeshComponent.SetScale(C.DefaultMeshScale);

        KFP.ThirdPersonHeadMeshComponent.SetParentAnimComponent(KFP.Mesh);
        KFP.ThirdPersonHeadMeshComponent.SetShadowParent(KFP.Mesh);
        KFP.ThirdPersonHeadMeshComponent.SetLODParent(KFP.Mesh);

        KFP.AttachComponent(KFP.ThirdPersonHeadMeshComponent);

        if (KFP.WorldInfo.NetMode != NM_DedicatedServer)
        {
            SetHeadSkinMaterial(C, C.HeadVariants[CurrentHeadMeshIndex], CurrentHeadSkinIndex, KFP);
        }
    }
}

static final function SetAttachmentSkinMaterial( KFCharacterInfo_Human C,
    int PawnAttachmentIndex,
    const out AttachmentVariants CurrentVariant,
    byte NewSkinIndex,
    KFPawn KFP,
    optional bool bIsFirstPerson)
{
    local int i;
    if (KFP.WorldInfo.NetMode != NM_DedicatedServer)
    {
        if( CurrentVariant.AttachmentItem.SkinVariations.length > 0 )
        {
            // Assign a skin to the attachment mesh as a material override
            if ( NewSkinIndex < CurrentVariant.AttachmentItem.SkinVariations.length )
            {
                if (bIsFirstPerson)
                {
                    if (KFP.FirstPersonAttachments[PawnAttachmentIndex] != none)
                    {
                        KFP.FirstPersonAttachments[PawnAttachmentIndex].SetMaterial(
                            CurrentVariant.AttachmentItem.SkinMaterialID,
                            CurrentVariant.AttachmentItem.SkinVariations[NewSkinIndex].Skin1p);
                    }
                }
                else
                {
                    KFP.ThirdPersonAttachments[PawnAttachmentIndex].SetMaterial(
                        CurrentVariant.AttachmentItem.SkinMaterialID,
                        CurrentVariant.AttachmentItem.SkinVariations[NewSkinIndex].Skin);
                }
            }
            else
            {
                `log("Out of bounds skin index for"@CurrentVariant.MeshName);
                C.RemoveAttachmentMeshAndSkin(PawnAttachmentIndex, KFP);
            }
        }
        else
        {
            if (bIsFirstPerson)
            {
                if (KFP.FirstPersonAttachments[PawnAttachmentIndex] != none)
                {
                    for (i = 0; i < KFP.FirstPersonAttachments[PawnAttachmentIndex].GetNumElements(); i++)
                    {
                        KFP.FirstPersonAttachments[PawnAttachmentIndex].SetMaterial(i, none);
                    }
                }
            }
            else
            {
                // Use material specified in the mesh asset
                for( i=0; i < KFP.ThirdPersonAttachments[PawnAttachmentIndex].GetNumElements(); i++ )
                {
                    KFP.ThirdPersonAttachments[PawnAttachmentIndex].SetMaterial(i, none);
                }
            }
        }
    }
}

static final function SetAttachmentMeshAndSkin( KFCharacterInfo_Human C,
    int CurrentAttachmentMeshIndex,
    int CurrentAttachmentSkinIndex,
    KFPawn KFP,
    KFPlayerReplicationInfo KFPRI,
    optional bool bIsFirstPerson )
{
    local string CharAttachmentMeshName;
    local name CharAttachmentSocketName;
    local int AttachmentSlotIndex;
    local SkeletalMeshComponent AttachmentMesh;

    if (KFP.WorldInfo.NetMode == NM_DedicatedServer)
    {
        return;
    }

    // Clear any previously attachments for the same slot
    //DetachConflictingAttachments(CurrentAttachmentMeshIndex, KFP, KFPRI);
    // Get a slot where this attachment could fit
    AttachmentSlotIndex = GetAttachmentSlotIndex(C, CurrentAttachmentMeshIndex, KFP, KFPRI);
    
    if (AttachmentSlotIndex == INDEX_NONE)
    {
        return;
    }

    // Since cosmetic attachments are optional, do not choose index 0 if none is
    // specified unlike the the head and body meshes
    if ( C.CosmeticVariants.Length > 0 &&
         CurrentAttachmentMeshIndex < C.CosmeticVariants.Length )
    {
        if (KFPRI.StartLoadCosmeticContent(C, ECOSMETICTYPE_Attachment, CurrentAttachmentMeshIndex))
        {
            return;
        }
        
        // Cache values from character info
        CharAttachmentMeshName = bIsFirstPerson ? C.Get1pMeshByIndex(CurrentAttachmentMeshIndex) : C.GetMeshByIndex(CurrentAttachmentMeshIndex);
        CharAttachmentSocketName = bIsFirstPerson ? C.CosmeticVariants[CurrentAttachmentMeshIndex].AttachmentItem.SocketName1p : C.CosmeticVariants[CurrentAttachmentMeshIndex].AttachmentItem.SocketName;
        AttachmentMesh = bIsFirstPerson ? KFP.ArmsMesh : KFP.Mesh;

        // If previously attached and we could have changed outfits (e.g. local player UI) then re-validate
        // required skeletal mesh socket.  Must be after body mesh DLO, but before AttachComponent.
        if ( KFP.IsLocallyControlled() )
        {
            if ( CharAttachmentSocketName != '' && KFP.Mesh.GetSocketByName(CharAttachmentSocketName) == None )
            {
                C.RemoveAttachmentMeshAndSkin(AttachmentSlotIndex, KFP, KFPRI);
                return;
            }
        }

        // Set First Person Cosmetic if mesh exists for it.
        if(CharAttachmentMeshName != "")
        {
            // Set Cosmetic Mesh
            SetAttachmentMesh(C, CurrentAttachmentMeshIndex, AttachmentSlotIndex, CharAttachmentMeshName, CharAttachmentSocketName, AttachmentMesh, KFP, bIsFirstPerson);
        }
        else
        {
            // Make sure to clear out attachment if we're replacing with nothing.
            if(bIsFirstPerson)
            {
                KFP.FirstPersonAttachments[AttachmentSlotIndex] = none;
                KFP.FirstPersonAttachmentSocketNames[AttachmentSlotIndex] = '';
            }
        }

        // Set Cosmetic Skin
        SetAttachmentSkinMaterial(
            C,
            AttachmentSlotIndex,
            C.CosmeticVariants[CurrentAttachmentMeshIndex],
            CurrentAttachmentSkinIndex,
            KFP,
            bIsFirstPerson);
    }

    // Treat `CLEARED_ATTACHMENT_INDEX as special value (for client detachment)
    if( CurrentAttachmentMeshIndex == `CLEARED_ATTACHMENT_INDEX )
    {
        C.RemoveAttachmentMeshAndSkin(AttachmentSlotIndex, KFP, KFPRI);
    }
}

static final function SetAttachmentMesh(KFCharacterInfo_Human C, int CurrentAttachmentMeshIndex, int AttachmentSlotIndex, string CharAttachmentMeshName, name CharAttachmentSocketName, SkeletalMeshComponent PawnMesh, KFPawn KFP, bool bIsFirstPerson = false)
{
    local StaticMeshComponent StaticAttachment;
    local SkeletalMeshComponent SkeletalAttachment;
    local bool bIsSkeletalAttachment;
    local StaticMesh CharAttachmentStaticMesh;
    local SkeletalMesh CharacterAttachmentSkelMesh;
    local float MaxDrawDistance;
    local SkeletalMeshSocket AttachmentSocket;
    local vector AttachmentLocationRelativeToSocket, AttachmentScaleRelativeToSocket;
    local rotator AttachmentRotationRelativeToSocket;

    MaxDrawDistance = C.CosmeticVariants[CurrentAttachmentMeshIndex].AttachmentItem.MaxDrawDistance;
    AttachmentLocationRelativeToSocket = C.CosmeticVariants[CurrentAttachmentMeshIndex].RelativeTranslation;
    AttachmentRotationRelativeToSocket = C.CosmeticVariants[CurrentAttachmentMeshIndex].RelativeRotation;
    AttachmentScaleRelativeToSocket = C.CosmeticVariants[CurrentAttachmentMeshIndex].RelativeScale;
    bIsSkeletalAttachment = C.CosmeticVariants[CurrentAttachmentMeshIndex].AttachmentItem.bIsSkeletalAttachment;

    //`log("AttachmentLocationRelativeToSocket: x="$AttachmentLocationRelativeToSocket.x@"y="$AttachmentLocationRelativeToSocket.y@"z="$AttachmentLocationRelativeToSocket.z);
    // If it is a skeletal attachment, parent anim it to the body mesh
    if (bIsSkeletalAttachment)
    {
        if (bIsFirstPerson && (SkeletalMeshComponent(KFP.FirstPersonAttachments[AttachmentSlotIndex]) != none))
        {
            SkeletalAttachment = SkeletalMeshComponent(KFP.FirstPersonAttachments[AttachmentSlotIndex]);
        }
        else if (!bIsFirstPerson && (SkeletalMeshComponent(KFP.ThirdPersonAttachments[AttachmentSlotIndex]) != none))
        {
            SkeletalAttachment = SkeletalMeshComponent(KFP.ThirdPersonAttachments[AttachmentSlotIndex]);
        }
        else
        {
            SkeletalAttachment = new(KFP) class'KFSkeletalMeshComponent';
            if (bIsFirstPerson)
            {
                C.SetFirstPersonCosmeticAttachment(SkeletalAttachment);
            }
            SkeletalAttachment.SetActorCollision(false, false);

            if(bIsFirstPerson)
            {
                KFP.FirstPersonAttachments[AttachmentSlotIndex] = SkeletalAttachment;
            }
            else
            {
                KFP.ThirdPersonAttachments[AttachmentSlotIndex] = SkeletalAttachment;
            }
        }

        // Load and assign skeletal mesh
        CharacterAttachmentSkelMesh = SkeletalMesh(DynamicLoadObject(CharAttachmentMeshName, class'SkeletalMesh'));
        SkeletalAttachment.SetSkeletalMesh(CharacterAttachmentSkelMesh);

        // Parent animation and LOD transitions to body mesh
        SkeletalAttachment.SetParentAnimComponent(PawnMesh);
        SkeletalAttachment.SetLODParent(PawnMesh);
        SkeletalAttachment.SetScale(C.DefaultMeshScale);
        SkeletalAttachment.SetCullDistance(MaxDrawDistance);
        SkeletalAttachment.SetShadowParent(PawnMesh);
        SkeletalAttachment.SetLightingChannels(KFP.PawnLightingChannel);

        KFP.AttachComponent(SkeletalAttachment);
    }
    // Otherwise (if static), attach to a socket on the body mesh
    else
    {
        if (!bIsFirstPerson && (StaticMeshComponent(KFP.ThirdPersonAttachments[AttachmentSlotIndex]) != none))
        {
            StaticAttachment = StaticMeshComponent(KFP.ThirdPersonAttachments[AttachmentSlotIndex]);
        }
        else if (bIsFirstPerson && (StaticMeshComponent(KFP.FirstPersonAttachments[AttachmentSlotIndex]) != none))
        {
            StaticAttachment = StaticMeshComponent(KFP.FirstPersonAttachments[AttachmentSlotIndex]);
        }
        else
        {
            StaticAttachment = new(KFP) class'StaticMeshComponent';
            StaticAttachment.SetActorCollision(false, false);

            if(bIsFirstPerson)
            {
                KFP.FirstPersonAttachments[AttachmentSlotIndex] = StaticAttachment;
            }
            else
            {
                KFP.ThirdPersonAttachments[AttachmentSlotIndex] = StaticAttachment;
            }
        }

        // Load and assign static mesh
        CharAttachmentStaticMesh = StaticMesh(DynamicLoadObject(CharAttachmentMeshName, class'StaticMesh'));
        StaticAttachment.SetStaticMesh(CharAttachmentStaticMesh);

        // Set properties
        StaticAttachment.SetScale(C.DefaultMeshScale);
        StaticAttachment.SetCullDistance(MaxDrawDistance);
        StaticAttachment.SetShadowParent(KFP.Mesh);
        StaticAttachment.SetLightingChannels(KFP.PawnLightingChannel);

        // For static meshes, attach to given socket
        AttachmentSocket = PawnMesh.GetSocketByName(CharAttachmentSocketName);
        PawnMesh.AttachComponent(
            StaticAttachment,
            AttachmentSocket.BoneName,
            AttachmentSocket.RelativeLocation + AttachmentLocationRelativeToSocket,
            AttachmentSocket.RelativeRotation + AttachmentRotationRelativeToSocket,
            AttachmentSocket.RelativeScale * AttachmentScaleRelativeToSocket);
    }

    if(bIsFirstPerson)
    {
        KFP.FirstPersonAttachmentSocketNames[AttachmentSlotIndex] = CharAttachmentSocketName;
    }
    else
    {
        KFP.ThirdPersonAttachmentSocketNames[AttachmentSlotIndex] = CharAttachmentSocketName;
    }
}

/**
 * Removes any attachments that exist in the same socket or have overriding cases 
 * Network: Local Player 
 */
static final function DetachConflictingAttachments( KFCharacterInfo_Human C, int NewAttachmentMeshIndex, KFPawn KFP, optional KFPlayerReplicationInfo KFPRI)
{
    local name NewAttachmentSocketName;
    local int i, CurrentAttachmentIdx;
    local ExtPlayerReplicationInfo EPRI;

    EPRI = ExtPlayerReplicationInfo(KFPRI);
    if ( EPRI==none || !EPRI.UsesCustomChar() )
        return;

    if ( C.CosmeticVariants.length > 0 &&
         NewAttachmentMeshIndex < C.CosmeticVariants.length )
    {
        // The socket that this attachment requires
        NewAttachmentSocketName = C.CosmeticVariants[NewAttachmentMeshIndex].AttachmentItem.SocketName;

        for( i=0; i < `MAX_COSMETIC_ATTACHMENTS; i++ )
        {
            CurrentAttachmentIdx = EPRI.CustomCharacter.AttachmentMeshIndices[i];
            if ( CurrentAttachmentIdx == `CLEARED_ATTACHMENT_INDEX )
                continue;

            // Remove the object if it is taking up our desired slot
            if( KFP.ThirdPersonAttachmentSocketNames[i] != '' &&
                KFP.ThirdPersonAttachmentSocketNames[i] == NewAttachmentSocketName )
            {
                C.RemoveAttachmentMeshAndSkin(i, KFP, KFPRI);    
                continue;
            }

            // Remove the object if it cannot exist at the same time as another equipped item
            if( C.GetOverrideCase(CurrentAttachmentIdx, NewAttachmentMeshIndex) )
            {
                C.RemoveAttachmentMeshAndSkin(i, KFP, KFPRI);
                continue;
            }

            // Check inverse override
            if( C.GetOverrideCase(NewAttachmentMeshIndex, CurrentAttachmentIdx) )
            {
                C.RemoveAttachmentMeshAndSkin(i, KFP, KFPRI);
                continue;
            }
        }
    }
}

/** Assign an arm mesh and material to this pawn */
static final function SetFirstPersonArmsFromArch( KFCharacterInfo_Human C, KFPawn KFP, optional KFPlayerReplicationInfo KFPRI )
{
    local MaterialInstanceConstant M;
    local ExtPlayerReplicationInfo EPRI;
    local bool bCustom;
    local int AttachmentIdx, CosmeticMeshIdx;

    if ( KFPRI == none )
    {
        `Warn("Does not have a KFPRI" @ C);
         return;
    }
    EPRI = ExtPlayerReplicationInfo(KFPRI);
    bCustom = (EPRI!=None ? EPRI.UsesCustomChar() : false);

    // First person arms mesh and skin are based on body mesh & skin. 
    // Index of 255 implies use index 0 (default).
    C.SetArmsMeshAndSkin(
        bCustom ? EPRI.CustomCharacter.BodyMeshIndex : KFPRI.RepCustomizationInfo.BodyMeshIndex,
        bCustom ? EPRI.CustomCharacter.BodySkinIndex : KFPRI.RepCustomizationInfo.BodySkinIndex,
        KFP,
        KFPRI);
        
    for (AttachmentIdx = 0; AttachmentIdx < `MAX_COSMETIC_ATTACHMENTS; AttachmentIdx++)
    {
        CosmeticMeshIdx = bCustom ? EPRI.CustomCharacter.AttachmentMeshIndices[AttachmentIdx] : KFPRI.RepCustomizationInfo.AttachmentMeshIndices[AttachmentIdx];
        if (CosmeticMeshIdx != `CLEARED_ATTACHMENT_INDEX && CosmeticMeshIdx != INDEX_NONE)
        {
            // Attach all saved attachments to the character
            SetAttachmentMeshAndSkin(
                C,
                CosmeticMeshIdx,
                bCustom ? EPRI.CustomCharacter.AttachmentSkinIndices[AttachmentIdx] : KFPRI.RepCustomizationInfo.AttachmentSkinIndices[AttachmentIdx],
                KFP, KFPRI, true);
        }
    }
    
    // Hack fix for a material bug on KF2
    if( bCustom && KFP.ArmsMesh.SkeletalMesh!=None && KFP.ArmsMesh.GetMaterial(0)!=None )
    {
        M = KFP.ArmsMesh.CreateAndSetMaterialInstanceConstant(0);
        CloneMIC(M);
    }
}

static function int GetAttachmentSlotIndex(
    KFCharacterInfo_Human C,
    int CurrentAttachmentMeshIndex,
    KFPawn KFP,
    KFPlayerReplicationInfo KFPRI)
{
    local int AttachmentIdx,CosmeticMeshIdx;
    local ExtPlayerReplicationInfo EPRI;
    local bool bCustom;

    if( KFPRI == None )
    {
        `warn("GetAttachmentSlotIndex - NO KFPRI");
        return INDEX_NONE;
    }
    
    EPRI = ExtPlayerReplicationInfo(KFPRI);
    bCustom = (EPRI!=None ? EPRI.UsesCustomChar() : false);
    
    // Return the next available attachment index or the index that matches this mesh
    for( AttachmentIdx = 0; AttachmentIdx < `MAX_COSMETIC_ATTACHMENTS; AttachmentIdx++ )
    {
        CosmeticMeshIdx = bCustom ? EPRI.CustomCharacter.AttachmentMeshIndices[AttachmentIdx] : KFPRI.RepCustomizationInfo.AttachmentMeshIndices[AttachmentIdx];
        if( CosmeticMeshIdx == INDEX_NONE || CosmeticMeshIdx == CurrentAttachmentMeshIndex )
        {
            return AttachmentIdx;
        }
    }
    return INDEX_NONE;
}

static function bool IsAttachmentAvailable(KFCharacterInfo_Human C, const out AttachmentVariants Attachment, Pawn PreviewPawn)
{
    if ( Attachment.AttachmentItem.SocketName != '' && PreviewPawn.Mesh.GetSocketByName(Attachment.AttachmentItem.SocketName) == None )
    {
        return false;
    }

    return true;
}