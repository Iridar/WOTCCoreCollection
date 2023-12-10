class X2DownloadableContentInfo_WOTCCoreCollection extends X2DownloadableContentInfo;

var private config(Content) array<name> FixClothPhysicsForThighs;
var private config bool bDisableSkulljackFix;
var private config bool bSkipOverrideOverwatchAllOthersShotHUDPriority;

delegate ModifyTemplate(X2DataTemplate DataTemplate);

static event OnPostTemplatesCreated()
{
	// Issue #1
	// Issue #4
	PatchOverwatchAllMod();	

	// Issue #8
	ModifyTemplateAllDiff('ConstantHighCover', class'X2AbilityTemplate', PatchCoverGenerationAbility);
	ModifyTemplateAllDiff('ConstantLowCover', class'X2AbilityTemplate', PatchCoverGenerationAbility);
	ModifyTemplateAllDiff('Bulwark', class'X2AbilityTemplate', PatchCoverGenerationAbility);
	ModifyTemplateAllDiff('HighCoverGenerator', class'X2AbilityTemplate', PatchCoverGenerationAbility);

	ModifyTemplateAllDiff('HighCoverGenerator', class'X2AbilityTemplate', PatchHackRewardAbility);

	// Issue #13
	PatchHackRewardAbilities();

	// Issue #15
	ModifyTemplateAllDiff('StabilizeMedkitOwner', class'X2AbilityTemplate', PatchStabilizeMe);

	// Issue #21
	PatchTrainingCenterAbilitiesForSharpshooters();

	// Issue #22
	ModifyTemplateAllDiff('AlienGrenade', class'X2ItemTemplate', PatchPlasmaGrenadeIcon);

	// Issue #23
	if (IsModActive('ScanningProtocolFix'))
	{
		FixScanningProtocolFix();
	}

	// Issue #26
	if (!default.bDisableSkulljackFix)
	{
		ModifyTemplateAllDiff('SKULLJACKAbility', class'X2AbilityTemplate', PatchSkulljackAbility);
		ModifyTemplateAllDiff('SKULLMINEAbility', class'X2AbilityTemplate', PatchSkullmineAbility);
	}
}

// Start Issue #16
static function UpdateAnimations(out array<AnimSet> CustomAnimSets, XComGameState_Unit UnitState, XComUnitPawn Pawn)
{
	if (!Pawn.m_bHasFullAnimWeightBones && default.FixClothPhysicsForThighs.Find(UnitState.kAppearance.nmThighs) != INDEX_NONE)
	{
		//Pawn.m_bHasFullAnimWeightBones = true;
		Pawn.Mesh.bEnableFullAnimWeightBodies = true;
		Pawn.Mesh.PhysicsWeight = 0;
		Pawn.Mesh.SetHasPhysicsAssetInstance(TRUE);
		Pawn.Mesh.bUpdateKinematicBonesFromAnimation=true;
		Pawn.Mesh.SetBlockRigidBody(true);
		Pawn.Mesh.SetRBChannel(RBCC_Pawn);		
		Pawn.Mesh.SetRBCollidesWithChannel(RBCC_Default,TRUE);
		Pawn.Mesh.SetRBCollidesWithChannel(RBCC_Pawn,TRUE);
		Pawn.Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,TRUE);
		Pawn.Mesh.SetRBCollidesWithChannel(RBCC_Clothing, TRUE);
		Pawn.Mesh.SetRBCollidesWithChannel(RBCC_ClothingCollision, TRUE);
		Pawn.Mesh.PhysicsAssetInstance.SetFullAnimWeightBonesFixed(false, Pawn.Mesh);
	}
}
// End Issue #16

