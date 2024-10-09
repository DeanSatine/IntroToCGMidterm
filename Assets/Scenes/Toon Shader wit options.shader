Shader "DeanToonWithReflection"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1) // Base color of the object
        _MainTex("Main Texture", 2D) = "white" {} // Main texture applied to the object
        [HDR] _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1) // Ambient light color affecting the object
        [HDR] _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1) // Color for specular highlights
        _Glossiness("Glossiness", Float) = 32 // Controls the sharpness of specular highlights
        [HDR] _RimColor("Rim Color", Color) = (1,1,1,1) // Color of the rim lighting effect
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716 // Controls how much the rim lighting is visible
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1 // Controls how sharp the rim lighting is
        _ReflectionColor("Reflection Color", Color) = (1,1,1,1) // Color for reflections
        _Reflectivity("Reflectivity", Range(0, 1)) = 0.5 // Reflectivity of the object
        _OutlineColor("Outline Color", Color) = (0,0,0,1) // Color for the object outline
        _OutlineThickness("Outline Thickness", Range(0, 0.05)) = 0.02 // Thickness of the outline
        _ToonSteps("Toon Steps", Range(1, 10)) = 3 // Number of steps for the toon shading effect
        _ShadowColor("Shadow Color", Color) = (0,0,0,1) // Color for the shadows
        _ShadowStrength("Shadow Strength", Range(0, 1)) = 0.5 // Strength of the shadows
        
        // Toggles for various effects
        _ToggleEffects("Enable All Effects", Float) = 1 // Master toggle for all effects
        _ToggleReflection("Toggle Reflection", Float) = 1 // Toggle reflection effect
        _ToggleRim("Toggle Rim Lighting", Float) = 1 // Toggle rim lighting effect
        _ToggleOutline("Toggle Outline", Float) = 1 // Toggle outline effect
        _ToggleShadow("Toggle Shadow", Float) = 1 // Toggle shadow effect
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase" // Forward rendering mode with base pass lighting
                "PassFlags" = "OnlyDirectional" // Only processes directional lights
            }

            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members reflDir)
#pragma exclude_renderers d3d11
            #pragma vertex vert // Vertex shader function name
            #pragma fragment frag // Fragment shader function name
            #pragma multi_compile_fwdbase // Supports multiple forward rendering paths

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityStandardUtils.cginc" // Needed for reflections

            // Struct to define inputs from the vertex shader
            struct appdata
            {
                float4 vertex : POSITION; // Vertex position
                float4 uv : TEXCOORD0; // Texture coordinates
                float3 normal : NORMAL; // Vertex normal
            };

            struct v2f
            {
                float4 pos : SV_POSITION; // Final clip space position
                float3 worldNormal : NORMAL; // Transformed normal in world space
                float2 uv : TEXCOORD0; // Transformed texture coordinates
                float3 viewDir : TEXCOORD1; // Direction from the camera to the vertex
                SHADOW_COORDS(2) // Coordinates for shadow calculation
                float3 reflDir; // Reflection direction for reflective surfaces
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color; // Color property
            float4 _AmbientColor; // Ambient light color
            float4 _SpecularColor; // Specular highlight color
            float _Glossiness; // Specular sharpness
            float4 _RimColor; // Rim light color
            float _RimAmount; // Rim light visibility
            float _RimThreshold; // Rim light sharpness
            float4 _ReflectionColor; // Reflection color
            float _Reflectivity; // Reflectivity amount
            float4 _OutlineColor; // Outline color
            float _OutlineThickness; // Outline thickness
            float _ToonSteps; // Toon shading steps
            float4 _ShadowColor; // Shadow color
            float _ShadowStrength; // Shadow strength
            float _ToggleEffects; // Master toggle for effects
            float _ToggleReflection; // Toggle reflection
            float _ToggleRim; // Toggle rim lighting
            float _ToggleOutline; // Toggle outline
            float _ToggleShadow; // Toggle shadow

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Convert object space vertex position to clip space
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // Convert object space normal to world space
                o.viewDir = WorldSpaceViewDir(v.vertex); // Get the direction from the camera to the vertex

                // Reflection direction
                o.reflDir = reflect(-o.viewDir, o.worldNormal); // Calculate reflection vector

                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // Apply texture scale and offset to UVs
                TRANSFER_SHADOW(o) // Pass shadow data
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                if (_ToggleEffects == 0) // If all effects are disabled, just return the main texture color
                    return tex2D(_MainTex, i.uv) * _Color;

                float3 normal = normalize(i.worldNormal); // Normalize the interpolated normal
                float3 viewDir = normalize(i.viewDir); // Normalize the view direction

                // Toon shading: calculate light intensity in steps
                float NdotL = max(dot(_WorldSpaceLightPos0, normal), 0); // Dot product for light intensity
                NdotL = floor(NdotL * _ToonSteps) / _ToonSteps; // Quantize the light intensity into steps

                float4 light = NdotL * _LightColor0; // Apply light color
                
                // Specular highlights
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = max(dot(normal, halfVector), 0);
                float specular = pow(NdotH, _Glossiness) * _SpecularColor;

                // Rim lighting (only if enabled)
                float4 rim = float4(0, 0, 0, 0);
                if (_ToggleRim > 0)
                {
                    float rimDot = 1 - dot(viewDir, normal); // Rim lighting based on angle between view and normal
                    float rimIntensity = pow(rimDot, _RimThreshold) * _RimAmount;
                    rim = rimIntensity * _RimColor;
                }

                // Reflection (only if enabled)
                float4 reflection = float4(0, 0, 0, 0);
                if (_ToggleReflection > 0)
                {
                    reflection = texCUBE(_Cube, i.reflDir) * _Reflectivity * _ReflectionColor;
                }

                // Shadows (only if enabled)
                float4 shadow = float4(0, 0, 0, 0);
                if (_ToggleShadow > 0)
                {
                    float shadowAttenuation = SHADOW_ATTENUATION(i); // Shadow strength
                    shadow = lerp(_ShadowColor, float4(0, 0, 0, 1), shadowAttenuation * _ShadowStrength);
                }

                // Outline (only if enabled)
                float4 outline = float4(0, 0, 0, 0);
                if (_ToggleOutline > 0)
                {
                    float3 outlineDir = normalize(viewDir - normal * _OutlineThickness); // Basic outline effect
                    float outlineFactor = dot(outlineDir, normal);
                    outline = (1 - outlineFactor) * _OutlineColor;
                }

                // Sample main texture and combine all effects
                float4 sample = tex2D(_MainTex, i.uv);
                return ((light + _AmbientColor + specular + rim + shadow + reflection) * _Color * sample) + outline;
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
