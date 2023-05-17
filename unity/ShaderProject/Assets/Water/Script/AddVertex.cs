using UnityEngine;

public class AddVertex : MonoBehaviour
{
    public int widthSegments = 1;
    public int lengthSegments = 1;

    void Start()
    {
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        if (meshFilter == null)
        {
            Debug.LogError("MeshFilter not found!");
            return;
        }

        Mesh mesh = meshFilter.mesh;
        if (mesh == null)
        {
            mesh = new Mesh();
            meshFilter.mesh = mesh;
        }

        Vector3[] vertices = mesh.vertices;
        int[] triangles = mesh.triangles;

        int numVertices = (widthSegments + 1) * (lengthSegments + 1);
        int numTriangles = widthSegments * lengthSegments * 6;

        Vector3[] newVertices = new Vector3[numVertices];
        int[] newTriangles = new int[numTriangles];

        int index = 0;
        for (int i = 0; i <= lengthSegments; i++)
        {
            for (int j = 0; j <= widthSegments; j++)
            {
                float x = (float)j / widthSegments;
                float z = (float)i / lengthSegments;
                newVertices[index++] = new Vector3(x, 0, z);
            }
        }

        index = 0;
        for (int i = 0; i < lengthSegments; i++)
        {
            for (int j = 0; j < widthSegments; j++)
            {
                int a = i * (widthSegments + 1) + j;
                int b = a + 1;
                int c = (i + 1) * (widthSegments + 1) + j;
                int d = c + 1;
                newTriangles[index++] = a;
                newTriangles[index++] = c;
                newTriangles[index++] = b;
                newTriangles[index++] = b;
                newTriangles[index++] = c;
                newTriangles[index++] = d;
            }
        }

        mesh.vertices = newVertices;
        mesh.triangles = newTriangles;
        mesh.RecalculateNormals();
    }
}