using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ActiveCamoObject {
	public Renderer renderer;
	public Material material;
}

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class ActiveCamoCommandBuffer : MonoBehaviour {

	public static ActiveCamoCommandBuffer instance;

	private CommandBuffer rbDrawAC;
	[SerializeField]
	private CameraEvent rbDrawACQueue = CameraEvent.AfterForwardOpaque;

	private HashSet<ActiveCamoObject> acObjects = new HashSet<ActiveCamoObject>();
	private Camera thisCamera;
	private bool updateActiveCamoCB = false;

	void Awake(){
		ActiveCamoCommandBuffer.instance = this;
	}

	void OnEnable() {
		thisCamera = GetComponent<Camera> ();

		rbDrawAC = new CommandBuffer();
		rbDrawAC.name = "DrawActiveCamo";
		thisCamera.AddCommandBuffer(rbDrawACQueue, rbDrawAC);
		updateActiveCamoCB = true;
	}

	void OnDisable() {
		if (rbDrawAC != null) {
			thisCamera.RemoveCommandBuffer(rbDrawACQueue, rbDrawAC);
			rbDrawAC = null;
		}
	}

	public void AddRenderer( ActiveCamoObject newObject ) {
		acObjects.Add (newObject);
		updateActiveCamoCB = true;
	}

	public void RemoveRenderer( ActiveCamoObject newObject ) {
		acObjects.Remove (newObject);
		updateActiveCamoCB = true;
	}

	void RebuildCBActiveCamo(){
		rbDrawAC.Clear ();
		foreach( ActiveCamoObject acObject in acObjects ){
			rbDrawAC.DrawRenderer(acObject.renderer, acObject.material);
		}
		updateActiveCamoCB = false;
		// use if rebuilding command buffer every frame
		//acObjects.Clear (); 
	}

	void OnPreRender(){
		if (updateActiveCamoCB) {
			RebuildCBActiveCamo ();
		}
	}
}
