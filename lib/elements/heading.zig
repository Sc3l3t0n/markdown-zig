const std = @import("std");
const utils = @import("../utils.zig");

const Element = @import("../elements.zig").Element;
const Heading = @This();

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
) Heading {
    var level: u8 = 0;
    var iter = utils.SliceIterator(u8).init(line);

    while (iter.next()) |char| {
        if (char == first_char) {
            level += 1;
        } else {
            break;
        }
    }

    return Heading{
        .level = level,
        .text = iter.rest(),
    };
}

/// Parses the heading and returns an element.
pub fn parseElement(
    /// The full heading line to parse
    line: []const u8,
) Element {
    return .{ .heading = parse(line) };
}

/// Returns the content height of the element
pub fn contentHeight(self: *Heading) usize {
    _ = self;
    return 1;
}

/// Returns the content width of the element
pub fn contentWidth(self: *Heading) usize {
    return self.text.len;
}

const testing = @import("std").testing;

test "parsing" {
    const element = parse("# Hello, world!");
    try testing.expect(element.level == 1);
    try testing.expectEqualSlices(u8, "Hello, world!", element.text);
}
