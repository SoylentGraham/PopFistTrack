using UnityEngine;
using System.Collections;
using System.Collections.Generic;


public class FeatureMatcher : MonoBehaviour {

	public RenderTexture	mInputPrev;
	public RenderTexture	mInputNext;
	private bool			mCopyToPrev = false;
	public Material			mMakeFeaturesShader;
	public RenderTexture	mFeaturesPrev;
	public RenderTexture	mFeaturesNext;
	public Material			mTrackFeaturesShader;
	public RenderTexture	mFeatureMatches;
	public Rect				mDebugRectPrev = new Rect(0,0,0.5f,1);
	public Rect				mDebugRectNext = new Rect(0.5f,0,0.5f,1);
	public bool				mDrawJoints = true;
	public FeatureResults	mJoints;
	private Texture2D		mFeatureMatchesBuffer;
	[Range(0,10000)]
	public int				mMaxResults = 100;
	[Range(0,10)]
	public float			mRenderMinDelta = 1.0f;

	public RenderTexture	mRenderLeft;
	public RenderTexture	mRenderRight;
	public RenderTexture	mRenderRightAlpha;

	// Use this for initialization
	void Start () {
		if ( !mInputPrev && mInputNext )
		{
			mCopyToPrev = true;
			mInputPrev = new RenderTexture( mInputNext.width, mInputNext.height, mInputNext.depth, mInputNext.format );
		}

		if ( !mFeaturesPrev && mFeaturesNext )
			mFeaturesPrev = new RenderTexture( mFeaturesNext.width, mFeaturesNext.height, mFeaturesNext.depth, mFeaturesNext.format );
	}
	
	// Update is called once per frame
	void Update () {
		if (!PopCheckCurrentCamera.CheckCurrentCamera ())
			return;


		if (!mInputPrev || 
			!mInputNext ||
			!mMakeFeaturesShader ||
			!mFeaturesPrev ||
			!mFeaturesNext ||
			!mTrackFeaturesShader ||
			!mFeatureMatches
		   ) {
			Debug.Log ("FeatureMatcher not setup");
			return;
		}

		//	make features for both inputs
		mFeaturesPrev.DiscardContents ();
		mFeaturesNext.DiscardContents ();
		Graphics.Blit (mInputPrev, mFeaturesPrev, mMakeFeaturesShader);
		Graphics.Blit (mInputNext, mFeaturesNext, mMakeFeaturesShader);

		//	match features
		mTrackFeaturesShader.SetTexture ("FeaturesPrev", mFeaturesPrev);
		Graphics.Blit (mFeaturesNext, mFeatureMatches, mTrackFeaturesShader);

		FeatureTrackOptions Options = new FeatureTrackOptions ();
		Options.MaxResults = mMaxResults;
		mJoints = FeatureTracker.GetFeatureTracks (mFeatureMatches, ref mFeatureMatchesBuffer, Options);

		if (mCopyToPrev)
			Graphics.Blit (mInputNext, mInputPrev);
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
		var TexturePrev = mRenderLeft;
		var TextureNext = mRenderRight;

		if ( TexturePrev != null )
			GUI.DrawTexture( new Rect(mDebugRectPrev.x*Screen.width,mDebugRectPrev.y*Screen.height,mDebugRectPrev.width*Screen.width,mDebugRectPrev.height*Screen.height), TexturePrev );

		if (TextureNext != null) {
			GUI.DrawTexture (new Rect (mDebugRectNext.x * Screen.width, mDebugRectNext.y * Screen.height, mDebugRectNext.width * Screen.width, mDebugRectNext.height * Screen.height), TextureNext);

			if (mRenderRightAlpha) {
				GUI.color = new Color (1, 1, 1, 0.5f);
				GUI.DrawTexture (new Rect (mDebugRectNext.x * Screen.width, mDebugRectNext.y * Screen.height, mDebugRectNext.width * Screen.width, mDebugRectNext.height * Screen.height), mRenderRightAlpha);
				GUI.color = new Color (1, 1, 1, 0.5f);
			}
		}

		if (mDrawJoints) {
		
			var MapJointRect = mDebugRectNext;
			Rect JointRect = new Rect(MapJointRect.x*Screen.width,MapJointRect.y*Screen.height,MapJointRect.width*Screen.width,MapJointRect.height*Screen.height );

			if ( mJoints!=null )
			for(int i=0;i<mJoints.mMatches.Count;	i++ )
			{
				bool Fast = ( mJoints.GetMatchLength(i) * 128.0f >= mRenderMinDelta );
				DrawMatch( mJoints.mMatches[i], JointRect, Fast ? Color.green : Color.red );
				//FilteredResults++;
			}

		}
	}
}
