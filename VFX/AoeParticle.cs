using Godot;

/// <summary>带延时的粒子：延时直接配在这个粒子节点上。</summary>
[GlobalClass]
[Tool]
public partial class AoeParticle : GpuParticles3D
{
    [Export] public float Delay { get; set; }
}
