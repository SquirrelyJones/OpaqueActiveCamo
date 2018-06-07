using UnityEngine;

public class ActiveCamoController : MonoBehaviour {

	[SerializeField]
	private ActiveCamoRenderer[] activeCamoRenderers;

	[SerializeField]
	[Range (0f,1f)]
	private float ActiveCamoRamp = 0.0f;
	
	// Update is called once per frame
	void Update () {
		for (int i = 0; i < activeCamoRenderers.Length; i++) {
			activeCamoRenderers [i].ActiveCamoRamp = ActiveCamoRamp;
		}
	}
}
