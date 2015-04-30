using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class FeatureInputManager : MonoBehaviour {

	public int					mFrameDelay = 5;
	public RenderTexture		mInput;
	public RenderTexture		mOutput;
	public List<RenderTexture>	mInputHistory;
	public List<RenderTexture>	mHistoryPool;

	// Use this for initialization
	void Start () {
	
	}

	RenderTexture PoolPop()
	{
		RenderTexture Element;

		//	pop if there's some in the pool
		if (mHistoryPool.Count > 0) {
			int PopIndex = mHistoryPool.Count-1;	//	gr: assuming mem-management style last-fastest
			Element = mHistoryPool [PopIndex];
			mHistoryPool.RemoveAt (PopIndex);
			return Element;
		}

		//	return a new one
		if (!mOutput)
			return null;

		Element = new RenderTexture( mOutput.width, mOutput.height, mOutput.depth, mOutput.format );
		return Element;
	}

	void PoolPush(RenderTexture Element)
	{
		mHistoryPool.Add (Element);
	}
	
	// Update is called once per frame
	void Update () {

		if (mInput == null || mOutput == null) {
			Debug.Log ("FeatureInputManager missing requirements");
			return;
		}

		//	pop oldest into output
		if (mInputHistory.Count >= mFrameDelay) {
			Graphics.Blit( mInputHistory[0], mOutput );
			PoolPush( mInputHistory[0] );
			mInputHistory.RemoveAt(0);
		}

		//	push input onto history stack
		if (mInputHistory.Count < mFrameDelay) {
			RenderTexture Temp = PoolPop();
			if ( Temp != null )
			{
				Graphics.Blit( mInput, Temp );
				mInputHistory.Add( Temp );
			}
		}

	}
}
