using Godot;
using System;

public partial class PanelTest : Control
{
    public override void _Ready()
    {
        base._Ready();
        var p = GetNode<Panel>("%Panel");
        var theme = p.GetThemeStylebox("panel") as StyleBoxFlat; // 需要转换一下类型
        GD.Print("theme: ", theme);

    }
}

