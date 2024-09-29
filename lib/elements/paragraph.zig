const Paragraph = @This();
const Element = @import("../elements.zig").Element;

// TODO: Multiline paragraphs
text: []const u8,

pub fn parse(line: []const u8) Paragraph {
    return Paragraph{
        .text = line,
    };
}

pub fn parseElement(line: []const u8) Element {
    return .{ .paragraph = parse(line) };
}
