const std = @import("std");

const Element = @import("../elements.zig").Element;
const Self = @This();

pub const ListItem = union(enum) {
    bullet: BulletListItem,
    numbered: NumberedListItem,

    pub fn children(self: *ListItem) *?Self {
        switch (self.*) {
            .bullet => return &self.bullet.children,
            .numbered => return &self.numbered.children,
        }
    }
};

pub const BulletListItem = struct {
    /// The first character of a bullet list item.
    pub const first_char = '-'; // TODO: Support multiple

    text: []const u8,
    children: ?Self = null, // TODO: Support nested lists
};

/// Individual list item.
pub const NumberedListItem = struct {
    text: []const u8,
    children: ?Self = null, // TODO: Support nested lists
};

/// List items in the list.
items: std.ArrayList(ListItem),

pub fn parse(allocator: std.mem.Allocator, lines: []const []const u8) !Self {
    var items = std.ArrayList(ListItem).init(allocator);
    var current_item: ?ListItem = null;

    for (lines) |line| {
        if (std.mem.startsWith(u8, line, "1. ")) {
            current_item = ListItem{
                .numbered = NumberedListItem{
                    .text = line[3..],
                },
            };
            try items.append(current_item.?);
        } else if (std.mem.startsWith(u8, line, "- ")) {
            current_item = ListItem{
                .bullet = BulletListItem{
                    .text = line[2..],
                },
            };
            try items.append(current_item.?);
        }
    }

    return Self{
        .items = items,
    };
}

pub fn parseElement(allocator: std.mem.Allocator, lines: []const []const u8) !Element {
    return .{ .list = try Self.parse(allocator, lines) };
}

/// Deinitializes the list, freeing all resources.
/// Freeing all created items and their children.
pub fn deinit(self: *Self) void {
    for (self.items.items) |*item| {
        if (item.children().*) |*children| {
            children.deinit();
        }
    }
    self.items.deinit();
}

const testing = std.testing;

test "parse" {
    const allocator = std.heap.page_allocator;
    var list = try Self.parse(allocator, &[_][]const u8{
        "- Item 1",
        "- Item 2",
    });
    defer list.deinit();

    try testing.expectEqual(2, list.items.items.len);
    try testing.expectEqualSlices(u8, "Item 1", list.items.items[0].bullet.text);
    try testing.expectEqualSlices(u8, "Item 2", list.items.items[1].bullet.text);
}
