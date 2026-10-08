;; extends

(enum_declaration
  name: (identifier) @type.enum)

(enum_body
  (property_identifier) @variable.member.enum)

(enum_assignment
  name: (property_identifier) @variable.member.enum)

(import_clause
  (identifier) @variable.import)

;; Recognize PascalCase.PascalCase as Enum.EnumMember when referred to later
((member_expression
  object: (identifier) @type.enum
  property: (property_identifier) @variable.member.enum)
 (#match? @type.enum "^[A-Z]")
 (#match? @variable.member.enum "^[A-Z]"))
