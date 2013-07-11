package org.flashgate.display.gpu.assembler {
import flash.utils.Proxy;
import flash.utils.flash_proxy;

/**
 * GPU Register
 */
dynamic public class GpuRegister extends Proxy {

    public var shader:int;
    public var type:int;
    public var index:int;
    public var field:String;

    public function GpuRegister(shader:int, type:int, index:int = 0, field:String = null) {
        super();
        this.shader = shader;
        this.type = type;
        this.index = index;
        this.field = field;
    }

    override flash_proxy function getProperty(name:*):* {
        return isNaN(name) ? new GpuRegister(shader, type, index, name) : new GpuRegister(shader, type, int(name));
    }
}
}