package;

import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexElement;
import kha.graphics4.VertexStructure;
import kha.math.FastMatrix4;

/**
 * ...
 * @author Dmitry Hryppa	http://themozokteam.com/
 */
class Mesh 
{
    public var name(default, null):String;
    public var vertexBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;
    
    public var transformMatrix:FastMatrix4;
    public var textureName:String = "";
    public function new(data:Array<Float>, indices:Array<Int>, vertexStructure:VertexStructure, transformMatrix:FastMatrix4)
    {
        this.transformMatrix = transformMatrix;
        
        var structureLength:Int = 0;
        for (i in 0...vertexStructure.elements.length) {
            var vertexElement:VertexElement = vertexStructure.get(i);
            switch(vertexElement.data) { 
                case VertexData.Float1: 
                    structureLength += 1;
                case VertexData.Float2:
                    structureLength += 2;
                case VertexData.Float3:
                    structureLength += 3;
                case VertexData.Float4:
                    structureLength += 4;
                case VertexData.Float4x4:
                    structureLength += 64;
            }
        }
        
        vertexBuffer = new VertexBuffer(Std.int(data.length / structureLength), vertexStructure, Usage.StaticUsage);
        var vbData:Float32Array = vertexBuffer.lock();
        for (i in 0...vbData.length) {
            vbData.set(i, data[i]);
        }
        vertexBuffer.unlock();

        indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);
        var iData:Uint32Array = indexBuffer.lock();
        for (i in 0...iData.length) {
            iData.set(i, indices[i]);
        }
        indexBuffer.unlock();
    }
    
}