Shader "DeanToon"
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
    }

    SubShader
    {
        Pass
        {
            // Tags specify rendering and lighting details for this pass
            Tags
            {
                "LightMode" = "ForwardBase" // Forward rendering mode with base pass lighting
                "PassFlags" = "OnlyDirectional" // Only processes directional lights
            }

            // Begin the Cg program for the vertex and fragment shaders
            CGPROGRAM
            #pragma vertex vert // Vertex shader function name
            #pragma fragment frag // Fragment shader function name
            #pragma multi_compile_fwdbase // Supports multiple forward rendering paths

            // Include Unity's common shader libraries
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            // Struct to define inputs from the vertex shader
            struct appdata
            {
                float4 vertex : POSITION; // Vertex position
                float4 uv : TEXCOORD0; // Texture coordinates
                float3 normal : NORMAL; // Vertex normal
            };

            // Struct to define outputs to the fragment shader
            struct v2f
            {
                float4 pos : SV_POSITION; // Final clip space position
                float3 worldNormal : NORMAL; // Transformed normal in world space
                float2 uv : TEXCOORD0; // Transformed texture coordinates
                float3 viewDir : TEXCOORD1; // Direction from the camera to the vertex
                SHADOW_COORDS(2) // Coordinates for shadow calculation
            };

            // Texture sampler for the main texture
            sampler2D _MainTex;
            float4 _MainTex_ST; // Scale and offset for texture UVs
            
            // Vertex shader function
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Convert object space vertex position to clip space
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // Convert object space normal to world space
                o.viewDir = WorldSpaceViewDir(v.vertex); // Get the direction from the camera to the vertex
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // Apply texture scale and offset to UVs
                TRANSFER_SHADOW(o) // Pass shadow data
                return o;
            }

            // Uniform variables for use in the fragment shader
            float4 _Color; // Color property
            float4 _AmbientColor; // Ambient light color
            float4 _SpecularColor; // Specular highlight color
            float _Glossiness; // Specular sharpness
            float4 _RimColor; // Rim light color
            float _RimAmount; // Rim light visibility
            float _RimThreshold; // Rim light sharpness

            // Fragment shader function
            float4 frag(v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal); // Normalize the interpolated normal
                float3 viewDir = normalize(i.viewDir); // Normalize the view direction

                // Calculate light intensity based on the angle between the normal and the light direction
                float NdotL = dot(_WorldSpaceLightPos0, normal);
                float shadow = SHADOW_ATTENUATION(i); // Get shadow attenuation
                float lightIntensity = smoothstep(0, 0.01, NdotL * shadow); // Smooth light intensity
                float4 light = lightIntensity * _LightColor0; // Final light color

                // Calculate specular highlights
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir); // Halfway vector between light and view
                float NdotH = dot(normal, halfVector); // Dot product for specular calculation
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness); // Specular sharpness
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity); // Smooth the specular intensity
                float4 specular = specularIntensitySmooth * _SpecularColor; // Final specular color

                // Calculate rim lighting
                float rimDot = 1 - dot(viewDir, normal); // Dot product for rim light calculation
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold); // Control rim intensity
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity); // Smooth rim lighting
                float4 rim = rimIntensity * _RimColor; // Final rim light color

                // Sample the main texture
                float4 sample = tex2D(_MainTex, i.uv);

                // Combine all effects: light, ambient, specular, and rim lighting, with the base color and texture
                return (light + _AmbientColor + specular + rim) * _Color * sample;
            }
            ENDCG
        }

        // Use the shadow caster pass from the legacy vertex-lit shader
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
