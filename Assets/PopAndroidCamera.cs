using UnityEngine;
using System.Collections;

public class PopAndroidCamera : MonoBehaviour {

	public bool		mEnableAutoFocus = true;

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
		SetAutoFocus (mEnableAutoFocus);
	}

	public bool	SetAutoFocus(bool Enable)
	{
		//#if UNITY_ANDROID && !UNITY_EDITOR
		#if UNITY_ANDROID

#endif
		return false;
	}

}
