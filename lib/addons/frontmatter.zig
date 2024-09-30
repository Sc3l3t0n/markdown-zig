const std = @import("std");
const utils = @import("../utils.zig");
const mem = std.mem;

const Self = @This();

pub const FrontMatterParseError = error{
    InvalidBegin,
    InvalidEnd,
    InvalidAttribute,
};

data: std.StringHashMap([]const u8),

pub fn parse(
    allocator: mem.Allocator,
    lines: []const u8,
) (FrontMatterParseError || mem.Allocator.Error)!Self {
    var frontmatter = std.StringHashMap([]const u8).init(allocator);
    var iter = std.mem.splitScalar(u8, lines, '\n');

    if (iter.peek()) |line| {
        if (!mem.eql(u8, line, "---")) {
            return FrontMatterParseError.InvalidBegin;
        }
        _ = iter.next();
    }

    while (iter.next()) |line| {
        if (mem.eql(u8, line, "---")) {
            return Self{
                .data = frontmatter,
            };
        }
        var splitted = mem.split(u8, line, ": ");
        const key = splitted.next();
        const value = splitted.next();
        if (key != null and value != null) {
            try frontmatter.put(key.?, value.?);
        } else {
            return FrontMatterParseError.InvalidAttribute;
        }
    }
    return FrontMatterParseError.InvalidEnd;
}

pub fn deinit(self: *Self) void {
    self.data.deinit();
}

pub fn get(self: Self, key: []const u8) ?[]const u8 {
    return self.data.get(key);
}

const testing = std.testing;

test "parse" {
    const allocator = std.heap.page_allocator;
    const data =
        \\---
        \\title: Hello, world!
        \\---
    ;

    var fm = try parse(allocator, data);
    const title = fm.get("title");

    try testing.expect(title != null);
    try testing.expectEqualSlices(u8, "Hello, world!", title.?);
}

test "parse invalid begin" {
    const allocator = std.heap.page_allocator;

    const data =
        \\title: Hello, world!
        \\---
    ;

    try testing.expectError(
        FrontMatterParseError.InvalidBegin,
        parse(allocator, data),
    );
}

test "parse invalid end" {
    const allocator = std.heap.page_allocator;
    const data =
        \\---
        \\title: Hello, world!
    ;

    try testing.expectError(
        FrontMatterParseError.InvalidEnd,
        parse(allocator, data),
    );
}

test "parse invalid attribute" {
    const allocator = std.heap.page_allocator;
    const data =
        \\---
        \\title: Hello, world!
        \\invalid
    ;
    try testing.expectError(
        FrontMatterParseError.InvalidAttribute,
        parse(allocator, data),
    );
}
