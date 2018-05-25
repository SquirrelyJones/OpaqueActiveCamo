Shader "Custom/ActiveCamoSurface" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalTex ("Normal", 2D) = "bump" {}
		_SmoothnessTex ("Smoothness", 2D) = "grey" {}
		_MetallicTex ("Metallic", 2D) = "black" {}
		_EmissiveTex ("Emissive", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 1.0
		_Metallic ("Metallic", Range(0,1)) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _SmoothnessTex;
		sampler2D _MetallicTex;
		sampler2D _EmissiveTex;

		struct Input {
			float2 uv_MainTex;
			INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {

			o.Albedo = tex2D (_MainTex, IN.uv_MainTex).xyz;
			o.Metallic = tex2D (_MetallicTex, IN.uv_MainTex) * _Metallic;
			o.Smoothness = tex2D (_SmoothnessTex, IN.uv_MainTex) * _Glossiness;
			o.Emission = tex2D (_EmissiveTex, IN.uv_MainTex).xyz;
			o.Normal = UnpackNormal( tex2D (_NormalTex, IN.uv_MainTex) );
			o.Alpha = 1.0;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
