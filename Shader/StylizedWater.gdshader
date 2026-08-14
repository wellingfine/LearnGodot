shader_type canvas_item;
 
uniform float wave_speed = 1.0;
uniform float wave_amount : hint_range(0.0, 0.05) = 0.01;
uniform vec4 water_tint : source_color = vec4(0.3, 0.6, 0.8, 0.6);
 
void fragment() {
    vec2 distorted_uv = UV; // UV为图片原始UV
    distorted_uv.x += sin(UV.y * 20.0 + TIME * wave_speed) * wave_amount;
    distorted_uv.y += cos(UV.x * 20.0 + TIME * wave_speed) * wave_amount;
  
    // 改过UV之后，再采样一次，就拿到不同的图像
    vec4 base = texture(TEXTURE, distorted_uv);
    // 做一次平滑
    COLOR = mix(base, water_tint, water_tint.a); 
}