import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => DuplicateMapKeyLintRule();

class DuplicateMapKeyLint extends DartLintRule {
  DuplicateMapKeyLint() : super(code: _lintCode);

  static const _lintCode = LintCode(
    name: 'duplicate_map_key',
    problemMessage: 'Duplicate key "{0}" in map.',
    correctionMessage: 'Remove or rename the duplicate key.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSetOrMapLiteral((node) {
      if (node.isMap) {
        _checkForDuplicateKeys(node, reporter);
      }
    });

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'addAll') {
        _checkAddAllInvocation(node, reporter);
      }
    });
  }

  void _checkForDuplicateKeys(SetOrMapLiteral node, ErrorReporter reporter) {
    final keys = <String>{};
    for (final entry in node.elements) {
      if (entry is MapLiteralEntry) {
        final key = entry.key.toString();
        if (keys.contains(key)) {
          reporter.reportErrorForNode(_lintCode, entry.key, [key]);
        } else {
          keys.add(key);
        }
      }
    }
  }

  void _checkAddAllInvocation(
    MethodInvocation node,
    ErrorReporter reporter,
  ) {
    final target = node.realTarget;
    if (target == null) return;

    final argument = node.argumentList.arguments.firstOrNull;
    if (argument == null) return;

    if (argument is SetOrMapLiteral && argument.isMap) {
      _checkForDuplicateKeys(argument, reporter);
    }
  }
}

class DuplicateMapKeyLintRule extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        DuplicateMapKeyLint(),
      ];
}
