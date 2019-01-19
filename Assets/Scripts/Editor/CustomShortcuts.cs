using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering.LightweightPipeline;
using UnityEngine.Rendering;

public static class CustomShortcuts
{
    private const string legacyShaderPath = "Assets/Shaders/LegacyLitVertexColor.shader";
    private const string lwrpShaderPath = "Assets/Shaders/LWRPLitVertexColor.shader";

    private const string builtInRpText = "Built-In RP";
    private const string lwrpText = "LWRP";

    private static void SwitchToBuiltInRenderer()
    {
        GraphicsSettings.renderPipelineAsset = null;
        GraphicsSettings.lightsUseLinearIntensity = false;
        ChangeShaderOnMaterial(legacyShaderPath);
        ChangeText(builtInRpText);
    }
    
    private static void SwitchToLWRP()
    {
        GraphicsSettings.renderPipelineAsset = AssetDatabase.LoadAssetAtPath<LightweightRenderPipelineAsset>("Assets/LightweightRenderPipelineAsset.asset");
        GraphicsSettings.lightsUseLinearIntensity = true;
        ChangeShaderOnMaterial(lwrpShaderPath);
        ChangeText(lwrpText);
    }

    private static void ChangeText(string text)
    {
        GameObject.Find("Canvas/Text")?.GetComponent<TextMeshProUGUI>().SetText(text);
    }

    private static void ChangeShaderOnMaterial(string shaderPath)
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/VertexColor.mat");
        if (mat)
        {
            mat.shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);
        }
    }

    [MenuItem("Tools/Switch Render Pipeline &s")]
    private static void SwitchRenderPipeline()
    {
        if (GraphicsSettings.renderPipelineAsset == null)
        {
            SwitchToLWRP();
        }
        else
        {
            SwitchToBuiltInRenderer();
        }
    }
}
