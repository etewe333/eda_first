import chisel3._
import chisel3.util._
import _root_.circt.stage.ChiselStage

// RV32I ALU Module
// Supports: ADD, SUB, AND, OR, XOR, SLT
// Output: zero flag when result is zero

class ALU extends Module {
  val io = IO(new Bundle {
    // Operation selection (3-bit for 8 operations, use 3:0 for future extension)
    val alu_op = Input(UInt(4.W))

    // Input operands
    val a = Input(SInt(32.W))
    val b = Input(SInt(32.W))

    // Output result
    val result = Output(SInt(32.W))

    // Zero flag: 1 when result is zero
    val zero = Output(Bool())
  })

  // Internal result as UInt for easier manipulation
  // Default to 0, will be overridden by matched cases
  val result = WireInit(0.U(32.W))

  // ALU operation implementation
  switch(io.alu_op) {
    // ADD: a + b
    is("b0000".U) {
      result := (io.a.asUInt + io.b.asUInt)
    }
    // SUB: a - b
    is("b0001".U) {
      result := (io.a.asUInt - io.b.asUInt)
    }
    // AND: a & b
    is("b0010".U) {
      result := (io.a.asUInt & io.b.asUInt)
    }
    // OR: a | b
    is("b0011".U) {
      result := (io.a.asUInt | io.b.asUInt)
    }
    // XOR: a ^ b
    is("b0100".U) {
      result := (io.a.asUInt ^ io.b.asUInt)
    }
    // SLT: 1 if a < b (signed), 0 otherwise
    is("b0101".U) {
      result := Mux(io.a < io.b, 1.U, 0.U)
    }
    // Unmatched cases will keep result = 0 (default)
  }

  // Output result (convert UInt to SInt)
  io.result := result.asSInt

  // Zero flag: assert when result is zero
  io.zero := (result === 0.U)
}

// Main object for Verilog generation
object ALUGen extends App {
  ChiselStage.emitSystemVerilogFile(
    new ALU(),
    Array("--target-dir", "generated")
  )
}
