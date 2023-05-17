using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class CreateURPShader 
{
    const string URPShaderTempPath = "Assets/Editor/Tools/URPShaderTemp.shader";
    [MenuItem("Assets/创建URPShader模版")]
    public static void CreateURPShaderTemp()
    {
        string newfileName = "NewURPShader.shader";
        string curPath = AssetDatabase.GetAssetPath(Selection.activeObject);
       
        if (File.Exists($"{AssetDatabase.GetAssetPath(Selection.activeObject)}/{newfileName}"))
        {
            newfileName = $"{GUID.Generate()}NewURPShader.shader";
        }
        string createPath = $"{AssetDatabase.GetAssetPath(Selection.activeObject)}/{newfileName}";
        AssetDatabase.CopyAsset(URPShaderTempPath, createPath);
    }
}
