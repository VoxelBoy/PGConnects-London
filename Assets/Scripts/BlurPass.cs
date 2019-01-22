using UnityEngine;
using UnityEngine.Experimental.Rendering.LWRP;
using UnityEngine.Rendering;
using UnityEngine.Rendering.LWRP;

public class BlurPass : MonoBehaviour, IAfterTransparentPass
{
    private BlurPassImpl blurPass;

    [SerializeField]
    private Color tintColor;
    
    [SerializeField]
    private float blurSize;
    
    [SerializeField]
    private float blurSigma;

    /// <summary>
    /// DO NOT REMOVE.
    /// Without the Start method, the Inspector won't show the enabled/disabled checkbox for this component.
    /// </summary>
    private void Start()
    {
        
    }

    public ScriptableRenderPass GetPassToEnqueue(RenderTextureDescriptor baseDescriptor, RenderTargetHandle colorHandle, RenderTargetHandle depthHandle)
    {
        if (blurPass == null)
        {
            blurPass = new BlurPassImpl(colorHandle, tintColor, blurSize, blurSigma);
        }

        blurPass.SetState(enabled, tintColor, blurSize, blurSigma);
            
        return blurPass;
    }
}

public class BlurPassImpl : ScriptableRenderPass
{
    const string k_RenderGrabPassTag = "BlurPass";

    private RenderTargetHandle m_ColorHandle;

    private readonly Material m_Material;
    private int screenCopyID;
    
    private bool enabled;
    private Color tintColor;
    private float blurSize;
    private float blurSigma;

    public BlurPassImpl(RenderTargetHandle colorHandle, Color tintColor, float blurSize, float blurSigma)
    {
        this.blurSigma = blurSigma;
        this.blurSize = blurSize;
        this.tintColor = tintColor;
        m_ColorHandle = colorHandle;

        m_Material = CoreUtils.CreateEngineMaterial(Shader.Find("_PGC/LWRP/Blur"));
        m_Material.SetColor("_Color", tintColor);
        m_Material.SetFloat("_Size", blurSize);
        m_Material.SetFloat("_Sigma", blurSigma);
    }

    public override void Execute(ScriptableRenderer renderer, ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (enabled == false)
        {
            return;
        }
        
        #if UNITY_EDITOR
        m_Material.SetColor("_Color", tintColor);
        m_Material.SetFloat("_Size", blurSize);
        m_Material.SetFloat("_Sigma", blurSigma);
        #endif
        
        CommandBuffer cmd = CommandBufferPool.Get(k_RenderGrabPassTag);

        using (new ProfilingSample(cmd, k_RenderGrabPassTag))
        {
            // copy screen into temporary RT
            screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
            RenderTextureDescriptor opaqueDesc = ScriptableRenderer.CreateRenderTextureDescriptor(ref renderingData.cameraData);
            
            cmd.GetTemporaryRT(screenCopyID, opaqueDesc, FilterMode.Bilinear);
            cmd.Blit(m_ColorHandle.Identifier(), screenCopyID);

            cmd.SetGlobalVector("offsets", new Vector4(2.0f / Screen.width, 0, 0, 0));
            cmd.Blit(screenCopyID, m_ColorHandle.Identifier(), m_Material);
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        cmd?.ReleaseTemporaryRT(screenCopyID);
    }

    public void SetState(bool enabled, Color tintColor, float blurSize, float blurSigma)
    {
        this.enabled = enabled;
        this.blurSigma = blurSigma;
        this.blurSize = blurSize;
        this.tintColor = tintColor;
    }
}