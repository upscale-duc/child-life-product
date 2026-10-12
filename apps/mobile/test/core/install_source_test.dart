import 'package:child_life/core/platform/install_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P-137 / Q-042: Android install source from the Play install referrer, sent once per account.
void main() {
  group('referrer → channel', () {
    test('the landing site is "website"', () {
      expect(
        channelOfReferrer('utm_source=website&utm_medium=landing'),
        InstallChannel.website,
      );
      expect(channelOfReferrer('utm_source=Website'), InstallChannel.website);
      expect(
        channelOfReferrer('utm_source%3Dwebsite%26utm_campaign%3Dhero'),
        InstallChannel.website,
        reason: 'still encoded',
      );
      expect(
        channelOfReferrer(
          'utm_source=social&utm_content=https://childlife.app/vi',
        ),
        InstallChannel.website,
      );
    });

    test('any other referrer is the store; none is unknown', () {
      expect(
        channelOfReferrer('utm_source=google-play&utm_medium=organic'),
        InstallChannel.store,
      );
      expect(channelOfReferrer('%E0%A4%A'), InstallChannel.store);
      expect(channelOfReferrer(''), InstallChannel.unknown);
      expect(channelOfReferrer(null), InstallChannel.unknown);
    });
  });

  group('reporter', () {
    late SharedPreferences prefs;
    late List<InstallChannel> sent;
    late int reads;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sent = [];
      reads = 0;
    });

    InstallSourceReporter reporter({
      bool android = true,
      Future<String?> Function()? read,
      bool failSend = false,
    }) => InstallSourceReporter(
      prefs: prefs,
      android: android,
      readReferrer:
          read ??
          () async {
            reads++;
            return 'utm_source=website';
          },
      send: (channel) async {
        if (failSend) throw Exception('offline');
        sent.add(channel);
      },
    );

    test('iOS sends nothing and never reads', () async {
      await reporter(android: false).report('u_mai');
      expect(sent, isEmpty);
      expect(reads, 0);
    });

    test('reads the referrer once, sends once per account', () async {
      await reporter().report('u_mai');
      await reporter().report('u_mai');
      expect(sent, [InstallChannel.website]);
      expect(reads, 1);

      // Another account on the same install: the remembered channel, no second read.
      await reporter().report('u_minh');
      expect(sent, [InstallChannel.website, InstallChannel.website]);
      expect(reads, 1);
    });

    test('a failed send is tried again next time', () async {
      await expectLater(
        reporter(failSend: true).report('u_mai'),
        throwsException,
      );
      expect(sent, isEmpty);
      await reporter().report('u_mai');
      expect(sent, [InstallChannel.website]);
      expect(reads, 1, reason: 'the channel was kept after the first read');
    });

    test('no Play services or not from Play is "unknown"', () async {
      await reporter(
        read: () async => throw Exception('FEATURE_NOT_SUPPORTED'),
      ).report('u_mai');
      expect(sent, [InstallChannel.unknown]);
    });
  });
}
