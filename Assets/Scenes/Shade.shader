/*

Theoretical component

Anatomy of a shader:

A shader is a small program executed by the GPU to control various stages of the rendering pipeline. There are two main types of shaders:
Vertex Shader: Processes vertex attributes (position, normals, etc.).
Fragment (Pixel) Shader: Calculates color and other pixel properties.
[Vertex Shader] --> [Rasterization] --> [Fragment Shader] --> [Output to Frame Buffer]

Rendering Pipeline

The Rendering Pipeline is the process the GPU follows to transform 3D models into 2D pixels on the screen.
[Vertices] --> [Vertex Shader] --> [Primitive Assembly] --> [Rasterization] --> [Fragment Shader] --> [Depth/Stencil Test] --> [Final Frame Buffer]

Lighting Model

Phong Lighting: Combines ambient, diffuse, and specular lighting components.
Blinn-Phong: An optimized version of Phong, using a halfway vector for specular calculations.

[Vertex Shader] --> [Diffuse Lighting] --> [Specular Lighting] --> [Combine] --> [Final Color]

Normal Mapping & Bump Mapping
Normal Mapping: Uses texture information to alter the surface normals for lighting, simulating surface details.
Bump Mapping: Similar, but adjusts the pixel shading based on a height map.
[Base Texture] --> [Normal Map Texture] --> [Fragment Shader Adjusts Normals] --> [Lighting]

Rim Lighting
Rim lighting highlights the edges of objects, typically by brightening areas where the view direction is tangent to the surface normal.

[Normal Vector] --> [View Direction] --> [Rim Lighting Factor] --> [Final Color]

Physically Based Rendering (PBR)
PBR models light more realistically, using parameters like albedo, roughness, and metalness for lighting calculations.
[Surface Properties (Albedo, Roughness)] --> [Lighting Calculation] --> [Physically Accurate Shading]
Color Grading
Color grading is the process of adjusting the color balance of a rendered scene to create a specific mood or style.
[Render Output] --> [Color Grading Adjustment] --> [Final Output]

Toon Shading
Toon shading (cel shading) creates a cartoon-like effect by quantizing the shading into discrete color bands.
[Vertex Shader] --> [Flat Color Shading] --> [Edge Detection] --> [Toon Shader Output]
Transparency
Transparency blends the color of an object with the background based on its alpha value.
[Fragment Shader] --> [Alpha Blending] --> [Final Pixel Color]


Visual Effects

Toon Shading (Cel Shading)
Explanation: Toon shading gives objects a cartoon-like appearance by using flat colors with sharp transitions between them, instead of smooth gradients.
Example: Popular in games like The Legend of Zelda: The Wind Waker and Borderlands.
Calculate light direction
vec3 lightDir = normalize(lightPos - fragPos);
Compute dot product between light direction and normal
float intensity = dot(lightDir, normal);
Quantize intensity for toon shading
float toonIntensity = step(threshold, intensity);
Apply toon shading based on the quantized intensity
vec3 color = mix(shadowColor, lightColor, toonIntensity);
Argument: The primary reason for using toon shading is artistic: it simplifies the shading of 3D objects to mimic hand-drawn animation styles. We use the step() function to achieve the sharp color transitions that are characteristic of this style.


Flat Shading
Explanation: Flat shading calculates one normal per polygon (usually per triangle) and shades the entire polygon with a single color.
Example: Retro games like Star Fox or simple low-poly games.

vec3 normal = normalize(cross(edge1, edge2));
vec3 lightDir = normalize(lightPos - fragPos);
float intensity = max(dot(normal, lightDir), 0.0);
vec3 color = intensity * surfaceColor;
Argument: Flat shading is computationally inexpensive since it only calculates a single normal and light interaction for each polygon. It's suitable for low-poly designs or retro aesthetic purposes.


Normal Mapping
Explanation: Normal mapping uses a texture to provide more detailed surface lighting without adding more geometry. The texture contains normal data (tangent-space vectors) that perturbs the original surface normals.
Example: Used in Unreal Engine to give low-poly objects the appearance of being high-poly.


vec3 normalMap = texture(normalMapTex, uvCoords).xyz * 2.0 - 1.0;
vec3 worldNormal = normalize(TBN * normalMap);
vec3 lightDir = normalize(lightPos - fragPos);
float intensity = max(dot(worldNormal, lightDir), 0.0);
Argument: By using normal maps, you can achieve complex surface details with low-performance cost since the complexity is in the texture, not in the geometry. 
The transformation via the TBN (tangent, bitangent, normal) matrix ensures that the normals align properly in 3D space.


 Bump Mapping
Explanation: Similar to normal mapping, but bump mapping uses a height map to simulate small-scale surface detail (like bumps or dents) by modifying the surface normal.
Example: Used in older games or situations where normal mapping isn't required.

float height = texture(bumpMapTex, uvCoords).r;
vec3 bumpNormal = normalize(normal + height * bumpFactor);
vec3 lightDir = normalize(lightPos - fragPos);
float intensity = max(dot(bumpNormal, lightDir), 0.0);
Argument: Bump mapping is easier to implement than normal mapping but offers less detail. It gives the illusion of depth and texture without modifying the underlying geometry.


Specular Shading
Explanation: Specular shading calculates how shiny a surface is based on the reflection of light. This effect mimics materials like metal or polished surfaces.
Example: Used in most modern 3D games for shiny surfaces.

vec3 lightDir = normalize(lightPos - fragPos);
vec3 viewDir = normalize(viewPos - fragPos);
vec3 reflectDir = reflect(-lightDir, normal);
float specFactor = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
vec3 specular = specFactor * lightColor * materialSpecularColor;
Argument: Specular shading adds realism to materials that reflect light sharply (like metals or glass). The use of the reflect() function combined with a specular power (shininess) gives control over how focused or spread out the reflection appears.


Color Correction
Explanation: Color correction adjusts the color balance of a scene to achieve a desired visual effect, such as enhancing contrast, brightness, or saturation.
Example: Used in post-processing for games and film to adjust for mood or environmental effects.


vec3 correctedColor = colorMatrix * originalColor;
Argument: Color correction is often applied in post-processing to adjust the overall tone of a scene. 
This helps unify the visual style and can emphasize certain mood settings (e.g., warmer colors for sunny scenes, cooler colors for night scenes).


Hologram Shader
Explanation: Hologram shaders simulate the appearance of a holographic display with scanlines, distortion, and transparency.
Example: Seen in games like Deus Ex for sci-fi interfaces.

float scanline = sin(uvCoords.y * scanlineDensity) * scanlineIntensity;
vec4 hologramColor = vec4(originalColor.rgb + scanline, originalColor.a * transparency);
Argument: The combination of distortion effects and transparency creates a futuristic hologram appearance. This effect is often layered over other shaders for sci-fi themes.


Other Shaders: Bloom (Bonus)
Explanation: Bloom adds a glow effect to bright areas of a scene, simulating overexposed light.
Example: Common in high dynamic range (HDR) rendering for bright light sources.

vec3 brightColor = max(originalColor - bloomThreshold, 0.0);
vec3 bloomEffect = applyGaussianBlur(brightColor);
vec3 finalColor = originalColor + bloomEffect;
Argument: Bloom makes bright light sources appear more realistic by creating a glow that bleeds into surrounding areas. This effect is particularly useful in scenes with intense light, like sunlight or artificial lights.


Programming Choices Argument
Each shader is chosen based on the artistic style and computational complexity:

Flat shading is simple and fast but suitable for stylized or retro games.
Normal mapping is more advanced and provides detailed surface features without heavy geometry, making it ideal for more realistic games.
Toon shading and specular shading are both driven by artistic goals (cel-shading for cartoon-like visuals, specular for realistic reflections).
Post-processing shaders like bloom and color correction can significantly enhance the aesthetic and mood of a scene, unifying its visual style.




Components of the Standard Light Model:


The Phong reflection model is a common lighting model used to compute pixel color based on interactions between light and surfaces. It consists of three main components:

Ambient Lighting:

Represents indirect, global light scattered in the scene.

Formula ambient = ka x Ia

Diffuse Lighting:

Simulates light scattered off rough surfaces, depending on the angle between the surface normal and light direction.
Formula: diffuse kd x Id x max(0, L x N)


Specular Lighting:

Models shiny reflections, depending on the viewer's position and reflection direction.
Formula:ks x Is x max(0, R x V)n

Combined Light equation: I = ka x Ia + kd x Id x max (0, L x N) + ks x Is x max (0, R x V)n

Limitations:
No global illumination: Doesn’t account for indirect light bounces.
Simplistic materials: Over-simplifies real-world surfaces like glass, metal, or fabric.
No shadows: Doesn’t handle shadows unless added through other techniques.
Point lights only: Assumes simple light sources and lacks support for area or complex lights.
In complex scenes or realistic renderings, techniques like global illumination and physically based rendering (PBR) are used to overcome these limitations.


Buffers
Vertex Buffer: Stores vertex data (positions, normals).

Example:

float4 vertex : POSITION;

Outcome: Defines object shapes.
Frame Buffer: Stores the final image.

Outcome: Displays the rendered scene.
Depth Buffer: Holds depth (Z) values to manage object occlusion.

Example:

float depth = tex2D(_CameraDepthTexture, i.uv).r;
Outcome: Handles which objects are in front.
Stencil Buffer: Controls where rendering occurs, for masking effects.

Example:
Stencil { Ref 1 Comp Equal }
Outcome: Used for effects like masking or outlining.
Color Buffer: Stores per-pixel color data.

Example:
float4 color = tex2D(_MainTex, i.uv);
Outcome: Final pixel colors.
Render Target Buffer (MRT): Allows writing to multiple buffers for advanced techniques (e.g., deferred shading).

Example:
SV_Target0 = albedoColor;
SV_Target1 = normalMap;
Outcome: Supports complex lighting techniques.
Example Outcomes:
Depth of Field (using depth buffer): Creates blurred backgrounds for objects far from the camera.
Outlines (using stencil buffer): Highlights selected objects.


Shaders Fundamentals

Lambert: Only diffuse lighting (light scattered equally on rough surfaces).
Ambient: Adds indirect, uniform light everywhere.
Phong: Adds specular highlights using the reflection vector, more expensive computation.
Blinn-Phong: Optimized specular using a halfway vector, often faster and smoother.

Each lighting model provides varying levels of realism and performance, with Blinn-Phong often favored for real-time graphics due to its efficiency.


Graphics Pipeline
The graphics pipeline is the sequence of steps that a GPU follows to render 3D objects onto a 2D screen. It transforms 3D models into pixels that make up the final image. 
The pipeline can be divided into two main stages: fixed-function (in older systems) and programmable (modern systems)

[Application] --> [Vertex Shader] --> [Primitive Assembly] --> [Rasterization]
      --> [Fragment Shader] --> [Depth/Stencil Testing] --> [Output Merging] --> [Frame Buffer]


Fixed-Function Pipeline (Legacy OpenGL):

Older versions of OpenGL (before version 3.0) used a fixed-function pipeline where stages were hard-coded, and developers had limited control over the shading process.
Example: You could call simple functions like glVertex() to specify vertices, and OpenGL would handle the lighting and shading without custom shaders.
Programmable Pipeline (Modern OpenGL):

Modern OpenGL (from version 3.0 onwards) introduced the programmable pipeline, allowing developers to write custom shaders (vertex, fragment, etc.). This gives more control over rendering and flexibility in visual effects.
Example: In modern OpenGL, you write GLSL shaders for custom lighting and materials, providing more detailed and optimized control of rendering techniques.

Modern OpenGL provides far greater flexibility and performance improvements by allowing developers to program custom shader behavior.


Stages of the Graphics Pipeline\

Application Stage:

Managed by the CPU, this stage prepares data like vertex positions, textures, and shader programs.
Example: The CPU sends the 3D model’s vertices, textures, and lighting data to the GPU for processing.
Vertex Processing:

Vertex Shader: Transforms 3D vertices into 2D screen space coordinates. Also processes normals, colors, and texture coordinates.
Example: A vertex shader might rotate an object or compute lighting per vertex.
Primitive Assembly:

Assembles vertices into geometric shapes (triangles, lines, etc.).
Example: Vertices form a triangle to be rasterized.
Rasterization:

Converts the assembled primitives (triangles) into fragments (potential pixels). Determines which pixels are covered by the primitives.
Example: A triangle is rasterized into individual pixels, which will then be shaded.
Fragment Processing:

Fragment Shader: Computes the color of each fragment, including texture mapping, lighting, and shadows.
Example: A fragment shader might apply a texture to an object or compute complex lighting effects like Phong shading.
Depth and Stencil Testing:

Ensures correct visibility of fragments (which fragment is in front) and applies stencil operations.
Example: Depth testing prevents fragments behind an object from being rendered.
Output Merging:

Combines all fragments to produce the final pixel colors in the frame buffer. Handles transparency, blending, and antialiasing.
Example: Two semi-transparent objects blend to create a see-through effect.


A Graphics API is a set of tools and protocols that allows developers to communicate with the GPU to create and manage graphical content. 
It defines how software can use the graphics hardware to render 2D and 3D images, handling tasks like drawing shapes, rendering textures, and applying effects.


Low-Level Graphics APIs:

Direct communication with GPU, offering more control but requiring more effort to manage resources and performance.
Examples:
Vulkan: A cross-platform, low-level API known for its high performance and efficiency.
DirectX 12: A low-level API by Microsoft, focused on Windows platforms and Xbox consoles.
Metal: A low-level API by Apple, optimized for macOS, iOS, and other Apple devices.
High-Level Graphics APIs:

Abstract much of the hardware complexity, making them easier to use but with less direct control over the hardware.
Examples:
OpenGL: A cross-platform API, widely used but less performant than low-level APIs due to higher abstraction.
DirectX 11: A higher-level version of Microsoft’s DirectX, with more ease of use than DirectX 12.
WebGL: A high-level API based on OpenGL, designed to render graphics in web browsers.

*/

