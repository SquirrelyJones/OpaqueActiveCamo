using System;
using System.Collections;
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
	private CameraEvent rbDrawACQueue = CameraEvent.BeforeForwardAlpha;

	private CommandBuffer rbFrame;
	[SerializeField]
	private CameraEvent rbFrameQueue = CameraEvent.AfterForwardAlpha;

    public RenderTexture lastFrame;
	public RenderTexture lastFrameTemp;
	private RenderTargetIdentifier lastFrameRTI;
	private int screenX = 0;
	private int screenY = 0;

	private HashSet<ActiveCamoObject> acObjects = new HashSet<ActiveCamoObject>();

	private Camera thisCamera;

	private bool updateActiveCamoRB = false;

	private bool init = false;

	void Awake(){
		ActiveCamoCommandBuffer.instance = this;
	}

	void OnEnable() {

		thisCamera = GetComponent<Camera> ();

		rbDrawAC = new CommandBuffer();
		rbDrawAC.name = "DrawActiveCamo";
		thisCamera.AddCommandBuffer(rbDrawACQueue, rbDrawAC);
		updateActiveCamoRB = true;

		rbFrame = new CommandBuffer();
		rbFrame.name = "FrameCapture";
		thisCamera.AddCommandBuffer(rbFrameQueue, rbFrame);

		RebuildCBFrame ();

		Shader.SetGlobalFloat( "_GlobalActiveCamo", 1.0f );
	}

	void OnDisable() {
		if (rbDrawAC != null)
		{
			thisCamera.RemoveCommandBuffer(rbDrawACQueue, rbDrawAC);
			rbDrawAC = null;
		}

		if (rbFrame != null)
		{
			thisCamera.RemoveCommandBuffer(rbFrameQueue, rbFrame);
			rbFrame = null;
		}

		if (lastFrame != null)
		{
			lastFrame.Release();
			lastFrame = null;
		}

		Shader.SetGlobalFloat( "_GlobalActiveCamo", 0.0f );
	}


	void Start(){
		screenX = thisCamera.pixelWidth;
		screenY = thisCamera.pixelHeight;
	}

	public void AddRenderer( ActiveCamoObject newObject ) {
		acObjects.Add (newObject);
		updateActiveCamoRB = true;
	}

	public void RemoveRenderer( ActiveCamoObject newObject ) {
		acObjects.Remove (newObject);
		updateActiveCamoRB = true;
	}

	void RebuildCBFrame()
	{
		rbFrame.Clear ();

		if (lastFrame != null) {
			lastFrameTemp = RenderTexture.GetTemporary(lastFrame.width, lastFrame.height, 0, RenderTextureFormat.DefaultHDR);
			Graphics.Blit (lastFrame, lastFrameTemp);

			lastFrame.Release();
			lastFrame = null;
		}

		lastFrame = new RenderTexture(thisCamera.pixelWidth/2, thisCamera.pixelHeight/2, 0, RenderTextureFormat.DefaultHDR);
		lastFrame.wrapMode = TextureWrapMode.Clamp;
		lastFrame.Create ();
		lastFrameRTI = new RenderTargetIdentifier(lastFrame);

		if (lastFrameTemp != null) {
			Graphics.Blit (lastFrameTemp, lastFrame);
			RenderTexture.ReleaseTemporary (lastFrameTemp);
			lastFrameTemp = null;
		}

		Shader.SetGlobalTexture ("_LastFrame", lastFrame);

		RenderTargetIdentifier cameraTargetID = new RenderTargetIdentifier(BuiltinRenderTextureType.CameraTarget);
		rbFrame.SetRenderTarget (lastFrame);
		rbFrame.Blit(cameraTargetID, lastFrameRTI);
	}

	void RebuildCBActiveCamo(){
		rbDrawAC.Clear ();
		RenderTargetIdentifier cameraTargetID = new RenderTargetIdentifier(BuiltinRenderTextureType.CameraTarget);
		rbFrame.SetRenderTarget (cameraTargetID);
		foreach( ActiveCamoObject acObject in acObjects ){
			rbDrawAC.DrawRenderer(acObject.renderer, acObject.material);
		}
		updateActiveCamoRB = false;
		// use if rebuilding command buffer every frame
		//acObjects.Clear (); 
	}

	void OnPreRender(){
		if (screenX != thisCamera.pixelWidth || screenY != thisCamera.pixelHeight) {
			RebuildCBFrame ();
		}

		if (updateActiveCamoRB) {
			RebuildCBActiveCamo ();
		}
	}
		
}
