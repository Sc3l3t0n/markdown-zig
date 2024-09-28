const std = @import("std");
const utils = @import("../utils.zig");

const Element = @import("../elements.zig").Element;
const List = @This();

pub const ListParseError = error{
    InvalidListPrefix,
} || std.mem.Allocator.Error;

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

/// ArrayList of Listitems in the list.
/// Use items() instead of directly accessing the items field.
item_list: std.ArrayList(ListItem),

/// Parses the list and returns it.
pub fn parse(
    /// The allocator to use for the list
    allocator: std.mem.Allocator,
    /// Line ot the list
    line: []const u8,
) ListParseError!List {
    var item_list = std.ArrayList(ListItem).init(allocator);

    if (std.mem.startsWith(u8, line, "- ")) {
        try item_list.append(ListItem{
            .bullet = BulletListItem{
                .text = line[2..],
            },
        });
    } else {
        var split = std.mem.splitScalar(u8, line, ' ');
        var prefix = split.first();
        if (!std.mem.endsWith(u8, prefix, ".")) {
            return ListParseError.InvalidListPrefix;
        }

        const number = std.fmt.parseInt(u64, prefix[0 .. prefix.len - 1], 10) catch {
            return ListParseError.InvalidListPrefix;
        };

        try item_list.append(ListItem{
            // TODO: Parse number
            .numbered = NumberedListItem{
                .text = line[prefix.len + 1 ..],
                .number = number,
            },
        });
    }

    return List{
        .item_list = item_list,
    };
}

/// Parses the list and returns an element.
pub fn parseElement(allocator: std.mem.Allocator, line: []const u8) !Element {
    return .{ .list = try List.parse(allocator, line) };
}

/// Returns the list items.
pub fn items(self: *List) []ListItem {
    return self.item_list.items;
}

/// Deinitializes the list, freeing all resources.
/// Freeing all created items and their children.
pub fn deinit(self: *List) void {
    for (self.item_list.items) |*item| {
        if (item.children().*) |*children| {
            children.deinit();
        }
    }
    self.item_list.deinit();
}

const testing = std.testing;

test "parse" {
    const allocator = std.heap.page_allocator;
    var list = try List.parse(
        allocator,
        "- Item 1",
    );
    defer list.deinit();

    try testing.expectEqual(1, list.items().len);
    try testing.expectEqualSlices(u8, "Item 1", list.items()[0].bullet.text);
}

test "parse numbered" {
    const allocator = std.heap.page_allocator;
    var list = try List.parse(
        allocator,
        "1. Item 1",
    );
    defer list.deinit();
    try testing.expectEqual(1, list.items().len);
    try testing.expectEqualSlices(u8, "Item 1", list.items()[0].numbered.text);
    try testing.expectEqual(1, list.items()[0].numbered.number);
}

test "parse numbered error" {
    const allocator = std.heap.page_allocator;
    const err = List.parse(
        allocator,
        "aw. Item 1",
    );
    try testing.expectEqual(ListParseError.InvalidListPrefix, err);
}
