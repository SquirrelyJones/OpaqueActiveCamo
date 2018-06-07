using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class FrameGrabCommandBuffer : MonoBehaviour {

	private CommandBuffer rbFrame;
	[SerializeField]
	private CameraEvent rbFrameQueue = CameraEvent.AfterForwardAlpha;

	public RenderTexture lastFrame;
	public RenderTexture lastFrameTemp;
	private RenderTargetIdentifier lastFrameRTI;

	private int screenX = 0;
	private int screenY = 0;
	private Camera thisCamera;

	void OnEnable() {

		thisCamera = GetComponent<Camera> ();

		rbFrame = new CommandBuffer();
		rbFrame.name = "FrameCapture";
		thisCamera.AddCommandBuffer(rbFrameQueue, rbFrame);

		RebuildCBFrame ();

		Shader.SetGlobalFloat( "_GlobalActiveCamo", 1.0f );
	}

	void OnDisable() {
		
		if (rbFrame != null) {
			thisCamera.RemoveCommandBuffer(rbFrameQueue, rbFrame);
			rbFrame = null;
		}

		if (lastFrame != null) {
			lastFrame.Release();
			lastFrame = null;
		}

		Shader.SetGlobalFloat( "_GlobalActiveCamo", 0.0f );
	}

	void RebuildCBFrame() {
		
		rbFrame.Clear ();

		if (lastFrame != null) {
			lastFrameTemp = RenderTexture.GetTemporary(lastFrame.width, lastFrame.height, 0, RenderTextureFormat.DefaultHDR);
			Graphics.Blit (lastFrame, lastFrameTemp);
			lastFrame.Release();
			lastFrame = null;
		}

		screenX = thisCamera.pixelWidth;
		screenY = thisCamera.pixelHeight;

		lastFrame = new RenderTexture(screenX/2, screenY/2, 0, RenderTextureFormat.DefaultHDR);
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
		rbFrame.Blit(cameraTargetID, lastFrameRTI);
	}
		
	void OnPreRender(){
		
		if (screenX != thisCamera.pixelWidth || screenY != thisCamera.pixelHeight) {
			RebuildCBFrame ();
		}
	}

}