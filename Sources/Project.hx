package;

import assimp.AiFace;
import assimp.AiMesh;
import assimp.AiNode;
import assimp.AiPostProcess;
import assimp.AiScene;
import assimp.AssimpImporter;
import assimp.math.AiMatrix4x4;
import assimp.math.AiQuaternion;
import assimp.math.AiVector3D;
import cpp.Pointer;
import cpp.Star;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.Scheduler;
import kha.System;
import kha.graphics4.DepthStencilFormat;
import kha.graphics4.Graphics;
import kha.graphics4.TextureFormat;
import kha.math.FastMatrix4;
import kha.math.FastVector3;

class Project 
{
    private var importer:AssimpImporter;
    private var scene:Pointer<AiScene>;
    
    private var backbuffer:Image;
    private var effect:Effect;
    private var projectionMatrix:FastMatrix4;
    private var viewMatrix:FastMatrix4;
    
    private var meshes:Array<Mesh>;
    private var diffuseImage:Image;
    public function new() 
    {
        Assets.loadEverything(loadingComplete);
    }
    
    public function loadingComplete():Void
    {
        importer = new AssimpImporter();
        scene = importer.readFileFromMemory(Assets.blobs.char_fbx.toBytes(), AiPostProcess.triangulate | AiPostProcess.flipUVs);
        
        if (scene == null || scene.ptr.flags == AiScene.AI_SCENE_FLAGS_INCOMPLETE || scene.ptr.rootNode == null) {
            trace("Assimp scene loding failded.");
        } else {
            trace("Loding complete.");
            
            effect = new Effect();
            meshes = new Array<Mesh>();
            diffuseImage = Assets.images.diffuse;
            
            projectionMatrix = FastMatrix4.perspectiveProjection(45 * Math.PI / 180, Main.WIDTH / Main.HEIGHT, 0.1, 2000);
            viewMatrix = FastMatrix4.lookAt(new FastVector3( 800, 700, 800), new FastVector3(0, 400, 0), new FastVector3(0, 1, 0));
            
            processNode(scene.ptr.rootNode);
            
            backbuffer = Image.createRenderTarget(Main.WIDTH, Main.HEIGHT, TextureFormat.RGBA32, DepthStencilFormat.DepthAutoStencilAuto);
            System.notifyOnRender(render);
        }
    }
    
    private function processNode(node:Pointer<AiNode>):Void
    {
        for (i in 0...node.ptr.numMeshes) {
            var meshIndex:Int = node.ptr.meshes[i];
            processMesh(node, scene.ptr.meshes[meshIndex], i);
        }
        
        for (i in 0...node.ptr.numChildren) {
            processNode(node.ptr.children[i]);
        }
    }
    
    private function processMesh(node:Pointer<AiNode>, aiMesh:Pointer<AiMesh>, index:Int):Void
    {
        var transformation:FastMatrix4 = new FastMatrix4(
                node.ptr.transformation.a1, node.ptr.transformation.a2, node.ptr.transformation.a3, node.ptr.transformation.a4,
                node.ptr.transformation.b1, node.ptr.transformation.b2, node.ptr.transformation.b3, node.ptr.transformation.b4,
                node.ptr.transformation.c1, node.ptr.transformation.c2, node.ptr.transformation.c3, node.ptr.transformation.c4,
                node.ptr.transformation.d1, node.ptr.transformation.d2, node.ptr.transformation.d3, node.ptr.transformation.d4);
        
        var data:Array<Float> = new Array<Float>();
        var indices:Array<Int> = new Array<Int>();
        
        for (i in 0...aiMesh.ptr.numVertices) {
            data.push(aiMesh.ptr.vertices[i].x);
            data.push(aiMesh.ptr.vertices[i].y);
            data.push(aiMesh.ptr.vertices[i].z);
            
            var u:Float = 0;
            var v:Float = 0;
            if (aiMesh.ptr.textureCoords[0] != null) {
                u = aiMesh.ptr.textureCoords[0][i].x;
                v = aiMesh.ptr.textureCoords[0][i].y;
            }
            
            data.push(u);
            data.push(v);
        }
        
        for (i in 0...aiMesh.ptr.numFaces) {
            var aiFace:AiFace = aiMesh.ptr.faces[i];
            for (j in 0...aiFace.numIndices) {
                var index:Int = aiFace.indices[j];
                indices.push(index);
            }
        }
        
        meshes.push(new Mesh(data, indices, effect.structure, transformation));
    }

    public function render(framebuffer: Framebuffer): Void 
    {
        var g4:Graphics = backbuffer.g4;
        g4.begin();
        g4.clear(Color.Black, Math.POSITIVE_INFINITY);
        g4.setPipeline(effect.pipeline);
        g4.setMatrix(effect.viewMatrixID, viewMatrix);
        g4.setMatrix(effect.projectionMatrixID, projectionMatrix);
        
        
        g4.setTexture(effect.textureID, diffuseImage);
        for (mesh in meshes) {
            g4.setMatrix(effect.modelMatrixID, mesh.transformMatrix);
            
            g4.setIndexBuffer(mesh.indexBuffer);
            g4.setVertexBuffer(mesh.vertexBuffer);
            g4.drawIndexedVertices();
        }
        g4.end();
        
        
        framebuffer.g2.begin();
#if kha_opengl
        framebuffer.g2.drawScaledImage(backbuffer, 0, Main.HEIGHT, Main.WIDTH, -Main.HEIGHT);
#elseif
        framebuffer.g2.drawImage(backbuffer, 0, 0);
#end
        framebuffer.g2.end();
    }
}
