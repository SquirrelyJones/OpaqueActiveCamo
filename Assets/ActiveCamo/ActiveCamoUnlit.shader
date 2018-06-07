Shader "Unlit/ActiveCamoUnlit"
{
	Properties
	{
		_NormalTex ("Normal", 2D) = "bump" {}
		_FresnelOpacity ("Fresnel Opacity", Range(0,1)) = 0.1

		[Toggle(_USE_UV2)] _UseUV2("Use UV 2", int) = 0

		_GlowColor ("Glow Color", Color) = (1,1,1,1)
		_HexColor ("Hex Color", Color) = (1,1,1,1)

		_RampTex ("Ramp Map", 2D) = "grey" {}
		_FXTex ("FX Map", 2D) = "grey" {}
		_FXTexTiling ("FX Map Tiling", Vector) = (1,1,0,0)
		_LutTex ("Look Up Table", 2D) = "grey" {}

		_DistortTex ("Distortion", 2D) = "grey" {}
		_DistortTexTiling ("Distortion Tiling", Vector) = (1,1,0,0)
		_DistortAmount ("Distortion Amount", Range(0,1)) = 0.1
		_VertDistortAmount ("Vert Distortion Amount", Range(0,1)) = 0.1
		_NormalBlend ("Vertex / Pixel Normal Blend", Range(0,1)) = 1.0
		_DiffusionAmount ("Diffusion Amount", Range(0,1)) = 0.1
		_ActiveCamo ("Active Camo", Range(0,1)) = 0.0
		_ActiveCamoSmear ("Active Camo Smear", Vector) = (0,0,0,0)

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

			#pragma shader_feature _USE_UV2
			
			#include "UnityCG.cginc"


			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 screenPos : TEXCOORD4;
				float2 screenNormal : TEXCOORD5;
			};

			sampler2D _NormalTex;
			float _FresnelOpacity;

			float4 _GlowColor;
			float4 _HexColor;

			sampler2D _RampTex;
			sampler2D _FXTex;
			float4 _FXTexTiling;
			sampler2D _LutTex;

			sampler2D _DistortTex;
			float4 _DistortTexTiling;
			float _DistortAmount;
			float _VertDistortAmount;

			float _NormalBlend;

			float _DiffusionAmount;
			float _ActiveCamo;
			float4 _ActiveCamoSmear;
			float _ActiveCamoRamp;

			// global variables
			sampler2D _LastFrame;
			float _GlobalActiveCamo;

			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord;
				#ifdef _USE_UV2
					o.uv.zw = v.texcoord1;
				#else
					o.uv.zw = v.texcoord;
				#endif

				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				o.screenPos = ComputeScreenPos(o.vertex);
				o.screenNormal = mul( (float3x3)UNITY_MATRIX_V, worldNormal );

				return o;
			}

			float2 noise( float2 seed ){
				float val1 = sin( dot( seed.xy, float2(3737.247, 5712.178)) * 2458.245 );
				float val2 = sin( dot( seed.yx, float2(8365.840, 3156.861)) * 4637.840 );
				return float2( val1, val2 );
			}
			
			fixed4 frag (v2f IN) : SV_Target
			{

				// get the normal map
				fixed3 localNormal = UnpackNormal( tex2D (_NormalTex, IN.uv.xy) );

				// convert tangent normal to world normal
				fixed3 worldNormal;
				worldNormal.x = dot(IN.tSpace0.xyz, localNormal.xyz);
				worldNormal.y = dot(IN.tSpace1.xyz, localNormal.xyz);
				worldNormal.z = dot(IN.tSpace2.xyz, localNormal.xyz);
				worldNormal = normalize( worldNormal );

				half2 screenNormal = mul( (float3x3)UNITY_MATRIX_V, worldNormal ).xy;
				screenNormal = lerp( IN.screenNormal.xy, screenNormal, _NormalBlend );

				// get world position and view vector and calculate fresnel for effect
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 viewDir = normalize( worldPos - _WorldSpaceCameraPos);
				half fresnel = 1.0 - saturate( dot( worldNormal, -viewDir ) );
				fresnel = 1.0 - ( fresnel * fresnel * _FresnelOpacity );

				// get the distortion for the prevous frame coords
				half2 distortion = tex2D (_DistortTex, IN.uv.zw * _DistortTexTiling.xy + _Time.yy * _DistortTexTiling.zw ).xy;
				distortion -= tex2D (_DistortTex, IN.uv.wz * _DistortTexTiling.yx + _Time.yy * _DistortTexTiling.wz ).yz;

				half3 fxMap = tex2D (_FXTex, IN.uv.zw * _FXTexTiling.xy + _Time.yy * _FXTexTiling.zw ).xyz;
				half rampMap = tex2D (_RampTex, IN.uv.zw ).x;
				rampMap = lerp( rampMap, distortion.x * 0.5 + 0.5, 0.15 );

				float lutGlowUV = ( rampMap - 1.0 ) + _ActiveCamoRamp * 2.0;
				half4 lutGlow = tex2D (_LutTex, float2( lutGlowUV, 0.5 ) );
				// premultiplied alpha glow
				half4 fxGlow = half4( _GlowColor.xyz * lutGlow.x * fxMap.z * 2.0, _GlowColor.w * lutGlow.x * fxMap.z );

				float lutHexUV = ( lerp( rampMap, fxMap.x, 0.1 ) - 1.0 ) + _ActiveCamoRamp * 2.0;
				half4 lutHex= tex2D ( _LutTex, float2( lutHexUV, 0.5 ) );
				// premultiplied alpha glow
				half4 fxHex = half4( _HexColor.xyz * lutHex.y * fxMap.y * 2.0, _HexColor.w * lutHex.y * fxMap.y );

				float lutFlickerUV = frac( fxMap.x + rampMap + _Time.yy * 0.1 );
				half4 lutFlicker= tex2D ( _LutTex, float2( lutFlickerUV, 0.5 ) );
				// premultiplied alpha flicker
				half4 fxFlicker = half4( _HexColor.xyz * lutFlicker.w * fxMap.y * lutHex.z * 0.2, 0 );

				// the final amound of active camo to apply
				half activeCamo = _ActiveCamo * _GlobalActiveCamo * fresnel * lutHex.z;

				// get the last frame to use as camo
				float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
				screenUV += _ActiveCamoSmear.xy * 0.1;
				screenUV += distortion * _DistortAmount * 0.1;
				screenUV += screenNormal * _VertDistortAmount * 0.1;
				float deadZone = 1.0 - length( screenNormal );
				screenUV += pow(deadZone, 3.0 ) * noise( IN.screenPos.xy + _SinTime.ww ) * _DiffusionAmount * 0.1;
				half3 lastFrame = tex2D (_LastFrame, screenUV).xyz;

				// premultiplied alpha camo
				half4 camo = half4( lastFrame * activeCamo, activeCamo);

				half4 final = camo + fxGlow + fxHex + fxFlicker;
				final.w = saturate( final.w);

				return final;
			}
			ENDCG
		}
	}
}
