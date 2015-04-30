using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public struct float2
{
	public float	x;
	public float	y;
	
	public float2(float _x,float _y)
	{
		x = _x;
		y = _y;
	}


};

public struct TJoint
{
	public float2	mStart;
	public float2	mMiddle;
	public float2	mRayEnd;	//	ray-calculated end
	public float2	mEnd;		//	cross adjusted end
	public float	mEndRadius;
	public float2	mRadLeft;
	public float2	mRadRight;
	
	public float	Length()
	{
		Vector2 a = new Vector2 (mMiddle.x - mStart.x, mMiddle.y - mStart.y);
		Vector2 b = new Vector2 (mEnd.x - mMiddle.x, mEnd.y - mMiddle.y);
		return a.magnitude + b.magnitude;
	}
};



public class TJointCalculator
{
	private Texture2D		mSecondJointTextureCopy;

#if UNITY_IOS && !UNITY_EDITOR
	[DllImport("__Internal", CallingConvention = CallingConvention.Cdecl)]
	//[DllImport("__Internal")]
	public static extern bool PopReadPixels(System.IntPtr TextureId,ref Color32[] Colours,int TextureWidth,int TextureHeight);
#endif

	public Texture2D GetCopyTexture()
	{
		return mSecondJointTextureCopy;
	}

	float radians(float Degrees)
	{
		return Degrees * Mathf.Deg2Rad;
	}

	void OnDisable()
	{
	}


	bool GetRenderTexturePixels(ref Color32[] Colours,RenderTexture SourceTexture,TextureFormat ReadBackFormat,ref string DebugOut)
	{
		//	gr: currently crashing when returning out of func...
#if UNITY_IOS && !UNITY_EDITOR && FALSE
		if ( Colours == null )
			Colours = new Color32[ SourceTexture.width * SourceTexture.height ];

	//	RenderTexture.active = SourceTexture;
		//	use my plugin
		bool result = PopReadPixels( SourceTexture.GetNativeTexturePtr(), ref Colours, SourceTexture.width, SourceTexture.height );
	//	RenderTexture.active = null; 

		return result;
#else
		//	calc joints frmo pixel data
		if (mSecondJointTextureCopy == null) {
			mSecondJointTextureCopy = new Texture2D (SourceTexture.width, SourceTexture.height, ReadBackFormat, false);
			mSecondJointTextureCopy.name = "mSecondJointTextureCopy";
		}
		RenderTexture.active = SourceTexture;
		mSecondJointTextureCopy.ReadPixels (new Rect (0, 0, SourceTexture.width, SourceTexture.height), 0, 0);
		mSecondJointTextureCopy.Apply (true);
		RenderTexture.active = null; 
		DebugOut += mSecondJointTextureCopy.GetPixel (0, mSecondJointTextureCopy.height-1) + "\n";
		
		Colours = mSecondJointTextureCopy.GetPixels32();
		//mSecondJointTextureCopy = null;
		return true;
#endif
	}

