using UnityEngine;
using System.Collections;

public class HomographyGenerator : MonoBehaviour {

	public Texture2D		mHomographyPoints;
	public RenderTexture	mHomographys;
	public FeatureMatcher	mFeatureMatcher;
	public Material			mMakeHomographyShader;
	public RenderTexture	mRandomTexture;

	// Use this for initialization
	void Start () {
	
	}
	
	bool MakeHomographyPointsTexture()
	{
		if (!mHomographyPoints)
			return false;

		if ( mHomographyPoints.height != 1 || mHomographyPoints.width < 4 )
		{
			throw new UnityException("Homography point data texture should have height of 1 and width of at least 4");
			return false;
		}
		
		FeatureResults FeatureMatches = mFeatureMatcher.mJoints;
		
		//	generate texture with point data
		Color32[] HomoPointsData = new Color32[mHomographyPoints.width];
		for (int i=0; i<HomoPointsData.Length; i++) {
			byte srcx = 0;
			byte srcy = 0;
			byte dstx = 0;
			byte dsty = 0;
			if (i < FeatureMatches.mMatches.Count) {
				srcx = (byte)(FeatureMatches.mMatches[i].x * 256.0f);
				srcy = (byte)(FeatureMatches.mMatches[i].y * 256.0f);
				dstx = (byte)(FeatureMatches.mMatches[i].z * 256.0f);
				dsty = (byte)(FeatureMatches.mMatches[i].w * 256.0f);
			}
			
			HomoPointsData [i].r = srcx;
			HomoPointsData [i].g = srcy;
			HomoPointsData [i].b = dstx;
			HomoPointsData [i].a = dsty;
		}
		mHomographyPoints.SetPixels32( HomoPointsData );
		mHomographyPoints.Apply ();
		return true;
	}

	bool MakeHomographyTexture()
	{
		if (!PopCheckCurrentCamera.CheckCurrentCamera ())
			return false;
	
		if ( mHomographys.height != 9 || mHomographys.width < 4 )
		{
			throw new UnityException("Homography target texture needs to be 9 pixels high (3x3 matrix)");
			return false;
		}
		
		Graphics.Blit (mHomographyPoints, mHomographys, mMakeHomographyShader);
		return true;
	}


	void Update () {
		if (!MakeHomographyPointsTexture())
			return;

		if ( !MakeHomographyTexture() )
			return;
	}
}
