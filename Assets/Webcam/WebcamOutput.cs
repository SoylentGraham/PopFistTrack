using UnityEngine;
using System.Collections;

public class WebcamOutput : MonoBehaviour {

	private WebCamTexture	mWebcamTexture;
	public string DeviceName = "";
	public RenderTexture	mOutputTexture;
	public Material			mProcessShader;
	public Material			mFlipMaterial;
	public bool				mFlip = false;
	public bool				mMirror = true;
	public Rect				mDebugViewport = new Rect(0,0,1,1);

	// Use this for initialization
	void Start () {
		#if UNITY_IOS && !UNITY_EDITOR
		mFlip =  true;
		#endif

		#if UNITY_ANDROID && !UNITY_EDITOR
		mMirror = false;
		#endif


	}
	
	// Update is called once per frame
	void Update () {
		if (!PopCheckCurrentCamera.CheckCurrentCamera ())
			return;

		if (!mWebcamTexture) {

			Application.RequestUserAuthorization(UserAuthorization.WebCam);

			string RealDeviceName = DeviceName;
#if UNITY_ANDROID
			RealDeviceName = "";
#endif
#if UNITY_IOS
			RealDeviceName = "";
#endif
			if ( RealDeviceName.Length > 0 )
			{
				mWebcamTexture = new WebCamTexture (RealDeviceName);
			}
			else
			{
				string debug = "using default webcam device. Options: ";
				foreach( WebCamDevice w in WebCamTexture.devices )
					debug += "\n" + w.name;
				Debug.Log(debug);
				mWebcamTexture = new WebCamTexture ();
			}

			if ( mWebcamTexture != null )
				mWebcamTexture.Play ();
		}

		if (mOutputTexture && mWebcamTexture) {
			mOutputTexture.DiscardContents();

			var TempTarget = mProcessShader!=null ? RenderTexture.GetTemporary(mOutputTexture.width,mOutputTexture.height,0,mOutputTexture.format) : mOutputTexture;

			//	ios camera seems to be upside down...
			if ( mFlipMaterial )
			{
				mFlipMaterial.SetInt("Flip", mFlip?1:0 );
				mFlipMaterial.SetInt("Mirror",mMirror?1:0 );
				Graphics.Blit (mWebcamTexture, TempTarget, mFlipMaterial );
			}
			else
			{
				Graphics.Blit (mWebcamTexture, TempTarget );
			}

			if ( TempTarget != mOutputTexture )
			{
				Graphics.Blit( TempTarget, mOutputTexture, mProcessShader );
				RenderTexture.ReleaseTemporary( TempTarget );
			}
		}
	}

	void OnDisable()
	{
		if (mWebcamTexture != null) {
			mWebcamTexture.Stop ();
			mWebcamTexture = null;
		}
	}

	void OnGUI()
	{
		if (!Camera.current)
			return;
		if ( mOutputTexture != null )
			GUI.DrawTexture( new Rect(mDebugViewport.x*Screen.width,mDebugViewport.y*Screen.height,mDebugViewport.width*Screen.width,mDebugViewport.height*Screen.height), mOutputTexture );
	}
}

