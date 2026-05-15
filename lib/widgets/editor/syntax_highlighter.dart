import 'package:flutter/material.dart';

class SyntaxHighlighter {
  static SyntaxHighlighter? _forLanguage(String? language) {
    switch (language?.toLowerCase()) {
      case 'dart': return DartSyntaxHighlighter();
      case 'python': case 'py': return PythonSyntaxHighlighter();
      case 'javascript': case 'js': case 'jsx': case 'ts': case 'tsx': return JavaScriptSyntaxHighlighter();
      case 'java': return JavaSyntaxHighlighter();
      case 'kotlin': case 'kt': return KotlinSyntaxHighlighter();
      case 'swift': return SwiftSyntaxHighlighter();
      case 'rust': case 'rs': return RustSyntaxHighlighter();
      case 'go': return GoSyntaxHighlighter();
      case 'c': case 'cpp': case 'csharp': case 'cs': return CSyntaxHighlighter();
      case 'html': return HtmlSyntaxHighlighter();
      case 'css': return CssSyntaxHighlighter();
      case 'json': return JsonSyntaxHighlighter();
      case 'yaml': case 'yml': return YamlSyntaxHighlighter();
      case 'markdown': case 'md': return MarkdownSyntaxHighlighter();
      case 'sql': return SqlSyntaxHighlighter();
      case 'bash': case 'sh': return BashSyntaxHighlighter();
      default: return null;
    }
  }

  static TextSpan highlight(String code, String? language) {
    final highlighter = _forLanguage(language);
    if (highlighter == null) {
      return TextSpan(
        text: code,
        style: const TextStyle(
          color: Color(0xFFE6EDF3),
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      );
    }
    return highlighter._highlight(code);
  }

  TextSpan _highlight(String code) => TextSpan(text: code);

  static const kKeywordColor = Color(0xFF7C3AED);
  static const kStringColor = Color(0xFF34D399);
  static const kNumberColor = Color(0xFFF59E0B);
  static const kCommentColor = Color(0xFF6B7280);
  static const kTypeColor = Color(0xFF38BDF8);
  static const kFunctionColor = Color(0xFFFBBF24);
  static const kOperatorColor = Color(0xFFE8E8E8);
  static const kPunctuationColor = Color(0xFF9CA3AF);
  static const kVariableColor = Color(0xFFE6EDF3);
  static const kAttributeColor = Color(0xFFA78BFA);
  static const kTagColor = Color(0xFFEF4444);
  static const kBuiltinColor = Color(0xFF60A5FA);
  static const kAnnotationColor = Color(0xFFA855F7);
  static const kPlainColor = Color(0xFFE6EDF3);

  static const kBaseStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.5,
  );

