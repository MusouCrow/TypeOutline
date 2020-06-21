using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderToTexture : ScriptableRendererFeature {
    [System.Serializable]
    public class Settings {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingPrePasses;
        public RenderQueueRange range = RenderQueueRange.opaque;
        public LayerMask layerMask = -1;
        public Material material;
        public string passName;
        public string cmdName;
        public string textureName;
    }
    
    public Settings settings = new Settings();

    private RenderToTexturePass pass;
    private RenderTargetHandle destination;

    public override void Create() {
        var s = this.settings;
        this.pass = new RenderToTexturePass(s.range, s.layerMask, s.material, s.passName, s.cmdName, s.textureName);
        this.pass.renderPassEvent = s.Event;

        this.destination.Init(s.textureName);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        this.pass.Setup(this.destination);
        renderer.EnqueuePass(this.pass);
    }
}