import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A file handed to the share sheet: written to the temporary folder first.
typedef NuShareFile = ({String name, String content, String mimeType});

/// Opens the system share sheet with [text] or [file] (9e doctor's summary, 9g calendar file).
/// No server call and no calendar permission (P-163 #7, #13). Tests replace it.
typedef NuShare =
    Future<void> Function({
      String? text,
      String? subject,
      NuShareFile? file,
      Rect? origin,
    });

final nuShareProvider = Provider<NuShare>(
  (ref) =>
      ({String? text, String? subject, NuShareFile? file, Rect? origin}) async {
        final files = <XFile>[];
        if (file != null) {
          final dir = await getTemporaryDirectory();
          final f = File('${dir.path}/${file.name}');
          await f.writeAsBytes(utf8.encode(file.content), flush: true);
          files.add(XFile(f.path, mimeType: file.mimeType));
        }
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: subject,
            files: files.isEmpty ? null : files,
            sharePositionOrigin: origin,
          ),
        );
      },
);

/// Where the share sheet points from on iPad: the widget of [context].
Rect? nuShareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  return box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}
