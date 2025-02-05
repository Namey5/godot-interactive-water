shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.01, 0.01, 0.05, 1.0);
uniform vec4 scattering : source_color = vec4(1.0, 0.4, 0.4, 1.0);
uniform float refraction_strength : hint_range(0.0, 1000.0, 1.0) = 100.0;
uniform float depth_blur : hint_range(0.0, 10.0, 0.1) = 4.0;
uniform float waves_strength : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform sampler2D waves_map : hint_normal;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float raw_depth = textureLod(depth_tex, SCREEN_UV, 0.0).x;
	vec4 scene_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	scene_pos.xyz /= scene_pos.w;
	float scene_depth = abs(scene_pos.z);
	float local_depth = abs(VERTEX.z);
	float water_depth = (scene_depth - local_depth);
	vec4 depth_scattering = exp(vec4(scattering.rgb, 1.0) * -(water_depth * 5.0));
	depth_scattering.w = 1.0 - depth_scattering.w;
	
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.05;
	
	NORMAL_MAP = (texture(waves_map, world_pos.xz / 3.0 + TIME * 0.1).xyz + texture(waves_map, world_pos.xz / 2.5 - TIME * 0.1).xyz) * 0.5;
	NORMAL_MAP_DEPTH = waves_strength;
	
	EMISSION = textureLod(screen_tex, SCREEN_UV + ((NORMAL_MAP.xy * 2.0 - 1.0) / VIEWPORT_SIZE) * (waves_strength * refraction_strength * depth_scattering.w / abs(VERTEX.z)), depth_scattering.w * depth_blur).rgb * depth_scattering.rgb;
	ALPHA = depth_scattering.w;
}
