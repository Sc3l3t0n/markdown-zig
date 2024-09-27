const Self = @This();
const Element = @import("../elements.zig").Element;

// TODO: Multiline paragraphs
text: []const u8,

pub fn parse(line: []const u8) Self {
    return Self{
        .text = line,
    };
}

pub fn parseElement(line: []const u8) Element {
    return .{ .paragraph = parse(line) };
}
