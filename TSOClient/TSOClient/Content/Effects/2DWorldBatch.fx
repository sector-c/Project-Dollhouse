/**
 * Various effects for rendering the 2D world.
 */
float4x4 viewProjection  : ViewProjection;
float4x4 worldViewProjection;
float worldUnitsPerTile = 2.5;

texture pixelTexture : Diffuse <string ResourceName = "default_color.dds";>;
texture depthTexture : Diffuse <string ResourceName = "default_depth.dds";>;

sampler pixelSampler = sampler_state {
    texture = <pixelTexture>;
    AddressU  = CLAMP; AddressV  = CLAMP; AddressW  = CLAMP;
    MIPFILTER = POINT; MINFILTER = POINT; MAGFILTER = POINT;
};

sampler depthSampler = sampler_state {
    texture = <depthTexture>;
    AddressU  = CLAMP; AddressV  = CLAMP; AddressW  = CLAMP;
    MIPFILTER = POINT; MINFILTER = POINT; MAGFILTER = POINT;
};


/**
 * SIMPLE EFFECT
 *   This effect simply draws the pixel texture onto the screen.
 *   Args:
 *		pixelTexture - Texture to sample for the pixel output
 */

struct SimpleVertex {
    float4 position: POSITION;
    float2 texCoords : TEXCOORD0;
};

SimpleVertex vsSimple(SimpleVertex v){
    SimpleVertex result;
    result.position = mul(v.position, viewProjection);
    result.texCoords = v.texCoords;
    return result;
}

void psSimple(SimpleVertex v, out float4 color: COLOR0){
	color = tex2D( pixelSampler, v.texCoords);
}

technique drawSimple {
   pass p0 {
		AlphaBlendEnable = TRUE; DestBlend = INVSRCALPHA; SrcBlend = SRCALPHA;
        ZEnable = false; ZWriteEnable = false;
        CullMode = CCW;
        
        VertexShader = compile vs_1_1 vsSimple();
        PixelShader  = compile ps_2_0 psSimple();
   }
}


/**
 * SPRITE ZBUFFER EFFECT
 *   This effect draws the pixels from the pixel sampler with depth provided by a zbuffer sprite.
 *   The depth buffer is used along with the sprites world coordinates to determine an absolute
 *   depth value.
 *   
 *   Args:
 *		pixelTexture - Texture to sample for the pixel output
 *		depthTexture - Texture to sample for the zbuffer values
 *		worldPosition - Position of the object in the world
 */

struct ZVertexIn {
	float4 position: POSITION;
    float2 texCoords : TEXCOORD0;
    float4 worldCoords : TEXCOORD1;
};

struct ZVertexOut {
	float4 position: POSITION;
    float2 texCoords : TEXCOORD0;
    float backDepth: TEXCOORD2;
    float frontDepth: TEXCOORD3;
    float refDepth: TEXCOORD4;
};

ZVertexOut vsZSprite(ZVertexIn v){
    ZVertexOut result;
    result.position = mul(v.position, viewProjection);
    result.texCoords = v.texCoords;
    
    float4 backPosition = v.worldCoords;
    float4 frontPosition = v.worldCoords;
    float4 refPosition = v.worldCoords;
    frontPosition.x += 3.0;
    frontPosition.z += 3.0;
    
    //x=1.5 y=3.0 for TopLeft
    //x=3, y=1.5 for TopRight
    refPosition.x = 1.5;
    refPosition.z = 3.0;
    
    float4 backProjection = mul( backPosition, worldViewProjection );
    float4 frontProjection = mul( frontPosition, worldViewProjection);
    float4 refProjection = mul( refPosition, worldViewProjection);
    
    result.backDepth = backProjection.z / backProjection.w;
    result.frontDepth = frontProjection.z / frontProjection.w;
    result.frontDepth -= result.backDepth;
    result.refDepth = refPosition;
    return result;
}

void psZSprite(ZVertexOut v, out float4 color:COLOR, out float depth:DEPTH0) {
    color = tex2D( pixelSampler, v.texCoords);
    //depth = v.backDepth + ((1-tex2D(depthSampler, v.texCoords).r) * v.frontDepth);
    
    float difference = v.refDepth - tex2D(depthSampler, v.texCoords).r;    
    depth = v.backDepth + (difference*v.frontDepth);
    
    
    //output.Color.rbg = v.DepthLow + ((1-tex2D(depthSampler, v.TexCoord).r) * v.DepthHigh);
    //output.Color.a = 1;
}


technique drawZSprite {
   pass p0 {
		AlphaBlendEnable = TRUE; DestBlend = INVSRCALPHA; SrcBlend = SRCALPHA;
        AlphaTestEnable = true; AlphaRef = 255; AlphaFunc = Equal;
        
        ZEnable = true; ZWriteEnable = true;
        CullMode = CCW;
        
        VertexShader = compile vs_1_1 vsZSprite();
        PixelShader  = compile ps_2_0 psZSprite();
   }
}

/**
 * SPRITE ZBUFFER EFFECT DEPTH CHANNEL
 *   Same as the sprite zbuffer effect except it draws the depth to the output render target.
 *	 This allows you to restore it at a later date.
 *   
 *   Args:
 *		pixelTexture - Texture to sample for the pixel output
 *		depthTexture - Texture to sample for the zbuffer values
 *		worldPosition - Position of the object in the world
 */

void psZDepthSprite(ZVertexOut v, out float4 color:COLOR, out float depth:DEPTH0) {
	float4 pixel = tex2D( pixelSampler, v.texCoords);
    float difference = v.refDepth - tex2D(depthSampler, v.texCoords).r;    
    depth = v.backDepth + (difference*v.frontDepth);
    
    //Copy alpha pixel so alpha test creates same result
    color = depth;
    color.a = pixel.a;
}

technique drawZSpriteDepthChannel {
   pass p0 {
		AlphaBlendEnable = TRUE; DestBlend = INVSRCALPHA; SrcBlend = SRCALPHA;
        AlphaTestEnable = true; AlphaRef = 255; AlphaFunc = Equal;
        
        ZEnable = true; ZWriteEnable = true;
        CullMode = CCW;
        
        VertexShader = compile vs_1_1 vsZSprite();
        PixelShader  = compile ps_2_0 psZDepthSprite();
   }
}


/**
 * SIMPLE EFFECT WITH RESTORE DEPTH
 *   Same as simple effect except the depth buffer is restored using a texture
 *   
 *   Args:
 *		pixelTexture - Texture to sample for the pixel output
 *		depthTexture - Texture to sample for absolute z-values
 */
 

void psSimpleRestoreDepth(SimpleVertex v, out float4 color: COLOR0, out float depth:DEPTH0){
	color = tex2D( pixelSampler, v.texCoords);
	depth = tex2D( depthSampler, v.texCoords).r;
}

technique drawSimpleRestoreDepth {
   pass p0 {
		AlphaBlendEnable = TRUE; DestBlend = INVSRCALPHA; SrcBlend = SRCALPHA;
        ZEnable = true; ZWriteEnable = true;
        CullMode = CCW;
        
        VertexShader = compile vs_1_1 vsSimple();
        PixelShader  = compile ps_2_0 psSimpleRestoreDepth();
   }
}






