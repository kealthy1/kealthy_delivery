import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please provide an argument: patch, minor, or major.');
    exit(1);
  }

  final file = File('pubspec.yaml');
  final lines = file.readAsLinesSync();

  final versionLineIndex =
      lines.indexWhere((line) => line.startsWith('version:'));
  if (versionLineIndex == -1) {
    print('Version not found in pubspec.yaml');
    exit(1);
  }

  final versionLine = lines[versionLineIndex];
  final currentVersion = versionLine.split(' ')[1].trim();
  final versionParts = currentVersion.split('.');
  if (versionParts.length != 3) {
    print(
        'Invalid version format in pubspec.yaml. Expected "major.minor.patch" format.');
    exit(1);
  }

  int major = int.tryParse(versionParts[0]) ?? 0;
  int minor = int.tryParse(versionParts[1]) ?? 0;
  int patch = int.tryParse(versionParts[2]) ?? 0;

  switch (args[0]) {
    case 'patch':
      patch++;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    default:
      print('Invalid argument: use patch, minor, or major.');
      exit(1);
  }

  final newVersion = '$major.$minor.$patch';
  lines[versionLineIndex] = 'version: $newVersion';

  file.writeAsStringSync(lines.join('\n'));
  print('Version updated to $newVersion');
}
