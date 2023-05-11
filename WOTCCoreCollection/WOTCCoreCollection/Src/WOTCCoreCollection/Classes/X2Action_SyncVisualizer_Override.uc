class X2Action_SyncVisualizer_Override extends X2Action_SyncVisualizer;

// Issue #18 - temporary bandaid fix for SyncVisualizer running for removed state objects.
function SyncVisualizer()
{
	local X2VisualizedInterface VisualizedObject;

	VisualizedObject = X2VisualizedInterface(Metadata.StateObject_NewState);
	if (VisualizedObject != none && !Metadata.StateObject_NewState.bRemoved) // Don't SyncVis for removed state objects.
	{
		VisualizedObject.SyncVisualizer(StateChangeContext.AssociatedState);
	}
}
