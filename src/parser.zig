const std = @import("std");
const elements = @import("elements.zig");

const startsWith = std.mem.startsWith;

const Element = @import("elements.zig").Element;

/// Parsed the content into Markdown elements.
pub fn parse(content: []const u8, element_list: *std.ArrayList(Element)) !void {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');

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
