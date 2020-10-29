class X2DownloadableContentInfo_WOTCCoreCollection extends X2DownloadableContentInfo;

delegate ModifyTemplate(X2DataTemplate DataTemplate);

static event OnPostTemplatesCreated()
{
	// Issue #1
	// Issue #4
	PatchOverwatchAllMod();	

	// Issue #8
	ModifyTemplateAllDiff('ConstantHighCover', class'X2AbilityTemplate', PatchTurretsCoverAbility);
	ModifyTemplateAllDiff('ConstantLowCover', class'X2AbilityTemplate', PatchTurretsCoverAbility);
}

// Begin Issue #8
static function PatchTurretsCoverAbility(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate			Template;
	local X2Effect					Effect;
	local X2Effect_GenerateCover	GenerateCover;

	Template = X2AbilityTemplate(DataTemplate);
	
	foreach Template.AbilityShooterEffects(Effect)
	{
		GenerateCover = X2Effect_GenerateCover(Effect);
		if (GenerateCover != none)
		{
			GenerateCover.bRemoveWhenTargetDies = true;
			GenerateCover.bRemoveWhenSourceDies = true;
			GenerateCover.EffectRemovedFn = TurretCoverEffectRemoved;
		}
	}
}

static function TurretCoverEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));	

	class'X2Effect_GenerateCover'.static.UpdateWorldCoverDataOnSync(UnitState);
}
// End Issue #8

static function PatchOverwatchAllMod()
{
	local X2CharacterTemplateManager	CharMgr;
	local array<name>					AllTemplateNames;
	local name							TemplateName;
	local array<X2DataTemplate>			AllTemplates;
	local X2DataTemplate				DataTemplate;
	local X2CharacterTemplate			CharTemplate;
	local UIScreenListener				UISL_CDO;

	// Begin Issue #1
	ModifyTemplateAllDiff('OverwatchOthers', class'X2AbilityTemplate', PatchOverwatchOthersAbilityTemplate);
	ModifyTemplateAllDiff('OverwatchOthers', class'X2AbilityTemplate', PatchOverwatchAllAbilityTemplate);
	// End Issue #1

	// Begin Issue #4
	UISL_CDO = UIScreenListener(class'XComEngine'.static.GetClassDefaultObjectByName('UIScreenListener_TacticalHUD_OverwatchAllWotC'));
	if (UISL_CDO != none)
	{
		UISL_CDO.ScreenClass = class'UIScreen_Dummy';
	}

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
static function PatchOverwatchOthersAbilityTemplate(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

	Template = X2AbilityTemplate(DataTemplate);

	Template.IconImage = "img:///IRI_CC_OverwatchAll.UIPerk_SmartOverwatchOthers";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY + 2;

	foreach Template.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
		{
			ActionCost.iNumPoints = 1;
		}
	}
}

static function PatchOverwatchAllAbilityTemplate(X2DataTemplate DataTemplate)
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

	Template = X2AbilityTemplate(DataTemplate);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY + 1;
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
static function OnPreCreateTemplates()
{
	local Engine	LocalEngine;
	local int		Index;

	LocalEngine = class'Engine'.static.GetEngine();

	for (Index = LocalEngine.ModClassOverrides.Length - 1; Index >= 0; Index--)
	{
		if (LocalEngine.ModClassOverrides[Index].ModClass == 'XComPathingPawn_GA')
		{
			LocalEngine.ModClassOverrides[Index].ModClass = 'XComPathingPawn_PeekFix';
		}
	}
}
// End Issue #6

//	--------------------------------------------------------------------------
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