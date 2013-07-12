package {
import com.allurent.coverage.runtime.AbstractCoverageAgent;

import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.events.Event;

public class Example extends Sprite {
    private var _stage:Stage3D;
    private var _context:Context3D;
    private var _program:Program3D;
    private var _shader:ExampleShader;
    private var _vertex:VertexBuffer3D;
    private var _index:IndexBuffer3D;

    public function Example() {
        _stage = stage.stage3Ds[0];
        _stage.addEventListener(Event.CONTEXT3D_CREATE, onContext);
        _stage.requestContext3D();
    }

    private function onContext(event:Event):void {
        var width:int = stage.stageWidth;
        var height:int = stage.stageHeight;

        _context = _stage.context3D;
        _context.enableErrorChecking = true;

        trace("Driver Info: " + _context.driverInfo);
        trace("Back buffer: " + width + "x" + height);

        _context.configureBackBuffer(width, height, 0);
        _context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, new <Number>[width / 2, height / 2, 1, 1]);

        _shader = new ExampleShader();
        _program = _context.createProgram();
        _program.upload(_shader.vertexProgram, _shader.fragmentProgram);
        _context.setProgram(_program);

        _vertex = _context.createVertexBuffer(3, 6);
        _vertex.uploadFromVector(new <Number>[
            0, 100, 0, 0, 1, 0,
            0, 0, 0, 1, 1, 1,
            100, 0, 0, 1, 0, 0
        ], 0, 3);

        _context.setVertexBufferAt(0, _vertex, 0, Context3DVertexBufferFormat.FLOAT_3);
        _context.setVertexBufferAt(1, _vertex, 3, Context3DVertexBufferFormat.FLOAT_3);

        _index = _context.createIndexBuffer(3);
        _index.uploadFromVector(new <uint>[0, 1, 2], 0, 3);

        _context.clear();
        _context.drawTriangles(_index);
        _context.present();
    }
}
}

