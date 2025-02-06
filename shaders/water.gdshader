shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(0.01, 0.01, 0.05, 1.0);
uniform vec4 scattering : source_color = vec4(1.0, 0.4, 0.4, 1.0);
uniform float scattering_strength : hint_range(0.0, 100.0, 0.01) = 5.0;
uniform float refraction_strength : hint_range(0.0, 1000.0, 1.0) = 100.0;
uniform float depth_blur : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float waves_strength : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float waves_scale : hint_range(0.01, 100.0, 0.1) = 1.0;
uniform float waves_speed : hint_range(0.0, 100.0, 0.1) = 1.0;
uniform float displacement_height : hint_range(0.0, 2.0, 0.01) = 0.1;
uniform vec2 water_size = vec2(1.0);
uniform sampler2D waves_map : hint_normal;
uniform sampler2D ripples_map;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

vec2 get_ripple_uv(vec2 uv) {
	vec2 ratio = water_size / min(water_size.x, water_size.y);
	vec3 offset = vec3(0.25 / ratio.y, 0.25 / ratio.x, 0.0);
	if (ratio.x > ratio.y) {
		uv = uv / ratio + offset.zy;
	} else if (ratio.y > ratio.x) {
		uv = uv / ratio.yx + offset.xz;
	}
	return uv;
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 ripple_uv = get_ripple_uv(UV);
	VERTEX.y += (
		(textureLod(waves_map, world_pos.xz * waves_scale / 3.0 + TIME * waves_speed * 0.1, 4.0).z - 1.0) * 10.0 +
		(textureLod(waves_map, world_pos.xz * waves_scale / 2.5 - TIME * waves_speed * 0.1, 4.0).z - 1.0) * 10.0 +
		textureLod(ripples_map, ripple_uv, 4.0).x
	) * displacement_height;
}

void fragment() {
	// hack: poor-man's triplanar texturing
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float raw_depth = textureLod(depth_tex, SCREEN_UV, 0.0).x;
	vec4 scene_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	scene_pos.xyz /= scene_pos.w;
	float scene_depth = abs(scene_pos.z);
	float local_depth = abs(VERTEX.z);
	// todo: fix perspective distortion
	float water_depth = (scene_depth - local_depth);
	
	vec4 depth_scattering = exp(vec4(scattering.rgb, 1.0) * -(water_depth * scattering_strength));
	// used for edge blending:
	depth_scattering.w = 1.0 - depth_scattering.w;
	
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.05;
	
	// todo: texel size of ripples_map is currently hardcoded to 512x512
	const vec3 duv = vec3(1.0, 1.0, 0.0) / 1024.0;
	vec2 ripple_uv = get_ripple_uv(UV);
	// approximate normals from heightmap:
	vec4 ripples = vec4(
		texture(ripples_map, ripple_uv + duv.xz).x,
		texture(ripples_map, ripple_uv - duv.xz).x,
		texture(ripples_map, ripple_uv + duv.zy).x,
		texture(ripples_map, ripple_uv - duv.zy).x
	);
	ripples.xyz = normalize(vec3(ripples.x - ripples.y, ripples.z - ripples.w, 0.2));
	
	// blend between normal maps in [-1,1] then re-normalize:
	NORMAL_MAP = (
		// todo: make these configurable
		texture(waves_map, world_pos.xz * waves_scale / 3.0 + TIME * waves_speed * 0.1).xyz * 2.0 - 1.0 +
		texture(waves_map, world_pos.xz * waves_scale / 2.5 - TIME * waves_speed * 0.1).xyz * 2.0 - 1.0 +
		ripples.xyz
	) / 3.0 * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = waves_strength;
	
	vec2 refracted_uv = SCREEN_UV
		// hack: just use tangent-space normals.xz
		// (and make scale consistent at different resolutions):
		+ ((NORMAL_MAP.xy * 2.0 - 1.0) / VIEWPORT_SIZE)
		// scale by uniforms + edge blend + camera distance:
		* (waves_strength * refraction_strength * depth_scattering.w / local_depth);
	// hack: depth blur by offsetting mipmaps
	EMISSION = textureLod(screen_tex, refracted_uv, depth_scattering.w * depth_blur).rgb;
	EMISSION *= depth_scattering.rgb;
	ALPHA = depth_scattering.w;
}
