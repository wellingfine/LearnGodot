shader_type canvas_item;

// 扫描线的密度
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.3;

// 扫描线条数
uniform float scanline_freq : hint_range(100.0, 1000.0) = 400.0;

// 模拟CRT的曲面效果
uniform float curvature : hint_range(0.0, 0.5) = 0.1;
 
void fragment() {
  vec2 uv = UV;
  vec2 cc = uv - 0.5; // 移动到中心，centered coordinates

  // 计算当前像素到中心的距离平方（即 cc.x² + cc.y² - 2cosθ) (但夹角为0)
  // 使用 dot 比 length 更高效（少一次开方），没必要开方
  // 这个值在中心为 0，越靠近边缘越大，用于控制变形强度：边缘变形大，中心变形小
  float dist = dot(cc, cc); 


  // 核心变形公式：对 UV 坐标施加径向 barrel distortion（桶形畸变）。
  // cc * dist 表示变形方向沿径向向外，且随距离平方增长。
  // 乘以 curvature 控制整体变形幅度。
  // 最终效果：图像边缘向中心"鼓起"，模拟 CRT 屏幕的弧形表面。
  uv = uv + cc * dist * curvature;

  // 边界裁剪：变形后，原图边缘的像素可能会被"拉"到 UV 范围之外。
  // 如果 uv 超出 [0, 1] 范围，说明该位置没有有效纹理数据，直接输出纯黑色 vec4(0.0)。
  // 这就是 CRT 屏幕边缘出现的黑边效果。
  if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
      COLOR = vec4(0.0);
  } else {
    vec4 color = texture(TEXTURE, uv);
    // 生成扫描线遮罩：
    //     uv.y * scanline_freq：将垂直 UV 坐标放大，使 sin 波在垂直方向上高频振荡。
    //     sin(...) 输出范围 [-1, 1]。
    //     * 0.5 + 0.5 将其映射到 [0, 1] 范围。
    // 结果：scanline 在 0 和 1 之间平滑交替，形成明暗相间的水平条纹。
    float scanline = sin(uv.y * scanline_freq) * 0.5 + 0.5;

    // scanline_intensity * scanline 得到当前像素应降低的亮度值。
    // 1.0 - ... 使扫描线暗部更暗，亮部接近原色。
    // 对 color.rgb 做乘法，降低亮度而非完全变黑，保留图像细节。
    // 当 scanline_intensity = 0.3 时，暗线处亮度约为原图的 70%~100% 波动。
    color.rgb *= 1.0 - scanline_intensity * scanline;
    COLOR = color;
  }
}