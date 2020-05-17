// Base for this shader:
// https://github.com/obsproject/obs-studio/blob/master/plugins/obs-filters/data/chroma_key_filter.effect

// This shader is for:
// https://github.com/Oncorporation/obs-shaderfilter/

// Licence: GNU General Public License v2.0

uniform texture2d alpha_image;

uniform	float4x4 yuv_mat = { 0.182586,  0.614231,  0.062007, 0.062745,
                            -0.100644, -0.338572,  0.439216, 0.501961,
                             0.439216, -0.398942, -0.040274, 0.501961,
                             0.000000,  0.000000,  0.000000, 1.000000};

uniform float4 color;
uniform float contrast = 1.06;
uniform float brightness = 0;
uniform float gamma = 0.70;

uniform float2 chroma_key = {0,0};
uniform float similarity = 0.38;
uniform float smoothness = 0.27;
uniform float spill = 0.36;

float4 mainImage(VertData v_in) : TARGET
{	
	float4 rgba = image.Sample(textureSampler, v_in.uv);
	float alpha = alpha_image.Sample(textureSampler, v_in.uv).a;

	if ( alpha < 1 )
	{
		float2 h_pixel_size = uv_pixel_interval / 2.0;
		float2 point_0 = float2(uv_pixel_interval.x, h_pixel_size.y);
		float2 point_1 = float2(h_pixel_size.x, -uv_pixel_interval.y);
		float distVal = distance(chroma_key, mul(float4(image.Sample(textureSampler,v_in.uv-point_0).rgb, 1.0), yuv_mat).yz);
		distVal += distance(chroma_key, mul(float4(image.Sample(textureSampler,v_in.uv+point_0).rgb, 1.0), yuv_mat).yz);
		distVal += distance(chroma_key, mul(float4(image.Sample(textureSampler,v_in.uv-point_1).rgb, 1.0), yuv_mat).yz);
		distVal += distance(chroma_key, mul(float4(image.Sample(textureSampler,v_in.uv+point_1).rgb, 1.0), yuv_mat).yz);
		distVal *= 2.0;
		distVal += distance(chroma_key, mul(float4(rgba.rgb, 1.0), yuv_mat).yz);
		float chromaDist = distVal / 9.0;
		float baseMask = chromaDist - similarity;
		float fullMask = pow(saturate(baseMask / smoothness), 1.5);
		float spillVal = pow(saturate(baseMask / spill), 1.5);

		rgba.rgba *= color;
		
		rgba.a *= max(fullMask, alpha);
		spillVal = max(spillVal, alpha);

		float desat = (rgba.r * 0.2126 + rgba.g * 0.7152 + rgba.b * 0.0722);
		rgba.rgb = saturate(float3(desat, desat, desat)) * (1.0 - spillVal) + rgba.rgb * spillVal;
	}
	
	return float4(pow(rgba.rgb, float3(gamma, gamma, gamma)) * contrast + brightness, rgba.a);
}