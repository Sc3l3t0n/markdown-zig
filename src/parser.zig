const std = @import("std");
const elements = @import("elements.zig");

const Element = @import("elements.zig").Element;

/// Parsed the content into Markdown elements.
pub fn parse(content: []const u8, element_list: *std.ArrayList(Element)) !void {
    var lines = std.mem.tokenizeScalar(u8, content, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        if (line[0] == elements.Heading.first_char) {
            try element_list.append(
                elements.Heading.parseElement(line),
            );
            continue;
        }
        if (line[0] == '-') {
            try element_list.append(
                // TODO: Multiline list items
                try elements.List.parseElement(element_list.allocator, &[1][]const u8{line}),
            );
            continue;
        }
        try element_list.append(
            // TODO: Multiline paragraphs
            elements.Paragraph.parseElement(line),
        );
    }
}