	public List<TJoint> CalculateJoints(ref string DebugOut,Texture MaskTexture,RenderTexture mRayTexture,Material mRayMaterial,RenderTexture mSecondJointTexture,Material mSecondJointMaterial,int MaxColumnTest,TextureFormat ReadBackFormat,int MinJointLength)
	{
		DebugOut = "";
		if (MaskTexture == null)
			return null;
		
		if (mRayTexture == null || mRayMaterial == null)
			return null;

		mRayTexture.DiscardContents ();
		Graphics.Blit (MaskTexture, mRayTexture, mRayMaterial);
		

		if (mSecondJointTexture == null || mSecondJointMaterial == null)
			return null;
		mSecondJointMaterial.SetTexture ("_RayTex", mRayTexture);
		mSecondJointTexture.DiscardContents ();
		Graphics.Blit (MaskTexture, mSecondJointTexture, mSecondJointMaterial);


		Color32[] SecondJointPixels = null;
		if (!GetRenderTexturePixels (ref SecondJointPixels, mSecondJointTexture, ReadBackFormat, ref DebugOut)) {
			DebugOut += "Failed to read render texture pixels";
			return null;
		}

		int MaxJointLength = mSecondJointMaterial.GetInt("MaxJointLength");
		float AngleDegMin = mSecondJointMaterial.GetFloat ("AngleDegMin");
		float AngleDegMax = mSecondJointMaterial.GetFloat ("AngleDegMax");

		return CalculateJoints (ref DebugOut, SecondJointPixels, mSecondJointTexture, MaskTexture, MaxJointLength, AngleDegMin, AngleDegMax, MaxColumnTest, MinJointLength, mSecondJointMaterial );
	}
	
	
	List<TJoint> CalculateJoints(ref string DebugOut,Color32[] SecondJointPixels,Texture SecondJointTexture,Texture MaskTexture,int MaxJointLength,float AngleDegMin,float AngleDegMax,int MaxColumnTest,int MinJointLength,Material ParamsMaterial)
	{
		//int RayPad = ParamsMaterial.GetInt ("RayPad");

		int MaxJoints = 400;
		List<TJoint> Joints = new List<TJoint> ();
		
		//	gr: verify w/h agains pixels size?
		int PixelCount = SecondJointPixels.Length;
		if (PixelCount % SecondJointTexture.width != 0)
			return Joints;
		
		//	should match mSecondJointTexture.height
		int PixelsWidth = SecondJointTexture.width;
		int PixelsHeight = PixelCount / PixelsWidth;

		MaxColumnTest = Mathf.Min(SecondJointTexture.width, MaxColumnTest);
		List<int> Columns = new List<int> ();
		for (int c=0; c<MaxColumnTest; c++) {
			float xf = (c / (float)MaxColumnTest) * SecondJointTexture.width;
			int x = Mathf.FloorToInt (xf);

			//	don't add dupes
			if (Columns.Count > 0)
			if (Columns [Columns.Count - 1] == x)
				continue;
			Columns.Add (x);
		}
	
		DebugOut += SecondJointPixels [0 + (0 * PixelsWidth)] + "\n";
		DebugOut += SecondJointPixels [0 + ((PixelsHeight/2) * PixelsWidth)] + "\n";
		DebugOut += SecondJointPixels [(10) + ((PixelsHeight-1) * PixelsWidth)] + "\n";

		//	gr: could probbaly be more cache friendly by approaching this row-by-row...
		for (int xi=0; xi<Columns.Count; xi++) 
		{
			int x = Columns[xi];
			Color32 ColPixel = SecondJointPixels[x];

			//	height is the same for each angle so we can skip that quick
			float Height = ( ColPixel.a / 255.0f ) * PixelsHeight;
			if ( Height < 1 )
				continue;
			
			//	get the longest joint for this X
			float BestJointLength = 0.0f;
			int BestJointAng = -1;
			
			for ( int angstep=0;	angstep<PixelsHeight;	angstep++ )
			{
				int p = x + (angstep*PixelsWidth);
				Color32 Pixel = SecondJointPixels[p];
				int pixr = Pixel.r;
			//	float AngleDeg = Mathf.Lerp( AngleDegMin, AngleDegMax, (float)angstep / (float)PixelsHeight );
				
				float JointLength = ( pixr / 255.0f) * MaxJointLength;
				if ( JointLength < BestJointLength )
					continue;
				
				BestJointLength = JointLength;
				BestJointAng = angstep;
			}
			
			if ( BestJointAng < 0 )
				continue;
			if ( BestJointLength < MinJointLength )
				continue;
			
			{
				int angstep = BestJointAng;
				int p = x + (angstep*PixelsWidth);
				Color32 Pixel = SecondJointPixels[p];
				float AngleDeg = Mathf.Lerp( AngleDegMin, AngleDegMax, (float)angstep / (float)PixelsHeight );

				float JointLength = ( (float)Pixel.r / 255.0f) * MaxJointLength;
				float PanLength = ( (float)Pixel.g / 255.0f) * MaxJointLength;
				float RadiusLength = ( (float)Pixel.b / 255.0f) * MaxJointLength;
				RadiusLength = Mathf.Max(1,RadiusLength);

				//	gr: something wrong in this calc? half seems to look right
				//	texture->texture scale
				//	gr: maybe just UVscalar is wrong?
				JointLength /= MaskTexture.width / SecondJointTexture.width;
				RadiusLength /= MaskTexture.width / SecondJointTexture.width;
				PanLength /= MaskTexture.width / SecondJointTexture.width;
				
				float AngleRad = radians(AngleDeg);
				Vector2 AngleVector = new Vector2( Mathf.Sin(AngleRad), Mathf.Cos(AngleRad) );
				AngleVector.Normalize();
				Vector2 LeftVector = new Vector2( AngleVector.y, -AngleVector.x ); 
				Vector2 RightVector = new Vector2( -AngleVector.y, AngleVector.x ); 

				//	in order to center the circle, we want to move it back a bit. we know it's already <PAD> back, but we might want to go further in either direction
				//	basically pad needs to become radius
				//float Diff = RadiusLength - RayPad;
				float Diff = 0;
				AngleVector *= JointLength + Diff;
				Vector2 PanVector = new Vector2( LeftVector.x, LeftVector.y );
				PanVector *= PanLength;
				LeftVector *= RadiusLength-PanLength;
				RightVector *= RadiusLength+PanLength;

				
				float2 UvScalar = new float2( 1.0f / SecondJointTexture.width, 1.0f / SecondJointTexture.height );
				TJoint joint = new TJoint();
				joint.mStart = new float2( x*UvScalar.x, 0 );
				joint.mMiddle = new float2( x*UvScalar.x, Height*UvScalar.y );
				joint.mRayEnd = new float2( joint.mMiddle.x + (AngleVector.x*UvScalar.x), joint.mMiddle.y + (AngleVector.y*UvScalar.y) );
				joint.mEnd = new float2( joint.mRayEnd.x + (PanVector.x*UvScalar.x), joint.mRayEnd.y + (PanVector.y*UvScalar.y) );
				joint.mEndRadius = RadiusLength * UvScalar.x;
				joint.mRadLeft = new float2( LeftVector.x*UvScalar.x, LeftVector.y*UvScalar.y );
				joint.mRadRight = new float2( RightVector.x*UvScalar.x, RightVector.y*UvScalar.y );
				Joints.Add( joint );
				
				if ( Joints.Count >= MaxJoints )
					return Joints;
			}
		}
		return Joints;
	}
	
}