  List<TextSpan> _tokenize(String code, List<_TokenRule> rules) {
    final spans = <TextSpan>[];
    int i = 0;
    while (i < code.length) {
      bool matched = false;
      for (final rule in rules) {
        final match = rule.pattern.matchAsPrefix(code, i);
        if (match != null) {
          spans.add(TextSpan(
            text: match.group(0),
            style: kBaseStyle.copyWith(color: rule.color),
          ));
          i += match.group(0)!.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        final char = code[i];
        final color = char == '\n' ? kPlainColor : kPlainColor;
        spans.add(TextSpan(
          text: char,
          style: kBaseStyle.copyWith(color: color),
        ));
        i++;
      }
    }
    return spans;
  }
}

class _TokenRule {
  final RegExp pattern;
  final Color color;
  const _TokenRule(this.pattern, this.color);
}

class DartSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"""[\s\S]*?"""'), kStringColor),
      _TokenRule(RegExp(r"'''[\s\S]*?'''"), kStringColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'r"[^"]*"|r\'[^\']*\''), kStringColor),
      _TokenRule(RegExp(r'\b(?:import|export|library|part|of|as|show|hide|abstract|class|extends|implements|mixin|with|enum|typedef|extension|on|covariant|@override|@deprecated|@required|late|final|const|var|void|int|double|num|String|bool|dynamic|Null|Object|Future|Stream|List|Set|Map|Record|never|throw|rethrow|try|catch|on|finally|return|break|continue|if|else|for|while|do|switch|case|default|assert|async|await|yield|sync|static|external|factory|get|set|operator|new|this|super|true|false|null|is|is!|as|in)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b(?:print|printError|printToConsole|identical|identityHashCode|identical|runtimeType|hashCode|toString|noSuchMethod|runtimeType)\b'), kBuiltinColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'@\w+'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class PythonSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'#.*'), kCommentColor),
      _TokenRule(RegExp(r'"""[\s\S]*?"""'), kStringColor),
      _TokenRule(RegExp(r"'''[\s\S]*?'''"), kStringColor),
      _TokenRule(RegExp(r'[fF]?(?:"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\')'), kStringColor),
      _TokenRule(RegExp(r'\b(?:def|class|if|elif|else|for|while|try|except|finally|with|as|import|from|pass|break|continue|return|yield|lambda|and|or|not|is|in|True|False|None|raise|async|await|global|nonlocal|del|assert|self|super)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b(?:print|len|range|int|str|float|list|dict|set|tuple|bool|open|sorted|enumerate|zip|map|filter|type|isinstance|hasattr|getattr|setattr|super|object|staticmethod|classmethod|property)\b'), kBuiltinColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'@\w+'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class JavaScriptSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'`(?:[^`\\]|\\.)*`'), kStringColor),
      _TokenRule(RegExp(r'/(?:[^/\\\n]|\\.)+/[gimsuy]*'), kStringColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'\b(?:const|let|var|function|class|extends|implements|interface|type|enum|import|export|from|default|async|await|yield|return|if|else|for|while|do|switch|case|break|continue|try|catch|finally|throw|new|this|super|typeof|instanceof|void|delete|in|of|true|false|null|undefined|NaN)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b(?:console|Math|JSON|Promise|Array|Object|String|Number|Boolean|Map|Set|Symbol|Date|RegExp|Error|setTimeout|setInterval|fetch|document|window|module|require|process)\b'), kBuiltinColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_$]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:?]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class JavaSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)'"), kStringColor),
      _TokenRule(RegExp(r'\b(?:public|private|protected|static|final|abstract|class|interface|extends|implements|enum|import|package|void|int|long|double|float|boolean|char|byte|short|null|true|false|if|else|for|while|do|switch|case|break|continue|return|throw|throws|try|catch|finally|new|this|super|synchronized|volatile|transient|native|strictfp|assert|default|instanceof|var|record|sealed|permits)\b'), kKeywordColor),
      _TokenRule(RegExp(r'@\w+'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?[fFdD]?\b'), kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class KotlinSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"""[\s\S]*?"""'), kStringColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)'"), kStringColor),
      _TokenRule(RegExp(r'\b(?:fun|val|var|class|object|companion|interface|enum|sealed|data|inner|abstract|open|override|private|protected|internal|public|final|lateinit|init|constructor|import|package|as|typealias|where|if|else|when|for|while|do|try|catch|finally|throw|return|break|continue|null|true|false|is|!is|in|!in|as|as?|this|super|suspend|tailrec|crossinline|noinline|inline|operator|infix|vararg|annotation|reified|expect|actual)\b'), kKeywordColor),
      _TokenRule(RegExp(r'@\w+'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class SwiftSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)'"), kStringColor),
      _TokenRule(RegExp(r'\b(?:func|var|let|class|struct|enum|protocol|extension|init|deinit|import|as|is|if|else|guard|for|while|repeat|switch|case|break|continue|return|throw|throws|rethrows|try|catch|do|where|true|false|nil|self|super|in|out|inout|public|private|fileprivate|internal|open|static|final|override|weak|unowned|lazy|mutating|nonmutating|required|optional|convenience|dynamic|available|async|await|actor|nonisolated|isolated|some|any)\b'), kKeywordColor),
      _TokenRule(RegExp(r'@\w+'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class RustSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'r#?"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)'"), kStringColor),
      _TokenRule(RegExp(r'\b(?:fn|let|mut|const|static|struct|enum|trait|impl|type|mod|use|crate|self|super|pub|unsafe|async|await|move|ref|return|if|else|for|while|loop|match|break|continue|where|as|in|true|false|Some|None|Ok|Err|Box|Vec|String|Option|Result|dyn|impl|abstract|become|box|do|final|macro|override|priv|typeof|unsized|virtual|yield)\b'), kKeywordColor),
      _TokenRule(RegExp(r'#!?\[.*?\]'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'\b0[xXoObB][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class GoSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r'`[^`]*`'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)'"), kStringColor),
      _TokenRule(RegExp(r'\b(?:func|struct|interface|map|chan|go|defer|select|package|import|type|var|const|return|if|else|for|range|switch|case|break|continue|fallthrough|default|goto|nil|true|false|make|new|append|len|cap|copy|close|delete|panic|recover|print|println|error|string|int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|complex64|complex128|byte|rune|bool|uintptr)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class CSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'//.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)'"), kStringColor),
      _TokenRule(RegExp(r'@"(?:[^"]|"")*"'), kStringColor),
      _TokenRule(RegExp(r'\b(?:int|long|double|float|char|bool|void|string|var|dynamic|object|byte|short|uint|ulong|ushort|nint|nuint|null|true|false|if|else|for|foreach|while|do|switch|case|break|continue|return|throw|try|catch|finally|class|struct|interface|enum|record|new|this|base|base|as|is|in|out|ref|readonly|const|static|virtual|override|abstract|sealed|async|await|yield|lock|checked|unchecked|unsafe|fixed|stackalloc|sizeof|nameof|using|namespace|public|private|protected|internal|partial|extern|event|delegate|operator|implicit|explicit|get|set|value|add|remove|where|select|from|let|join|on|equals|into|orderby|ascending|descending|group|by|namespace)\b'), kKeywordColor),
      _TokenRule(RegExp(r'@\w+'), kAnnotationColor),
      _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9]*\b'), kTypeColor),
      _TokenRule(RegExp(r'\b[a-z_]\w*(?=\s*\()'), kFunctionColor),
      _TokenRule(RegExp(r'\b0[xX][0-9a-fA-F]+\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:[eE][+-]?\d+)?[fFdDmM]?\b'), kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class HtmlSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'<!--[\s\S]*?-->'), kCommentColor),
      _TokenRule(RegExp(r'<[a-zA-Z][a-zA-Z0-9]*'), kTagColor),
      _TokenRule(RegExp(r'</[a-zA-Z][a-zA-Z0-9]*>'), kTagColor),
      _TokenRule(RegExp(r'/>'), kTagColor),
      _TokenRule(RegExp(r'\b[a-zA-Z-]+(?=\s*=)'), kAttributeColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'[{}]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class CssSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'#[0-9a-fA-F]{3,8}\b'), kNumberColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*(?:px|em|rem|vh|vw|%|s|ms)?\b'), kNumberColor),
      _TokenRule(RegExp(r'(?:https?:\/\/[^\s;)]+)'), kStringColor),
      _TokenRule(RegExp(r'[.#]?[a-zA-Z][a-zA-Z0-9_-]*(?=\s*{)'), kTagColor),
      _TokenRule(RegExp(r'\b[a-zA-Z-]+(?=\s*:)'), kAttributeColor),
      _TokenRule(RegExp(r'[{};:]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class JsonSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"(?=\s*:)'), kAttributeColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r'\b(?:true|false|null)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b-?\d+\.?\d*(?:[eE][+-]?\d+)?\b'), kNumberColor),
      _TokenRule(RegExp(r'[{}[\]],:'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class YamlSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'#.*'), kCommentColor),
      _TokenRule(RegExp(r'---'), kPunctuationColor),
      _TokenRule(RegExp(r'\.\.\.'), kPunctuationColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\s*):', multiLine: true), kAttributeColor),
      _TokenRule(RegExp(r'^\s*[a-zA-Z][a-zA-Z0-9_]*(\s*):', multiLine: true), kAttributeColor),
      _TokenRule(RegExp(r'\b(?:true|false|yes|no|on|off|null)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*\b'), kNumberColor),
      _TokenRule(RegExp(r'[{}[\]],:-'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class MarkdownSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'^#{1,6}\s.*', multiLine: true), kKeywordColor),
      _TokenRule(RegExp(r'\*\*.*?\*\*'), kKeywordColor),
      _TokenRule(RegExp(r'__.*?__'), kKeywordColor),
      _TokenRule(RegExp(r'\*.*?\*'), kFunctionColor),
      _TokenRule(RegExp(r'_.*?_'), kFunctionColor),
      _TokenRule(RegExp(r'`[^`]+`'), kStringColor),
      _TokenRule(RegExp(r'```[\s\S]*?```'), kStringColor),
      _TokenRule(RegExp(r'!?\[.*?\]\(.*?\)'), kTagColor),
      _TokenRule(RegExp(r'^[-*+]\s', multiLine: true), kPunctuationColor),
      _TokenRule(RegExp(r'^\d+\.\s', multiLine: true), kNumberColor),
      _TokenRule(RegExp(r'^>\s', multiLine: true), kCommentColor),
      _TokenRule(RegExp(r'^---+', multiLine: true), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class SqlSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'--.*'), kCommentColor),
      _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), kCommentColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r'\b(?:SELECT|FROM|WHERE|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|DROP|ALTER|ADD|COLUMN|INDEX|VIEW|JOIN|LEFT|RIGHT|INNER|OUTER|CROSS|ON|AND|OR|NOT|IN|BETWEEN|LIKE|IS|NULL|TRUE|FALSE|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|UNION|ALL|DISTINCT|AS|CASE|WHEN|THEN|ELSE|END|EXISTS|PRIMARY|KEY|FOREIGN|REFERENCES|CONSTRAINT|DEFAULT|UNIQUE|CHECK|ASC|DESC|COUNT|SUM|AVG|MIN|MAX|CAST|COALESCE|NULLIF|BEGIN|COMMIT|ROLLBACK|SAVEPOINT|GRANT|REVOKE)\b'), kKeywordColor),
      _TokenRule(RegExp(r'\b\d+\.?\d*\b'), kNumberColor),
      _TokenRule(RegExp(r'[+\-*/=<>,.;()]'), kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: kBaseStyle);
  }
}

class BashSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan _highlight(String code) {
    final rules = [
      _TokenRule(RegExp(r'#.*'), kCommentColor),
      _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), kStringColor),
      _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), kStringColor),
      _TokenRule(RegExp(r'`(?:[^`\\]|\\.)*`'), kStringColor),
      _TokenRule(RegExp(r'\b(?:if|then|else|elif|fi|for|while|do|done|case|esac|function|return|exit|break|continue|export|local|readonly|unset|declare|typeset|set|unset|read|echo|printf|source|\.|exec|eval|trap|wait|shift|getopts)\b'), SyntaxHighlighter.kKeywordColor),
      _TokenRule(RegExp(r'\b(?:sudo|apt|apt-get|yum|dnf|brew|pip|npm|yarn|git|docker|kubectl|curl|wget|grep|sed|awk|find|xargs|chmod|chown|ls|cd|mkdir|rm|cp|mv|cat|less|more|head|tail|touch|vim|nano)\b'), SyntaxHighlighter.kBuiltinColor),
      _TokenRule(RegExp(r'\$\{?\w+\}?'), SyntaxHighlighter.kVariableColor),
      _TokenRule(RegExp(r'\b\d+\b'), SyntaxHighlighter.kNumberColor),
      _TokenRule(RegExp(r'=>|[+\-*/%&|^~<>!?=]+'), SyntaxHighlighter.kOperatorColor),
      _TokenRule(RegExp(r'[{}[\]();.,]'), SyntaxHighlighter.kPunctuationColor),
    ];
    final spans = _tokenize(code, rules);
    return TextSpan(children: spans, style: SyntaxHighlighter.kBaseStyle);
  }
}

