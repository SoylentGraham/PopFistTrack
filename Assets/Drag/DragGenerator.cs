using UnityEngine;
using System.Collections;

public class DragGenerator : MonoBehaviour {

	public RenderTexture	mFrameLum;
	private RenderTexture	mFrameLumPrev;
	public Material			mFrameMotionShader;
	public RenderTexture	mFrameMotion;

	public Material			mUvMapInitShader;
	public Material			mUvMapUpdateShader;
	public RenderTexture	mUvMap;

	public Material			mUndragShader;
	public RenderTexture	mUndragSource;
	public RenderTexture	mUndragTarget;

	private bool			mInitialised = false;

	// Use this for initialization
	public void Start () {
		mInitialised = false;
		mFrameLumPrev = null;
		Resources.UnloadUnusedAssets ();
	}

	public void OnDisable()
	{
		Start();
	}
	
	// Update is called once per frame
	void Update () {
	
		if (!mInitialised && mUvMap && mUvMapInitShader ) {
			//	initialise uv map
			Graphics.Blit( null, mUvMap, mUvMapInitShader );
			mInitialised = true;
		}

		//	get frame motion
		if ( mFrameLumPrev && mFrameLum )
		{
			mFrameMotionShader.SetTexture("Prev_MainTex", mFrameLumPrev );
			Graphics.Blit( mFrameLum, mFrameMotion, mFrameMotionShader );

			//	move uv map to frame motion
			RenderTexture PrevUvMap = RenderTexture.GetTemporary( mUvMap.width, mUvMap.height, mUvMap.depth, mUvMap.format );
			Graphics.Blit( mUvMap, PrevUvMap );

			mUvMapUpdateShader.SetTexture("MotionTexture", mFrameMotion );
			Graphics.Blit( PrevUvMap, mUvMap, mUvMapUpdateShader );
		}

		if (mFrameLum) {
			if (!mUndragSource )
			{
				mUndragSource = new RenderTexture (mFrameLum.width, mFrameLum.height, mFrameLum.depth, mFrameLum.format);
				Graphics.Blit (mFrameLum, mUndragSource);
			}

			if (!mFrameLumPrev)
				mFrameLumPrev = new RenderTexture (mFrameLum.width, mFrameLum.height, mFrameLum.depth, mFrameLum.format);
			Graphics.Blit (mFrameLum, mFrameLumPrev);
		}

		//	undrag debug image
		if (mUndragSource && mUndragTarget && mUvMap) {
			mUndragShader.SetTexture("UvMapTexture", mUvMap );
			Graphics.Blit (mUndragSource, mUndragTarget, mUndragShader);
			//Graphics.Blit (mUndragSource, mUndragTarget);
		}
	}
}
