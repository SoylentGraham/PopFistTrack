using UnityEngine;
using System.Collections;
using System.Collections.Generic;



public class JointDebug : MonoBehaviour {

	public JointGenerator	mJointGenerator;

	
	void DrawTexture(int ScreenSectionX,int ScreenSectionY,Texture texture)
	{
		if (texture == null)
			return;
		
		float Sectionsx = Screen.width / 2;
		float Sectionsy = Screen.height / 2;
		Rect rect = new Rect( Sectionsx*ScreenSectionX, Sectionsy*ScreenSectionY, Sectionsx, Sectionsy );
		
		GUI.DrawTexture (rect, texture);
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
	
	static Rect GetScreenRect(int ScreenSectionX,int ScreenSectionY)
	{
		float Sectionsx = Screen.width / 2;
		float Sectionsy = Screen.height / 2;
		Rect rect = new Rect( Sectionsx*ScreenSectionX, Sectionsy*ScreenSectionY, Sectionsx, Sectionsy );
		return rect;
	}
	
	public static void DrawJoint(TJoint joint,int ScreenSectionX,int ScreenSectionY)
	{
		Rect rect = GetScreenRect (ScreenSectionX, ScreenSectionY);
		DrawJoint (joint, rect);
	}

	public static void DrawJoint(TJoint joint,Rect ScreenRect)
	{
		Vector2 Start = new Vector2 (joint.mStart.x, joint.mStart.y);
		Vector2 Middle = new Vector2 (joint.mMiddle.x, joint.mMiddle.y);
		Vector2 RayEnd = new Vector2 (joint.mRayEnd.x, joint.mRayEnd.y);
		Vector2 End = new Vector2 (joint.mEnd.x, joint.mEnd.y);
		Vector2 Left = End + new Vector2 (joint.mRadLeft.x, joint.mRadLeft.y);
		Vector2 Right = End + new Vector2 (joint.mRadRight.x, joint.mRadRight.y);
		float Radius = joint.mEndRadius;
		FitToRect( ref Start, ScreenRect );
		FitToRect( ref Middle, ScreenRect );
		FitToRect( ref RayEnd, ScreenRect );
		FitToRect( ref End, ScreenRect );
		FitToRect( ref Left, ScreenRect );
		FitToRect( ref Right, ScreenRect );
		FitToRect (ref Radius, ScreenRect);

		GuiHelper.DrawLine( Start, Middle, Color.red );
		GuiHelper.DrawLine( Middle, RayEnd, Color.green );
		GuiHelper.DrawCircle (End, Radius, Color.magenta);
		GuiHelper.DrawLine (End, Left, Color.blue);
		GuiHelper.DrawLine (End, Right, Color.blue);
	}

	void Update()
	{
		/*
		Texture mInputTexture = mJointGenerator ? mJointGenerator.mInputTexture : null;
		if (mInputTexture != null) {
			//	update mask test
			if (mMaskTestMaterial ) {
				if ( mMaskTestTexture == null )
					mMaskTestTexture = new RenderTexture (mInputTexture.width, mInputTexture.height, 0, RenderTextureFormat.ARGB32);
				Graphics.Blit (mInputTexture, mMaskTestTexture, mMaskTestMaterial);
			}
		}
*/
	}

	void OnGUI()
	{
		if (mJointGenerator != null) {
			DrawTexture (0, 0, mJointGenerator.mMaskTexture);
			DrawTexture (1, 0, mJointGenerator.mRayTexture);
			DrawTexture (1, 1, mJointGenerator.mSecondJointTexture);
		//	DrawTexture (0, 1, mMaskTestTexture);
		
			for (int i=0; mJointGenerator.mJoints!=null && i<mJointGenerator.mJoints.Count; i++) {
				DrawJoint (mJointGenerator.mJoints [i], 0, 1);
			}
		
			GUI.Label (GetScreenRect (0, 1), "Joints: " + mJointGenerator.mJoints.Count);
		}
	}
}

