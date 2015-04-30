using UnityEngine;
using System.Collections;


[ExecuteInEditMode]
public class MaskGenerator : MonoBehaviour {

	//public RenderTexture		mMotionTexture;
	public Texture				mInputTexture;
	public RenderTexture		mMaskTexture;
	public BackgroundLearner	mBackgroundLearner;
	public Material				mSubtractMaterial;
	private RenderTextureFormat	mTempTextureFormat = RenderTextureFormat.ARGB32;
	private FilterMode			mTempTextureFilterMode = FilterMode.Point;
	public Material				mSubtractFillMaterial;
	private RenderTexture		mFillTempTexture;


	void OnDisable()
	{
		mFillTempTexture = null;
	}

	void Update () {

		//	take input and subtract from background learner to generate mask
		if (!mInputTexture || !mBackgroundLearner || !mMaskTexture)
			return;

		Texture BackgroundTexture = mBackgroundLearner.mBackgroundTexture;
		if (!BackgroundTexture || !mSubtractMaterial )
			return;

		RenderTexture SubtractTempTexture = RenderTexture.GetTemporary (mInputTexture.width, mInputTexture.height, 0, mTempTextureFormat);
		mSubtractMaterial.SetTexture ("LastBackgroundTex",BackgroundTexture);
		Graphics.Blit (mInputTexture, SubtractTempTexture, mSubtractMaterial);

		//	do a fill to remove noise etc
		if (mSubtractFillMaterial != null) {

			if ( !mFillTempTexture )
			{
				mFillTempTexture = new RenderTexture(mInputTexture.width, mInputTexture.height, 0, mTempTextureFormat);
				mFillTempTexture.filterMode = mTempTextureFilterMode;
			}
			//FillTempTexture.DiscardContents();
			Graphics.Blit (SubtractTempTexture, mFillTempTexture, mSubtractFillMaterial);
			//SubtractTempTexture.DiscardContents();
			mMaskTexture.DiscardContents();
			Graphics.Blit (mFillTempTexture, mMaskTexture);

		} else 

		{
			Graphics.Blit( SubtractTempTexture, mMaskTexture );
		}

		SubtractTempTexture.DiscardContents ();
		RenderTexture.ReleaseTemporary (SubtractTempTexture);
	}
	
}
