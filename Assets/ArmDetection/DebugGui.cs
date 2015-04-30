using UnityEngine;
using System.Collections;

public class DebugGui : MonoBehaviour {

	public MotionTextureGenerator mMotionTextureGenerator;
	public BackgroundLearner	mBackgroundLearner;
	public Material BackgroundJustLumMaterial;
	public Material BackgroundJustScoreMaterial;
	private RenderTexture		mJustLumTexture;
	private RenderTexture		mJustScoreTexture;
	public RenderTextureFormat	mTempTextureFormat = RenderTextureFormat.ARGBFloat;
	public FilterMode			mTempTextureFilterMode = FilterMode.Point;

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {

		//	reset
		if (Input.GetMouseButtonDown (0)) {
			if (mBackgroundLearner != null)
				mBackgroundLearner.OnDisable ();
		}
	
		//	update intermediate textures
		if ( mBackgroundLearner != null )
			UpdateTempTexture( mBackgroundLearner.mBackgroundTexture, BackgroundJustLumMaterial, ref mJustLumTexture );
		
		if ( mBackgroundLearner != null )
			UpdateTempTexture( mBackgroundLearner.mBackgroundTexture, BackgroundJustScoreMaterial, ref mJustScoreTexture );
		
	
	}


	void UpdateTempTexture(Texture texture,Material material,ref RenderTexture TempTexture)
	{
		if (material == null)
			return;
		
		if (TempTexture == null) {
			TempTexture = new RenderTexture (texture.width, texture.height, 0, mTempTextureFormat);
			TempTexture.filterMode = mTempTextureFilterMode;
		}

		Graphics.Blit (texture, TempTexture, material);
	}

	void DrawTexture(int ScreenSectionX,int ScreenSectionY,Texture texture)
	{
		if (texture == null)
			return;

		float Sectionsx = Screen.width / 3;
		float Sectionsy = Screen.height / 3;
		Rect rect = new Rect( Sectionsx*ScreenSectionX, Sectionsy*ScreenSectionY, Sectionsx, Sectionsy );

		GUI.DrawTexture (rect, texture);
	}


	void OnGUI()
	{
		if ( mMotionTextureGenerator != null )
			DrawTexture( 1, 0, mMotionTextureGenerator.mLumTexture );
		
		if ( mMotionTextureGenerator != null )
			DrawTexture( 0, 1, mMotionTextureGenerator.mMotionTexture );

		if (mBackgroundLearner != null)
			DrawTexture (1, 1, mBackgroundLearner.mBackgroundTexture);

		if ( mJustLumTexture != null )
			DrawTexture( 2, 1, mJustLumTexture );

		if ( mJustScoreTexture != null )
			DrawTexture( 2, 2, mJustScoreTexture );

	}
}
