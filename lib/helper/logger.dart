import 'dart:io';

import 'package:askaide/helper/platform.dart';
import 'package:logger/logger.dart' as logger;

class Logger {
  static final logger.Logger instance = logger.Logger(
    printer: logger.PrettyPrinter(
      lineLength: 120,
      printTime: true,
      noBoxingByDefault: true,
    ),
    output: logger.MultiOutput(
      [
        logger.ConsoleOutput(),
        if (!PlatformTool.isWeb())
          logger.FileOutput(
            file: File(
              '${Directory.systemTemp.path}/log.txt',
            ),
            overrideExisting: true,
          ),
      ],
    ),
  );
}
