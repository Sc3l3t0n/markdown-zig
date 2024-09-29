pub fn SliceIterator(T: type) type {
    return struct {
        const Self = @This();

        items: []const T,
        current_index: usize,

        pub fn init(items: []const T) Self {
            return Self{
                .items = items,
                .current_index = 0,
            };
        }

        pub fn next(self: *Self) ?T {
            if (self.current_index >= self.items.len) {
                return null;
            }
            const item = self.items[self.current_index];
            self.current_index += 1;
            return item;
        }

        pub fn peek(self: *Self) ?T {
            if (self.current_index >= self.items.len) {
                return null;
            }
            return self.items[self.current_index];
        }

        pub fn reset(self: *Self) void {
            self.current_index = 0;
        }

        pub fn rest(self: *Self) []const T {
            return self.items[self.current_index..];
        }
    };
}

const testing = @import("std").testing;

test "next" {
    const items = [_]u8{ 1, 2, 3 };
    var iter = SliceIterator(u8).init(&items);
    try testing.expectEqual(1, iter.next());
    try testing.expectEqual(2, iter.next());
    try testing.expectEqual(3, iter.next());
    try testing.expectEqual(null, iter.next());
}

test "peek" {
    const items = [_]u8{ 1, 2, 3 };
    var iter = SliceIterator(u8).init(&items);
    try testing.expectEqual(1, iter.peek());
    try testing.expectEqual(1, iter.peek());
    try testing.expectEqual(1, iter.next());
    try testing.expectEqual(2, iter.peek());
    try testing.expectEqual(2, iter.next());
    try testing.expectEqual(3, iter.peek());
    try testing.expectEqual(3, iter.next());
    try testing.expectEqual(null, iter.peek());
}

test "reset" {
    const items = [_]u8{ 1, 2, 3 };
    var iter = SliceIterator(u8).init(&items);
    try testing.expectEqual(1, iter.next());
    try testing.expectEqual(2, iter.next());
    iter.reset();
    try testing.expectEqual(1, iter.next());
    try testing.expectEqual(2, iter.next());
    try testing.expectEqual(3, iter.next());
    try testing.expectEqual(null, iter.next());
}

test "rest" {
    const items = [_]u8{ 1, 2, 3 };
    var iter = SliceIterator(u8).init(&items);
    try testing.expectEqual(1, iter.next());
    try testing.expectEqual(items[1..], iter.rest());
    try testing.expectEqual(2, iter.next());
}
