using UnityEngine;
using System.Collections;
using System.Collections.Generic;


public class FeatureResults
{
	public int				mTotalResults = 0;
	public List<Vector4>	mMatches = new List<Vector4>();

	public float			GetMatchLength(int Index)
	{
		Vector2 Delta = new Vector2 (mMatches [Index].x - mMatches [Index].z, mMatches [Index].y - mMatches [Index].w);
		return Delta.magnitude;
	}
};

public class FeatureTracker : MonoBehaviour {

	public Material			mMakeFeaturesShader;
	public int				mTrackFrameLag = 5;			//	may need this? but to test algo we need the tracking over X frames to get significant movement
	private List<RenderTexture>	mFeaturesPrev;			//	feature per pixel
	public RenderTexture	mFeatures;
	public Material			mTrackFeaturesShader;
	public RenderTexture	mTrackedFeatures;	//	per pixel feature's best match (offset)
	public RenderTexture	mInput;
	public RenderTexture	mInputBlurred;
	public Material			mInputBlurShader;
	private Texture2D		mTrackedFeaturesDataTexture;
	private TextureFormat	mTrackedFeaturesDataTextureFormat = TextureFormat.ARGB32;
	private Color32[]		mTrackedFeaturesData;
	public FeatureResults	mFeatureResults;
	public int 				mRansacSamples = 10;
	public bool 			mLockPrevFeatures = false;
	public bool				mShowInput = true;
	[Range(0,10)]
	public float			mRenderMinDelta = 0.0f;

	// Use this for initialization
	void Start () {
		mFeaturesPrev = new List<RenderTexture> ();
		mTrackedFeaturesDataTexture = null;
		mTrackedFeaturesData = null;
		Resources.UnloadUnusedAssets ();
	}

	public void OnDisable()
	{
		Start();
	}

	// Update is called once per frame
	void Update () {
	
		//	generate features
		if (!mMakeFeaturesShader || !mInput || !mFeatures)
			return;

		if (mInputBlurred) {
			if ( mInputBlurShader )
			{
				mInputBlurShader.SetFloat("Time", Time.timeSinceLevelLoad );
				Graphics.Blit (mInput, mInputBlurred, mInputBlurShader);
			}
			else
				Graphics.Blit (mInput, mInputBlurred);
			Graphics.Blit (mInputBlurred, mFeatures, mMakeFeaturesShader);
		} else {
			Graphics.Blit (mInput, mFeatures, mMakeFeaturesShader);
		}

		//	pop oldest prev features
		//	gr: may need to hold onto it until we've moved significantly, 
		//		if we don't use an old frame, maybe don't want any others and make the latest (significant change) the next to pop
		RenderTexture FeaturesPrev = null;
		if (mFeaturesPrev.Count >= mTrackFrameLag) {
			FeaturesPrev = mFeaturesPrev [0];

			if ( !mLockPrevFeatures )
				mFeaturesPrev.RemoveAt (0);
		}

			//	find the feature's best match
		if (FeaturesPrev && mTrackFeaturesShader && mTrackedFeatures ) 
		{
			if (! mTrackedFeaturesDataTexture )
				mTrackedFeaturesDataTexture = new Texture2D( mTrackedFeatures.width, mTrackedFeatures.height, mTrackedFeaturesDataTextureFormat, false );
			mTrackFeaturesShader.SetTexture("FeaturesPrev", FeaturesPrev );
			Graphics.Blit( mFeatures, mTrackedFeatures, mTrackFeaturesShader );

			//	extract data for debug rendering
			RenderTexture.active = mTrackedFeatures;
			mTrackedFeaturesDataTexture.ReadPixels(new Rect (0, 0, mTrackedFeatures.width, mTrackedFeatures.height), 0, 0);
			mTrackedFeaturesDataTexture.Apply (true);
			mTrackedFeaturesData = mTrackedFeaturesDataTexture.GetPixels32();
			RenderTexture.active = null;
		}

		//	push features onto prev list
		if (mFeaturesPrev.Count < mTrackFrameLag) {
			//	re-use texture
			if (!FeaturesPrev)
				FeaturesPrev = new RenderTexture (mFeatures.width, mFeatures.height, mFeatures.depth, mFeatures.format);
			Graphics.Blit (mFeatures, FeaturesPrev);
			mFeaturesPrev.Add (FeaturesPrev);
		}


		//	calc feature pairs
		if ( mTrackedFeaturesData != null && mTrackedFeaturesDataTexture != null )
			mFeatureResults = CalcFeaturePairs (mTrackedFeaturesData,mTrackedFeaturesDataTexture.width, mTrackedFeaturesDataTexture.height, mRansacSamples);
	}

