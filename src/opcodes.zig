pub const Opcode = enum(u8) {
    Constant,
    ConstantLong,
    Negate,
    Add,
    Substract,
    Multiply,
    Divide,
    Return,
};
