// Based on https://github.com/fatih/camelcase/

{
  split:: split,

  local isLower(c) =
    local cp(c) = std.codepoint(c);
    if cp(c) >= 97 && cp(c) < 123
    then true
    else false,

  local isUpper(c) =
    local cp(c) = std.codepoint(c);
    if cp(c) >= 65 && cp(c) < 91
    then true
    else false,

  local isNumber(c) =
    local cp(c) = std.codepoint(c);
    if std.isNumber(c) || (cp(c) >= 48 && cp(c) < 58)
    then true
    else false,

  local split(src) =
    if src == ''
    then ['']
    else
      local runes = std.foldl(
        function(acc, r)
          acc {
            local class =
              if isNumber(r)
              then 1
              else if isLower(r)
              then 2
              else if isUpper(r)
              then 3
              else 4,

            lastClass:: class,

            runes:
              if
                //std.trace(r + ' : ' + class + ' ' + super.lastClass,
                class == super.lastClass
              //)
              then super.runes[:std.length(super.runes) - 1]
                   + [super.runes[std.length(super.runes) - 1] + r]
              else super.runes + [r],
          },
        [src[i] for i in std.range(0, std.length(src) - 1)],
        { lastClass:: 0, runes: [] }
      ).runes;

      local fixRunes =
        std.foldl(
          function(runes, i)
            if runes[i][0] == std.asciiUpper(runes[i][0])
               && runes[i + 1][0] == std.asciiLower(runes[i + 1][0])
               && !std.member(['' + i for i in std.range(0, 9)], runes[i + 1][0])
               && runes[i][0] != ' '
               && runes[i + 1][0] != ' '
            then
              std.mapWithIndex(
                function(index, r)
                  if index == i + 1
                  then runes[i][std.length(runes[i]) - 1:] + r
                  else
                    if index == i
                    then r[:std.length(r) - 1]
                    else r
                , runes
              )
            else runes
          ,
          [i for i in std.range(0, std.length(runes) - 2)],
          runes
        );

      [
        r
        for r in fixRunes
        if r != ''
      ],

  tests: {
    nostring: split('') == [''],
    lowercase: split('lowercase') == ['lowercase'],
    Class: split('Class') == ['Class'],
    MyClass: split('MyClass') == ['My', 'Class'],
    MyC: split('MyC') == ['My', 'C'],
    HTML: split('HTML') == ['HTML'],
    PDFLoader: split('PDFLoader') == ['PDF', 'Loader'],
    AString: split('AString') == ['A', 'String'],
    SimpleXMLParser: split('SimpleXMLParser') == ['Simple', 'XML', 'Parser'],
    vimRPCPlugin: split('vimRPCPlugin') == ['vim', 'RPC', 'Plugin'],
    GL11Version: split('GL11Version') == ['GL', '11', 'Version'],
    '99Bottles': split('99Bottles') == ['99', 'Bottles'],
    May5: split('May5') == ['May', '5'],
    BFG9000: split('BFG9000') == ['BFG', '9000'],
    'Two  spaces': split('Two  spaces') == ['Two', '  ', 'spaces'],
    'Multiple   Random  spaces': split('Multiple   Random  spaces') == ['Multiple', '   ', 'Random', '  ', 'spaces'],

    // TODO: find or create is(Upper|Lower) for non-ascii characters
    // Something like this for Jsonnet: https://cs.opensource.google/go/go/+/refs/tags/go1.17.3:src/unicode/tables.go
    //'BöseÜberraschung': split('BöseÜberraschung') == ['Böse', 'Überraschung'],

    // This doesn't even render in Jsonnet
    //"BadUTF8\xe2\xe2\xa1": split("BadUTF8\xe2\xe2\xa1") ==  ["BadUTF8\xe2\xe2\xa1"],
  },
}
