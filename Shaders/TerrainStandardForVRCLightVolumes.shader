// Unity built-in shader source. Copyright (c) 2016 Unity Technologies.
// MIT license (see license.txt)

Shader "Nature/Terrain/Standard_VRCLightVolumes" {
    Properties {
        [HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
        [HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)
        [HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}
    }

    SubShader {
        Tags {
            "Queue" = "Geometry-100"
            "RenderType" = "Opaque"
            "TerrainCompatible" = "True"
        }

        CGPROGRAM
        #pragma surface surf Standard vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer addshadow fullforwardshadows
        #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd
        #pragma multi_compile_fog
        #pragma target 3.0
        
        #include "UnityPBSLighting.cginc"
        #include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"

        #pragma multi_compile_local_fragment __ _ALPHATEST_ON
        #pragma multi_compile_local __ _NORMALMAP

        #define TERRAIN_STANDARD_SHADER
        #define TERRAIN_INSTANCED_PERPIXEL_NORMAL
        #define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard
        #include "TerrainSplatmapCommon_LightVolumes.cginc"

        half _Metallic0;
        half _Metallic1;
        half _Metallic2;
        half _Metallic3;

        half _Smoothness0;
        half _Smoothness1;
        half _Smoothness2;
        half _Smoothness3;

        void surf (Input IN, inout SurfaceOutputStandard o) {
            half4 splat_control;
            half weight;
            fixed4 mixedDiffuse;
            half4 defaultSmoothness = half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);

            SplatmapMix(IN, defaultSmoothness, splat_control, weight, mixedDiffuse, o.Normal);
            
            o.Albedo = mixedDiffuse.rgb;
            o.Alpha = weight;
            o.Smoothness = mixedDiffuse.a;
            o.Metallic = dot(splat_control, half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3));

            // --- Light Volume Integration ---
            float3 L0, L1r, L1g, L1b;
            LightVolumeAdditiveSH(IN.worldPos, L0, L1r, L1g, L1b);

            float3 lightVolumeDiffuse = LightVolumeEvaluate(o.Normal, L0, L1r, L1g, L1b);

            o.Emission = float3(0,0,0); // Initialize Emission
            o.Emission += lightVolumeDiffuse * o.Albedo;

            float3 lightVolumeSpecular = LightVolumeSpecularDominant(o.Albedo, o.Smoothness, o.Metallic, o.Normal, IN.viewDir, L0, L1r, L1g, L1b);
            
            o.Emission += lightVolumeSpecular;
            // --- Light Volume Integration End ---
        }
        ENDCG

        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
        UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"
    }

    Dependency "AddPassShader"    = "Hidden/TerrainEngine/Splatmap/Standard-AddPass"
    Dependency "BaseMapShader"    = "Hidden/TerrainEngine/Splatmap/Standard-Base"
    Dependency "BaseMapGenShader" = "Hidden/TerrainEngine/Splatmap/Standard-BaseGen"

    Fallback "Nature/Terrain/Diffuse"
}