public class JointGenerator : MonoBehaviour {
	
	public RenderTexture mRayTexture;
	public Material mRayMaterial;
	public RenderTexture mSecondJointTexture;
	public Material mSecondJointMaterial;
	private TJointCalculator	mJointCalculator = new TJointCalculator();
	public Texture			mMaskTexture;
	public List<TJoint>		mJoints = new List<TJoint>();
	public int				mMaxColumnTest = 50;
	public TextureFormat	mReadBackFormat = TextureFormat.ARGB32;
	public string 			mDebug;
	public bool				mDebugJoint = false;
	public bool				mBestJointOnly = false;
	public int				mMinJointLength = 1;

	public Texture2D GetCopyTexture()
	{
		return mJointCalculator !=null ? mJointCalculator.GetCopyTexture() : null;
	}


	void OnDisable()
	{
		mJoints.Clear ();
		mJointCalculator = null;
	}
	
	// Update is called once per frame
	void Update () {

		//	yield return new WaitForEndOfFrame();

		if (mMaskTexture == null)
			return;
		
		if (mJointCalculator == null) {
			mJointCalculator = new TJointCalculator ();
		}

		if (mDebugJoint) {
			TJoint joint = new TJoint ();
			joint.mStart = new float2 (0, 0);
			joint.mMiddle = new float2 (0.2f, 0.2f);
			joint.mEnd = new float2 (0.4f, 0.5f);
			mJoints = new List<TJoint> ();
			mJoints.Add (joint);
		} else {
			mJoints = mJointCalculator.CalculateJoints (ref mDebug, mMaskTexture, mRayTexture, mRayMaterial, mSecondJointTexture, mSecondJointMaterial, mMaxColumnTest, mReadBackFormat, mMinJointLength );

			if ( mBestJointOnly )
			{
			//	filter out best
				int Best = 0;
				for ( int i=1;	i<mJoints.Count;	i++ )
				{
					if ( mJoints[i].Length() > mJoints[Best].Length() )
						Best = i;
				}

				if ( mJoints.Count > 0 )
				{
					TJoint joint = mJoints[Best];
					mJoints.Clear();
					mJoints.Add( joint );
				}
			}
		}
	}
	
}
