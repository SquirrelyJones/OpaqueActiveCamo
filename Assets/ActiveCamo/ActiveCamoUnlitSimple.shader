Shader "Unlit/ActiveCamoUnlitSimple"
{
	Properties
	{
		_DistortTex ("Distortion", 2D) = "grey" {}
		_DistortTexTiling ("Distortion Tiling", Vector) = (1,1,0,0)
		_DistortAmount ("Distortion Amount", Range(0,1)) = 0.1
		_VertDistortAmount ("Vert Distortion Amount", Range(0,1)) = 0.1

		_ActiveCamoRamp ("Active Camo Ramp", Range(0,1)) = 0.0
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		Pass
		{
			Offset -1,-1
			Blend One OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _DistortTex;
			float4 _DistortTexTiling;
			float _DistortAmount;
			float _VertDistortAmount;

			// per instance variables
			float _ActiveCamoRamp;

			// global variables
			sampler2D _LastFrame;
			float _GlobalActiveCamo;

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 screenPos: TEXCOORD1;
				float2 screenNormal : TEXCOORD2;
			};
			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.screenPos = ComputeScreenPos(o.vertex);
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.screenNormal = mul( (float3x3)UNITY_MATRIX_V, worldNormal ).xy;

				return o;
			}
			
			fixed4 frag (v2f IN) : SV_Target
			{

				// get the distortion for the prevous frame coords
				half2 distortion = tex2D (_DistortTex, IN.uv.xy * _DistortTexTiling.xy + _Time.yy * _DistortTexTiling.zw ).xy;
				distortion -= tex2D (_DistortTex, IN.uv.xy * _DistortTexTiling.xy + _Time.yy * _DistortTexTiling.wz ).yz;

				// get the last frame to use as camo
				float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
				screenUV += distortion * _DistortAmount * 0.1;
				screenUV += IN.screenNormal * _VertDistortAmount * 0.1;
				half3 lastFrame = tex2D (_LastFrame, screenUV).xyz;

				// the final amound of active camo to apply
				half activeCamo = _ActiveCamoRamp * _GlobalActiveCamo;

				// premultiplied alpha camo
				half4 final = half4( lastFrame * activeCamo, activeCamo);
				final.w = saturate( final.w);

				return final;
			}
			ENDCG
		}
	}
}