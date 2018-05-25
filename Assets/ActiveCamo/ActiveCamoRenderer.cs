using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ActiveCamoRenderer : MonoBehaviour {

	private Renderer thisRenderer;
	public Material ActiveCamoMaterial;
	private MaterialPropertyBlock MPB;
	private ActiveCamoObject acObject;
	[HideInInspector]
	public float ActiveCamoRamp = 0.0f;

	void Start(){
		MPB = new MaterialPropertyBlock ();
		thisRenderer = GetComponent<Renderer> ();
		acObject = new ActiveCamoObject();
		acObject.renderer = thisRenderer;
		acObject.material = ActiveCamoMaterial;
	}

	// use if rebuilding command buffer every frame
	//void OnWillRenderObject(){
	//	ActiveCamoCommandBuffer.instance.AddRenderer (acObject);
	//}

	void OnBecameVisible(){
		ActiveCamoCommandBuffer.instance.AddRenderer (acObject);
	}

	void OnBecameInvisible() {
		ActiveCamoCommandBuffer.instance.RemoveRenderer (acObject);
	}

	void Update () {
		MPB.SetFloat ("_ActiveCamoRamp", ActiveCamoRamp);
		thisRenderer.SetPropertyBlock (MPB);
	}
}
