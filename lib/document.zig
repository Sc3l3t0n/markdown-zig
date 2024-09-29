const std = @import("std");
const parser = @import("parser.zig");

const Element = @import("elements.zig").Element;
const Self = @This();

const max_append_size = 10_000;

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
    try parser.parse(self.content.items, &self.elements);
}

/// Sets the content of the document from a file and parses it into elements.
/// Clears any existing content and elements.
/// Accessing the document old elements after calling this function is undefined behavior.
pub fn setContentFromFile(
    self: *Self,
    /// The relative path to the file.
    rel_path: []const u8,
) !void {
    self.content.clearAndFree();
    var file = try std.fs.cwd().openFile(rel_path, .{});
    try file.reader().readAllArrayList(&self.content, max_append_size);
    self.elements.clearAndFree();
    try parser.parse(self.content.items, &self.elements);
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

    // try testing.expectEqual(4, elements.len);

    try testing.expectEqualSlices(u8, "Heading", elements[0].heading.text);
    try testing.expectEqual(1, elements[0].heading.level);

    try testing.expectEqualSlices(u8, "Subheading", elements[1].heading.text);
    try testing.expectEqual(2, elements[1].heading.level);

    try testing.expectEqualSlices(u8, "First item", elements[2].list.items()[0].bullet.text);
    try testing.expectEqual(1, elements[2].list.items().len);

    try testing.expectEqualSlices(u8, "Paragraph text", elements[3].paragraph.text);
}

test "from file" {
    const allocator = std.testing.allocator;
    var document = Self.init(allocator);
    defer document.deinit();
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    var file = try tmp_dir.dir.createFile("test_document.md", .{});
    var writer = file.writer();
    try writer.writeAll("# Heading\n");

    const path = try std.fs.path.join(
        allocator,
        &[_][]const u8{ ".zig-cache", "tmp", &tmp_dir.sub_path, "test_document.md" },
    );
    defer allocator.free(path);

    try document.setContentFromFile(path);
    const elements = document.elements.items;
    try testing.expectEqualSlices(u8, "# Heading\n", document.content.items);
    try testing.expectEqualSlices(u8, "Heading", elements[0].heading.text);
    try testing.expectEqual(1, elements[0].heading.level);
}
