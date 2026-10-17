import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';

export 'emergency_numbers.dart';

/// Where a family lives (D-072 #3, D-078): ISO 3166 alpha-2, asked on 11 Thông tin bé and kept on
/// `families/{id}.country`. Only countries whose ambulance number we know are offered, so Sơ cứu
/// never has to guess one.
const familyCountries = [
  'VN',
  'US',
  'CA',
  'GB',
  'AU',
  'NZ',
  'SG',
  'DE',
  'FR',
  'JP',
  'KR',
  'TW',
  'MY',
  'TH',
  'HK',
  'CN',
  'IE',
  'NL',
  'BE',
  'ES',
  'CH',
  'AT',
  'CZ',
  'PL',
  'SE',
  'NO',
  'DK',
  'FI',
  'AE',
  'QA',
];

String countryName(AppLocalizations l10n, String code) => switch (code) {
  'VN' => l10n.pmCountryVN,
  'US' => l10n.pmCountryUS,
  'GB' => l10n.pmCountryGB,
  'AU' => l10n.pmCountryAU,
  'CA' => l10n.pmCountryCA,
  'SG' => l10n.pmCountrySG,
  'NZ' => l10n.pmCountryNZ,
  'DE' => l10n.pmCountryDE,
  'FR' => l10n.pmCountryFR,
  'JP' => l10n.pmCountryJP,
  'KR' => l10n.pmCountryKR,
  'TW' => l10n.pmCountryTW,
  'MY' => l10n.pmCountryMY,
  'TH' => l10n.pmCountryTH,
  'HK' => l10n.pmCountryHK,
  'CN' => l10n.pmCountryCN,
  'IE' => l10n.pmCountryIE,
  'NL' => l10n.pmCountryNL,
  'BE' => l10n.pmCountryBE,
  'ES' => l10n.pmCountryES,
  'CH' => l10n.pmCountryCH,
  'AT' => l10n.pmCountryAT,
  'CZ' => l10n.pmCountryCZ,
  'PL' => l10n.pmCountryPL,
  'SE' => l10n.pmCountrySE,
  'NO' => l10n.pmCountryNO,
  'DK' => l10n.pmCountryDK,
  'FI' => l10n.pmCountryFI,
  'AE' => l10n.pmCountryAE,
  'QA' => l10n.pmCountryQA,
  _ => code,
};

/// The country a time zone belongs to, when the zone is one country's only (Asia/Ho_Chi_Minh →
/// VN). Used to preselect the 11 row, which stays visible and changeable; zones shared by several
/// countries (America/*) give null and the parent picks.
String? countryForZone(String zone) {
  if (zone.startsWith('Australia/')) return 'AU';
  return const {
    'Asia/Ho_Chi_Minh': 'VN',
    'Asia/Saigon': 'VN',
    'Europe/London': 'GB',
    'Pacific/Auckland': 'NZ',
    'Asia/Singapore': 'SG',
    'Europe/Berlin': 'DE',
    'Europe/Paris': 'FR',
    'Asia/Tokyo': 'JP',
    'Asia/Seoul': 'KR',
    'Asia/Taipei': 'TW',
    'Asia/Kuala_Lumpur': 'MY',
    'Asia/Bangkok': 'TH',
    'Asia/Hong_Kong': 'HK',
    'Asia/Shanghai': 'CN',
    'Europe/Dublin': 'IE',
    'Europe/Amsterdam': 'NL',
    'Europe/Brussels': 'BE',
    'Europe/Madrid': 'ES',
    'Europe/Zurich': 'CH',
    'Europe/Vienna': 'AT',
    'Europe/Prague': 'CZ',
    'Europe/Warsaw': 'PL',
    'Europe/Stockholm': 'SE',
    'Europe/Oslo': 'NO',
    'Europe/Copenhagen': 'DK',
    'Europe/Helsinki': 'FI',
    'Asia/Dubai': 'AE',
    'Asia/Qatar': 'QA',
  }[zone];
}

/// "Gia đình đang sống ở đâu?": the picked code, or null when the sheet is dismissed.
Future<String?> showCountrySheet(BuildContext context, {String? current}) =>
    showClSheet<String>(
      context: context,
      builder: (sheet) {
        final l10n = AppLocalizations.of(sheet);
        final cl = sheet.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.pmRegionTitle),
            Text(
              l10n.pmRegionBody,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s3),
            Flexible(
              child: SingleChildScrollView(
                child: ClCardGroup(
                  children: [
                    for (final code in familyCountries)
                      ClOptionRow(
                        title: countryName(l10n, code),
                        selected: current == code,
                        onTap: () => Navigator.of(sheet).pop(code),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ClSpace.s4),
          ],
        );
      },
    );
