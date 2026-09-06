using Godot;
using System.Collections.Generic;
using System.Linq;

// [Tool] 让脚本在编辑器里也能运行，配合下面的按钮即可在编辑器视口中预览
[Tool]
public partial class Aoe01 : Node3D {
    [Export] public bool PlayOnReady { get; set; } = true;

    [Export] public bool Loop { get; set; } = false;

    [Export] public float LoopInterval { get; set; } = 0.2f;

    // 粒子容器：留空则从自身开始找
    [Export] public Node ParticlesRoot { get; set; }

    private readonly List<Item> _items = new();
    private int _index;
    private float _time;
    private bool _playing;
    private int _playId;

    // 编辑器里不会自动打开 _Process，必须手动打开
    public override void _EnterTree() {
        SetProcess(true);
    }

    public override void _Ready() {
        SetProcess(true);
        Stop();
        if (PlayOnReady) {
            Play();
        }
    }

    public override void _Process(double delta) {
        if (!_playing) {
            return;
        }

        _time += (float)delta;

        while (_index < _items.Count && _items[_index].Delay <= _time) {
            StartItem(_items[_index]);
            _index++;
        }

        if (_index >= _items.Count) {
            _playing = false;
        }
    }

    [ExportToolButton("预览播放")]
    public Callable PreviewPlayButton => Callable.From(Play);

    [ExportToolButton("停止")]
    public Callable PreviewStopButton => Callable.From(Stop);

    /// <summary>按各自延时依次播放粒子，可重复调用，新的播放会打断旧的。</summary>
    public void Play() {
        int id = ++_playId;

        BuildQueue();

        _index = 0;
        _time = 0.0f;
        _playing = true;

        // 延时为 0 的立即开始
        while (_index < _items.Count && _items[_index].Delay <= 0.0f) {
            StartItem(_items[_index]);
            _index++;
        }

        // 定时器兜底：即使 _Process 没跑（例如编辑器里）也能按延时播放并循环
        PlayByTimer(id);
    }

    /// <summary>停止并重置所有粒子。</summary>
    public void Stop() {
        _playId++;

        BuildQueue();

        _playing = false;

        foreach (Item item in _items) {
            item.Started = false;

            if (!IsInstanceValid(item.Particle)) {
                continue;
            }

            item.Particle.Emitting = false;
            item.Particle.Restart();
        }
    }

    private async void PlayByTimer(int id) {
        Item[] items = _items.ToArray();

        foreach (Item item in items) {
            if (item.Delay <= 0.0f) {
                continue;
            }

            await ToSignal(GetTree().CreateTimer(item.Delay), SceneTreeTimer.SignalName.Timeout);

            if (id != _playId || !IsInstanceValid(this)) {
                return;
            }

            StartItem(item);
        }

        if (Loop) {
            await ToSignal(GetTree().CreateTimer(Mathf.Max(LoopInterval, 0.0f)), SceneTreeTimer.SignalName.Timeout);

            if (id != _playId || !IsInstanceValid(this)) {
                return;
            }

            Play();
        }
    }

    private void StartItem(Item item) {
        if (item.Started || !IsInstanceValid(item.Particle)) {
            return;
        }

        item.Started = true;
        item.Particle.Restart();
        item.Particle.Emitting = true;
    }

    // 从 ParticlesRoot（或自身）收集子节点上的（粒子, 延时）并按延时升序排序
    private void BuildQueue() {
        _items.Clear();

        Node root = (ParticlesRoot != null && IsInstanceValid(ParticlesRoot)) ? ParticlesRoot : this;
        CollectChildren(root);

        if (_items.Count > 1) {
            _items.Sort((a, b) => a.Delay.CompareTo(b.Delay));
        }
    }

    private void CollectChildren(Node parent) {
        foreach (Node child in parent.GetChildren()) {
            if (child is AoeParticle ap) {
                _items.Add(new Item { Particle = ap, Delay = Mathf.Max(ap.Delay, 0.0f) });
            }
            else if (child is GpuParticles3D p) {
                _items.Add(new Item { Particle = p, Delay = 0.0f });
            }

            CollectChildren(child);
        }
    }

    private class Item {
        public GpuParticles3D Particle;
        public float Delay;
        public bool Started;
    }
}
