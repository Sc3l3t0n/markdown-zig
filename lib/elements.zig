/// Represents a Heading element in Markdown
pub const Heading = @import("elements/heading.zig");

/// Represents a List element in Markdown
pub const List = @import("elements/list.zig");

/// Represents a Paragraph element in Markdown
pub const Paragraph = @import("elements/paragraph.zig");

/// Represents a Horizontal Rule element in Markdown
pub const HorizontalRule = struct {};

/// Union of all element types in Markdown
pub const Element = union(enum) {
    heading: Heading,
    list: List,
    paragraph: Paragraph,
    horizontal_rule: HorizontalRule,

    /// Deinitializes the element
    /// Only necessary for elements that contain other elements
    /// Safe to call on all elements
    pub fn deinit(self: *Element) void {
        switch (self.*) {
            .heading => {},
            .list => self.list.deinit(),
            .paragraph => {},
            .horizontal_rule => {},
        }
    }
};
