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
            .list => |*l| l.deinit(),
            .paragraph => {},
            .horizontal_rule => {},
        }
    }

    /// Returns the content height of the element
    pub fn contentHight(self: Element) usize {
        switch (self) {
            .heading => |h| h.contentHight(),
            .list => |l| l.contentHight(),
            .paragraph => |p| p.contentHight(),
            .horizontal_rule => 1,
        }
    }

    /// Returns the content width of the element
    /// If multiple lines are present, returns the width of the longest line
    /// Horizontal rules always return 1
    pub fn contentWidth(self: Element) usize {
        switch (self) {
            .heading => |h| h.contentWidth(),
            .list => |l| l.contentWidth(),
            .paragraph => |p| p.contentWidth(),
            .horizontal_rule => 1,
        }
    }
};
