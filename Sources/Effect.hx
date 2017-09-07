package;
import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.CompareMode;
import kha.graphics4.ConstantLocation;
import kha.graphics4.CullMode;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureUnit;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;

/**
 * ...
 * @author Dmitry Hryppa	http://themozokteam.com/
 */
class Effect 
{
    public var structure(default, null):VertexStructure;
    public var pipeline(default, null):PipelineState;
    public var modelMatrixID(default, null):ConstantLocation;
    public var viewMatrixID(default, null):ConstantLocation;
    public var projectionMatrixID(default, null):ConstantLocation;
    public var textureID(default, null):TextureUnit;
    
    public function new() 
    {
        structure = new VertexStructure();
        structure.add("vertexPosition", VertexData.Float3);
        structure.add("textureCoords", VertexData.Float2);
        
        pipeline = new PipelineState();
        pipeline.inputLayout = [structure];
        pipeline.vertexShader = Shaders.default_mesh_vert;
        pipeline.fragmentShader = Shaders.default_mesh_frag;
        pipeline.depthWrite = true;
        pipeline.depthMode = CompareMode.Less;
        pipeline.cullMode = CullMode.Clockwise;
        pipeline.blendSource = BlendingFactor.BlendOne;
        pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.alphaBlendSource = BlendingFactor.SourceAlpha;
        pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.compile();
        
        projectionMatrixID = pipeline.getConstantLocation("projectionMatrix");
        modelMatrixID = pipeline.getConstantLocation("modelMatrix");
        viewMatrixID = pipeline.getConstantLocation("viewMatrix");
        
        textureID = pipeline.getTextureUnit("mainTexture");
    }
}