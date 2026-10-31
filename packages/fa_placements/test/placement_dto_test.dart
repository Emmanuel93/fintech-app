import 'package:fa_placements/src/infrastructure/dtos/placement_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlacementDto', () {
    Map<String, dynamic> json(String? placedOn) => {
          'placementId': 'p-1',
          'beneficiaryName': 'Beneficiaria',
          'beneficiaryPhoneMask': '55 •• •• 90 37',
          'amount': 5000,
          'termFortnights': 12,
          'fortnightlyPayment': 480,
          'status': 'active',
          'placedOn': placedOn,
        };

    test('la fecha de colocación llega en UTC y se pinta en la hora del teléfono', () {
      // 19:50 del 30 de octubre en México es 01:50 del 31 en UTC.
      final placed = PlacementDto.fromJson(json('2026-10-31T01:50:00Z')).toDomain().placedOn!;

      expect(placed.isUtc, isFalse, reason: 'DateFormat pintaría el día de Greenwich');
      expect(placed, DateTime.utc(2026, 10, 31, 1, 50).toLocal());
    });

    test('sin fecha de colocación no inventa una', () {
      expect(PlacementDto.fromJson(json(null)).toDomain().placedOn, isNull);
    });
  });
}
