const std = @import("std");
const parser = @import("parser.zig");

const Element = @import("elements.zig").Element;
const Self = @This();

allocator: std.mem.Allocator,
content: std.ArrayList(u8),
elements: std.ArrayList(Element),

/// Initializes the document.
pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .allocator = allocator,
        .content = std.ArrayList(u8).init(allocator),
        .elements = std.ArrayList(Element).init(allocator),
    };
}

/// Sets the content of the document and parses it into elements.
/// Clears any existing content and elements.
/// Accessing the document old elements after calling this function is undefined behavior.
pub fn setContent(self: *Self, content: []const u8) !void {
    self.content.clearAndFree();
    try self.content.appendSlice(content);

    self.elements.clearAndFree();
    try parser.parse(content, &self.elements);
}

/// Deinitializes the document, freeing all resources.
/// Accessing the document or its elements after calling this function is undefined behavior.
pub fn deinit(self: *Self) void {
    self.content.deinit();

    for (self.elements.items) |*element| {
        element.deinit();
    }
    self.elements.deinit();
}

pub const testing = std.testing;

test "Full SetContent" {
    const content =
        \\# Heading
        \\## Subheading
        \\- First item
        \\Paragraph text
    ;

    var document = Self.init(std.testing.allocator);
    defer document.deinit();
    try document.setContent(content);
    try testing.expectEqualSlices(u8, content, document.content.items);

    const elements = document.elements.items;

    try testing.expectEqual(elements.len, 4);
    try testing.expectEqualSlices(u8, elements[0].heading.text, "Heading");
    try testing.expectEqual(elements[0].heading.level, 1);

    try testing.expectEqualSlices(u8, elements[1].heading.text, "Subheading");
    try testing.expectEqual(elements[1].heading.level, 2);

    try testing.expectEqualSlices(u8, elements[2].list.items.items[0].bullet.text, "First item");
    try testing.expectEqual(elements[2].list.items.items.len, 1);

    try testing.expectEqualSlices(u8, elements[3].paragraph.text, "Paragraph text");
}
