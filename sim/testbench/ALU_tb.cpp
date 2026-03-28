#include "VALU.h"
#include <iostream>
#include <cstdint>
#include <cassert>

// Required function for Verilator
double sc_time_stamp() { return 0; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Instantiate the design
    VALU* top = new VALU("ALU");

    int passed = 0;
    int failed = 0;

    // Helper lambda for testing
    auto test_alu = [&](int id, const char* op_name,
                        uint32_t alu_op, uint32_t a, uint32_t b,
                        uint32_t expected_result, uint32_t expected_zero) {
        // Apply inputs
        top->io_alu_op = alu_op;
        top->io_a = a;
        top->io_b = b;

        // Evaluate
        top->eval();

        // Get outputs
        uint32_t got_result = top->io_result;
        uint32_t got_zero = top->io_zero;

        // Check result
        bool pass = (got_result == expected_result) && (got_zero == expected_zero);

        // Output format: [TEST id] <OP>: a=<VAL> b=<VAL> | expect=<VAL> got=<VAL> | PASS/FAIL
        std::cout << "[TEST " << id << "] " << op_name
                  << ": a=0x" << std::hex << a << " b=0x" << b
                  << " | expect=0x" << expected_result << " got=0x" << got_result
                  << " zero_exp=" << expected_zero << " got=" << got_zero
                  << " | " << (pass ? "PASS" : "FAIL") << std::dec << std::endl;

        if (pass) passed++;
        else failed++;

        return pass;
    };

    std::cout << "=== RV32I ALU Testbench ===" << std::endl;

    // RV32I ALU operation codes (alu_op = {sub_enable, funct3}):
    // ADD = 0x0 (funct3=000, sub_enable=0)
    // SUB = 0x8 (funct3=000, sub_enable=1)
    // SLT = 0x2 (funct3=010)
    // XOR = 0x4 (funct3=100)
    // OR  = 0x6 (funct3=110)
    // AND = 0x7 (funct3=111)
    const uint32_t OP_ADD = 0x0;
    const uint32_t OP_SUB = 0x8;
    const uint32_t OP_SLT = 0x2;
    const uint32_t OP_XOR = 0x4;
    const uint32_t OP_OR  = 0x6;
    const uint32_t OP_AND = 0x7;

    // === Basic Function Tests ===

    // Test 1: ADD basic (5 + 3 = 8)
    test_alu(1, "ADD", OP_ADD, 5, 3, 8, 0);

    // Test 2: SUB basic (10 - 4 = 6)
    test_alu(2, "SUB", OP_SUB, 10, 4, 6, 0);

    // Test 3: AND (0xFF0F & 0xF0FF = 0xF00F)
    test_alu(3, "AND", OP_AND, 0xFF0F, 0xF0FF, 0xF00F, 0);

    // Test 4: OR (0x0F0F | 0xF0F0 = 0xFFFF)
    test_alu(4, "OR", OP_OR, 0x0F0F, 0xF0F0, 0xFFFF, 0);

    // Test 5: XOR (0xAAAA ^ 0x5555 = 0xFFFF)
    test_alu(5, "XOR", OP_XOR, 0xAAAA, 0x5555, 0xFFFF, 0);

    // Test 6: SLT (5 < 10 -> 1)
    test_alu(6, "SLT", OP_SLT, 5, 10, 1, 0);

    // Test 7: SLT (10 < 5 -> 0, result=0, so zero=1)
    test_alu(7, "SLT", OP_SLT, 10, 5, 0, 1);

    // === Arithmetic Wrap-around Tests (RV32I Standard) ===

    // Test 8: ADD wrap-around (0x7FFFFFFF + 1 = 0x80000000)
    test_alu(8, "ADD", OP_ADD, 0x7FFFFFFF, 1, 0x80000000, 0);

    // Test 9: SUB wrap-around (0x80000000 - 1 = 0x7FFFFFFF)
    test_alu(9, "SUB", OP_SUB, 0x80000000, 1, 0x7FFFFFFF, 0);

    // Test 10: ADD zero (-1 + 1 = 0, zero flag = 1)
    test_alu(10, "ADD", OP_ADD, 0xFFFFFFFF, 1, 0, 1);

    // === SLT Signed Logic Tests (Critical) ===

    // Test 11: SLT signed (+1 < -1 -> 0, result=0, so zero=1)
    test_alu(11, "SLT", OP_SLT, 1, 0xFFFFFFFF, 0, 1);

    // Test 12: SLT signed (-2 < -1 -> 1)
    test_alu(12, "SLT", OP_SLT, 0xFFFFFFFE, 0xFFFFFFFF, 1, 0);

    // Test 13: SLT signed (equal -> 0)
    test_alu(13, "SLT", OP_SLT, 0x80000000, 0x80000000, 0, 1);

    // === Zero Flag Tests ===

    // Test 14: AND produces zero (1 & 0 = 0)
    test_alu(14, "AND", OP_AND, 1, 0, 0, 1);

    // Test 15: XOR equal values (0x80000000 ^ 0x80000000 = 0)
    test_alu(15, "XOR", OP_XOR, 0x80000000, 0x80000000, 0, 1);

    // Test 16: SUB equal values (10 - 10 = 0)
    test_alu(16, "SUB", OP_SUB, 10, 10, 0, 1);

    // === Additional Edge Cases ===

    // Test 17: AND with negative (0x80000000 & 0x80000000 = 0x80000000)
    test_alu(17, "AND", OP_AND, 0x80000000, 0x80000000, 0x80000000, 0);

    // Test 18: OR with negative (0x80000000 | 0x7FFFFFFF = 0xFFFFFFFF)
    test_alu(18, "OR", OP_OR, 0x80000000, 0x7FFFFFFF, 0xFFFFFFFF, 0);

    // Test 19: XOR with negative (0x55555555 ^ 0xFFFFFFFF = 0xAAAAAAAA)
    test_alu(19, "XOR", OP_XOR, 0x55555555, 0xFFFFFFFF, 0xAAAAAAAA, 0);

    // Test 20: SLT negative vs positive (-1 < 1 -> 1)
    test_alu(20, "SLT", OP_SLT, 0xFFFFFFFF, 1, 1, 0);

    // Summary
    std::cout << "=== TEST SUMMARY ===" << std::endl;
    std::cout << "Passed: " << passed << "/" << (passed + failed) << std::endl;
    std::cout << "Failed: " << failed << "/" << (passed + failed) << std::endl;

    delete top;

    return failed > 0 ? 1 : 0;
}
