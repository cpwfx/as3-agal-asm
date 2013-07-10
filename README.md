#AS3 AGAL Assembler#

Small AS3 pseudo program to AGAL bytecode generator.
Compatible with Adobe's AGALMiniAssembler version 1.

Usage:

	var shader:MyShader = new MyShader();
	var program:Program3D = context.createProgram();
	program.upload(shader.vertexProgram, shader.fragmentProgram);

Shader program must inherit GpuAssembler and override vertex()/shader() methods:
    
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
		override protected function vertex(va : GpuRegister, vc : GpuRegister, vt : GpuRegister, v : GpuRegister, op : GpuRegister) : void {
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
		override protected function fragment(v : GpuRegister, fc : GpuRegister, ft : GpuRegister, fs : GpuRegister, od : GpuRegister, oc : GpuRegister) : void {
			tex(oc, v, fs, LINEAR);
		}

	}

Conditional shader generation:

	var useTextures:Boolean;
	...
	if (useTextures) {
		tex(oc, v, fs, LINEAR);
	} else {
		mov(oc, v);	
	}
	...

Bug report:

- [https://github.com/flashgate/as3-agal-asm/issues](https://github.com/flashgate/as3-agal-asm/issues)
 

