import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import 'print_ui.dart';
import 'print_widgets.dart';

/// First-order/edited-address state of PS30N. Saving returns to the same checkout.
class PrintAddressEditor extends StatefulWidget {
  const PrintAddressEditor({
    required this.initial,
    required this.leadDays,
    super.key,
  });
  final Map<String, dynamic> initial;
  final int leadDays;
  @override
  State<PrintAddressEditor> createState() => _PrintAddressEditorState();
}

class _PrintAddressEditorState extends State<PrintAddressEditor> {
  late final recipient = TextEditingController(
        text: widget.initial['recipient'] as String? ?? '',
      ),
      phone = TextEditingController(
        text: widget.initial['phone'] as String? ?? '',
      ),
      address = TextEditingController(
        text: widget.initial['address'] as String? ?? '',
      );
  late String country = widget.initial['country'] as String? ?? 'VN';
  late DateTime? needed = DateTime.tryParse(
    widget.initial['neededBy'] as String? ?? '',
  );
  String? error;
  @override
  void dispose() {
    recipient.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), cl = context.cl;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .73,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.psShipping,
                      style: psText(context, 24, weight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const ClIcon(ClIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    PrintInput(
                      label: l.psRecipient,
                      controller: recipient,
                      maxLength: 80,
                    ),
                    const SizedBox(height: 14),
                    PrintInput(
                      label: l.psPhone,
                      controller: phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.psPhoneHelp,
                      style: psText(context, 12, color: cl.colors.inkMuted),
                    ),
                    const SizedBox(height: 14),
                    PrintInput(
                      label: l.psAddress,
                      controller: address,
                      maxLength: 400,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l.psCountry,
                      style: psText(
                        context,
                        13,
                        weight: FontWeight.w600,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: country == 'VN' ? 'VN' : 'US',
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cl.colors.surface,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const ClIcon(ClIcons.chevronDown, size: 18),
                      items: [
                        DropdownMenuItem(value: 'VN', child: Text(l.psVietnam)),
                        DropdownMenuItem(
                          value: 'US',
                          child: Text(l.psOtherCountry),
                        ),
                      ],
                      onChanged: (v) => setState(() => country = v ?? 'VN'),
                    ),
                    const SizedBox(height: 14),
                    PrintCard(
                      lifted: false,
                      onTap: () async {
                        final now = DateUtils.dateOnly(DateTime.now()),
                            first = DateUtils.dateOnly(
                              DateTime.now(),
                            ).add(Duration(days: widget.leadDays));
                        final day = await showDatePicker(
                          context: context,
                          initialDate: needed?.isBefore(first) == false
                              ? needed!
                              : first,
                          firstDate: first,
                          lastDate: DateTime(now.year + 2),
                        );
                        if (day != null && mounted) {
                          setState(() => needed = day);
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              needed == null
                                  ? l.psNeededBy
                                  : DateFormat.yMd().format(needed!),
                              style: psText(context, 15),
                            ),
                          ),
                          const ClIcon(ClIcons.calendar, size: 18),
                        ],
                      ),
                    ),
                    if (country != 'VN')
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: PrintNotice(l.psCountryHelp, warning: true),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          error!,
                          style: psText(context, 13, color: cl.colors.error),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClButton(
                label: l.psDone,
                expand: true,
                onPressed: () {
                  final number = phone.text.replaceAll(RegExp(r'[\s()-]'), '');
                  if (country == 'VN' &&
                      (recipient.text.trim().length < 2 ||
                          address.text.trim().length < 10 ||
                          !RegExp(
                            r'^(0|\+84)[35789]\d{8}$',
                          ).hasMatch(number))) {
                    setState(() => error = l.psInvalidForm);
                    return;
                  }
                  Navigator.pop(context, {
                    'recipient': recipient.text.trim(),
                    'phone': number,
                    'address': address.text.trim(),
                    'country': country,
                    'neededBy': needed == null
                        ? null
                        : DateFormat('yyyy-MM-dd').format(needed!),
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
