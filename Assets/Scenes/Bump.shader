Shader "Custom/Bump"
{
    Properties
    {
        // _Color is the base color that can be modified in the shader
        _Color ("Main Color", Color) = (1,1,1,1)
        // _MainTex is the main texture defaulted to white
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        // _BumpMap is the normal map defaulted to a bump texture
        _BumpMap ("Normalmap", 2D) = "bump" {}
    }

    // Define the actual rendering part of the shader
    SubShader
    {
        // Tags which determine how shader is handled in the rendering pipeline
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        // Enable alpha blending
        Blend SrcAlpha OneMinusSrcAlpha
        // Disable writing to the depth buffer
        ZWrite Off
        
        // Start
        CGPROGRAM
        
        // Use the surface shader model with BlinnPhong lighting, vertex function, and support for full forward shadows
        #pragma surface surf BlinnPhong vertex:vert fullforwardshadows alpha:fade
        // Set shader target to 3.0, defining the minimum graphics hardware needed to run it
        #pragma target 3.0

        // Define textures used in the shader
        sampler2D _MainTex;  // The main texture
        sampler2D _BumpMap;  // The bump map 
        fixed4 _Color;       // The color multiplier

        // Define the Input structure passed to the surface function
        struct Input
        {
            float2 uv_MainTex;   // UV coordinates for main texture
            float2 uv_BumpMap;   // UV coordinates for bump map
            float4 color : COLOR; // Vertex color passed from the mesh
        };

        // Vertex function to pass vertex data to the input structure
        void vert (inout appdata_full v, out Input o)
        {
            // Initialize the Input structure
            UNITY_INITIALIZE_OUTPUT(Input,o);
            // Store the vertex color in Input
            o.color = v.color;
        }

        // Surface function that defines how the shader interacts with lighting and textures
        void surf (Input IN, inout SurfaceOutput o)
        {
            // Get the texture color at the UV position, multiplied by the base color
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            // Set the albedo to the texture's RGB value
            o.Albedo = c.rgb;
            // Unpack the normal map and apply it to the surface's normal
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            // Set the surface's alpha based on the texture and vertex color alpha
            o.Alpha = c.a * IN.color.a;
        }

        // end
        ENDCG
    }
}
