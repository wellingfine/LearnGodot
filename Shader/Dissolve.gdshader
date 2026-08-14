shader_type canvas_item;
 
uniform sampler2D noise_tex;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
 

void fragment() {
  vec4 sprite = texture(TEXTURE, UV); // 采样原图颜色
  float noise = texture(noise_tex, UV).r;
    
  if (noise < threshold) {
    
    COLOR=vec4(1.0, 0.0, 1.0, 1.0);
    discard;
  }

  //if (noise < threshold + edge_width) {
    //// 噪声值落在 [threshold, threshold + edge_width] 区间的像素会显示边缘颜色。
    //COLOR = edge_color;
  //} else {
    //COLOR = sprite;
  //}
}