	FeatureResults CalcFeaturePairs(Color32[] TrackedFeaturesData,int ImageWidth,int ImageHeight,int RansacSamples)
	{
		FeatureResults Results = new FeatureResults ();

		//	count matches
		for (int i=0; i<mTrackedFeaturesData.Length; i++)
		{
			if ( mTrackedFeaturesData [i].a < 1 )
				continue;
			Results.mTotalResults ++;

			if ( Results.mMatches.Count >= RansacSamples )
				continue;

			int y = i / ImageWidth;
			int x = i % ImageWidth;
			float Startu = x /(float)ImageWidth;
			float Startv = y /(float)ImageHeight;
			float Endu = (mTrackedFeaturesData [i].r / 255.0f);
			float Endv = (mTrackedFeaturesData [i].g / 255.0f);
			Vector4 Match = new Vector4( Startu, Startv, Endu, Endv );
			Results.mMatches.Add( Match );
		}

		return Results;
	}
	static void FitToRect(ref float LengthNorm,Rect rect)
	{
		LengthNorm *= rect.width;
	}
	
	static void FitToRect(ref Vector2 PosNorm,Rect rect)
	{
		if (PosNorm.x < 0)
			PosNorm.x = 0;
		if (PosNorm.y < 0)
			PosNorm.y = 0;
		if (PosNorm.x > 1)
			PosNorm.x = 1;
		if (PosNorm.y > 1)
			PosNorm.y = 1;
		
		//	y is inverted... at source? not the line drawing code?
		PosNorm.y = 1.0f - PosNorm.y;
		
		PosNorm.x *= rect.width;
		PosNorm.y *= rect.height;
		PosNorm.x += rect.xMin;
		PosNorm.y += rect.yMin;
	}
	public static void DrawMatch(Vector4 joint,Rect ScreenRect,Color Colour)
	{
		Vector2 Start = new Vector2 (joint.x, joint.y);
		Vector2 Middle = new Vector2 (joint.z, joint.w);
		FitToRect( ref Start, ScreenRect );
		FitToRect( ref Middle, ScreenRect );

		GuiHelper.DrawLine( Start, Middle, Colour );
	}
	void OnGUI()
	{
		Rect a = new Rect(0,0,Screen.width/2,Screen.height);
		GUI.DrawTexture (a, mFeatures);
	
		Rect b = new Rect(Screen.width/2,0,Screen.width/2,Screen.height);
		if (mShowInput) {
			GUI.DrawTexture (b, mInputBlurred ? mInputBlurred : mInput);
		} else {
			GUI.DrawTexture (b, mTrackedFeatures);
		}

		int FilteredResults = 0;

		//	render matches
		if ( mFeatureResults != null )
		{
			for ( int i=0;	i<mFeatureResults.mMatches.Count;	i++ )
			{
				bool Fast = ( mFeatureResults.GetMatchLength(i) * 128.0f >= mRenderMinDelta );
				DrawMatch( mFeatureResults.mMatches[i], b, Fast ? Color.green : Color.red );
				FilteredResults++;
			}
		}

		if ( mFeatureResults != null )
			GUI.Label( a, "matched features: " + FilteredResults + "/" + mFeatureResults.mTotalResults );

	}
}
