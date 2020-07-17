class X2DownloadableContentInfo_WOTCCoreCollection extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	// Issue #1
	// Issue #4
	PatchOverwatchAllMod();	
}

static function PatchOverwatchAllMod()
{
	local X2AbilityTemplate				Template;
    local X2AbilityTemplateManager		AbilityTemplateManager;
	local X2AbilityCost					AbilityCost;
	local X2AbilityCost_ActionPoints	ActionCost;

	local X2CharacterTemplateManager	CharMgr;
	local array<name>					AllTemplateNames;
	local name							TemplateName;
	local array<X2DataTemplate>			AllTemplates;
	local X2DataTemplate				DataTemplate;
	local X2CharacterTemplate			CharTemplate;
	local UIScreenListener				UISL_CDO;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// Begin Issue #1
    Template = AbilityTemplateManager.FindAbilityTemplate('OverwatchOthers');
	Template.IconImage = "img:///IRI_CC_OverwatchAll.UIPerk_SmartOverwatchOthers";
    if (Template != none)
    {
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
	Template = AbilityTemplateManager.FindAbilityTemplate('OverwatchAll');
    if (Template != none)
    {
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