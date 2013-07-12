package shaders {
import com.adobe.utils.AGALMiniAssembler;

import flash.display3D.Context3DProgramType;

import flash.utils.ByteArray;

import org.flashgate.display.gpu.assembler.GpuAssembler;
import org.flashgate.display.gpu.assembler.GpuRegister;

public class FractalShader extends GpuAssembler {

    public function get vertexProgramTest():ByteArray {
        return new AGALMiniAssembler().assemble(
                Context3DProgramType.VERTEX, [
                    "dp4 op.x, va0, vc0",
                    "dp4 op.y, va0, vc1",
                    "dp4 op.z, va0, vc2",
                    "dp4 op.w, va0, vc3"
                ].join("\n")
        );
    }

    override protected function vertex(va:GpuRegister, vc:GpuRegister, vt:GpuRegister, v:GpuRegister, op:GpuRegister):void {
        dp4(op.x, va, vc[0]);
        dp4(op.y, va, vc[1]);
        dp4(op.z, va, vc[2]);
        dp4(op.w, va, vc[3]);
    }

    public function get fragmentProgramTest():ByteArray {
        return new AGALMiniAssembler().assemble(
                Context3DProgramType.FRAGMENT, [
                    "mov oc, fc0"
                ].join("\n")
        );
    }

    override protected function fragment(v:GpuRegister, fc:GpuRegister, ft:GpuRegister, fs:GpuRegister, od:GpuRegister, oc:GpuRegister):void {
        mov(oc, fc);
    }
}
}
