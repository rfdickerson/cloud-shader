shader_type spatial;
render_mode unshaded;
//render_mode unshaded, world_vertex_coords; // to raymarch in world space

varying vec3 world_camera;
varying vec3 world_position;

uniform sampler3D noiseTexture;

uniform float alpha: hint_range(0.001, 0.05) = 0.02;
// stepping inside of the volume
uniform float step_size: hint_range(0.001, 0.01);

const int MAX_STEPS = 200;
const float MAX_DIST = 20.0;
const float SURF_DIST = 1e-3;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}


float GetDist(vec3 p){
	float d = length(p) - .5; //Sphere
	//
	//d = length(vec2(length(p.xz) - .5, p.y)) - .1; //torus
	
	return d;
}

float DensityFunction (float sdf){
	return max(-sdf, 0.0);
}

vec2 RayMarch(vec3 ro, vec3 rd) {
	
	float dO = 0.0;
	float dS;
	//float t = 0.0;
	float accumDistance = 0.0;
	
	float dHit = 0.0;
	
	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		
		float r = random(p.xy)/100.0;
		
		if (dO >= MAX_DIST)
			break;
		
		if (dS < SURF_DIST) {
			
			if (dHit==0.0) {
				dHit = dO;
			}
			
			//float density = texture(noiseTexture, (vec3(1.0)-p)*2.0).x;
			float density = texture(noiseTexture, p + vec3(1.0)/2.0).x;
			accumDistance += density * step_size;
			
		}
		
		// inside of volume
		dO += max(step_size + r, dS);
		//dO += dS <= 0.0 ? step_size : dS;
		//dO += dS < SURF_DIST ? step_size: max(dS, step_size);
		
	}
	
	return vec2(accumDistance, dHit);
}

vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1e-2, 0);
	
	vec3 n = GetDist(p) - vec3(
		GetDist(p - e.xyy),
		GetDist(p - e.yxy),
		GetDist(p - e.yyx)
	);
	
	return normalize(n);
}

void vertex() {
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz; //object space
	//world_camera = ( CAMERA_MATRIX  * vec4(0, 0, 0, 1)).xyz; //uncomment this to raymarch in world space
}

void fragment() {
	
	vec3 ro = world_camera;
	vec3 rd =  normalize(world_position - ro);
	
	vec2 result = RayMarch(ro, rd);
	
	if (result.y == 0.0) 
		discard;
		
	float transmittance = exp(-result.x * 10.0 );
	
	ALBEDO = vec3(0.8);
	ALPHA = (1.0-transmittance);
	DEPTH = result.y;
}