// Start Issue #15
static final function PatchStabilizeMe(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate			Template;
	local X2Condition_Visibility	Visibility;
	local int i;

	Template = X2AbilityTemplate(DataTemplate);

	for (i = Template.AbilityTargetConditions.Length - 1; i >= 0; i--)
	{
		if (Template.AbilityTargetConditions[i].Class.Name == 'X2Condition_StabilizeMedkitOwner')
		{
			Template.AbilityTargetConditions[i] = new class'X2Condition_TargetHasMedikit';
			break;
		}
	}

	Visibility = new class'X2Condition_Visibility';
	Visibility.bRequireGameplayVisible = true;
	Visibility.bRequireBasicVisibility = true;
	Template.AbilityTargetConditions.AddItem(Visibility);

	// Original BuildGameStateFn uses the same loggy spammy function as the X2Condition_StabilizeMedkitOwner.
	// Replace custom function with standard one, and instead use an X2Effect to apply the cost.
	Template.BuildNewGameStateFn = class'X2Ability'.static.TypicalAbility_BuildGameState;

	Template.AddTargetEffect(new class'X2Effect_ApplyMedikitChargeCost');
}
// End Issue #15

// Start Issue #13
static final function PatchHackRewardAbilities()
{
	local X2HackRewardTemplateManager	Mgr;
	local X2DataTemplate				DataTemplate;
	local X2HackRewardTemplate			HackRewardTemplate;

	Mgr = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	foreach Mgr.IterateTemplates(DataTemplate)
	{
		HackRewardTemplate = X2HackRewardTemplate(DataTemplate);
		if (HackRewardTemplate.AbilityTemplateName != '')
		{
			ModifyTemplateAllDiff(HackRewardTemplate.AbilityTemplateName, class'X2AbilityTemplate', PatchHackRewardAbility);
		}
	}
}

