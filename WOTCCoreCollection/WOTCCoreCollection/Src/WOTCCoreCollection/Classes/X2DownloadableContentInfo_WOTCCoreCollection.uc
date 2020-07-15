class X2DownloadableContentInfo_WOTCCoreCollection extends X2DownloadableContentInfo dependson(X2EventListener_CCMM);

static event OnPostTemplatesCreated()
{
	local name SomeName;
	local YAF1_AutopsyRequirementStruct SomeStruct;

	foreach class'X2EventListener_CCMM'.default.YAF1_AutopsyRequirement(SomeStruct)
	{
		foreach SomeStruct.CharacterTemplates(SomeName)
		{
			`LOG(SomeName,, 'CCMM');
		}
	}
	// Issue #1
	PatchOverwatchAllMod();	
}

static function PatchOverwatchAllMod()
{
	local X2AbilityTemplate				Template;
    local X2AbilityTemplateManager		AbilityTemplateManager;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    Template = AbilityTemplateManager.FindAbilityTemplate('OverwatchOthers');
    if (Template != none)
    {
		foreach Template.AbilityCosts(AbilityCost)
		{
			ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
			if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
			{
				ActionCost.iNumPoints = 1;
			}
		}
    }
	Template = AbilityTemplateManager.FindAbilityTemplate('OverwatchAll');
    if (Template != none)
    {
		foreach Template.AbilityCosts(AbilityCost)
		{
			ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
			if (ActionCost != none && ActionCost.bFreeCost && ActionCost.bConsumeAllPoints)
			{
				ActionCost.iNumPoints = 1;
			}
		}
    }
}