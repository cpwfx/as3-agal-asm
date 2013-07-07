package org.flashgate.display.gpu.assembler {
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * AGAL (Adobe Graphics Assembly Language) Pseudo Program Bytecode Generator
	 * 
	 * @see http://help.adobe.com/en_US/as3/dev/WSd6a006f2eb1dc31e-310b95831324724ec56-8000.html
	 */
	public class GpuAssembler {
		
		// Sampler
		protected const RGBA : int = 0 << 8;
		protected const DXT1 : int = 1 << 8;
		protected const DXT5 : int = 2 << 8;
		protected const VIDEO : int = 3 << 8;
		
		// Sampler Type
		protected const D2 : int = 0 << 12;
		protected const CUBE : int = 1 << 12;
		protected const D3 : int = 2 << 12;
		
		// Sampler Flags
		protected const CENTROID : int = 1 << 16;
		protected const SINGLE : int = 2 << 16;
		protected const IGNORESAMPLER : int = 4 << 16;
		
		// Sampler Wrap
		protected const CLAMP : int = 0 << 20;
		protected const WRAP : int = 1 << 20;
		
		// Sampler MipMap
		protected const MIPNONE : int = 0 << 24;
		protected const MIPNEAREST : int = 1 << 24;
		protected const MIPLINEAR : int = 2 << 24;
		
		// Sampler Filter
		protected const NEAREST : int = 0;
		protected const LINEAR : int = 1 << 28;
		
		// Constants
		private const VERTEX : int = 0x00;
		private const FRAGMENT : int = 0x01;
		private const ATTRIBUTE : int = 0x00;
		private const CONSTANT : int = 0x01;
		private const TEMPORARY : int = 0x02;
		private const OUTPUT : int = 0x03;
		private const VARYING : int = 0x04;
		private const SAMPLER : int = 0x05;
		private const DEPTH : int = 0x05;
		
		// Private
		private var _bytes : ByteArray;
		private var _type : int;
		private var _version : int = 1;

		public function get vertexProgram() : ByteArray {
			var va : GpuRegister = new GpuRegister(VERTEX, ATTRIBUTE);
			var vc : GpuRegister = new GpuRegister(VERTEX, CONSTANT);
			var vt : GpuRegister = new GpuRegister(VERTEX, TEMPORARY);
			var v : GpuRegister = new GpuRegister(VERTEX, VARYING);
			var op : GpuRegister = new GpuRegister(VERTEX, OUTPUT);

			header(VERTEX);
			vertex(va, vc, vt, v, op);
			return pack();
		}

		public function get fragmentProgram() : ByteArray {
			var v : GpuRegister = new GpuRegister(VERTEX, VARYING);
			var fc : GpuRegister = new GpuRegister(FRAGMENT, CONSTANT);
			var ft : GpuRegister = new GpuRegister(FRAGMENT, TEMPORARY);
			var fs : GpuRegister = new GpuRegister(FRAGMENT, SAMPLER);
			var od : GpuRegister = new GpuRegister(FRAGMENT, DEPTH);
			var oc : GpuRegister = new GpuRegister(FRAGMENT, OUTPUT);

			header(FRAGMENT);
			fragment(v, fc, ft, fs, od, oc);
			return pack();
		}

		/**
		 * Vertex Shader Program
		 * 
		 * @param va	Attributes from Context3D::setVertexBufferAt()
		 * @param vc	Constants from Context3D::setProgramConstants()
		 * @param vt	Temporary register
		 * @param v		Variables
		 * @param op	Output position
		 */
		protected function vertex(va : GpuRegister, vc : GpuRegister, vt : GpuRegister, v : GpuRegister, op : GpuRegister) : void {
			mov(v, va[1]);
			div(op, va, vc);
		}

		/**
		 * Fragment Shader Program
		 * 
		 * @param v		Variables
		 * @param fc	Constants from Context3D::setProgramConstants()
		 * @param ft	Temporary register
		 * @param fs	Sampler
		 * @param od	Depth output
		 * @param oc	Output color
		 */
		protected function fragment(v : GpuRegister, fc : GpuRegister, ft : GpuRegister, fs : GpuRegister, od : GpuRegister, oc : GpuRegister) : void {
			mov(oc, v);
		}

		private function header(type : int) : void {
			_bytes = new ByteArray();
			_bytes.endian = Endian.LITTLE_ENDIAN;
			_bytes.writeByte(0xa0);
			_bytes.writeUnsignedInt(_version);
			_bytes.writeByte(0xa1);
			_bytes.writeByte(_type = type);
		}
		
		private function pack() : ByteArray {
			var result:ByteArray = _bytes;
			_bytes.length = _bytes.position;
			_bytes.position = 1;
			_bytes.writeUnsignedInt(_version);
			_bytes = null;			
			return result;
		}

		protected function opcode(code : int, dest : GpuRegister = null, a : GpuRegister = null, b : GpuRegister = null, sampler : uint = 0, bias : int = 0) : void {
			var bytes : ByteArray = _bytes;
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

		private function push(src : GpuRegister, bytes : ByteArray) : void {
			bytes.writeShort(src.index);
			bytes.writeByte(0);
			bytes.writeByte(swizzle(src.field));
			bytes.writeByte(src.type);
			bytes.writeByte(0);
			bytes.writeShort(0);
		}

		private function mask(fields : String) : uint {
			var result : uint = 0;
			if (fields) {
				for each (var i : String in fields.split("")) {
					result |= 1 << getField(i);
				}
			}
			return result || 0x0f;
		}

		private function swizzle(fields : String) : uint {
			var result : uint = 0;
			if (fields) {
				var field : int;
				var shift : int = 0;

				for each (var i : String in fields.split("")) {
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

		private function getField(name : String) : int {
			switch(name) {
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
		 *	Move: <code>dest = src</code>
		 */
		protected function mov(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x00, dest, src);
		}

		/**
		 * Add: <code>dest = a + b</code>
		 */
		protected function add(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x01, dest, a, b);
		}

		/**
		 * Subtract: <code>dest = a - b</code>
		 */
		protected function sub(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x02, dest, a, b);
		}

		/**
		 * Multiply: <code>dest = a * b</code>
		 */
		protected function mul(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x03, dest, a, b);
		}

		/**
		 * Divide: <code>dest = a / b</code>
		 */
		protected function div(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x04, dest, a, b);
		}

		/**
		 * Reciprocal: <code>dest = 1 / src</code>
		 */
		protected function rcp(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x05, dest, src);
		}

		/**
		 * Minimum: <code>dest = min(a, b)</code>
		 */
		protected function min(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x06, dest, a, b);
		}

		/**
		 * Maximum: <code>dest = max(a, b)</code>
		 */
		protected function max(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x07, dest, a, b);
		}

		/**
		 * Fractional: <code>dest = src - floor(src)</code>
		 */
		protected function frc(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x08, dest, src);
		}

		/**
		 * Square root: <code>dest = sqrt(src)</code>
		 */
		protected function sqt(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x09, dest, src);
		}

		/**
		 * Reciprocal root: <code>dest = 1 / sqrt(src)</code>
		 */
		protected function rsq(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x0a, dest, src);
		}

		/**
		 * Power: <code>dest = a ^ b</code>
		 */
		protected function pow(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x0b, dest, a, b);
		}

		/**
		 * Logarithm: <code>dest = log2(src)</code>
		 */
		protected function log(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x0c, dest, src);
		}

		/**
		 * Exponential: <code>dest = 2 ^ src</code>
		 */
		protected function exp(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x0d, dest, src);
		}

		/**
		 * Normalize: <code>dest = normalize(src)</code>
		 */
		protected function nrm(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x0e, dest, src);
		}

		/**
		 * Sine: <code>dest = sin(src)</code>
		 */
		protected function sin(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x0f, dest, src);
		}

		/**
		 * Cosine: <code>dest = cos(src)</code>
		 */
		protected function cos(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x10, dest, src);
		}

		/**
		 * Cross product: <code>dest = a x b</code>
		 * <br /><code>
		 * dest.x = a.y * b.z - a.z * b.y<br/>
		 * dest.y = a.z * b.x - a.x * b.z<br/>
		 * dest.z = a.x * b.y - a.y * b.x</code>
		 */
		protected function crs(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x11, dest, a, b);
		}

		/**
		 * Three-component dot product: <code>dest = dot3(a, b)</code>
		 * <br /><code>
		 * dest = (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + (a.w * b.w)</code>
		 */
		protected function dp3(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x12, dest, a, b);
		}

		/**
		 * Four-component dot product: <code>dest = dot4(a, b)</code>
		 * <br /><code>
		 * dest = (a.x * b.x) + (a.y * b.y) + (a.z * b.z) + (a.w * b.w)</code>
		 */
		protected function dp4(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x13, dest, a, b);
		}

		/**
		 * Absolute: <code>dest = abs(src)</code>
		 */
		protected function abs(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x14, dest, src);
		}

		/**
		 * Negate: <code>dest = -src</code>
		 */
		protected function neg(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x15, dest, src);
		}

		/**
		 * Saturate: <code>dest = max(min(src, 1), 0)</code>
		 */
		protected function sat(dest : GpuRegister, src : GpuRegister) : void {
			opcode(0x16, dest, src);
		}

		/**
		 * Multiply a 3-component vector by a 3x3 matrix: <code>dest = b * a<br/></code>
		 * <br/><code>
		 * dest.x = dot3(a, b+0)<br/>
		 * dest.y = dot3(a, b+1)<br/>
		 * dest.z = dot3(a, b+2)</code>
		 * 
		 * @param a 3-component vector
		 * @param b 3x3 matrix
		 */
		protected function m33(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x17, dest, a, b);
		}

		/**
		 * Multiply a 4-component vector by a 4x4 matrix: <code>dest = b * a</code>
		 * <br/><code>
		 * dest.x = dot4(a, b+0)<br/>
		 * dest.y = dot4(a, b+1)<br/>
		 * dest.z = dot4(a, b+2)<br/>
		 * dest.w = dot4(a, b+3)</code>
		 * 
		 * @param a 4-component vector
		 * @param b 4x4 matrix
		 */
		protected function m44(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x18, dest, a, b);
		}

		/**
		 * Multiply a 3-component vector by a 3x4 matrix: <code>dest = b * a</code>
		 * <br/><code>
		 * dest.x = dot4(a, b+0)<br/>
		 * dest.y = dot4(a, b+1)<br/>
		 * dest.z = dot4(a, b+2)</code>
		 * 
		 * @param a 3-component vector
		 * @param b 3x4 matrix
		 */
		protected function m34(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x19, dest, a, b);
		}

		/**
		 * Set if greater or equal: <code>dest = (a >= b) ? 1 : 0</code>
		 */
		protected function sge(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x29, dest, a, b);
		}

		/**
		 * Discard fragment if any of src[i] < 0
		 */
		protected function kil(src : GpuRegister) : void {
			opcode(0x27, null, src);
		}

		/**
		 * Set if less: <code>dest = (a < b) ? 1 : 0</code>
		 */
		protected function slt(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x2a, dest, a, b);
		}

		/**
		 * Set if equal: <code>dest = (a == b) ? 1 : 0</code>
		 */
		protected function seq(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x2c, dest, a, b);
		}

		/**
		 * Set if not equal: <code>dest = (a != b) ? 1 : 0</code>
		 */
		protected function sne(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x2d, dest, a, b);
		}

		/**
		 * Load from texture at coordinates
		 * 
		 * @param src		Coordinates
		 * @param sampler	Texture
		 * @param flags		Sampler, default is RGBA | D2 | MIPNONE | NEAREST | CLAMP
		 * @param level		Texture level of details, default is 0
		 */
		protected function tex(dest : GpuRegister, coords : GpuRegister, sampler : GpuRegister, flags : uint = 0, level : int = 0) : void {
			opcode(0x28, dest, coords, sampler, flags, level << 3);
		}

		// Version 2 opcodes
		
		protected function ddx(dest : GpuRegister, src : GpuRegister) : void {
			_version = 2;
			opcode(0x1a, dest, src);
		}

		protected function ddy(dest : GpuRegister, src : GpuRegister) : void {
			_version = 2;
			opcode(0x1b, dest, src);
		}

		protected function ife(a : GpuRegister, b : GpuRegister) : void {
			_version = 2;
			opcode(0x1c, null, a, b);
		}

		protected function ine(a : GpuRegister, b : GpuRegister) : void {
			_version = 2;
			opcode(0x1d, null, a, b);
		}

		protected function ifg(a : GpuRegister, b : GpuRegister) : void {
			_version = 2;
			opcode(0x1e, null, a, b);
		}

		protected function ifl(a : GpuRegister, b : GpuRegister) : void {
			_version = 2;
			opcode(0x1f, null, a, b);
		}

		protected function els() : void {
			_version = 2;
			opcode(0x20);
		}

		protected function eif() : void {
			_version = 2;
			opcode(0x21);
		}

		protected function ted(dest : GpuRegister, a : GpuRegister, b : GpuRegister) : void {
			opcode(0x26, dest, a, b);
		}

		public function dispose() : void {
		}
	}
}