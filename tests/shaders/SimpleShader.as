package shaders {
import com.adobe.utils.AGALMiniAssembler;

import flash.display3D.Context3DProgramType;

import flash.utils.ByteArray;

import org.flashgate.display.gpu.assembler.GpuAssembler;
import org.flashgate.display.gpu.assembler.GpuRegister;

public class SimpleShader extends GpuAssembler {

    public function get vertexProgramTest():ByteArray {
        return new AGALMiniAssembler().assemble(
                Context3DProgramType.VERTEX, [
                    "mov v, va1",
                    "div op, va, vc"
                ].join("\n")
        );
    }

    override protected function vertex(va:GpuRegister, vc:GpuRegister, vt:GpuRegister, v:GpuRegister, op:GpuRegister):void {
        mov(v, va[1]);
        div(op, va, vc);
    }

    public function get fragmentProgramTest():ByteArray {
        return new AGALMiniAssembler().assemble(
                Context3DProgramType.FRAGMENT, [
                    "tex oc, v, fs <linear>"
                ].join("\n")
        );
    }

    override protected function fragment(v:GpuRegister, fc:GpuRegister, ft:GpuRegister, fs:GpuRegister, od:GpuRegister, oc:GpuRegister):void {
        tex(oc, v, fs, LINEAR);
    }
}
}