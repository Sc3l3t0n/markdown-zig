const std = @import("std");
const elements = @import("elements.zig");
const utils = @import("utils.zig");

const startsWith = std.mem.startsWith;

const Element = @import("elements.zig").Element;
const Frontmatter = @import("addons.zig").Frontmatter;

/// Parsed the content into Markdown elements.
pub fn parse(content: []const u8, element_list: *std.ArrayList(Element)) !void {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');

    skipFrontmatter(&lines);

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

/// Skips the frontmatter if it exists
fn skipFrontmatter(lines: *std.mem.TokenIterator(u8, .scalar)) void {
    if (lines.peek()) |start| {
        if (!startsWith(u8, start, "---")) return;
        while (lines.next()) |line| {
            if (startsWith(u8, line, "---")) break;
        }
    }
}

/// Parses the frontmatter of the content.
pub fn parseFrontmatter(
    allocator: std.mem.Allocator,
    content: []const u8,
) !?Frontmatter {
    var lines = std.mem.splitScalar(u8, content, '\n');

    if (lines.next()) |start| {
        if (!std.mem.eql(u8, start, "---")) return Frontmatter.FrontMatterParseError.InvalidBegin;

        while (lines.next()) |line| {
            if (!std.mem.eql(u8, line, "---")) continue;

            const len = content.len - lines.rest().len;
            return try Frontmatter.parse(
                allocator,
                content[0..len],
            );
        }
    }
    return Frontmatter.FrontMatterParseError.InvalidEnd;
}

const testing = std.testing;

test "frontmatter" {
    const allocator = std.heap.page_allocator;
    const content =
        \\---
        \\title: Hello world!
        \\---
    ;

    var fm = try parseFrontmatter(allocator, content);
    defer fm.deinit();

    const value = fm.get("title");
    try testing.expect(value != null);
    try testing.expectEqualSlices(u8, "Hello world!", value.?);
}
