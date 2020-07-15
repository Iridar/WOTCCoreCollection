class X2DownloadableContentInfo_WOTCCoreCollection extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
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