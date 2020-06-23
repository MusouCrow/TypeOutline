using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderToTexture : ScriptableRendererFeature {
    [System.Serializable]
    public class Settings {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingPrePasses;
        public LayerMask layerMask = -1;
        public Material material;
        public string passName;
        public string cmdName;
        public string textureName;
        public Color clearColor = Color.black;
    }
    
    public Settings settings = new Settings();

    private RenderToTexturePass pass;
    private RenderTargetHandle destination;

    public override void Create() {
        this.pass = new RenderToTexturePass(this.settings);
        this.pass.renderPassEvent = this.settings.Event;

        this.destination.Init(this.settings.textureName);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        this.pass.Setup(this.destination);
        renderer.EnqueuePass(this.pass);
    }
}