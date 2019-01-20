using TMPro;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.LWRP;
using UnityEngine.SceneManagement;

public static class CustomShortcuts
{
    private const string legacyShaderPath = "Assets/Shaders/LegacyLitVertexColor.shader";
    private const string lwrpShaderPath = "Assets/Shaders/LWRPLitVertexColor.shader";

    private const string builtInRpText = "Built-In RP";
    private const string lwrpText = "LWRP";

    private static void SwitchToBuiltInRenderer()
    {
        GraphicsSettings.renderPipelineAsset = null;
        ChangeShaderOnMaterial(legacyShaderPath);
        ChangeText(builtInRpText);
    }
    
    private static void SwitchToLWRP()
    {
        GraphicsSettings.renderPipelineAsset = AssetDatabase.LoadAssetAtPath<LightweightRenderPipelineAsset>("Assets/LightweightRenderPipelineAsset.asset");
        ChangeShaderOnMaterial(lwrpShaderPath);
        ChangeText(lwrpText);
    }

    private static void ChangeText(string text)
    {
        var go = GameObject.Find("Canvas/Text");
        go.GetComponent<TextMeshProUGUI>().SetText(text);
        EditorUtility.SetDirty(go);
        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
    }

    private static void ChangeShaderOnMaterial(string shaderPath)
    {
        var mat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/VertexColor.mat");
        mat.shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);
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
    
    [MenuItem("Tools/Toggle SRP Batcher &b")]
    private static void ToggleSRPBatcher()
    {
        var lwrpAsset = AssetDatabase.LoadAssetAtPath<LightweightRenderPipelineAsset>("Assets/LightweightRenderPipelineAsset.asset");
        var so = new SerializedObject(lwrpAsset);
        so.Update();
        var prop = so.FindProperty("m_UseSRPBatcher");
        prop.boolValue = !prop.boolValue;
        so.ApplyModifiedProperties();
        
        var go = GameObject.Find("Canvas/BatchText");
        go.GetComponent<TextMeshProUGUI>().enabled = prop.boolValue;
        EditorUtility.SetDirty(go);
        EditorSceneManager.MarkSceneDirty(SceneManager.GetActiveScene());
    }
}
