using UnityEngine;
using System.Collections;


public class ProductionGui : MonoBehaviour {

	public DragGenerator		mDragGenerator;
	public BackgroundLearner	mBackgroundLearner;
	public MotionTextureGenerator	mMotionTextureGenerator;
	public JointGenerator		mJointGenerator;
	public MaskGenerator		mMaskGenerator;
	public RenderTexture		mBackgroundTexture;
	public Texture				mCameraTexture;
	public bool					mAutoReset = false;
	private float				mResetCountdownInterval = 5.0f;
	private float				mResetCountdown = 0.0f;
	private int					mCycleJointIndex = 0;
	public bool					mCycleJoints = false;
	public bool					mDebugTextures = false;
	public bool					mShowBackgroundLum = false;
	public Material				mBackgroundLumShader;
	private RenderTexture		mBackgroundLum;
	public Material				mAdjustToMotionShader;
	private RenderTexture		mMotionAdjustedGuiTexture;
	private RenderTextureFormat	mMotionAdjustedGuiTextureFormat = RenderTextureFormat.ARGB32;

	[Range(0,1)]
	public float 				mBackgroundAlpha = 0.5f;

	void Start()
	{
		Application.targetFrameRate = 60;
	}

	void Update()
	{
		bool Reset = Input.GetMouseButtonDown (0);

		//	every so often, reset for testing
		if (mAutoReset) {
			mResetCountdown -= Time.deltaTime;
			if (mResetCountdown < 0.0f) {
				Reset = true;
				mResetCountdown = mResetCountdownInterval;
			}
		}

		//	reset
		if (Reset) {
			if (mBackgroundLearner != null)
				mBackgroundLearner.OnDisable ();
			if ( mMotionTextureGenerator != null )
				mMotionTextureGenerator.OnDisable();
			if( mDragGenerator != null )
				mDragGenerator.OnDisable();
		}

		if (mShowBackgroundLum && mBackgroundLumShader != null && mBackgroundTexture != null) {
			if (!mBackgroundLum)
				mBackgroundLum = new RenderTexture (mBackgroundTexture.width, mBackgroundTexture.height, mBackgroundTexture.depth, mBackgroundTexture.format);

			Graphics.Blit (mBackgroundTexture, mBackgroundLum, mBackgroundLumShader);
		}

		if (mAdjustToMotionShader && mMotionTextureGenerator) {
			var GuiTexture = GetGuiRenderTexture (false);
			if ( mMotionAdjustedGuiTexture == null )
				mMotionAdjustedGuiTexture = new RenderTexture( GuiTexture.width, GuiTexture.height, 0, mMotionAdjustedGuiTextureFormat );

			mAdjustToMotionShader.SetTexture("MotionTexture", mMotionTextureGenerator.mMotionTexture );
			Graphics.Blit( GuiTexture, mMotionAdjustedGuiTexture, mAdjustToMotionShader );
		}

		//	fix texture leak by forcing unity to unload assets
		//	gr: killing IOS performance
#if UNITY_IOS
		//Resources.UnloadUnusedAssets();
#else
		Resources.UnloadUnusedAssets();
#endif
	}

	Texture GetGuiRenderTexture(bool IncludeMotionAdjusted=true)
	{
		if (IncludeMotionAdjusted && mAdjustToMotionShader && mMotionAdjustedGuiTexture)
			return mMotionAdjustedGuiTexture;

		if (mCameraTexture != null)
			return mCameraTexture;

		if ( mBackgroundTexture != null)
			return mBackgroundTexture;
		
		if ( mShowBackgroundLum && mBackgroundLum )
			return mBackgroundLum;

		if ( mJointGenerator != null )
			return mJointGenerator.GetCopyTexture();

		return null;
	}

	// Update is called once per frame
	void OnGUI () {
		Camera camera = this.GetComponent<Camera> ();
		if (!camera)
			return;

		Rect ScreenRect = camera.pixelRect;

		Texture GuiRenderTexture = GetGuiRenderTexture ();

		if (GuiRenderTexture) {
			var OldColour = GUI.color;
			GUI.color = new Color(1,1,1,mBackgroundAlpha);
			GUI.DrawTexture (ScreenRect, GuiRenderTexture);
			GUI.color = OldColour;
		}

		//	render joints
		if (mJointGenerator != null && mJointGenerator.mJoints!=null)
		{
			mCycleJointIndex = (mCycleJointIndex+1) % Mathf.Max(mJointGenerator.mJoints.Count,1);

			for (int i=0; i<mJointGenerator.mJoints.Count; i++) {
				if ( mCycleJointIndex == i || !mCycleJoints )
					JointDebug.DrawJoint (mJointGenerator.mJoints [i], ScreenRect );
			}

		}
	
		if (mJointGenerator) {

			string debug = "";
			Texture2D[] AllTextures = GameObject.FindObjectsOfType<Texture2D>();
			int Texture2DCount = AllTextures.Length;
			debug += "Texture2D count: " +  Texture2DCount + "\n";

			if ( mDebugTextures )
			{
				for ( int i=0;	i<Mathf.Min(30,AllTextures.Length);	i++ )
					debug += AllTextures[i].name + " ";
				debug += "\n";
			}

			debug += mJointGenerator.mDebug;
			GUI.Label (ScreenRect, debug);
		}
	}
}
