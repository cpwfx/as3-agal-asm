#AS3 AGAL Assembler#

Small AS3 pseudo program to AGAL bytecode generator.
Compatible with Adobe's AGALMiniAssembler v1.

Usage:

	var shader:MyShader = new MyShader();
	var program:Program3D = context.createProgram();
	program.upload(shader.vertexProgram, shader.fragmentProgram);

Shader program must inherit GpuAssembler and override vertex()/fragment() methods:
	
	class MyShader extends GpuAssembler {
		/**
		 * Vertex Shader Program
		 * 
		 * @param va	Attributes from Context3D::setVertexBufferAt()
		 * @param vc	Constants from Context3D::setProgramConstants()
		 * @param vt	Temporary register
		 * @param v		Variables
		 * @param op	Output position
		 */
		override protected function vertex(va:GpuRegister, vc:GpuRegister, vt:GpuRegister, v:GpuRegister, op:GpuRegister) : void {
			mov(v, va[1]);
			div(op, va, vc);

			// It's the same as:
			// mov(v[0], va[1]);
			// div(op.xyzw, va[0]["rgba"], vc[0].rgba);
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
		override protected function fragment(v:GpuRegister, fc:GpuRegister, ft:GpuRegister, fs:GpuRegister, od:GpuRegister, oc:GpuRegister) : void {
			tex(oc, v, fs, LINEAR);
		}

	}

Conditional program generation:

	var useTextures:Boolean;
	...
	if (useTextures) {
		tex(oc, v, fs, LINEAR);
	} else {
		mov(oc, v);	
	}
	...

Macros examples:

	...
	length(vt, vt[3]);
	reflect(vt[1], va[1], vt[1]);
	...
	private function length(dest:GpuRegister, v:GpuRegister):void {
		dp3(dest, v, v);
		sqt(dest, dest);
	}
	...
	private function reflect(dest:GpuRegister, v:GpuRegister, n:GpuRegister):void {
		dp3(dest.x, x.xyz, n.xyz);
		mul(dest, x.xyz, dest.x);
		add(dest, dest, dest);
		sub(dest, n.xyz, dest);
	}
	...

Bug report:

- [https://github.com/flashgate/as3-agal-asm/issues/new](https://github.com/flashgate/as3-agal-asm/issues/new)
 

