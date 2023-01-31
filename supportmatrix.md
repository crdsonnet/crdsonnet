# WIP: Support matrix

Huge WIP: Table should be split into parser/render/validator.

Keyword                Supported
const                  Yes
enum                   Yes
not                    Yes
allOf                  Yes
anyOf                  Yes
oneOf                  Yes
if-then-else           Yes
type                   Yes
minLength              Yes
maxLength              Yes
pattern                No [1]
format                 No [2]
multipleOf             Yes
minimum                Yes
maximum                Yes
exclusiveMinimum       Yes
exclusiveMaximum       Yes
patternProperties      No [1]
dependentRequired      No (to implement)
unevaluatedProperties  No [3]
additionalProperties   No [3]
properties             Yes
required               Yes
propertyNames          Yes
minProperties          Yes
maxProperties          Yes
minItems               Yes
maxItems               Yes
uniqueItems            Yes
prefixItems            Yes
items                  Yes
contains               Yes
minContains            Yes
maxContains            Yes
unevaluatedItems       No (to implement)


[1] Jsonnet has not native support for regular expressions.
[2] Depends on external vocabulary
[3] Depends on patternProperties to evaluate properly (see [1])
