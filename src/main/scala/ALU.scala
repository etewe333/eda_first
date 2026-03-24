import chisel3._
import chisel3.util._
import _root_.circt.stage.ChiselStage // 用于生成 Verilog

/**
  * ALU模块 - 支持RV32I基本算术逻辑操作
  *
  * 支持的操作：
  * - ADD: 加法 (funct3=000, sub_enable=0)
  * - SUB: 减法 (funct3=000, sub_enable=1)
  * - AND: 位与 (funct3=111)
  * - OR: 位或 (funct3=110)
  * - XOR: 位异或 (funct3=100)
  * - SLT: 有符号小于置位 (funct3=010)
  *
  * 端口：
  * - a, b: 32位输入操作数
  * - alu_op[3:0]: 操作码，alu_op[2:0]为funct3，alu_op[3]为sub_enable(funct7[5])
  * - result: 32位运算结果
  * - zero: 零标志位 (result == 0)
  *
  * RV32I funct3编码：
  * 000: ADD/SUB (通过sub_enable区分)
  * 001: SLL (不支持，返回0)
  * 010: SLT
  * 011: SLTU (不支持，返回0)
  * 100: XOR
  * 101: SRL/SRA (不支持，返回0)
  * 110: OR
  * 111: AND
  */
class ALU extends Module {
  val io = IO(new Bundle {
    val a = Input(UInt(32.W))
    val b = Input(UInt(32.W))
    // alu_op[3]用于区分ADD/SUB (funct7[5])，alu_op[2:0]为funct3
    val alu_op = Input(UInt(4.W))
    val result = Output(UInt(32.W))
    val zero = Output(Bool())
  })

  // 提取funct3和SUB使能信号
  val funct3 = io.alu_op(2, 0)
  val sub_enable = io.alu_op(3)  // funct7[5]，用于区分ADD/SUB

  // RV32I funct3编码定义
  val FUNCT3_ADD_SUB = 0.U(3.W)  // 000: ADD/SUB
  val FUNCT3_SLL     = 1.U(3.W)  // 001: SLL (不支持)
  val FUNCT3_SLT     = 2.U(3.W)  // 010: SLT
  val FUNCT3_SLTU    = 3.U(3.W)  // 011: SLTU (不支持)
  val FUNCT3_XOR     = 4.U(3.W)  // 100: XOR
  val FUNCT3_SRL_SRA = 5.U(3.W)  // 101: SRL/SRA (不支持)
  val FUNCT3_OR      = 6.U(3.W)  // 110: OR
  val FUNCT3_AND     = 7.U(3.W)  // 111: AND

  // 算术运算结果（ADD/SUB）
  val add_sub_result = Mux(sub_enable, io.a - io.b, io.a + io.b)

  // 逻辑运算结果
  val and_result = io.a & io.b
  val or_result  = io.a | io.b
  val xor_result = io.a ^ io.b

  // SLT: 有符号比较 (a < b ? 1 : 0)
  val slt_result = Mux(io.a.asSInt < io.b.asSInt, 1.U(32.W), 0.U(32.W))

  // 根据funct3选择结果（符合RV32I标准）
    io.result := MuxLookup(funct3, 0.U(32.W))(Seq(
    FUNCT3_ADD_SUB -> add_sub_result,
    FUNCT3_SLT     -> slt_result,
    FUNCT3_XOR     -> xor_result,
    FUNCT3_OR      -> or_result,
    FUNCT3_AND     -> and_result
  ))

  // 零标志位: 当结果为0时置位
  io.zero := io.result === 0.U
}

// 定义 Main 对象以便手动调用生成器
object ALUGen extends App {
  ChiselStage.emitSystemVerilogFile(
    new ALU(),
    Array("--target-dir", "generated")
  )
}