package;

import assimp.AiFace;
import assimp.AiMaterial;
import assimp.AiMesh;
import assimp.AiNode;
import assimp.AiPostProcess;
import assimp.AiScene;
import assimp.AiString;
import assimp.AiTextureType;
import assimp.AssimpImporter;
import assimp.math.AiMatrix4x4;
import assimp.math.AiQuaternion;
import assimp.math.AiVector3D;
import cpp.ArrayBase;
import cpp.Pointer;
import cpp.Reference;
import cpp.Star;
import cpp.Struct;
import haxe.ds.StringMap;
import haxe.io.Path;
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
    private var textures:StringMap<Image>;
    public function new() 
    {
        Assets.loadEverything(loadingComplete);
    }
    
    public function loadingComplete():Void
    {
        importer = new AssimpImporter();
        //scene = importer.readFileFromMemory(Assets.blobs.SponzaNoFlag_obj.toBytes(), AiPostProcess.triangulate | AiPostProcess.flipUVs);
        scene = importer.readFileFromMemory(Assets.blobs.char_fbx.toBytes(), AiPostProcess.triangulate | AiPostProcess.flipUVs);
        
        if (scene == null || scene.ptr.flags == AiScene.AI_SCENE_FLAGS_INCOMPLETE || scene.ptr.rootNode == null) {
            trace("Assimp scene loding failded.");
        } else {
            trace("Loding complete.");
            
            effect = new Effect();
            meshes = new Array<Mesh>();
            textures = new StringMap<Image>();
            
            projectionMatrix = FastMatrix4.perspectiveProjection(45 * Math.PI / 180, Main.WIDTH / Main.HEIGHT, 0.1, 10000);
            viewMatrix = FastMatrix4.lookAt(new FastVector3(800, 700, 800), new FastVector3(0, 400, 0), new FastVector3(0, 1, 0));
            
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
        
        var mesh:Mesh = new Mesh(data, indices, effect.structure, transformation);
        meshes.push(mesh);
        
        if (scene.ptr.hasMaterials()) {
            if (aiMesh.ptr.materialIndex >= 0) {
                var aiMaterial:Pointer<AiMaterial> = scene.ptr.materials[aiMesh.ptr.materialIndex];
                var count:Int =  aiMaterial.ptr.getTextureCount(AiTextureType.aiTextureType_DIFFUSE);
                for (l in 0...count) {
                    var path:Pointer<AiString> = AiString.create();
                    aiMaterial.ptr.getTexture(AiTextureType.aiTextureType_DIFFUSE, l, path.ptr);
                    var texturePath:String = path.ptr.c_str().toString();
                    var textureName:String = Path.withoutDirectory(texturePath);
                    
                    mesh.textureName = textureName;
                    
                    if (!textures.exists(textureName)) {
                        var withoutExtension:String = textureName.substring(0, textureName.lastIndexOf("."));
                        textures.set(textureName, Reflect.field(Assets.images, withoutExtension));
                    }
                    
                    path.destroy();
                    path = null;
                }
            }
        } else {
            trace("There is no materials in current scene");
        }
    }

    public function render(framebuffer: Framebuffer): Void 
    {
        var g4:Graphics = backbuffer.g4;
        g4.begin();
        g4.clear(Color.Black, Math.POSITIVE_INFINITY);
        g4.setPipeline(effect.pipeline);
        g4.setMatrix(effect.viewMatrixID, viewMatrix);
        g4.setMatrix(effect.projectionMatrixID, projectionMatrix);
        
        for (mesh in meshes) {
            if (textures.exists(mesh.textureName)) {
                g4.setTexture(effect.textureID, textures.get(mesh.textureName));
            }
            g4.setMatrix(effect.modelMatrixID, FastMatrix4.rotationY(Scheduler.time() * 0.5).multmat(mesh.transformMatrix));
            
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
