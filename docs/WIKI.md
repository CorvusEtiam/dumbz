# Useful info:

## Converting []u8 to u24 and vice versa:

>  slice[0..3].* will produce a [3]u8 if both indices are comptime-known, which you can then @bitCast(u24, ...) in theory.

>  FYI, if you have a runtime-known offset instead of 0, you can do slice[off..][0..3].* instead, I think


## Allocator

Do not copy allocator out of struct.

```ts
var gpa = GeneralPurposeAllocator(.{}){};
var allocator = &gpa.allocator
//            --^-- - remember to access as slice
```

# Format Strings

> print("{d}", .{double});
> print("{d<4}", {right_padded_double});
> print("{}")
