using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class RandomTextureGenerator : MonoBehaviour {

	public RenderTexture	mRandomTexture;
	public Material			mRandomShader;
	public bool				mGenerateOnce = false;
	private bool			mRandomInitialised = false;
	public Rect				mDebugRect = new Rect(0,0,0,0);

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
		if (!PopCheckCurrentCamera.CheckCurrentCamera ())
			return;

	//	if (!mGenerateOnce || !mRandomInitialised) {
		mRandomTexture.DiscardContents ();
			Graphics.Blit (null, mRandomTexture, mRandomShader);
			mRandomInitialised = true;
	//	}

	}

	void OnGUI()
	{
		if ( mRandomTexture != null )
			GUI.DrawTexture( new Rect(mDebugRect.x*Screen.width,mDebugRect.y*Screen.height,mDebugRect.width*Screen.width,mDebugRect.height*Screen.height), mRandomTexture );
	}

}
