shader_type spatial;
// 属于 spatial 类型，用于 3D 物体的材质渲染，
// 核心效果是给漫反射光照添加“色阶”（banding）量化，实现类似卡通或低多边形风格的着色。
uniform vec3 base_color : source_color = vec3(0.8, 0.4, 0.4);
uniform int bands : hint_range(2, 8) = 3;
 
void fragment() {
  // 物体表面固有色
  ALBEDO = base_color;
}
// Godot 中专门用于处理每个光源光照贡献的函数。对于每个光源，此函数会被调用一次，并累计到内置变量（如 DIFFUSE_LIGHT）中
void light() {
  // dot(NORMAL, LIGHT)：计算表面法线 NORMAL 与光线方向 LIGHT 的点积，得到余弦值（范围 -1~1）。dot(a,b) = |a||b|cos(θ) -> 因为都是单位向量，所以就是cos(θ)。它给出了入射角。
  // max(..., 0.0)：将负值截断为 0，避免背面受光，得到漫反射强度因子。
  float n_dot_l = max(dot(NORMAL, LIGHT), 0.0);

  // n_dot_l * float(bands)：将连续强度值映射到 [0, bands] 区间。
  // floor(...)：向下取整，得到离散等级（0 到 bands-1）。
  // 再除以 float(bands)，将等级映射回 [0, 1) 区间，得到量化后的漫反射因子 quantized。
  // 例如，bands=3，原始 n_dot_l 为 0.4 → 0.4*3=1.2 → floor=1 → 1/3≈0.333，即强度被量化为三个离散档位（0, 1/3, 2/3）。
  float quantized = floor(n_dot_l * float(bands)) / float(bands);
  // 色阶化有多种处理手段，这里就比较简单


  // DIFFUSE_LIGHT：内置累积变量，代表当前像素接收到的漫反射光总量。
  // 累加 quantized * LIGHT_COLOR.rgb * ATTENUATION。
  //     LIGHT_COLOR.rgb：当前光源的颜色（RGB）。
  //     ATTENUATION：当前光源的衰减因子（由距离、阴影等决定）。
  // 最终像素的漫反射颜色 = ALBEDO * DIFFUSE_LIGHT（Godot 内部自动处理）。
  DIFFUSE_LIGHT += quantized * LIGHT_COLOR.rgb * ATTENUATION;
}