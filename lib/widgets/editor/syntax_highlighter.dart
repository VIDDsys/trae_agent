import 'package:flutter/material.dart';

class SyntaxHighlighter {
  static const Color kPlainColor = Color(0xFFE2E8F0);
  static const Color kKeywordColor = Color(0xFFFF7B72);
  static const Color kStringColor = Color(0xFFA5D6FF);
  static const Color kNumberColor = Color(0xFF79C0FF);
  static const Color kCommentColor = Color(0xFF8B949E);
  static const Color kTypeColor = Color(0xFFFFA657);
  static const Color kFunctionColor = Color(0xFFD2A8FF);
  static const Color kOperatorColor = Color(0xFFFF7B72);
  static const Color kPunctuationColor = Color(0xFFE2E8F0);
  static const Color kVariableColor = Color(0xFFFFA657);
  static const Color kAttributeColor = Color(0xFFFFA657);
  static const Color kTagColor = Color(0xFF7EE787);
  static const Color kBuiltinColor = Color(0xFFD2A8FF);
  static const Color kAnnotationColor = Color(0xFFD2A8FF);

  static final _TokenRule kDoubleQuote = _TokenRule(RegExp(r'"[^"]*"'), kStringColor);
  static final _TokenRule kSingleQuote = _TokenRule(RegExp(r"'[^']*'"), kStringColor);
  static final _TokenRule kNumber = _TokenRule(RegExp(r'\b(?:0[xX][0-9a-fA-F]+|[0-9]+\.[0-9]+|[0-9]+)\b'), kNumberColor);

  static TextSpan highlight(String code, String language) {
    switch (language.toLowerCase()) {
      case 'dart': return DartSyntaxHighlighter().highlight(code);
      case 'python': return PythonSyntaxHighlighter().highlight(code);
      case 'javascript':
      case 'js': return JavaScriptSyntaxHighlighter().highlight(code);
      case 'typescript':
      case 'ts': return TypeScriptSyntaxHighlighter().highlight(code);
      case 'java': return JavaSyntaxHighlighter().highlight(code);
      case 'kotlin': return KotlinSyntaxHighlighter().highlight(code);
      case 'rust':
      case 'rs': return RustSyntaxHighlighter().highlight(code);
      case 'go': return GoSyntaxHighlighter().highlight(code);
      case 'c': return CSyntaxHighlighter().highlight(code);
      case 'cpp':
      case 'c++': return CppSyntaxHighlighter().highlight(code);
      case 'html': return HtmlSyntaxHighlighter().highlight(code);
      case 'css': return CssSyntaxHighlighter().highlight(code);
      case 'json': return JsonSyntaxHighlighter().highlight(code);
      case 'yaml':
      case 'yml': return YamlSyntaxHighlighter().highlight(code);
      case 'sql': return SqlSyntaxHighlighter().highlight(code);
      case 'bash':
      case 'sh': return BashSyntaxHighlighter().highlight(code);
      default: return TextSpan(text: code, style: const TextStyle(color: kPlainColor));
    }
  }
}

class _TokenRule {
  final RegExp pattern;
  final Color color;
  const _TokenRule(this.pattern, this.color);
}

TextSpan _buildSpans(String code, List<_TokenRule> rules, Color defaultColor) {
  final spans = <TextSpan>[];
  int pos = 0;

  while (pos < code.length) {
    int earliestMatch = code.length;
    _TokenRule? matchedRule;
    Match? matched;

    for (final rule in rules) {
      final m = rule.pattern.matchAsPrefix(code, pos);
      if (m != null && m.start < earliestMatch) {
        earliestMatch = m.start;
        matchedRule = rule;
        matched = m;
        if (earliestMatch == pos) break;
      }
    }

    if (matchedRule != null && matched != null) {
      if (earliestMatch > pos) {
        spans.add(TextSpan(
          text: code.substring(pos, earliestMatch),
          style: TextStyle(color: defaultColor),
        ));
      }
      spans.add(TextSpan(
        text: matched.group(0),
        style: TextStyle(color: matchedRule.color),
      ));
      pos = earliestMatch + matched.group(0)!.length;
    } else {
      spans.add(TextSpan(
        text: code.substring(pos),
        style: TextStyle(color: defaultColor),
      ));
      break;
    }
  }
  return TextSpan(children: spans);
}

// ==================== LANGUAGE DEFINITIONS ====================

class DartSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:import|export|library|part|of|class|extends|implements|with|mixin|abstract|typedef|enum|final|const|var|void|int|double|num|bool|String|dynamic|Future|Stream|async|await|return|if|else|for|while|do|switch|case|default|break|continue|throw|try|catch|finally|new|this|super|static|factory|override|required|late|covariant|is|as|in|null|true|false|null|assert|rethrow)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    _TokenRule(RegExp(r"'''[\s\S]*?'''"), SyntaxHighlighter.kStringColor),
    _TokenRule(RegExp(r'r"[^"]*"'), SyntaxHighlighter.kStringColor),
    _TokenRule(RegExp(r"r'[^']*'"), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class PythonSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'#[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'"""(?:[^"]*(?:""?)?)*"""'), SyntaxHighlighter.kStringColor),
    _TokenRule(RegExp(r"'''(?:[^']*(?:''?)?)*'''"), SyntaxHighlighter.kStringColor),
    _TokenRule(RegExp(r'\b(?:def|class|return|if|elif|else|for|while|try|except|finally|with|as|import|from|pass|break|continue|raise|yield|lambda|self|None|True|False|and|or|not|in|is|async|await|print|len|range|int|float|str|bool|list|dict|set|tuple|type|super|global|nonlocal|del|assert)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class JavaScriptSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:const|let|var|function|return|if|else|for|while|do|switch|case|break|continue|new|this|class|extends|import|export|from|async|await|try|catch|finally|throw|typeof|instanceof|in|of|null|undefined|true|false|yield|delete|void)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    _TokenRule(RegExp(r'`[^`]*`'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class TypeScriptSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:const|let|var|function|return|if|else|for|while|do|switch|case|break|continue|new|this|class|extends|implements|import|export|from|async|await|try|catch|finally|throw|typeof|instanceof|in|of|null|undefined|true|false|yield|type|interface|enum|namespace|module|declare|readonly|public|private|protected|abstract|static|keyof)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    _TokenRule(RegExp(r'`[^`]*`'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class JavaSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:public|private|protected|static|final|class|interface|extends|implements|abstract|new|this|super|return|if|else|for|while|do|switch|case|break|continue|try|catch|finally|throw|import|package|void|int|long|double|float|boolean|char|byte|short|String|List|Map|Set|ArrayList|HashMap|HashSet|true|false|null|instanceof|enum|record|var|synchronized|volatile|transient|native|strictfp)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class KotlinSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:fun|val|var|class|object|interface|abstract|open|override|private|public|protected|internal|data|sealed|enum|companion|init|constructor|import|package|return|if|else|for|while|do|when|try|catch|finally|throw|break|continue|new|this|super|null|true|false|is|as|in|typealias|inline|infix|suspend|lateinit|lazy|let|apply|run|also|with)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    _TokenRule(RegExp(r'"""[^"]*"""'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class RustSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:fn|let|mut|const|static|struct|enum|impl|trait|use|mod|crate|pub|super|self|return|if|else|for|while|loop|match|break|continue|unsafe|async|await|true|false|Some|None|Ok|Err|where|as|in|ref|move|dyn|type|macro_rules|derive|extern|abstract|final|override|typeof|box|virtual|yield|union|all|any|not|and|or)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    _TokenRule(RegExp(r'r#"[^"]*"#'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class GoSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:func|var|const|type|struct|interface|map|chan|go|defer|select|range|return|if|else|for|switch|case|break|continue|fallthrough|default|import|package|true|false|nil|make|new|len|cap|append|copy|close|delete|panic|recover|int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|string|bool|byte|rune|complex64|complex128|error)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    _TokenRule(RegExp(r'`[^`]*`'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class CSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:if|else|for|while|do|switch|case|break|continue|return|goto|typedef|struct|union|enum|const|static|extern|register|volatile|auto|sizeof|int|long|short|char|float|double|void|unsigned|signed|true|false|NULL|include|define|ifdef|ifndef|endif|pragma)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class CppSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'//[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:class|public|private|protected|virtual|override|explicit|constexpr|nullptr|template|typename|namespace|using|new|delete|throw|try|catch|noexcept|auto|decltype|static_cast|dynamic_cast|reinterpret_cast|const_cast|this|friend|operator|inline|export|mutable|volatile|asm|alignas|alignof|and|or|not|xor|bitand|bitor|compl)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class HtmlSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'<!--[\s\S]*?-->'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'</?[a-zA-Z][a-zA-Z0-9]*'), SyntaxHighlighter.kTagColor),
    _TokenRule(RegExp(r'(?<=<)[^>]+(?=>)'), SyntaxHighlighter.kAttributeColor),
    _TokenRule(RegExp(r'"[^"]*"'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kSingleQuote,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class CssSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'"[^"]*"'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class JsonSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kNumber,
    _TokenRule(RegExp(r'\b(?:true|false|null)\b'), SyntaxHighlighter.kKeywordColor),
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class YamlSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'#[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*:', multiLine: true), SyntaxHighlighter.kAttributeColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
  ] as List<_TokenRule>;

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class SqlSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'--[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:SELECT|FROM|WHERE|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|DROP|ALTER|INDEX|VIEW|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AND|OR|NOT|IN|LIKE|BETWEEN|IS|NULL|AS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|UNION|ALL|DISTINCT|COUNT|SUM|AVG|MIN|MAX|EXISTS|CASE|WHEN|THEN|ELSE|END|BEGIN|COMMIT|ROLLBACK|PRIMARY|KEY|FOREIGN|REFERENCES|CASCADE|INT|VARCHAR|TEXT|BOOLEAN|DATE|FLOAT|INTEGER|BOOLEAN)\b', caseSensitive: false), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    SyntaxHighlighter.kNumber,
  ] as List<_TokenRule>;

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}

class BashSyntaxHighlighter {
  static final List<_TokenRule> _rules = [
    _TokenRule(RegExp(r'#[^\n]*'), SyntaxHighlighter.kCommentColor),
    _TokenRule(RegExp(r'\b(?:if|then|else|elif|fi|for|while|do|done|case|esac|function|return|exit|break|continue|export|local|readonly|unset|declare|typeset|set|unset|read|echo|printf|source|\.|exec|eval|let|shift|select)\b'), SyntaxHighlighter.kKeywordColor),
    SyntaxHighlighter.kDoubleQuote,
    SyntaxHighlighter.kSingleQuote,
    _TokenRule(RegExp(r'`[^`]*`'), SyntaxHighlighter.kStringColor),
    SyntaxHighlighter.kNumber,
  ];

  TextSpan highlight(String code) => _buildSpans(code, _rules, SyntaxHighlighter.kPlainColor);
}
