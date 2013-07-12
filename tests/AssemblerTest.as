package {
import flash.utils.ByteArray;

import flexunit.framework.AssertionFailedError;

import flexunit.framework.TestCase;

import org.flexunit.AssertionError;

import shaders.FractalShader;

import shaders.SimpleShader;

public class AssemblerTest extends TestCase {

    [Test]
    public function testSimpleShader():void {
        var shader:SimpleShader = new SimpleShader();
        assertEqualBytes(shader.fragmentProgramTest, shader.fragmentProgram);
        assertEqualBytes(shader.vertexProgramTest, shader.vertexProgram);
    }

    [Test]
    public function testFractalShader():void {
        var shader:FractalShader = new FractalShader();
        assertEqualBytes(shader.fragmentProgramTest, shader.fragmentProgram);
        assertEqualBytes(shader.vertexProgramTest, shader.vertexProgram);
    }

    private static function assertEqualBytes(a:ByteArray, b:ByteArray):void {
        if (a.length != b.length) {
            throw new AssertionFailedError("ByteArray length expected: " + a.length + " but was: " + b.length);
        }
        var count:int = a.length;
        for (var i:int = 0; i < count; i++) {
            if (a[i] != b[i]) {
                throw new AssertionFailedError("ByteArray at position: " + i + " expected: " + a[i] + " but was: " + b[i]);
            }
        }
    }
}
}