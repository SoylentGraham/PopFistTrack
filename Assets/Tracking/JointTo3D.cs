using UnityEngine;
using System.Collections;
using System.Collections.Generic;


public class JointTo3D : MonoBehaviour {

	public Transform		mElbowObject;
	public Transform		mHandObject;
	public Camera			mWebcamCamera;
	public JointGenerator	mJointGenerator;

	private int				mJointLooper = 0;
	[Range(0.1f,5.0f)]
	public float			MiddleDepth = 3.0f;
	[Range(0.1f,5.0f)]
	public float			EndDepth = 3.0f;

	// Update is called once per frame
	void Update () {

		if (!mJointGenerator || !mElbowObject || !mHandObject || !mWebcamCamera)
			return;

		//	work out the best joint...
		IList<TJoint> Joints = mJointGenerator.mJoints;

		TJoint joint = new TJoint ();
		//	if no joints, make up dummy one
		if (Joints.Count == 0) 
			return;
	
		mJointLooper = (mJointLooper + 1) % Joints.Count;
		joint = Joints [mJointLooper];
	
		//	use camera to make 3D positions
		Vector3 MiddleScreen = new Vector3( joint.mMiddle.x * mWebcamCamera.pixelWidth, joint.mMiddle.y * mWebcamCamera.pixelHeight, MiddleDepth );
		Vector3 EndScreen = new Vector3( joint.mEnd.x * mWebcamCamera.pixelWidth, joint.mEnd.y * mWebcamCamera.pixelHeight, EndDepth );
		Vector3 Middle = mWebcamCamera.ScreenToWorldPoint (MiddleScreen);
		Vector3 End = mWebcamCamera.ScreenToWorldPoint (EndScreen);

		mElbowObject.position = Middle;
		mHandObject.position = End;

	}
}
