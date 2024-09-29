const std = @import("std");
const elements = @import("elements.zig");

const startsWith = std.mem.startsWith;

const Element = @import("elements.zig").Element;

const ParserError = error{
    FrontmatterTooLong,
};

/// Parsed the content into Markdown elements.
pub fn parse(content: []const u8, element_list: *std.ArrayList(Element)) !void {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');

    try parseFrontmatter(&lines, element_list);

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        if (startsWith(u8, line, "#")) {
            try element_list.append(
                elements.Heading.parseElement(line),
            );
        } else if (startsWith(u8, line, "---")) {
            try element_list.append(
                .{ .horizontal_rule = elements.HorizontalRule{} },
            );
        } else if (startsWith(u8, line, "- ")) {
            try element_list.append(
                // TODO: Multiline list items
                try elements.List.parseElement(element_list.allocator, line),
            );
        } else {
            try element_list.append(
                // TODO: Multiline paragraphs
                elements.Paragraph.parseElement(line),
            );
        }
    }
}

fn parseFrontmatter(
    lines: *std.mem.TokenIterator(u8, .scalar),
    element_list: *std.ArrayList(Element),
) !void {
    if (lines.peek()) |start| {
        if (!std.mem.eql(u8, start, "---")) return;

        // TODO: Do not use a buffer here
        var buf: [200][]const u8 = undefined;
        var i: usize = 0;
        buf[i] = lines.next().?;
        i += 1;
        while (lines.next()) |line| {
            if (i == buf.len) {
                return ParserError.FrontmatterTooLong;
            }
            buf[i] = line;
            i += 1;
            if (!std.mem.eql(u8, line, "---")) continue;

            try element_list.append(
                try elements.Frontmatter.parseElement(
                    element_list.allocator,
                    buf[0..i],
                ),
            );
            break;
        }
    }
}

const testing = std.testing;

test "frontmatter" {
    const allocator = std.heap.page_allocator;
    var element_list = std.ArrayList(Element).init(allocator);
    const content =
        \\---
        \\title: Hello world!
        \\---
    ;

    try parse(content, &element_list);

    const element = element_list.items[0];
    switch (element) {
        .frontmatter => {
            const value = element.frontmatter.get("title");
            try testing.expect(value != null);
            try testing.expectEqualSlices(u8, "Hello world!", value.?);
        },
        else => unreachable,
    }
}
