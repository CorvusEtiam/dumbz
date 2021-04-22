const std = @import("std");
const my  = @import("./my.zig");


// const Chunk = @import("./chunk.zig").Chunk;
// const Opcode = @import("./opcodes.zig").Opcode;
// const disasm = @import("./debug.zig");
// const VM = @import("./vm.zig");

const CliResult = union(enum) {
    filePath: []const u8,
    version: void,
    repl: void,
    help: void,
    tests: void,
};

fn printHelp() void {
    std.debug.print("Usage: dumbz.exe repl|version|<filename> \n", .{});
}

fn printVersion() void {
    std.debug.print("Dumbz: 0.0.1 \n", .{});
}

fn readPrompt(allocator: *std.mem.Allocator, prompt: []const u8, max_size: usize) ![]u8 {
    const in = std.io.getStdIn().reader();
    const out = std.io.getStdOut().writer();
    _ = try out.write(prompt);
    
    const result = try in.readUntilDelimiterAlloc(allocator, '\n', max_size);
    return if (std.mem.endsWith(u8, result, "\r")) result[0..(result.len - 1)] else result;
}

fn runRepl(allocator: *std.mem.Allocator) !void {
    const in = std.io.getStdIn().reader();
    const out = std.io.getStdOut().writer();

    while (true) {
        var result = try readPrompt(allocator, "=> ", 1024);
        if ( std.mem.startsWith(u8, result, "quit") ) {
            _ = try out.print("-------- EXITING\n", .{});
            return;
        }
        _ = try out.print("Command to be executed: \n", .{});
        _ = try out.write(result);
        _ = try out.write("\n");
        // var coll = try my.compiler.collect_tokens(allocator, result);
        // defer coll.deinit();
        _ = try my.compile(allocator, result);
    }
}

fn runFile(file_name: [] const u8, allocator: *std.mem.Allocator) void {
    std.debug.print("\x1b[31m  > TODO: File Runner\x1b[0m\n", .{});
    return;
}

fn startCli(allocator: *std.mem.Allocator) anyerror!void {
    var it = std.process.args();
    _ = it.skip();

    var cli: CliResult = undefined;
    // runRepl, runFile, showHelp
    // next error | C-string  

    var result = try (it.next(allocator) orelse ""); 

    if ( std.mem.eql(u8, result, "") ) {
        cli = CliResult.repl;
    } else if ( std.mem.eql(u8, result, "test") ) {
        cli = CliResult.tests;
    } else if ( std.mem.eql(u8, result, "help") ) {
        cli = CliResult.help;
    } else if ( std.mem.eql(u8, result, "repl") ) {
        cli = CliResult.repl;
    } else if ( std.mem.eql(u8, result, "version") ) {
        cli = CliResult.version;
    } else {
        cli = CliResult { .filePath = result };
    }
    
    switch ( cli ) {
        CliResult.repl => {
            return runRepl(allocator);
        },
        CliResult.help => {
            return printHelp();
        },
        CliResult.filePath => | file_path| {
            return runFile(file_path, allocator);
        },
        CliResult.version => {
            return printVersion();
        },
        CliResult.tests => {
            return runCode(allocator);
        },        
    }
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;

    try startCli(allocator);
}


fn runCode(allocator: *std.mem.Allocator) anyerror!void {
    var chunk = my.Chunk.init(allocator);
    defer chunk.deinit();

    var vm = my.VirtualMachine.init(allocator);
    



    chunk.writeConstant(3.14, 123);
    chunk.writeConstant(6.86, 123);
    chunk.writeOpcode(my.Opcode.Add, 123);
    chunk.writeConstant(2.0, 123);
    chunk.writeOpcode(my.Opcode.Divide, 123);
    chunk.writeOpcode(my.Opcode.Negate, 123);
    chunk.writeOpcode(my.Opcode.Return, 125);

    var ok = vm.interpret(&chunk) catch |err| {
        switch (err) {
            my.InterpreterError.CompileError => {
                std.debug.warn("Compilation Error ip:{d} !\n", .{vm.ip});
                return;
            },
            my.InterpreterError.RuntimeError => {
                std.debug.warn("Runtime Error ip:{d} !\n", .{vm.ip});
                return;
            },
        }
    };
    std.debug.print("Intepreter run was successful \n", .{});
    my.debug.disassembleChunk(&chunk, "RET");
}

