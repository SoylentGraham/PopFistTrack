using UnityEngine;
using System.Collections;
using System.Collections.Generic;



public class MotionTextureGenerator : MonoBehaviour {

	public RenderTexture	mLumTexture;
	private RenderTexture	mLumTextureLast;
	public RenderTexture	mMotionTexture;
	public Material			mMotionCalcMat;
	public Material			mMotionInitMat;
	public Material			mFillerMat;

	// Use this for initialization
	void Start () {
	
	}

	public void OnDisable()
	{
	//	mLumTexture = null;
		mLumTextureLast = null;
	//	mMotionTexture = null;
	}
	

	bool ExecuteShaderLumToMotion(Texture LumTextureNew,Texture LumTexturePrev)
	{
		if (!LumTextureNew)
			return false;

		if (!mMotionTexture)
			return false;

		if (!mMotionInitMat || !mMotionCalcMat)
			return false;


		if ( LumTexturePrev == null) 
		{
			//	run init motion texture shader
			Graphics.Blit (LumTextureNew, mMotionTexture, mMotionInitMat );
		}
		else{
			mMotionCalcMat.SetTexture("LumLastTex", LumTexturePrev );

			//	run normal motion generator
			Graphics.Blit (LumTextureNew, mMotionTexture, mMotionCalcMat );

			if ( mFillerMat != null )
			{
				var Temp = RenderTexture.GetTemporary( mMotionTexture.width, mMotionTexture.height, 0, mMotionTexture.format );
				Graphics.Blit (mMotionTexture, Temp, mFillerMat );
				Graphics.Blit (Temp, mMotionTexture );
				RenderTexture.ReleaseTemporary( Temp );
			}

		}

		return true;
	}

	// Update is called once per frame
	void Update () {

		if ( !ExecuteShaderLumToMotion( mLumTexture, mLumTextureLast ) )
			return;

		if (!mLumTextureLast) {
			mLumTextureLast = new RenderTexture (mLumTexture.width, mLumTexture.height, mLumTexture.depth, mLumTexture.format, RenderTextureReadWrite.Default);
			Graphics.Blit (mLumTexture, mLumTextureLast);
		}

		//	copy for next run
		//Graphics.Blit (mLumTexture, mLumTextureLast);

	}
}
