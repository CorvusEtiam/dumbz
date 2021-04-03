# Useful info:

## Converting []u8 to u24 and vice versa:

### Old, crappier way

>  slice[0..3].* will produce a [3]u8 if both indices are comptime-known, which you can then @bitCast(u24, ...) in theory.

>  FYI, if you have a runtime-known offset instead of 0, you can do slice[off..][0..3].* instead, I think

### Better way

* Reading:  `@intCast(usize, std.mem.readIntLittle(u24, code[self.ip..][0..3]));`
* Writing: 

```rust
var buf: [3]u8 = undefined;
std.mem.writeIntLittle(u24, &buf, @intCast(u24, tmp));
self.code.appendSlice(&buf) catch unreachable;
```

## Allocator

Do not copy allocator out of struct.

```ts
var gpa = GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator
//            --^-- - remember to access as slice
```

# Format Strings

```rust
print("{d}", .{double});
print("{d<4}", {right_padded_double});
print("{d:.2}", {two_place_precision_double})
print("{}")
```

# Compile-Time If

```rust
const x: bool = false;
if ( x ) {
    // this should show up in assembly only when x is true!
} else {
    // otherwise; no comptime required. 
}
```

# Arrays

## Multidimensional Arrays

## Allocating arrays in functions

* Requires alloc for runtime-known size
    