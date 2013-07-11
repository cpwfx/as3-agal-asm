package org.flashgate.display.gpu.assembler {
import flash.errors.IllegalOperationError;
import flash.utils.ByteArray;
import flash.utils.Endian;

/**
 * ActionScript pseudo program to AGAL assembler bytecode generator
 *
 * @see http://help.adobe.com/en_US/as3/dev/WSd6a006f2eb1dc31e-310b95831324724ec56-8000.html AGAL bytecode format
 */
public class GpuAssembler {

    // Sampler
    public static const RGBA:int = 0 << 8;
    public static const DXT1:int = 1 << 8;
    public static const DXT5:int = 2 << 8;
    public static const VIDEO:int = 3 << 8;

    // Sampler Type
    public static const D2:int = 0 << 12;
    public static const CUBE:int = 1 << 12;
    public static const D3:int = 2 << 12;

    // Sampler Flags
    public static const CENTROID:int = 1 << 16;
    public static const SINGLE:int = 2 << 16;
    public static const IGNORESAMPLER:int = 4 << 16;

    // Sampler Wrap
    public static const CLAMP:int = 0 << 20;
    public static const WRAP:int = 1 << 20;

    // Sampler MipMap
    public static const MIPNONE:int = 0 << 24;
    public static const MIPNEAREST:int = 1 << 24;
    public static const MIPLINEAR:int = 2 << 24;

    // Sampler Filter
    public static const NEAREST:int = 0;
    public static const LINEAR:int = 1 << 28;

    // Constants
    private static const VERTEX:int = 0x00;
    private static const FRAGMENT:int = 0x01;
    private static const ATTRIBUTE:int = 0x00;
    private static const CONSTANT:int = 0x01;
    private static const TEMPORARY:int = 0x02;
    private static const OUTPUT:int = 0x03;
    private static const VARYING:int = 0x04;
    private static const SAMPLER:int = 0x05;
    private static const DEPTH:int = 0x05;

    // Private
    private var _bytes:ByteArray;
    private var _type:int;
    private var _version:int = 1;

    public function GpuAssembler() {
        super();
    }

    /**
     * Vertex Shader Program Bytecode
     */
    public function get vertexProgram():ByteArray {
        var va:GpuRegister = new GpuRegister(VERTEX, ATTRIBUTE);
        var vc:GpuRegister = new GpuRegister(VERTEX, CONSTANT);
        var vt:GpuRegister = new GpuRegister(VERTEX, TEMPORARY);
        var v:GpuRegister = new GpuRegister(VERTEX, VARYING);
        var op:GpuRegister = new GpuRegister(VERTEX, OUTPUT);

        header(VERTEX);
        vertex(va, vc, vt, v, op);
        return pack();
    }

    /**
     * Fragment Shader Program Bytecode
     */
    public function get fragmentProgram():ByteArray {
        var v:GpuRegister = new GpuRegister(VERTEX, VARYING);
        var fc:GpuRegister = new GpuRegister(FRAGMENT, CONSTANT);
        var ft:GpuRegister = new GpuRegister(FRAGMENT, TEMPORARY);
        var fs:GpuRegister = new GpuRegister(FRAGMENT, SAMPLER);
        var od:GpuRegister = new GpuRegister(FRAGMENT, DEPTH);
        var oc:GpuRegister = new GpuRegister(FRAGMENT, OUTPUT);

        header(FRAGMENT);
        fragment(v, fc, ft, fs, od, oc);
        return pack();
    }

    /**
     * Vertex Shader Program
     *
     * @param va    Attributes from Context3D::setVertexBufferAt()
     * @param vc    Constants from Context3D::setProgramConstants()
     * @param vt    Temporary register
     * @param v     Variables
     * @param op    Output position
     */
    protected function vertex(va:GpuRegister, vc:GpuRegister, vt:GpuRegister, v:GpuRegister, op:GpuRegister):void {
        mov(v, va[1]);
        div(op, va, vc);
    }

    /**
     * Fragment Shader Program
     *
     * @param v     Variables
     * @param fc    Constants from Context3D::setProgramConstants()
     * @param ft    Temporary register
     * @param fs    Sampler
     * @param od    Depth output
     * @param oc    Output color
     */
    protected function fragment(v:GpuRegister, fc:GpuRegister, ft:GpuRegister, fs:GpuRegister, od:GpuRegister, oc:GpuRegister):void {
        mov(oc, v);
    }

    private function header(type:int):void {
        _bytes = new ByteArray();
        _bytes.endian = Endian.LITTLE_ENDIAN;
        _bytes.writeByte(0xa0);
        _bytes.writeUnsignedInt(_version);
        _bytes.writeByte(0xa1);
        _bytes.writeByte(_type = type);
    }

    private function pack():ByteArray {
        var result:ByteArray = _bytes;
        _bytes.length = _bytes.position;
        _bytes = null;
        return result;
    }

    protected function opcode(code:int, dest:GpuRegister = null, a:GpuRegister = null, b:GpuRegister = null, sampler:uint = 0, bias:int = 0):void {
        var bytes:ByteArray = _bytes;
        bytes.writeUnsignedInt(code);

        if (dest) {
            bytes.writeShort(dest.index);
            bytes.writeByte(mask(dest.field));
            bytes.writeByte(dest.type);
        } else {
            bytes.writeUnsignedInt(0x00);
        }

        if (a) {
            push(a, bytes);
        }

        if (b) {
            if (b.type == SAMPLER) {
                bytes.writeShort(b.index);
                bytes.writeByte(bias);
                bytes.writeByte(0);
                bytes.writeUnsignedInt(sampler | 5);
            } else {
                push(b, bytes);
            }
        } else {
            bytes.writeUnsignedInt(0x00);
            bytes.writeUnsignedInt(0x00);
        }
    }

    protected function opcode2(code:int, dest:GpuRegister = null, a:GpuRegister = null, b:GpuRegister = null):void {
        throw new IllegalOperationError("Unsupported version");
    }

    private function push(src:GpuRegister, bytes:ByteArray):void {
        bytes.writeShort(src.index);
        bytes.writeByte(0);
        bytes.writeByte(swizzle(src.field));
        bytes.writeByte(src.type);
        bytes.writeByte(0);
        bytes.writeShort(0);
    }

    private function mask(fields:String):uint {
        var result:uint = 0;
        if (fields) {
            for each (var i:String in fields.split("")) {
                result |= 1 << getField(i);
            }
        }
        return result || 0x0f;
    }

    private function swizzle(fields:String):uint {
        var result:uint = 0;
        if (fields) {
            var field:int;
            var shift:int = 0;

            for each (var i:String in fields.split("")) {
                field = getField(i);
                result |= field << (shift << 1);
                shift++;
            }

            while (shift < 4) {
                result |= field << (shift << 1);
                shift++;
            }
        }
        return result || 0xe4;
    }

    private function getField(name:String):int {
        switch (name) {
            case "x":
            case "r":
                return 0;
            case "y":
            case "g":
                return 1;
            case "z":
            case "b":
                return 2;
        }
        return 3;
    }

    /**
     * Move dest = src
     */
    [Inline]
    final protected function mov(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x00, dest, src);
    }

    /**
     * Add dest = a + b
     */
    [Inline]
    final protected function add(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x01, dest, a, b);
    }

    /**
     * Subtract dest = a - b
     */
    [Inline]
    final protected function sub(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x02, dest, a, b);
    }

    /**
     * Multiply dest = a * b
     */
    [Inline]
    final protected function mul(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x03, dest, a, b);
    }

    /**
     * Divide dest = a / b
     */
    [Inline]
    final protected function div(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x04, dest, a, b);
    }

    /**
     * Reciprocal dest = 1 / src
     */
    [Inline]
    final protected function rcp(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x05, dest, src);
    }

    /**
     * Minimum dest = min(a, b)
     */
    [Inline]
    final protected function min(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x06, dest, a, b);
    }

    /**
     * Maximum dest = max(a, b)
     */
    [Inline]
    final protected function max(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x07, dest, a, b);
    }

    /**
     * Fractional dest = src - floor(src)
     */
    [Inline]
    final protected function frc(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x08, dest, src);
    }

    /**
     * Square root dest = sqrt(src)
     */
    [Inline]
    final protected function sqt(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x09, dest, src);
    }

    /**
     * Reciprocal root dest = 1 / sqrt(src)
     */
    [Inline]
    final protected function rsq(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x0a, dest, src);
    }

    /**
     * Power dest = a ^ b
     */
    [Inline]
    final protected function pow(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x0b, dest, a, b);
    }

    /**
     * Logarithm dest = log2(src)
     */
    [Inline]
    final protected function log(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x0c, dest, src);
    }

    /**
     * Exponential dest = 2 ^ src
     */
    [Inline]
    final protected function exp(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x0d, dest, src);
    }

    /**
     * Normalize dest = normalize(src)
     */
    [Inline]
    final protected function nrm(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x0e, dest, src);
    }

    /**
     * Sine dest = sin(src)
     */
    [Inline]
    final protected function sin(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x0f, dest, src);
    }

    /**
     * Cosine dest = cos(src)
     */
    [Inline]
    final protected function cos(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x10, dest, src);
    }

    /**
     * Cross product dest = a x b
     * <pre>
     * dest.x = a.y * b.z - a.z * b.y
     * dest.y = a.z * b.x - a.x * b.z
     * dest.z = a.x * b.y - a.y * b.x
     * </pre>
     */
    [Inline]
    final protected function crs(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x11, dest, a, b);
    }

    /**
     * Three-component dot product dest = dot3(a, b)
     * <pre>
     * dest = (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + (a.w * b.w)
     * </pre>
     */
    [Inline]
    final protected function dp3(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x12, dest, a, b);
    }

    /**
     * Four-component dot product dest = dot4(a, b)
     * <pre>
     * dest = (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + (a.w * b.w)
     * </pre>
     */
    [Inline]
    final protected function dp4(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x13, dest, a, b);
    }

    /**
     * Absolute dest = abs(src)
     */
    [Inline]
    final protected function abs(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x14, dest, src);
    }

    /**
     * Negate dest = -src
     */
    [Inline]
    final protected function neg(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x15, dest, src);
    }

    /**
     * Saturate dest = max(min(src, 1), 0)
     */
    [Inline]
    final protected function sat(dest:GpuRegister, src:GpuRegister):void {
        opcode(0x16, dest, src);
    }

    /**
     * Multiply a 3-component vector by a 3x3 matrix dest = a x b<br/>
     * <pre>
     * dest.x = dot3(a, b+0)
     * dest.y = dot3(a, b+1)
     * dest.z = dot3(a, b+2)
     * </pre>
     *
     * @param a 3-component vector
     * @param b 3x3 matrix
     */
    [Inline]
    final protected function m33(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x17, dest, a, b);
    }

    /**
     * Multiply a 4-component vector by a 4x4 matrix dest = a x b
     * <pre>
     * dest.x = dot4(a, b+0)
     * dest.y = dot4(a, b+1)
     * dest.z = dot4(a, b+2)
     * dest.w = dot4(a, b+3)
     * </pre>
     *
     * @param a 4-component vector
     * @param b 4x4 matrix
     */
    [Inline]
    final protected function m44(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x18, dest, a, b);
    }

    /**
     * Multiply a 3-component vector by a 3x4 matrix dest = a x b
     * <pre>
     * dest.x = dot4(a, b+0)
     * dest.y = dot4(a, b+1)
     * dest.z = dot4(a, b+2)
     * </pre>
     *
     * @param a 3-component vector
     * @param b 3x4 matrix
     */
    [Inline]
    final protected function m34(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x19, dest, a, b);
    }

    /**
     * Set if greater or equal dest = (a >= b) ? 1 : 0
     */
    [Inline]
    final protected function sge(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x29, dest, a, b);
    }

    /**
     * Discard fragment if any of src[i] < 0
     */
    [Inline]
    final protected function kil(src:GpuRegister):void {
        opcode(0x27, null, src);
    }

    /**
     * Set if less dest = (a < b) ? 1 : 0
     */
    [Inline]
    final protected function slt(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x2a, dest, a, b);
    }

    /**
     * Set if equal dest = (a == b) ? 1 : 0
     */
    [Inline]
    final protected function seq(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x2c, dest, a, b);
    }

    /**
     * Set if not equal dest = (a != b) ? 1 : 0
     */
    [Inline]
    final protected function sne(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode(0x2d, dest, a, b);
    }

    /**
     * Load from texture at coordinates
     *
     * @param src      Coordinates
     * @param sampler  Texture
     * @param flags    Sampler, default is RGBA | D2 | MIPNONE | NEAREST | CLAMP
     * @param level    Texture level of details, default is 0
     */
    [Inline]
    final protected function tex(dest:GpuRegister, coords:GpuRegister, sampler:GpuRegister, flags:uint = 0, level:int = 0):void {
        opcode(0x28, dest, coords, sampler, flags, level << 3);
    }

    // Version 2 opcodes are not supported

    [Inline]
    final protected function ddx(dest:GpuRegister, src:GpuRegister):void {
        opcode2(0x1a, dest, src);
    }

    [Inline]
    final protected function ddy(dest:GpuRegister, src:GpuRegister):void {
        opcode2(0x1b, dest, src);
    }

    [Inline]
    final protected function ife(a:GpuRegister, b:GpuRegister):void {
        opcode2(0x1c, null, a, b);
    }

    [Inline]
    final protected function ine(a:GpuRegister, b:GpuRegister):void {
        opcode2(0x1d, null, a, b);
    }

    [Inline]
    final protected function ifg(a:GpuRegister, b:GpuRegister):void {
        opcode2(0x1e, null, a, b);
    }

    [Inline]
    final protected function ifl(a:GpuRegister, b:GpuRegister):void {
        opcode2(0x1f, null, a, b);
    }

    [Inline]
    final protected function els():void {
        opcode2(0x20);
    }

    [Inline]
    final protected function eif():void {
        opcode2(0x21);
    }

    [Inline]
    final protected function ted(dest:GpuRegister, a:GpuRegister, b:GpuRegister):void {
        opcode2(0x26, dest, a, b);
    }

}
}