static final function PatchHackRewardAbility(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate Template;
	local int i;

	Template = X2AbilityTemplate(DataTemplate);
	
	for (i = 0; i < Template.AbilityTriggers.Length; i++)
	{
		if (X2AbilityTrigger_EventListener(Template.AbilityTriggers[i]) != none &&
			X2AbilityTrigger_EventListener(Template.AbilityTriggers[i]).ListenerData.EventID == class'X2HackRewardTemplateManager'.default.HackAbilityEventName &&
			string(X2AbilityTrigger_EventListener(Template.AbilityTriggers[i]).ListenerData.EventFn) == "XComGame.Default__XComGameState_Ability.AbilityTriggerEventListener_Self")
		{
			`LOG("Patching Event Listener Trigger for Hack Reward Ability:" @ Template.LocFriendlyName @ "(" $ Template.DataName $ ")",, 'CCMM');
			X2AbilityTrigger_EventListener(Template.AbilityTriggers[i]).ListenerData.EventFn = static.AbilityTriggerEventListener_HackReward;
		}
	}
}
// End Issue #13

// Start Issue #21
static final function PatchTrainingCenterAbilitiesForSharpshooters()
{
	local X2AbilityTemplateManager	AbilityTemplateManager;
	local X2AbilityTemplate			AbilityTemplate;
	local X2Effect_Guardian			GuardianEffect;
	local X2Effect_CoveringFire		CoveringFireEffect;
	local X2Effect					Effect;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('HailOfBullets');
	if (AbilityTemplate != none)
		PatchTrainingCenterAbilityForSharpshooters(AbilityTemplate);

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('ChainShot');
	if (AbilityTemplate != none)
		PatchTrainingCenterAbilityForSharpshooters(AbilityTemplate);

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('RapidFire');
	if (AbilityTemplate != none)
		PatchTrainingCenterAbilityForSharpshooters(AbilityTemplate);

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('Sentinel');
	if (AbilityTemplate != none)
	{
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);	
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('LongWatchShot');
		}
	}

	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('LongWatch');
	if (AbilityTemplate != none)
	{
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			CoveringFireEffect = X2Effect_CoveringFire(Effect);	
			if (CoveringFireEffect == none)
				continue;

			CoveringFireEffect.AbilityToActivate = 'LongWatchShot';
		}
	}
}
static final function PatchTrainingCenterAbilityForSharpshooters(out X2AbilityTemplate AbilityTemplate)
{
	local X2Condition_Visibility		VisibilityCondition;
	local X2Condition_Visibility		NewVisibilityCondition;
	local int i;

	for (i = 0; i < AbilityTemplate.AbilityTargetConditions.Length; i++)
	{
		VisibilityCondition = X2Condition_Visibility(AbilityTemplate.AbilityTargetConditions[i]);
		if (VisibilityCondition == none)
			continue;

		NewVisibilityCondition = new class'X2Condition_Visibility'(VisibilityCondition);

		NewVisibilityCondition.bAllowSquadsight = true;

		// Have to specifically replace the old condition rather than patch the old one, 
		// otherwise the change will affect all abilities using that instance of the condition.
		// Would be patching default.GameplayVisibilityCondition essentially.
		AbilityTemplate.AbilityTargetConditions[i] = NewVisibilityCondition;
		break;
	}
}
// End Issue #21

static final function EventListenerReturn AbilityTriggerEventListener_HackReward(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Ability AbilityState;
		
	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState != none && GameState.GetGameStateForObjectID(AbilityState.ObjectID) != none)
	{
		AbilityState.AbilityTriggerAgainstSingleTarget(AbilityState.OwnerStateObject, false);
	}	

    return ELR_NoInterrupt;
}

// Begin Issue #8
static final function PatchCoverGenerationAbility(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate			Template;
	local X2Effect					Effect;
	local X2Effect_GenerateCover	GenerateCover;

	Template = X2AbilityTemplate(DataTemplate);
	
	foreach Template.AbilityShooterEffects(Effect)
	{
		GenerateCover = X2Effect_GenerateCover(Effect);
		if (GenerateCover != none && GenerateCover.EffectRemovedFn == none)
		{
			//	Interestingly, this doesn't prevent the cover bonus from disappearing if it dies normally.
			//	Duuh, this doesn't remove the bonus, it relocates it to the new unit's position.
			//	Thankfully, this doesn't cause cover to appear where the turret supposedly fell.
			//	Or maybe it does, but the turret falls all the way to Narnia, so we just never know.
			GenerateCover.bRemoveWhenTargetDies = true;
			GenerateCover.bRemoveWhenSourceDies = true;
			GenerateCover.EffectRemovedFn = CoverGeneratorEffectRemoved;
		}
	}
	foreach Template.AbilityTargetEffects(Effect)
	{
		GenerateCover = X2Effect_GenerateCover(Effect);
		if (GenerateCover != none && GenerateCover.EffectRemovedFn == none)
		{
			GenerateCover.bRemoveWhenTargetDies = true;
			GenerateCover.bRemoveWhenSourceDies = true;
			GenerateCover.EffectRemovedFn = CoverGeneratorEffectRemoved;
		}
	}
}

static final function CoverGeneratorEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));	

	class'X2Effect_GenerateCover'.static.UpdateWorldCoverDataOnSync(UnitState);
}
// End Issue #8

static final function PatchOverwatchAllMod()
{
	local X2CharacterTemplateManager	CharMgr;
	local array<name>					AllTemplateNames;
	local name							TemplateName;
	local array<X2DataTemplate>			AllTemplates;
	local X2DataTemplate				DataTemplate;
	local X2CharacterTemplate			CharTemplate;
	local UIScreenListener				UISL_CDO;

	// Begin Issue #4
	UISL_CDO = UIScreenListener(class'XComEngine'.static.GetClassDefaultObjectByName('UIScreenListener_TacticalHUD_OverwatchAllWotC'));
	if (UISL_CDO != none)
	{
		UISL_CDO.ScreenClass = class'UIScreen_Dummy';
	}
	else return;  // Exit if there's no UISL, meaning there is no OverwatchAll mod active.

	// Begin Issue #1
	ModifyTemplateAllDiff('OverwatchOthers', class'X2AbilityTemplate', PatchOverwatchOthersAbilityTemplate);
	ModifyTemplateAllDiff('OverwatchAll', class'X2AbilityTemplate', PatchOverwatchAllAbilityTemplate);
	// End Issue #1

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharMgr.GetTemplateNames(AllTemplateNames);
	foreach AllTemplateNames(TemplateName)
	{
		CharMgr.FindDataTemplateAllDifficulties(TemplateName, AllTemplates);
		foreach AllTemplates(DataTemplate)
		{
			CharTemplate = X2CharacterTemplate(DataTemplate);
			if (CharTemplate.bIsSoldier)
			{
				CharTemplate.Abilities.AddItem('OverwatchAll');
				CharTemplate.Abilities.AddItem('OverwatchOthers');
			}
		}
	}
	// End Issue #4
}

// Begin Issue #1
static final function PatchOverwatchOthersAbilityTemplate(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

	Template = X2AbilityTemplate(DataTemplate);

	Template.IconImage = "img:///IRI_CC_OverwatchAll.UIPerk_SmartOverwatchOthers";

	if (!default.bSkipOverrideOverwatchAllOthersShotHUDPriority)
	{
		Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY + 2;
	}

	foreach Template.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
		{
			ActionCost.iNumPoints = 1;
		}
	}
}

static final function PatchOverwatchAllAbilityTemplate(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

	Template = X2AbilityTemplate(DataTemplate);

	if (!default.bSkipOverrideOverwatchAllOthersShotHUDPriority)
	{
		Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY + 1;
	}
	Template.IconImage = "img:///IRI_CC_OverwatchAll.UIPerk_SmartOverwatchAll";

	foreach Template.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
		{
			ActionCost.iNumPoints = 1;
		}
	}
}
// End Issue #1

// Start Issue #6
// Disabled by Issue #11
//static function OnPreCreateTemplates()
//{
//	local Engine	LocalEngine;
//	local int		Index;
//
//	LocalEngine = class'Engine'.static.GetEngine();
//
//	for (Index = LocalEngine.ModClassOverrides.Length - 1; Index >= 0; Index--)
//	{
//		if (LocalEngine.ModClassOverrides[Index].ModClass == 'XComPathingPawn_GA')
//		{
//			LocalEngine.ModClassOverrides[Index].ModClass = 'XComPathingPawn_PeekFix';
//		}
//	}
//}
// End of Disabled by Issue #11
// End Issue #6

// Start Issue #12
static function bool GetValidFloorSpawnLocations(out array<Vector> FloorPoints, float SpawnSizeOverride, XComGroupSpawn SpawnPoint)
{
	local XComGameState_MissionSite	MissionSite;
	local XComGameState_BattleData	BattleData;
	local XComGameStateHistory		History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (BattleData == none)
		return false;

	MissionSite = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));
	if (MissionSite == none)
		return false;

	// Increase spawn zone if it is needed, but has not been done already.
	if (class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission(MissionSite) > 6 &&
		class'CHHelpers'.default.SPAWN_EXTRA_TILE == 0 &&
		SpawnSizeOverride <= 0)
	{
		class'CHHelpers'.default.SPAWN_EXTRA_TILE = 1;
	}
	return false;
}
// End Issue #12

// Start Issue #22
static private function PatchPlasmaGrenadeIcon(X2DataTemplate DataTemplate)
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = X2ItemTemplate(DataTemplate);
	if (ItemTemplate == none)
		return;

	ItemTemplate.strImage = "img:///IRI_CC_OverwatchAll.Inv_Plasma_GrenadeFIX";
}
// End Issue #22

// Start Issue #23
static private function FixScanningProtocolFix()
{
	local X2AbilityTemplate			AbilityTemplate;
	local X2AbilityTemplateManager	AbilityTemplateManager;
	local X2Effect_ScanningProtocol	ScanningProtocol;
	local X2Effect					Effect;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('ScanningProtocol');
	if (AbilityTemplate == none)
		return;

	foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
	{
		ScanningProtocol = X2Effect_ScanningProtocol(Effect);
		if (ScanningProtocol == none)
			continue;

		ScanningProtocol.bDisplayInUI = true;
		ScanningProtocol.BuffCategory = ePerkBuff_Penalty;
		ScanningProtocol.FriendlyName = AbilityTemplate.LocFriendlyName;
		ScanningProtocol.FriendlyDescription = AbilityTemplate.GetMyHelpText();
		ScanningProtocol.IconImage = AbilityTemplate.IconImage;
		ScanningProtocol.AbilitySourceName = AbilityTemplate.AbilitySourceName;
	}	
}
// End Issue #23

// Start Issue #26
// Vanilla uses trademark Firaxis noodle code approach of using the same condition for two different abilities.
// I separated this into two conditions and integrated community fixes from:
// [WOTC] Skulljack Mind-Controlled Enemies https://steamcommunity.com/sharedfiles/filedetails/?id=2230952627
// Codex Skulljack Fix https://steamcommunity.com/sharedfiles/filedetails/?id=929030780
// and optimized the condition code to improve performance.
// As a side effect, Skulljack will no longer appear when it's no longer relevant to the story.
static private function PatchSkulljackAbility(X2DataTemplate DataTemplate)
{
	local X2Condition_Skulljack Condition;
	local X2AbilityTemplate Template;
	local int i;

	Template = X2AbilityTemplate(DataTemplate);

	for (i = Template.AbilityTargetConditions.Length - 1; i >= 0; i--)
	{
		if (Template.AbilityTargetConditions[i].IsA('X2Condition_StasisLanceTarget') ||
			Template.AbilityTargetConditions[i].IsA('X2Condition_StasisLanceTargetFix') ||
			Template.AbilityTargetConditions[i].IsA('X2Condition_ModLanceTarget'))
		{
			`LOG("Removing Skulljack condition:" @ Template.AbilityTargetConditions[i].Class.name,, 'CCMM');
			Template.AbilityTargetConditions.Remove(i, 1);
		}
	}
	Condition = new class'X2Condition_Skulljack';
	Condition.FinalzeHackAbilityName = Template.FinalizeAbilityName;
	Template.AbilityTargetConditions.AddItem(Condition);
}

