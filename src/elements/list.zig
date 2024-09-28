const std = @import("std");
const utils = @import("../utils.zig");

const Element = @import("../elements.zig").Element;
const List = @This();

pub const ListItem = union(enum) {
    bullet: BulletListItem,
    numbered: NumberedListItem,

    pub fn text(self: *ListItem) []const u8 {
        return switch (self.*) {
            .bullet => self.bullet.text,
            .numbered => self.numbered.text,
        };
    }

    pub fn children(self: *ListItem) *?List {
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
    children: ?List = null, // TODO: Support nested lists
};

/// Individual list item.
pub const NumberedListItem = struct {
    text: []const u8,
    number: u64,
    children: ?List = null, // TODO: Support nested lists
};

/// List items in the list.
item_list: std.ArrayList(ListItem),

/// Parses the list and returns it.
pub fn parse(
    /// The allocator to use for the list
    allocator: std.mem.Allocator,
    /// All lines of the list
    lines: []const []const u8,
) !List {
    var item_list = std.ArrayList(ListItem).init(allocator);
    var iter = utils.SliceIterator([]const u8).init(lines);

    while (iter.next()) |line| {
        if (std.mem.startsWith(u8, line, "1. ")) {
            try item_list.append(ListItem{
                // TODO: Parse number
                .numbered = NumberedListItem{
                    .text = line[3..],
                    .number = 1,
                },
            });
        } else if (std.mem.startsWith(u8, line, "- ")) {
            try item_list.append(ListItem{
                .bullet = BulletListItem{
                    .text = line[2..],
                },
            });
        }
    }

    return List{
        .items = items,
    };
}

pub fn parseElement(allocator: std.mem.Allocator, lines: []const []const u8) !Element {
    return .{ .list = try List.parse(allocator, lines) };
}

pub fn items(self: *List) []ListItem {
    return self.items.items;
}

/// Deinitializes the list, freeing all resources.
/// Freeing all created items and their children.
pub fn deinit(self: *List) void {
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
    var list = try List.parse(allocator, &[_][]const u8{
        "- Item 1",
        "- Item 2",
    });
    defer list.deinit();

    try testing.expectEqual(2, list.items.items.len);
    try testing.expectEqualSlices(u8, "Item 1", list.items.items[0].bullet.text);
    try testing.expectEqualSlices(u8, "Item 2", list.items.items[1].bullet.text);
}
