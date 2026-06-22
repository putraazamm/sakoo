// lib/screens/parent/widgets/edit_child_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/child_detail_controller.dart';
import '../../../models/child_model.dart';

class EditChildSheet extends StatefulWidget {
  final ChildDetailController controller;
  final ChildModel child;

  const EditChildSheet({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends State<EditChildSheet> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _dailyLimitController;
  late final TextEditingController _autoTopUpAmountController;

  bool _isSaving = false;

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.child.childNickname);
    _dailyLimitController = TextEditingController(
      text: widget.child.dailyLimit == 0 ? '' : widget.child.dailyLimit.toStringAsFixed(2),
    );
    _autoTopUpAmountController = TextEditingController(
      text: widget.child.autoTopUpAmount == 0 ? '' : widget.child.autoTopUpAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _dailyLimitController.dispose();
    _autoTopUpAmountController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final newNickname = _nicknameController.text.trim();
    final newLimit = double.tryParse(_dailyLimitController.text.trim());
    final autoTopUpEnabled = widget.controller.editAutoTopUpEnabled.value;

    if (newNickname.isEmpty || newLimit == null || newLimit < 0) {
      Get.snackbar(
        "Invalid input",
        "Please provide a valid nickname and daily limit",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    double autoTopUpAmount = 0.0;
    if (autoTopUpEnabled) {
      final parsedAmount = double.tryParse(_autoTopUpAmountController.text.trim());
      if (parsedAmount == null || parsedAmount <= 0) {
        Get.snackbar(
          "Invalid amount",
          "Please enter a valid auto top-up amount, or turn the toggle off.",
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      autoTopUpAmount = parsedAmount;
    }

    setState(() => _isSaving = true);

    await widget.controller.saveChildEdits(
      newNickname: newNickname,
      newDailyLimit: newLimit,
      autoTopUpEnabled: autoTopUpEnabled,
      autoTopUpAmount: autoTopUpAmount,
      autoTopUpFrequency: widget.controller.editAutoTopUpFrequency.value,
      autoTopUpDay: widget.controller.editAutoTopUpDay.value,
    );

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle + header
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Card Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'SF Pro Rounded',
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(text: "Profile"),
                  const SizedBox(height: 8),
                  _Card(
                    child: TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: "Child Nickname",
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                    _SectionLabel(text: "Spending Controls"),
                    const SizedBox(height: 8),
                    _Card(
                      child: TextField(
                        controller: _dailyLimitController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Daily Limit",
                          prefixText: "RM ",
                          hintText: "0.00",
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(text: "Scheduled Auto Top-Up"),
                    const SizedBox(height: 8),
                    _Card(
                      padding: const EdgeInsets.all(4),
                      child: Obx(() {
                        final enabled = widget.controller.editAutoTopUpEnabled.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Auto Top-Up",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          enabled
                                              ? "Funds will be sent from your wallet automatically."
                                              : "Turn on to schedule recurring top-ups.",
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: enabled,
                                    activeColor: const Color(0xFF2B2B2B),
                                    onChanged: (value) {
                                      widget.controller.editAutoTopUpEnabled.value = value;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            if (enabled) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                child: TextField(
                                  controller: _autoTopUpAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: "Amount per top-up",
                                    prefixText: "RM ",
                                    hintText: "0.00",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "Frequency",
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _FrequencySelector(
                                  value: widget.controller.editAutoTopUpFrequency.value,
                                  onChanged: (freq) {
                                    widget.controller.editAutoTopUpFrequency.value = freq;
                                    // reset the day to a sensible default when frequency changes
                                    if (freq == 'weekly') {
                                      widget.controller.editAutoTopUpDay.value = 1;
                                    } else if (freq == 'monthly') {
                                      widget.controller.editAutoTopUpDay.value = 1;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Day picker, depends on frequency
                              if (widget.controller.editAutoTopUpFrequency.value == 'weekly') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    "On",
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: List.generate(7, (i) {
                                      final isoDay = i + 1; // 1 = Monday ... 7 = Sunday
                                      final isSelected = widget.controller.editAutoTopUpDay.value == isoDay;
                                      return GestureDetector(
                                        onTap: () => widget.controller.editAutoTopUpDay.value = isoDay,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF2B2B2B) : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _weekdayLabels[i],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ] else if (widget.controller.editAutoTopUpFrequency.value == 'monthly') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    "On day of month",
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: SizedBox(
                                    height: 36,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 28,
                                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                                      itemBuilder: (context, index) {
                                        final day = index + 1;
                                        final isSelected = widget.controller.editAutoTopUpDay.value == day;
                                        return GestureDetector(
                                          onTap: () => widget.controller.editAutoTopUpDay.value = day,
                                          child: Container(
                                            width: 36,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFF2B2B2B) : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$day',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                              ],
                            ],
                          ],
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    _SectionLabel(text: "Card Status"),
                    const SizedBox(height: 8),
                    _Card(
                      child: widget.controller.buildCardStatusSlider(widget.child),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B2B2B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SF Pro Rounded',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 0.3,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FrequencySelector({required this.value, required this.onChanged});

  static const _options = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _options.map((option) {
          final isSelected = value == option['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2B2B2B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}