/// Returns the language identifier for syntax highlighting based on file extension
String languageFromExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'dart': return 'dart';
    case 'py': return 'python';
    case 'js': case 'jsx': case 'mjs': return 'javascript';
    case 'ts': case 'tsx': return 'typescript';
    case 'java': return 'java';
    case 'kt': case 'kts': return 'kotlin';
    case 'swift': return 'swift';
    case 'rs': return 'rust';
    case 'go': return 'go';
    case 'c': case 'h': return 'c';
    case 'cpp': case 'cc': case 'cxx': case 'hpp': case 'hxx': return 'cpp';
    case 'cs': return 'csharp';
    case 'html': case 'htm': case 'xhtml': return 'html';
    case 'css': case 'scss': case 'sass': case 'less': return 'css';
    case 'json': return 'json';
    case 'xml': case 'svg': case 'plist': return 'xml';
    case 'yaml': case 'yml': return 'yaml';
    case 'md': case 'markdown': return 'markdown';
    case 'sql': return 'sql';
    case 'sh': case 'bash': case 'zsh': return 'bash';
    case 'dockerfile': return 'dockerfile';
    case 'toml': return 'toml';
    case 'gradle': case 'groovy': return 'groovy';
    case 'rb': return 'ruby';
    case 'php': return 'php';
    case 'pl': case 'pm': return 'perl';
    case 'lua': return 'lua';
    case 'r': return 'r';
    case 'tex': case 'sty': case 'cls': return 'latex';
    case 'proto': return 'protobuf';
    case 'graphql': case 'gql': return 'graphql';
    default: return 'plaintext';
  }
}
