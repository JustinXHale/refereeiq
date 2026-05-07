import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:RefereeIQ/services/feature_flags_service.dart';

void main() {
  group('FeatureFlagsService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FeatureFlagsService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = FeatureFlagsService(db: fakeFirestore);
    });

    group('watchChallengeEnabled', () {
      test(
          'Given challengeEnabled is true in Firestore, '
          'When stream emits, '
          'Then returns true', () async {
        await fakeFirestore
            .collection('app_config')
            .doc('features')
            .set({'challengeEnabled': true});

        final result = await service.watchChallengeEnabled().first;

        expect(result, isTrue);
      });

      test(
          'Given challengeEnabled is false in Firestore, '
          'When stream emits, '
          'Then returns false', () async {
        await fakeFirestore
            .collection('app_config')
            .doc('features')
            .set({'challengeEnabled': false});

        final result = await service.watchChallengeEnabled().first;

        expect(result, isFalse);
      });

      test(
          'Given document does not exist, '
          'When stream emits, '
          'Then returns false', () async {
        final result = await service.watchChallengeEnabled().first;

        expect(result, isFalse);
      });
    });

    group('watchSourcesEnabled', () {
      test(
          'Given sourcesEnabled is true, '
          'When stream emits, '
          'Then returns true', () async {
        await fakeFirestore
            .collection('app_config')
            .doc('features')
            .set({'sourcesEnabled': true});

        final result = await service.watchSourcesEnabled().first;

        expect(result, isTrue);
      });

      test(
          'Given sourcesEnabled is absent, '
          'When stream emits, '
          'Then returns false', () async {
        await fakeFirestore
            .collection('app_config')
            .doc('features')
            .set({'challengeEnabled': true});

        final result = await service.watchSourcesEnabled().first;

        expect(result, isFalse);
      });
    });

    group('watchShopEnabled', () {
      test(
          'Given shopEnabled is true, '
          'When stream emits, '
          'Then returns true', () async {
        await fakeFirestore
            .collection('app_config')
            .doc('features')
            .set({'shopEnabled': true});

        final result = await service.watchShopEnabled().first;

        expect(result, isTrue);
      });

      test(
          'Given shopEnabled is false, '
          'When stream emits, '
          'Then returns false', () async {
        await fakeFirestore
            .collection('app_config')
            .doc('features')
            .set({'shopEnabled': false});

        final result = await service.watchShopEnabled().first;

        expect(result, isFalse);
      });

      test(
          'Given document has no shopEnabled key, '
          'When stream emits, '
          'Then returns false (shop off by default)', () async {
        final result = await service.watchShopEnabled().first;

        expect(result, isFalse);
      });
    });
  });
}
