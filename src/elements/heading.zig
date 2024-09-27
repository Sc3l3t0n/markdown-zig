const std = @import("std");

const Element = @import("../elements.zig").Element;
const Self = @This();

/// First character of a heading in Markdown
pub const first_char = '#';

/// Heading level
/// Between 1 and 6
level: u8,
/// Heading text
text: []const u8,

/// Parses the heading and returns it.
pub fn parse(
    /// The full heading line to parse
    line: []const u8,
) Self {
    var level: u8 = 0;
    var start_index: ?usize = null;

    for (line, 0..) |char, index| {
        switch (char) {
            '#' => level += 1,
            ' ' => {},
            else => {
                start_index = index;
                break;
            },
        }
    }

    return Self{
        .level = level,
        .text = line[start_index.?..],
    };
}

/// Parses the heading and returns an element.
pub fn parseElement(
    /// The full heading line to parse
    line: []const u8,
) Element {
    return .{ .heading = parse(line) };
}

const testing = @import("std").testing;

test "parsing" {
    const element = parse("# Hello, world!");
    try testing.expect(element.level == 1);
    try testing.expectEqualSlices(u8, "Hello, world!", element.text);
}