static private function PatchSkullmineAbility(X2DataTemplate DataTemplate)
{
	local X2Condition_Skullmine Condition;
	local X2AbilityTemplate Template;
	local int i;

	Template = X2AbilityTemplate(DataTemplate);

	for (i = Template.AbilityTargetConditions.Length - 1; i >= 0; i--)
	{
		if (Template.AbilityTargetConditions[i].IsA('X2Condition_StasisLanceTarget') ||
			Template.AbilityTargetConditions[i].IsA('X2Condition_StasisLanceTargetFix') ||
			Template.AbilityTargetConditions[i].IsA('X2Condition_ModLanceTarget'))
		{	
			`LOG("Removing Skullmine condition:" @ Template.AbilityTargetConditions[i].Class.name,, 'CCMM');
			Template.AbilityTargetConditions.Remove(i, 1);
		}
	}

	Condition = new class'X2Condition_Skullmine';
	Condition.FinalzeHackAbilityName = Template.FinalizeAbilityName;
	Template.AbilityTargetConditions.AddItem(Condition);
}
// End Issue #26


//	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
//	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
//	HELPER FUNCTIONS
static private function IterateTemplatesAllDiff(class TemplateClass, delegate<ModifyTemplate> ModifyTemplateFn)
{
    local X2DataTemplate                                    IterateTemplate;
    local X2DataTemplate                                    DataTemplate;
    local array<X2DataTemplate>                             DataTemplates;
    local X2DownloadableContentInfo_WOTCCoreCollection		CDO;

    local X2ItemTemplateManager             ItemMgr;
    local X2AbilityTemplateManager          AbilityMgr;
    local X2CharacterTemplateManager        CharMgr;
    local X2StrategyElementTemplateManager  StratMgr;
    local X2SoldierClassTemplateManager     ClassMgr;

    if (ClassIsChildOf(TemplateClass, class'X2ItemTemplate'))
    {
        CDO = GetCDO();
        ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

        foreach ItemMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            ItemMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {   
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2AbilityTemplate'))
    {
        CDO = GetCDO();
        AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

        foreach AbilityMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            AbilityMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2CharacterTemplate'))
    {
        CDO = GetCDO();
        CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
        foreach CharMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            CharMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2StrategyElementTemplate'))
    {
        CDO = GetCDO();
        StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
        foreach StratMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            StratMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }
    else if (ClassIsChildOf(TemplateClass, class'X2SoldierClassTemplate'))
    {

        CDO = GetCDO();
        ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
        foreach ClassMgr.IterateTemplates(IterateTemplate)
        {
            if (!ClassIsChildOf(IterateTemplate.Class, TemplateClass)) continue;

            ClassMgr.FindDataTemplateAllDifficulties(IterateTemplate.DataName, DataTemplates);
            foreach DataTemplates(DataTemplate)
            {
                CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
            }
        }
    }    
}

static private function ModifyTemplateAllDiff(name TemplateName, class TemplateClass, delegate<ModifyTemplate> ModifyTemplateFn)
{
    local X2DataTemplate                                    DataTemplate;
    local array<X2DataTemplate>                             DataTemplates;
    local X2DownloadableContentInfo_WOTCCoreCollection    CDO;

    local X2ItemTemplateManager             ItemMgr;
    local X2AbilityTemplateManager          AbilityMgr;
    local X2CharacterTemplateManager        CharMgr;
    local X2StrategyElementTemplateManager  StratMgr;
    local X2SoldierClassTemplateManager     ClassMgr;

    if (ClassIsChildOf(TemplateClass, class'X2ItemTemplate'))
    {
        ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
        ItemMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2AbilityTemplate'))
    {
        AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
        AbilityMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2CharacterTemplate'))
    {
        CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
        CharMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2StrategyElementTemplate'))
    {
        StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
        StratMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else if (ClassIsChildOf(TemplateClass, class'X2SoldierClassTemplate'))
    {
        ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
        ClassMgr.FindDataTemplateAllDifficulties(TemplateName, DataTemplates);
    }
    else return;

    CDO = GetCDO();
    foreach DataTemplates(DataTemplate)
    {
        CDO.CallModifyTemplateFn(ModifyTemplateFn, DataTemplate);
    }
}

static private function X2DownloadableContentInfo_WOTCCoreCollection GetCDO()
{
    return X2DownloadableContentInfo_WOTCCoreCollection(class'XComEngine'.static.GetClassDefaultObjectByName(default.Class.Name));
}

protected function CallModifyTemplateFn(delegate<ModifyTemplate> ModifyTemplateFn, X2DataTemplate DataTemplate)
{
    ModifyTemplateFn(DataTemplate);
}


exec function ResetBondForSelectedSoldier()
{
    local XComGameStateHistory                History;
    local UIArmory                            Armory;
    local StateObjectReference                UnitRef;
    local XComGameState_Unit                UnitState;
    local XComGameState                        NewGameState;

    Armory = UIArmory(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory'));
    if (Armory == none)
    {
        class'Helpers'.static.OutputMsg("No unit selected");
        return;
    }

    UnitRef = Armory.GetUnitRef();
    History = `XCOMHISTORY;
    UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
    if (UnitState == none)
    {
        class'Helpers'.static.OutputMsg("No unit selected");
        return;
    }
    
    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Levelup Soldier");
    UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
    class'X2StrategyGameRulesetDataStructures'.static.ResetAllBonds(NewGameState, UnitState);
    `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

    class'Helpers'.static.OutputMsg("Bond reset successfully");
    Armory.PopulateData();
}


static final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
            return true;
        }
    }
    return false;
}