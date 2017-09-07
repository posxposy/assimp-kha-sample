package;

import assimp.AiFace;
import assimp.AiMesh;
import assimp.AiNode;
import assimp.AiPostProcess;
import assimp.AiScene;
import assimp.AssimpImporter;
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
    private var scene:AiScene;
    
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
        
        if (scene == null || scene.flags == AiScene.AI_SCENE_FLAGS_INCOMPLETE || scene.rootNode == null) {
            trace("Assimp scene loding failded.");
        } else {
            trace("Loding complete.");
            
            effect = new Effect();
            meshes = new Array<Mesh>();
            diffuseImage = Assets.images.diffuse;
            
            projectionMatrix = FastMatrix4.perspectiveProjection(45 * Math.PI / 180, Main.WIDTH / Main.HEIGHT, 0.1, 1000);
            viewMatrix = FastMatrix4.lookAt(new FastVector3( -10, 10, -10), new FastVector3(0, 0, 0), new FastVector3(0, 1, 0));
            
            processNode(scene.rootNode);
            
            backbuffer = Image.createRenderTarget(Main.WIDTH, Main.HEIGHT, TextureFormat.RGBA32, DepthStencilFormat.DepthAutoStencilAuto);
            System.notifyOnRender(render);
        }
    }
    
    private function processNode(node:AiNode):Void
    {
        /*for (i in 0...node.numMeshes) {
            var meshIndex:Int = node.meshes[i];
            processMesh(node, scene.meshes[meshIndex], i);
        }
        for (i in 0...node.numChildren) {
            processNode(node.children[i]);
        }*/
        
        for (i in 0...node.numMeshes) {
            processMesh(node, untyped __cpp__("scene->ptr->mMeshes[node->ptr->mMeshes[i]]"), i);
        }
        for (j in 0...node.numChildren) {
            processNode( untyped __cpp__("node->ptr->mChildren[j]") );
        }
    }
    
    private function processMesh(node:AiNode, aiMesh:AiMesh, index:Int):Void
    {
        var transformation:FastMatrix4 = FastMatrix4.identity();
        
        var data:Array<Float> = new Array<Float>();
        var indices:Array<Int> = new Array<Int>();
        
        for (i in 0...aiMesh.numVertices) {
            data.push(aiMesh.vertices[i].x);
            data.push(aiMesh.vertices[i].y);
            data.push(aiMesh.vertices[i].z);
            
            var u:Float = 0;
            var v:Float = 0;
            if ( untyped __cpp__("aiMesh->ptr->mTextureCoords[0]") ) {
                u = untyped __cpp__("aiMesh->ptr->mTextureCoords[0][i].x");
                v = untyped __cpp__("aiMesh->ptr->mTextureCoords[0][i].y");
            }
            
            data.push(u);
            data.push(v);
        }
        
        for (j in 0...aiMesh.numFaces) {
            var aiFace:AiFace = untyped __cpp__ ("aiMesh->ptr->mFaces[j]");
            for (k in 0...aiFace.numIndices) {
                var index:Int = untyped __cpp__ ("aiFace.mIndices[k]");
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
